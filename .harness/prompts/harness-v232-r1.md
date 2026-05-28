You are conducting r1 review of Hara v2.3.2 — codification of 4-ship dogfood lessons that v2.3.1 didn't cover.

## Context

v2.3.1 (c4200ca) closed parser/round/skill carry. starpin v0.17.1/0.17.2/0.17.3 진행 동안 추가 발견 lesson 2개를 PATTERNS.md 에 codify:

1. **Subagent deliverable category template** (§deliverable-categories) — 5 카테고리 explicit (Code / Styling / Tests / Fixture / impl-review) + Z-index convention (modal 1000 / overlay 1010 / banner 950 / FAB 50) + ARIA imperative for Maestro WKWebView
2. **Modal/overlay race pattern** (§modal-overlay-race) — DOM cleanup vs navigation 분리 (`_removeOverlayDom` internal vs `closeModal` public). v0.17.3 V-CX-TEL-01 root cause.

## Files changed

1. `PATTERNS.md`:
   - §deliverable-categories NEW — subagent prompt template, 5 카테고리 표, Z-index convention, ARIA imperative
   - §modal-overlay-race NEW — anti-pattern → correct pattern 코드 예시, 감지 방법, 적용 대상
2. `HARNESS.md`:
   - title v2.3.1 → v2.3.2
   - §11 version history row 추가
3. `STATUS.md` + `DECISIONS.md`:
   - STATUS row 갱신
   - ADR-032 added (this round)

## YOUR REVIEW

### Section A — §deliverable-categories utility

1. 5 카테고리 split (Code / Styling / Tests / Fixture / impl-review) 가 *실제 누락 패턴* 을 잘 covers? Z-index convention 이 실제 starpin 코드에서 사용된 값과 일치?
2. Template prose 가 subagent prompt 에 그대로 copy-paste 가능한 명확한 form? `<path>` `<description>` placeholder 가 헷갈리지 않게 specific?
3. Self-check mechanism — coordinator 가 prompt 작성 시 5 카테고리 모두 채워야 send 가능 — *enforceable* 한가? 아니면 그냥 guideline 인가?
4. ARIA imperative — Maestro WKWebView nested span limitation 의 mitigation 명확? 예시 (profile-stars v0.17.2) 가 specific?

### Section B — §modal-overlay-race pattern utility

1. anti-pattern vs correct pattern 코드 예시 — 명확? 두 코드의 차이가 lesson 을 표현?
2. *감지 방법* (hashchange 2회 연속 / Maestro screenshot 가 default tab) — debuggable? 다른 race 와 구별 가능?
3. *적용 대상* 표 — starpin 외 다른 프로젝트에서도 활용 가능? (mobile app shell + modal/overlay 가진 일반 SPA-ish 프로젝트)
4. anti-pattern 의 navigation side-effect 가 React/Vue/SPA framework 의 router 호출에도 동일 적용? 또는 vanilla hash router 한정?

### Section C — Cross-impact

1. v2.3.1 의 §subagent-recovery 와 §deliverable-categories 가 *중복* 부분 없이 complementary?
2. v2.3.1 의 §scope-chunking 의 자가진단 표와 §deliverable-categories 의 5 카테고리 표가 *동일 row* 가 아닌지? (적정 ship size 판정에 5 카테고리 채움 정도가 신호인가?)

### Section D — Doc length / dogma

1. HARNESS.md trim 원칙 위배 없이 추가? §11 row 1줄 + chunking 본문 변경 없음 = OK?
2. PATTERNS.md 가 너무 길어지지 않는지? (§subagent-recovery + §scope-chunking + §deliverable-categories + §modal-overlay-race + §history = 5 큰 섹션)
3. 새 HC 추가 없음 (chunking 처럼 *discipline* 위치) — 합리?

### Section E — Regression sweep

1. starpin v0.17 codebase 의 *기존* modal/overlay code (news-modal, profile-stars, messaging-full, permission-ui) 가 §modal-overlay-race anti-pattern 에 해당? — 만약 yes, v2.3.2 직후 patch 필요?
2. 새 ADR-032 의 dogfood validation 계획 (starpin v0.18 wholesale 에 5-카테고리 template 적용) — 합리적?

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose. Do NOT write `codex_pass: true.` in body — parser rejects.
