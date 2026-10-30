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
  STATS_DASH = "–".freeze

  # Parameters that keep the query, the chosen tab, period and slice when a link changes one thing.
  def stats_link_parameters(replacement_filters: nil)
    parameters = if replacement_filters
      RubylodeStats::QueryParameters.from_filters(replacement_filters)
    elsif @query.persisted?
      { query_id: @query.id }
    else
      RubylodeStats::QueryParameters.from_filters(@query.filters)
    end
    parameters.merge(tab: @tab.key, period: @period, slice_by: @slice_by, shape: @shape)
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
      active = stats_preset_active?(date_filter)
      link_to l("label_stats_preset_#{preset_key}"), stats_page_path(stats_link_parameters(replacement_filters: filters)),
              class: ["stats-preset", ("active" if active)].compact.join(" "), data: { preset: preset_key },
              "aria-current": (active ? "true" : nil)
    end
  end

  # A preset is active when the date filter of the tab matches its range; "All time" when there is no date filter.
  def stats_preset_active?(preset_filter)
    current = @query.filters[@tab.preset_date_field]
    return current.nil? if preset_filter.nil?

    current.present? && current[:operator] == preset_filter[:operator] && current[:values] == preset_filter[:values]
  end

  def stats_active_filter_count
    @query.filters.size
  end

  # The four tiles of the Overview, as hashes for the view. A dash stands where there is nothing to show, and the backlog tile
  # carries an arrow and words, so colour is never the only signal.
  def stats_tile_cards
    return [] unless @tiles

    open, closed, median, backlog = @tiles.values_at("open", "closed_in_range", "median_days", "backlog_change")
    [
      { key: "open", value: open["tickets"], detail: l(:label_stats_tile_open_detail, count: open["of_tickets"]) },
      { key: "closed_in_range", value: closed["tickets"],
        detail: closed["percent_of_tickets"] ? l(:label_stats_tile_closed_in_range_detail, percent: closed["percent_of_tickets"]) : l(:label_stats_tile_closed_in_range_detail_empty) },
      { key: "median_days", value: median["days"] || STATS_DASH, unit: (l(:label_stats_tile_median_days_unit) if median["days"]),
        detail: l(:label_stats_tile_median_days_detail, count: median["closed_tickets"]) },
      stats_backlog_tile(backlog)
    ]
  end

  def stats_backlog_tile(backlog)
    direction = backlog["direction"]
    return { key: "backlog_change", value: STATS_DASH, detail: l(:label_stats_tile_backlog_empty), direction: "empty" } unless direction

    arrow = { "growing" => "▲", "shrinking" => "▼", "steady" => "▶" }.fetch(direction)
    value = backlog["difference"].zero? ? "0" : format("%+d", backlog["difference"])
    detail = l("label_stats_tile_backlog_#{direction}", difference: backlog["difference"].abs, periods: backlog["periods"],
               period_name: l("label_stats_period_unit_#{backlog["period"]}"))
    { key: "backlog_change", value: value, arrow: arrow, detail: detail, direction: direction }
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
