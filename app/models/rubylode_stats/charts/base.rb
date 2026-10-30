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
    # A chart builds a Vega-Lite specification (a Hash) from the rows of one row model. Subclass it, say which rows and which
    # title, and write the specification; then add the class to its tab in RubylodeStats::Registry.
    #
    # options carries the page choices a chart may use: :slice_by, :shape ("pie"), :period and :time_zone.
    #
    # issue_list_link is a callable that takes an extra filter (for example "status_id" => 5) and returns the URL of the
    # issue list with the query's filters plus that one, so a bar can link to what it counts.
    class Base
      SCHEMA = "https://vega.github.io/schema/vega-lite/v5.json".freeze

      # The name used in the page's element ids: RubylodeStats::Charts::TicketsByStatus becomes "tickets_by_status".
      def self.chart_name
        name.demodulize.underscore
      end

      def initialize(query:, issue_list_link:, options: {})
        @query = query
        @issue_list_link = issue_list_link
        @options = options
      end

      def chart_name
        self.class.chart_name
      end

      def specification
        raise NotImplementedError
      end

      # The card around the chart: a title, a one-line subtitle naming the question the chart answers, an optional note and
      # whether the card spans the whole grid. The specification itself carries no title.
      def card_title
        I18n.t("label_stats_#{chart_name}")
      end

      def card_subtitle
        I18n.t("label_stats_#{chart_name}_subtitle")
      end

      def card_note
        nil
      end

      def wide?
        false
      end

      private

      attr_reader :query, :issue_list_link, :options

      # Counts up to this many get a tick at every whole number; above it the chart picks its own whole-number steps.
      EVERY_WHOLE_TICKET_LIMIT = 8

      # A count axis of whole tickets: the title says Tickets and no tick falls between two whole numbers. The browser's
      # chart library ignores a minimum tick step on a short axis (it drew 0.5, 1.5), so when the largest count is given and
      # small, the ticks are named outright: 0 up to that count.
      def count_axis(field, maximum_count = nil)
        axis = { "tickMinStep" => 1, "format" => "d" }
        axis = axis.merge("values" => (0..maximum_count).to_a) if maximum_count && maximum_count <= EVERY_WHOLE_TICKET_LIMIT
        { "field" => field, "type" => "quantitative", "title" => I18n.t(:label_stats_tickets), "axis" => axis }
      end

      def largest_count(rows, field)
        rows.map { |row| row[field] }.max || 0
      end

      # Clicking a legend entry hides the series; add the result to a mark's encoding as "opacity" and to the chart's
      # "params". Only for charts with a legend.
      def legend_toggle_params(field)
        [{ "name" => "legend_selection", "select" => { "type" => "point", "fields" => [field] }, "bind" => "legend" }]
      end

      def legend_toggle_opacity
        { "condition" => { "param" => "legend_selection", "value" => 1 }, "value" => 0.2 }
      end
    end
  end
end
