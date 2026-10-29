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

module RubylodeStats
  # Two rows, open and closed (always both, even with no tickets), by the "closed" flag of the ticket's status.
  class OpenVersusClosedRows
    def initialize(query)
      @query = query
    end

    def rows
      ticket_counts = @query.base_scope.group("#{IssueStatus.table_name}.is_closed").count
      closed_tickets = ticket_counts.sum { |is_closed, tickets| ActiveModel::Type::Boolean.new.cast(is_closed) ? tickets : 0 }
      [
        { "state" => "open", "tickets" => ticket_counts.values.sum - closed_tickets },
        { "state" => "closed", "tickets" => closed_tickets }
      ]
    end
  end
end
