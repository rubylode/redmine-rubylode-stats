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

class PaletteTest < ActiveSupport::TestCase
  LIGHT_PAGE = "#ffffff".freeze
  DARK_PAGE = "#1e1e1e".freeze
  MINIMUM_GRAPHICS_CONTRAST = 3.0

  def build_palette(values = {})
    RubylodeStats::PluginSettings.new(values).palette
  end

  def relative_luminance(hex)
    red, green, blue = hex.delete("#").scan(/../).map { |pair| pair.to_i(16) / 255.0 }
    linear = [red, green, blue].map { |value| value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4 }
    (0.2126 * linear[0]) + (0.7152 * linear[1]) + (0.0722 * linear[2])
  end

  def contrast_ratio(first, second)
    lighter, darker = [relative_luminance(first), relative_luminance(second)].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  def test_with_no_stored_keys_the_palette_follows_the_theme_and_falls_back_to_material
    palette = build_palette({})

    assert palette.follow_theme?
    assert_equal RubylodeStats::Palette::PRESETS.fetch("material"), palette.to_h.slice("light", "dark")
  end

  def test_the_material_preset_has_ten_distinct_colours_with_a_light_and_a_dark_variant
    material = RubylodeStats::Palette::PRESETS.fetch("material")

    assert_equal 10, material["light"]["categorical"].size
    assert_equal 10, material["dark"]["categorical"].size
    assert_equal 10, material["light"]["categorical"].uniq.size
    refute_equal material["light"]["categorical"], material["dark"]["categorical"]
  end

  def test_the_choosable_presets_use_the_preset_named_in_the_setting
    %w[material colour_blind_safe data_visualisation].each do |preset|
      palette = build_palette("palette_preset" => preset)

      refute palette.follow_theme?, preset
      assert_equal RubylodeStats::Palette::PRESETS.fetch(preset), palette.to_h.slice("light", "dark"), preset
    end
  end

  def test_the_colour_blind_safe_dark_variant_is_the_okabe_ito_set_with_grey_for_black
    dark = RubylodeStats::Palette::PRESETS.fetch("colour_blind_safe")["dark"]["categorical"]

    assert_equal %w[#0072B2 #D55E00 #009E73 #CC79A7 #E69F00 #56B4E9 #F0E442 #999999], dark
  end

  def test_an_unknown_preset_reads_as_following_the_theme
    assert build_palette("palette_preset" => "neon").follow_theme?
  end

  def test_every_preset_keeps_graphics_contrast_against_the_page_in_light_and_dark
    RubylodeStats::Palette::PRESETS.each do |preset, variants|
      { "light" => LIGHT_PAGE, "dark" => DARK_PAGE }.each do |variant, page|
        set = variants.fetch(variant)
        colours = set["categorical"] + set.values_at("open", "closed", "neutral")
        colours.each do |colour|
          assert_operator contrast_ratio(colour, page), :>=, MINIMUM_GRAPHICS_CONTRAST, "#{preset} #{variant} #{colour} on #{page}"
        end
      end
    end
  end

  def test_the_neutral_grey_of_a_custom_palette_keeps_graphics_contrast_in_both_variants
    assert_operator contrast_ratio(RubylodeStats::Palette::CUSTOM_NEUTRAL, LIGHT_PAGE), :>=, MINIMUM_GRAPHICS_CONTRAST
    assert_operator contrast_ratio(RubylodeStats::Palette::CUSTOM_NEUTRAL, DARK_PAGE), :>=, MINIMUM_GRAPHICS_CONTRAST
  end

  def test_adjacent_categories_differ_in_every_preset
    RubylodeStats::Palette::PRESETS.each_value do |variants|
      variants.each_value do |set|
        set["categorical"].each_cons(2) { |first, second| refute_equal first, second }
      end
    end
  end

  def test_a_custom_palette_uses_the_listed_colours_in_both_variants_and_expands_short_hex
    palette = build_palette("palette_preset" => "custom", "custom_colours" => "#f00, #00ff00 ,#0000FF")

    assert_equal %w[#FF0000 #00FF00 #0000FF], palette.to_h["light"]["categorical"]
    assert_equal palette.to_h["light"]["categorical"], palette.to_h["dark"]["categorical"]
  end

  def test_a_custom_palette_takes_open_and_closed_from_its_first_two_colours_and_a_neutral_grey
    set = build_palette("palette_preset" => "custom", "custom_colours" => "#111111,#222222").to_h["light"]

    assert_equal "#111111", set["open"]
    assert_equal "#222222", set["closed"]
    assert_equal RubylodeStats::Palette::CUSTOM_NEUTRAL, set["neutral"]
  end

  def test_a_custom_palette_with_one_colour_uses_it_for_open_and_closed
    set = build_palette("palette_preset" => "custom", "custom_colours" => "#336699").to_h["light"]

    assert_equal "#336699", set["open"]
    assert_equal "#336699", set["closed"]
  end

  def test_custom_role_colours_override_the_fallbacks
    set = build_palette("palette_preset" => "custom", "custom_colours" => "#111111,#222222", "custom_open_colour" => "#abc",
                        "custom_closed_colour" => "#ddeeff", "custom_neutral_colour" => "#808080").to_h["light"]

    assert_equal "#AABBCC", set["open"]
    assert_equal "#DDEEFF", set["closed"]
    assert_equal "#808080", set["neutral"]
  end

  def test_a_custom_preset_with_nothing_usable_falls_back_to_material
    palette = build_palette("palette_preset" => "custom", "custom_colours" => "")

    assert_equal RubylodeStats::Palette::PRESETS.fetch("material"), palette.to_h.slice("light", "dark")
  end

  def test_the_palette_serialises_for_the_page
    data = JSON.parse(build_palette({}).to_json)

    assert_equal true, data["follow_theme"]
    assert_equal 10, data["light"]["categorical"].size
    assert data["dark"]["neutral"].start_with?("#")
  end
end
