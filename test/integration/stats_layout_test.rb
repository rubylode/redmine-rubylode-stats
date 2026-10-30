# Rubylode Stats: charts over a project's tickets, for Redmine
# Copyright (C) 2026  Nick Gorbikoff
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path("../test_helper", __dir__)

class StatsLayoutTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :issue_categories, :versions, :workflows, :queries,
           :custom_fields, :custom_values, :custom_fields_trackers, :custom_fields_projects, :journals, :journal_details,
           :watchers, :time_entries, :attachments, :repositories, :changesets

  ALL_STATUSES = "set_filter=1&f[]=status_id&op[status_id]=*".freeze

  def setup
    @project = Project.find(1)
    @original_subproject_setting = Setting.display_subprojects_issues
    Setting.display_subprojects_issues = "0"
    @project.enable_module!(:rubylode_stats)
    Role.find(1).add_permission!(:view_rubylode_stats)
    log_user("jsmith", "jsmith")
  end

  def teardown
    Setting.display_subprojects_issues = @original_subproject_setting
  end

  def test_the_first_load_filters_to_this_quarter_and_marks_that_preset_active
    travel_to Time.utc(2026, 10, 29, 12) do
      get stats_path

      assert_includes response.body, 'addFilter("created_on", "\u003e\u003c", ["2026-10-01","2026-12-31"])'
      assert_equal ["this_quarter"], active_presets
      assert_select "a.stats-preset[data-preset=this_quarter][aria-current=true]"
      assert_select "a.stats-preset[data-preset=this_week][aria-current]", false
    end
  end

  def test_the_default_range_goes_on_the_closed_date_for_the_people_tab_without_the_open_status_filter
    travel_to Time.utc(2026, 10, 29, 12) do
      get "#{stats_path}?tab=people"

      assert_equal ["this_quarter"], active_presets
      assert_equal %w[closed_on], preset_filter_fields("this_quarter")
    end
  end

  def test_a_chosen_preset_replaces_the_default_and_all_time_removes_it
    travel_to Time.utc(2026, 10, 29, 12) do
      get stats_path
      get css_select("a.stats-preset[data-preset=this_month]").first["href"]
      assert_equal ["this_month"], active_presets

      get css_select("a.stats-preset[data-preset=all_time]").first["href"]
      assert_equal ["all_time"], active_presets
      assert_not_includes response.body, 'addFilter("created_on"'
    end
  end

  def test_a_user_chosen_filter_without_a_date_is_not_given_the_default_range
    get "#{stats_path}?#{ALL_STATUSES}"

    assert_equal ["all_time"], active_presets
    assert_equal 7, chart_rows("tickets_by_status").sum { |row| row["tickets"] }
  end

  def test_filters_and_options_sit_behind_one_button_that_shows_the_active_filter_count
    get "#{stats_path}?#{ALL_STATUSES}&f[]=tracker_id&op[tracker_id]=%3D&v[tracker_id][]=1"

    assert_select "button.stats-filters-toggle[aria-expanded=false][aria-controls=stats-filters-panel]" do
      assert_select ".stats-filter-count", text: "2"
    end
    assert_select "#stats-filters-panel fieldset#filters"
    assert_select "#stats-filters-panel fieldset#options"
    assert_select ".stats-bar input.stats-apply[type=submit]"
    assert_select ".stats-bar a.stats-clear"
    assert_select ".stats-bar select#period"
    assert_select ".stats-bar select#slice_by"
  end

  def test_the_overview_shows_four_summary_tiles_with_the_numbers_and_words_for_the_backlog
    get "#{stats_path}?#{ALL_STATUSES}"

    assert_equal %w[open closed_in_range median_days backlog_change], css_select(".stats-tile").map { |tile| tile["data-tile"] }
    assert_equal "4", css_select(".stats-tile[data-tile=open] .stats-tile-value").first.text.strip
    assert_match(/of 7 tickets/, css_select(".stats-tile[data-tile=open] .stats-tile-detail").first.text)
    assert_equal "3", css_select(".stats-tile[data-tile=closed_in_range] .stats-tile-value").first.text.strip
    assert_match(/43% of the tickets counted/, css_select(".stats-tile[data-tile=closed_in_range] .stats-tile-detail").first.text)
    backlog = css_select(".stats-tile[data-tile=backlog_change]").first
    assert_match(/(Growing: up|Shrinking: down|Steady: no change)/, backlog.text)
    assert_not_empty backlog.css(".stats-tile-arrow")
  end

  def test_the_tiles_show_a_dash_when_there_is_nothing_to_divide
    get "#{stats_path}?#{ALL_STATUSES}&f[]=tracker_id&op[tracker_id]=%3D&v[tracker_id][]=3"

    assert_response :success
    assert_equal "0", css_select(".stats-tile[data-tile=open] .stats-tile-value").first.text.strip
    assert_equal "–", css_select(".stats-tile[data-tile=median_days] .stats-tile-value").first.text.strip
    assert_no_match(/%/, css_select(".stats-tile[data-tile=closed_in_range] .stats-tile-detail").first.text)
  end

  def test_the_other_tabs_have_no_tiles
    get "#{stats_path}?#{ALL_STATUSES}&tab=speed"

    assert_select ".stats-tile", false
  end

  def test_each_chart_is_a_card_with_a_title_and_a_subtitle_and_the_time_chart_is_full_width
    get "#{stats_path}?#{ALL_STATUSES}"

    assert_select ".stats-grid section.stats-card", 4
    assert_select "#stats-card-tickets_by_status h3.stats-card-title", text: "Tickets by status"
    assert_select "#stats-card-tickets_by_status p.stats-card-subtitle", text: "Where does the work sit right now?"
    assert_select "#stats-card-opened_and_closed.stats-card-wide"
    assert_select "#stats-card-tickets_by_status.stats-card-wide", false
    assert_select "#stats-card-open_versus_closed #stats-chart-open_versus_closed"
  end

  def test_the_time_to_close_histogram_is_on_the_speed_tab_only
    get "#{stats_path}?#{ALL_STATUSES}"
    assert_select "#stats-chart-time_to_close_histogram", false

    get "#{stats_path}?#{ALL_STATUSES}&tab=speed"
    assert_select "#stats-chart-time_to_close_histogram"
  end

  def test_open_versus_closed_is_a_donut_with_the_percentage_in_the_centre_and_counts_in_the_legend
    get "#{stats_path}?set_filter=1&f[]=status_id&op[status_id]=c"

    specification = chart_specification("open_versus_closed")
    assert_equal %w[arc text text], specification["layer"].map { |layer| layer.dig("mark", "type") }
    assert_equal [["open", 4], ["closed", 3]], chart_rows("open_versus_closed").map { |row| [row["state"], row["tickets"]] }
    assert_equal ["Open 4 (57%)", "Closed 3 (43%)"], chart_rows("open_versus_closed").map { |row| row["legend_label"] }
    assert_equal "43%", specification["layer"][1].dig("encoding", "text", "value")
    assert_select "#stats-card-open_versus_closed p.stats-card-note", text: /status filter is ignored/
  end

  private

  def stats_path
    "/projects/#{@project.identifier}/stats"
  end

  def active_presets
    css_select("a.stats-preset.active").map { |link| link["data-preset"] }
  end

  def preset_filter_fields(key)
    href = css_select("a.stats-preset[data-preset=#{key}]").first["href"]
    Rack::Utils.parse_nested_query(URI(href).query)["f"]
  end

  def chart_specification(chart_name)
    JSON.parse(css_select("#stats-chart-#{chart_name}").first["data-specification"])
  end

  def chart_rows(chart_name)
    chart_specification(chart_name).dig("data", "values")
  end
end
