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
    # The query's tickets counted by status, one bar each. A bar links to the issue list narrowed to that status, the
    # tooltip names the count, the share of all the tickets and the total.
    class TicketsByStatus < Base
      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "data" => { "values" => rows_with_links },
          "params" => hover_params,
          "mark" => { "type" => "bar", "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "x" => { "field" => "status", "type" => "nominal", "sort" => { "field" => "position" }, "title" => nil },
            "y" => count_axis("tickets", largest_count(rows_with_links, "tickets")),
            "color" => { "field" => "status", "type" => "nominal", "sort" => { "field" => "position" }, "legend" => nil, "scale" => status_color_scale(rows_with_links) },
            "opacity" => emphasis_opacity(with_legend: false),
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => [
              tooltip_line("status", I18n.t(:field_status), "nominal"),
              count_line("tickets", I18n.t("rubylode_stats.tickets")),
              share_line,
              count_line("total", I18n.t("rubylode_stats.all_tickets"))
            ]
          }
        }
      end

      def data_table
        DataTable.new(
          headers: [I18n.t(:field_status), I18n.t("rubylode_stats.tickets"), I18n.t("rubylode_stats.share_of_total"), I18n.t("rubylode_stats.table.tickets")],
          rows: rows_with_links.map do |row|
            DataTable.row([row["status"], count_text(row["tickets"]), share_text(row["share"])], [I18n.t("rubylode_stats.table.open_tickets"), row["url"]])
          end
        )
      end

      private

      # Color by meaning: a closed status takes the closed role color, an empty or None bucket the neutral gray, and the
      # open statuses the palette in order (the script skips the color the closed role uses, so no open bar looks closed).
      def status_color_scale(rows)
        neutral_labels = [I18n.t("rubylode_stats.none"), "Other"]
        position = 0
        range = rows.map do |row|
          next "role:closed" if row["is_closed"]
          next "role:neutral" if neutral_labels.include?(row["status"].to_s) || row["status"].to_s.strip.empty?

          position += 1
          "open_status:#{position}"
        end
        { "domain" => rows.map { |row| row["status"] }, "range" => range }
      end

      def rows_with_links
        @rows_with_links ||= begin
          rows = TicketsByStatusRows.new(query).rows
          total = rows.sum { |row| row["tickets"] }
          rows.each_with_index.map do |row, position|
            row.merge("position" => position, "total" => total, "share" => share_of(row["tickets"], total),
                      "url" => issue_list_link.call("status_id" => row["status_id"]))
          end
        end
      end
    end
  end
end
