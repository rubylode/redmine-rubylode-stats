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
    # Open versus closed as a donut with the percentage closed in its centre; the legend carries the counts and a click on an
    # entry hides that half. Both halves are always counted, whatever the status filter says (see OpenVersusClosedRows). A slice
    # links to the issue list narrowed to open or closed tickets; its tooltip names the count, the share and the total.
    class OpenVersusClosed < Base
      STATE_FILTERS = { "open" => "o", "closed" => "c" }.freeze

      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "data" => { "values" => rows_with_links },
          "width" => 220, "height" => 220,
          "layer" => [donut, centre_text(percent_closed_text, 34, "bold", 0), centre_text(I18n.t(:label_stats_state_closed).downcase, 13, "normal", 26)]
        }
      end

      def card_note
        I18n.t(:label_stats_open_versus_closed_note)
      end

      def data_table
        DataTable.new(
          headers: [I18n.t(:field_status), I18n.t(:label_stats_tickets), I18n.t(:label_stats_share_of_total), I18n.t(:label_stats_table_tickets)],
          rows: rows_with_links.map do |row|
            DataTable.row([row["state_label"], count_text(row["tickets"]), share_text(row["share"])], [I18n.t(:label_stats_table_open_tickets), row["url"]])
          end
        )
      end

      private

      def state_color
        {
          "field" => "legend_label", "type" => "nominal", "sort" => { "field" => "position" },
          "title" => nil, "legend" => { "orient" => "right", "symbolType" => "square" },
          "scale" => { "domain" => legend_labels, "range" => ["#2f6fb0", "#6aa84f"] }
        }
      end

      def legend_labels
        rows_with_links.map { |row| row["legend_label"] }
      end

      def tooltip
        [
          tooltip_line("state_label", I18n.t(:field_status), "nominal"),
          count_line("tickets", I18n.t(:label_stats_tickets)),
          share_line,
          count_line("total", I18n.t(:label_stats_all_tickets))
        ]
      end

      def donut
        {
          "params" => legend_toggle_params("legend_label") + hover_params,
          "mark" => { "type" => "arc", "innerRadius" => 70, "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "theta" => { "field" => "tickets", "type" => "quantitative", "stack" => true },
            "color" => state_color,
            "opacity" => emphasis_opacity,
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => tooltip
          }
        }
      end

      def centre_text(text, size, weight, offset)
        {
          "data" => { "values" => [{}] },
          "mark" => { "type" => "text", "align" => "center", "baseline" => "middle", "fontSize" => size, "fontWeight" => weight, "dy" => offset },
          "encoding" => { "text" => { "value" => text } }
        }
      end

      def percent_closed_text
        closed_row = rows.find { |row| row["state"] == "closed" }
        percent = percent_of_all(closed_row["tickets"])
        percent ? "#{percent}%" : DASH
      end

      def percent_of_all(tickets)
        (tickets * 100.0 / total_tickets).round unless total_tickets.zero?
      end

      def total_tickets
        @total_tickets ||= rows.sum { |row| row["tickets"] }
      end

      def rows
        @rows ||= OpenVersusClosedRows.new(query).rows
      end

      def rows_with_links
        @rows_with_links ||= rows.each_with_index.map do |row, position|
          state_label = I18n.t("label_stats_state_#{row["state"]}")
          percent = percent_of_all(row["tickets"])
          row.merge(
            "position" => position,
            "total" => total_tickets,
            "share" => share_of(row["tickets"], total_tickets),
            "state_label" => state_label,
            "legend_label" => I18n.t(:label_stats_legend_with_count, state: state_label, tickets: row["tickets"], percent: percent || DASH),
            "url" => issue_list_link.call("status_id" => { operator: STATE_FILTERS.fetch(row["state"]), values: [] })
          )
        end
      end
    end
  end
end
