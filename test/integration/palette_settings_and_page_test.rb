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

class PaletteSettingsAndPageTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :issue_categories, :versions, :workflows, :queries,
           :custom_fields, :custom_values, :custom_fields_trackers, :custom_fields_projects, :journals, :journal_details,
           :watchers, :time_entries, :attachments, :repositories, :changesets

  SETTINGS_PATH = "/settings/plugin/redmine_rubylode_stats".freeze

  def setup
    @previous_settings = Setting.plugin_redmine_rubylode_stats
    @project = Project.find(1)
    @project.enable_module!(:rubylode_stats)
    Role.find(1).add_permission!(:view_rubylode_stats)
  end

  def teardown
    Setting.plugin_redmine_rubylode_stats = @previous_settings
  end

  def palette_on_page(tab = nil)
    get "/projects/#{@project.identifier}/stats", params: { tab: tab }.compact
    assert_response :success
    element = css_select("[data-palette]").first
    assert element, "the page carries no data-palette"
    JSON.parse(element["data-palette"])
  end

  def specification_of(chart_name)
    JSON.parse(css_select("#stats-chart-#{chart_name}").first["data-specification"])
  end

  def test_the_page_carries_the_theme_following_editorial_palette_by_default
    log_user("jsmith", "jsmith")
    Setting.plugin_redmine_rubylode_stats = {}

    palette = palette_on_page

    assert_equal true, palette["follow_theme"]
    assert_equal RubylodeStats::Palette::PRESETS.fetch("editorial")["light"], palette["light"]
  end

  def test_the_page_carries_the_chosen_preset
    log_user("jsmith", "jsmith")
    Setting.plugin_redmine_rubylode_stats = { "palette_preset" => "colour_blind_safe" }

    palette = palette_on_page

    assert_equal false, palette["follow_theme"]
    assert_equal RubylodeStats::Palette::PRESETS.fetch("colour_blind_safe")["light"]["categorical"], palette["light"]["categorical"]
  end

  def test_the_page_carries_a_custom_palette
    log_user("jsmith", "jsmith")
    Setting.plugin_redmine_rubylode_stats = { "palette_preset" => "custom", "custom_colours" => "#123456,#654321" }

    assert_equal %w[#123456 #654321], palette_on_page["dark"]["categorical"]
  end

  def test_a_deployment_tool_writing_the_hash_directly_changes_the_page
    log_user("jsmith", "jsmith")
    Setting.plugin_redmine_rubylode_stats = { "palette_preset" => "data_visualisation" }

    assert_equal RubylodeStats::Palette::PRESETS.fetch("data_visualisation")["light"], palette_on_page["light"]
  end

  def test_the_page_loads_the_palette_script_before_the_page_script
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/stats"

    sources = css_select("script[src]").map { |script| script["src"][%r{[^/?]+\.js}].sub(/-\h{8}\.js\z/, ".js") }
    assert_operator sources.index("rubylode_stats_palette.js"), :<, sources.index("rubylode_stats.js")
  end

  def test_the_charts_name_open_and_closed_by_role_so_every_chart_agrees
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/stats"

    donut_range = specification_of("open_versus_closed").dig("layer", 0, "encoding", "color", "scale", "range")
    opened_and_closed_range = specification_of("opened_and_closed").dig("layer", 0, "encoding", "color", "scale", "range")

    assert_equal %w[role:open role:closed], donut_range
    assert_equal %w[role:open role:closed role:neutral], opened_and_closed_range
  end

  def test_the_versions_chart_draws_remaining_in_the_neutral_role_and_done_in_the_closed_role
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/stats", params: { tab: "versions" }

    range = specification_of("progress_per_version").dig("layer", 0, "encoding", "color", "scale", "range")

    assert_equal %w[role:closed role:neutral], range
  end

  def test_the_status_and_category_bars_are_coloured_by_their_own_label_in_order_with_no_legend
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/stats"

    { "tickets_by_status" => "status", "tickets_by_slice" => "slice" }.each do |chart_name, field|
      color = specification_of(chart_name).dig("encoding", "color")

      assert_equal field, color["field"], chart_name
      assert_equal({ "field" => "position" }, color["sort"], chart_name)
      assert_nil color["legend"], chart_name
      assert color.key?("legend"), "#{chart_name} must switch the legend off"
    end
  end

  def test_the_time_to_close_histogram_and_the_median_line_keep_the_single_colour
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/stats", params: { tab: "speed" }

    assert_nil specification_of("time_to_close_histogram").dig("encoding", "color")
    assert_nil specification_of("median_time_to_close").dig("encoding", "color")
  end

  def test_no_chart_specification_holds_a_hex_colour
    log_user("jsmith", "jsmith")
    %w[overview people speed versions].each do |tab|
      get "/projects/#{@project.identifier}/stats", params: { tab: tab }
      css_select(".stats-chart").each do |chart|
        assert_no_match(/#[0-9a-fA-F]{6}\b/, chart["data-specification"].gsub(/"url":"[^"]*"/, ""), "#{tab} #{chart["id"]}")
      end
    end
  end

  def test_the_settings_form_shows_the_presets_and_the_custom_fields_with_their_defaults
    log_user("admin", "admin")
    Setting.plugin_redmine_rubylode_stats = {}

    get SETTINGS_PATH

    assert_response :success
    assert_select "select#settings_palette_preset option", 6
    assert_select "select#settings_palette_preset option[selected][value=follow_theme]"
    assert_select "input#settings_custom_colours"
    assert_select "input#settings_custom_open_colour"
    assert_select "input#settings_custom_closed_colour"
    assert_select "input#settings_custom_neutral_colour"
  end

  def test_the_settings_form_saves_the_editorial_preset
    log_user("admin", "admin")

    post SETTINGS_PATH, params: { settings: { palette_preset: "editorial" } }

    assert_redirected_to SETTINGS_PATH
    assert_equal "editorial", Setting.plugin_redmine_rubylode_stats["palette_preset"]
  end

  def test_the_category_bars_and_the_pie_draw_the_none_bucket_in_the_neutral_role
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/stats"

    scale = specification_of("tickets_by_slice").dig("encoding", "color", "scale")
    none_position = scale["domain"].index("None")

    assert none_position, "the category chart of the fixtures has a None bucket"
    assert_equal "role:neutral", scale["range"][none_position]
    (scale["range"] - ["role:neutral"]).each_with_index { |token, index| assert_equal "category:#{index + 1}", token }
  end

  def test_the_settings_form_saves_a_valid_custom_palette
    log_user("admin", "admin")

    post SETTINGS_PATH, params: { settings: { palette_preset: "custom", custom_colours: "#abc, #123456", custom_open_colour: "",
                                              custom_closed_colour: "", custom_neutral_colour: "" } }

    assert_redirected_to SETTINGS_PATH
    saved = Setting.plugin_redmine_rubylode_stats
    assert_equal "custom", saved["palette_preset"]
    assert_equal "#abc, #123456", saved["custom_colours"]
  end

  def test_the_settings_form_refuses_a_bad_colour_and_keeps_what_was_typed
    log_user("admin", "admin")
    Setting.plugin_redmine_rubylode_stats = { "palette_preset" => "material" }

    post SETTINGS_PATH, params: { settings: { palette_preset: "custom", custom_colours: "#112233, banana" } }

    assert_response :unprocessable_entity
    assert_select ".flash.error", text: /banana/
    assert_select "input#settings_custom_colours[value=?]", "#112233, banana"
    assert_select "select#settings_palette_preset option[selected][value=custom]"
    assert_equal "material", Setting.plugin_redmine_rubylode_stats["palette_preset"]
  end
end
