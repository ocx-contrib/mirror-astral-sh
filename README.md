# mirror-astral-sh

OCX mirrors for [Astral](https://astral.sh) tooling. Each package publishes to
`ghcr.io/ocx-contrib/astral-sh/<package>` with cascade tags after a smoke test
per `(version, platform)`, then announces the result into the OCX index as
`ocx.sh/astral-sh/<package>`.

| Package | Upstream | Index name | Upstream SPDX |
|---|---|---|---|
| [`python-build-standalone/`](python-build-standalone/) | [astral-sh/python-build-standalone](https://github.com/astral-sh/python-build-standalone) | `ocx.sh/astral-sh/python-build-standalone` | `PSF-2.0 AND MPL-2.0` |
| [`uv/`](uv/) | [astral-sh/uv](https://github.com/astral-sh/uv) | `ocx.sh/astral-sh/uv` | `Apache-2.0 OR MIT` |
| [`ruff/`](ruff/) | [astral-sh/ruff](https://github.com/astral-sh/ruff) | `ocx.sh/astral-sh/ruff` | `MIT` |
| [`ty/`](ty/) | [astral-sh/ty](https://github.com/astral-sh/ty) | `ocx.sh/astral-sh/ty` | `MIT` |

> **Two different things are called "uv" here.** The
> `[tools] uv = "ocx.sh/astral-sh/uv:0"` entry in `ocx.toml` is a **build-time**
> dependency — the CLI that runs `python-build-standalone/scripts/generate.py`.
> It is unrelated to the `uv/` package this repo mirrors, though it now resolves
> to it: the toolchain entry points at this repo's own published package.
> `ocx-contrib/mirror-uv` still serves the older flat coordinate `ocx.sh/uv`, but
> that repo is slated for deletion and the flat name dies with the `ocx.sh` host
> — **never pin `ocx.sh/uv:0` in new work.**

## Layout

One directory per package. Everything a package owns — its spec, metadata,
catalog entry, logo and smoke test — lives in its own directory, so adding a
package renames nothing and editing one never triggers another's CI.

```
mirror-base.yml         repo-wide policy for the Rust CLIs (see below)
<package>/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface (+ metadata-<platform>.json overrides)
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
├── scripts/            url_index generator, where the source needs one
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because they are different marks (the Python
two-snake for `python-build-standalone`, Astral's own for the rest) and because
a repo-root `logo.*` sits in no workflow's `paths:` filter, so replacing it
would publish nothing until some unrelated edit happened to fire.

### `mirror-base.yml`

`uv/`, `ruff/` and `ty/` share a base via `extends: ../mirror-base.yml`: the
same release cadence, the same libc verdict, and therefore the same platform and
container matrix. `python-build-standalone/` does **not** extend it — it needs
`build_timestamp: none`, much lower concurrency limits for its 22–120 MB assets,
and a different platform set, so it stays self-contained.

⚠️ `extends:` is a **shallow merge** of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim goes
back to being asserted rather than verified. Restate a block in full or not at
all.

## Platforms

`uv`, `ruff` and `ty` each publish **eight** platform entries. Upstream ships
both a glibc-linked gnu build and a fully static musl build for each Linux
arch, and both are carried — but **not** as a glibc/musl pair:

| Key | Asset | Requires | Container legs |
|---|---|---|---|
| `linux/{amd64,arm64}` | `*-unknown-linux-musl.tar.gz` | nothing — static | `ubuntu:24.04`, `alpine:3.20`, `fedora:40` |
| `linux/{amd64,arm64}+libc.glibc` | `*-unknown-linux-gnu.tar.gz` | a glibc loader | `ubuntu:24.04`, `fedora:40` |
| `darwin/{amd64,arm64}` | `*-apple-darwin.tar.gz` | — | — |
| `windows/{amd64,arm64}` | `*-pc-windows-msvc.zip` | — | — |

`os.features` states what an artifact **requires of the host**, not how it was
built. The musl builds are static (no `PT_INTERP`), so they require nothing and
take a **bare** key — tagging them `+libc.musl` would be a false requirement
that hid them from every glibc host. Resolution is subset matching scored by
specificity, so a glibc host matches both keys and takes the more specific
`+libc.glibc` one, while a musl host matches only the bare key and gets the
static build.

The container legs are the only thing that turns those claims into evidence —
the bare key claims universality, so its alpine leg is the entire proof. The
measurement behind each key (`file` / `readelf` / `ldd` on the real artifacts)
is recorded above the `assets:` block in each spec.

`python-build-standalone` declares its own set: the same four libc-split Linux
keys, both darwin arches, and `windows/amd64` only.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `<package>/mirror.yml`, `mirror-base.yml` | hand | yes — see below |
| `<package>/{metadata*.json,CATALOG.md,logo.*}` | hand | — |
| `<package>/tests/smoke.star`, `<package>/scripts/*` | hand | — |
| `.github/workflows/*.yml` | **generated** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci \
  --spec python-build-standalone/mirror.yml \
  --spec uv/mirror.yml \
  --spec ruff/mirror.yml \
  --spec ty/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces. `--repo-root` is inferred from the enclosing git repository; the guard
bakes its own check command without that flag, so passing one here would put the
two permanently out of step.

Never hand-edit `.github/workflows/`. `verify-generated.yml` exits 65 on any
drift; if a generated workflow is wrong, the spec or the template is wrong.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

### `binaries` and `bin_scan`

`python-build-standalone` uses `bin_scan: auto` — every executable it ships also
appears under a CPython-minor alias, so the correct list is version-dependent
and cannot be written down. That is why its Windows archive keeps its `python/`
wrapper (`strip_components: 0`) while Linux and macOS drop theirs: the scan
needs a `${installPath}/<dir>` target.

The three Rust CLIs hand-list `binaries` with `bin_scan: off`. They ship a flat
handful of executables at the content root on every platform, so there is no
`${installPath}/<dir>` to scan at all — the reasoning is spelled out above each
spec's `bin_scan` key.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
