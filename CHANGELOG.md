# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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

[Unreleased]: https://github.com/rubylode/redmine-rubylode-stats/compare/v1.0.0...main
[1.0.0]: https://github.com/rubylode/redmine-rubylode-stats/releases/tag/v1.0.0
