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
  # show, so the page prints a dash instead of dividing by zero):
  #
  # - open: tickets open now, and the tickets all the filters except the date range and the status select.
  # - closed_in_range: tickets closed inside the date range of the filters (no date filter: ever), and their share of those
  #   same tickets, in whole percent.
  # - median_days: the median whole days from created to closed of the tickets closed in the range.
  # - backlog_change: opened minus closed over the last four periods of the range (fewer when the range is shorter), with the
  #   direction "growing", "shrinking" or "steady".
  class SummaryTilesRows
    BACKLOG_PERIODS = 4
    SECONDS_PER_DAY = 86_400

    def initialize(query, period:, time_zone:, today: time_zone.today)
      @query = query
      @period = period
      @time_zone = time_zone
      @today = today
    end

    def tiles
      {
        "open" => { "tickets" => open_tickets, "of_tickets" => total_tickets },
        "closed_in_range" => { "tickets" => closed_in_range.size, "percent_of_tickets" => percent(closed_in_range.size, total_tickets) },
        "median_days" => { "days" => median(closed_in_range_days), "closed_tickets" => closed_in_range.size },
        "backlog_change" => backlog_change
      }
    end

    private

    def population
      QueryPopulation.scope(@query, ignored_fields: FilterDateRange::FIELDS + ["status_id"])
    end

    def total_tickets
      @total_tickets ||= population.count
    end

    def open_tickets
      population.where(issue_statuses: { is_closed: false }).count
    end

    # [created_on, closed_on] of the tickets closed inside the range.
    def closed_in_range
      @closed_in_range ||= begin
        first_day, last_day = FilterDateRange.bounds(@query.filters, @today)
        scope = population.where.not(closed_on: nil)
        scope = scope.where(closed_on: @time_zone.local(first_day.year, first_day.month, first_day.day).beginning_of_day..) if first_day
        scope = scope.where(closed_on: ..@time_zone.local(last_day.year, last_day.month, last_day.day).end_of_day) if last_day
        scope.pluck("issues.created_on", "issues.closed_on")
      end
    end

    def closed_in_range_days
      closed_in_range.map { |created_on, closed_on| [((closed_on - created_on) / SECONDS_PER_DAY).floor, 0].max }
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
