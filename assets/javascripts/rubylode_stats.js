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

/*
 * Draws every .stats-chart on the page with vega-embed. The specification travels in the element's data-specification
 * attribute. Colours come from the theme's CSS variables when the theme defines them; the light or dark set is chosen from
 * the system colour scheme, and the charts are drawn again when it changes.
 */
(function () {
  var darkSchemeQuery = window.matchMedia("(prefers-color-scheme: dark)");

  function themeColor(variableName, fallback) {
    var value = getComputedStyle(document.documentElement).getPropertyValue(variableName).trim();
    return value || fallback;
  }

  function chartConfiguration() {
    var dark = darkSchemeQuery.matches;
    var text = themeColor("--rubylode-text-color", dark ? "#e6e6e6" : "#333333");
    var background = themeColor("--rubylode-background-color", dark ? "#1e1e1e" : "#ffffff");
    var grid = themeColor("--rubylode-border-color", dark ? "#444444" : "#dddddd");
    return {
      background: background,
      title: { color: text },
      axis: { labelColor: text, titleColor: text, domainColor: grid, gridColor: grid, tickColor: grid },
      legend: { labelColor: text, titleColor: text },
      view: { stroke: grid },
      range: {
        category: dark
          ? ["#6fa8dc", "#f6b26b", "#93c47d", "#e06666", "#b4a7d6", "#ffd966", "#76a5af", "#c27ba0"]
          : ["#2f6fb0", "#e69138", "#6aa84f", "#cc0000", "#674ea7", "#bf9000", "#45818e", "#a64d79"]
      }
    };
  }

  function drawCharts() {
    document.querySelectorAll(".stats-chart").forEach(function (element) {
      var specification = JSON.parse(element.dataset.specification);
      vegaEmbed(element, specification, { actions: false, config: chartConfiguration() });
    });
  }

  document.addEventListener("DOMContentLoaded", drawCharts);
  darkSchemeQuery.addEventListener("change", drawCharts);
})();
