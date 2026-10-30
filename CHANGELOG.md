# Changelog

## 0.2.0

- A card grid layout under a filter bar, with summary tiles on the Overview (open, closed in the range, median days to
  close, backlog change) and a donut of open against closed that ignores the status filter.
- The Versions tab: progress per version, done against remaining, in order of due date.
- A first visit shows this quarter by default; All time shows everything.
- The charts: tickets by status, by category (or version, assignee, tracker, priority, author), open against closed,
  opened and closed per period with the backlog line, closed per person, and time to close with its median.
- Tabs (Overview, People, Speed, Versions), presets for the dates, and selects for the slice and the period.
- A page across projects, limited to the projects where the user holds the permission and the module is on.
- Bars and slices link to the ticket list with the same filters; on the page across projects the link keeps to the
  permitted projects.
- A demo data script for the throwaway Redmine, with screenshots of each tab.

## 0.1.0

- The skeleton: a Stats tab in the project menu and one chart, tickets by status.
