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

class SlicedTicketsRowsTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :issue_categories, :versions, :workflows

  def setup
    User.current = User.find(1)
    @original_subproject_setting = Setting.display_subprojects_issues
    Setting.display_subprojects_issues = "0"
  end

  def teardown
    Setting.display_subprojects_issues = @original_subproject_setting
    User.current = nil
  end

  def test_by_category_keeps_tickets_without_a_category_as_none
    assert_equal [
      { "slice_id" => 1, "slice" => "Printing", "tickets" => 3 },
      { "slice_id" => nil, "slice" => "None", "tickets" => 4 }
    ], rows_for("category")
  end

  def test_by_version_orders_by_ticket_count_and_puts_none_last
    assert_equal [
      { "slice_id" => 2, "slice" => "1.0", "tickets" => 2 },
      { "slice_id" => 1, "slice" => "0.1", "tickets" => 1 },
      { "slice_id" => nil, "slice" => "None", "tickets" => 4 }
    ], rows_for("version")
  end

  def test_by_assignee
    assert_equal [
      { "slice_id" => 3, "slice" => "Dave Lopper", "tickets" => 2 },
      { "slice_id" => nil, "slice" => "None", "tickets" => 5 }
    ], rows_for("assignee")
  end

  def test_by_tracker
    assert_equal [
      { "slice_id" => 1, "slice" => "Bug", "tickets" => 6 },
      { "slice_id" => 2, "slice" => "Feature request", "tickets" => 1 }
    ], rows_for("tracker")
  end

  def test_by_priority
    assert_equal [
      { "slice_id" => 5, "slice" => "Normal", "tickets" => 5 },
      { "slice_id" => 4, "slice" => "Low", "tickets" => 2 }
    ], rows_for("priority")
  end

  def test_by_author
    assert_equal [
      { "slice_id" => 2, "slice" => "John Smith", "tickets" => 6 },
      { "slice_id" => 3, "slice" => "Dave Lopper", "tickets" => 1 }
    ], rows_for("author")
  end

  def test_follows_the_filters_of_the_query
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("status_id", "c", [""])

    rows = RubylodeStats::SlicedTicketsRows.new(query, "category").rows

    assert_equal [
      { "slice_id" => 1, "slice" => "Printing", "tickets" => 2 },
      { "slice_id" => nil, "slice" => "None", "tickets" => 1 }
    ], rows
  end

  def test_an_unknown_slice_is_refused
    assert_raises(ArgumentError) { RubylodeStats::SlicedTicketsRows.new(IssueQuery.new(name: "_"), "colour") }
  end

  private

  def rows_for(slice_by)
    query = IssueQuery.new(name: "_", project: Project.find(1))
    query.add_filter("status_id", "*", [""])
    RubylodeStats::SlicedTicketsRows.new(query, slice_by).rows
  end
end
