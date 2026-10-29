---
title: Brief for the stats plugin session
kind: brief
created: 2026-10-29
status: skeleton built (0.1.0); charts not built
---

# Brief: Rubylode Stats

Start the session in this folder. The skeleton loads in Redmine, adds a **Stats** tab to the project menu and draws one chart
(tickets by status). Everything else is to build.

## The point

The existing reporting plugin tried on the tracker is confusing and overwhelming. This one is for answering plain questions in
a few seconds, in the manner of the best project dashboards: simple to read, a few presets, and Redmine's own filters
and options to narrow them.

## Questions the page must answer

- Who closed tickets this week, this month, this quarter?
- Which categories are being worked on? Which versions (roadmaps) are being worked on?
- How many tickets are open and closed, and how is that changing?
- Speed: how long does it take to close a ticket (created to closed), how long do tickets sit in each status, and what is the trend?
- Throughput: tickets opened versus closed per week; what is the backlog doing?

## Charts (Vega-Lite)

| Chart | Kind | Answers |
|---|---|---|
| Tickets by category | bar, pie as an option | where the work is |
| Open versus closed | stacked bar and donut | how much is done |
| Opened and closed per period | line, two series, with a cumulative backlog line | is the backlog growing |
| Closed per person per period | grouped or stacked bar | who closed what this week or month |
| Time to close | histogram plus a median line per period | how long it takes, and the trend |
| Work by version | horizontal stacked bar, done against remaining | progress of each roadmap item |
| Status over time | stacked area | flow through the statuses |
| Calendar heatmap of closings | heatmap (week by weekday) | rhythm of the work |
| Priority by category | heatmap | where the urgent work sits |
| Cumulative flow | stacked area of open statuses | bottlenecks |

Start with the first five; the rest are slices of their own. Every chart: tooltip, a legend that can be clicked to hide a series,
and a link from a bar or slice to the matching Redmine issue list.

## How it is controlled

- **Redmine's own filters and options.** The page uses `IssueQuery`: the same Filters and Options blocks as the issue list, saved
  queries included, so any saved query becomes a report. No second filter language.
- **Presets** as one row of buttons above the charts: This week, This month, This quarter, Last 30 days, This year, All time.
  A preset only sets the date range (closed on, or created on) of the query; the filters stay editable.
- **Slice by** (one select): category, version, assignee, tracker, priority, author. **Period** (one select): day, week, month.
- Permission `view_rubylode_stats` per role, module `rubylode_stats` per project; a subproject toggle follows Redmine's setting.

## How it is built

- Server side: a model per question (a plain Ruby object that takes an `IssueQuery` and returns rows as an array of Hashes),
  tested first with literal expected rows. A chart specification is a Hash built from those rows. Closing events and who closed
  them come from `journals` and `journal_details` (status changes), because `issues.closed_on` has no author.
- Browser side: `vega`, `vega-lite` and `vega-embed` are vendored in `assets/javascripts/` (5.30.0, 5.21.0, 6.26.0, from jsdelivr,
  2026-10-29). One Stimulus controller can wrap `vegaEmbed` later if the page needs behaviour; Redmine 7 has Stimulus on an
  importmap and no Turbo.
- The `vega` gem (renders specs to PNG/SVG in Ruby) is not needed for the page; it fits an export button (chart as an image)
  later. Decide in the interview.
- Respect Redmine visibility: use `Issue.visible` through the query, never raw SQL over all projects.
- Dark mode: the Rubylode themes follow the system setting, so the charts need a light and a dark Vega-Lite config, chosen from
  `prefers-color-scheme`, with the colours read from the theme's CSS variables when they exist.

## Open questions for the interview

1. Closing person: status-change journals (exact, but misses tickets closed by import) or assignee at close (simple)? Fall back to
   the assignee when there is no journal?
2. Period boundaries: ISO weeks starting Monday, in the user's time zone?
3. Which date does a preset filter: closed on (best for "who closed this week") or created on? Probably closed on for
   throughput charts, created on for the intake chart.
4. One page with all charts, or tabs (Overview, People, Speed, Versions)?
5. Single project only, or also a cross-project page (administration level) for the whole tracker?
6. Image export per chart, and a CSV of the rows behind each chart?

## Slices (suggested order)

1. The page frame: query form (Filters, Options, presets), period and slice-by selects, the one existing chart driven by the query.
2. Tickets by category and open versus closed.
3. Opened and closed per period, with the backlog line.
4. Closed per person per period (journal-based).
5. Time to close: histogram and median trend.
6. Work by version.
7. The rest of the table; export; the cross-project page.

## Try it and deploy it

`docker compose up -d` then http://localhost:3008; `bin/test` for the tests. The deploy to the home tracker follows the to-do
plugin's (a folder on Moneta, a bind mount in the tracker's compose file, a restart).
