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

class TicketsByStatusRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows

  def setup
    User.current = User.find(1)
    @original_subproject_setting = Setting.display_subprojects_issues
  end

  def teardown
    Setting.display_subprojects_issues = @original_subproject_setting
    User.current = nil
  end

  def test_counts_the_tickets_of_the_project_by_status_in_status_order
    Setting.display_subprojects_issues = "0"
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("status_id", "*", [""])

    rows = RubylodeStats::TicketsByStatusRows.new(query).rows

    assert_equal [
      { "status_id" => 1, "status" => "New", "tickets" => 3 },
      { "status_id" => 2, "status" => "Assigned", "tickets" => 1 },
      { "status_id" => 5, "status" => "Closed", "tickets" => 3 }
    ], rows
  end

  def test_follows_the_filters_of_the_query
    Setting.display_subprojects_issues = "0"
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("status_id", "c", [""])

    rows = RubylodeStats::TicketsByStatusRows.new(query).rows

    assert_equal [{ "status_id" => 5, "status" => "Closed", "tickets" => 3 }], rows
  end

  def test_includes_subproject_tickets_when_the_setting_is_on
    Setting.display_subprojects_issues = "1"
    query = IssueQuery.new(name: "_", project: Project.find(1))

    rows = RubylodeStats::TicketsByStatusRows.new(query).rows

    assert_equal query.base_scope.count, rows.sum { |row| row["tickets"] }
    assert_operator rows.sum { |row| row["tickets"] }, :>, 6
  end

  def test_counts_only_what_the_user_may_see_across_projects
    User.current = User.find(2)
    query = IssueQuery.new(name: "_", project: nil)
    query.add_filter("status_id", "*", [""])

    rows = RubylodeStats::TicketsByStatusRows.new(query).rows

    assert_equal query.issue_count, rows.sum { |row| row["tickets"] }
  end
end
