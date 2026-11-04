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

# The strings follow the Rubylode plugin standard: one root key, settings with a label and a hint, US spelling, no dashes.
class LocaleTest < ActiveSupport::TestCase
  LOCALE = YAML.safe_load_file(File.expand_path("../../config/locales/en.yml", __dir__)).fetch("en")

  def flattened_strings(node = LOCALE, path = [])
    return { path.join(".") => node } unless node.is_a?(Hash)

    node.flat_map { |key, value| flattened_strings(value, path + [key]).to_a }.to_h
  end

  def test_only_the_keys_redmine_reads_are_outside_the_plugin_root
    assert_equal %w[label_stats permission_view_rubylode_stats project_module_rubylode_stats rubylode_stats], LOCALE.keys.sort
  end

  def test_every_setting_has_a_label_and_a_hint
    RubylodeStats::Settings::DEFAULTS.each_key do |key|
      assert LOCALE.dig("rubylode_stats", "settings", key, "label").present?, "#{key} has no label"
      assert LOCALE.dig("rubylode_stats", "settings", key, "hint").present?, "#{key} has no hint"
    end
  end

  def test_no_string_has_a_dash_or_british_spelling
    flattened_strings.each do |path, text|
      assert_no_match(/[\u2013\u2014]/, text.to_s, "#{path} has a dash")
      assert_no_match(/colour|visualis|\bgrey\b/i, text.to_s, "#{path} is not US spelling")
    end
  end

  def test_no_setting_label_ends_with_a_period
    LOCALE.dig("rubylode_stats", "settings").each do |key, texts|
      assert_no_match(/\.\z/, texts["label"].to_s, key)
      assert_match(/\.\z/, texts["hint"].to_s, key) if texts["hint"]
    end
  end

  def test_the_shipped_files_have_no_dash_in_text_shown_to_people
    %w[app/helpers/stats_helper.rb app/models/rubylode_stats/charts/base.rb app/models/rubylode_stats/charts/progress_per_version.rb
       app/models/rubylode_stats/charts/open_versus_closed.rb].each do |path|
      source = File.read(File.expand_path("../../#{path}", __dir__))
      assert_no_match(/"[^"\n]*[\u2013\u2014][^"\n]*"/, source, path)
    end
  end

  def test_the_median_tile_counts_one_closed_ticket_in_the_singular
    assert_equal "1 closed ticket", I18n.t("rubylode_stats.tiles.median_days_detail", count: 1)
    assert_equal "2 closed tickets", I18n.t("rubylode_stats.tiles.median_days_detail", count: 2)
  end

  def test_the_color_error_agrees_with_the_number_of_bad_values
    assert_equal "Custom colors: red is not a hex color such as #abc or #aabbcc.", I18n.t("rubylode_stats.errors.custom_colors_invalid", count: 1, values: "red")
    assert_includes I18n.t("rubylode_stats.errors.custom_colors_invalid", count: 2, values: "red, blue"), "are not hex colors"
  end
end
