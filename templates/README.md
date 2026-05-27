# templates/ — 산출물 양식

이 디렉토리는 하니스의 모든 정형 산출물 타입에 대한 표준 양식을 보유한다.
[HARNESS.md §4.3](../HARNESS.md) artifact-specific status enum이 여기에서 정식 확정된다.

## 9개 양식 (v0.6 — 6 base + 3 adaptive)

| 양식 | 인스턴스 위치 | status enum | 누가 작성 |
|---|---|---|---|
| [BLUEPRINT.template.md](BLUEPRINT.template.md) | `.harness/docs/blueprint.md` | `draft \| approved \| superseded \| rejected` | claude-implementer |
| [MODULE-PLAN.template.md](MODULE-PLAN.template.md) | `.harness/docs/modules/<name>/plan.md` | `draft \| approved \| superseded \| rejected` | claude-implementer |
| [REVIEW.template.md](REVIEW.template.md) | `.harness/reviews/<phase>-<date>-<slug>.md` 또는 `INBOX/codex-feedback-<date>-<slug>.md` | `open \| resolved \| deferred \| disputed` | codex-reviewer / claude-reviewer |
| [ADR.template.md](ADR.template.md) | `DECISIONS.md` 항목 또는 `.harness/decisions/ADR-NNNN-<slug>.md` | `proposed \| accepted \| superseded \| rejected` | claude-implementer (작성), user (승인) |
| [POSTMORTEM.template.md](POSTMORTEM.template.md) | `postmortems/<date>-<slug>.md` 또는 `.harness/postmortems/...` | `open \| resolved` | claude-implementer |
| [STATUS.template.md](STATUS.template.md) | 프로젝트 루트 `STATUS.md` 또는 `.harness/status.md` | (front-matter 불필요) | claude-implementer |
| [LOCAL-SKILL.template.md](LOCAL-SKILL.template.md) ⭐ | `.harness/skills/<id>.md` | `draft \| approved \| superseded \| rejected` | claude-implementer (synthesize-local-layer) + user 승인 |
| [LOCAL-ROLE.template.md](../project-types/_incubating/LOCAL-ROLE.template.md) ⭐ | `.harness/roles/<id>.md` (authority: advisory만) | `draft \| approved \| superseded \| rejected` | claude-implementer + user 승인 — **v1.6 relocated to _incubating** (활성 사용 시 base 복귀 검토) |
| [CAPABILITY-MANIFEST.template.md](CAPABILITY-MANIFEST.template.md) ⭐ | `.harness/capabilities.md` (프로젝트당 1개) | `draft \| approved \| superseded` | claude-implementer; user가 *Active* 등재 승인 |

## 사용 규칙

1. **인스턴스화**: `cp templates/<X>.template.md <대상경로>` 후 front-matter와 본문을 채운다. `<...>` 자리표시자는 모두 실제 값으로 교체.
2. **버전**: 인스턴스는 `version: v0.1`로 시작, 이후 수정 시 increment.
3. **승인**: front-matter `status: approved` + `approval` 블록은 사용자/codex-review/claude-self-test 중 누가 승인했는지 명시 (HARNESS §7 Approval record format).
4. **superseding**: 새 버전으로 갈 때 이전 인스턴스의 `status: superseded` + 새 버전의 `supersedes: <old version 또는 hash>` 기록.
5. **enum 위반**: status 값이 위 표에 없는 형태(예: `deferred(이유)` 합성)는 금지. canonical 영어 enum + 보조 필드(`deferred_reason` 등)로 분리.

## 양식 변경 정책

- 양식 자체의 변경은 하니스 자체 변경으로 간주 (HARNESS §6 절차 + 사용자 승인).
- 양식이 바뀌면 기존 인스턴스는 자동 마이그레이션 불가 — 새 인스턴스부터 적용. 필요 시 마이그레이션 ADR.
