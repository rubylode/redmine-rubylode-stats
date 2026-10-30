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
  before_action :find_optional_project_by_project_id, :authorize_stats

  helper :queries
  include QueriesHelper
  helper :stats

  # The page is one IssueQuery (Redmine's own filters, options and saved queries) drawn as the charts of one tab. To add a
  # chart, see RubylodeStats::Registry.
  def index
    retrieve_query(IssueQuery, true)
    @query.extend(RubylodeStats::PermittedProjects::QueryRestriction) unless @project
    @tab = RubylodeStats::Registry.tab(params[:tab])
    apply_default_range
    @period = RubylodeStats::Registry.period(params[:period])
    @slice_by = RubylodeStats::Registry.slice(params[:slice_by])
    @shape = params[:shape] == "pie" ? "pie" : "bar"
    @tiles = overview_tiles
    @charts = @query.valid? ? @tab.chart_classes.map { |chart_class| chart_class.new(query: @query, issue_list_link: issue_list_link, options: chart_options) } : []
  end


  private

  # The first load, with no filter chosen by the user, shows this quarter on the date that suits the tab. A request that carries
  # filters, a preset or a saved query is the user's own choice and is left alone; "All time" is such a request.
  def apply_default_range
    return unless @query.new_record? && default_filters_only? && params.values_at(:set_filter, :query_id, :f).all?(&:blank?)

    date_field = @tab.preset_date_field
    @query.filters = @query.filters.except("status_id") if date_field == "closed_on"
    default_filter = RubylodeStats::Presets.filter_for(RubylodeStats::Presets::DEFAULT_KEY, User.current.today)
    @query.add_filter(date_field, default_filter[:operator], default_filter[:values])
  end

  def default_filters_only?
    @query.filters.keys == ["status_id"] && @query.filters.dig("status_id", :operator) == "o"
  end

  def overview_tiles
    return unless @tab.key == "overview" && @query.valid?

    time_zone = User.current.time_zone || Time.zone
    RubylodeStats::SummaryTilesRows.new(@query, period: @period, time_zone: time_zone, today: User.current.today).tiles
  end

  def find_optional_project_by_project_id
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    User.current.logged? ? render_404 : require_login
  end

  # One project: Redmine's own check. All projects: at least one project must hold the permission and the module.
  def authorize_stats
    return authorize if @project
    deny_access unless RubylodeStats::PermittedProjects.any?(User.current)
  end

  def chart_options
    { slice_by: @slice_by, shape: @shape, period: @period, time_zone: User.current.time_zone || Time.zone }
  end

  def permitted_project_ids
    Project.where(RubylodeStats::PermittedProjects.condition(User.current)).pluck(:id) unless @project
  end

  def issue_list_link
    link_builder = RubylodeStats::IssueListLink.new(@query, permitted_project_ids: permitted_project_ids)
    lambda do |extra_filter|
      url_for(link_builder.parameters(extra_filter).merge(controller: "issues", action: "index", project_id: @project, only_path: true))
    end
  end
end
