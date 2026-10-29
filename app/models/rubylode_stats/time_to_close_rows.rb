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
  # How long closed tickets took: whole days from created_on to closed_on. Open tickets are left out. A ticket closed before it
  # was created (an import, a back-dated close) counts as 0 days. A ticket reopened and closed again is measured to its latest
  # closing, which is what closed_on holds. The query's filters select the tickets as usual (the default "open tickets" status
  # filter is ignored), so a closed-on filter is the date range.
  class TimeToCloseRows
    SECONDS_PER_DAY = 86_400
    # [label, first day, last day or nil for no upper end]
    BINS = [["0-1", 0, 1], ["2-3", 2, 3], ["4-7", 4, 7], ["8-14", 8, 14], ["15-30", 15, 30], ["31-90", 31, 90], ["91+", 91, nil]].freeze

    def initialize(query)
      @query = query
    end

    # One row per bin, in order, empty bins included: { "bin" => "4-7", "tickets" => 3 }.
    def histogram_rows
      counts = durations.map { |_closed_on, days| bin_label(days) }.tally
      BINS.map { |label, _first_day, _last_day| { "bin" => label, "tickets" => counts.fetch(label, 0) } }
    end

    # One row per period (cut in the time zone, weeks from Monday) that has a closing, by closing period, oldest first:
    # { "period" => "2026-10-05", "median_days" => 7.5, "closed" => 4 }. With an even count the median is the mean of the two
    # middle values.
    def median_rows(period:, time_zone:)
      period_start = OpenedAndClosedRows::PERIOD_START.fetch(period) { raise ArgumentError, "unknown period #{period.inspect}" }
      durations.group_by { |closed_on, _days| period_start.call(closed_on.in_time_zone(time_zone).to_date) }
               .sort_by { |start, _entries| start }
               .map do |start, entries|
        { "period" => start.iso8601, "median_days" => median(entries.map(&:last)), "closed" => entries.size }
      end
    end

    private

    # [closed_on, whole days to close] for each closed ticket.
    def durations
      @durations ||= QueryPopulation.scope(@query).where.not(closed_on: nil).pluck("issues.created_on", "issues.closed_on").map do |created_on, closed_on|
        [closed_on, [((closed_on - created_on) / SECONDS_PER_DAY).floor, 0].max]
      end
    end

    def bin_label(days)
      BINS.find { |_label, first_day, last_day| days >= first_day && (last_day.nil? || days <= last_day) }.first
    end

    def median(values)
      sorted = values.sort
      middle = sorted.size / 2
      value = sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
      value == value.to_i ? value.to_i : value
    end
  end
end
