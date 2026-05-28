# STATUS

> 단일 진실 출처. 세션 시작 시 read, 종료 시 갱신. (HARNESS.md §8 양식)

## Current

| 항목 | 값 |
|---|---|
| Project | Hara 메타 부트스트랩 (이 레포) + starpin dogfood (`examples/starpin/`) |
| Harness version | **v2.3.2** (pending) — v2.3.1 + PATTERNS §deliverable-categories (subagent 5-카테고리 책임 template) + §modal-overlay-race (DOM cleanup vs nav 분리) + ARIA imperative for Maestro. v2.3.1 의 4-ship dogfood 자체로 발견된 lesson 의 codification. v2.3.2 직후 starpin v0.18 wholesale 으로 dogfood validation. |
| Last ship | (pending) `harness(v2.3.2)` — subagent deliverable template + modal race pattern + ARIA imperative (ADR-032). 직전: `cb59b6d` note(starpin-v0.17.3). |
| Strictness | autonomous (overnight session continues — Hara v2.3.2 r1 PASS 후 ship 대기, starpin v0.18 wholesale 다음 round) |
| Last updated | 2026-05-28 11pm round by Claude (Hara v2.3.2 ship 준비 — codex r1 PASS 2 minor) |

## Active gate

- starpin v0.14 / v0.15 / v0.16 / v0.17 ✓ shipped — UI.md 전체 scope 완료.
- starpin v0.17.1 / v0.17.2 / v0.17.3 ✓ shipped — codex carry close + Hara v2.3.1 dogfood validation (manual canonical patch 0회).
- Hara v2.3.1 ✓ shipped (`c4200ca`) — HC-13 dogfood carry consolidation.
- **Hara v2.3.2 ship 준비 (ADR-032)** — 4-ship dogfood 추가 codification. PATTERNS §deliverable-categories (subagent 5-카테고리 책임 *prompt checklist* — hook 강제 아님) + §modal-overlay-race (DOM cleanup vs nav 분리) + ARIA imperative for Maestro. codex r1 PASS (0 blocker / 0 major / 2 minor — minor patch 적용 후 ship).
- **starpin v0.18 wholesale 준비 (intake-content-enrichment.md)** — image proxy (local SVG cosmos illustrations) + messaging full real POST + Maestro flow 확장. v2.3.2 의 5-카테고리 deliverables template 첫 dogfood.
  - functional smoke pass + 6 screenshots + Claude/Codex visual review = canonical `ui_review` evidence
  - r1: 1 blocker (telescope blank CSP frame-ancestors) + 2 major (news image broken) → patched
  - r2: codex disputed Claude r2 close on V-VR-03 (news-modal symmetric pattern broken) → reopened major → r3 patched (news-modal.ts now mirrors newsletter.ts)
  - r3: claude_pass=true + codex_pass=true. 1 minor (hero glyph 비중) carry to v0.16
- **Autonomous multi-ship 진행 중**: v0.16 sensor (gyro/GPS/compass) → v0.17 filter/zoom/lock/highlight → v0.18 자세히보기 + claim flow → v0.19 profile + messaging full
- Hara v2.3.1 carry 누적:
  - codex narrative-only output robustness (v0.14 + v0.15 둘 다 manual canonical front-matter patch 발생)
  - `ui-codex-<slug>.md` round suffix 누락 (r1 = r2 = r3 overwrite — round-tracking 단절)
  - symmetric-component pair 대칭성 검사 (codex r2 가 잡았지만 자동화 가능)
  - Phase 02 blueprint 의 CSP/cross-platform constraint 자동 checklist
- Open findings: 0 blocker. INBOX: 0 unread.

## Required reads (세션 시작 시)

1. [HARNESS.md](HARNESS.md) — 헌법 (must-read)
2. [STATUS.md](STATUS.md) — 본 파일
3. [DECISIONS.md](DECISIONS.md) — 최근 ADR (현재 ADR-023)
4. `ls INBOX/` — codex 피드백 unread
5. [CLAUDE.md](CLAUDE.md) / [AGENTS.md](AGENTS.md) — agent별 진입점

참조용 (필요할 때만): [PATTERNS.md](PATTERNS.md), [FLEET.md](FLEET.md)

**Hook 설치** (clone 1회): `git config core.hooksPath .githooks` — HC-6/HC-11/HC-12 자동 enforce.

## Recent ships

| commit | scope | 내용 |
|---|---|---|
| (pending) | harness(v2.3.2) | subagent 5-카테고리 deliverable template + modal-overlay-race 패턴 + ARIA imperative (ADR-032). v2.3.1 dogfood lesson 추가 codification |
| cb59b6d | note(starpin-v0.17.3) | V-CX-TEL-01 FULL close — detail-page race fix (_removeOverlayDom split) + missing CSS + friendly-name title (V-CX-TEL-02 in detail-page surface). 12 PNG |
| 78e7b52 | note(starpin-v0.17.2) | profile-stars aria-label a11y win (Maestro WKWebView nested span 한계 우회) + V-CX-TEL-01 partial close + Hara v2.3.1 round-suffix r2 dogfood |
| ba4360e | note(starpin-v0.17.1) | v0.17.0 codex carry close (V-CX-TEL-03/05) + Hara v2.3.1 첫 dogfood validation PASS (ADR-031). 0 manual canonical patch |
| c4200ca | harness(v2.3.1) | HC-13 dogfood carry 정리 (ADR-030) — parser robustness + round suffix + skill v0.3 + PATTERNS §subagent-recovery + §scope-chunking + chunking 헌법 |
| af9118f | note(starpin-v0.17.0) | wholesale ship (ADR-029) — UI.md 잔여 통합 (filter + variable visual + highlight + lag-camera + zoom-lock + 자세히보기 + claim + profile-stars + messaging-full). chunking memory 적용 |
| a5a4afe | note(starpin-v0.16.0) | sensor scaffold (ADR-028) — fake mode + permission UI + iframe postMessage + landscape CSS. Subagent 529 → coordinator direct-impl |
| 7402140 | note(starpin-v0.15.0) | UI shell rework + HC-13 두 번째 dogfood, 3-round adaptive (ADR-027) |
| f44ddbd | note(starpin-v0.14.0) | mobile UI 개선 + HC-13 첫 dogfood (ADR-026) |
| f79b643 | harness(v2.3.0) | HC-13 Visual-Review (ADR-025) — base skill + runner + dual-lane hook |
| 1751c28 | note(starpin-v0.13.0) | Capacitor iOS wrap (ADR-024) |
| bde2b47 | harness(v2.2.0) | HC-12 mobile equivalent extension (ADR-023) |
| ee5cd0d | harness(v2.1.0) | enforcement gap pass (ADR-022) |
| 4e0c71d | note(starpin-v0.12.0) | planet interactivity (ADR-021) |
| 3bf567c | harness(v2.0.0) | trim discipline (ADR-020) |
| 9f23d2a | note(starpin-v0.11.0) | nickname-setup + planet overlay (ADR-019) |
| 74391d5 | harness(v1.9.0) + starpin v0.10 | HC-12 신설 + login flow fix (ADR-017/018) |
| (older) | — | git log; ADR-001~ADR-016은 DECISIONS.md |

## Open findings

(none — v0.11 codex r1+r2 모두 closed)

## Notes (사용자 지시 — 보존)

- **2026-05-27**: "하니스 만들 때마다 느꼈던 '하니스 안지켜짐 → 규칙 추가 → 길어져서 안 읽힘' 무의미한 반복 없도록 필요없는 부분 계속 쳐내며 가장 중요하고 잘 지켜질 내용 중심으로. 세션 개성 일부 허용, 전체 흐름만 지키면 OK."
- **(prior)**: "obsolete 적극 제거, 단순 append 금지."
