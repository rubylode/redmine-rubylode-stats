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

class StatsController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  helper :queries
  include QueriesHelper
  helper :stats

  # The page is one IssueQuery (Redmine's own filters, options and saved queries) drawn as the charts of one tab. To add a
  # chart, see RubylodeStats::Registry.
  def index
    retrieve_query(IssueQuery, true)
    @tab = RubylodeStats::Registry.tab(params[:tab])
    @period = RubylodeStats::Registry.period(params[:period])
    @slice_by = RubylodeStats::Registry.slice(params[:slice_by])
    @charts = @query.valid? ? @tab.chart_classes.map { |chart_class| chart_class.new(query: @query, issue_list_link: issue_list_link) } : []
  end

  private

  def issue_list_link
    link_builder = RubylodeStats::IssueListLink.new(@query)
    lambda do |extra_filter|
      url_for(link_builder.parameters(extra_filter).merge(controller: "issues", action: "index", project_id: @project, only_path: true))
    end
  end
end
