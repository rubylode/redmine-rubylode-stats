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
  # The tickets a query selects, for the charts that look at closed tickets as well as open ones: the query's own scope (so
  # visibility and the cross-project permission restriction hold), without the default "open tickets" status filter and without
  # the filters on the fields named in ignored_fields.
  module QueryPopulation
    def self.scope(query, ignored_fields: [])
      filters = query.filters.except(*ignored_fields)
      filters = filters.except("status_id") if filters.dig("status_id", :operator) == "o"
      population_query = query.dup
      # dup drops what was mixed into this one query, such as the cross-project permission restriction.
      extensions = query.singleton_class.included_modules - query.class.included_modules
      population_query.extend(*extensions) if extensions.any?
      population_query.filters = filters
      population_query.base_scope
    end
  end
end
