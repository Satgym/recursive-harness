# skills/ — 작업 절차 (Procedural docs)

각 skill은 *언제 / 무엇을 / 어떻게* 수행하는지 단계별 절차를 명세한다. 모두 [HARNESS.md](../HARNESS.md), [phases/](../phases/), [scripts/](../scripts/), [templates/](../templates/) 위에서 동작.

## 9 skills

| Skill | 발동 시점 | Phase 매핑 |
|---|---|---|
| [kickoff-project.md](kickoff-project.md) | 새 프로젝트 시작 | 00 Intake |
| [plan-blueprint.md](plan-blueprint.md) | Intake 완료 후 | 01 Blueprint |
| [plan-module.md](plan-module.md) | Blueprint 후 모듈마다 | 02 ModulePlan |
| [request-codex-review.md](request-codex-review.md) | cross-review / 텍스트 검토 필요 시 | 01 / 02 / 04 |
| [apply-review.md](apply-review.md) | codex review 결과 수령 후 | 04 CrossReview |
| [checkpoint-handoff.md](checkpoint-handoff.md) | 세션 / 모듈 / phase 종료 | 06 Handoff |
| [resume-session.md](resume-session.md) | 새 세션 시작 | (모든 phase) |
| [drift-check.md](drift-check.md) | phase 경계 / 의심 신호 | (모든 phase) HC-3 |
| [harness-amend.md](harness-amend.md) | 드리프트 / 결함으로 하니스 수정 필요 | meta — HARNESS §6 |

## 사용 패턴

Skill은 *호출* 개념: claude-implementer가 "이 skill을 수행한다"는 명시적 선언과 함께 절차를 따른다. STATUS *Next action*에 어떤 skill이 다음에 적용되는지 명시 가능.

```
Next action:
- Claude: invoke skill resume-session, then plan-module (M3: auth)
```

Claude Code의 user-invocable skill 시스템과 통합하려면 향후 각 skill 파일을 그 양식(frontmatter `name`, `description`)으로 변환 + `~/.claude/skills/`에 심볼릭 링크. 본 phase에선 *procedural docs*만 제공 — 통합은 Phase C 또는 Phase D에서 고려.

## 작성 컨벤션

각 skill 파일은 6 섹션:
1. **Purpose** — 한 단락
2. **When to invoke** — 발동 조건
3. **Inputs** — 무엇이 필요한가
4. **Procedure** — 단계별 (번호 매김)
5. **Outputs / Side effects** — 무엇이 만들어지는가
6. **Failure modes** — 어떻게 실패하나, 회복 절차
