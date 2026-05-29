# STATUS

> 단일 진실 출처. 세션 시작 시 read, 종료 시 갱신. (HARNESS.md §8 양식)

## Current

| 항목 | 값 |
|---|---|
| Project | Hara 메타 부트스트랩 (이 레포) + starpin dogfood (`examples/starpin/`) |
| Harness version | **v2.5** SHIPPED (`9f4ce21`) — PATTERNS dom-mutation + smoke-setup + SMOKE_FRESH_SIM. v0.21 dogfood 가 두 패턴 모두 자율 준수 검증. |
| Last ship | `7b8f048` note(starpin-v0.21.0) — friend highlight backend wire + Gaia 646 search corpus + telescope-iframe sky-canvas-reset unmount cleanup (ADR-040). Hara v2.5 두 번째 dogfood VALIDATED. |
| Strictness | autonomous (overnight session 종료 — 7am target 통과; Hara v2.3.1→v2.5 + starpin v0.17.1→v0.21 모두 ship 완료) |
| Last updated | 2026-05-29 08:41 by Claude — overnight 자율 세션 완료 (Hara 6 ship + starpin 7 ship). 다음 액션 user 결정. |

## Active gate

- **자율 세션 종료** — 7am target 통과 (08:41 종료 시점). 다음 ship 결정은 user 깨어난 후.
- Open findings: 0 blocker / 0 major. INBOX: 0 unread.
- Hara cumulative carry: v2.6 후보 — (1) `check-subagent-prompt.sh §dom-mutation-order grep`, (2) Maestro system overlay (Siri 받아쓰기) auto-dismiss handler, (3) pre-Agent hook automation.
- Starpin v0.22 후보 — (1) telescope-iframe FAB navigation back-button 안정화, (2) search-jump result-row tap Maestro consistency.

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
| 7b8f048 | note(starpin-v0.21.0) | friend highlight backend wire + Gaia 646 search corpus + telescope-iframe sky-canvas-reset cleanup (ADR-040). Hara v2.5 두 번째 dogfood (DOM/ARIA 자율 준수). 384 jest pass / 0 regression |
| 9f4ce21 | harness(v2.5) | PATTERNS §dom-mutation-order + §smoke-setup + SMOKE_FRESH_SIM env (ADR-039) — v0.20 2 lesson codify |
| 2ba7b8f | note(starpin-v0.20.0) | today widget (월령 + 일몰 + 행성) + 천체 검색 (Connect 축 보강, ADR-038). astronomy-engine VSOP87. Hara v2.4.2 첫 dogfood |
| 5b8d00b | harness(v2.4.2) | ARIA grep + race retry (ADR-037) — v0.17.2 + v0.19 aria-label 누락 반복 prevent |
| 8517c7a | note(starpin-v0.19.0) | friends + sky tag share Connect 축 실구현 (ADR-036). Hara v2.4 5-카테고리 두 번째 dogfood VALIDATED |
| 1f9eb22 | harness(v2.4.1) | check-subagent-prompt.sh `--mode=auto|impl|review` (ADR-035) |
| e4ba304 | harness(v2.4) | scripts/check-subagent-prompt.sh 5-카테고리 enforceable lint (ADR-034). v2.3.2 의 self-checklist → enforced gate |
| dc97fb7 | note(starpin-v0.18.0) | content enrichment — 6 cosmos SVG + messaging real POST + I-UI-19 (ADR-033). Hara v2.3.2 첫 dogfood VALIDATED 5/5 delivered |
| c2a1726 | harness(v2.3.2) | subagent 5-카테고리 deliverable template + modal-overlay-race 패턴 + ARIA imperative (ADR-032). v2.3.1 dogfood lesson 추가 codification |
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
