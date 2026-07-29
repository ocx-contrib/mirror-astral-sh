# mirror-astral-sh

OCX mirror for [python-build-standalone](https://github.com/astral-sh/python-build-standalone).
Publishes Astral's self-contained CPython builds to
`ghcr.io/ocx-contrib/astral-sh/python-build-standalone` with cascade tags
after a smoke test per `(version, platform)`, then announces the result into
the OCX index as `ocx.sh/astral-sh/python-build-standalone`.

Two build flavors ship from the same upstream release:

| Variant | Upstream archive | Tags |
|---|---|---|
| default | `install_only` | `3.13.14+20260728`, `3.13`, `3`, `latest` |
| `slim` | `install_only_stripped` | `slim-3.13.14+20260728`, `slim-3.13`, … |

A version is `<cpython_patch>+<upstream_build_date>`. Upstream tags releases
by build date and ships every supported minor under one tag, so
`scripts/generate.py` explodes each release into one version per
`(python_version, build_date)` pair and keeps only the newest build date per
patch. Which minors are mirrored, and from which patch, is the `MINOR_FLOORS`
map in that script — the only place to change coverage.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror.yml` | hand | `ocx-mirror package pipeline generate ci` |
| `scripts/generate.py` | hand | — |
| `tests/smoke.star` | hand | — |
| `metadata*.json`, `CATALOG.md`, `logo.*` | hand | — |
| `.github/workflows/*.yml` | generated | re-run when `mirror.yml` changes |

CI fails on drift via `ocx-mirror package pipeline generate ci --check`.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use
the run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; see
[`NOTICE.md`](NOTICE.md).
