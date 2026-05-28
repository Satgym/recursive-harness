# STATUS

> 단일 진실 출처. 세션 시작 시 read, 종료 시 갱신. (HARNESS.md §8 양식)

## Current

| 항목 | 값 |
|---|---|
| Project | Hara 메타 부트스트랩 (이 레포) + starpin dogfood (`examples/starpin/`) |
| Harness version | **v2.4.2** (pending) — ARIA imperative grep (`--strict` 시 "aria-label" 단어 의무) + ui-visual-review.sh race retry (6×1s probe, 5s window 정확 cover). v0.17.2 + v0.19 의 aria-label 누락 패턴 반복 prevent. |
| Last ship | (pending) `harness(v2.4.2)` — ARIA grep + race retry (ADR-037). 직전: `8517c7a` note(starpin-v0.19.0). |
| Strictness | autonomous (overnight session 누적 — Hara v2.3.2 + starpin v0.18 모두 ship 완료) |
| Last updated | 2026-05-28 11pm + late round by Claude (Hara v2.3.2 + starpin v0.18 모두 SHIPPED — 5-카테고리 template 첫 production dogfood 성공) |

## Active gate

- **Hara v2.4 r2 verify 단계** — `scripts/check-subagent-prompt.sh` lint enforcement. r1 PASS (3 minor patched). r2 PASS (2 minor patched in r3 patch). ship 임박.
- Open findings: 0 blocker / 0 major. INBOX: 0 unread.
- Hara cumulative carry (v2.4.1+ pre-Agent hook automation, v2.5+ design system 일치 검증).

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
| (pending) | harness(v2.4.2) | ARIA grep + race retry (ADR-037) — v0.17.2 + v0.19 aria-label 누락 반복 prevent |
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
