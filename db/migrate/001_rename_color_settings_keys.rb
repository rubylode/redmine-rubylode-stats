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

# 2.0.0 spells the settings keys and two preset values the US way (colour to color, visualisation to visualization).
# This moves the values saved under Administration, Plugins, Configure to the new names, and back on a rollback.
# It writes nothing when nothing was ever saved, so the defaults still apply.
class RenameColorSettingsKeys < ActiveRecord::Migration[5.2]
  SETTING_NAME = "plugin_redmine_rubylode_stats".freeze

  def up
    rewrite_saved_settings { |values| RubylodeStats::SettingsKeyRenames.forward(values) }
  end

  def down
    rewrite_saved_settings { |values| RubylodeStats::SettingsKeyRenames.reverse(values) }
  end

  private

  def rewrite_saved_settings
    return unless Setting.where(name: SETTING_NAME).exists?

    Setting.plugin_redmine_rubylode_stats = yield(Setting.plugin_redmine_rubylode_stats)
  end
end
