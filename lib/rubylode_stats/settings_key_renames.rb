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

module RubylodeStats
  # The 2.0.0 renames of the saved settings: British to US spelling in four keys and in two preset values.
  # The migration in db/migrate calls forward on upgrade and reverse on rollback; neither touches a key it does not know.
  module SettingsKeyRenames
    KEYS = {
      "custom_colours" => "custom_colors",
      "custom_open_colour" => "custom_open_color",
      "custom_closed_colour" => "custom_closed_color",
      "custom_neutral_colour" => "custom_neutral_color"
    }.freeze

    PRESET_VALUES = {
      "colour_blind_safe" => "color_blind_safe",
      "data_visualisation" => "data_visualization"
    }.freeze

    def self.forward(values)
      rename(values, KEYS, PRESET_VALUES)
    end

    def self.reverse(values)
      rename(values, KEYS.invert, PRESET_VALUES.invert)
    end

    # A key already in its new spelling wins over the old one left beside it.
    def self.rename(values, keys, preset_values)
      renamed = values.to_h.stringify_keys
      keys.each do |from, to|
        next unless renamed.key?(from)

        value = renamed.delete(from)
        renamed[to] = value unless renamed.key?(to)
      end
      renamed["palette_preset"] = preset_values.fetch(renamed["palette_preset"], renamed["palette_preset"]) if renamed.key?("palette_preset")
      renamed
    end
    private_class_method :rename
  end
end
