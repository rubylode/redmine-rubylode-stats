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
 * Draws every .stats-chart on the page with vega-embed. The specification travels in the element's data-specification
 * attribute. Colours and the font come from the theme's CSS variables, each with a fallback; the fallback light or dark set
 * follows the system colour scheme. The charts are drawn again when that changes and when the window is resized, so they
 * always fill their card. The button of the filter bar shows and hides the filter panel.
 */
(function () {
  var darkSchemeQuery = window.matchMedia("(prefers-color-scheme: dark)");
  var resizeTimer = null;

  function themeColor(variableName, fallback) {
    var value = getComputedStyle(document.documentElement).getPropertyValue(variableName).trim();
    return value || fallback;
  }

  function chartConfiguration() {
    var dark = darkSchemeQuery.matches;
    var text = themeColor("--oc-gray-9", dark ? "#e6e6e6" : "#212529");
    var background = themeColor("--oc-white", dark ? "#1e1e1e" : "#ffffff");
    var grid = themeColor("--oc-gray-3", dark ? "#444444" : "#dee2e6");
    var axis = themeColor("--oc-gray-4", dark ? "#555555" : "#ced4da");
    var neutral = themeColor("--oc-gray-5", dark ? "#868e96" : "#adb5bd");
    var accent = themeColor("--oc-blue-7", dark ? "#6fa8dc" : "#1c7ed6");
    var font = themeColor("--fonts-main", "sans-serif");
    return {
      background: background,
      font: font,
      title: { color: text, font: font },
      axis: { labelColor: text, titleColor: text, labelFont: font, titleFont: font, domainColor: axis, tickColor: axis, gridColor: grid },
      legend: { labelColor: text, titleColor: text, labelFont: font, titleFont: font },
      text: { color: text, font: font },
      view: { stroke: "transparent" },
      bar: { fill: accent },
      arc: { fill: neutral },
      range: {
        category: dark
          ? ["#6fa8dc", "#f6b26b", "#93c47d", "#e06666", "#b4a7d6", "#ffd966", "#76a5af", "#c27ba0"]
          : ["#2f6fb0", "#e69138", "#6aa84f", "#cc0000", "#674ea7", "#bf9000", "#45818e", "#a64d79"]
      }
    };
  }

  // Charts that do not fix their own width fill the card, so they follow it when the window changes.
  function withContainerWidth(specification) {
    var fixedShape = specification.width !== undefined || specification.hconcat || (specification.mark && specification.mark.type === "arc");
    if (!fixedShape) { specification.width = "container"; }
    return specification;
  }

  function drawCharts() {
    document.querySelectorAll(".stats-chart").forEach(function (element) {
      var specification = withContainerWidth(JSON.parse(element.dataset.specification));
      vegaEmbed(element, specification, { actions: false, config: chartConfiguration() });
    });
  }

  function drawChartsAfterResize() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(drawCharts, 150);
  }

  function wireFilterToggle() {
    var button = document.querySelector(".stats-filters-toggle");
    var panel = document.getElementById("stats-filters-panel");
    if (!button || !panel) { return; }
    button.addEventListener("click", function () {
      var expanded = button.getAttribute("aria-expanded") === "true";
      button.setAttribute("aria-expanded", expanded ? "false" : "true");
      panel.hidden = expanded;
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    wireFilterToggle();
    drawCharts();
  });
  darkSchemeQuery.addEventListener("change", drawCharts);
  window.addEventListener("resize", drawChartsAfterResize);
})();
