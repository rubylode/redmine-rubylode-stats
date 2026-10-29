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

# A Ruby-style "# " header is a comment only in Ruby files. In a view it prints on the page, in a script it is a syntax error
# that stops the charts from being drawn.
class AssetAndViewHeadersTest < ActiveSupport::TestCase
  PLUGIN_ROOT = File.expand_path("../..", __dir__)

  def test_no_view_starts_with_a_ruby_style_comment
    view_paths = Dir[File.join(PLUGIN_ROOT, "app/views/**/*.erb")]

    assert_not_empty view_paths
    view_paths.each do |path|
      assert_no_match(/\A# /, File.read(path), "#{path} would print its header on the page")
    end
  end

  def test_the_plugin_script_starts_with_a_script_comment
    script = File.read(File.join(PLUGIN_ROOT, "assets/javascripts/rubylode_stats.js"))

    assert_no_match(/^# /, script)
    assert_match(%r{\A/\*}, script)
  end
end
