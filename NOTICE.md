# NOTICE

This repository packages and redistributes upstream software published by
[Astral](https://astral.sh). The Apache-2.0 license in [`LICENSE`](LICENSE)
covers the OCX pipeline files authored here. It does **not** cover any
upstream-derived asset — each package's redistributed bytes carry their own
license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `python-build-standalone` | `ghcr.io/ocx-contrib/astral-sh/python-build-standalone` | `PSF-2.0 AND MPL-2.0` |
| `uv` | `ghcr.io/ocx-contrib/astral-sh/uv` | `Apache-2.0 OR MIT` |
| `ruff` | `ghcr.io/ocx-contrib/astral-sh/ruff` | `MIT` |
| `ty` | `ghcr.io/ocx-contrib/astral-sh/ty` | `MIT` |

---

## `python-build-standalone`

Upstream: <https://github.com/astral-sh/python-build-standalone>
Published to `ghcr.io/ocx-contrib/astral-sh/python-build-standalone`.

| Component | SPDX | Holder |
|---|---|---|
| CPython interpreter and standard library | **PSF-2.0** | Python Software Foundation |
| python-build-standalone build recipes and patches | **MPL-2.0** | Astral Software Inc. |

The logo shipped with this package is the Python two-snake mark, a trademark of
the Python Software Foundation.

The published archives also embed statically linked third-party libraries
(OpenSSL, SQLite, libffi, zlib, bzip2, xz, ncurses/libedit, Tcl/Tk). Upstream
enumerates every bundled component and its license at
<https://gregoryszorc.com/docs/python-build-standalone/main/licensing.html>;
each build additionally ships a `PYTHON.json` manifest listing the licenses
that apply to that exact artifact.

### Source conveyance

MPL-2.0 is a file-level weak copyleft: redistributing a binary built from
MPL-covered files obliges us to make the Source Code Form of those files
available. Each mirrored version's Corresponding Source is the upstream tag
it was built from, published at the same place, at no charge:

    https://github.com/astral-sh/python-build-standalone/releases/tag/<build_date>

where `<build_date>` is the `+YYYYMMDD` segment of the mirrored version — a
version `3.13.14+20260728` was built from tag `20260728`. No modifications
are made to the upstream artifacts; they are republished byte-for-byte inside
an OCX bundle.

---

## `uv`

Upstream: <https://github.com/astral-sh/uv>
Published to `ghcr.io/ocx-contrib/astral-sh/uv`.

| Component | SPDX | Holder |
|---|---|---|
| uv (`uv`, `uvx`, `uvw`) | **Apache-2.0 OR MIT** | Astral Software Inc. |

Dual-licensed at the licensee's option; upstream ships both `LICENSE-APACHE`
and `LICENSE-MIT` at its repository root. Both are permissive and grant
redistribution of the compiled binaries. The uv logo is an Astral trademark.

The published binaries statically link third-party Rust crates under permissive
licenses; upstream's dependency licensing is enumerated in its `Cargo.lock` and
`LICENSE-APACHE`/`LICENSE-MIT`.

## `ruff`

Upstream: <https://github.com/astral-sh/ruff>
Published to `ghcr.io/ocx-contrib/astral-sh/ruff`.

| Component | SPDX | Holder |
|---|---|---|
| ruff | **MIT** | Astral Software Inc. |

Permissive; redistribution of the compiled binary is granted provided the
copyright notice and permission notice are retained. Upstream vendors rules
derived from Flake8 and its plugin ecosystem, isort, pyupgrade, pydocstyle and
Pylint; the licenses of those derived works are recorded in upstream's own
`LICENSE` file. The ruff logo is an Astral trademark.

## `ty`

Upstream: <https://github.com/astral-sh/ty>
Published to `ghcr.io/ocx-contrib/astral-sh/ty`.

| Component | SPDX | Holder |
|---|---|---|
| ty | **MIT** | Astral Software Inc. |

Permissive; redistribution of the compiled binary is granted provided the
copyright notice and permission notice are retained. The ty logo is an Astral
trademark.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
