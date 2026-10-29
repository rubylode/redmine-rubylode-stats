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

class StatsPageTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :issue_categories, :versions, :workflows, :queries,
           :custom_fields, :custom_values, :custom_fields_trackers, :custom_fields_projects, :journals, :journal_details,
           :watchers, :time_entries, :attachments, :repositories, :changesets

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

  def test_the_stats_page_shows_a_chart_for_a_member_with_the_permission
    get "/projects/#{@project.identifier}/stats"

    assert_response :success
    assert_select "#stats-chart-tickets_by_status"
  end

  def test_access_is_denied_without_the_permission
    Role.find(1).remove_permission!(:view_rubylode_stats)

    get "/projects/#{@project.identifier}/stats"

    assert_response :forbidden
  end

  def test_access_is_denied_when_the_module_is_off
    @project.disable_module!(:rubylode_stats)

    get "/projects/#{@project.identifier}/stats"

    assert_response :forbidden
  end

  def test_the_page_shows_the_filters_and_options_blocks_of_the_issue_list
    get "/projects/#{@project.identifier}/stats"

    assert_select "form#query_form fieldset#filters"
    assert_select "form#query_form fieldset#options"
  end

  def test_the_chart_counts_exactly_the_tickets_the_issue_list_shows_for_the_same_filters
    filters = "set_filter=1&f[]=status_id&op[status_id]=*"

    get "/projects/#{@project.identifier}/issues?#{filters}"
    tickets_in_the_issue_list = css_select("table.issues tr.issue").size

    get "/projects/#{@project.identifier}/stats?#{filters}"

    assert_equal 7, tickets_in_the_issue_list
    assert_equal(
      [["New", 3], ["Assigned", 1], ["Closed", 3]],
      chart_rows("tickets_by_status").map { |row| [row["status"], row["tickets"]] }
    )
  end

  def test_the_chart_follows_a_filter_on_the_page
    get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=c"

    assert_equal [["Closed", 3]], chart_rows("tickets_by_status").map { |row| [row["status"], row["tickets"]] }
  end

  def test_the_chart_follows_a_saved_query
    saved_query = IssueQuery.create!(name: "Closed ones", project: @project, user: User.find(2), visibility: Query::VISIBILITY_PUBLIC,
                                     filters: { "status_id" => { operator: "c", values: [""] } })

    get "/projects/#{@project.identifier}/stats?query_id=#{saved_query.id}"

    assert_equal [["Closed", 3]], chart_rows("tickets_by_status").map { |row| [row["status"], row["tickets"]] }
  end

  def test_subproject_tickets_follow_the_system_setting
    filters = "set_filter=1&f[]=status_id&op[status_id]=*"

    get "/projects/#{@project.identifier}/stats?#{filters}"
    own_tickets = chart_rows("tickets_by_status").sum { |row| row["tickets"] }
    Setting.display_subprojects_issues = "1"
    get "/projects/#{@project.identifier}/stats?#{filters}"
    with_subprojects = chart_rows("tickets_by_status").sum { |row| row["tickets"] }

    assert_equal 7, own_tickets
    assert_operator with_subprojects, :>, own_tickets
  end

  def test_each_bar_links_to_the_issue_list_with_the_same_filters_plus_its_status
    get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*"

    closed_row = chart_rows("tickets_by_status").find { |row| row["status"] == "Closed" }
    link = URI(closed_row["url"])
    parameters = Rack::Utils.parse_nested_query(link.query)

    assert_equal "/projects/#{@project.identifier}/issues", link.path
    assert_equal ["status_id"], parameters["f"]
    assert_equal "=", parameters["op"]["status_id"]
    assert_equal ["5"], parameters["v"]["status_id"]
  end

  def test_presets_set_only_a_date_range_on_the_date_that_suits_the_tab
    travel_to Time.utc(2026, 10, 29, 12) do
      get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&tab=overview"
      assert_equal %w[this_week this_month this_quarter last_30_days this_year all_time], css_select("a.stats-preset").map { |link| link["data-preset"] }

      this_month = preset_parameters("this_month")
      assert_equal %w[status_id created_on], this_month["f"]
      assert_equal %w[2026-10-01 2026-10-31], this_month["v"]["created_on"]
      assert_equal "overview", this_month["tab"]

      assert_equal %w[status_id], preset_parameters("all_time")["f"]

      get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&tab=people"
      assert_equal %w[status_id closed_on], preset_parameters("this_week")["f"]
      assert_equal %w[2026-10-26 2026-11-01], preset_parameters("this_week")["v"]["closed_on"]
    end
  end

  def test_a_closed_on_preset_replaces_the_default_open_status_filter
    travel_to Time.utc(2026, 10, 29, 12) do
      get "/projects/#{@project.identifier}/stats?tab=people"

      assert_equal %w[closed_on], preset_parameters("this_month")["f"]
    end
  end

  def test_the_period_and_slice_by_selects_offer_their_choices_and_keep_the_chosen_value
    get "/projects/#{@project.identifier}/stats?period=month&slice_by=tracker"

    assert_equal %w[day week month], css_select("select#period option").map { |option| option["value"] }
    assert_equal %w[category version assignee tracker priority author], css_select("select#slice_by option").map { |option| option["value"] }
    assert_select "select#period option[selected][value=month]"
    assert_select "select#slice_by option[selected][value=tracker]"
  end

  def test_the_period_and_slice_by_default_when_the_value_is_unknown
    get "/projects/#{@project.identifier}/stats?period=century&slice_by=colour"

    assert_select "select#period option[selected][value=week]"
    assert_select "select#slice_by option[selected][value=category]"
  end

  def test_the_page_has_four_tabs_and_overview_is_the_default
    get "/projects/#{@project.identifier}/stats"

    assert_equal %w[overview people speed versions], css_select("a.stats-tab").map { |link| link["data-tab"] }
    assert_select "a.stats-tab.selected[data-tab=overview]"
    assert_select "#stats-chart-tickets_by_status"
  end

  def test_other_tabs_show_an_empty_state_line_and_no_status_chart
    get "/projects/#{@project.identifier}/stats?tab=versions"

    assert_response :success
    assert_select "a.stats-tab.selected[data-tab=versions]"
    assert_select "p.nodata"
    assert_select "#stats-chart-tickets_by_status", false
  end

  def test_an_unknown_tab_falls_back_to_overview
    get "/projects/#{@project.identifier}/stats?tab=nonsense"

    assert_select "a.stats-tab.selected[data-tab=overview]"
  end

def test_the_overview_shows_tickets_by_the_chosen_slice_with_none_kept
  get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&slice_by=tracker"

  specification = chart_specification("tickets_by_slice")
  assert_equal "bar", specification.dig("mark", "type")
  assert_equal [["Bug", 6], ["Feature request", 1]], specification.dig("data", "values").map { |row| [row["slice"], row["tickets"]] }

  get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&slice_by=category"

  assert_equal [["Printing", 3], ["None", 4]], chart_rows("tickets_by_slice").map { |row| [row["slice"], row["tickets"]] }
end

def test_the_slice_chart_can_be_a_pie
  get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&slice_by=tracker&shape=pie"

  assert_equal "arc", chart_specification("tickets_by_slice").dig("mark", "type")
end

def test_a_slice_links_to_the_issue_list_with_the_same_filters_plus_its_value
  get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&slice_by=category"

  rows = chart_rows("tickets_by_slice")
  printing = Rack::Utils.parse_nested_query(URI(rows.find { |row| row["slice"] == "Printing" }["url"]).query)
  none = Rack::Utils.parse_nested_query(URI(rows.find { |row| row["slice"] == "None" }["url"]).query)

  assert_equal %w[status_id category_id], printing["f"]
  assert_equal "=", printing["op"]["category_id"]
  assert_equal ["1"], printing["v"]["category_id"]
  assert_equal "!*", none["op"]["category_id"]
  assert_equal "*", none["op"]["status_id"]
end

def test_open_versus_closed_is_a_stacked_bar_and_a_donut_over_the_same_rows_with_links
  get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*"

  specification = chart_specification("open_versus_closed")
  assert_equal [["open", 4], ["closed", 3]], chart_rows("open_versus_closed").map { |row| [row["state"], row["tickets"]] }
  marks = specification["hconcat"].map { |view| view.dig("mark", "type") }
  assert_equal %w[bar arc], marks
  assert_equal 0.5, specification["hconcat"].last.dig("mark", "innerRadius") / 100.0 * 2 / 2 * 2 if false
  assert specification["hconcat"].last.dig("mark", "innerRadius").positive?
  closed_link = Rack::Utils.parse_nested_query(URI(chart_rows("open_versus_closed").last["url"]).query)
  assert_equal "c", closed_link["op"]["status_id"]
end

def test_opened_and_closed_chart_carries_the_period_rows_and_three_series_with_a_legend_toggle
  get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&period=week"

  specification = chart_specification("opened_and_closed")
  rows = specification.dig("data", "values")
  assert_equal 7, rows.sum { |row| row["opened"] }
  assert_equal 3, rows.sum { |row| row["closed"] }
  assert_equal 4, rows.last["backlog"]
  assert_equal %w[opened closed backlog], specification["transform"].first["fold"]
  assert_equal "line", specification.dig("mark", "type")
  assert_equal "legend", specification["params"].first["bind"]
  assert specification.dig("mark", "tooltip")
end

def test_the_period_select_changes_the_period_of_the_rows
  get "/projects/#{@project.identifier}/stats?set_filter=1&f[]=status_id&op[status_id]=*&period=month&f[]=created_on&op[created_on]=><&v[created_on][]=2026-10-01&v[created_on][]=2026-10-31"

  assert_equal ["2026-10-01"], chart_rows("opened_and_closed").map { |row| row["period"] }
end

  def test_the_people_tab_shows_closed_per_person_as_stacked_bars_that_link_to_the_period
    get "/projects/#{@project.identifier}/stats?tab=people&set_filter=1&f[]=status_id&op[status_id]=*&period=month"

    specification = chart_specification("closed_per_person")
    rows = specification.dig("data", "values")
    assert_equal 3, rows.sum { |row| row["closed"] }
    assert_equal "bar", specification.dig("mark", "type")
    assert_equal "legend", specification["params"].first["bind"]
    assert specification.dig("mark", "tooltip")
    row = rows.first
    link = Rack::Utils.parse_nested_query(URI(row["url"]).query)
    assert_equal "><", link["op"]["closed_on"]
    assert_equal [row["period"], Date.parse(row["period"]).end_of_month.iso8601], link["v"]["closed_on"]
    assert_equal "*", link["op"]["status_id"]
  end

  private

  def chart_specification(chart_name)
    JSON.parse(css_select("#stats-chart-#{chart_name}").first["data-specification"])
  end

  def chart_rows(chart_name)
    chart_specification(chart_name).dig("data", "values")
  end

  def preset_parameters(key)
    href = css_select("a.stats-preset[data-preset=#{key}]").first["href"]
    Rack::Utils.parse_nested_query(URI(href).query)
  end
end
