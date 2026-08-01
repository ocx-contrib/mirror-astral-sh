# tests/smoke.star — stable across upstream ruff releases.
# Asserts machine-stable contracts only: exit codes, version digits, and a
# stable rule code. Never asserts diagnostic prose, which upstream rewords
# freely (the F401 message text has changed within the mirrored range; the
# code has not).
#
# Every command and exit code below was verified against the real 0.14.0 (the
# version floor) and 0.16.1 binaries.
#
# `--isolated --no-cache` on every invocation: the test sandbox must not pick
# up a pyproject.toml or a cache directory from anywhere outside it, or the
# assertions below would depend on the runner's filesystem.

RUFF = "ruff.exe" if ocx.target_platform.os == ocx.os.Windows else "ruff"

# ── Tier 1 + 2 — liveness and version SHAPE ────────────────────────────────
r_version = ocx.run(RUFF, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3 — the linter actually lints ─────────────────────────────────────
# A hermetic file with one unambiguous violation. Exit 1 plus the stable rule
# code F401 (pyflakes: unused import) is the contract; the message wording is
# not. A stub binary that always exits 0, or one whose rule engine failed to
# initialize, cannot reach this.
ocx.write_file("bad.py", "import os\n")
r_check = ocx.run(
    RUFF, "check", "--no-cache", "--isolated", "--output-format", "concise", "bad.py"
)
expect.eq(r_check.exit_code, 1)
expect.contains(r_check.stdout, "F401")

# The other direction — a clean file must PASS. Without this, a linter that
# flagged everything would satisfy the assertion above.
ocx.write_file("good.py", "import os\n\nprint(os.name)\n")
expect.ok(
    ocx.run(
        RUFF, "check", "--no-cache", "--isolated", "--output-format", "concise", "good.py"
    )
)

# ── Tier 3 — the formatter actually rewrites the file ──────────────────────
# Proved by a computed result rather than by scraping output: --check reds on
# the unformatted file, the format run rewrites it, and --check then greens on
# the SAME path. That third assertion is the one a no-op binary cannot reach —
# it can only pass if the bytes on disk actually changed.
ocx.write_file("fmt.py", "x   =    1\n")
expect.eq(
    ocx.run(RUFF, "format", "--no-cache", "--isolated", "--check", "fmt.py").exit_code, 1
)
expect.ok(ocx.run(RUFF, "format", "--no-cache", "--isolated", "fmt.py"))
expect.eq(
    ocx.run(RUFF, "format", "--no-cache", "--isolated", "--check", "fmt.py").exit_code, 0
)

# metadata.json declares PATH only — no Tier 4 env-var wiring to test.
