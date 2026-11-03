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
  # The plugin's settings (Administration, Plugins, Configure), read with their defaults and checked before they are saved.
  # Redmine keeps them as one hash under Setting.plugin_redmine_rubylode_stats; anything missing or unusable falls back to the
  # default, so an upgrade with no stored keys works.
  class PluginSettings
    PLUGIN_ID = :redmine_rubylode_stats
    PRESET_CHOICES = %w[follow_theme material colour_blind_safe data_visualisation custom].freeze
    MAXIMUM_CUSTOM_COLOURS = 10
    HEX_COLOUR = /\A#(\h{3}|\h{6})\z/

    DEFAULTS = {
      "palette_preset" => "follow_theme",
      "custom_colours" => "",
      "custom_open_colour" => "",
      "custom_closed_colour" => "",
      "custom_neutral_colour" => ""
    }.freeze

    ROLE_KEYS = { "open" => "custom_open_colour", "closed" => "custom_closed_colour", "neutral" => "custom_neutral_colour" }.freeze

    # An unsaved hash can be passed in (the settings form on a failed save, tests); by default the saved one is read.
    def initialize(values = nil)
      @values = (values || saved_values).to_h.stringify_keys
    end

    def self.errors_for(values)
      new(values).errors
    end

    def errors
      return [I18n.t(:rubylode_stats_error_palette_preset, value: raw_preset)] unless PRESET_CHOICES.include?(raw_preset)
      return [] unless raw_preset == "custom"

      custom_colour_errors + role_colour_errors
    end

    def valid? = errors.empty?

    # An unknown value reads as the default, so a hand-written bad value never breaks the page.
    def palette_preset
      PRESET_CHOICES.include?(raw_preset) ? raw_preset : DEFAULTS["palette_preset"]
    end

    def palette
      case palette_preset
      when "follow_theme" then Palette.preset(Palette::FALLBACK_PRESET, follow_theme: true)
      when "custom" then custom_palette
      else Palette.preset(palette_preset)
      end
    end

    private

    def custom_palette
      Palette.custom(
        colours: listed_colours.filter_map { |colour| normalised(colour) }.first(MAXIMUM_CUSTOM_COLOURS),
        open: normalised(@values["custom_open_colour"]),
        closed: normalised(@values["custom_closed_colour"]),
        neutral: normalised(@values["custom_neutral_colour"])
      )
    end

    def raw_preset
      @values.fetch("palette_preset", DEFAULTS["palette_preset"]).to_s
    end

    def listed_colours
      @values["custom_colours"].to_s.split(",").map(&:strip).reject(&:empty?)
    end

    def custom_colour_errors
      colours = listed_colours
      return [I18n.t(:rubylode_stats_error_custom_colours_missing)] if colours.empty?

      messages = []
      messages << I18n.t(:rubylode_stats_error_custom_colours_too_many, count: MAXIMUM_CUSTOM_COLOURS) if colours.size > MAXIMUM_CUSTOM_COLOURS
      invalid = colours.reject { |colour| colour.match?(HEX_COLOUR) }
      messages << I18n.t(:rubylode_stats_error_custom_colours_invalid, values: invalid.join(", ")) if invalid.any?
      messages
    end

    def role_colour_errors
      ROLE_KEYS.filter_map do |role, key|
        value = @values[key].to_s.strip
        next if value.empty? || value.match?(HEX_COLOUR)

        I18n.t(:rubylode_stats_error_role_colour, role: role, value: value)
      end
    end

    # "#abc" becomes "#AABBCC"; nil for an empty or unusable value.
    def normalised(value)
      text = value.to_s.strip
      return unless text.match?(HEX_COLOUR)

      digits = text.delete("#")
      digits = digits.chars.map { |digit| digit * 2 }.join if digits.size == 3
      "##{digits.upcase}"
    end

    def saved_values
      Setting.send(:"plugin_#{PLUGIN_ID}") || {}
    end
  end
end
