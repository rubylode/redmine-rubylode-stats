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

module RubylodeStats
  module Charts
    # Open and closed tickets as one stacked bar next to a donut, both from the same two rows. A segment links to the issue
    # list narrowed to open or closed tickets.
    class OpenVersusClosed < Base
      STATE_FILTERS = { "open" => "o", "closed" => "c" }.freeze

      def specification
        {
          "$schema" => SCHEMA,
          "title" => title,
          "data" => { "values" => rows_with_links },
          "hconcat" => [stacked_bar, donut]
        }
      end

      private

      def state_color
        {
          "field" => "state_label", "type" => "nominal", "sort" => { "field" => "position" },
          "title" => nil, "scale" => { "domain" => state_labels, "range" => ["#2f6fb0", "#6aa84f"] }
        }
      end

      def state_labels
        STATE_FILTERS.keys.map { |state| I18n.t("label_stats_state_#{state}") }
      end

      def tooltip
        [
          { "field" => "state_label", "type" => "nominal", "title" => I18n.t(:field_status) },
          { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) }
        ]
      end

      def stacked_bar
        {
          "width" => 360, "height" => 60,
          "mark" => { "type" => "bar", "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "x" => { "field" => "tickets", "type" => "quantitative", "stack" => "zero", "title" => I18n.t(:label_stats_tickets) },
            "color" => state_color.merge("legend" => nil),
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => tooltip
          }
        }
      end

      def donut
        {
          "params" => legend_toggle_params("state_label"),
          "mark" => { "type" => "arc", "innerRadius" => 50, "tooltip" => true, "cursor" => "pointer" },
          "encoding" => {
            "theta" => { "field" => "tickets", "type" => "quantitative", "stack" => true },
            "color" => state_color,
            "opacity" => legend_toggle_opacity,
            "href" => { "field" => "url", "type" => "nominal" },
            "tooltip" => tooltip
          }
        }
      end

      def rows_with_links
        OpenVersusClosedRows.new(query).rows.each_with_index.map do |row, position|
          row.merge(
            "position" => position,
            "state_label" => I18n.t("label_stats_state_#{row["state"]}"),
            "url" => issue_list_link.call("status_id" => { operator: STATE_FILTERS.fetch(row["state"]), values: [] })
          )
        end
      end
    end
  end
end
