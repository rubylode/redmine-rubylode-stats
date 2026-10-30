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

class ProgressPerVersionRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :versions, :workflows

  def setup
    User.current = User.find(1)
    Setting.display_subprojects_issues = "0"
  end

  def teardown
    User.current = nil
  end

  def test_one_row_per_version_with_tickets_by_due_date_and_no_version_last
    assert_equal [
      { "version_id" => 1, "name" => "0.1", "due_date" => "2006-07-01", "overdue" => false, "done" => 1, "remaining" => 0, "total" => 1, "percent" => 100 },
      { "version_id" => 2, "name" => "1.0", "due_date" => 20.days.from_now.to_date.iso8601, "overdue" => false, "done" => 1, "remaining" => 1, "total" => 2, "percent" => 50 },
      { "version_id" => nil, "name" => I18n.t(:label_stats_no_version), "due_date" => nil, "overdue" => false, "done" => 1, "remaining" => 3, "total" => 4, "percent" => 25 }
    ], rows_for(Project.find(1))
  end

  def test_the_status_filter_does_not_apply
    open_only = rows_for(Project.find(1), status_operator: "o")
    closed_only = rows_for(Project.find(1), status_operator: "c")

    assert_equal rows_for(Project.find(1)), open_only
    assert_equal open_only, closed_only
  end

  def test_other_filters_apply
    rows = rows_for(Project.find(1), tracker_ids: ["2"])

    assert_equal [{ "done" => 0, "remaining" => 1, "total" => 1 }],
                 rows.map { |row| row.slice("done", "remaining", "total") }
  end

  def test_a_version_past_its_due_date_and_still_open_is_overdue
    Version.find(2).update_columns(effective_date: 3.days.ago.to_date, status: "open")
    Version.find(1).update_columns(status: "closed")

    overdue_by_name = rows_for(Project.find(1)).to_h { |row| [row["name"], row["overdue"]] }

    assert_equal true, overdue_by_name["1.0"]
    assert_equal false, overdue_by_name["0.1"]
  end

  def test_a_version_without_a_due_date_comes_after_dated_ones_and_before_no_version
    Issue.where(id: 3).update_all(fixed_version_id: 3)

    assert_equal ["0.1", "1.0", "2.0", I18n.t(:label_stats_no_version)], rows_for(Project.find(1)).map { |row| row["name"] }
  end

  def test_without_a_project_shared_versions_of_other_projects_appear_by_their_own_name
    Issue.where(id: 4).update_all(fixed_version_id: 5)
    names = rows_for(nil).map { |row| row["name"] }

    assert_includes names, "Alpha"
  end

  def test_no_rows_when_a_query_selects_nothing
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("tracker_id", "=", ["99"])

    assert_equal [], RubylodeStats::ProgressPerVersionRows.new(query).rows
  end

  private

  def rows_for(project, status_operator: nil, tracker_ids: nil)
    query = IssueQuery.new(name: "_", project: project)
    query.add_filter("status_id", status_operator || "*", [""])
    query.add_filter("tracker_id", "=", tracker_ids) if tracker_ids
    RubylodeStats::ProgressPerVersionRows.new(query).rows
  end
end
