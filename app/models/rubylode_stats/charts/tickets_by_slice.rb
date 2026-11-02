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
    # The query's tickets counted by the page's Slice-by (category, version, assignee, tracker, priority, author), as a bar
    # chart, or as a pie when the page asks for the "pie" shape. Tickets without a value are the "None" slice. A bar or slice
    # links to the issue list narrowed to its value; the tooltip names the count, the share of all the tickets and the total.
    class TicketsBySlice < Base
      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "data" => { "values" => rows_with_links },
          "params" => hover_params,
          "mark" => pie? ? { "type" => "arc", "tooltip" => true, "cursor" => "pointer" } : { "type" => "bar", "tooltip" => true, "cursor" => "pointer" },
          "encoding" => pie? ? pie_encoding : bar_encoding
        }
      end

      def card_title
        "#{I18n.t(:label_stats_tickets_by)} #{slice_label.downcase}"
      end

      def data_table
        DataTable.new(
          headers: [slice_label, I18n.t(:label_stats_tickets), I18n.t(:label_stats_share_of_total), I18n.t(:label_stats_table_tickets)],
          rows: rows_with_links.map do |row|
            DataTable.row([row["slice"], count_text(row["tickets"]), share_text(row["share"])], [I18n.t(:label_stats_table_open_tickets), row["url"]])
          end
        )
      end

      private

      def slice_by
        options.fetch(:slice_by, Registry::DEFAULT_SLICE)
      end

      def pie?
        options[:shape] == "pie"
      end

      def slice_label
        I18n.t("label_stats_slice_#{slice_by}")
      end

      def tooltip
        [
          tooltip_line("slice", slice_label, "nominal"),
          count_line("tickets", I18n.t(:label_stats_tickets)),
          share_line,
          count_line("total", I18n.t(:label_stats_all_tickets))
        ]
      end

      def bar_encoding
        {
          "x" => { "field" => "slice", "type" => "nominal", "sort" => { "field" => "position" }, "title" => nil },
          "y" => count_axis("tickets", largest_count(rows_with_links, "tickets")),
          "opacity" => emphasis_opacity(with_legend: false),
          "href" => { "field" => "url", "type" => "nominal" },
          "tooltip" => tooltip
        }
      end

      def pie_encoding
        {
          "theta" => { "field" => "tickets", "type" => "quantitative", "stack" => true },
          "color" => { "field" => "slice", "type" => "nominal", "sort" => { "field" => "position" }, "title" => slice_label },
          "opacity" => emphasis_opacity(with_legend: false),
          "href" => { "field" => "url", "type" => "nominal" },
          "tooltip" => tooltip
        }
      end

      def rows_with_links
        filter_field = SlicedTicketsRows.filter_field(slice_by)
        @rows_with_links ||= begin
          rows = SlicedTicketsRows.new(query, slice_by).rows
          total = rows.sum { |row| row["tickets"] }
          rows.each_with_index.map do |row, position|
            row.merge("position" => position, "total" => total, "share" => share_of(row["tickets"], total),
                      "url" => issue_list_link.call(filter_field => row["slice_id"]))
          end
        end
      end
    end
  end
end
