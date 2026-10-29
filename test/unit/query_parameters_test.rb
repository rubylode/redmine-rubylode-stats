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

class QueryParametersTest < ActiveSupport::TestCase
  def test_turns_filters_into_the_parameters_the_issue_list_reads
    filters = { "status_id" => { operator: "=", values: ["5"] }, "closed_on" => { operator: "><", values: %w[2026-10-01 2026-10-31] } }

    assert_equal(
      {
        set_filter: "1",
        f: %w[status_id closed_on],
        op: { "status_id" => "=", "closed_on" => "><" },
        v: { "status_id" => ["5"], "closed_on" => %w[2026-10-01 2026-10-31] }
      },
      RubylodeStats::QueryParameters.from_filters(filters)
    )
  end

  def test_a_filter_without_values_still_gets_an_empty_value
    parameters = RubylodeStats::QueryParameters.from_filters("status_id" => { operator: "o", values: [""] })

    assert_equal({ "status_id" => [""] }, parameters[:v])
  end
end
