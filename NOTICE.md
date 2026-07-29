# NOTICE

This repository packages and redistributes upstream
[python-build-standalone](https://github.com/astral-sh/python-build-standalone).

The Apache-2.0 license covers the OCX pipeline files authored here. It does
**not** cover upstream-derived assets — the CPython binaries published to
`ghcr.io/ocx-contrib/astral-sh/python-build-standalone` and the Python logo
(PSF trademark, used for catalog identification under nominative-fair-use).

## Redistributed bytes and their licenses

| Component | SPDX | Holder |
|---|---|---|
| CPython interpreter and standard library | **PSF-2.0** | Python Software Foundation |
| python-build-standalone build recipes and patches | **MPL-2.0** | Astral Software Inc. |

The published archives also embed statically linked third-party libraries
(OpenSSL, SQLite, libffi, zlib, bzip2, xz, ncurses/libedit, Tcl/Tk). Upstream
enumerates every bundled component and its license at
<https://gregoryszorc.com/docs/python-build-standalone/main/licensing.html>;
each build additionally ships a `PYTHON.json` manifest listing the licenses
that apply to that exact artifact.

## Source conveyance

MPL-2.0 is a file-level weak copyleft: redistributing a binary built from
MPL-covered files obliges us to make the Source Code Form of those files
available. Each mirrored version's Corresponding Source is the upstream tag
it was built from, published at the same place, at no charge:

    https://github.com/astral-sh/python-build-standalone/releases/tag/<build_date>

where `<build_date>` is the `+YYYYMMDD` segment of the mirrored version — a
version `3.13.14+20260728` was built from tag `20260728`. No modifications
are made to the upstream artifacts; they are republished byte-for-byte inside
an OCX bundle.
