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
    # issue list has no filter for who closed a ticket).
    class ClosedPerPerson < Base
      TIME_UNITS = { "day" => "yearmonthdate", "week" => "yearmonthdate", "month" => "yearmonth" }.freeze
      AXIS_FORMATS = { "day" => "%b %d", "week" => "%b %d", "month" => "%b %Y" }.freeze

      def specification
        {
          "$schema" => SCHEMA,
          "width" => "container",
          "data" => { "values" => rows_with_links },
          "params" => legend_toggle_params("person"),
          "mark" => { "type" => "bar", "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "x" => { "field" => "period", "type" => "temporal", "timeUnit" => TIME_UNITS.fetch(period), "title" => period_label,
                     "axis" => { "format" => AXIS_FORMATS.fetch(period) } },
            "y" => { "field" => "closed", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) },
            "color" => { "field" => "person", "type" => "nominal", "title" => I18n.t(:label_stats_person) },
            "opacity" => legend_toggle_opacity,
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => [
              { "field" => "period", "type" => "temporal", "title" => period_label },
              { "field" => "person", "type" => "nominal", "title" => I18n.t(:label_stats_person) },
              { "field" => "closed", "type" => "quantitative", "title" => I18n.t(:label_stats_series_closed) }
            ]
          }
        }
      end

      private

      def period
        options.fetch(:period, Registry::DEFAULT_PERIOD)
      end

      def period_label
        I18n.t("label_stats_period_#{period}")
      end

      def rows_with_links
        time_zone = options.fetch(:time_zone) { ActiveSupport::TimeZone["UTC"] }
        ClosedPerPersonRows.new(query, period: period, time_zone: time_zone).rows.map do |row|
          row.merge("url" => issue_list_link.call(period_filter(Date.iso8601(row["period"]))))
        end
      end

      # Every status, because the issue list of an open-tickets query would otherwise hide the closed tickets of the bar.
      def period_filter(first_day)
        last_day = case period
                   when "day" then first_day
                   when "week" then first_day + 6
                   else first_day.end_of_month
                   end
        { "closed_on" => { operator: "><", values: [first_day.iso8601, last_day.iso8601] }, "status_id" => { operator: "*", values: [] } }
      end
    end
  end
end
