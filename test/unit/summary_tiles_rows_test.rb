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

require File.expand_path("../test_helper", __dir__)

class SummaryTilesRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows

  UTC = ActiveSupport::TimeZone["UTC"]
  TODAY = Date.new(2026, 10, 30)

  def setup
    User.current = User.find(1)
    Setting.display_subprojects_issues = "0"
    Issue.where(project_id: 1).delete_all
  end

  def teardown
    User.current = nil
  end

  def test_the_tiles_count_open_tickets_closed_in_the_range_their_share_the_median_and_the_backlog_change
    create_ticket("2026-09-01 10:00", nil)
    create_ticket("2026-09-02 10:00", nil)
    create_ticket("2026-08-01 10:00", "2026-10-05 10:00") # 65 days
    create_ticket("2026-10-01 10:00", "2026-10-03 10:00") # 2 days
    create_ticket("2026-08-01 10:00", "2026-09-10 10:00") # closed before the range
    filter = { "closed_on" => { operator: "><", values: %w[2026-10-01 2026-10-31] } }

    assert_equal(
      {
        "open" => { "tickets" => 2, "of_tickets" => 5 },
        "closed_in_range" => { "tickets" => 2, "percent_of_tickets" => 40 },
        "median_days" => { "days" => 33.5, "closed_tickets" => 2 },
        "backlog_change" => { "difference" => -1, "periods" => 2, "period" => "week", "direction" => "shrinking" }
      },
      tiles(filter)
    )
  end

  def test_the_backlog_change_looks_at_the_last_four_periods_only
    %w[2026-09-07 2026-09-14 2026-09-21 2026-09-28 2026-10-05 2026-10-12].each { |day| create_ticket("#{day} 10:00", nil) }

    assert_equal(
      { "difference" => 4, "periods" => 4, "period" => "week", "direction" => "growing" },
      tiles["backlog_change"]
    )
  end

  def test_the_backlog_change_is_steady_when_opened_equals_closed
    create_ticket("2026-10-06 10:00", "2026-10-07 10:00")

    assert_equal(
      { "difference" => 0, "periods" => 1, "period" => "week", "direction" => "steady" },
      tiles["backlog_change"]
    )
  end

  def test_without_tickets_nothing_divides_by_zero_and_the_values_are_missing
    assert_equal(
      {
        "open" => { "tickets" => 0, "of_tickets" => 0 },
        "closed_in_range" => { "tickets" => 0, "percent_of_tickets" => nil },
        "median_days" => { "days" => nil, "closed_tickets" => 0 },
        "backlog_change" => { "difference" => nil, "periods" => 0, "period" => "week", "direction" => nil }
      },
      tiles
    )
  end

  def test_the_status_filter_does_not_change_the_open_and_closed_counts
    create_ticket("2026-10-01 10:00", nil)
    create_ticket("2026-10-01 10:00", "2026-10-03 10:00")

    assert_equal 1, tiles({ "status_id" => { operator: "c", values: [""] } }).dig("open", "tickets")
    assert_equal 2, tiles({ "status_id" => { operator: "c", values: [""] } }).dig("open", "of_tickets")
  end

  private

  def create_ticket(created_at, closed_at)
    issue = Issue.new(project_id: 1, tracker_id: 1, author_id: 2, status_id: closed_at ? 5 : 1, priority_id: 5, subject: "ticket")
    issue.save!(validate: false)
    Issue.where(id: issue.id).update_all(created_on: utc_time(created_at), closed_on: closed_at && utc_time(closed_at))
  end

  def utc_time(text)
    Time.utc(*text.scan(/\d+/).map(&:to_i))
  end

  def tiles(filters = {})
    query = IssueQuery.new(name: "_", project: Project.find(1))
    filters.each { |field, filter| query.add_filter(field, filter[:operator], filter[:values]) }
    RubylodeStats::SummaryTilesRows.new(query, period: "week", time_zone: UTC, today: TODAY).tiles
  end
end
