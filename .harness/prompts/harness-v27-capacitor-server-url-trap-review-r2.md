# Codex r2 — Hara v2.7 CAPACITOR_SERVER_URL trap (post-r1 patch)

r1 verdict was `major`. r2 re-evaluates after 2 patches.

## r1 → r2 patches

### MAJOR — env precedence bug (FIXED)
- File: `examples/starpin/scripts/run-mobile-smoke.sh`
- Was: `local from_env="${CAPACITOR_SERVER_URL:-}"` then `[[ -z "$from_env" && -f ... ]]` — empty-string (force-local intent) fell through to `.env.local` re-read → false warning even when user followed the documented fix.
- Now: `${CAPACITOR_SERVER_URL+x}` distinguishes "set" (even to empty) from "unset". Set-but-empty = env precedence + no warning. Unset = fall through to `.env.local`.
- Self-test (3-case):
  - unset + `.env.local` populated → warns (from file)
  - empty (`CAPACITOR_SERVER_URL=`) → silent (force-local works)
  - set to value → warns (from env)

### MINOR — URL redaction (FIXED, HC-7)
- File: `examples/starpin/scripts/run-mobile-smoke.sh`
- Was: full URL printed to stderr
- Now: `sed -E 's|^([a-zA-Z]+://)([^@]*@)?([^/?#]+).*$|\1\3|'` strips userinfo (basic-auth user:pass@), path, query (api_key etc.), and fragment. Shows scheme + host only.
- Added "(full value redacted — see env or .env.local)" line so operator knows the displayed value is partial.
- Self-test: `https://user:pass@example.com/foo?token=secret#x` → `https://example.com`

## Doc updates (also patched)

- PATTERNS.md §smoke-setup v2.7 subsection — bash snippet updated to the corrected logic + 4-line "설계 결정" block citing r1 codex feedback.
- DECISIONS.md ADR-043 — new "r1 codex patches" block enumerating both fixes with self-test summary.

## Validation

- `bash -n scripts/run-mobile-smoke.sh` clean
- 3-case self-test passed (see above)
- Warning copy: 7 lines (was 6) — added redaction notice
- No regression to v2.5 `SMOKE_FRESH_SIM` logic (separate code path)

## What to evaluate

1. Did the `${VAR+x}` pattern correctly fix the precedence bug?
2. Does the redact sed work for edge cases (no scheme / IPv6 host / no userinfo / file:// / etc.)?
3. Is the "(full value redacted …)" line clear enough?
4. Any new concerns introduced?
5. Verdict: `pass | minor | major | block` + rationale.
