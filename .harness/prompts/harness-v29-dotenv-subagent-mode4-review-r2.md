# Codex r2 — Hara v2.9 dotenv extension + Mode 4 (post-r1 alignment fix)

r1 verdict was `major`: detector checked 3 files but `capacitor.config.ts`
only loaded `.env.local` → false positives for `.env`/`.env.production`.

## r1 → r2 patches

### MAJOR — detector ↔ Capacitor loader alignment (FIXED)

`examples/starpin/capacitor.config.ts`:

```diff
- loadEnv({ path: '.env.local' });    // explicit; capacitor CLI 가 자동 안 함
+ // v2.9 (Hara): 3-file priority chain matches the run-mobile-smoke.sh detector
+ // — `.env.local` > `.env` > `.env.production`. dotenv default behavior is
+ // non-overwriting, so the FIRST load to set a var wins → loading `.env.local`
+ // first preserves local-overrides convention.
+ loadEnv({ path: '.env.local' });
+ loadEnv({ path: '.env' });
+ loadEnv({ path: '.env.production' });
```

Now `CAPACITOR_SERVER_URL` in any of the 3 files actually drives the iOS
WKWebView remote load → detector warnings are accurate (no false positives).

### NIT — §subagent-recovery intro (FIXED)

`PATTERNS.md`:
```diff
- Phase 03 background subagent 가 작업 중 실패하는 3 가지 모드 + 대응:
+ Phase 03 background subagent 가 작업 중 실패하는 4 가지 모드 + 대응:
```

## Validation

- `bash -n examples/starpin/scripts/run-mobile-smoke.sh`: clean
- 4-case dotenv self-test PASS (unchanged from r1)
- `npm --prefix backend run build`: clean (capacitor.config.ts compile)
- `npm --prefix backend test`: 472 pass / 3 skip / 0 fail / 0 regression
- `npx cap sync ios`: clean (capacitor.config.json still generated)

## What to confirm

1. dotenv chain order: `.env.local` first → non-overwrite means it wins
   over later loads. Confirm this matches the detector's first-match-wins
   loop semantics.
2. The "non-overwrite" default: was there a `dotenv` version where this
   changed? Current backend uses `"dotenv": "^16.x"` — confirm default
   behavior is still non-overwrite.
3. Mode 4 intro update is correct (3 → 4).
4. Final verdict: `pass | minor | major | block`.
