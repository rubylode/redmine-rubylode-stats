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
  # The row of date presets. A preset is only a date range filter on the query; the caller picks which date field it applies
  # to. Weeks start on Monday, and "today" is the viewing user's today, so boundaries follow the user's time zone.
  module Presets
    KEYS = %w[this_week this_month this_quarter last_30_days this_year all_time].freeze

    def self.filter_for(key, today)
      case key
      when "this_week"
        between(today.beginning_of_week(:monday), today.end_of_week(:monday))
      when "this_month"
        between(today.beginning_of_month, today.end_of_month)
      when "this_quarter"
        between(today.beginning_of_quarter, today.end_of_quarter)
      when "last_30_days"
        { operator: ">t-", values: ["30"] }
      when "this_year"
        between(today.beginning_of_year, today.end_of_year)
      when "all_time"
        nil
      else
        raise ArgumentError, "unknown preset #{key.inspect}"
      end
    end

    def self.between(first_day, last_day)
      { operator: "><", values: [first_day.iso8601, last_day.iso8601] }
    end
    private_class_method :between
  end
end
