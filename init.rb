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

require "redmine"

Redmine::Plugin.register :redmine_rubylode_stats do
  name "Rubylode Stats"
  author "Rubylode"
  author_url "https://github.com/rubylode"
  description "Charts over a project's tickets: by category, open and closed, over time, who closed what"
  version "0.1.0"
  requires_redmine version_or_higher: "7.0.0"

  project_module :rubylode_stats do
    permission :view_rubylode_stats, { stats: %i[index] }, read: true
  end

  menu :project_menu, :rubylode_stats, { controller: "stats", action: "index" },
       caption: :label_stats, after: :issues, param: :project_id

  menu :top_menu, :rubylode_stats, { controller: "stats", action: "index" }, caption: :label_stats,
       if: proc { RubylodeStats::PermittedProjects.any?(User.current) }
end

