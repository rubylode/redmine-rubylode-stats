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
    # Tickets closed per period, one stacked bar per period with a segment per person. A click on a legend entry hides or
    # shows that person; a click on a bar opens the issue list of the tickets closed in that period (not of one person: the
    # issue list has no filter for who closed a ticket). The tooltip names the person's count and share of the period, the
    # period's total and how that total changed against the previous period.
    class ClosedPerPerson < Base
      TIME_UNITS = { "day" => "yearmonthdate", "week" => "yearmonthdate", "month" => "yearmonth" }.freeze
      AXIS_FORMATS = { "day" => "%b %d", "week" => "%b %d", "month" => "%b %Y" }.freeze

      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "width" => "container",
          "data" => { "values" => rows_with_links },
          "params" => legend_toggle_params("person") + hover_params,
          "mark" => { "type" => "bar", "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "x" => { "field" => "period", "type" => "temporal", "timeUnit" => TIME_UNITS.fetch(period), "title" => period_label,
                     "axis" => { "format" => AXIS_FORMATS.fetch(period) } },
            "y" => count_axis("closed"),
            "color" => { "field" => "person", "type" => "nominal", "title" => I18n.t(:label_stats_person) },
            "opacity" => emphasis_opacity,
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => [
              tooltip_line("period_text", period_label, "nominal"),
              tooltip_line("person", I18n.t(:label_stats_person), "nominal"),
              count_line("closed", I18n.t(:label_stats_series_closed)),
              share_line("share", I18n.t(:label_stats_share_of_period)),
              count_line("period_total", I18n.t(:label_stats_period_total)),
              tooltip_line("period_change_text", change_title(I18n.t(:label_stats_period_total), period), "nominal")
            ]
          }
        }
      end

      def data_table
        DataTable.new(
          headers: [period_label, I18n.t(:label_stats_person), I18n.t(:label_stats_series_closed), I18n.t(:label_stats_share_of_period),
                    I18n.t(:label_stats_period_total), I18n.t(:label_stats_table_tickets)],
          rows: rows_with_links.map do |row|
            DataTable.row(
              [row["period_text"], row["person"], count_text(row["closed"]), share_text(row["share"]),
               "#{count_text(row["period_total"])} (#{row["period_change_text"]})"],
              [I18n.t(:label_stats_table_open_closed), row["url"]]
            )
          end
        )
      end

      private

      def period
        options.fetch(:period, Registry::DEFAULT_PERIOD)
      end

      def period_label
        I18n.t("label_stats_period_#{period}")
      end

      def rows_with_links
        @rows_with_links ||= begin
          time_zone = options.fetch(:time_zone) { ActiveSupport::TimeZone["UTC"] }
          rows = ClosedPerPersonRows.new(query, period: period, time_zone: time_zone).rows
          totals = rows.group_by { |row| row["period"] }.transform_values { |period_rows| period_rows.sum { |row| row["closed"] } }
          rows.map { |row| row_with_links(row, totals) }
        end
      end

      def row_with_links(row, totals)
        first_day = Date.iso8601(row["period"])
        period_total = totals.fetch(row["period"])
        row.merge(
          "period_text" => period_text(first_day, period),
          "period_total" => period_total,
          "share" => share_of(row["closed"], period_total),
          "period_change_text" => change_text(period_total, previous_total(first_day, totals)),
          "url" => issue_list_link.call(date_range_filter("closed_on", *period_days(first_day, period)))
        )
      end

      # The total of the period before this one; 0 when nothing was closed then, nil for the first period of the chart.
      def previous_total(first_day, totals)
        return nil if first_day <= Date.iso8601(totals.keys.min)

        totals.fetch(PREVIOUS_PERIOD.fetch(period).call(first_day).iso8601, 0)
      end
    end
  end
end
