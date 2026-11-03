# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.3.1] - 2026-11-03

A thumbnail for the plugin.

### Added

- The plugin has a Rubylode thumbnail, shown at the top of the README. No change to the plugin itself.

## [1.3.0] - 2026-11-03

Calmer chart colours.

### Added

- An Editorial preset: ten muted hues with a grey for context, in a light and a dark set, each keeping 3:1 contrast against the page.

### Changed

- Editorial is the palette used when the preset is Follow the theme and the theme defines no chart colours. Material stays selectable.
- Tickets by status colours by meaning: closed statuses use the closed colour, open statuses take the palette in order without the closed colour, and a None bucket is grey.
- A None, Other or unnamed bucket in the category and closed per person charts is drawn in the neutral grey instead of a palette colour.

## [1.2.0] - 2026-11-02

Better chart colours, set in the plugin settings.

### Added

- A settings page (Administration, Plugins, Configure) with the presets Follow the theme, Material, Colour-blind safe, Data visualisation and Custom. Custom takes up to ten hex colours and optional colours for open, closed and neutral, and is checked on save.
- The charts use the theme's own colours when the page defines `--theme-chart-1` to `--theme-chart-10`, `--theme-chart-open`, `--theme-chart-closed` and `--theme-chart-neutral`. They are read again on every draw.
- The settings keys and their allowed values are in the README, for tools that write `Setting.plugin_redmine_rubylode_stats`.
- A test of the palette script (`npm test`).

### Changed

- Tickets by status and by category colour each bar from the palette in order. Charts with a single series are drawn in the first colour of the palette, not near-black. The default palette is a ten colour Material set with a light and a dark variant. Every preset keeps 3:1 contrast against the page.
- Open and closed use the same colours in every chart, and remaining tickets and the backlog line use the neutral colour.
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
- The tooltip colours come from `--stats-tooltip-background`, `--stats-tooltip-color`, `--stats-tooltip-key-color` and `--stats-tooltip-border`.
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

[Unreleased]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.3.0...main
[1.3.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.1.1...v1.2.0
[1.1.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rubylode/redmine-rubylode-stats/releases/tag/v1.0.0
