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
    def initialize(query)
      @query = query
    end

    # extra_filter: for example "status_id" => 5; it replaces any filter the query already has on that field.
    def parameters(extra_filter)
      filters = @query.filters.dup
      extra_filter.each { |field, value| filters[field] = { operator: "=", values: [value.to_s] } }
      QueryParameters.from_filters(filters)
    end
  end
end
