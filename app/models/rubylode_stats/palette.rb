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
  # The colors of the charts, as the page hands them to the script: a light and a dark set, each with ten categorical
  # colors and the roles open, closed and neutral. The script draws with these unless the theme defines its own
  # (see "Follow the theme" in the README). Every color keeps 3:1 contrast against a white page (light set) or a #1E1E1E
  # page (dark set); test/unit/palette_test.rb checks it.
  class Palette
    CUSTOM_NEUTRAL = "#8A8A8A".freeze

    PRESETS = {
      # An original muted set in the manner of editorial newsroom graphics: restrained hues, one idea per color, a gray for
      # context. The light set keeps 3:1 against white, the dark set 3:1 against #1E1E1E. It is not any publisher's palette.
      "editorial" => {
        "light" => {
          "categorical" => %w[#2F6C9F #D4662A #3F8F6B #B5493F #7A5C9A #B88C27 #4F9AA0 #8C6D5A #6B7F94 #8E959B],
          "open" => "#2F6C9F", "closed" => "#3F8F6B", "neutral" => "#8E959B"
        },
        "dark" => {
          "categorical" => %w[#6FA3D0 #EE9A63 #7CC09E #E08A82 #A98CC9 #E3BE63 #86C4C9 #BBA08F #9FB0C2 #B4BAC0],
          "open" => "#6FA3D0", "closed" => "#7CC09E", "neutral" => "#8A9199"
        }
      },
      # Material Design hues: the 600 to 700 shades on a light page, the 300 to 400 shades on a dark one. The order puts
      # unlike hues next to each other.
      "material" => {
        "light" => {
          "categorical" => %w[#1E88E5 #EA6A00 #00897B #D81B60 #689F38 #8E24AA #0097A7 #3949AB #6D4C41 #546E7A],
          "open" => "#1E88E5", "closed" => "#43A047", "neutral" => "#78909C"
        },
        "dark" => {
          "categorical" => %w[#64B5F6 #FFA726 #4DB6AC #F06292 #9CCC65 #BA68C8 #4DD0E1 #7986CB #A1887F #90A4AE],
          "open" => "#64B5F6", "closed" => "#81C784", "neutral" => "#90A4AE"
        }
      },
      # Okabe and Ito's set, safe for the common kinds of color blindness. Black becomes gray, and on a light page orange,
      # sky blue and yellow are darkened until they keep 3:1 against white.
      "color_blind_safe" => {
        "light" => {
          "categorical" => %w[#0072B2 #D55E00 #009E73 #CB75A5 #C28600 #1D99E0 #9C920C #919191],
          "open" => "#0072B2", "closed" => "#009E73", "neutral" => "#919191"
        },
        "dark" => {
          "categorical" => %w[#0072B2 #D55E00 #009E73 #CC79A7 #E69F00 #56B4E9 #F0E442 #999999],
          "open" => "#56B4E9", "closed" => "#009E73", "neutral" => "#999999"
        }
      },
      # Saturated categorical colors in the style of the wpdatatables palettes (Dutch Field, River Nights, Retro Metro).
      "data_visualization" => {
        "light" => {
          "categorical" => %w[#1A53FF #CC8200 #00A58B #E60049 #9B19F5 #0098DC #899623 #DC0AB4 #7C1158 #729F39],
          "open" => "#1A53FF", "closed" => "#00A58B", "neutral" => "#8A8A8A"
        },
        "dark" => {
          "categorical" => %w[#245BFF #FFA300 #00BFA0 #E60049 #9D1EF5 #0BB4FF #BDCF32 #DC0AB4 #C81B8E #87BC45],
          "open" => "#0BB4FF", "closed" => "#00BFA0", "neutral" => "#9A9A9A"
        }
      }
    }.freeze

    FALLBACK_PRESET = "editorial".freeze

    # variants: { "light" => set, "dark" => set }; follow_theme: whether the script should look for the theme's own colors first.
    def initialize(variants:, follow_theme:)
      @variants = variants
      @follow_theme = follow_theme
    end

    def self.preset(name, follow_theme: false)
      new(variants: PRESETS.fetch(name), follow_theme: follow_theme)
    end

    # A palette from a list of hex colors (already normalized) and optional role colors; both variants are the same.
    def self.custom(colors:, open: nil, closed: nil, neutral: nil)
      return preset(FALLBACK_PRESET) if colors.empty?

      set = {
        "categorical" => colors,
        "open" => open || colors.first,
        "closed" => closed || colors[1] || colors.first,
        "neutral" => neutral || CUSTOM_NEUTRAL
      }
      new(variants: { "light" => set, "dark" => set }, follow_theme: false)
    end

    def follow_theme? = @follow_theme

    def to_h
      { "follow_theme" => @follow_theme }.merge(@variants)
    end

    def to_json(*arguments) = to_h.to_json(*arguments)
  end
end
