---
title: Rubylode Stats
kind: spec
created: 2026-10-29
status: draft, awaiting confirmation of the test seams
ticket: 1657
brief: 2026-10-29-stats-brief.md
---

# Rubylode Stats

## Problem

The reporting plugin tried on the tracker is confusing and overwhelming. People want plain answers in a few seconds:
who closed tickets this week, which categories and versions are being worked on, how many tickets are open and closed,
how long closing takes, and whether the backlog is growing.

## Solution

A **Stats** page, per project and across projects, that draws a few clear charts over the same filters people already use
in the issue list. One row of presets (This week, This month, This quarter, Last 30 days, This year, All time) narrows the
dates; two selects choose how to slice the data and how long a period is. Saved issue queries work as reports. The page is
split into tabs (Overview, People, Speed, Versions) so each tab answers one family of questions. Every chart has a tooltip,
a legend that hides a series when clicked, and a bar or slice that links to the matching issue list.

## Acceptance behaviours

1. When a user without the stats permission, or in a project without the module, opens the page, then access is denied.
2. When the page is opened, then only tickets the user may see are counted, in a project or across the projects where the user
   holds the permission. An administrator sees all projects.
3. When a saved query or any filter is applied, then every chart counts exactly the tickets that the issue list shows for it.
4. When a preset is chosen, then the date range is set on the date that suits the chart: closed on for throughput, people and
   speed charts; created on for the intake series. The other filters stay as they were.
5. When tickets are grouped by a period, then weeks start on Monday and boundaries follow the viewing user's time zone.
6. When the question is "who closed", then the person is the author of the status change to a closed status; when no such
   change exists, then the assignee at the time of the query is used.
7. When a ticket was reopened and closed again, then it counts as closed once, at its latest closing.
8. When tickets are counted by category, version, assignee, tracker, priority or author, then tickets without a value are shown
   as "None", not dropped.
9. When opened and closed are charted per period, then the backlog line equals opened minus closed, cumulative, and starts from
   the tickets already open before the range begins.
10. When time to close is charted, then the value is the days from created to closed, shown as a histogram, with a median per
    period; open tickets are excluded.
11. When a bar or slice is clicked, then the matching issue list opens with the same filters plus that slice.
12. When the system setting for subprojects is on, then subproject tickets are included.
13. When the system follows a dark colour scheme, then the charts use the dark palette.
14. When open versus closed is drawn, then both halves are always counted: the status filter is ignored and every other filter
    applies; a note under the chart says so. The donut shows the percentage closed in its centre and the counts in its legend.
15. When the page is opened for the first time with no filter chosen by the user, then the date range is This quarter, with that
    preset marked active, on the date that suits the tab. A filter, a preset or a saved query overrides it; "All time" removes
    it, and then the "All time" preset is marked active.
16. When the Overview is opened, then four tiles show open tickets, tickets closed in the range with their share, the median
    days to close, and the backlog change over the last four periods with an arrow and words. Where there is nothing to
    divide the tile shows a dash. The time-to-close histogram lives on the Speed tab only.
17. When the Versions tab is opened, then progress per version is drawn as one horizontal stacked bar per version, done against
    remaining, with the share done and the counts at the bar end ("90% (18 of 20)"). The row label carries the due date and
    "(overdue)" when the date is past and the version is still open; rows run by due date, versions without a date next, and
    tickets without a version last as "No version". Like open versus closed, the status filter is ignored and every other
    filter applies; a bar opens the issue list of that version, and a legend click hides Done or Remaining.
18. When the Overview is opened, then the Open and Closed in range tiles, the "of N tickets" and the closed percentage count
    exactly the tickets of the Open versus closed donut: the filters and the date range apply, the status filter is ignored, so
    a ticket outside the date range is in neither. The median days to close is taken over the closed tickets of that same
    population; the backlog change keeps its own definition (opened minus closed per period over the last four periods).

## Decisions

- **Filters:** the page uses Redmine's own issue query, filters, options and saved queries; there is no second filter language.
  Reason: people already know it, and a saved query becomes a report for free.
- **One model per question:** a plain object that takes a query and returns rows as an array of hashes, with no drawing
  concerns. A chart specification is built from those rows. Reason: the numbers are testable with literal expected rows.
- **Closing events** come from the status-change history, because the closed-on date has no author. Imported tickets without
  history fall back to the assignee (see behaviour 6).
- **Visibility:** all counting goes through Redmine's own visibility rules; no raw queries across all projects.
- **Permission and module:** a permission `view_rubylode_stats` per role and a project module `rubylode_stats`. The
  cross-project page lists only projects where the user holds the permission.
- **Charts are drawn in the browser** by vendored Vega-Lite; the server only sends the specification. Colours come from the
  theme's CSS variables when present, with a light and a dark configuration.
- **Date filters and the opened-and-closed chart:** the created-on and closed-on filters set the range of the opened-and-closed
  chart instead of selecting tickets (a ticket created before the range and closed inside it still counts). This differs from
  behaviour 3 for date filters only; every other filter selects the same tickets as the issue list.
- **Export:** per-chart CSV later; images through the embed library's own menu. No server-side image rendering.

## Test seams

1. **The row models** (one per question): given a fixture project with known tickets, journals and users, the model returns
   exactly the expected literal rows. This is where behaviours 2 to 10 and 12 are tested.
2. **The page, through an integration request**: behaviours 1, 3, 4, 11 and 13 are checked by what the response and the chart
   specification carry (data values, links), never how it looks.

Nothing is tested against internals. Closest imitations: the existing integration tests in the repository, and the to-do
plugin's tests.

## Out of scope

- A second filter language, or custom report builders.
- Server-side image rendering and scheduled or emailed reports.
- Any client framework other than the vendored chart scripts and Redmine's own Stimulus.
- Live updates; the page is drawn on load.

## Later slices (not in the first six)

Work by version, status over time, calendar heatmap of closings, priority by category, cumulative flow, per-chart CSV export.
Each is its own ticket once the first six are done.

## Notes

- The charts, in the first six slices: tickets by status (exists), by category, open versus closed, opened and closed per period
  with a backlog line, closed per person per period, time to close.
- The cross-project page is in the first slices on purpose; the row models must accept a query that spans projects from the start.
