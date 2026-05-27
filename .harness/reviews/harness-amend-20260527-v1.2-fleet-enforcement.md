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
  session_id: 019e673f-9924-7d81-98f9-6925ce9e1711
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 97740
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T02:24
  prompt_source: .harness/prompts/v1.2-fleet-enforcement-bundle.md
---

## REVIEW — Hara v1.2 Fleet Enforcement Bundle

## Findings

### Finding 1: `user-delegated` approval path is forgeable
- **severity**: blocker
- **위치**: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:447), [skills/spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:50), [templates/SPLIT-DECISION-ADR.template.md](/Users/satgym/work/harness/templates/SPLIT-DECISION-ADR.template.md:99)
- **근거**: `delegation_source`는 “비어 있지 않음”만 검사합니다. autonomous 세션이 과거 사용자 메시지를 재구성하거나 허위 quote를 넣어도 preflight가 통과합니다. “기계적 강제” approval gate가 자기기입 문자열로 우회되는 구조라, v1.2 ship 전 차단해야 합니다.
- **제안**: production Fleet에서는 `approver: user-delegated`를 valid approval path에서 제거하거나, “검증 불가능한 delegation claim”으로 격하하세요. 유지하려면 spawn 직전 별도 사용자 확인 artifact가 필요합니다. 최소한 `user-delegated`는 examples/dogfood 전용으로 제한하고 production은 `approver: user`만 허용해야 합니다.

### Finding 2: `inter_child_consume_strategy`는 검증만 하고 실행 semantics가 없음
- **severity**: major
- **위치**: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:534), [skills/spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:96), [skills/spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:104)
- **근거**: spawn skill은 `a|b|c` 필드 존재만 확인합니다. 이후 Step 2는 모든 child worktree를 한 번에 만들고, Step 6도 모든 child 세션을 동시에 열라고 안내합니다. 즉 option (c) topo-order를 선택해도 provider 완료 후 consumer dispatch가 강제되지 않습니다. option (a) stub 생성, option (b) ambient 생성/제거도 실제 절차가 없습니다.
- **제안**: strategy별 실행 절차를 spawn skill에 명시하세요. `a`: parent stub 파일 생성 + consumer test mock policy. `b`: ambient declaration 위치/merge 제거 gate. `c`: dependency graph topological sort + provider 완료 전 consumer prompt 미발행.

### Finding 3: `lock-grep-gate` is still advisory, not strong mechanical enforcement
- **severity**: major
- **위치**: [skills/lock-grep-gate.md](/Users/satgym/work/harness/skills/lock-grep-gate.md:46), [skills/lock-grep-gate.md](/Users/satgym/work/harness/skills/lock-grep-gate.md:62), [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:524)
- **근거**: import grep은 `import { ... } from '../provider/index.js'` 단일 형태만 잡습니다. alias, namespace import, multiline import, re-export helper, 하위 디렉토리 파일은 놓칠 수 있습니다. invariant marker도 실제 호출을 보장하지 않고 marker만 있으면 dead import를 허용합니다.
- **제안**: v1.2에서는 “typecheck 수준에 근접” 표현을 낮추거나, lock에서 생성한 ESLint/TS AST rule을 gate로 삼으세요. invariant는 marker 허용보다 runtime wrapper 또는 AST 기반 call-site 확인을 기본으로 두는 편이 맞습니다.

### Finding 4: Phase 05 checklist does not require `lock-grep-gate`
- **severity**: major
- **위치**: [phases/05-integration.md](/Users/satgym/work/harness/phases/05-integration.md:14), [phases/05-integration.md](/Users/satgym/work/harness/phases/05-integration.md:45), [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:524)
- **근거**: HARNESS §14.8은 parent Phase 05에서 `lock-grep-gate` 자동 검증을 요구하지만, 실제 Phase 05 Activities/Exit 기준에는 없습니다. 하니스의 실질 gate는 phases 파일이므로 현재 상태에서는 운영자가 이 검증을 생략해도 Exit 기준 위반이 아닙니다.
- **제안**: Phase 05 Fleet merge-collection 활동과 Exit 기준에 `lock-grep-gate PASS`를 명시하고, output review path도 요구하세요.

### Finding 5: scope-only gate command is too fragile to be a standard gate
- **severity**: major
- **위치**: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:548), [templates/SUBTREE-PROMPT.template.md](/Users/satgym/work/harness/templates/SUBTREE-PROMPT.template.md:77), [skills/spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:121)
- **근거**: template에는 `src/<child>/*.ts src/shared/*.ts tests/<child>/*.ts`가 하드코딩되어 있고, spawn skill은 실제 `tsconfig.<child>.json`/`jest.config.<child>.json`을 생성하지 않습니다. nested source, shared transitive imports, jest globals, provider stub/ambient path가 프로젝트마다 깨질 수 있습니다.
- **제안**: inline `tsc` 예시를 fallback으로 낮추고, spawn skill이 child별 tsconfig/jest config를 생성하도록 의무화하세요. ownership matrix에서 owned paths와 shared transitive paths를 읽어 include를 만들도록 해야 합니다.

### Finding 6: new `LOCKED-INTERFACE` template is not wired into spawn output
- **severity**: major
- **위치**: [templates/LOCKED-INTERFACE.template.md](/Users/satgym/work/harness/templates/LOCKED-INTERFACE.template.md:29), [skills/spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:125)
- **근거**: 신규 template은 runtime/type-only import, behavior spec, defensive validation policy를 요구하지만 spawn skill Step 3은 기존 항목만 “추출”한다고 되어 있습니다. future child locked-interface가 새 양식을 따르도록 강제되지 않습니다.
- **제안**: spawn skill Step 3에서 `templates/LOCKED-INTERFACE.template.md`를 인스턴스화하도록 바꾸고, 필수 섹션 누락 시 die 조건을 추가하세요.

### Finding 7: dogfood evidence is useful but not sufficient for “mechanical enforcement” claims
- **severity**: minor
- **위치**: [examples/starpin-fleet/.harness/decisions/ADR-001-split-decision-4-children.md](/Users/satgym/work/harness/examples/starpin-fleet/.harness/decisions/ADR-001-split-decision-4-children.md:86), [examples/starpin-fleet/.harness/reviews/05-merge-collection-20260527.md](/Users/satgym/work/harness/examples/starpin-fleet/.harness/reviews/05-merge-collection-20260527.md:91), [DECISIONS.md](/Users/satgym/work/harness/DECISIONS.md:89)
- **근거**: starpin-fleet는 같은 worktree에서 self-discipline boundary로 진행했고, child codex review도 dogfood scope에서 self-test로 대체했습니다. evidence로는 좋지만 v1.2의 “mechanical enforcement” 자체가 검증됐다고 보긴 어렵습니다.
- **제안**: ADR-011 positive claim을 “gap discovery evidence”로 낮추고, real git worktree + generated lock gate를 적용한 후속 dogfood를 v1.3 exit candidate로 명시하세요.

## Overall Verdict

- **new_blockers**: 1
- **new_majors**: 5
- **new_minors**: 1
- **ready_for_next_phase**: no

v1.2 방향은 맞지만, 현재 bundle은 “규칙 추가 + grep skill 초안”에 가깝고 핵심 강제 지점이 아직 phase gate와 spawn 절차에 충분히 연결되지 않았습니다. 특히 `user-delegated` approval은 ship 전 반드시 막아야 합니다.
