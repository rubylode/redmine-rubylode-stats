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
      # Done takes the closed role color and remaining the neutral one; the script turns the tokens into the palette's colors.
      STATE_COLORS = { done: "role:closed", remaining: "role:neutral" }.freeze
      ROW_HEIGHT = 34
      END_LABEL_ROOM = 1.35

      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "data" => { "values" => rows_with_labels },
          "height" => { "step" => ROW_HEIGHT },
          "encoding" => { "y" => row_axis },
          "layer" => [bars, end_labels]
        }
      end

      def card_note
        I18n.t("rubylode_stats.charts.progress_per_version.note")
      end

      def data_table
        DataTable.new(
          headers: [I18n.t(:label_version), I18n.t(:field_effective_date), I18n.t("rubylode_stats.progress.done"), I18n.t("rubylode_stats.progress.remaining"),
                    I18n.t("rubylode_stats.all_tickets"), I18n.t("rubylode_stats.table.tickets")],
          rows: rows_with_labels.map do |row|
            DataTable.row([row["name"], row["due_text"], "#{count_text(row["done"])} (#{row["percent"]}%)", count_text(row["remaining"]),
                           count_text(row["total"])], [I18n.t("rubylode_stats.table.open_tickets"), row["url"]])
          end
        )
      end

      def wide?
        true
      end

      private

      def state_labels
        { "done" => I18n.t("rubylode_stats.progress.done"), "remaining" => I18n.t("rubylode_stats.progress.remaining") }
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
          "params" => legend_toggle_params("state") + hover_params,
          "transform" => [
            { "fold" => %w[done remaining], "as" => %w[state_key tickets] },
            { "calculate" => "#{JSON.generate(state_labels)}[datum.state_key]", "as" => "state" }
          ],
          "mark" => { "type" => "bar", "height" => { "band" => 0.7 }, "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "x" => count_axis("tickets").merge("stack" => "zero", "scale" => { "domainMax" => domain_maximum, "nice" => false }),
            "color" => {
              "field" => "state", "type" => "nominal", "title" => nil, "legend" => { "orient" => "top", "symbolType" => "square" },
              "scale" => { "domain" => state_labels.values, "range" => [STATE_COLORS[:done], STATE_COLORS[:remaining]] }
            },
            "order" => { "field" => "state_key", "sort" => "ascending" },
            "opacity" => emphasis_opacity,
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => [
              tooltip_line("name", I18n.t(:label_version), "nominal"),
              tooltip_line("due_text", I18n.t(:field_effective_date), "nominal"),
              tooltip_line("state", I18n.t(:field_status), "nominal"),
              count_line("tickets", I18n.t("rubylode_stats.tickets")),
              count_line("done", I18n.t("rubylode_stats.progress.done")),
              count_line("remaining", I18n.t("rubylode_stats.progress.remaining")),
              count_line("total", I18n.t("rubylode_stats.all_tickets")),
              tooltip_line("percent_text", I18n.t("rubylode_stats.progress.percent"), "nominal")
            ]
          }
        }
      end

      # Room to the right of the longest bar for its end label, which is wider than any bar segment.
      def domain_maximum
        (rows_with_labels.map { |row| row["total"] }.max.to_i * END_LABEL_ROOM).ceil
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
            "due_text" => row["due_date"] ? format_date(Date.iso8601(row["due_date"])) : not_available,
            "percent_text" => "#{row["percent"]}%",
            "end_label" => I18n.t("rubylode_stats.progress.end", percent: row["percent"], done: row["done"], total: row["total"]),
            "url" => issue_list_link.call("fixed_version_id" => row["version_id"], "status_id" => { operator: "*", values: [] })
          )
        end
      end

      def row_label(row)
        return row["name"] unless row["due_date"]

        label = I18n.t("rubylode_stats.progress.row_due", name: row["name"], date: row["due_date"])
        row["overdue"] ? "#{label}  #{I18n.t("rubylode_stats.progress.overdue")}" : label
      end
    end
  end
end
