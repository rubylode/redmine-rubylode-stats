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
    # How many closed tickets took 0-1, 2-3, 4-7, 8-14, 15-30, 31-90 or 91+ days from creation to closing, as a histogram.
    class TimeToCloseHistogram < Base
      def specification
        {
          "$schema" => SCHEMA,
          "title" => title,
          "width" => "container",
          "data" => { "values" => TimeToCloseRows.new(query).histogram_rows },
          "mark" => { "type" => "bar", "tooltip" => true },
          "encoding" => {
            "x" => { "field" => "bin", "type" => "ordinal", "sort" => TimeToCloseRows::BINS.map(&:first),
                     "title" => I18n.t(:label_stats_days_to_close), "axis" => { "labelAngle" => 0 } },
            "y" => { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) },
            "tooltip" => [
              { "field" => "bin", "type" => "ordinal", "title" => I18n.t(:label_stats_days_to_close) },
              { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) }
            ]
          }
        }
      end
    end
  end
end
