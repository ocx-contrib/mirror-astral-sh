# tests/smoke.star — stable across upstream ty releases.
# Asserts machine-stable contracts only: exit codes, version digits, and a
# stable diagnostic id. Never asserts diagnostic prose — the `invalid-return-type`
# MESSAGE has been reworded within the mirrored range; the id has not.
#
# Every command and exit code below was verified against the real 0.0.40 (the
# version floor) and 0.0.65 binaries.

TY = "ty.exe" if ocx.target_platform.os == ocx.os.Windows else "ty"

# ── Tier 1 + 2 — liveness and version SHAPE ────────────────────────────────
r_version = ocx.run(TY, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3 — the checker actually infers types ─────────────────────────────
# A hermetic file whose declared return type contradicts what it returns.
# Reaching a correct verdict requires the whole inference pipeline, not just
# a parse. Exit 1 plus the stable rule id is the contract.
ocx.write_file("bad.py", "def f(x: int) -> str:\n    return x\n")
r_bad = ocx.run(TY, "check", "--output-format", "concise", "bad.py")
expect.eq(r_bad.exit_code, 1)
# Which stream carries diagnostics is not part of the contract — assert on both.
expect.contains(r_bad.stdout + r_bad.stderr, "invalid-return-type")

# The other direction — a well-typed file must PASS. Without this, a checker
# that errored on everything (or failed to load its typeshed stubs) would
# satisfy the assertion above.
ocx.write_file("good.py", "def f(x: int) -> int:\n    return x\n\n\ny: int = f(1)\n")
expect.ok(ocx.run(TY, "check", "--output-format", "concise", "good.py"))

# metadata.json declares PATH only — no Tier 4 env-var wiring to test.
