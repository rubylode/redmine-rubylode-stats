# Rubylode Stats for Redmine

Charts over a project's tickets: by category, open and closed, over time, who closed what, and how long it takes. Vega-Lite,
driven by Redmine's own filters. A plugin for Redmine 7 and up.

Status: skeleton (0.1.0). The brief is in `docs/specs/2026-10-29-stats-brief.md`.

## Try it

    docker compose up -d      # then http://localhost:3008, admin / admin
    bin/test                  # the integration tests

## License

GPL v2 or later, see `LICENSE`.
