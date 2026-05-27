# STATUS

> 단일 진실 출처. 세션 시작 시 read, 종료 시 갱신. (HARNESS.md §8 양식)

## Current

| 항목 | 값 |
|---|---|
| Project | Hara 메타 부트스트랩 (이 레포) + starpin dogfood (`examples/starpin/`) |
| Harness version | **v2.0** (trim discipline) |
| Last ship | `4e0c71d` note(starpin-v0.12.0) — planet interactivity. 야간 작업 5 ship 완료 (Hara v1.9/v2.0 + starpin v0.10/v0.11/v0.12). |
| Strictness | autonomous (사용자 sleep delegation; 마무리 상태) |
| Last updated | 2026-05-27 by Claude (sleep-delegation session 완료) |

## Active gate

- (none) — 야간 자율 작업 모두 ship 완료. 사용자 wake-up 핸드오프 대기.
- Open findings: 0. INBOX: 0 unread.
- HC-12 evidence: `examples/starpin/.harness/runs/e2e-20260527-login-smoke.json` (pass, 모든 ship 직전 갱신).

## Required reads (세션 시작 시)

1. [HARNESS.md](HARNESS.md) — 헌법 (must-read)
2. [STATUS.md](STATUS.md) — 본 파일
3. [DECISIONS.md](DECISIONS.md) — 최근 ADR (현재 ADR-020)
4. `ls INBOX/` — codex 피드백 unread
5. [CLAUDE.md](CLAUDE.md) / [AGENTS.md](AGENTS.md) — agent별 진입점

참조용 (필요할 때만): [PATTERNS.md](PATTERNS.md), [FLEET.md](FLEET.md)

**Hook 설치** (clone 1회): `git config core.hooksPath .githooks` — HC-6/HC-11/HC-12 자동 enforce.

## Recent ships (이번 sleep-delegation session)

| commit | scope | 내용 |
|---|---|---|
| 4e0c71d | note(starpin-v0.12.0) | planet interactivity — click + a11y list buttons (ADR-021, codex r1+r2 ship/0) |
| 3bf567c | harness(v2.0.0) | trim discipline — STATUS −73% / HARNESS HC-12 row + version history 압축 (ADR-020) |
| 9f23d2a | note(starpin-v0.11.0) | nickname-setup + planet overlay (ADR-019, codex r2 minor-followup) |
| 74391d5 | harness(v1.9.0) + starpin v0.10 | HC-12 신설 + Mock OAuth/route 누락 fix (ADR-017/018) |
| (older) | — | git log; ADR-001~ADR-016은 DECISIONS.md |

## Open findings

(none — v0.11 codex r1+r2 모두 closed)

## Notes (사용자 지시 — 보존)

- **2026-05-27**: "하니스 만들 때마다 느꼈던 '하니스 안지켜짐 → 규칙 추가 → 길어져서 안 읽힘' 무의미한 반복 없도록 필요없는 부분 계속 쳐내며 가장 중요하고 잘 지켜질 내용 중심으로. 세션 개성 일부 허용, 전체 흐름만 지키면 OK."
- **(prior)**: "obsolete 적극 제거, 단순 append 금지."
