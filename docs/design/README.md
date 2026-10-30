# Design mockups

Sheets are self-contained HTML in `mockups/`; they load the vendored chart scripts from `assets/javascripts/` by relative path,
so serve the repository root (any static server) and open them. Screenshots are in `previews/`. Chrome of each sheet (tags and
notes) is magenta on purpose, outside the palette. No variant has been picked yet.

| Sheet | Contents | Preview | Pick |
|-------|----------|---------|------|
| `mockups/2026-10-30-stats-layout.html` | Page layout, Overview tab: A card grid, B numbers first, C filter rail; light and dark | `previews/2026-10-30-stats-layout.png` | none yet |
| `mockups/2026-10-30-stats-open-closed-versions.html` | Open versus closed card (both halves, centre percentage, clickable legend); Versions tab | `previews/2026-10-30-stats-open-closed-versions.png` | none yet |

Theme variables the charts should read: `--oc-gray-9` (text), `--oc-white` (background), `--oc-gray-3` (grid lines),
`--oc-gray-4` (axis lines), `--oc-gray-5` (neutral fill), `--oc-blue-7` (accent), `--fonts-main` (font).
