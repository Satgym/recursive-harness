# phases/ — 페이즈 정식 정의

> [HARNESS.md §3](../HARNESS.md)의 7단계 워크플로우 각 phase의 *Entry 입력 / Activities / Outputs / Exit 기준*을 상세 명세.
>
> **A.4 완료 시점에서 [HARNESS.md §9](../HARNESS.md) Bootstrap exception이 자동 폐기**된다 (ADR-007로 명문화). 이후 모든 phase 진행은 본 디렉토리의 Exit 기준을 따른다.

## 7 phases

```
[00 Intake] ─▶ [01 Blueprint] ─▶ [02 ModulePlan] ─▶ [03 Implement] ─▶ [04 CrossReview] ─▶ [05 Integration] ─▶ [06 Handoff]
                                       ▲                                                                              │
                                       └──────── 다음 모듈마다 02~05 반복 ──────────────────────────────────────────┘
```

| Phase | 파일 | 주도 역할 | 사용자 승인이 필수인 모드 |
|---|---|---|---|
| 00 Intake | [00-intake.md](00-intake.md) | claude-implementer | strict, balanced |
| 01 Blueprint | [01-blueprint.md](01-blueprint.md) | claude-implementer + codex-reviewer | **모든 모드** |
| 02 ModulePlan | [02-module-plan.md](02-module-plan.md) | claude-implementer + codex-reviewer | strict |
| 03 Implement | [03-implement.md](03-implement.md) | claude-implementer | — |
| 04 CrossReview | [04-cross-review.md](04-cross-review.md) | codex-reviewer + claude-implementer | (disputed blocker/major 시) |
| 05 Integration | [05-integration.md](05-integration.md) | claude-implementer | — |
| 06 Handoff | [06-handoff.md](06-handoff.md) | claude-implementer | — |

## 공통 규칙

- 각 phase의 Exit 기준이 만족되지 않으면 다음 phase 진입 금지 (HC-4).
- HC-7/8/9 위반 작업은 어느 phase에서도 사용자 승인 필요 (모드 무관).
- disputed `severity ∈ {blocker, major}`는 phase 차단 ([HARNESS.md §11](../HARNESS.md)).
- 모든 phase 종료 시 STATUS.md 갱신 (HC-6).
- Postmortem 트리거가 발생하면 그 phase는 일시 정지 + `postmortems/<date>-<slug>.md` 작성 → `status: resolved` 후 재개.

## 모드별 승인 매트릭스 요약

| Phase | strict | balanced | autonomous |
|---|:---:|:---:|:---:|
| 00 Intake | user | user | — |
| 01 Blueprint | **user** | **user** | **user** |
| 02 ModulePlan | user + codex | codex만 | — |
| 03 Implement | — | — | — |
| 04 CrossReview (disputed blocker/major 시) | user | user | user |
| 05 Integration | — | — | — |
| 06 Handoff | — | — | — |

Blueprint(01)와 하니스 자체 변경은 모든 모드에서 항상 user 승인 (ADR-004 v0.2).
