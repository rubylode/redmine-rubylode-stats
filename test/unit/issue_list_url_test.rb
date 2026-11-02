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

class IssueListUrlTest < ActiveSupport::TestCase
  def build(filters, path = "/projects/garden/issues")
    RubylodeStats::IssueListUrl.build(path, filters)
  end

  def parsed(url)
    Rack::Utils.parse_nested_query(URI(url).query)
  end

  def test_it_emits_the_query_format_of_the_issue_list
    url = build("status_id" => { operator: "=", values: ["5"] })

    assert_equal "/projects/garden/issues?set_filter=1&f[]=status_id&op[status_id]=%3D&v[status_id][]=5", url
  end

  def test_the_global_issue_list_has_no_project_in_its_path
    assert_equal "/issues", URI(build({ "status_id" => { operator: "o", values: [] } }, "/issues")).path
  end

  def test_an_equals_filter_with_several_values
    parameters = parsed(build("project_id" => { operator: "=", values: %w[1 3 7] }))

    assert_equal %w[project_id], parameters["f"]
    assert_equal "=", parameters["op"]["project_id"]
    assert_equal %w[1 3 7], parameters["v"]["project_id"]
  end

  def test_an_open_closed_or_any_status_filter_has_an_empty_value
    %w[o c *].each do |operator|
      parameters = parsed(build("status_id" => { operator: operator, values: [] }))

      assert_equal operator, parameters["op"]["status_id"]
      assert_equal [""], parameters["v"]["status_id"]
    end
  end

  def test_a_filter_for_no_value
    assert_equal "!*", parsed(build("assigned_to_id" => { operator: "!*", values: [] }))["op"]["assigned_to_id"]
  end

  def test_a_date_range_carries_both_ends
    parameters = parsed(build("created_on" => { operator: "><", values: %w[2026-10-05 2026-10-11] }))

    assert_equal "><", parameters["op"]["created_on"]
    assert_equal %w[2026-10-05 2026-10-11], parameters["v"]["created_on"]
  end

  def test_every_filter_type_of_the_charts_can_be_combined_in_order
    filters = {
      "project_id" => { operator: "=", values: ["2"] }, "tracker_id" => { operator: "=", values: ["1"] },
      "status_id" => { operator: "c", values: [] }, "assigned_to_id" => { operator: "=", values: ["9"] },
      "priority_id" => { operator: "=", values: ["4"] }, "category_id" => { operator: "!*", values: [] },
      "fixed_version_id" => { operator: "=", values: ["3"] }, "author_id" => { operator: "=", values: ["5"] },
      "closed_on" => { operator: "><", values: %w[2026-10-01 2026-10-31] }, "cf_12" => { operator: "=", values: ["8"] }
    }
    parameters = parsed(build(filters))

    assert_equal filters.keys, parameters["f"]
    filters.each do |field, filter|
      assert_equal filter[:operator], parameters["op"][field], field
      assert_equal(filter[:values].empty? ? [""] : filter[:values], parameters["v"][field], field)
    end
  end

  def test_a_value_is_escaped_so_it_cannot_end_or_add_a_parameter
    url = build("subject" => { operator: "~", values: ["a&f[]=assigned_to_id&x=1 #frag?"] })
    parameters = parsed(url)

    assert_equal %w[subject], parameters["f"]
    assert_equal ["a&f[]=assigned_to_id&x=1 #frag?"], parameters["v"]["subject"]
    assert_no_match(/[ #]/, url)
    assert_equal 1, url.scan("f[]=").size
  end

  def test_a_hostile_field_name_is_left_out
    hostile = ["status_id]=x&f[", "Status", "status id", "../x", "a" * 80, "", "1status", "status_id\n", "<script>"]
    filters = hostile.to_h { |field| [field, { operator: "=", values: ["1"] }] }.merge("status_id" => { operator: "o", values: [] })
    url = build(filters)

    assert_equal %w[status_id], parsed(url)["f"]
    assert_no_match(/script|\.\.|%0A|\n/, url)
  end

  def test_an_unknown_operator_leaves_the_filter_out
    url = build("status_id" => { operator: "=&f[]=x", values: ["1"] }, "tracker_id" => { operator: "javascript:", values: ["1"] },
                "category_id" => { operator: nil, values: [] }, "author_id" => { operator: "=", values: ["2"] })

    assert_equal %w[author_id], parsed(url)["f"]
  end

  def test_a_path_that_is_not_an_issue_list_path_is_refused
    ["https://elsewhere.example/issues", "//elsewhere.example/issues", "/issues?x=1", "/issues#a", "issues", nil, "/is sues", "/issues\nX: y"].each do |path|
      assert_raises(ArgumentError, path.inspect) { RubylodeStats::IssueListUrl.build(path, {}) }
    end
  end

  def test_a_value_is_cut_to_a_sensible_length_and_the_values_to_a_sensible_number
    parameters = parsed(build("subject" => { operator: "~", values: ["x" * 5000] }, "project_id" => { operator: "=", values: (1..900).map(&:to_s) }))

    assert_equal 255, parameters["v"]["subject"].first.size
    assert_equal 500, parameters["v"]["project_id"].size
  end

  def test_no_filters_gives_only_set_filter
    assert_equal "/issues?set_filter=1", build({}, "/issues")
  end
end
