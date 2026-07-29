# tests/smoke.star — stable across upstream releases, one script for both
# build flavors.
#
# The `slim` variant ships an IDENTICAL file set to the default (verified:
# `diff` of the two `tar tf` listings for 3.13.14+20260728
# x86_64-unknown-linux-gnu is empty) — only debug symbols are stripped from
# the binaries. So there is no second contract to assert, and the variant
# needs no per-variant test axis: ocx-mirror folds the variant into the
# version axis, so this file already runs once per
# (version, platform, variant) leg.
#
# metadata.json declares PATH only, so the contract is Tiers 1-3.

# Windows ships `python.exe` at the archive root and no `python3`; Linux and
# macOS ship `python3` in `bin/`.
PY = "python.exe" if ocx.target_platform.os == ocx.os.Windows else "python3"

# ── Tier 1 + 2 — liveness and version SHAPE ────────────────────────────────
# Reaching exit 0 already requires the ELF/PE loader to accept the binary
# under this container's libc, `libpython` to resolve, and the frozen
# `encodings` bootstrap to find the bundle's own stdlib directory.
r_version = ocx.run(PY, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout + r_version.stderr, r"\d+\.\d+\.\d+")

# ── Tier 3 — the stdlib beyond the frozen bootstrap ────────────────────────
# This is the assertion a truncated or mis-relocated bundle cannot reach.
#
# `--version` above needs only the frozen `encodings` bootstrap, so it survives
# a bundle whose `lib/python3.X/` was truncated. Every name imported below is
# a pure-Python module that lives on disk under that directory, wrapping a C
# library upstream links statically into the interpreter (verified:
# `_ssl`, `_sqlite3`, `zlib`, `_lzma`, `_bz2`, `_ctypes`, `_hashlib`,
# `_decimal` and `_socket` are all in `sys.builtin_module_names` here — there
# is no `lib-dynload/*.so` for them). So this line reds on a missing stdlib
# tree, and the values printed below red on a C library that failed to
# initialize. Demonstrated by deleting `lib/python3.13/{json,sqlite3,ssl.py}`
# from a real bundle: `--version` still exited 0, this probe failed with
# `ModuleNotFoundError: No module named 'json'`.
#
# The values are computed by the interpreter and by those C libraries, never
# read from a string upstream controls.
ocx.write_file(
    "probe.py",
    """
import bz2, ctypes, decimal, hashlib, json, lzma, socket, sqlite3, ssl, sys, zlib

sys.stdout.write("sum=%d\\n" % sum(range(10)))
sys.stdout.write("sha256=%s\\n" % hashlib.sha256(b"ocx").hexdigest())
sys.stdout.write("crc32=%d\\n" % zlib.crc32(b"ocx"))
sys.stdout.write("ssl=%d\\n" % ssl.OPENSSL_VERSION_NUMBER)
sys.stdout.write("sqlite=%s\\n" % sqlite3.sqlite_version)
sys.stdout.write("json=%s\\n" % json.dumps({"n": len(lzma.compress(b"ocx" * 64)) > 0}))
""",
)
r_probe = ocx.run(PY, "probe.py")
expect.ok(r_probe)
# Interpreter-computed constants — a stub or a half-extracted archive cannot
# produce these, and they never change across CPython releases.
expect.contains(r_probe.stdout, "sum=45")
expect.contains(r_probe.stdout, "sha256=79eb99d1113252a8251e1589f7e0c20fbb4826ff0a96666fb7787133f379b08e")
expect.contains(r_probe.stdout, "crc32=2898564197")
expect.contains(r_probe.stdout, "json={\"n\": true}")
# Shapes, not values: these move with the bundled C libraries, so only their
# presence and form is the contract.
expect.matches(r_probe.stdout, r"ssl=\d+")
expect.matches(r_probe.stdout, r"sqlite=\d+\.\d+\.\d+")

# ── Tier 3 — the bundled installer is usable ───────────────────────────────
# `pip` is shipped into `site-packages` on every platform (only the Windows
# console script is absent, which is why metadata-windows.json's `binaries`
# claim is shorter). Exit 0 here proves site-packages was relocated with the
# interpreter rather than pointing at a build-time prefix.
r_pip = ocx.run(PY, "-m", "pip", "--version")
expect.ok(r_pip)
expect.matches(r_pip.stdout, r"\d+\.\d+")
