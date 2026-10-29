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
  # One row per value of the chosen slice (category, version, assignee, tracker, priority or author): how many of the query's
  # tickets have it. Tickets without a value get their own row, "None", always last; the other rows run from most to fewest
  # tickets. The query decides which tickets; this class works with or without a project.
  class SlicedTicketsRows
    Slice = Struct.new(:column, :filter_field, :model)

    SLICES = {
      "category" => Slice.new("issues.category_id", "category_id", IssueCategory),
      "version" => Slice.new("issues.fixed_version_id", "fixed_version_id", Version),
      "assignee" => Slice.new("issues.assigned_to_id", "assigned_to_id", Principal),
      "tracker" => Slice.new("issues.tracker_id", "tracker_id", Tracker),
      "priority" => Slice.new("issues.priority_id", "priority_id", IssuePriority),
      "author" => Slice.new("issues.author_id", "author_id", Principal)
    }.freeze

    # The issue filter that selects one value of the slice, for example "category_id".
    def self.filter_field(slice_by)
      SLICES.fetch(slice_by).filter_field
    end

    def initialize(query, slice_by)
      raise ArgumentError, "unknown slice #{slice_by.inspect}" unless SLICES.key?(slice_by)

      @query = query
      @slice = SLICES.fetch(slice_by)
    end

    def rows
      ticket_counts = @query.base_scope.group(@slice.column).count
      names = @slice.model.where(id: ticket_counts.keys.compact).to_h { |record| [record.id, record.name.to_s] }
      valued_rows = names.map { |id, name| { "slice_id" => id, "slice" => name, "tickets" => ticket_counts.fetch(id) } }
      rows = valued_rows.sort_by { |row| [-row["tickets"], row["slice"]] }
      rows << { "slice_id" => nil, "slice" => I18n.t(:label_stats_none), "tickets" => ticket_counts[nil] } if ticket_counts[nil]
      rows
    end
  end
end
