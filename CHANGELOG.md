# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.1.1] - 2026-11-02

### Added

- The plugin shows its project address on Administration, Plugins, and its name, author and version are the ones to list on redmine.org, so "Check for updates" can recognise it. The text for the listing is in `docs/redmine-org-listing.md`.

## [1.1.0] - 2026-11-01

Interactive charts.

### Added

- A tooltip on every mark with the exact figures: the count, the share of the total, the total, and the change on the previous period where it makes sense. Numbers and month names follow the page's language.
- The mark under the pointer stays bright and the others dim. A click on a legend entry hides a series, as before.
- A click on a bar, a point or a slice opens the ticket list with the page's filters plus that mark's value, in the same tab or, with ctrl or cmd, in a new one. The median line links to the tickets closed in each period, and the opened and closed bars to the tickets created and closed in it.
- A "View data" table under every chart with the same figures and links, and a label on each chart for screen readers.
- The tooltip follows the theme through `--stats-tooltip-background`, `--stats-tooltip-color`, `--stats-tooltip-key-color` and `--stats-tooltip-border`.
- A browser check (`npm run check`) and a script that retakes the screenshots (`npm run screenshots`).

### Changed

- Ticket list addresses are built by one small class that keeps to Redmine's own query format and leaves out any filter or operator it does not know. A link shows only to people who may open the ticket list.
- Charts are drawn as SVG, so a mark that links is a real link.
- Motion is switched off for people whose system asks for less of it.

## [1.0.0] - 2026-10-30

First release. Redmine 7.0 and newer.

### Added

- A Stats page in each project, with tabs for Overview, People, Speed and Versions, under a filter bar, on a card grid.
- Overview: tiles for open tickets, tickets closed in the range, median days to close and backlog change; tickets by status, by category (or version, assignee, tracker, priority, author); a donut of open against closed that ignores the status filter; opened and closed per period with the backlog line.
- People: tickets closed per person per period.
- Speed: time to close as a histogram with its median, and the median per period.
- Versions: done against remaining per version, in order of due date.
- Redmine's own ticket filters and saved queries, presets for the dates (This quarter on a first visit, All time shows everything), and selects for the slice and the period.
- Bars and slices link to the ticket list with the same filters.
- A page across projects, limited to the projects where the user holds the permission and the module is on.
- A demo data script for the throwaway Redmine, and screenshots of each tab.

[Unreleased]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.1.0...main
[1.1.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rubylode/redmine-rubylode-stats/releases/tag/v1.0.0
