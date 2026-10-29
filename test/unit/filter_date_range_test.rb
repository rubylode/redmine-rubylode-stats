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

class FilterDateRangeTest < ActiveSupport::TestCase
  TODAY = Date.new(2026, 10, 29)

  def test_between_gives_both_ends
    filters = { "created_on" => { operator: "><", values: %w[2026-10-01 2026-10-31] } }

    assert_equal [Date.new(2026, 10, 1), Date.new(2026, 10, 31)], RubylodeStats::FilterDateRange.bounds(filters, TODAY)
  end

  def test_the_last_n_days_run_to_today
    filters = { "closed_on" => { operator: ">t-", values: ["30"] } }

    assert_equal [Date.new(2026, 9, 29), TODAY], RubylodeStats::FilterDateRange.bounds(filters, TODAY)
  end

  def test_the_widest_range_of_the_created_and_closed_filters_wins
    filters = {
      "created_on" => { operator: "><", values: %w[2026-10-05 2026-10-10] },
      "closed_on" => { operator: "><", values: %w[2026-10-01 2026-10-08] }
    }

    assert_equal [Date.new(2026, 10, 1), Date.new(2026, 10, 10)], RubylodeStats::FilterDateRange.bounds(filters, TODAY)
  end

  def test_no_date_filter_or_an_operator_it_does_not_know_gives_no_bounds
    assert_equal [nil, nil], RubylodeStats::FilterDateRange.bounds({ "status_id" => { operator: "o", values: [] } }, TODAY)
    assert_equal [nil, nil], RubylodeStats::FilterDateRange.bounds({ "created_on" => { operator: "!*", values: [] } }, TODAY)
  end

  def test_this_week_this_month_and_open_ended_operators
    assert_equal [Date.new(2026, 10, 26), Date.new(2026, 11, 1)], RubylodeStats::FilterDateRange.bounds({ "created_on" => { operator: "w", values: [] } }, TODAY)
    assert_equal [Date.new(2026, 10, 1), Date.new(2026, 10, 31)], RubylodeStats::FilterDateRange.bounds({ "created_on" => { operator: "m", values: [] } }, TODAY)
    assert_equal [Date.new(2026, 10, 5), nil], RubylodeStats::FilterDateRange.bounds({ "created_on" => { operator: ">=", values: ["2026-10-05"] } }, TODAY)
  end

  def test_a_huge_number_of_days_is_clamped_to_one_hundred_years
    filters = { "closed_on" => { operator: ">t-", values: ["999999999"] } }

    assert_equal [TODAY - 36_500, TODAY], RubylodeStats::FilterDateRange.bounds(filters, TODAY)
    assert_equal [nil, TODAY - 36_500], RubylodeStats::FilterDateRange.bounds({ "closed_on" => { operator: "<t-", values: ["999999999"] } }, TODAY)
    assert_equal [TODAY, TODAY + 36_500], RubylodeStats::FilterDateRange.bounds({ "closed_on" => { operator: "><t+", values: ["999999999"] } }, TODAY)
    assert_equal [TODAY + 36_500, nil], RubylodeStats::FilterDateRange.bounds({ "closed_on" => { operator: ">t+", values: ["999999999"] } }, TODAY)
  end

  def test_a_negative_or_unreadable_number_of_days_counts_as_zero
    assert_equal [TODAY, TODAY], RubylodeStats::FilterDateRange.bounds({ "closed_on" => { operator: ">t-", values: ["-5"] } }, TODAY)
    assert_equal [TODAY, TODAY], RubylodeStats::FilterDateRange.bounds({ "closed_on" => { operator: ">t-", values: ["abc"] } }, TODAY)
  end

  def test_an_unreadable_date_leaves_its_end_open
    filters = { "created_on" => { operator: "><", values: ["2026-10-01", "not a date"] } }

    assert_equal [Date.new(2026, 10, 1), nil], RubylodeStats::FilterDateRange.bounds(filters, TODAY)
    assert_equal [nil, nil], RubylodeStats::FilterDateRange.bounds({ "created_on" => { operator: ">=", values: ["2026-13-45"] } }, TODAY)
  end
end
