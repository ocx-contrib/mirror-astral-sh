# /// script
# requires-python = ">=3.13"
# dependencies = ["ocx-mirror-sdk~=0.6.0"]
# ///
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The OCX Authors
"""Generate url_index JSON for astral-sh/python-build-standalone.

Upstream tags a *release* by build date (`20260728`) and ships every
supported CPython minor under that one tag. A `github_release` source maps
one tag to one version, so a per-triple asset regex would match six assets
and resolve as ambiguous. This generator explodes each release into one ocx
version per `(python_version, build_date)` pair — `3.13.14+20260728` — so
each emitted version owns only its own platform tarballs.

Both build flavors this mirror publishes (`install_only` and
`install_only_stripped`) are emitted into the same version's asset map;
`mirror.yml`'s two `variants:` route each to its own tag prefix.

Only the NEWEST build date is emitted per CPython version. Upstream rebuilds
every supported minor on every release, so emitting all of them would
backfill dozens of superseded rebuilds of the same interpreter. A genuinely
new upstream build of an already-published patch still lands: it carries a
later build date, which is a new version.
"""

from __future__ import annotations

import re
import sys

from ocx_mirror_sdk import IndexBuilder, github

REPO = "astral-sh/python-build-standalone"

# `cpython-<python_version>+<build_date>-<triple>-<flavor>.tar.gz`.
#
# Anchored on both ends, and the flavor group admits only the two archives
# this mirror publishes. That is what excludes `-freethreaded-install_only`
# (a different, GIL-free ABI), the `*-full` development artifacts (`.tar.zst`
# — a different extension entirely), and any future suffix upstream adds.
# The python_version group is `\d+\.\d+\.\d+` with no pre-release part, so
# CPython betas riding a stable upstream release (`3.15.0b4+20260728`) never
# reach the index.
FILENAME_RE = re.compile(
    r"^cpython-(?P<version>\d+\.\d+\.\d+)\+(?P<date>\d{8})"
    r"-(?P<triple>[a-z0-9_]+-[a-z0-9-]+)"
    r"-install_only(?:_stripped)?\.tar\.gz$"
)

# The exact triples mirror.yml declares. A triple absent here is scoped out
# of the mirror (armv7/ppc64le/riscv64/s390x/i686/windows-arm64, the
# x86_64_v2-v4 micro-arch levels) — see the scope comment in mirror.yml.
TRIPLES = frozenset(
    {
        "x86_64-unknown-linux-gnu",
        "x86_64-unknown-linux-musl",
        "aarch64-unknown-linux-gnu",
        "aarch64-unknown-linux-musl",
        "x86_64-apple-darwin",
        "aarch64-apple-darwin",
        "x86_64-pc-windows-msvc",
    }
)

# Per-minor patch floor, inclusive. A minor absent from this map is not
# mirrored at all, which is what keeps a new CPython series (and its betas)
# out until someone opts it in. Raising a floor retires older patches;
# already-published versions stay in the registry and the index.
MINOR_FLOORS: dict[tuple[int, int], tuple[int, int, int]] = {
    (3, 12): (3, 12, 13),
    (3, 13): (3, 13, 14),
    (3, 14): (3, 14, 6),
}

VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def log(message: str) -> None:
    sys.stderr.write(f"generate: {message}\n")


def in_scope(py_version: str) -> bool:
    """True when py_version is a mirrored minor at or above its patch floor."""
    match = VERSION_RE.match(py_version)
    if match is None:
        return False
    major, minor, patch = (int(part) for part in match.groups())
    floor = MINOR_FLOORS.get((major, minor))
    return floor is not None and (major, minor, patch) >= floor


def main() -> int:
    # REST, deliberately. This repo carries ~850 assets per release; the SDK's
    # REST backend pages down adaptively on a 504 and reads the inline asset
    # list, so a full crawl is a handful of requests. GraphQL is billed against
    # a shared points budget that the N concurrent CI prepare legs exhaust
    # (ocx-sh/ocx#160), reddening the whole run on a busy release.
    releases = list(
        github.list_releases(
            REPO,
            backend=github.Backend.REST,
            include_prereleases=False,
            include_drafts=False,
        )
    )
    log(f"fetched {len(releases)} releases")

    # (python_version, build_date) -> {asset_name: url}
    pairs: dict[tuple[str, str], dict[str, str]] = {}
    # python_version -> newest build_date seen
    newest: dict[str, str] = {}
    out_of_scope = 0

    for release in releases:
        for asset in release.assets:
            match = FILENAME_RE.match(asset.name)
            if match is None:
                continue
            if match["triple"] not in TRIPLES:
                continue
            version, date = match["version"], match["date"]
            if not in_scope(version):
                out_of_scope += 1
                continue
            pairs.setdefault((version, date), {})[asset.name] = asset.browser_download_url
            if date > newest.get(version, ""):
                newest[version] = date

    if out_of_scope:
        log(f"skipped {out_of_scope} assets outside the mirrored minor/patch floors")

    index = IndexBuilder()
    emitted = 0
    for (version, date), assets in sorted(pairs.items()):
        if newest[version] != date:
            continue
        ocx_version = f"{version}+{date}"
        index.add_version(ocx_version, assets=assets, prerelease=False)
        log(f"  {ocx_version} ({len(assets)} assets)")
        emitted += 1

    if emitted == 0:
        log("no versions generated — check MINOR_FLOORS against upstream")
        return 1

    index.emit()
    log(f"done — {emitted} versions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
