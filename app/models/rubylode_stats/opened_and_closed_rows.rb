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
  # One row per day, week or month: how many tickets were opened (created) and closed in it, and the backlog at its end
  # (opened minus closed, cumulative, starting from the tickets already open before the first period).
  #
  # The created-on and closed-on filters of the query are read as the range of the chart, not as a selection of tickets: a
  # ticket created before the range and closed inside it still counts as closed, and the backlog needs it. The other filters
  # select the tickets as usual; the default "open tickets" status filter is ignored because this chart is about both kinds.
  # Without a date filter the range runs from the first to the last event. A ticket reopened and closed again counts as
  # closed once, at its latest closing (that is what closed_on holds).
  #
  # Periods are cut in the given time zone (the viewing user's); weeks start on Monday. Works with or without a project.
  class OpenedAndClosedRows
    PERIOD_START = {
      "day" => ->(date) { date },
      "week" => ->(date) { date.beginning_of_week(:monday) },
      "month" => ->(date) { date.beginning_of_month }
    }.freeze
    NEXT_PERIOD = {
      "day" => ->(date) { date + 1 },
      "week" => ->(date) { date + 7 },
      "month" => ->(date) { date.next_month }
    }.freeze

    MAXIMUM_PERIODS = 5000

    def initialize(query, period:, time_zone:)
      raise ArgumentError, "unknown period #{period.inspect}" unless PERIOD_START.key?(period)

      @query = query
      @period = period
      @time_zone = time_zone
    end

    def rows
      tickets = ticket_periods
      periods = periods_of_range(tickets)
      return [] if periods.empty?

      first_period = periods.first
      backlog = tickets.count { |opened, closed| opened < first_period && (closed.nil? || closed >= first_period) }
      opened_counts = tickets.map(&:first).tally
      closed_counts = tickets.filter_map(&:last).tally
      periods.map do |period_start|
        opened = opened_counts.fetch(period_start, 0)
        closed = closed_counts.fetch(period_start, 0)
        backlog += opened - closed
        { "period" => period_start.iso8601, "opened" => opened, "closed" => closed, "backlog" => backlog }
      end
    end

    private

    # [period the ticket was opened in, period it was closed in or nil] for every ticket the other filters select.
    def ticket_periods
      QueryPopulation.scope(@query, ignored_fields: FilterDateRange::FIELDS).pluck("issues.created_on", "issues.closed_on").map do |created_on, closed_on|
        [period_start(created_on), closed_on && period_start(closed_on)]
      end
    end

    def period_start(time)
      PERIOD_START.fetch(@period).call(time.in_time_zone(@time_zone).to_date)
    end

    # The filter range cut down to the periods that hold a ticket event, so a filter such as "last 999999999 days" or a
    # year-1 to year-9999 range cannot ask for millions of rows; an unreadable date was already read as an open end. Beyond
    # MAXIMUM_PERIODS only the most recent periods are returned (nothing is coarsened silently into a wider period).
    def periods_of_range(tickets)
      event_periods = tickets.flatten.compact
      return [] if event_periods.empty?

      filter_first, filter_last = FilterDateRange.bounds(@query.filters, @time_zone.today)
      first_period = [event_periods.min, filter_first && period_start_of_date(filter_first)].compact.max
      last_period = [event_periods.max, filter_last && period_start_of_date(filter_last)].compact.min
      periods_between(first_period, last_period).last(MAXIMUM_PERIODS)
    end

    def period_start_of_date(date)
      PERIOD_START.fetch(@period).call(date)
    end

    def periods_between(first_period, last_period)
      periods = []
      current = first_period
      while current <= last_period
        periods << current
        current = NEXT_PERIOD.fetch(@period).call(current)
      end
      periods
    end
  end
end
