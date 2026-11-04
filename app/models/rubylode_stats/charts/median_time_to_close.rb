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
    # The median days to close of the tickets closed in each period, as a line with a point per period. The point under the
    # pointer grows; the tooltip names the median, the tickets closed and the change of the median against the previous
    # period; a point links to the issue list of the tickets closed in that period.
    class MedianTimeToClose < Base
      AXIS_FORMATS = { "day" => "%b %d", "week" => "%b %d", "month" => "%b %Y" }.freeze
      POINT_SIZE = 60
      POINT_SIZE_HOVERED = 220

      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "width" => "container",
          "data" => { "values" => rows_with_links },
          "encoding" => {
            "x" => { "field" => "period", "type" => "temporal", "title" => period_label,
                     "axis" => { "format" => AXIS_FORMATS.fetch(period) } },
            "y" => { "field" => "median_days", "type" => "quantitative", "title" => I18n.t("rubylode_stats.median_days") }
          },
          "layer" => [{ "mark" => { "type" => "line" } }, points]
        }
      end

      def data_table
        DataTable.new(
          headers: [period_label, I18n.t("rubylode_stats.median_days"), I18n.t("rubylode_stats.series.closed"), I18n.t("rubylode_stats.table.tickets")],
          rows: rows_with_links.map do |row|
            DataTable.row([row["period_text"], "#{row["median_days"]} (#{row["median_change_text"]})", count_text(row["closed"])],
                          [I18n.t("rubylode_stats.table.open_closed"), row["url"]])
          end
        )
      end

      private

      def points
        {
          "params" => hover_params,
          "mark" => { "type" => "point", "filled" => true, "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "size" => { "condition" => { "param" => "hover", "empty" => false, "value" => POINT_SIZE_HOVERED }, "value" => POINT_SIZE },
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => [
              tooltip_line("period_text", period_label, "nominal"),
              tooltip_line("median_days", I18n.t("rubylode_stats.median_days"), "quantitative", ",.1~f"),
              count_line("closed", I18n.t("rubylode_stats.series.closed")),
              tooltip_line("median_change_text", change_title(I18n.t("rubylode_stats.median_days"), period), "nominal")
            ]
          }
        }
      end

      def period
        options.fetch(:period, Registry::DEFAULT_PERIOD)
      end

      def period_label
        I18n.t("rubylode_stats.periods.#{period}")
      end

      def rows_with_links
        @rows_with_links ||= begin
          time_zone = options.fetch(:time_zone) { ActiveSupport::TimeZone["UTC"] }
          rows = TimeToCloseRows.new(query).median_rows(period: period, time_zone: time_zone)
          rows.each_with_index.map do |row, index|
            first_day = Date.iso8601(row["period"])
            previous = rows[index - 1] if index.positive?
            row.merge(
              "period_text" => period_text(first_day, period),
              "median_change_text" => change_text(row["median_days"], previous && previous["median_days"]),
              "url" => issue_list_link.call(date_range_filter("closed_on", *period_days(first_day, period)))
            )
          end
        end
      end
    end
  end
end
