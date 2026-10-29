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

require File.expand_path("../test_helper", __dir__)

class PresetsTest < ActiveSupport::TestCase
  # Thursday 2026-10-29
  TODAY = Date.new(2026, 10, 29)

  def test_keys_in_display_order
    assert_equal %w[this_week this_month this_quarter last_30_days this_year all_time], RubylodeStats::Presets::KEYS
  end

  def test_this_week_runs_monday_to_sunday
    assert_equal({ operator: "><", values: %w[2026-10-26 2026-11-01] }, RubylodeStats::Presets.filter_for("this_week", TODAY))
  end

  def test_this_month
    assert_equal({ operator: "><", values: %w[2026-10-01 2026-10-31] }, RubylodeStats::Presets.filter_for("this_month", TODAY))
  end

  def test_this_quarter
    assert_equal({ operator: "><", values: %w[2026-10-01 2026-12-31] }, RubylodeStats::Presets.filter_for("this_quarter", TODAY))
  end

  def test_last_30_days_is_relative
    assert_equal({ operator: ">t-", values: ["30"] }, RubylodeStats::Presets.filter_for("last_30_days", TODAY))
  end

  def test_this_year
    assert_equal({ operator: "><", values: %w[2026-01-01 2026-12-31] }, RubylodeStats::Presets.filter_for("this_year", TODAY))
  end

  def test_all_time_has_no_date_filter
    assert_nil RubylodeStats::Presets.filter_for("all_time", TODAY)
  end
end
