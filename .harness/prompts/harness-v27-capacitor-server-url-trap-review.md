# Codex review prompt — Hara v2.7 CAPACITOR_SERVER_URL trap detection

You are an independent reviewer for a *small surface* Hara ship that codifies a
lesson from the immediately prior starpin v0.22 dogfood.

## Target

`harness(v2.7)` — adds a detect block to starpin's `run-mobile-smoke.sh` that
warns when `CAPACITOR_SERVER_URL` is set (either via env or `.env.local`), and
documents the pattern in PATTERNS.md §smoke-setup as "CAPACITOR_SERVER_URL trap".

## Origin

starpin v0.22 dogfood (just shipped at `615b271`) cost 9 Maestro reruns +
simulator erase + uninstall/reinstall to discover that the iOS WKWebView was
loading HTML/JS from a ngrok-tunneled remote (configured in `.env.local`), NOT
the local bundle. The remote served pre-v0.22 build → silent failure mode where
every local build / sync / install signal showed green, only the runtime
accessibility tree revealed the mismatch.

## Files in scope

- `examples/starpin/scripts/run-mobile-smoke.sh` (+39 lines, detect block after
  `SMOKE_FRESH_SIM` handling, before sim boot detection)
- `PATTERNS.md` (+30 lines, "v2.7 — CAPACITOR_SERVER_URL trap (silent
  stale-asset failure)" subsection appended to §smoke-setup)
- `HARNESS.md` (title v2.6→v2.7, §11 row added)
- `DECISIONS.md` (ADR-043 added above ADR-042)
- `STATUS.md` (v2.6 marked SHIPPED retro, v2.7 pending)

`git diff --stat` summary: 5 files, ~110 insertions, 8 deletions.

## What I want you to evaluate

### A. Detect logic correctness

```bash
detect_capacitor_server_url() {
  local from_env="${CAPACITOR_SERVER_URL:-}"
  local from_file=""
  if [[ -z "$from_env" && -f "$ROOT/.env.local" ]]; then
    from_file=$(grep -E '^CAPACITOR_SERVER_URL=' "$ROOT/.env.local" 2>/dev/null \
      | head -1 \
      | sed -E 's/^CAPACITOR_SERVER_URL=//' \
      | sed -E 's/^"(.*)"$/\1/' \
      | sed -E "s/^'(.*)'\$/\1/")
  fi
  local effective="${from_env:-$from_file}"
  if [[ -n "$effective" ]]; then
    echo "[WARN: CAPACITOR_SERVER_URL set ($effective)]" >&2
    # ... 5 more guidance lines
  fi
}
```

1. **Env precedence**: env wins over `.env.local` (matches dotenv convention).
   Right?
2. **`.env.local` parsing**: handles single-quoted, double-quoted, or unquoted
   values; only first matching line. Misses: multi-line values (impossible in
   dotenv standard), `export CAPACITOR_SERVER_URL=...` form (Capacitor's
   dotenv pkg supports it but doesn't enforce). Acceptable scope?
3. **No-fire case**: env unset + `.env.local` absent or doesn't set the var →
   silent (correct). Confirm?
4. **Warning placement**: after `SMOKE_FRESH_SIM` shutdown, before sim boot
   detection. Visible immediately when log starts.

### B. Decision: warn-not-probe

ADR-043 §Non-decisions explains why we don't probe the remote for asset
freshness:
- Cross-origin probe (curl/HEAD) gets blocked by the harness permission
  classifier as "exfil scouting" (already observed in v0.22 debug session)
- Remote may need auth headers/cookies
- Hash compare with cache busting / minification produces false alarms
- 30s warning is sufficient signal for future operator

Is this reasoning sound? Or should we add an opt-in probe behind a `SMOKE_PROBE_REMOTE=1` flag?

### C. Scope: starpin-specific impl vs Hara-level shared helper

The implementation lives in `examples/starpin/scripts/`. PATTERNS.md
documentation lives in Hara. Other Capacitor projects would copy/paste the
detect block. Acceptable, or should there be a `scripts/lib/` shared helper in
the root harness that starpin's script sources?

### D. Warning quality

```
[run-mobile-smoke] WARN: CAPACITOR_SERVER_URL set (<value>)
[run-mobile-smoke]   iOS WKWebView will load assets from THIS remote, NOT the
[run-mobile-smoke]   local bundle in ios/App/App/public/. If remote has stale
[run-mobile-smoke]   code, Maestro will validate stale code (silent failure mode).
[run-mobile-smoke]   Fix: (a) restart backend dev server so ngrok'd remote serves
[run-mobile-smoke]   latest, OR (b) force local: 'CAPACITOR_SERVER_URL= bash $0 ...'.
[run-mobile-smoke]   See PATTERNS.md §smoke-setup — "CAPACITOR_SERVER_URL trap".
```

Is this enough to make a future operator pause 30s and realize the issue?
Anything missing (e.g., expected fix time, severity color)?

### E. PATTERNS.md and ADR-043 quality

Read the v2.7 subsection in PATTERNS.md and ADR-043 — do they correctly
characterize:
- The signal matrix (all green local, runtime stale)
- The diagnostic cost (9 reruns)
- The "warn-not-probe" decision rationale
- The carry path (`.env`/`.env.production` extension)

### F. Verdict

`pass | minor | major | block` + 1-2 sentence rationale.
