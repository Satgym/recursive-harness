# STATUS

> 단일 진실 출처. 세션 시작 시 read, 종료 시 갱신. (HARNESS.md §8 양식)

## Current

| 항목 | 값 |
|---|---|
| Project | Hara 메타 부트스트랩 (이 레포) + starpin dogfood (`examples/starpin/`) |
| Harness version | **v1.9** (HC-12 신설) — v2.0 trim pass 진행 중 |
| Last ship | (pending) note(starpin-v0.12.0) — planet interactivity (click + a11y list). codex r1+r2 both ship/0 findings. Earlier: `3bf567c` harness(v2.0.0). |
| Strictness | autonomous (사용자 sleep delegation) |
| Last updated | 2026-05-27 by Claude |

## Active gate

- starpin v0.12 ship 직전 — codex r1 (ship/0 findings) + r2 (ship/0 findings) closed. HC-12 smoke green.
- Open findings: 0. INBOX: 0 unread.

## Required reads (세션 시작 시)

1. [HARNESS.md](HARNESS.md) — 헌법 (must-read)
2. [STATUS.md](STATUS.md) — 본 파일
3. [DECISIONS.md](DECISIONS.md) — 최근 ADR (현재 ADR-020)
4. `ls INBOX/` — codex 피드백 unread
5. [CLAUDE.md](CLAUDE.md) / [AGENTS.md](AGENTS.md) — agent별 진입점

참조용 (필요할 때만): [PATTERNS.md](PATTERNS.md), [FLEET.md](FLEET.md)

**Hook 설치** (clone 1회): `git config core.hooksPath .githooks` — HC-6/HC-11/HC-12 자동 enforce.

## Recent ships

| commit | scope | 내용 |
|---|---|---|
| 9f23d2a | note(starpin-v0.11.0) | nickname-setup + planet overlay (codex r2 minor-followup) |
| 74391d5 | harness(v1.9.0) + starpin v0.10 | HC-12 신설 + Mock OAuth/route 누락 fix |
| d529e3f | note(starpin-v0.9.0) | HD namespace + sky planet API |
| (older) | — | git log; ADR-001~ADR-018은 DECISIONS.md |

## Open findings

(none — v0.11 codex r1+r2 모두 closed)

## Notes (사용자 지시 — 보존)

- **2026-05-27**: "하니스 만들 때마다 느꼈던 '하니스 안지켜짐 → 규칙 추가 → 길어져서 안 읽힘' 무의미한 반복 없도록 필요없는 부분 계속 쳐내며 가장 중요하고 잘 지켜질 내용 중심으로. 세션 개성 일부 허용, 전체 흐름만 지키면 OK."
- **(prior)**: "obsolete 적극 제거, 단순 append 금지."
