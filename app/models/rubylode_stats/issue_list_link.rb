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

module RubylodeStats
  # The request parameters for the issue list that holds the query's own tickets narrowed by one more filter, so a bar or
  # slice of a chart can link to what it counts.
  class IssueListLink
    # permitted_project_ids: on the cross-project page, the projects the chart counts. The link then carries a project filter
    # with them, so the issue list does not widen to projects the page left out.
    def initialize(query, permitted_project_ids: nil)
      @query = query
      @permitted_project_ids = permitted_project_ids
    end

    # extra_filter: for example "category_id" => 5; it replaces any filter the query already has on that field. A nil value
    # selects the tickets without a value; a Hash ({ operator: "o", values: [] }) is used as the filter itself.
    def parameters(extra_filter)
      filters = @query.filters.dup
      extra_filter.each { |field, value| filters[field] = filter_for(value) }
      filters["project_id"] = filter_for(@permitted_project_ids.map(&:to_s)) if @permitted_project_ids
      QueryParameters.from_filters(filters)
    end

    private

    def filter_for(value)
      case value
      when nil then { operator: "!*", values: [] }
      when Hash then value
      when Array then { operator: "=", values: value.map(&:to_s) }
      else { operator: "=", values: [value.to_s] }
      end
    end
  end
end
