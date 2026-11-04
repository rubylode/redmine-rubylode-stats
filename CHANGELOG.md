# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - Unreleased

The plugin follows the Rubylode plugin standard: US spelling in the settings, one settings reader, one locale root.
The Stats page and its addresses do not change.

### Changed

- The settings keys are spelled the US way. Renamed keys:
  - `custom_colours` is now `custom_colors`
  - `custom_open_colour` is now `custom_open_color`
  - `custom_closed_colour` is now `custom_closed_color`
  - `custom_neutral_colour` is now `custom_neutral_color`
- Two values of `palette_preset` are renamed too: `colour_blind_safe` is now `color_blind_safe`, and `data_visualisation` is now
  `data_visualization`. The key `palette_preset` keeps its name.
- Labels and hints say color, color-blind safe and data visualization. The week range in a tooltip reads "Oct 5, 2026 to Oct 11, 2026",
  and a tile with nothing to show reads "n/a" instead of a dash. "vs previous" reads "versus previous".
- The word "Percentage" under Progress per version reads "Percent done", as on the chart. The median tile says "1 closed ticket" for one.
- `RubylodeStats::PluginSettings` is now `RubylodeStats::Settings`, the single settings reader.
- The locale has one root, `rubylode_stats`, with `settings.<key>.label` and `settings.<key>.hint`. The old flat `label_stats_*` and
  `rubylode_stats_*` keys are gone. Only `label_stats` (the menu caption), `permission_view_rubylode_stats` and
  `project_module_rubylode_stats` stay flat, because Redmine reads them. A translation file for 1.x must move its keys under the new root.
- Each custom role color (open, closed, neutral) has its own hint. The invalid color error uses the singular or plural.
- The README follows the standard headings (Install, Settings, Where it shows, Troubleshooting, Tests, License) and the four install steps.
- The docs describe the current plugin: the roadmap lists every release, the spec is marked built, and the first-session brief is removed.

### Added

- A migration, `001_rename_color_settings_keys`, that moves the saved settings to the new keys and preset values. Its rollback moves them back.
  It saves nothing when no settings were ever saved. Tests cover both directions.

### Upgrading from 1.x

1. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`, then restart Redmine. The migration renames the saved keys and values.
2. Without the migration the colors fall back to Follow the theme, because the old keys are no longer read.
3. If a deployment tool writes `Setting.plugin_redmine_rubylode_stats`, change it to the new key names and preset values above.
4. If you translated the plugin, move your keys under `rubylode_stats` in your locale file.

## [1.4.1] - 2026-11-04

### Changed

- Needs Redmine 5.1 or newer instead of 5.0. Redmine 5.0 cannot be tested in CI (the sqlite3 gem it pins does not build
  there), and this plugin only claims what CI verifies. No code changed.

## [1.4.0] - 2026-11-04

### Changed

- Runs on Redmine 5.0 and newer. The plugin's own tests pass unchanged on those versions; no code changed.

## [1.3.1] - 2026-11-03

### Added

- A Rubylode thumbnail at the top of the README. No change to the plugin.

## [1.3.0] - 2026-11-03

### Added

- An Editorial color preset, now the default fallback: ten muted hues with a gray for context, in a light and a dark set, each keeping 3:1 contrast against the page.

### Changed

- Editorial is the palette used when the preset is Follow the theme and the theme defines no chart colors. Material stays selectable.
- Tickets by status colors by meaning: closed statuses use the closed color, open statuses take the palette in order without the closed color, and a None bucket is gray.
- A None, Other or unnamed bucket in the category and closed per person charts is drawn in the neutral gray instead of a palette color.

## [1.2.0] - 2026-11-02

Chart colors are now set in the plugin settings.

### Added

- A settings page (Administration, Plugins, Configure) with the presets Follow the theme, Material, Color-blind safe, Data visualization and Custom. Custom takes up to ten hex colors and optional colors for open, closed and neutral, and is checked on save.
- The charts use the theme's own colors when the page defines `--theme-chart-1` to `--theme-chart-10`, `--theme-chart-open`, `--theme-chart-closed` and `--theme-chart-neutral`. They are read again on every draw.
- The settings keys and their allowed values are in the README, for tools that write `Setting.plugin_redmine_rubylode_stats`.
- A test of the palette script (`npm test`).

### Changed

- Tickets by status and by category color each bar from the palette in order. Charts with a single series are drawn in the first color of the palette, not near-black. The default palette is a ten-color Material set with a light and a dark variant. Every preset keeps 3:1 contrast against the page.
- Open and closed use the same colors in every chart, and remaining tickets and the backlog line use the neutral color.

## [1.1.1] - 2026-11-02

### Added

- The plugins page in Administration shows the project address.
- The plugin's name, author and version match the redmine.org listing, so "Check for updates" can find it. The listing text is in `docs/redmine-org-listing.md`.

## [1.1.0] - 2026-11-01

Interactive charts.

### Added

- A tooltip on every mark with the count, the share of the total, the total and, where it applies, the change on the previous period. Numbers and month names follow the page's language.
- The mark under the pointer stays bright and the others dim. A click on a legend entry still hides a series.
- A click on a bar, a point or a slice opens the ticket list with the page's filters plus that mark's value, in the same tab or, with ctrl or cmd, in a new one.
- The median line links to the tickets closed in each period. The opened and closed bars link to the tickets created and closed in it.
- A "View data" table under every chart with the same figures and links, and a label on each chart for screen readers.
- The tooltip colors come from `--stats-tooltip-background`, `--stats-tooltip-color`, `--stats-tooltip-key-color` and `--stats-tooltip-border`.
- A browser check (`npm run check`) and a script that retakes the screenshots (`npm run screenshots`).

### Changed

- One small class builds the ticket list addresses. It follows Redmine's query format and drops any filter or operator it does not know.
- A link shows only to people who may open the ticket list.
- Charts are drawn as SVG, so a mark that links is a real link.
- Motion is switched off for people whose system asks for less of it.

## [1.0.0] - 2026-10-30

First release. Needs Redmine 7.0 or newer.

### Added

- A Stats page in each project, with the tabs Overview, People, Speed and Versions, a filter bar and a card grid.
- Overview: tiles for open tickets, tickets closed in the range, median days to close and backlog change. Tickets by status and by category (or version, assignee, tracker, priority, author). A donut of open against closed that ignores the status filter. Opened and closed per period, with the backlog line.
- People: tickets closed per person per period.
- Speed: time to close as a histogram with its median, and the median per period.
- Versions: done against remaining per version, in order of due date.
- Redmine's ticket filters and saved queries, date presets (This quarter on a first visit, All time for everything) and selects for the slice and the period.
- Bars and slices link to the ticket list with the same filters.
- A page across projects, limited to the projects where the user holds the permission and the module is on.
- A demo data script for the throwaway Redmine, and a screenshot of each tab.

[Unreleased]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.4.1...main
[1.3.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.1.1...v1.2.0
[1.1.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rubylode/redmine-rubylode-stats/releases/tag/v1.0.0
