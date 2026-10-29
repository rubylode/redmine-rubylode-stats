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
  # Which projects the cross-project page may count: those where the user holds view_rubylode_stats and the module is
  # enabled (Redmine's own rule; an administrator holds every permission). Ticket visibility is still decided by the query.
  module PermittedProjects
    def self.condition(user)
      Project.allowed_to_condition(user, :view_rubylode_stats)
    end

    def self.any?(user)
      Project.where(condition(user)).exists?
    end

    # Extend an IssueQuery without a project with this module and its statement also holds the permitted-project condition,
    # so the row models need to know nothing about permissions.
    module QueryRestriction
      def project_statement
        [super, PermittedProjects.condition(User.current)].reject(&:blank?).map { |clause| "(#{clause})" }.join(" AND ")
      end
    end
  end
end
