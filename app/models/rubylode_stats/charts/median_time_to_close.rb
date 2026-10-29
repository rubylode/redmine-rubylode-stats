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
    # The median days to close of the tickets closed in each period, as a line.
    class MedianTimeToClose < Base
      AXIS_FORMATS = { "day" => "%b %d", "week" => "%b %d", "month" => "%b %Y" }.freeze

      def specification
        {
          "$schema" => SCHEMA,
          "title" => title,
          "width" => "container",
          "data" => { "values" => rows },
          "mark" => { "type" => "line", "point" => true, "tooltip" => true },
          "encoding" => {
            "x" => { "field" => "period", "type" => "temporal", "title" => period_label,
                     "axis" => { "format" => AXIS_FORMATS.fetch(period) } },
            "y" => { "field" => "median_days", "type" => "quantitative", "title" => I18n.t(:label_stats_median_days) },
            "tooltip" => [
              { "field" => "period", "type" => "temporal", "title" => period_label },
              { "field" => "median_days", "type" => "quantitative", "title" => I18n.t(:label_stats_median_days) },
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

      def rows
        time_zone = options.fetch(:time_zone) { ActiveSupport::TimeZone["UTC"] }
        TimeToCloseRows.new(query).median_rows(period: period, time_zone: time_zone)
      end
    end
  end
end
