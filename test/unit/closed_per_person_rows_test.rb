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

class ClosedPerPersonRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows

  UTC = ActiveSupport::TimeZone["UTC"]
  NEW_YORK = ActiveSupport::TimeZone["America/New_York"]
  JOHN = 2 # John Smith
  DAVE = 3 # Dave Lopper
  NEW = 1
  CLOSED = 5
  REJECTED = 6

  def setup
    User.current = User.find(1)
    Setting.display_subprojects_issues = "0"
    Setting.user_format = "firstname_lastname"
    Issue.where(project_id: 1).delete_all
  end

  def teardown
    User.current = nil
  end

  def test_the_closer_is_the_author_of_the_status_change_and_the_assignee_stands_in_when_there_is_none
    closed_by_journal = create_closed_ticket("2026-10-06 10:00", assignee_id: DAVE)
    add_status_change(closed_by_journal, user_id: JOHN, at: "2026-10-06 10:00", from: NEW, to: CLOSED)
    create_closed_ticket("2026-10-07 10:00", assignee_id: DAVE) # imported: closed with no journal
    create_closed_ticket("2026-10-08 10:00") # no journal and no assignee

    assert_equal [
      { "period" => "2026-10-05", "person_id" => DAVE, "person" => "Dave Lopper", "closed" => 1 },
      { "period" => "2026-10-05", "person_id" => JOHN, "person" => "John Smith", "closed" => 1 },
      { "period" => "2026-10-05", "person_id" => nil, "person" => "None", "closed" => 1 }
    ], rows_for("week", UTC)
  end

  def test_a_ticket_reopened_and_closed_again_counts_once_at_its_latest_closing_for_whoever_made_it
    ticket = create_closed_ticket("2026-10-14 10:00", assignee_id: JOHN)
    add_status_change(ticket, user_id: JOHN, at: "2026-10-01 10:00", from: NEW, to: CLOSED)
    add_status_change(ticket, user_id: JOHN, at: "2026-10-03 10:00", from: CLOSED, to: NEW)
    add_status_change(ticket, user_id: DAVE, at: "2026-10-14 10:00", from: NEW, to: CLOSED)

    assert_equal [
      { "period" => "2026-10-12", "person_id" => DAVE, "person" => "Dave Lopper", "closed" => 1 }
    ], rows_for("week", UTC)
  end

  def test_a_change_from_one_closed_status_to_another_is_not_a_new_closing
    ticket = create_closed_ticket("2026-10-06 10:00")
    add_status_change(ticket, user_id: JOHN, at: "2026-10-06 10:00", from: NEW, to: CLOSED)
    add_status_change(ticket, user_id: DAVE, at: "2026-10-07 10:00", from: CLOSED, to: REJECTED)

    assert_equal [{ "period" => "2026-10-05", "person_id" => JOHN, "person" => "John Smith", "closed" => 1 }], rows_for("week", UTC)
  end

  def test_changes_of_other_fields_and_open_tickets_are_ignored
    open_ticket = create_ticket(status_id: NEW, assignee_id: DAVE)
    add_status_change(open_ticket, user_id: JOHN, at: "2026-10-06 10:00", from: CLOSED, to: NEW)
    ticket = create_closed_ticket("2026-10-06 10:00", assignee_id: DAVE)
    add_detail_change(ticket, user_id: JOHN, at: "2026-10-06 10:00", key: "priority_id", from: "4", to: "5")

    assert_equal [{ "period" => "2026-10-05", "person_id" => DAVE, "person" => "Dave Lopper", "closed" => 1 }], rows_for("week", UTC)
  end

  def test_day_and_month_periods_and_the_user_time_zone
    create_closed_ticket("2026-10-12 03:30", assignee_id: JOHN) # Sunday evening in New York
    create_closed_ticket("2026-11-01 12:00", assignee_id: JOHN)

    assert_equal %w[2026-10-12 2026-11-01], rows_for("day", UTC).map { |row| row["period"] }
    assert_equal %w[2026-10-01 2026-11-01], rows_for("month", UTC).map { |row| row["period"] }
    assert_equal %w[2026-10-05 2026-10-26], rows_for("week", NEW_YORK).map { |row| row["period"] }
    assert_equal %w[2026-10-11], rows_for("day", NEW_YORK).first(1).map { |row| row["period"] }
  end

  def test_the_closed_on_filter_is_the_range_and_other_filters_apply
    create_closed_ticket("2026-10-06 10:00", assignee_id: JOHN, tracker_id: 1)
    create_closed_ticket("2026-10-07 10:00", assignee_id: JOHN, tracker_id: 2)
    create_closed_ticket("2026-09-07 10:00", assignee_id: JOHN, tracker_id: 1)

    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("closed_on", "><", %w[2026-10-01 2026-10-31])
    query.add_filter("tracker_id", "=", ["1"])
    rows = RubylodeStats::ClosedPerPersonRows.new(query, period: "week", time_zone: UTC).rows

    assert_equal [{ "period" => "2026-10-05", "person_id" => JOHN, "person" => "John Smith", "closed" => 1 }], rows
  end

  def test_tickets_the_user_cannot_see_are_not_counted
    User.current = User.anonymous
    Project.find(1).update_column(:is_public, false)
    create_closed_ticket("2026-10-06 10:00", assignee_id: JOHN)

    assert_equal [], rows_for("week", UTC)
  end

  def test_no_closed_tickets_gives_no_rows
    create_ticket(status_id: NEW)

    assert_equal [], rows_for("week", UTC)
  end

  private

  def create_ticket(status_id:, assignee_id: nil, tracker_id: 1)
    issue = Issue.new(project_id: 1, tracker_id: tracker_id, author_id: 2, status_id: status_id, assigned_to_id: assignee_id,
                      priority_id: 5, subject: "ticket")
    issue.save!(validate: false)
    issue
  end

  def create_closed_ticket(closed_at, assignee_id: nil, tracker_id: 1)
    issue = create_ticket(status_id: CLOSED, assignee_id: assignee_id, tracker_id: tracker_id)
    Issue.where(id: issue.id).update_all(created_on: Time.utc(2026, 1, 1), closed_on: utc_time(closed_at))
    issue
  end

  def add_status_change(issue, user_id:, at:, from:, to:)
    add_detail_change(issue, user_id: user_id, at: at, key: "status_id", from: from.to_s, to: to.to_s)
  end

  def add_detail_change(issue, user_id:, at:, key:, from:, to:)
    journal = Journal.new(journalized: issue, user_id: user_id, notes: "", created_on: utc_time(at))
    journal.details.build(property: "attr", prop_key: key, old_value: from, value: to)
    journal.save!
  end

  def utc_time(text)
    Time.utc(*text.scan(/\d+/).map(&:to_i))
  end

  def rows_for(period, time_zone)
    query = IssueQuery.new(name: "_", project: Project.find(1))
    RubylodeStats::ClosedPerPersonRows.new(query, period: period, time_zone: time_zone).rows
  end
end
