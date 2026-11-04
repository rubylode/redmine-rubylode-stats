# Rubylode Stats for Redmine

<p><img src="docs/thumbnail.png" alt="Rubylode Stats plugin" width="160"></p>

[![tests](https://img.shields.io/github/actions/workflow/status/rubylode/redmine-rubylode-stats/tests.yml?branch=main&label=tests)](https://github.com/rubylode/redmine-rubylode-stats/actions/workflows/tests.yml)
[![security](https://img.shields.io/github/actions/workflow/status/rubylode/redmine-rubylode-stats/security.yml?branch=main&label=security)](https://github.com/rubylode/redmine-rubylode-stats/actions/workflows/security.yml)
[![version](https://img.shields.io/github/v/tag/rubylode/redmine-rubylode-stats?sort=semver&label=version)](https://github.com/rubylode/redmine-rubylode-stats/tags)
[![license](https://img.shields.io/github/license/rubylode/redmine-rubylode-stats)](https://github.com/rubylode/redmine-rubylode-stats/blob/main/LICENSE)
![Redmine](https://img.shields.io/badge/Redmine-5.1%20%7C%206.0%20%7C%206.1%20%7C%207.0-b22222)
![Ruby](https://img.shields.io/badge/Ruby-3.2%20%7C%203.3%20%7C%203.4%20%7C%204.0-cc342d)

A Stats page for every [Redmine](https://www.redmine.org) project, and one across projects, with charts over the tickets.

Contents:

- [What it does](#what-it-does)
- [Install](#install)
- [Settings](#settings)
- [Where it shows](#where-it-shows)
- [Troubleshooting](#troubleshooting)
- [Limits](#limits)
- [Tests](#tests)
- [Releasing](#releasing)
- [License](#license)

I wanted a page that answers "what is getting done" in a few seconds: who closed tickets this week, which categories and
versions are being worked on, how many tickets are open and closed, how long closing takes. Redmine has the tickets but
no quick way to see that. So each project now gets a Stats page, with charts over the same filters the ticket list
already has. Point at a bar for the exact figures, click it for the matching tickets.

![The Overview tab: summary tiles, then cards for status, category, open against closed and the backlog](docs/screenshots/stats-overview.png)

![A tooltip: the pointer on one week, with the figures of the week and the change on the week before, the other weeks dimmed](docs/screenshots/stats-tooltip.png)

![The People tab: tickets closed per person per week](docs/screenshots/stats-people.png)

![The Speed tab: how long tickets take to close, and the median per week](docs/screenshots/stats-speed.png)

![The Versions tab: done against remaining per version, by due date](docs/screenshots/stats-versions.png)

![The page across projects](docs/screenshots/stats-all-projects.png)

## What it does

- Four tabs: Overview, People, Speed and Versions. The charts sit in cards on a grid, under a filter bar.
- Charts: tickets by status, by category (or version, assignee, tracker, priority, author), open against closed, opened
  and closed per period with the backlog line, closed per person, time to close with its median, and progress per version.
- Redmine's own ticket filters narrow every chart, and a saved query works as a report. Every chart counts what the
  ticket list shows for the same filters.
- One row of presets (This week, This month, This quarter, Last 30 days, This year, All time) sets the dates.
- Two selects choose how to slice the data (category, version, assignee, tracker, priority, author) and how long a
  period is (day, week, month).
- Point at a mark and a tooltip gives its exact figures: the count, the share of the total, the change on the previous
  period. The other marks dim a little. A click on a legend entry hides a series.
- Click a bar, a point or a slice and the ticket list opens with the same filters plus that mark's value, in the same tab,
  or in a new one with ctrl or cmd. See [Using the charts](#using-the-charts).
- Every chart has a "View data" table with the same figures, so the page works without a mouse.
- Tickets without a value (no category, no assignee) show as "None" and are not dropped.
- Only tickets the user may see are counted.
- The charts are drawn in the browser by [Vega-Lite](https://vega.github.io/vega-lite/), which ships inside the plugin.
  It needs no extra gem. One settings page sets the chart colors.

## Install

Redmine 5.1 or newer, on any database Redmine supports. The plugin adds no table; its one migration moves saved settings
when you upgrade from 1.x.

1. Put the plugin folder in Redmine's `plugins/` directory, named `redmine_rubylode_stats`:

       cd /path/to/redmine/plugins
       git clone https://github.com/rubylode/redmine-rubylode-stats.git redmine_rubylode_stats

   Or unpack a [release archive](https://github.com/rubylode/redmine-rubylode-stats/releases) there, as `redmine_rubylode_stats`.
2. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`.
3. If the plugin reads an environment variable, set it where Redmine runs, then restart Redmine. This plugin reads none, so
   only restart Redmine.
4. In Administration, Plugins, open the plugin and choose Configure.

Then allow it, as an administrator:

1. Administration, Roles and permissions: check View stats for the roles that should see the page.
2. Each project needs the module once (Settings, Modules, Stats). To do all of them at once:

       bundle exec rails runner -e production 'Project.find_each { |project| project.enable_module!(:rubylode_stats) }'

With [Docker](https://www.docker.com), mount or copy the plugin to `/usr/src/redmine/plugins/redmine_rubylode_stats`, run the
migration inside the container and restart it:

    docker compose exec redmine bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    docker compose restart redmine

To upgrade, `git pull`, run the migration again and restart. To remove it, delete the folder and restart. Tickets are not touched.

### Upgrading from 1.x

2.0.0 spells the settings keys the US way, and a migration moves what you saved. Run step 2 above. Details are in the
[changelog](CHANGELOG.md).

## Settings

Administration, Plugins, Rubylode Stats, Configure.

| Setting | Key | Hint |
|---|---|---|
| Chart colors | `palette_preset` | Follow the theme uses the theme's chart colors, and Editorial when the theme defines none. The other choices ignore the theme. |
| Custom colors | `custom_colors` | Used with Custom. Enter 1 to 10 hex colors separated by commas. The first draws single-series charts. |
| Custom color for open | `custom_open_color` | Optional hex color. If empty, open takes the first custom color. |
| Custom color for closed | `custom_closed_color` | Optional hex color. If empty, closed takes the second custom color, or the first when there is only one. |
| Custom color for neutral | `custom_neutral_color` | Optional hex color. If empty, neutral is a gray. |

The form checks the values before it saves them and names every color it does not accept.

### Chart colors

The charts take their colors from the theme when it provides them, and from a preset of the plugin otherwise.

| Preset | What it is |
|---|---|
| Follow the theme (default) | The theme's own chart colors when the page defines `--theme-chart-1`, Editorial when it does not |
| Editorial | Ten muted hues in the manner of newsroom graphics, with a gray for context: steel blue, burnt orange, muted green, brick red and so on. A darker set for a light page and a lighter set for a dark page |
| Material | Ten saturated Material Design hues, a darker set for a light page and a lighter set for a dark page |
| Color-blind safe | The Okabe-Ito set, with gray in place of black and darker tones on a light page |
| Data visualization | Ten saturated categorical colors in the style of the wpdatatables palettes |
| Custom | Up to ten hex colors of your own, and optional colors for open, closed and neutral |

How the colors are assigned:

- Tickets by status colors by meaning: a closed status uses the closed color, and an open status takes the palette in
  order, skipping the color the closed role uses.
- A None bucket is gray. In the category charts (tickets by category, closed per person) a bucket named None or Other, or
  with an empty name, is gray too, so it reads as context and uses no hue.
- Other category buckets take the colors in order and start again after the last one. The bars of tickets by status and
  by category need no legend, as the axis names them.
- Charts with a single series (time to close, the median line) are drawn in the first color.
- Open and closed use the same two colors in every chart: the open and closed donut, opened and closed per period, and
  done against remaining per version. The neutral color draws remaining tickets and the backlog line.
- Every color of the presets keeps a contrast of at least 3:1 against a white page in the light set and against a
  #1E1E1E page in the dark set. The test suite checks it.
- The light or dark set follows the system color scheme, and the charts are drawn again when it changes.

#### The theme contract

A theme gives the charts its colors by defining these CSS custom properties on the page (on `:root`, or on `html`):

| Property | Meaning |
|---|---|
| `--theme-chart-1` to `--theme-chart-10` | Categorical colors, in order. Define as many as you have. The first one also draws single-series charts |
| `--theme-chart-open` | Open tickets. Without it, categorical color 1 |
| `--theme-chart-closed` | Closed tickets and the done part of a version. Without it, categorical color 2 |
| `--theme-chart-neutral` | Remaining tickets, the backlog line and gray fills. Without it, a neutral gray of the plugin |

The script reads the properties each time it draws, so a theme that changes them for light and dark gets the right ones.
It uses them only when the preset is Follow the theme and `--theme-chart-1` is defined. Example:

    :root {
      --theme-chart-1: #1e88e5;
      --theme-chart-2: #ea6a00;
      --theme-chart-3: #00897b;
      --theme-chart-open: #1e88e5;
      --theme-chart-closed: #43a047;
      --theme-chart-neutral: #78909c;
    }

    @media (prefers-color-scheme: dark) {
      :root {
        --theme-chart-1: #64b5f6;
        --theme-chart-2: #ffa726;
        --theme-chart-3: #4db6ac;
        --theme-chart-open: #64b5f6;
        --theme-chart-closed: #81c784;
        --theme-chart-neutral: #90a4ae;
      }
    }

Pick colors that keep 3:1 against the page background, or the bars will be hard to see.

The tooltip takes its colors from the theme's variables too. A theme can set `--stats-tooltip-background`,
`--stats-tooltip-color`, `--stats-tooltip-key-color` and `--stats-tooltip-border`.

#### Palette values

The roles are open, closed and neutral. Editorial uses `#2F6C9F`, `#3F8F6B` and `#8E959B` in the light set and `#6FA3D0`, `#7CC09E` and `#8A9199` in the dark set. Editorial was made for this plugin.

| Preset | Light set | Dark set |
|---|---|---|
| Editorial | `#2F6C9F` `#D4662A` `#3F8F6B` `#B5493F` `#7A5C9A` `#B88C27` `#4F9AA0` `#8C6D5A` `#6B7F94` `#8E959B` | `#6FA3D0` `#EE9A63` `#7CC09E` `#E08A82` `#A98CC9` `#E3BE63` `#86C4C9` `#BBA08F` `#9FB0C2` `#B4BAC0` |
| Material | `#1E88E5` `#EA6A00` `#00897B` `#D81B60` `#689F38` `#8E24AA` `#0097A7` `#3949AB` `#6D4C41` `#546E7A` | `#64B5F6` `#FFA726` `#4DB6AC` `#F06292` `#9CCC65` `#BA68C8` `#4DD0E1` `#7986CB` `#A1887F` `#90A4AE` |
| Color-blind safe | `#0072B2` `#D55E00` `#009E73` `#CB75A5` `#C28600` `#1D99E0` `#9C920C` `#919191` | `#0072B2` `#D55E00` `#009E73` `#CC79A7` `#E69F00` `#56B4E9` `#F0E442` `#999999` |
| Data visualization | `#1A53FF` `#CC8200` `#00A58B` `#E60049` `#9B19F5` `#0098DC` `#899623` `#DC0AB4` `#7C1158` `#729F39` | `#245BFF` `#FFA300` `#00BFA0` `#E60049` `#9D1EF5` `#0BB4FF` `#BDCF32` `#DC0AB4` `#C81B8E` `#87BC45` |

#### Writing the settings from a deployment tool

Redmine keeps the settings as one hash in `Setting.plugin_redmine_rubylode_stats`. Missing keys read as the default, so a
tool can write only the keys it wants to change, and an upgrade with no stored keys follows the theme. All values are strings.

| Key | Allowed values | Default |
|---|---|---|
| `palette_preset` | `"follow_theme"`, `"editorial"`, `"material"`, `"color_blind_safe"`, `"data_visualization"`, `"custom"` | `"follow_theme"` |
| `custom_colors` | 1 to 10 hex colors (`#rgb` or `#rrggbb`) separated by commas; used only with `"custom"` | `""` |
| `custom_open_color` | one hex color, or `""` for the first custom color | `""` |
| `custom_closed_color` | one hex color, or `""` for the second custom color (the first when there is only one) | `""` |
| `custom_neutral_color` | one hex color, or `""` for a gray | `""` |

For example, from `rails runner`:

    Setting.plugin_redmine_rubylode_stats = { "palette_preset" => "custom", "custom_colors" => "#1e88e5, #ea6a00, #00897b" }

Writing the hash directly skips the form's check: an unusable value reads as the default, and unusable custom colors leave
the Editorial palette.

## Where it shows

- **In a project:** a Stats tab after Issues, once the module is on for the project and the role holds View stats.
- **Across projects:** a Stats link in the top menu opens the same tabs over every project where the user holds the permission
  and the module is on. Its links to the ticket list keep to those projects. The link shows only to people who have at least one.

### Using the charts

- Tooltip: the period or the name of the bar, each series, the total, the share of the total (status, category and
  the other slices, and open against closed), and the change on the previous day, week or month (opened and closed,
  closed per person, median days to close). Numbers and month names follow the language of the page, dates follow the
  user's date format.
- Highlight: the mark under the pointer stays bright, the others dim. On opened and closed, all the bars of the week
  stay bright together. Click a name in the legend to hide a series, click again to bring it back.
- Click-through: a bar, a point or a slice opens the ticket list with the page's own filters and the one the mark
  stands for (status, category, version, the week or month as a created or closed date range). Ctrl or cmd click
  opens it in a new tab. The address holds only filter ids and dates, and only shows for people who may open the
  ticket list. Two charts have no link, because the ticket list cannot show what they count: the time to close
  histogram, and the backlog line of opened and closed.
- Without a pointer: under each chart, "View data" opens a table with the same figures and the same links. It is a
  real table, headed and labeled, so keyboard and screen reader users reach everything. The chart carries a label
  that says what it shows. Tooltips need a pointer; on a touch screen the table is the way to the figures.
- Motion is switched off for people whose system asks for less of it.

### What the tabs answer

- Overview: how many tickets are open, how many were closed in the range, how long closing takes, and whether the
  backlog is growing. Four tiles come first (open tickets, closed in the range, median days to close, backlog change).
  Then tickets by status, tickets by category (or version, assignee, tracker, priority, author), a donut of open
  against closed, and opened and closed per period with the backlog line. The tiles and the donut count the same
  tickets. They ignore the status filter on purpose, so open and closed always show together. Where there is nothing to
  divide, a tile shows n/a.
- People: who closes tickets. It shows tickets closed per person per period. The person is the author of the change to a
  closed status. For tickets closed without such a change (an import, say) it is the assignee.
- Speed: how long closing takes. A histogram of the days from created to closed with the median marked, and the median
  per period as a line. Open tickets are left out.
- Versions: how far each version is. Done against remaining, one bar per version, in order of due date, with the percent
  done and the counts at the end of the bar. Versions without a date come last, and tickets without a version show as
  "No version". Like the donut, it ignores the status filter.

A ticket that was reopened and closed again counts once, at its latest closing.

### Presets and filters

- The first time you open a tab it shows This quarter. Choose All time to see everything, which the Versions tab needs
  to show every version.
- A preset sets the date that suits the chart: closed on for finished work, created on for intake. The other filters
  stay as they were.
- Filters and options opens Redmine's usual filter form above the charts. Save a query in the ticket list and pick it
  here to use it as a report.
- The created and closed date filters set the range of the opened and closed chart. A ticket created before the range
  and closed inside it still counts.
- Weeks start on Monday, in your time zone. Subproject tickets are included when Redmine's setting for that is on.

## Troubleshooting

- **No Stats tab in a project.** The module is off for that project (Settings, Modules, Stats), or the role does not hold
  View stats. The command under [Install](#install) turns the module on everywhere.
- **The Stats link is missing from the top menu.** It shows only to people who hold View stats in at least one project that has
  the module on.
- **The Versions tab shows only some versions.** The first visit shows This quarter. Choose All time.
- **The colors went back to the default after an upgrade.** The migration of 2.0.0 did not run, so the saved settings still
  use the 1.x key names, which are ignored. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`.
- **The theme's colors are not used.** The preset must be Follow the theme, and the page must define `--theme-chart-1`.
- **Saving the settings shows a red message.** A color is not hex (`#abc` or `#aabbcc`), or Custom has no colors. Nothing is
  saved.

## Limits

- English only. The strings live in `config/locales/en.yml`; translations are welcome.
- It is built for a desktop browser.
- A chart is tested by the data its specification carries, and the numbers behind it are tested with literal expected
  rows. The browser check (see Tests) covers the tooltip, the highlight, the click-through and the legend.
- "Closed by" is read from the status change history, with the assignee as the fallback. A ticket that an import
  reopened and closed again, with no history, is credited to its earlier closer.
- Not built: status over time, a calendar heatmap of closings, priority by category, cumulative flow and CSV export. See the
  [roadmap](docs/roadmap/ROADMAP.md).

## Tests

    bin/test                                       all tests
    bin/test test/unit/issue_list_link_test.rb     one file

They run in a Redmine 7 image with its test gems. The numbers behind the charts are tested first, and a chart is checked
by the data it carries, not by how it looks. The browser parts are checked with [Playwright](https://playwright.dev) against the throwaway Redmine below, filled with
its demo data. It needs [Node](https://nodejs.org) and a Chrome or Chromium (set `CHROME_PATH` if it is not found):

    npm install
    npm test               the palette script, with Node's own test runner
    npm run check          hover, tooltip, dimming, click-through, new tab, legend, data table, dark scheme
    npm run screenshots    retake the screenshots in docs/screenshots

By hand, in the throwaway Redmine, also open the page across projects as a user who holds the permission in one
project only.

### Try it

A throwaway Redmine 7 runs from this folder, with the repository mounted as the plugin. It needs [Docker](https://www.docker.com).

    docker compose up -d
    open http://localhost:3008

Give it a minute to start. Then fill it with two demo projects (Demo Garden and Demo Workshop), four people and about 150
tickets over the last 12 weeks, some of them reopened, some without a category or an assignee:

    docker exec redmine-stats-dev bundle exec rails runner plugins/redmine_rubylode_stats/script/seed_demo.rb

Sign in as one of the demo people, with the password `demo-password-1`: `alan.turing`, `ada.lovelace`, `grace.hopper`
or `edsger.dijkstra`. The administrator is `admin` with the password `admin` (the script sets it, for this preview only).
Open Demo Garden and click Stats. The script is safe to run twice. Wipe the preview with `docker compose down -v`.

Pull Requests are welcome!

## Releasing

Push a `vX.Y.Z` tag whose version matches `version` in `init.rb` and has an entry in `CHANGELOG.md`. CI runs the tests, builds `redmine_rubylode_stats-X.Y.Z.zip` and publishes the GitHub release with the changelog entry as its notes. To build a release for a tag that already exists, use Actions, release, Run workflow.

The text to paste when listing the plugin on www.redmine.org, and how to read the result of Check for updates, is in [docs/redmine-org-listing.md](docs/redmine-org-listing.md).

## License

GPL v2 or later, the same as Redmine. See `LICENSE`.

Copyright (C) 2026  Nick Gorbikoff. Each Ruby file carries the same short notice Redmine puts on its own.

[Vega](https://github.com/vega/vega), [Vega-Lite](https://github.com/vega/vega-lite) and
[Vega-Embed](https://github.com/vega/vega-embed) (BSD 3-Clause) are bundled in `assets/javascripts`, and the fallback
colors are [Open Color](https://github.com/yeun/open-color) values (MIT). Their notices are in `NOTICE.md`.

No warranty, as the GPL says. The plugin only reads tickets: it adds no table and changes no ticket. Tested in CI on Redmine
7.0, 6.1, 6.0 and 5.1. Try it on a copy of your tracker first.
