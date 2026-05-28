# STATUS

> 단일 진실 출처. 세션 시작 시 read, 종료 시 갱신. (HARNESS.md §8 양식)

## Current

| 항목 | 값 |
|---|---|
| Project | Hara 메타 부트스트랩 (이 레포) + starpin dogfood (`examples/starpin/`) |
| Harness version | **v2.3** (HC-13 Visual-Review; ADR-025) — Claude(multimodal) + Codex visual independent review + base skill ui-visual-review |
| Last ship | (pending) `harness(v2.3.0)` — visual review infrastructure. 직전: `1751c28` note(starpin-v0.13.0). |
| Strictness | autonomous (UI verification + UI improvement phase) |
| Last updated | 2026-05-28 by Claude (Hara v2.3 design + starpin v0.14 paired plan) |

## Active gate

- starpin v0.13 ✓ shipped (`1751c28` Capacitor iOS wrap).
- **Hara v2.3 base ship 진행 중** — HC-13 Visual-Review + ui-visual-review base skill + hook 확장.
- **starpin v0.14 paired**: v2.3 dogfood — mobile UI 개선 (mobile-first layout, tap target ≥44pt, 사용자 친화 star info) + visual review 첫 발동.
- Open findings: 0. INBOX: 0 unread.

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
| (pending) | harness(v2.3.0) | HC-13 Visual-Review (ADR-025) — starpin v0.14 prerequisite |
| 1751c28 | note(starpin-v0.13.0) | Capacitor iOS wrap (ADR-024) — iPhone simulator first-flow PASS |
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
