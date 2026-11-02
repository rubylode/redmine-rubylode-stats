# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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

[Unreleased]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.1.0...main
[1.1.0]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rubylode/redmine-rubylode-stats/releases/tag/v1.0.0
