# INVARIANT (HC-10 + HARNESS §13.5):
#   `status: approved` 또는 capability manifest *Active* 등재는 `approval.approver == "user"` 인 경우에만 유효.
#   다른 approver enum은 evidence (codex-review의 HC-10 delta safety check 등) 제공만 가능.
---
artifact: local_role
version: v0.1
date: <YYYY-MM-DD>
author: claude
status: draft   # draft | approved | superseded | rejected
approval:
  approver: <pending — must be 'user' for status:approved or manifest Active entry>
  approved_at: <pending>
  mode: <strict | balanced | autonomous>
  scope: <어느 phase / 어느 도메인>
authority: advisory   # 항상 advisory — execution authority는 base 4 roles만 (claude-implementer, codex-reviewer, claude-reviewer, codex-implementer)
extends: <base role 파일 경로 또는 'none'>
may_not_override: HC-1~10, base role permission matrix, approver enum, phase Exit criteria
hc_review:
  hc7_secrets: <이 role이 다루는 domain-specific secrets?>
  hc8_external: <이 role이 외부 mutation에 관여?>
  hc9_destructive: <이 role이 destructive 작업에 관여?>
activation:
  trigger: <언제 이 role의 advisory가 발동 — 특정 phase / 특정 finding 종류 / 사용자 명시 요청>
references:
  - related_base_roles: [<base role IDs>]
---

# Local Role (advisory): `<name>`

> Project-local advisory role. HC-10 적용: base 4 roles의 execution authority는 *그대로* — 이 role은 검토·자문·체크리스트 제공만.

## Purpose

이 role의 *전문 영역*과 어떤 도메인 결정에 자문 제공하는가.

예: `firmware-safety-reviewer` = HIL 안전 / 메모리·플래시 예산 / 인터럽트 우선순위 / 전원 fail-safe.

## When to invoke

- 어떤 산출물에 대한 자문이 필요할 때
- 어떤 finding 종류가 발생할 때
- 어떤 phase Exit 점검에 추가 항목으로 들어갈 때

## Advisory output format

본 role이 *자문*을 제공할 때의 출력 양식:
- 텍스트 (Free-form 권고) 또는
- REVIEW 형식의 추가 finding (base codex-reviewer / claude-reviewer가 *최종 출력*; local role은 *입력*에 추가)
- 또는 새 체크리스트 (산출물의 §승인 체크 안에 추가 항목)

> **출력 권한**: 본 role은 *최종 REVIEW 산출물을 *직접 발행하지 않음* — base reviewer에게 input으로 제공.

## Scope of authority (advisory)

| 항목 | 허용 |
|---|---|
| 산출물에 직접 코드 작성 | ✗ (base roles만) |
| Final REVIEW 산출 | ✗ (codex-reviewer / claude-reviewer가) |
| 산출물의 *체크리스트 항목 추가* | ✓ (PR 또는 ADR로 명시) |
| Phase 의사결정 자문 | ✓ |
| Phase Exit 점검 *추가 항목* | ✓ (제거는 금지) |
| HC-7/8/9 사례 식별 | ✓ |

## Failure modes

- 본 role이 base의 execution authority를 *주장*하는 경우 → HC-10 위반 → drift 신호
- advisory 출력이 산출물에 *직접 commit*되는 경우 → 절차 위반

## HC-10 self-check

- 본 role은 어떤 base role도 *대체*하지 않음 (구체적)
- 산출물 권한이 base 4 roles에 그대로 남아 있음을 명시
- approver enum 확장 없음 (이 role은 *작성자*나 *advisory contributor*일 뿐, *approver* 아님)

## Related

- base roles: [path...]
- 관련 local skills: [path...]
