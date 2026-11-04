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
require File.expand_path("../../db/migrate/001_rename_color_settings_keys", __dir__)

class SettingsKeyRenamesTest < ActiveSupport::TestCase
  OLD_VALUES = {
    "palette_preset" => "colour_blind_safe",
    "custom_colours" => "#112233, #445566",
    "custom_open_colour" => "#112233",
    "custom_closed_colour" => "#445566",
    "custom_neutral_colour" => "#778899"
  }.freeze

  NEW_VALUES = {
    "palette_preset" => "color_blind_safe",
    "custom_colors" => "#112233, #445566",
    "custom_open_color" => "#112233",
    "custom_closed_color" => "#445566",
    "custom_neutral_color" => "#778899"
  }.freeze

  def test_forward_renames_every_key_and_the_two_preset_values
    assert_equal NEW_VALUES, RubylodeStats::SettingsKeyRenames.forward(OLD_VALUES)
    assert_equal "data_visualization", RubylodeStats::SettingsKeyRenames.forward("palette_preset" => "data_visualisation")["palette_preset"]
  end

  def test_reverse_puts_the_old_keys_and_preset_values_back
    assert_equal OLD_VALUES, RubylodeStats::SettingsKeyRenames.reverse(NEW_VALUES)
    assert_equal "data_visualisation", RubylodeStats::SettingsKeyRenames.reverse("palette_preset" => "data_visualization")["palette_preset"]
  end

  def test_forward_leaves_other_values_and_unknown_keys_alone
    values = { "palette_preset" => "material", "custom_colours" => "", "somebody_elses_key" => "kept" }

    assert_equal({ "palette_preset" => "material", "custom_colors" => "", "somebody_elses_key" => "kept" }, RubylodeStats::SettingsKeyRenames.forward(values))
  end

  def test_forward_twice_changes_nothing_more
    once = RubylodeStats::SettingsKeyRenames.forward(OLD_VALUES)

    assert_equal once, RubylodeStats::SettingsKeyRenames.forward(once)
  end

  def test_a_new_key_wins_over_an_old_one_left_beside_it
    values = { "custom_colours" => "#111111", "custom_colors" => "#222222" }

    assert_equal({ "custom_colors" => "#222222" }, RubylodeStats::SettingsKeyRenames.forward(values))
  end
end

class RenameColorSettingsKeysMigrationTest < ActiveSupport::TestCase
  def setup
    @original = Setting.plugin_redmine_rubylode_stats
    @row_existed = Setting.where(name: "plugin_redmine_rubylode_stats").exists?
    ActiveRecord::Migration.verbose = false
  end

  def teardown
    ActiveRecord::Migration.verbose = true
    @row_existed ? Setting.plugin_redmine_rubylode_stats = @original : Setting.where(name: "plugin_redmine_rubylode_stats").delete_all
  end

  def test_up_moves_the_saved_values_to_the_new_keys
    Setting.plugin_redmine_rubylode_stats = SettingsKeyRenamesTest::OLD_VALUES

    RenameColorSettingsKeys.new.up

    assert_equal SettingsKeyRenamesTest::NEW_VALUES, Setting.plugin_redmine_rubylode_stats
  end

  def test_down_moves_them_back
    Setting.plugin_redmine_rubylode_stats = SettingsKeyRenamesTest::NEW_VALUES

    RenameColorSettingsKeys.new.down

    assert_equal SettingsKeyRenamesTest::OLD_VALUES, Setting.plugin_redmine_rubylode_stats
  end

  def test_up_saves_nothing_when_no_settings_were_ever_saved
    Setting.where(name: "plugin_redmine_rubylode_stats").delete_all

    RenameColorSettingsKeys.new.up

    assert_not Setting.where(name: "plugin_redmine_rubylode_stats").exists?
  end
end
