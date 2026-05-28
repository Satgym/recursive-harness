You are conducting r2 review of Hara v2.5 — verify r1 1 major + 2 minor closures.

## r1 → r2 patches

**Major** (SMOKE_FRESH_SIM only shuts first booted sim — multi-sim leak):
→ `examples/starpin/scripts/run-mobile-smoke.sh`:
  - Replaced python3 JSON parse + first-only shutdown with single `xcrun simctl shutdown all 2>/dev/null || true` + 2s sleep
  - Self-test: SMOKE_FRESH_SIM=1 rerun → 25s PASS, 5 PNG (after patch verified)

**Minor #1** (PATTERNS misleads about `clearState`):
→ `PATTERNS.md` root cause #4:
  - "Capacitor 의 localStorage 만 clear" → "iOS 에서 app data 폴더 reinstall 수행 (localStorage 포함 reset) 하지만 simulator-level system overlay (Siri dictation, share sheet, notification permission) dismiss 는 *보장 안 함* (Maestro 공식 docs)"

**Minor #2** (PATTERNS path mismatch + carry confusion):
→ `PATTERNS.md` v2.5 mitigation section rewritten:
  - "scripts/run-mobile-smoke.sh" → `<project>/scripts/run-mobile-smoke.sh` (예: `examples/starpin/scripts/run-mobile-smoke.sh`)
  - 호출 example 도 `examples/<proj>/scripts/...`
  - "v2.6 carry" 라인 제거 (deliverable-categories carry 표에 이미 있음 — duplicate avoidance)

## YOUR REVIEW (r2)

### Section A — multi-sim closure
1. `xcrun simctl shutdown all` 는 모든 state 의 sim 을 shutdown (Booted + Shutting Down 등). 의도 정확?
2. iOS sim 외 다른 platform (Android emulator) 영향 없는지 — `$PLATFORM == "ios"` guard 확인.
3. sleep 2s 후 boot detection 작동? — self-test PASS 로 확인.

### Section B — PATTERNS clarity
1. clearState 표현 정확? Maestro 공식 docs 인용 (link 명시 안 했지만 표현 자체).
2. path 표기 일관 (PATTERNS 본문 + 호출 example)?

### Section C — Regression
1. SMOKE_FRESH_SIM=0 (default) → 변경 없음 — backward compat 확인.
2. self-test 1 PASS 후 file 변경 없는 second run 도 PASS 예상 (idempotent).
3. 새 minor finding 없는지.

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose.
