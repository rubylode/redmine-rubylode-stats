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
      include Redmine::I18n

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

      # The same figures as the chart, for people who do not use a pointer: a table under the chart (see DataTable). A chart
      # that has no table returns nil.
      def data_table
        nil
      end

      # What a screen reader announces for the chart; the table holds the figures.
      def description
        "#{card_title}. #{card_subtitle}"
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

      # A colour scale for a category chart: each label takes the next palette colour in order, except the "None" and "Other" buckets,
      # which is drawn in the neutral grey so it reads as context and does not use up a hue.
      def category_color_scale(labels)
        neutral_labels = [I18n.t(:label_stats_none), "Other"]
        position = 0
        range = labels.map do |label|
          next "role:neutral" if neutral_labels.include?(label.to_s) || label.to_s.strip.empty?

          position += 1
          "category:#{position}"
        end
        { "domain" => labels, "range" => range }
      end

      def largest_count(rows, field)
        rows.map { |row| row[field] }.max || 0
      end

      # Clicking a legend entry hides the series; add the result to a mark's encoding as "opacity" and to the chart's
      # "params". Only for charts with a legend.
      def legend_toggle_params(field)
        [{ "name" => "legend_selection", "select" => { "type" => "point", "fields" => [field] }, "bind" => "legend" }]
      end

      # The mark under the pointer. With no fields the selection is the mark itself; with fields, every mark that shares
      # their values (all the bars of one period, say) is emphasised together.
      def hover_params(fields = nil)
        select = { "type" => "point", "on" => "pointerover", "clear" => "pointerout" }
        select["fields"] = fields if fields
        [{ "name" => "hover", "select" => select }]
      end

      DIMMED_OPACITY = 0.45
      HIDDEN_SERIES_OPACITY = 0.2

      # A mark hidden through the legend is faint; with the pointer over a mark, the others dim a little; otherwise all are
      # full. Add the result to a mark's encoding as "opacity", with hover_params (and legend_toggle_params when
      # with_legend) among the chart's params.
      def emphasis_opacity(with_legend: true)
        conditions = []
        conditions << { "test" => { "not" => { "param" => "legend_selection" } }, "value" => HIDDEN_SERIES_OPACITY } if with_legend
        conditions << { "param" => "hover", "empty" => false, "value" => 1 }
        conditions << { "test" => "length(data('hover_store')) === 0", "value" => 1 }
        { "condition" => conditions, "value" => DIMMED_OPACITY }
      end

      # Number formats are Vega's (d3), which the page's script sets to the user's language.
      COUNT_FORMAT = ",d".freeze
      SHARE_FORMAT = ".1~%".freeze
      DASH = "–".freeze

      def tooltip_line(field, title, type = "quantitative", format = nil)
        line = { "field" => field, "type" => type, "title" => title }
        line["format"] = format if format
        line
      end

      def count_line(field, title)
        tooltip_line(field, title, "quantitative", COUNT_FORMAT)
      end

      def share_line(field = "share", title = I18n.t(:label_stats_share_of_total))
        tooltip_line(field, title, "quantitative", SHARE_FORMAT)
      end

      # The mark's share of the whole, as a fraction (the tooltip formats it as a percentage); nil for an empty whole.
      def share_of(part, whole)
        part.to_f / whole if whole.positive?
      end

      def count_text(count)
        ActiveSupport::NumberHelper.number_to_delimited(count)
      end

      def share_text(fraction)
        return DASH unless fraction

        percent = (fraction * 100).round(1)
        "#{percent == percent.to_i ? percent.to_i : percent}%"
      end

      # "+3", "-2" or "0" against the previous period; a dash when there is no previous period to compare with.
      def change_text(current, previous)
        return DASH if previous.nil? || current.nil?

        difference = (current - previous).round(1)
        difference = difference.to_i if difference == difference.to_i
        difference.positive? ? "+#{difference}" : difference.to_s
      end

      def change_title(name, period)
        I18n.t(:label_stats_change_title, name: name, period: I18n.t("label_stats_period_#{period}").downcase)
      end

      PREVIOUS_PERIOD = {
        "day" => ->(date) { date - 1 },
        "week" => ->(date) { date - 7 },
        "month" => ->(date) { date.prev_month }
      }.freeze

      # The first and last day of the period that starts on first_day.
      def period_days(first_day, period)
        last_day = case period
                   when "day" then first_day
                   when "week" then first_day + 6
                   else first_day.end_of_month
                   end
        [first_day, last_day]
      end

      # The issue list of an open-tickets query would hide the closed tickets of a bar, so the default "open" status filter
      # gives way to every status; any status filter the user chose stays, as the chart honours it too.
      def date_range_filter(field, first_day, last_day)
        filter = { field => { operator: "><", values: [first_day.iso8601, last_day.iso8601] } }
        filter["status_id"] = { operator: "*", values: [] } if query.filters.dig("status_id", :operator) == "o"
        filter
      end

      # "Oct 5, 2026" for a day, "Oct 5, 2026 – Oct 11, 2026" for a week, "October 2026" for a month, in the user's date format.
      def period_text(first_day, period)
        case period
        when "day" then format_date(first_day)
        when "week" then "#{format_date(first_day)} – #{format_date(first_day + 6)}"
        else ::I18n.l(first_day, format: "%B %Y")
        end
      end

      def legend_toggle_opacity
        { "condition" => { "param" => "legend_selection", "value" => 1 }, "value" => 0.2 }
      end
    end
  end
end
