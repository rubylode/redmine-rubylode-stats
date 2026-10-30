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
  # What the page is made of. Each tab lists its chart classes and the date field that its presets filter: closed_on for the
  # charts about finished work, created_on for the charts about intake and the whole backlog.
  #
  # A new chart is one new class under charts/ plus one line in its tab's list below.
  module Registry
    Tab = Struct.new(:key, :preset_date_field, :chart_classes)

    TABS = [
      Tab.new("overview", "created_on", [Charts::TicketsByStatus, Charts::TicketsBySlice, Charts::OpenVersusClosed, Charts::OpenedAndClosed].freeze),
      Tab.new("people", "closed_on", [Charts::ClosedPerPerson].freeze),
      Tab.new("speed", "closed_on", [Charts::TimeToCloseHistogram, Charts::MedianTimeToClose].freeze),
      Tab.new("versions", "created_on", [Charts::ProgressPerVersion].freeze)
    ].freeze

    DEFAULT_TAB = "overview".freeze
    PERIODS = %w[day week month].freeze
    DEFAULT_PERIOD = "week".freeze
    SLICES = %w[category version assignee tracker priority author].freeze
    DEFAULT_SLICE = "category".freeze

    def self.tab(key)
      TABS.find { |tab| tab.key == key } || TABS.first
    end

    def self.period(value)
      PERIODS.include?(value) ? value : DEFAULT_PERIOD
    end

    def self.slice(value)
      SLICES.include?(value) ? value : DEFAULT_SLICE
    end
  end
end
