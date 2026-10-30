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
    # The query's tickets counted by the page's Slice-by (category, version, assignee, tracker, priority, author), as a bar
    # chart, or as a pie when the page asks for the "pie" shape. Tickets without a value are the "None" slice.
    class TicketsBySlice < Base
      def specification
        {
          "$schema" => SCHEMA,
          "data" => { "values" => rows_with_links },
          "mark" => pie? ? { "type" => "arc", "tooltip" => true, "cursor" => "pointer" } : { "type" => "bar", "tooltip" => true, "cursor" => "pointer" },
          "encoding" => pie? ? pie_encoding : bar_encoding
        }
      end

      def card_title
        "#{I18n.t(:label_stats_tickets_by)} #{slice_label.downcase}"
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
          { "field" => "slice", "type" => "nominal", "title" => slice_label },
          { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) }
        ]
      end

      def bar_encoding
        {
          "x" => { "field" => "slice", "type" => "nominal", "sort" => { "field" => "position" }, "title" => nil },
          "y" => { "field" => "tickets", "type" => "quantitative", "title" => I18n.t(:label_stats_tickets) },
          "href" => { "field" => "url", "type" => "nominal" },
          "tooltip" => tooltip
        }
      end

      def pie_encoding
        {
          "theta" => { "field" => "tickets", "type" => "quantitative", "stack" => true },
          "color" => { "field" => "slice", "type" => "nominal", "sort" => { "field" => "position" }, "title" => slice_label },
          "href" => { "field" => "url", "type" => "nominal" },
          "tooltip" => tooltip
        }
      end

      def rows_with_links
        filter_field = SlicedTicketsRows.filter_field(slice_by)
        SlicedTicketsRows.new(query, slice_by).rows.each_with_index.map do |row, position|
          row.merge("position" => position, "url" => issue_list_link.call(filter_field => row["slice_id"]))
        end
      end
    end
  end
end
