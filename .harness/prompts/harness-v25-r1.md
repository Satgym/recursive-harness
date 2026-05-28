You are conducting r1 review of Hara v2.5 — PATTERNS §dom-mutation-order + §smoke-setup + scripts/run-mobile-smoke.sh `SMOKE_FRESH_SIM` env var.

## Context

v0.20 dogfood lessons (ADR-038):
1. Subagent 가 today-widget mount 를 fetchNews 전에 함 → `while removeChild` 가 widget 제거 → "오늘의 하늘" 사라짐. coordinator 가 post-hoc fix (DOM mutation order)
2. iOS sim 의 Siri 받아쓰기 prompt 가 다음 Maestro run 까지 system-level 잔존 → "starpin" assertion FAIL. workaround: sim restart

v2.5 = 두 lesson 의 codification + env var helper.

## v2.5 changes

1. `PATTERNS.md` §dom-mutation-order (NEW):
   - anti-pattern vs correct pattern 코드 예시
   - subagent prompt imperative (DOM mutation 순서)
   - v2.6 carry: check-subagent-prompt.sh grep enforcement

2. `PATTERNS.md` §smoke-setup (NEW):
   - root causes (iOS dialogs / stale WebView / session token / clearState 한계)
   - v2.5 mitigation: scripts/run-mobile-smoke.sh `SMOKE_FRESH_SIM=1` env var
   - Maestro flow level: defensive `runFlow when visible "받아쓰기"` block

3. `scripts/run-mobile-smoke.sh`:
   - Top: optional `SMOKE_FRESH_SIM=1` 가 set 되면 `xcrun simctl shutdown booted` 후 boot 재시작 (clean state)
   - Default behavior 변화 없음 (env unset → 기존 동작)

4. Subagent prompts §deliverable-categories precedent 표에 v0.20 case 추가.

## Self-test

- `SMOKE_FRESH_SIM=1 bash scripts/run-mobile-smoke.sh ios today-search-smoke` → sim shutdown + reboot + Maestro PASS (5 PNG)
- env unset → 기존 동작 (sim 재시작 X) — backward compat

## YOUR REVIEW (r1)

### Section A — §dom-mutation-order
1. Anti-pattern + correct pattern code 차이 명확? subagent 가 imperative 따르기 쉬움?
2. starpin v0.20 의 newsletter.ts 실제 fix 가 본 pattern 과 일치?
3. v2.6 carry (grep enforcement) — 적절한 future path?

### Section B — §smoke-setup
1. root causes 4 항목 — 실제로 dogfood 에서 모두 마주칠 일?
2. `SMOKE_FRESH_SIM=1` env var pattern 합리? 더 자주 set 되어야 한다면 default 가 1?
3. defensive runFlow snippet (Maestro Siri dismiss) — 정확한 syntax?

### Section C — scripts change
1. python3 inline embedded — bash + python composition acceptable?
2. CURRENT_BOOTED detection 정확? (`state == 'Booted'`)
3. error handling — `2>/dev/null || true` 충분?

### Section D — backward compat / regression
1. env var unset → 기존 동작 정확 보존?
2. 다른 callers (CI, fleet tests) 가 본 변경에 영향받음?

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose.
