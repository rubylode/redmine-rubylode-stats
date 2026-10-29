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
  # One row per period and person: how many tickets that person closed in the period. The closer of a ticket is the author of
  # the latest journal change that moved its status from an open one to a closed one; a ticket without such a change (closed
  # by an import, say) is credited to its assignee, and with no assignee either to "None" (person_id nil). A ticket reopened and
  # closed again counts once, in the period of its latest closing (closed_on), for whoever made that latest change.
  #
  # The query's filters select the tickets as usual, so a closed-on filter is the date range; the default "open tickets" status
  # filter is ignored because this chart is about closed ones. Works with or without a project. Periods are cut in the given
  # time zone; weeks start on Monday. Only periods with a closing have a row.
  class ClosedPerPersonRows
    def initialize(query, period:, time_zone:)
      raise ArgumentError, "unknown period #{period.inspect}" unless OpenedAndClosedRows::PERIOD_START.key?(period)

      @query = query
      @period = period
      @time_zone = time_zone
    end

    def rows
      tickets = closed_tickets
      return [] if tickets.empty?

      closer_by_ticket = closers(tickets.keys)
      counts = Hash.new(0)
      tickets.each do |ticket_id, (closed_on, assignee_id)|
        counts[[period_start(closed_on), closer_by_ticket.fetch(ticket_id, assignee_id)]] += 1
      end
      names = person_names(counts.keys.filter_map(&:last))
      counts.map { |(period_start, person_id), closed| row(period_start, person_id, names, closed) }
            .sort_by { |row| [row["period"], row["person_id"].nil? ? 1 : 0, row["person"].downcase, row["person_id"].to_i] }
    end

    private

    # { ticket id => [closed_on, assignee id] } for the closed tickets the query selects (and the user may see).
    def closed_tickets
      scope = QueryPopulation.scope(@query).where.not(closed_on: nil)
      scope.pluck("issues.id", "issues.closed_on", "issues.assigned_to_id").to_h { |id, closed_on, assignee_id| [id, [closed_on, assignee_id]] }
    end

    # { ticket id => user id of the latest change from an open status to a closed one }.
    def closers(ticket_ids)
      closed_status_ids = IssueStatus.where(is_closed: true).pluck(:id).map(&:to_s)
      closers = {}
      ticket_ids.each_slice(1000) do |slice|
        changes = JournalDetail.joins(:journal)
                               .where(journals: { journalized_type: "Issue", journalized_id: slice })
                               .where(property: "attr", prop_key: "status_id", value: closed_status_ids)
                               .order("journals.created_on", "journals.id")
                               .pluck("journals.journalized_id", "journals.user_id", "journal_details.old_value")
        changes.each do |ticket_id, user_id, old_status_id|
          closers[ticket_id] = user_id unless closed_status_ids.include?(old_status_id)
        end
      end
      closers
    end

    def person_names(user_ids)
      User.where(id: user_ids).to_h { |user| [user.id, user.name] }
    end

    def row(period_start, person_id, names, closed)
      person = person_id ? names.fetch(person_id, "##{person_id}") : I18n.t(:label_stats_none)
      { "period" => period_start.iso8601, "person_id" => person_id, "person" => person, "closed" => closed }
    end

    def period_start(time)
      OpenedAndClosedRows::PERIOD_START.fetch(@period).call(time.in_time_zone(@time_zone).to_date)
    end
  end
end
