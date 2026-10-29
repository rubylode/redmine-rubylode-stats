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

require File.expand_path("../test_helper", __dir__)

class OpenedAndClosedRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows

  UTC = ActiveSupport::TimeZone["UTC"]
  NEW_YORK = ActiveSupport::TimeZone["America/New_York"]

  def setup
    User.current = User.find(1)
    Setting.display_subprojects_issues = "0"
    Issue.where(project_id: 1).delete_all
  end

  def teardown
    User.current = nil
  end

  def test_weekly_rows_open_the_backlog_with_tickets_open_before_the_range_and_carry_it_forward
    create_ticket("2026-10-05 10:00", "2026-10-13 10:00")
    create_ticket("2026-10-06 10:00", nil)
    create_ticket("2026-10-14 10:00", "2026-10-15 10:00")
    create_ticket("2026-09-20 10:00", nil)
    create_ticket("2026-09-01 10:00", "2026-09-10 10:00")
    create_ticket("2026-09-25 10:00", "2026-10-07 10:00")

    rows = rows_for("week", UTC, created_on: { operator: "><", values: %w[2026-10-05 2026-10-18] })

    assert_equal [
      { "period" => "2026-10-05", "opened" => 2, "closed" => 1, "backlog" => 3 },
      { "period" => "2026-10-12", "opened" => 1, "closed" => 2, "backlog" => 2 }
    ], rows
  end

  def test_without_a_date_filter_the_range_runs_from_the_first_to_the_last_event_and_empty_periods_are_zero
    create_ticket("2026-10-05 10:00", nil)
    create_ticket("2026-10-21 10:00", "2026-10-22 10:00")

    assert_equal [
      { "period" => "2026-10-05", "opened" => 1, "closed" => 0, "backlog" => 1 },
      { "period" => "2026-10-12", "opened" => 0, "closed" => 0, "backlog" => 1 },
      { "period" => "2026-10-19", "opened" => 1, "closed" => 1, "backlog" => 1 }
    ], rows_for("week", UTC)
  end

  def test_a_ticket_created_late_on_sunday_evening_belongs_to_the_week_in_the_user_time_zone
    create_ticket("2026-10-12 03:30", nil) # Sunday 23:30 in New York, Monday in UTC

    assert_equal [{ "period" => "2026-10-05", "opened" => 1, "closed" => 0, "backlog" => 1 }], rows_for("week", NEW_YORK)
    assert_equal [{ "period" => "2026-10-12", "opened" => 1, "closed" => 0, "backlog" => 1 }], rows_for("week", UTC)
  end

  def test_daily_and_monthly_periods
    create_ticket("2026-09-30 22:00", "2026-10-02 12:00")

    assert_equal [
      { "period" => "2026-09-30", "opened" => 1, "closed" => 0, "backlog" => 1 },
      { "period" => "2026-10-01", "opened" => 0, "closed" => 0, "backlog" => 1 },
      { "period" => "2026-10-02", "opened" => 0, "closed" => 1, "backlog" => 0 }
    ], rows_for("day", UTC)
    assert_equal [
      { "period" => "2026-09-01", "opened" => 1, "closed" => 0, "backlog" => 1 },
      { "period" => "2026-10-01", "opened" => 0, "closed" => 1, "backlog" => 0 }
    ], rows_for("month", UTC)
  end

  def test_other_filters_still_apply_and_the_default_open_status_filter_is_ignored
    create_ticket("2026-10-05 10:00", "2026-10-06 10:00", tracker_id: 1)
    create_ticket("2026-10-05 10:00", nil, tracker_id: 2)
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("tracker_id", "=", ["1"])

    rows = RubylodeStats::OpenedAndClosedRows.new(query, period: "week", time_zone: UTC).rows

    assert_equal [{ "period" => "2026-10-05", "opened" => 1, "closed" => 1, "backlog" => 0 }], rows
  end

  def test_no_tickets_gives_no_rows
    assert_equal [], rows_for("week", UTC)
  end

  def test_a_huge_last_n_days_filter_stops_at_the_first_ticket_instead_of_looping_for_ever
    create_ticket("2026-10-05 10:00", nil)

    rows = rows_for("day", UTC, created_on: { operator: ">t-", values: ["999999999"] })

    assert_equal "2026-10-05", rows.first["period"]
    assert_equal 1, rows.first["opened"]
    assert_operator rows.size, :<, 40_000
  end

  def test_a_far_past_and_far_future_range_is_cut_to_the_days_that_hold_tickets
    create_ticket("2026-10-05 10:00", nil)
    create_ticket("2026-10-07 10:00", "2026-10-07 12:00")

    rows = rows_for("day", UTC, created_on: { operator: "><", values: %w[0001-01-01 9999-12-31] })

    assert_equal %w[2026-10-05 2026-10-06 2026-10-07], rows.map { |row| row["period"] }
  end

  def test_an_unreadable_date_leaves_the_end_open
    create_ticket("2026-10-05 10:00", nil)
    create_ticket("2026-10-06 10:00", nil)

    rows = rows_for("day", UTC, created_on: { operator: "><", values: ["2026-10-06", "garbage"] })

    assert_equal ["2026-10-06"], rows.map { |row| row["period"] }
  end

  def test_more_than_five_thousand_periods_keep_only_the_most_recent_ones_and_the_backlog_still_counts_the_older_tickets
    create_ticket("2000-01-01 10:00", nil)
    create_ticket("2026-10-05 10:00", nil)

    rows = rows_for("day", UTC)

    assert_equal 5000, rows.size
    assert_equal "2026-10-05", rows.last["period"]
    assert_equal({ "period" => "2013-01-27", "opened" => 0, "closed" => 0, "backlog" => 1 }, rows.first)
    assert_equal 2, rows.last["backlog"]
  end

  private

  def create_ticket(created_at, closed_at, tracker_id: 1)
    issue = Issue.new(project_id: 1, tracker_id: tracker_id, author_id: 2, status_id: closed_at ? 5 : 1, priority_id: 5, subject: "ticket")
    issue.save!(validate: false)
    Issue.where(id: issue.id).update_all(created_on: Time.utc(*created_at.scan(/\d+/).map(&:to_i)),
                                        closed_on: closed_at && Time.utc(*closed_at.scan(/\d+/).map(&:to_i)))
  end

  def rows_for(period, time_zone, date_filters = {})
    query = IssueQuery.new(name: "_", project: Project.find(1))
    date_filters.each { |field, filter| query.add_filter(field.to_s, filter[:operator], filter[:values]) }
    RubylodeStats::OpenedAndClosedRows.new(query, period: period, time_zone: time_zone).rows
  end
end
