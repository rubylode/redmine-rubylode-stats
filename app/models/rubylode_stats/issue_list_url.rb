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
  # Builds the address of Redmine's issue list for a set of filters, in the query format the list itself reads:
  #
  #   /projects/garden/issues?set_filter=1&f[]=status_id&op[status_id]==&v[status_id][]=5
  #
  # The path is the issue list's own (a project's or the global one). Filter ids and operators must be ones Redmine knows
  # (a field name of letters, digits and underscores, an operator from its fixed list); a filter with anything else is
  # left out, never passed on. Values are percent-escaped, so a value can never end a parameter or add one. Nothing but the
  # filters goes into the address: no names, no free text of the chart.
  module IssueListUrl
    FIELD_PATTERN = /\A[a-z][a-z0-9_]{0,63}\z/
    PATH_PATTERN = %r{\A/(?!/)[A-Za-z0-9_\-./]*\z}
    OPERATORS = %w[= ! !* * >= <= >< <t+ >t+ ><t+ t+ nd t ld nw w lw l2w nm m lm y >t- <t- ><t- t- ~ !~ ^ $ =p =!p !p *o !o o c].freeze
    MAXIMUM_VALUE_LENGTH = 255
    MAXIMUM_VALUES_PER_FILTER = 500

    # filters: { "field" => { operator: "=", values: ["5"] } }, the shape of IssueQuery#filters.
    def self.build(path, filters)
      raise ArgumentError, "not an issue list path: #{path.inspect}" unless path.is_a?(String) && PATH_PATTERN.match?(path)

      usable = filters.select { |field, filter| usable_filter?(field, filter) }
      parts = ["set_filter=1"]
      usable.each_key { |field| parts << "f[]=#{field}" }
      usable.each do |field, filter|
        parts << "op[#{field}]=#{escape(filter[:operator])}"
        values = Array(filter[:values]).first(MAXIMUM_VALUES_PER_FILTER).map { |value| value.to_s[0, MAXIMUM_VALUE_LENGTH] }
        values = [""] if values.empty?
        values.each { |value| parts << "v[#{field}][]=#{escape(value)}" }
      end
      "#{path}?#{parts.join("&")}"
    end

    def self.usable_filter?(field, filter)
      field.is_a?(String) && FIELD_PATTERN.match?(field) && filter.is_a?(Hash) && OPERATORS.include?(filter[:operator])
    end
    private_class_method :usable_filter?

    def self.escape(text)
      URI.encode_www_form_component(text.to_s).gsub("+", "%20")
    end
    private_class_method :escape
  end
end
