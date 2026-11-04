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
    # How many closed tickets took 0-1, 2-3, 4-7, 8-14, 15-30, 31-90 or 91+ days from creation to closing, as a histogram.
    # The tooltip names the count, the share of the closed tickets, and the share closed in that time or faster. A bar has no
    # link: the issue list has no filter for how long a ticket took.
    class TimeToCloseHistogram < Base
      def specification
        {
          "$schema" => SCHEMA,
          "description" => description,
          "width" => "container",
          "data" => { "values" => rows },
          "params" => hover_params,
          "mark" => { "type" => "bar", "tooltip" => true },
          "encoding" => {
            "x" => { "field" => "bin", "type" => "ordinal", "sort" => TimeToCloseRows::BINS.map(&:first),
                     "title" => I18n.t("rubylode_stats.days_to_close"), "axis" => { "labelAngle" => 0 } },
            "y" => count_axis("tickets"),
            "opacity" => emphasis_opacity(with_legend: false),
            "tooltip" => [
              tooltip_line("bin", I18n.t("rubylode_stats.days_to_close"), "ordinal"),
              count_line("tickets", I18n.t("rubylode_stats.tickets")),
              share_line("share", I18n.t("rubylode_stats.share_of_closed")),
              share_line("cumulative_share", I18n.t("rubylode_stats.share_within")),
              count_line("total", I18n.t("rubylode_stats.all_closed"))
            ]
          }
        }
      end

      def data_table
        DataTable.new(
          headers: [I18n.t("rubylode_stats.days_to_close"), I18n.t("rubylode_stats.tickets"), I18n.t("rubylode_stats.share_of_closed"), I18n.t("rubylode_stats.share_within")],
          rows: rows.map { |row| DataTable.row([row["bin"], count_text(row["tickets"]), share_text(row["share"]), share_text(row["cumulative_share"])]) }
        )
      end

      private

      def rows
        @rows ||= begin
          bins = TimeToCloseRows.new(query).histogram_rows
          total = bins.sum { |row| row["tickets"] }
          running = 0
          bins.map do |row|
            running += row["tickets"]
            row.merge("total" => total, "share" => share_of(row["tickets"], total), "cumulative_share" => share_of(running, total))
          end
        end
      end
    end
  end
end
