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

  # The tracker for the whole page: the issues the project's own filters select. The first chart (tickets by status) is the
  # pattern to copy: the controller builds a Vega-Lite spec as a Hash, the view hands it to vega-embed as JSON.
  def index
    @chart_specifications = { by_status: tickets_by_status_specification }
  end

  private

  def tickets_by_status_specification
    rows = @project.issues.group(:status_id).count.map do |status_id, ticket_count|
      { "status" => IssueStatus.find(status_id).name, "tickets" => ticket_count }
    end
    {
      "$schema" => "https://vega.github.io/schema/vega-lite/v5.json",
      "title" => l(:label_stats_by_status),
      "data" => { "values" => rows },
      "mark" => "bar",
      "encoding" => {
        "x" => { "field" => "status", "type" => "nominal", "sort" => "-y" },
        "y" => { "field" => "tickets", "type" => "quantitative" }
      }
    }
  end
end
