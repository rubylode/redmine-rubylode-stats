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
  module Charts
    # Tickets opened and closed per period as two bars side by side, with the backlog (opened minus closed, cumulative) as a
    # line over them. A click on a legend entry hides or shows its series. A bar links to the issue list of the tickets created
    # (opened) or closed (closed) in that period; the backlog has no list to open, because the issue list cannot show the
    # backlog as it stood at the end of a past period. The tooltip names the period, the three figures and what each changed
    # against the previous period.
    class OpenedAndClosed < Base
      SERIES = %w[opened closed backlog].freeze
      AXIS_FORMATS = { "day" => "%b %d", "week" => "%b %d", "month" => "%b %Y" }.freeze

      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "width" => "container",
          "data" => { "values" => rows_with_links },
          "transform" => [
            { "fold" => SERIES, "as" => ["series_key", "tickets"] },
            { "calculate" => series_label_expression, "as" => "series" },
            { "calculate" => "datum.series_key === 'opened' ? datum.opened_url : datum.closed_url", "as" => "url" }
          ],
          "layer" => [bars, backlog_line]
        }
      end

      def wide?
        true
      end

      def data_table
        DataTable.new(
          headers: [period_label, I18n.t(:label_stats_series_opened), I18n.t(:label_stats_series_closed), I18n.t(:label_stats_series_backlog),
                    I18n.t(:label_stats_table_tickets)],
          rows: rows_with_links.map do |row|
            DataTable.row(
              [row["period_text"], *SERIES.map { |series| "#{count_text(row[series])} (#{row["#{series}_change_text"]})" }],
              [I18n.t(:label_stats_table_open_opened), row["opened_url"]], [I18n.t(:label_stats_table_open_closed), row["closed_url"]]
            )
          end
        )
      end

      private

      # Opened and closed are bars side by side in each period; the backlog is a line over them. All the bars of the period
      # under the pointer stay bright.
      def bars
        {
          "params" => legend_toggle_params("series") + hover_params(["period"]),
          "transform" => [{ "filter" => "datum.series_key !== 'backlog'" }],
          "mark" => { "type" => "bar", "tooltip" => true, "cornerRadiusEnd" => 2, "cursor" => "pointer" },
          "encoding" => shared_encoding("opacity" => emphasis_opacity, "href" => { "field" => "url", "type" => "nominal" })
            .merge("xOffset" => { "field" => "series" })
        }
      end

      def backlog_line
        {
          "transform" => [{ "filter" => "datum.series_key === 'backlog'" }],
          "mark" => { "type" => "line", "point" => true, "tooltip" => true, "strokeWidth" => 2.5 },
          "encoding" => shared_encoding("opacity" => legend_toggle_opacity)
        }
      end

      def shared_encoding(extra)
        {
          "x" => { "field" => "period", "type" => "ordinal", "timeUnit" => "yearmonthdate", "title" => period_label,
                   "axis" => { "format" => AXIS_FORMATS.fetch(period) } },
          "y" => count_axis("tickets"),
          "color" => { "field" => "series", "type" => "nominal", "title" => nil, "scale" => { "domain" => series_labels, "range" => %w[role:open role:closed role:neutral] } },
          "tooltip" => tooltip
        }.merge(extra)
      end

      def tooltip
        [
          tooltip_line("period_text", period_label, "nominal"),
          count_line("opened", I18n.t(:label_stats_series_opened)),
          count_line("closed", I18n.t(:label_stats_series_closed)),
          count_line("backlog", I18n.t(:label_stats_series_backlog)),
          *SERIES.map { |series| tooltip_line("#{series}_change_text", change_title(I18n.t("label_stats_series_#{series}"), period), "nominal") }
        ]
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

      def rows_with_links
        @rows_with_links ||= begin
          time_zone = options.fetch(:time_zone) { ActiveSupport::TimeZone["UTC"] }
          rows = OpenedAndClosedRows.new(query, period: period, time_zone: time_zone).rows
          rows.each_with_index.map do |row, index|
            first_day = Date.iso8601(row["period"])
            previous = rows[index - 1] if index.positive?
            row.merge(
              "period_text" => period_text(first_day, period),
              "opened_url" => range_link("created_on", first_day), "closed_url" => range_link("closed_on", first_day),
              **SERIES.to_h { |series| ["#{series}_change_text", change_text(row[series], previous && previous[series])] }
            )
          end
        end
      end

      # The chart reads the created-on and closed-on filters as its range, so the link drops them and names the period instead.
      def range_link(field, first_day)
        issue_list_link.call(date_range_filter(field, *period_days(first_day, period)), FilterDateRange::FIELDS)
      end
    end
  end
end
