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

module StatsHelper
  # Parameters that keep the query, the chosen tab, period and slice when a link changes one thing.
  def stats_link_parameters(replacement_filters: nil)
    parameters = if replacement_filters
      RubylodeStats::QueryParameters.from_filters(replacement_filters)
    elsif @query.persisted?
      { query_id: @query.id }
    else
      RubylodeStats::QueryParameters.from_filters(@query.filters)
    end
    parameters.merge(tab: @tab.key, period: @period, slice_by: @slice_by)
  end

  def stats_page_path(parameters = {})
    @project ? project_stats_path(@project, parameters) : stats_path(parameters)
  end

  def stats_preset_links
    today = User.current.today
    date_field = @tab.preset_date_field
    RubylodeStats::Presets::KEYS.map do |preset_key|
      filters = @query.filters.except(date_field)
      # A closed-on range only matches closed tickets, so the default "open" status filter would empty the chart.
      filters = filters.except("status_id") if date_field == "closed_on" && filters.dig("status_id", :operator) == "o"
      date_filter = RubylodeStats::Presets.filter_for(preset_key, today)
      filters = filters.merge(date_field => date_filter) if date_filter
      link_to l("label_stats_preset_#{preset_key}"), stats_page_path(stats_link_parameters(replacement_filters: filters)),
              class: "stats-preset", data: { preset: preset_key }
    end
  end

  def stats_tab_links
    RubylodeStats::Registry::TABS.map do |tab|
      link_to l("label_stats_tab_#{tab.key}"), stats_page_path(stats_link_parameters.merge(tab: tab.key)),
              class: ["stats-tab", ("selected" if tab == @tab)].compact.join(" "), data: { tab: tab.key }
    end
  end

  def stats_period_options
    options_for_select(RubylodeStats::Registry::PERIODS.map { |period| [l("label_stats_period_#{period}"), period] }, @period)
  end

  def stats_slice_options
    options_for_select(RubylodeStats::Registry::SLICES.map { |slice| [l("label_stats_slice_#{slice}"), slice] }, @slice_by)
  end
end
