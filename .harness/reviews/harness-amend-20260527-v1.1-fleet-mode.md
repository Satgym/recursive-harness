---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: <see body>
target: <see body>
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e6710-cced-7412-8b3e-94e5abee6c93
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 84462
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T01:33
  prompt_source: .harness/prompts/v1.1-fleet-mode-bundle.md
---

# Hara v1.1 Fleet Mode Review

## Summary

v1.1 방향 자체는 HC-7/8/9를 약화하지 않습니다. child prompt에도 secret/external/destructive gate 재확인이 있고, F4의 “읽기는 허용, 쓰기만 ownership 제한”도 맞습니다. 다만 Fleet가 실제 운영 규칙으로 ship되기엔 gate와 evidence 쪽에 막히는 지점이 있습니다.

## Findings

### Finding F71: fleet-mini dogfood가 Module Plan gate를 통과하지 않은 상태로 ship evidence를 주장함
- **severity**: blocker
- **위치**: `examples/fleet-mini/.harness/status.md:20`, `examples/fleet-mini/RELEASE.md:27`, `examples/fleet-mini/.harness/docs/blueprint.md:80`
- **근거**: STATUS/RELEASE는 “3 module plans” 완료를 주장하지만 `.harness/docs/`에는 `blueprint.md`만 있고 module plan 파일이 없습니다. Blueprint DoD도 “3 module plans approved”가 미체크입니다. 이는 HC-1/HC-4 evidence 위반입니다.
- **제안**: `add/mul/stat` module plan 3개를 실제 작성·승인하거나, fleet-mini를 “정식 Hara dogfood”가 아닌 “mechanical simulation”으로 강등하고 v1.1 ship evidence에서 HC gate 충족 주장 제거.

### Finding F72: F2 cross-cutting invariant 의무가 Phase 01 gate/template에 없음
- **severity**: major
- **위치**: `HARNESS.md:442`, `phases/01-blueprint.md:31`, `templates/BLUEPRINT.template.md:100`
- **근거**: HARNESS F2는 “parent Phase 01 Blueprint Exit” 의무라고 하지만 Phase 01 Exit와 Blueprint 승인 체크에는 해당 항목이 없습니다. split 시점인 Phase 02에서는 이미 Blueprint가 승인된 뒤라 누락을 gate에서 잡기 어렵습니다.
- **제안**: Phase 01 Activities/Exit와 BLUEPRINT template에 `Cross-cutting invariants` 섹션을 필수 추가. split하지 않는 경우도 `none identified`를 명시하게 하세요.

### Finding F73: split 사용자 승인 gate가 machine preflight에서 우회 가능함
- **severity**: major
- **위치**: `HARNESS.md:446`, `skills/spawn-subtree-prompts.md:36`, `templates/SPLIT-DECISION-ADR.template.md:84`
- **근거**: F6는 모든 모드에서 user approval 필수인데, spawn preflight는 `status: accepted`만 확인합니다. `approver: claude-self-test` 또는 다른 non-user accepted ADR도 통과 가능합니다.
- **제안**: preflight에 `approver: user`와 `approved_at` 검증을 추가하고, dogfood 예외는 명시적 `dogfood_simulation: true`일 때만 별도 경로로 처리하세요.

### Finding F74: recursion depth와 root/parent 관계가 기계적으로 추적되지 않음
- **severity**: major
- **위치**: `HARNESS.md:445`, `HARNESS.md:498`, `templates/SPLIT-DECISION-ADR.template.md:9`, `skills/spawn-subtree-prompts.md:80`
- **근거**: depth ≤ 2 규칙은 있으나 grandchild 생성 시 immediate parent, root coordinator, root manifest freeze 기준, resulting depth 계산을 강제하는 preflight가 없습니다. `depth` 필드는 상태 기록일 뿐 enforcement가 아닙니다.
- **제안**: ADR/subtree marker에 `root_path`, `parent_subtree`, `current_depth`, `resulting_depth`, `max_depth`, `root_capability_manifest_hash`를 추가하고 `resulting_depth > 2`면 spawn이 실패하게 하세요.

### Finding F75: F3 manifest freeze와 F9 child local skill 추가 허용이 충돌 가능함
- **severity**: major
- **위치**: `HARNESS.md:443`, `HARNESS.md:449`, `templates/SUBTREE-PROMPT.template.md:79`, `templates/SUBTREE-PROMPT.template.md:85`
- **근거**: F3는 child가 manifest를 읽기만 하고 신규 capability는 MERGE-REPORT candidate라고 합니다. 그런데 F9/prompt는 child가 local skill을 “추가 가능”하다고만 말해, manifest 미등재 skill을 active로 사용하는 HC-10 우회 해석이 가능합니다.
- **제안**: “child may draft local capability files only; may not load/use them unless already active in the frozen manifest”로 명확히 쓰고, 후보는 MERGE-REPORT 전용으로 제한하세요.

### Finding F76: “root coordinator scope의 마지막 plan” 판정이 기계적이지 않음
- **severity**: major
- **위치**: `phases/02-module-plan.md:23`, `phases/02-module-plan.md:44`, `skills/estimate-project-scope.md:34`
- **근거**: 마지막 plan 여부를 판단하는 기준이 없습니다. `ls .harness/docs/modules/`는 존재하는 plan 수만 세며 Blueprint상 계획된 module set과 비교하지 않습니다.
- **제안**: Blueprint 또는 `.harness/docs/modules/index.md`에 expected module IDs를 고정하고, Phase 02 Exit에서 “expected set == approved plan set”일 때만 split-decision을 실행하게 하세요.

### Finding F77: merge conflict resolution의 판단 기준과 기록 양식이 부족함
- **severity**: major
- **위치**: `phases/05-integration.md:18`, `phases/05-integration.md:41`, `templates/MERGE-REPORT.template.md:52`
- **근거**: shared conflict는 parent가 결정한다고만 되어 있고, 어떤 child의 제안이 lock/invariant/test evidence 측면에서 우선되는지 판단하는 절차가 없습니다.
- **제안**: MERGE-REPORT 통합본에 conflict decision matrix를 추가하세요. lock conformance, invariant impact, test evidence, rejected alternatives, ADR 필요 여부를 기록하고 major 이상 분쟁은 §11 사용자 escalation으로 연결해야 합니다.

### Finding F78: SUBTREE-PROMPT가 “prompt+lock만으로 시작 가능”하다고 하기엔 required reads가 부족함
- **severity**: minor
- **위치**: `templates/SUBTREE-PROMPT.template.md:16`, `templates/SUBTREE-PROMPT.template.md:59`, `templates/SUBTREE-PROMPT.template.md:87`
- **근거**: 시작 절차가 HARNESS/STATUS 중심이고 DECISIONS, parent Blueprint, split ADR, frozen capabilities manifest를 명시적으로 읽게 하지 않습니다.
- **제안**: child required reads를 고정 목록으로 추가하세요: HARNESS, AGENTS/CLAUDE, `.harness/subtree.md`, locked-interface, parent Blueprint, split ADR, frozen capabilities manifest.

## Overall verdict

- **new_blockers**: 1
- **new_majors**: 6
- **new_minors**: 1
- **ready_for_next_phase**: no

HC-7/8/9 직접 위반은 발견하지 못했습니다. v1.1 ship 전에는 최소 F71~F77 처리가 필요합니다.

## Assumptions

- Assumption A1: `examples/fleet-mini/`는 v1.1의 정식 dogfood evidence로 제출된 것으로 보았습니다. 단순 illustrative simulation이면 F71은 blocker가 아니라 “evidence claim 수정” major로 낮출 수 있습니다.
