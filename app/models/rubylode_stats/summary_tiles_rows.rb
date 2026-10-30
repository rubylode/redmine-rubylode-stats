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
  # The four numbers above the charts of the Overview tab, as a plain hash of literal values (nil where there is nothing to
  # show, so the page prints a dash instead of dividing by zero). Open, closed and the total count the very tickets of the
  # Open versus closed donut: the filters and the date range apply, the status filter does not.
  #
  # - open: those tickets that are open, and how many tickets there are.
  # - closed_in_range: those tickets that are closed, and their share of all of them, in whole percent.
  # - median_days: the median whole days from created to closed of those closed tickets.
  # - backlog_change: opened minus closed over the last four periods of the range (fewer when the range is shorter), with the
  #   direction "growing", "shrinking" or "steady".
  class SummaryTilesRows
    BACKLOG_PERIODS = 4
    SECONDS_PER_DAY = 86_400

    def initialize(query, period:, time_zone:)
      @query = query
      @period = period
      @time_zone = time_zone
    end

    def tiles
      {
        "open" => { "tickets" => ticket_counts["open"], "of_tickets" => total_tickets },
        "closed_in_range" => { "tickets" => ticket_counts["closed"], "percent_of_tickets" => percent(ticket_counts["closed"], total_tickets) },
        "median_days" => { "days" => median(closed_days), "closed_tickets" => closed_days.size },
        "backlog_change" => backlog_change
      }
    end

    private

    def ticket_counts
      @ticket_counts ||= OpenVersusClosedRows.new(@query).rows.to_h { |row| [row["state"], row["tickets"]] }
    end

    def total_tickets
      ticket_counts.values.sum
    end

    # Whole days from created to closed of the closed tickets of the donut's population.
    def closed_days
      @closed_days ||= OpenVersusClosedRows.closed_scope(@query).where.not(closed_on: nil).pluck("issues.created_on", "issues.closed_on")
                                           .map { |created_on, closed_on| [((closed_on - created_on) / SECONDS_PER_DAY).floor, 0].max }
    end

    def percent(part, whole)
      (part * 100.0 / whole).round unless whole.zero?
    end

    def median(values)
      return nil if values.empty?

      sorted = values.sort
      middle = sorted.size / 2
      value = sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
      value == value.to_i ? value.to_i : value
    end

    def backlog_change
      recent_periods = OpenedAndClosedRows.new(@query, period: @period, time_zone: @time_zone).rows.last(BACKLOG_PERIODS)
      return { "difference" => nil, "periods" => 0, "period" => @period, "direction" => nil } if recent_periods.empty?

      difference = recent_periods.sum { |row| row["opened"] - row["closed"] }
      direction = difference.positive? ? "growing" : (difference.negative? ? "shrinking" : "steady")
      { "difference" => difference, "periods" => recent_periods.size, "period" => @period, "direction" => direction }
    end
  end
end
