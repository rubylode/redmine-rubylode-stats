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
 * attribute. The text, grid and font come from the theme's CSS variables, each with a fallback; the fallback light or dark set
 * follows the system color scheme. The chart colors come from rubylode_stats_palette.js (the plugin's palette, or the theme's
 * --theme-chart-* properties), read again on every draw. The charts are drawn again when that changes and when the window is resized, so they
 * always fill their card. The button of the filter bar shows and hides the filter panel.
 *
 * The charts answer the pointer: a tooltip with the figures of the mark, the mark under the pointer emphasized (the
 * specification carries that), a click on a bar, point or slice opens the ticket list its "href" holds (a ctrl or cmd click
 * in a new tab). Numbers and month names follow the page's language (the lang attribute of the page). The tooltip is styled by
 * custom properties (see the stylesheet), so it follows the theme.
 */
(function () {
  var darkSchemeQuery = window.matchMedia("(prefers-color-scheme: dark)");
  var resizeTimer = null;
  var drawnViews = [];

  function themeColor(variableName, fallback) {
    var value = getComputedStyle(document.documentElement).getPropertyValue(variableName).trim();
    return value || fallback;
  }

  function readCustomProperty(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  function currentPalette() {
    var element = document.querySelector("[data-palette]");
    var payload = element ? JSON.parse(element.dataset.palette) : null;
    return payload ? window.RubylodeStatsPalette.resolve(payload, readCustomProperty, darkSchemeQuery.matches) : null;
  }

  function chartConfiguration(palette) {
    var dark = darkSchemeQuery.matches;
    var text = themeColor("--oc-gray-9", dark ? "#e6e6e6" : "#212529");
    var background = themeColor("--oc-white", dark ? "#1e1e1e" : "#ffffff");
    var grid = themeColor("--oc-gray-3", dark ? "#444444" : "#dee2e6");
    var axis = themeColor("--oc-gray-4", dark ? "#555555" : "#ced4da");
    var font = themeColor("--fonts-main", "sans-serif");
    return Object.assign({
      background: background,
      font: font,
      title: { color: text, font: font },
      axis: { labelColor: text, titleColor: text, labelFont: font, titleFont: font, domainColor: axis, tickColor: axis, gridColor: grid },
      legend: { labelColor: text, titleColor: text, labelFont: font, titleFont: font },
      text: { color: text, font: font },
      view: { stroke: "transparent" }
    }, palette ? window.RubylodeStatsPalette.colorConfiguration(palette) : {});
  }

  function pageLanguage() {
    return document.documentElement.lang || navigator.language || "en";
  }

  // Vega's number and time formats in the page's language, built from the browser's own knowledge of it. A language the
  // browser does not know leaves Vega's English.
  function formatLocales() {
    try {
      var language = pageLanguage();
      var numberParts = new Intl.NumberFormat(language).formatToParts(1234567.5);
      var partValue = function (type, fallback) {
        var part = numberParts.find(function (candidate) { return candidate.type === type; });
        return part ? part.value : fallback;
      };
      var monthNames = function (style) {
        return Array.from({ length: 12 }, function (_, month) {
          return new Intl.DateTimeFormat(language, { month: style, timeZone: "UTC" }).format(new Date(Date.UTC(2021, month, 15)));
        });
      };
      // 2021-08-01 was a Sunday, and Vega's week starts on Sunday.
      var dayNames = function (style) {
        return Array.from({ length: 7 }, function (_, day) {
          return new Intl.DateTimeFormat(language, { weekday: style, timeZone: "UTC" }).format(new Date(Date.UTC(2021, 7, 1 + day)));
        });
      };
      return {
        number: { decimal: partValue("decimal", "."), thousands: partValue("group", ","), grouping: [3], currency: ["", ""] },
        time: {
          dateTime: "%x, %X", date: "%Y-%m-%d", time: "%H:%M:%S", periods: ["AM", "PM"],
          days: dayNames("long"), shortDays: dayNames("short"), months: monthNames("long"), shortMonths: monthNames("short")
        }
      };
    } catch (error) {
      return null;
    }
  }

  // Charts that do not fix their own width fill the card, so they follow it when the window changes.
  function withContainerWidth(specification) {
    var fixedShape = specification.width !== undefined || specification.hconcat || (specification.mark && specification.mark.type === "arc");
    if (!fixedShape) { specification.width = "container"; }
    return specification;
  }

  function embedOptions(palette) {
    var options = {
      actions: false,
      config: chartConfiguration(palette),
      renderer: "svg",
      tooltip: { theme: "stats", offsetX: 12, offsetY: 12 }
    };
    var locales = formatLocales();
    if (locales) {
      options.formatLocale = locales.number;
      options.timeFormatLocale = locales.time;
    }
    return options;
  }

  function drawCharts() {
    drawnViews.forEach(function (result) { result.finalize(); });
    drawnViews = [];
    var palette = currentPalette();
    var options = embedOptions(palette);
    document.querySelectorAll(".stats-chart").forEach(function (element) {
      var specification = JSON.parse(element.dataset.specification);
      if (palette) { specification = window.RubylodeStatsPalette.applyTokens(specification, palette); }
      specification = withContainerWidth(specification);
      vegaEmbed(element, specification, options).then(function (result) { drawnViews.push(result); });
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
