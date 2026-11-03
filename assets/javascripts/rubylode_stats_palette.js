/*
 * Rubylode Stats: charts over a project's tickets, for Redmine
 * Copyright (C) 2026  Nick Gorbikoff
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/*
 * Chooses the colours of the charts. The server sends the plugin's palette (a light and a dark set, see
 * RubylodeStats::Palette) in the data-palette attribute. When the setting follows the theme and the page defines
 * --theme-chart-1, the theme's colours win: --theme-chart-1 to --theme-chart-10 for categories and --theme-chart-open,
 * --theme-chart-closed and --theme-chart-neutral for the roles. The chart specifications name colours as tokens
 * ("role:open", "role:closed", "role:neutral", "category:3"), which applyTokens turns into the chosen colours. The functions
 * take what they read as arguments, so they run under Node as well (test/javascript).
 */
(function (root) {
  var CATEGORY_COUNT = 10;
  var THEME_ROLE_PROPERTIES = { open: "--theme-chart-open", closed: "--theme-chart-closed", neutral: "--theme-chart-neutral" };

  // readProperty(name) returns the value of a CSS custom property, or an empty string.
  function resolve(payload, readProperty, dark) {
    var variant = (dark ? payload.dark : payload.light) || payload.light;
    if (payload.follow_theme && readProperty("--theme-chart-1")) {
      var categorical = [];
      for (var number = 1; number <= CATEGORY_COUNT; number += 1) {
        var colour = readProperty("--theme-chart-" + number);
        if (colour) { categorical.push(colour); }
      }
      return {
        categorical: categorical,
        open: readProperty(THEME_ROLE_PROPERTIES.open) || categorical[0],
        closed: readProperty(THEME_ROLE_PROPERTIES.closed) || categorical[1] || categorical[0],
        neutral: readProperty(THEME_ROLE_PROPERTIES.neutral) || variant.neutral
      };
    }
    return { categorical: variant.categorical, open: variant.open, closed: variant.closed, neutral: variant.neutral };
  }

  // A copy of the specification with each colour token replaced. Categories wrap after the last colour.
  function applyTokens(specification, palette) {
    return JSON.parse(JSON.stringify(specification), function (key, value) {
      if (typeof value !== "string") { return value; }
      var role = /^role:(open|closed|neutral)$/.exec(value);
      if (role) { return palette[role[1]]; }
      var category = /^category:(\d+)$/.exec(value);
      if (category) { return palette.categorical[(Number(category[1]) - 1) % palette.categorical.length]; }
      return value;
    });
  }

  // The parts of the chart configuration that carry colour: single-series marks take the first colour, and charts that colour
  // by category take the palette in order.
  function colourConfiguration(palette) {
    return { mark: { color: palette.categorical[0] }, range: { category: palette.categorical } };
  }

  var api = { resolve: resolve, applyTokens: applyTokens, colourConfiguration: colourConfiguration };
  root.RubylodeStatsPalette = api;
})(typeof window !== "undefined" ? window : globalThis);
