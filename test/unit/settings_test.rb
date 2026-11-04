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

class SettingsTest < ActiveSupport::TestCase
  def errors_for(values)
    RubylodeStats::Settings.errors_for(values)
  end

  def test_the_defaults_follow_the_theme_and_leave_the_custom_keys_empty
    assert_equal(
      { "palette_preset" => "follow_theme", "custom_colors" => "", "custom_open_color" => "", "custom_closed_color" => "", "custom_neutral_color" => "" },
      RubylodeStats::Settings::DEFAULTS
    )
  end

  def test_the_choices_are_the_five_presets_in_display_order
    assert_equal %w[follow_theme editorial material color_blind_safe data_visualization custom], RubylodeStats::Settings::PRESET_CHOICES
  end

  def test_an_empty_hash_is_valid_and_reads_as_the_defaults
    settings = RubylodeStats::Settings.new({})

    assert_empty settings.errors
    assert_equal "follow_theme", settings.palette_preset
  end

  def test_a_symbol_keyed_hash_is_read_too
    assert_equal "material", RubylodeStats::Settings.new(palette_preset: "material").palette_preset
  end

  def test_an_unknown_preset_is_an_error
    messages = errors_for("palette_preset" => "neon")

    assert_equal 1, messages.size
    assert_includes messages.first, "neon"
  end

  def test_every_choice_is_valid
    RubylodeStats::Settings::PRESET_CHOICES.each do |choice|
      assert_empty errors_for("palette_preset" => choice, "custom_colors" => "#112233"), choice
    end
  end

  def test_the_custom_preset_needs_at_least_one_color
    assert_match(/at least one/i, errors_for("palette_preset" => "custom", "custom_colors" => " ").first)
  end

  def test_the_custom_preset_allows_at_most_ten_colors
    eleven = (1..11).map { |number| format("#%06x", number * 1000) }

    assert_match(/no more than 10/i, errors_for("palette_preset" => "custom", "custom_colors" => eleven.join(",")).first)
    assert_empty errors_for("palette_preset" => "custom", "custom_colors" => eleven.first(10).join(","))
  end

  def test_a_custom_color_that_is_not_hex_is_named_in_the_error
    messages = errors_for("palette_preset" => "custom", "custom_colors" => "#112233, red, #12345")

    assert_equal 1, messages.size
    assert_includes messages.first, "red"
    assert_includes messages.first, "#12345"
  end

  def test_a_bad_role_color_is_an_error_that_names_the_role
    assert_match(/open/i, errors_for("palette_preset" => "custom", "custom_colors" => "#112233", "custom_open_color" => "blue").first)
    assert_match(/closed/i, errors_for("palette_preset" => "custom", "custom_colors" => "#112233", "custom_closed_color" => "#zzz").first)
    assert_match(/neutral/i, errors_for("palette_preset" => "custom", "custom_colors" => "#112233", "custom_neutral_color" => "12").first)
  end

  def test_custom_values_are_not_checked_when_another_preset_is_chosen
    assert_empty errors_for("palette_preset" => "material", "custom_colors" => "nonsense", "custom_open_color" => "blue")
  end

  def test_the_saved_setting_is_read_when_no_hash_is_given
    original = Setting.plugin_redmine_rubylode_stats
    Setting.plugin_redmine_rubylode_stats = { "palette_preset" => "color_blind_safe" }

    assert_equal "color_blind_safe", RubylodeStats::Settings.new.palette_preset
  ensure
    Setting.plugin_redmine_rubylode_stats = original
  end
end
