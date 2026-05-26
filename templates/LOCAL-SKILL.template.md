# INVARIANT (HC-10 + HARNESS §13.5):
#   `status: approved` 또는 capability manifest *Active* 등재는 `approval.approver == "user"` 인 경우에만 유효.
#   `codex-review` / `claude-reviewer` / `claude-self-test`는 *evidence*만 제공 — user 승인을 대체할 수 없다.
#   review-local-layer는 non-user approval로 Active 진입 시도를 강제 blocker로 표시.
---
artifact: local_skill
version: v0.1
date: <YYYY-MM-DD>
author: claude   # or codex / user
status: draft   # draft | approved | superseded | rejected
approval:
  approver: <pending — must be 'user' for status:approved or manifest Active entry>
  approved_at: <pending>
  mode: <strict | balanced | autonomous>
  scope: <어느 phase / 어느 모듈 / 어느 도메인에 활성>
extends: <base skill 파일 경로 또는 'none'>
may_not_override: HC-1, HC-2, HC-3, HC-4, HC-5, HC-6, HC-7, HC-8, HC-9, HC-10, base phase Exit criteria, base role permission matrix
hc_review:
  hc7_secrets: <어떻게 domain secrets를 redact? — N/A if not applicable>
  hc8_external: <어떤 외부 mutation이 새로 등장? 사용자 승인 어떻게? — N/A if not applicable>
  hc9_destructive: <어떤 destructive 작업이 새로 등장? irreversible checklist? — N/A if not applicable>
activation:
  phase: <00-intake | 01-blueprint | 02-module-plan | 03-implement | 04-cross-review | 05-integration | 06-handoff | any>
  trigger: <when this skill should be invoked — 명시적 호출 / 특정 산출물 작성 시 / 특정 finding 종류>
references:
  - related_base_skills: [<base skill IDs>]
  - related_local_capabilities: [<other local capability IDs>]
---

# Local Skill: `<name>`

> Project-local extension. HC-10 적용: base를 약화하지 않고 *추가*만.

## Purpose

한 단락 — 이 skill이 이 *프로젝트*에서 왜 필요한가. 어떤 도메인 gap을 메우는가.

## When to invoke

- 발동 조건 (구체적)
- base skill만으로 부족한 *어떤 순간*

## Inputs

- 무엇을 읽고 / 받는가
- 도메인 자료 / 사용자 의견 / 다른 산출물

## Procedure

번호 매김 단계.

## Outputs / Side effects

- 새 산출물
- 갱신되는 기존 산출물 (capability manifest 등)
- 기록되어야 하는 산출물

## Failure modes

- 어떻게 실패하나
- 회복 절차
- 어느 base skill로 fallback 가능한가

## HC-10 self-check

본 skill이 어떻게 *extension-only*인지 명시:
- HC-1~9 어디도 약화하지 않음 (구체적으로)
- base phase Exit 기준의 *제거* 없음 (추가만)
- execution authority는 base roles에 남음 (이 skill은 advisory)

## Related

- base skills: [path...]
- local capabilities: [path...]
