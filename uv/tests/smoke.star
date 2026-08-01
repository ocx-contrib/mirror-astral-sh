# tests/smoke.star — stable across upstream uv releases.
# Asserts machine-stable contracts only: exit codes, version digits,
# subcommand presence. Never asserts help prose or banner text.
#
# Every command below was verified against the real 0.10.0 (the version floor)
# and 0.12.1 binaries — the surface has not moved across the mirrored range.

UV = "uv.exe" if ocx.target_platform.os == ocx.os.Windows else "uv"
UVX = "uvx.exe" if ocx.target_platform.os == ocx.os.Windows else "uvx"

# Tier 1 + 2: liveness + version shape.
r = ocx.run(UV, "--version")
expect.ok(r)
expect.matches(r.stdout, r"\d+\.\d+\.\d+")

# Tier 1: the second published binary (uvx) also resolves on the composed PATH.
expect.ok(ocx.run(UVX, "--version"))

# Tier 3: functional behavior on a real code path (not a --help short-circuit).
# `uv cache dir` resolves and prints a cache path — exercises real init.
r = ocx.run(UV, "cache", "dir")
expect.ok(r)
expect.true(len(r.stdout) > 0)

# Tier 3: subcommand-presence probes — prove the surfaces EXIST via exit code,
# without scraping help descriptions (which upstream rewords freely).
expect.eq(ocx.run(UV, "help", "pip").exit_code, 0)
expect.eq(ocx.run(UV, "help", "venv").exit_code, 0)

# metadata.json declares PATH only — no Tier 4 env-var wiring to test.
