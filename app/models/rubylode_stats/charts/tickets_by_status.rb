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
    class TicketsByStatus < Base
      def specification
        {
          "$schema" => SCHEMA,
          "title" => title,
          "data" => { "values" => rows_with_links },
          "mark" => { "type" => "bar", "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "x" => { "field" => "status", "type" => "nominal", "sort" => { "field" => "position" }, "title" => nil },
            "y" => { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) },
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => [
              { "field" => "status", "type" => "nominal", "title" => I18n.t(:field_status) },
              { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) }
            ]
          }
        }
      end

      private

      def rows_with_links
        TicketsByStatusRows.new(query).rows.each_with_index.map do |row, position|
          row.merge("position" => position, "url" => issue_list_link.call("status_id" => row["status_id"]))
        end
      end
    end
  end
end
