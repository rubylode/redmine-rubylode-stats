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
  # The date range that a query's created-on and closed-on filters ask for, as [first_day, last_day]; nil for an end that is
  # open. When both fields are filtered the range covers both. Understands the operators of the presets and the common ones
  # of Redmine's date filter; any other operator leaves its end open. Weeks start on Monday.
  module FilterDateRange
    FIELDS = %w[created_on closed_on].freeze

    def self.bounds(filters, today)
      ranges = FIELDS.filter_map { |field| filters[field] && range_for(filters[field], today) }
      [ranges.filter_map(&:first).min, ranges.filter_map(&:last).max]
    end

    # A filter that asks for an absurd number of days ("last 999999999 days") is read as this many.
    MAXIMUM_DAYS = 36_500

    def self.range_for(filter, today)
      values = filter[:values]
      case filter[:operator]
      when "><" then [parse_date(values[0]), parse_date(values[1])]
      when ">=" then [parse_date(values[0]), nil]
      when "<=" then [nil, parse_date(values[0])]
      when "=" then [parse_date(values[0]), parse_date(values[0])]
      when ">t-" then [today - days(values[0]), today]
      when "<t-" then [nil, today - days(values[0])]
      when "t-" then [today - days(values[0]), today - days(values[0])]
      when "t+" then [today + days(values[0]), today + days(values[0])]
      when ">t+" then [today + days(values[0]), nil]
      when "><t+" then [today, today + days(values[0])]
      when "t" then [today, today]
      when "ld" then [today - 1, today - 1]
      when "w" then [today.beginning_of_week(:monday), today.end_of_week(:monday)]
      when "m" then [today.beginning_of_month, today.end_of_month]
      when "y" then [today.beginning_of_year, today.end_of_year]
      else [nil, nil]
      end
    end
    private_class_method :range_for

    # An unreadable date leaves its end of the range open.
    def self.parse_date(text)
      Date.parse(text.to_s)
    rescue Date::Error
      nil
    end
    private_class_method :parse_date

    def self.days(text)
      text.to_i.clamp(0, MAXIMUM_DAYS)
    end
    private_class_method :days
  end
end
