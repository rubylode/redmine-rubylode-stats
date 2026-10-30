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

class OpenVersusClosedRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows

  def setup
    User.current = User.find(1)
    Setting.display_subprojects_issues = "0"
  end

  def teardown
    User.current = nil
  end

  def test_counts_open_and_closed_tickets
    assert_equal [
      { "state" => "open", "tickets" => 4 },
      { "state" => "closed", "tickets" => 3 }
    ], rows_with(nil)
  end

  def test_the_status_filter_is_ignored_so_both_halves_are_always_counted
    both_halves = [{ "state" => "open", "tickets" => 4 }, { "state" => "closed", "tickets" => 3 }]

    assert_equal both_halves, rows_with("c")
    assert_equal both_halves, rows_with("o")
  end

  def test_the_other_filters_still_apply
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("status_id", "c", [""])
    query.add_filter("tracker_id", "=", ["2"])

    assert_equal [{ "state" => "open", "tickets" => 1 }, { "state" => "closed", "tickets" => 0 }],
                 RubylodeStats::OpenVersusClosedRows.new(query).rows
  end

  private

  def rows_with(status_operator)
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("status_id", status_operator, [""]) if status_operator
    query.add_filter("status_id", "*", [""]) unless status_operator
    RubylodeStats::OpenVersusClosedRows.new(query).rows
  end
end
