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

require File.expand_path("../test_helper", __dir__)

class StatsAcrossProjectsTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :issue_categories, :versions, :workflows, :queries,
           :custom_fields, :custom_values, :custom_fields_trackers, :custom_fields_projects, :journals, :journal_details,
           :watchers, :time_entries, :attachments, :repositories, :changesets

  ALL_STATUSES = "set_filter=1&f[]=status_id&op[status_id]=*".freeze

  def setup
    Setting.display_subprojects_issues = "0"
    # Project 1 is the one with the module; project 5 is visible to the same user, but has no module.
    Project.find(1).enable_module!(:rubylode_stats)
    Role.find(1).add_permission!(:view_rubylode_stats)
  end

  def test_a_user_sees_only_the_tickets_of_projects_where_the_permission_and_module_are_held
    log_user("jsmith", "jsmith")

    get "/stats?#{ALL_STATUSES}"

    assert_response :success
    assert_operator Issue.visible(User.find(2)).where(project_id: 5).count, :>, 0
    assert_equal 7, status_rows.sum { |row| row["tickets"] }
  end

  def test_access_is_denied_when_no_project_has_both_the_permission_and_the_module
    log_user("jsmith", "jsmith")
    Role.find(1).remove_permission!(:view_rubylode_stats)

    get "/stats"

    assert_response :forbidden
  end

  def test_access_is_denied_when_the_permission_is_held_but_no_project_has_the_module
    log_user("jsmith", "jsmith")
    Project.find(1).disable_module!(:rubylode_stats)

    get "/stats"

    assert_response :forbidden
  end

  def test_an_anonymous_visitor_is_sent_to_the_login_page
    get "/stats"

    assert_response :redirect
    assert_match %r{/login}, response.location
  end

  def test_an_administrator_sees_the_tickets_of_every_project_with_the_module
    Project.find(5).enable_module!(:rubylode_stats)
    log_user("admin", "admin")

    get "/stats?#{ALL_STATUSES}"

    assert_response :success
    assert_equal Issue.where(project_id: [1, 5]).count, status_rows.sum { |row| row["tickets"] }
  end

  def test_the_cross_project_page_has_the_same_tabs_presets_and_selects
    log_user("jsmith", "jsmith")

    get "/stats"

    assert_equal %w[overview people speed versions], css_select("a.stats-tab").map { |link| link["data-tab"] }
    assert_equal 6, css_select("a.stats-preset").size
    assert_select "select#period"
    assert_select "select#slice_by"
    assert_select "form#query_form fieldset#filters"
    assert css_select("a.stats-preset").all? { |link| link["href"].start_with?("/stats?") }
  end

  def test_the_top_menu_offers_the_page_to_a_user_who_can_see_a_project_with_stats
    log_user("jsmith", "jsmith")

    get "/my/page"

    assert_select "#top-menu a.rubylode-stats[href='/stats']"
  end

  def test_the_top_menu_hides_the_page_from_a_user_without_such_a_project
    log_user("dlopper", "foo")

    get "/my/page"

    assert_select "#top-menu a.rubylode-stats", false
  end

def test_the_opened_and_closed_chart_also_keeps_to_the_permitted_projects
  log_user("jsmith", "jsmith")

  get "/stats?#{ALL_STATUSES}"

  rows = JSON.parse(css_select("#stats-chart-opened_and_closed").first["data-specification"]).dig("data", "values")
  assert_equal 7, rows.sum { |row| row["opened"] }
end

  def test_bar_links_carry_a_project_filter_limited_to_the_permitted_projects
    log_user("jsmith", "jsmith")

    get "/stats?#{ALL_STATUSES}"

    specification = css_select("#stats-chart-tickets_by_status").first["data-specification"]
    urls = JSON.parse(specification).dig("data", "values").map { |row| row["url"] }
    assert urls.all? { |url| url.include?("v%5Bproject_id%5D%5B%5D=1") }
    assert urls.none? { |url| url.include?("v%5Bproject_id%5D%5B%5D=5") }
  end

  private

  def status_rows
    specification = JSON.parse(css_select("#stats-chart-tickets_by_status").first["data-specification"])
    specification.dig("data", "values")
  end
end
