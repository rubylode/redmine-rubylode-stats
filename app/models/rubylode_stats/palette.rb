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
  # The colours of the charts, as the page hands them to the script: a light and a dark set, each with ten categorical
  # colours and the roles open, closed and neutral. The script draws with these unless the theme defines its own
  # (see "Follow the theme" in the README). Every colour keeps 3:1 contrast against a white page (light set) or a #1E1E1E
  # page (dark set); test/unit/palette_test.rb checks it.
  class Palette
    CUSTOM_NEUTRAL = "#8A8A8A".freeze

    PRESETS = {
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
      # Okabe and Ito's set, safe for the common kinds of colour blindness. Black becomes grey, and on a light page orange,
      # sky blue and yellow are darkened until they keep 3:1 against white.
      "colour_blind_safe" => {
        "light" => {
          "categorical" => %w[#0072B2 #D55E00 #009E73 #CB75A5 #C28600 #1D99E0 #9C920C #919191],
          "open" => "#0072B2", "closed" => "#009E73", "neutral" => "#919191"
        },
        "dark" => {
          "categorical" => %w[#0072B2 #D55E00 #009E73 #CC79A7 #E69F00 #56B4E9 #F0E442 #999999],
          "open" => "#56B4E9", "closed" => "#009E73", "neutral" => "#999999"
        }
      },
      # Saturated categorical colours in the style of the wpdatatables palettes (Dutch Field, River Nights, Retro Metro).
      "data_visualisation" => {
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

    FALLBACK_PRESET = "material".freeze

    # variants: { "light" => set, "dark" => set }; follow_theme: whether the script should look for the theme's own colours first.
    def initialize(variants:, follow_theme:)
      @variants = variants
      @follow_theme = follow_theme
    end

    def self.preset(name, follow_theme: false)
      new(variants: PRESETS.fetch(name), follow_theme: follow_theme)
    end

    # A palette from a list of hex colours (already normalised) and optional role colours; both variants are the same.
    def self.custom(colours:, open: nil, closed: nil, neutral: nil)
      return preset(FALLBACK_PRESET) if colours.empty?

      set = {
        "categorical" => colours,
        "open" => open || colours.first,
        "closed" => closed || colours[1] || colours.first,
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
