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
  # One row per version that has tickets: how many are done (the ticket's status is closed) and how many remain, with the
  # share done. Versions run by due date, those without a date after them, and tickets without a version come last as their
  # own row. The status filter is ignored (a progress chart needs both halves); every other filter applies.
  class ProgressPerVersionRows
    def initialize(query)
      @query = query
    end

    def rows
      version_rows = counts_by_version.except(nil).map { |version_id, counts| version_row(versions.fetch(version_id), counts) }
      ordered = version_rows.sort_by { |row| [row["due_date"] ? 0 : 1, row["due_date"].to_s, row["name"], row["version_id"]] }
      ordered << row_without_version(counts_by_version[nil]) if counts_by_version[nil]
      ordered
    end

    private

    def counts_by_version
      @counts_by_version ||= begin
        grouped = QueryPopulation.scope(@query, ignored_fields: ["status_id"])
                                 .group("#{Issue.table_name}.fixed_version_id", "#{IssueStatus.table_name}.is_closed").count
        grouped.each_with_object({}) do |((version_id, is_closed), tickets), counts|
          counts[version_id] ||= { done: 0, remaining: 0 }
          counts[version_id][ActiveModel::Type::Boolean.new.cast(is_closed) ? :done : :remaining] += tickets
        end
      end
    end

    def versions
      @versions ||= Version.where(id: counts_by_version.keys.compact).index_by(&:id)
    end

    def version_row(version, counts)
      due_date = version.effective_date
      build_row(version.id, version.name, due_date, version.open? && due_date.present? && due_date < Date.current, counts)
    end

    def row_without_version(counts)
      build_row(nil, I18n.t(:label_stats_no_version), nil, false, counts)
    end

    def build_row(version_id, name, due_date, overdue, counts)
      total = counts[:done] + counts[:remaining]
      {
        "version_id" => version_id, "name" => name, "due_date" => due_date&.iso8601, "overdue" => overdue,
        "done" => counts[:done], "remaining" => counts[:remaining], "total" => total, "percent" => (counts[:done] * 100.0 / total).round
      }
    end
  end
end
