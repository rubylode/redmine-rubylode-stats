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
  # The figures of one chart as a table, for the "View data" block under it: the headers, and a row per mark with its cells
  # as text and the links that open the matching tickets (each [text, address]; none when the viewer cannot open the list).
  class DataTable
    Row = Struct.new(:cells, :links)

    attr_reader :headers, :rows

    def initialize(headers:, rows:)
      @headers = headers
      @rows = rows
    end

    # A row from its cells and any number of [text, address] pairs; a pair without an address is dropped.
    def self.row(cells, *links)
      Row.new(cells, links.select { |_text, address| address })
    end

    def links?
      rows.any? { |row| row.links.any? }
    end
  end
end
