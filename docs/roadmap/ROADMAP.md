# Roadmap

## Done

- 1.0.0: the Overview, People, Speed and Versions tabs, Redmine's own filters, presets, bars and slices that link to the ticket list, a page across projects.
- 1.1.0: interactive charts.
  - A tooltip on every mark with the exact figures: count, share of the total, change on the previous period, the total.
  - The mark under the pointer emphasized and the rest dimmed.
  - A click on a bar, point or slice opens the ticket list filtered to it, in a new tab with ctrl or cmd.
  - A "View data" table under every chart, labels for screen readers, and a tooltip that follows the theme.
- 1.2.0: a settings page with color presets and custom colors; the charts use the theme's own colors when it defines them.
- 1.3.0: the Editorial preset, and colors by meaning in tickets by status.
- 1.4.0 and 1.4.1: tested on Redmine 5.1, 6.0, 6.1 and 7.0.
- 2.0.0: US spelling in the settings keys, one settings reader (`RubylodeStats::Settings`), one locale root, and a migration for the saved settings.

## Open

- Status over time (stacked area), a calendar heatmap of closings, priority by category and cumulative flow.
- CSV export per chart, and the chart as an image.
- A link from the time to close histogram and from the backlog line: the ticket list has no filter for how long a ticket took or for the backlog as it stood in a past week, so they need a filter of their own.
- Translations (English only so far).
- A tooltip for touch screens: a tap shows the tooltip and a second tap follows the link.
