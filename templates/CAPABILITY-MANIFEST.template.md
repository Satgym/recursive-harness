---
artifact: capability_manifest
version: v0.1
project_name: <name>
project_type_seed: <web-service | _generic | ...>
date: <YYYY-MM-DD>
author: claude
status: draft   # draft | approved | superseded
approval:
  approver: <pending>
  approved_at: <pending>
  mode: <strict | balanced | autonomous>
  scope: 전체 manifest (개별 capability별로도 approved_at 명시)
references:
  - intake: .harness/docs/intake.md
  - capability_synthesis_review: .harness/reviews/00.5-capability-*.md
---

# `<project name>` — Capability Manifest

> HARNESS.md §13.3 — 세션 시작 시 base files 이후 본 manifest를 읽는다. 여기 *명시*된 항목만 working set에 포함된다. 자동 discovery 금지.

## Base references (read-only — base는 그대로 작동)

- HARNESS.md (pinned version per .harness/VERSION-PIN)
- phases/ (base — 7 phase docs)
- roles/ (base — 4 roles)
- templates/ (base — 6 templates)
- scripts/ (base — wrappers + helpers)
- skills/ (base — 9 + 새 base skills synthesize-local-layer, review-local-layer)

## Active local capabilities

> **INVARIANT (HC-10 + HARNESS §13.5)**: *Active* entries below require `approver: user`. Non-user approvers (codex-review / claude-reviewer / claude-self-test) are *evidence only* — never sufficient for Active activation.

### Skills

```yaml
# 예시 (실 프로젝트에서 채움; INVARIANT: approver must be 'user' for Active entry):
# - id: spec-first-blueprint
#   path: .harness/skills/spec-first-blueprint.md
#   scope: "phase 01 Blueprint, web-service projects with OpenAPI"
#   extends: skills/plan-blueprint.md
#   approved_at: 2026-05-25T18:30
#   approver: user      # required for Active
#   evidence_review: .harness/reviews/00.5-capability-<round>.md
```

(아직 승인된 local skill 없음 — Local Capability Synthesis 통과 + user 승인 후 추가)

### Roles (advisory)

```yaml
# 예시 (INVARIANT: approver must be 'user' for Active entry):
# - id: firmware-safety-reviewer
#   path: .harness/roles/firmware-safety-reviewer.md
#   scope: "phase 01 Blueprint risks, phase 04 cross-review HC-9 check"
#   authority: advisory
#   approved_at: 2026-05-25T18:30
#   approver: user      # required for Active
#   evidence_review: .harness/reviews/00.5-capability-<round>.md
```

(아직 승인된 local role 없음)

## Draft / pending (review or approval 대기 — working set 포함 X)

```yaml
# capability synthesis 중 작성됐지만 아직 codex review + 사용자 승인 안 받은 항목.
```

## Superseded (archive — 참고용)

```yaml
# 이전 버전의 capability — 새 버전으로 대체된 경우 supersedes 명시.
```

## Promotion candidates (local → base)

- (HARNESS §13.6 기준 충족 시 base 승격 후보로 등재. v0.6에선 manual 추적)

## Notes

- 본 manifest는 *프로젝트별 SoT* of active local capabilities.
- session start 의무: 본 파일 읽고 *Active* 목록의 모든 path를 working set에 포함 (CLAUDE.md / AGENTS.md / skills/resume-session.md 갱신 예정).
- 새 capability 추가: skills/synthesize-local-layer.md 절차 → skills/review-local-layer.md (Codex review) → 사용자 승인 → 본 manifest의 *Active*로 이동.
