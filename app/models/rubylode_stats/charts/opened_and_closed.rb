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

module RubylodeStats
  module Charts
    # Tickets opened and closed per period as two lines, with the backlog (opened minus closed, cumulative) as a third.
    # A click on a legend entry hides or shows its line.
    class OpenedAndClosed < Base
      SERIES = %w[opened closed backlog].freeze
      AXIS_FORMATS = { "day" => "%b %d", "week" => "%b %d", "month" => "%b %Y" }.freeze

      def specification
        {
          "$schema" => SCHEMA,
          "width" => "container",
          "data" => { "values" => rows },
          "transform" => [
            { "fold" => SERIES, "as" => ["series_key", "tickets"] },
            { "calculate" => series_label_expression, "as" => "series" }
          ],
          "layer" => [bars, backlog_line]
        }
      end

      def wide?
        true
      end

      private

      # Opened and closed are bars side by side in each period; the backlog is a line over them.
      def bars
        {
          "params" => legend_toggle_params("series"),
          "transform" => [{ "filter" => "datum.series_key !== 'backlog'" }],
          "mark" => { "type" => "bar", "tooltip" => true, "cornerRadiusEnd" => 2 },
          "encoding" => shared_encoding.merge("xOffset" => { "field" => "series" })
        }
      end

      def backlog_line
        {
          "transform" => [{ "filter" => "datum.series_key === 'backlog'" }],
          "mark" => { "type" => "line", "point" => true, "tooltip" => true, "strokeWidth" => 2.5 },
          "encoding" => shared_encoding
        }
      end

      def shared_encoding
        {
          "x" => { "field" => "period", "type" => "ordinal", "timeUnit" => "yearmonthdate", "title" => period_label,
                   "axis" => { "format" => AXIS_FORMATS.fetch(period) } },
          "y" => { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) },
          "color" => { "field" => "series", "type" => "nominal", "title" => nil, "scale" => { "domain" => series_labels } },
          "opacity" => legend_toggle_opacity,
          "tooltip" => [
            { "field" => "period", "type" => "temporal", "title" => period_label },
            { "field" => "series", "type" => "nominal", "title" => nil },
            { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) }
          ]
        }
      end

      def period
        options.fetch(:period, Registry::DEFAULT_PERIOD)
      end

      def period_label
        I18n.t("label_stats_period_#{period}")
      end

      def series_labels
        SERIES.map { |series| I18n.t("label_stats_series_#{series}") }
      end

      def series_label_expression
        SERIES.zip(series_labels).map { |key, label| "datum.series_key === '#{key}' ? #{label.to_json} : " }.join + "datum.series_key"
      end

      def rows
        time_zone = options.fetch(:time_zone) { ActiveSupport::TimeZone["UTC"] }
        OpenedAndClosedRows.new(query, period: period, time_zone: time_zone).rows
      end
    end
  end
end
