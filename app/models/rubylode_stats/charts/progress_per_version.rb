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
    # One horizontal stacked bar per version, done against remaining, with the share done and the counts at the bar end
    # ("90% (18 of 20)"). The row label carries the due date and "(overdue)" for an open version past it. A click on a legend
    # entry hides that half; a click on a bar opens the issue list of that version's tickets, of every status. The status filter
    # is ignored (see ProgressPerVersionRows).
    class ProgressPerVersion < Base
      STATE_COLORS = { done: "#6aa84f", remaining: "#adb5bd" }.freeze
      ROW_HEIGHT = 34

      def specification
        {
          "$schema" => SCHEMA,
          "data" => { "values" => rows_with_labels },
          "height" => { "step" => ROW_HEIGHT },
          "encoding" => { "y" => row_axis },
          "layer" => [bars, end_labels]
        }
      end

      def card_note
        I18n.t(:label_stats_progress_per_version_note)
      end

      def wide?
        true
      end

      private

      def state_labels
        { "done" => I18n.t(:label_stats_progress_done), "remaining" => I18n.t(:label_stats_progress_remaining) }
      end

      def row_axis
        labels_by_position = rows_with_labels.to_h { |row| [row["position"].to_s, row["label"]] }
        {
          "field" => "position", "type" => "ordinal", "sort" => "ascending", "title" => nil,
          "axis" => { "labelLimit" => 280, "labelFontSize" => 12, "labelExpr" => "#{JSON.generate(labels_by_position)}[datum.value]" }
        }
      end

      def bars
        {
          "params" => legend_toggle_params("state"),
          "transform" => [
            { "fold" => %w[done remaining], "as" => %w[state_key tickets] },
            { "calculate" => "#{JSON.generate(state_labels)}[datum.state_key]", "as" => "state" }
          ],
          "mark" => { "type" => "bar", "height" => { "band" => 0.7 }, "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "x" => { "field" => "tickets", "type" => "quantitative", "stack" => "zero", "title" => I18n.t(:label_stats_tickets), "axis" => { "tickMinStep" => 1 } },
            "color" => {
              "field" => "state", "type" => "nominal", "title" => nil, "legend" => { "orient" => "top", "symbolType" => "square" },
              "scale" => { "domain" => state_labels.values, "range" => [STATE_COLORS[:done], STATE_COLORS[:remaining]] }
            },
            "order" => { "field" => "state_key", "sort" => "ascending" },
            "opacity" => legend_toggle_opacity,
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => [
              { "field" => "name", "type" => "nominal", "title" => I18n.t(:label_version) },
              { "field" => "state", "type" => "nominal", "title" => I18n.t(:field_status) },
              { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) }
            ]
          }
        }
      end

      def end_labels
        {
          "mark" => { "type" => "text", "align" => "left", "dx" => 6, "fontSize" => 12, "fontWeight" => 600 },
          "encoding" => { "x" => { "field" => "total", "type" => "quantitative" }, "text" => { "field" => "end_label", "type" => "nominal" } }
        }
      end

      def rows_with_labels
        @rows_with_labels ||= ProgressPerVersionRows.new(query).rows.each_with_index.map do |row, position|
          row.merge(
            "position" => position,
            "label" => row_label(row),
            "end_label" => I18n.t(:label_stats_progress_end, percent: row["percent"], done: row["done"], total: row["total"]),
            "url" => issue_list_link.call("fixed_version_id" => row["version_id"], "status_id" => { operator: "*", values: [] })
          )
        end
      end

      def row_label(row)
        return row["name"] unless row["due_date"]

        label = I18n.t(:label_stats_progress_row_due, name: row["name"], date: row["due_date"])
        row["overdue"] ? "#{label}  #{I18n.t(:label_stats_progress_overdue)}" : label
      end
    end
  end
end
