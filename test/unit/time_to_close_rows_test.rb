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

class TimeToCloseRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows

  UTC = ActiveSupport::TimeZone["UTC"]

  def setup
    User.current = User.find(1)
    Setting.display_subprojects_issues = "0"
    Issue.where(project_id: 1).delete_all
  end

  def teardown
    User.current = nil
  end

  def test_the_histogram_counts_whole_days_into_fixed_bins_and_always_lists_every_bin
    # days to close: 0, 1, 2, 3, 4, 7, 8, 14, 15, 30, 31, 90, 91, 400
    [0, 1, 2, 3, 4, 7, 8, 14, 15, 30, 31, 90, 91, 400].each { |days| create_ticket("2026-01-01 00:00", days_later(days)) }

    assert_equal [
      { "bin" => "0-1", "tickets" => 2 },
      { "bin" => "2-3", "tickets" => 2 },
      { "bin" => "4-7", "tickets" => 2 },
      { "bin" => "8-14", "tickets" => 2 },
      { "bin" => "15-30", "tickets" => 2 },
      { "bin" => "31-90", "tickets" => 2 },
      { "bin" => "91+", "tickets" => 2 }
    ], histogram_rows
  end

  def test_a_partial_day_is_rounded_down_and_open_tickets_are_left_out
    create_ticket("2026-01-01 10:00", "2026-01-03 09:59") # 1 day and 23 hours: 1 whole day
    create_ticket("2026-01-01 10:00", nil)

    assert_equal 1, histogram_rows.sum { |row| row["tickets"] }
    assert_equal 1, histogram_rows.first["tickets"]
  end

  def test_a_ticket_closed_before_it_was_created_counts_as_zero_days
    create_ticket("2026-03-10 10:00", "2026-03-01 10:00")

    assert_equal 1, histogram_rows.first["tickets"]
    assert_equal [{ "period" => "2026-02-23", "median_days" => 0, "closed" => 1 }], median_rows("week")
  end

  def test_the_median_is_taken_per_closing_period_and_an_even_count_averages_the_middle_two
    create_ticket("2026-09-20 10:00", "2026-10-06 10:00") # 16 days, closed in week of 10-05
    create_ticket("2026-10-01 10:00", "2026-10-07 10:00") # 6 days
    create_ticket("2026-10-01 10:00", "2026-10-08 10:00") # 7 days
    create_ticket("2026-10-01 10:00", "2026-10-09 10:00") # 8 days
    create_ticket("2026-10-01 10:00", "2026-10-14 10:00") # 13 days, closed in week of 10-12
    create_ticket("2026-10-01 10:00", nil)

    assert_equal [
      { "period" => "2026-10-05", "median_days" => 7.5, "closed" => 4 },
      { "period" => "2026-10-12", "median_days" => 13, "closed" => 1 }
    ], median_rows("week")
  end

  def test_the_median_follows_the_period_and_time_zone
    create_ticket("2026-10-01 00:00", "2026-10-12 03:30") # Sunday evening in New York
    new_york = ActiveSupport::TimeZone["America/New_York"]

    assert_equal ["2026-10-05"], median_rows("week", new_york).map { |row| row["period"] }
    assert_equal ["2026-10-12"], median_rows("week", UTC).map { |row| row["period"] }
    assert_equal ["2026-10-01"], median_rows("month", UTC).map { |row| row["period"] }
    assert_equal ["2026-10-11"], median_rows("day", new_york).map { |row| row["period"] }
  end

  def test_the_filters_apply_and_the_default_open_status_filter_is_ignored
    create_ticket("2026-10-01 10:00", "2026-10-03 10:00", tracker_id: 1)
    create_ticket("2026-10-01 10:00", "2026-10-30 10:00", tracker_id: 2)
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("tracker_id", "=", ["1"])

    assert_equal 1, RubylodeStats::TimeToCloseRows.new(query).histogram_rows.sum { |row| row["tickets"] }
    assert_equal [2], RubylodeStats::TimeToCloseRows.new(query).median_rows(period: "month", time_zone: UTC).map { |row| row["median_days"] }
  end

  def test_no_closed_tickets_gives_empty_medians_and_a_zero_histogram
    create_ticket("2026-10-01 10:00", nil)

    assert_equal [], median_rows("week")
    assert_equal 0, histogram_rows.sum { |row| row["tickets"] }
    assert_equal 7, histogram_rows.size
  end

  private

  def days_later(days)
    (Time.utc(2026, 1, 1) + days * 86_400).strftime("%Y-%m-%d %H:%M")
  end

  def create_ticket(created_at, closed_at, tracker_id: 1)
    issue = Issue.new(project_id: 1, tracker_id: tracker_id, author_id: 2, status_id: closed_at ? 5 : 1, priority_id: 5, subject: "ticket")
    issue.save!(validate: false)
    Issue.where(id: issue.id).update_all(created_on: utc_time(created_at), closed_on: closed_at && utc_time(closed_at))
  end

  def utc_time(text)
    Time.utc(*text.scan(/\d+/).map(&:to_i))
  end

  def query
    IssueQuery.new(name: "_", project: Project.find(1))
  end

  def histogram_rows
    RubylodeStats::TimeToCloseRows.new(query).histogram_rows
  end

  def median_rows(period, time_zone = UTC)
    RubylodeStats::TimeToCloseRows.new(query).median_rows(period: period, time_zone: time_zone)
  end
end
