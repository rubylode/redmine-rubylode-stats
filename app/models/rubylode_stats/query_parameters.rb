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
  # Turns a hash of query filters back into the request parameters that Redmine's issue list and this page both read,
  # so a link can carry a changed copy of the current filters.
  module QueryParameters
    def self.from_filters(filters)
      parameters = { set_filter: "1", f: [], op: {}, v: {} }
      filters.each do |field, filter|
        parameters[:f] << field
        parameters[:op][field] = filter[:operator]
        parameters[:v][field] = filter[:values].presence || [""]
      end
      parameters
    end
  end
end
