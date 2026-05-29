# Codex review — Hara v2.9 dotenv extension + §subagent-recovery Mode 4

You are an independent reviewer for a *very small surface* Hara ship that
closes 1 carry item + codifies 1 new lesson.

## Target

`harness(v2.9)` — two clean follow-up changes:

### A. CAPACITOR_SERVER_URL detect — dotenv 3-file extension (v2.7 carry close)

v2.7 codified `CAPACITOR_SERVER_URL` trap detection in
`starpin/scripts/run-mobile-smoke.sh` — `.env.local` only. v2.7 ADR-043
explicitly named v2.7.1 carry: "`.env` / `.env.production` 추가 detect". v2.9
closes that carry.

Change: `.env.local` single-file lookup → 3-file priority loop
(`.env.local` → `.env` → `.env.production`, dotenv local-overrides
convention). First match wins. Warning copy updated.

### B. PATTERNS §subagent-recovery — Mode 4 (rate-limit) codify

v0.25 ISS ship hit a new subagent failure mode that didn't match the existing
3 modes (529 / socket close / spec-incomplete): `API Error: Server is
temporarily limiting requests · Rate limited`. Subagent did `tool_uses=42`
before throttle → 30% partial. Coordinator finished 70% direct.

Added as Mode 4 with the existing diagnose/recover template + v0.25 precedent.

## Files in scope

- `examples/starpin/scripts/run-mobile-smoke.sh` (+12 lines: 1-line → 8-line
  for-loop, warning copy update)
- `PATTERNS.md` §smoke-setup bash snippet sync (+8 lines for-loop) + carry
  line update; §subagent-recovery Mode 4 block (+15 lines)
- `HARNESS.md` (title v2.8 → v2.9; §11 row added)
- `DECISIONS.md` (ADR-048 added)
- `STATUS.md` (v2.8 SHIPPED + v2.9 pending)

## Validation

- `bash -n` clean on the script
- 4-case dotenv self-test PASS:
  1. no env file, unset env → no warning
  2. `.env.local` has URL → warning
  3. `.env` has URL (no `.env.local`) → warning
  4. `.env.production` has URL → warning
- Production starpin build / test untouched (script change only)

## What to evaluate

### A. dotenv 3-file priority order

`.env.local` → `.env` → `.env.production` (local-overrides convention). Some
dotenv loaders also support `.env.development` / `.env.test` /
`.env.<NODE_ENV>.local`. ADR-048 §Consequences notes that v2.9.x carry would
add those if a real project needs them. Acceptable v2.9 scope?

### B. Loop bash semantics

```bash
for f in "$ROOT/.env.local" "$ROOT/.env" "$ROOT/.env.production"; do
  [[ -f "$f" ]] || continue
  from_file=$(grep -E '^CAPACITOR_SERVER_URL=' "$f" 2>/dev/null \
    | head -1 | sed -E 's/^CAPACITOR_SERVER_URL=//' \
    | sed -E 's/^"(.*)"$/\1/' | sed -E "s/^'(.*)'\$/\1/")
  [[ -n "$from_file" ]] && break
done
```

- Correct first-match-wins?
- If `.env.local` exists but has NO `CAPACITOR_SERVER_URL=` line, the grep
  returns empty → `from_file=""` → break check fails → loop continues to
  `.env`. Right?
- Bash 3.2 compat (macOS default) — `for` loop with explicit list, `[[`
  conditionals: works on 3.2.

### C. Mode 4 codification

The new block extends §subagent-recovery with the v0.25 precedent. Format
matches existing modes (신호 / 현상 / 대응 / precedent). Is the diagnostic
signal (`total_tokens=0` + `tool_uses>0`) distinctive enough vs Mode 2
(socket close: `total_tokens>0`, `tool_uses>0`)? Both modes share the same
recovery pattern (diagnose + coordinator-finish), so the only real
difference is the cause label. Worth a separate mode, or could fold into
Mode 2 as a sub-case?

### D. Verdict

`pass | minor | major | block` + 1-2 sentence rationale.
