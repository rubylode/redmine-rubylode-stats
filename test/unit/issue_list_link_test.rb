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

class IssueListLinkTest < ActiveSupport::TestCase
  def query_with_status_filter
    IssueQuery.new(name: "_").tap { |query| query.add_filter("status_id", "*", [""]) }
  end

  def test_a_value_replaces_the_filter_on_its_field_with_equals
    parameters = RubylodeStats::IssueListLink.new(query_with_status_filter).parameters("category_id" => 3)

    assert_equal %w[status_id category_id], parameters[:f]
    assert_equal "=", parameters[:op]["category_id"]
    assert_equal ["3"], parameters[:v]["category_id"]
    assert_equal "*", parameters[:op]["status_id"]
  end

  def test_nil_means_the_ticket_has_no_value
    parameters = RubylodeStats::IssueListLink.new(query_with_status_filter).parameters("category_id" => nil)

    assert_equal "!*", parameters[:op]["category_id"]
  end

  def test_an_operator_can_be_given_in_full
    parameters = RubylodeStats::IssueListLink.new(query_with_status_filter).parameters("status_id" => { operator: "o", values: [] })

    assert_equal %w[status_id], parameters[:f]
    assert_equal "o", parameters[:op]["status_id"]
  end
end
