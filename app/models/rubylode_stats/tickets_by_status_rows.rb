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
  # One row per status: how many of the query's tickets have it. The query decides which tickets (filters, visibility,
  # subprojects); this class works with or without a project.
  class TicketsByStatusRows
    def initialize(query)
      @query = query
    end

    def rows
      ticket_counts = @query.base_scope.group("issues.status_id").count
      IssueStatus.where(id: ticket_counts.keys).sorted.map do |status|
        { "status_id" => status.id, "status" => status.name, "tickets" => ticket_counts.fetch(status.id) }
      end
    end
  end
end
