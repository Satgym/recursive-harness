---
artifact: review
date: 2026-05-25
author: codex
status: open
severity: <see body>
target: harness v0.5 vs adaptive vision
review_round: adaptive-redesign-r1
prior_review: .harness/reviews/a5-20260525-integrated.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e5e78-2ff0-7ed3-a379-58e7f6b7294d
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: medium
  tokens_used: 117845
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-25T09:29
  prompt_source: .harness/prompts/adaptive-redesign-r1.md
---

---
date: 2026-05-25
author: codex
severity: blocker
target: harness v0.5 vs adaptive-harness vision (strategic redesign)
status: open
review_round: adaptive-redesign-r1
prior_review: examples/todo-api/.harness/reviews/02-module-plan-20260525-m-service.md
---

# Adaptive Harness Redesign Review (adaptive-redesign-r1)

## Summary
현재 하니스는 “정적 base harness + dogfood로 점진 개선”에는 꽤 강하지만, 사용자가 새로 명확히 한 “project intake를 바탕으로 프로젝트 로컬 skill/role/agent layer를 자체 구성하는 adaptive harness”와는 구조적으로 한 단계 떨어져 있다. `harness-amend`, `drift-check`, ADR, INBOX, dogfood loop는 적응의 feedback channel로는 작동하지만, 적응 결과가 프로젝트 내부의 승인된 local capability로 영속화되는 메커니즘이 없다. 핵심 권고는 `project-types/`를 중심 메커니즘에서 fallback seed로 격하하고, Phase 00과 01 사이에 `.harness/skills/`, `.harness/roles/`, `.harness/capabilities.md`를 생성·리뷰·승인하는 Local Capability Synthesis 게이트를 추가하는 것이다.

## Part A — Gap analysis

### Finding 52: Adaptive feedback loop exists, but only at base-harness level
- severity: info
- target: `HARNESS.md §6`, `skills/harness-amend.md`, `skills/drift-check.md`, `DECISIONS.md`, `INBOX/README.md`
- detail: 현재 설계는 drift 신호, ADR, postmortem, INBOX, dogfood finding을 통해 하니스가 배울 수 있는 루프를 갖고 있다. 특히 `harness-amend`는 하니스 자체 결함을 base 문서/스크립트/템플릿 변경으로 연결한다. 이 점은 adaptive vision의 기반이다.
- suggested_action: 이 루프를 유지하되, “base amend”와 “project-local adaptation”을 별도 경로로 분리하라.
- references: `HARNESS.md §6.2`, `skills/harness-amend.md`, `examples/todo-api/.harness/status.md` F41 note

### Finding 53: No project-local skill/role layer exists
- severity: blocker
- target: `HARNESS.md §4.2`, `scripts/new-project.sh`, `examples/todo-api/.harness/`
- detail: 표준 프로젝트 산출물 위치에는 `.harness/skills/`, `.harness/roles/`, `.harness/agents/`, capability manifest가 없다. `examples/todo-api/.harness/`에도 docs/reviews/prompts/inbox만 있고 local skill/role 디렉토리는 없다. 따라서 intake가 “이 프로젝트에는 firmware safety reviewer, AI eval designer, hardware lab operator가 필요하다”를 발견해도 이를 승인된 프로젝트 로컬 material로 만들 위치와 게이트가 없다.
- suggested_action: `.harness/skills/`, `.harness/roles/`, `.harness/capabilities.md`, `.harness/capabilities/reviews/`를 표준 위치에 추가하고, `new-project.sh`가 빈 skeleton을 생성하게 하라.
- references: `HARNESS.md §4.2`, `scripts/new-project.sh`, `examples/todo-api/.harness/`

### Finding 54: Phase 00 selects a static project-type instead of synthesizing capabilities
- severity: major
- target: `phases/00-intake.md`, `skills/kickoff-project.md`, `project-types/README.md`
- detail: Phase 00의 핵심 행동은 `ls project-types/` 후 closest match 또는 `_generic` 선택이다. 매칭이 없으면 “새 project-type을 만드는 것 자체가 하니스 작업”으로 base repo 수정 경로를 탄다. 이는 사용자가 거부한 정적 catalog 확장 방식에 가깝다.
- suggested_action: Phase 00을 “project-type 선택”에서 “capability gap 분석”으로 바꾸고, project-type은 local layer 생성을 돕는 seed/reference로만 사용하라.
- references: `phases/00-intake.md:18`, `skills/kickoff-project.md`, `project-types/README.md`, ADR-005

### Finding 55: Projects cannot add a domain SME role without modifying the base repo
- severity: major
- target: `roles/README.md`, `roles/*.md`
- detail: role catalog는 4개 base roles로 고정되어 있고, Reviewer-Swap/Implementer-Rare만 예외로 다룬다. “domain-sme-reviewer”, “firmware-safety-reviewer”, “ml-eval-reviewer” 같은 프로젝트 로컬 역할을 선언·검토·활성화하는 규칙이 없다.
- suggested_action: base roles는 execution authority만 정의하고, domain roles는 `.harness/roles/*.md`에 “advisory reviewer / domain checklist owner / implementation constraints provider”로 추가할 수 있게 하라.
- references: `roles/README.md`, `roles/codex-reviewer.md`

### Finding 56: Local loading semantics are undefined
- severity: blocker
- target: `skills/README.md`, `skills/resume-session.md`, `AGENTS.md instructions`
- detail: skills README는 향후 Claude Code skill 시스템과 symlink 통합 가능성을 언급하지만, 현재는 procedural docs다. 프로젝트 로컬 skill이 생겨도 Claude/Codex 세션 시작 시 어떤 파일을 읽고, 어떤 우선순위로 base skill을 override/extend하며, Codex review prompt에 어떻게 포함되는지 정의되어 있지 않다.
- suggested_action: session start order에 `.harness/capabilities.md`를 추가하고, 그 manifest가 local skills/roles의 explicit import list가 되게 하라. base override는 금지하고 extension-only로 시작하라.
- references: `skills/README.md`, `skills/resume-session.md`

### Finding 57: Local material has no approval or safety gate
- severity: major
- target: `HARNESS.md §2`, `phases/01-blueprint.md`, `templates/`
- detail: base harness 변경은 사용자 승인 필수지만, project-local skill/role 생성에 대한 status enum, template, Codex review, user approval rule이 없다. 이 상태에서 local role이 HC-8/9 승인 규칙을 약화하거나 Codex reviewer 권한을 바꾸면 안전 표면이 커진다.
- suggested_action: local material은 `artifact: local_skill | local_role | capability_manifest`로 front-matter를 갖고, Codex review + user approval 전에는 advisory draft로만 취급하라.
- references: `HARNESS.md §2`, `templates/ADR.template.md`, `templates/REVIEW.template.md`

### Finding 58: Dogfood F41 was logged, not adapted
- severity: major
- target: `examples/todo-api/.harness/status.md`, `examples/todo-api/.harness/reviews/01-blueprint-20260525-initial.md`
- detail: bp.1에서 spec-first placeholder 문제가 발견됐고, project status는 F41을 “하니스 dogfood 학습”으로 open carry했다. 그러나 harness가 즉시 web-service local skill, local checklist, or project-local gate를 생성한 것은 아니다. 즉 현재 적응은 “나중에 base를 고치자”에 머문다.
- suggested_action: F41 같은 finding은 base amend 후보와 별개로 `.harness/skills/spec-first-blueprint.md` local draft를 자동/반자동 생성하고, Codex review 후 프로젝트에서 먼저 쓰게 하라.
- references: `examples/todo-api/.harness/reviews/01-blueprint-20260525-initial.md` Finding 35 / Part D, `examples/todo-api/.harness/status.md` Notes F41

## Part B — Concrete redesign proposals

### Finding 59: Add a Base vs Local Layer constitution section
- severity: info
- target: `HARNESS.md` new section
- detail: HARNESS needs an explicit model: base harness defines hard constraints, phases, artifact schemas, and default roles; project-local layer defines domain-specific skills, roles, checklists, test gates, and review rubrics.
- suggested_action: Add `HARNESS.md §13 Project-local adaptive layer` with rules: local material may extend but not weaken HC-1~9; local material is project-scoped; base remains authoritative on safety, approval, and phase gates.
- references: F53-F57

### Finding 60: Insert Local Capability Synthesis after Intake
- severity: info
- target: `phases/00-intake.md`, `phases/01-blueprint.md`
- detail: The adaptive moment should happen after requirements/nature are known but before Blueprint freezes module boundaries.
- suggested_action: Add sub-phase `00.5 Local Capability Synthesis`: identify domain gaps, draft local roles/skills/checklists, run Codex review, get user approval, then Blueprint uses them. Avoid making it a full new numbered phase for v1.0 unless the workflow diagram must stay strictly linear.
- references: `phases/00-intake.md`, `phases/01-blueprint.md`

### Finding 61: Add templates for local capabilities
- severity: info
- target: `templates/`
- detail: Local material needs machine-readable metadata and reviewable structure.
- suggested_action: Add `LOCAL-SKILL.template.md`, `LOCAL-ROLE.template.md`, and `CAPABILITY-MANIFEST.template.md`. Required fields: `artifact`, `scope`, `extends`, `may_not_override`, `hc_review`, `activation`, `inputs`, `outputs`, `approval`, `references`.
- references: `templates/README.md`, `HARNESS.md §4.3`

### Finding 62: Add three base skills for adaptation
- severity: info
- target: `skills/`
- detail: `harness-amend` is too broad and base-oriented for project-local adaptation.
- suggested_action: Add `synthesize-local-layer.md`, `review-local-layer.md`, and `promote-local-capability.md`. The first drafts local material from intake; the second invokes Codex and maps HC-1~9 compliance; the third proposes base promotion after repeated successful use.
- references: `skills/harness-amend.md`, `skills/kickoff-project.md`

### Finding 63: Define loading by manifest, not implicit discovery
- severity: minor
- target: `skills/resume-session.md`, `AGENTS.md`, project `CLAUDE.md`/`AGENTS.md`
- detail: Assumption: current Claude/Codex CLI sessions will not automatically load arbitrary `.harness/skills/*.md` unless instructed through startup docs/prompts. Relying on magic discovery would be brittle.
- suggested_action: Make `.harness/capabilities.md` the explicit loading contract. `resume-session` must read it after `.harness/status.md`; Codex review prompts must include it when relevant. Optional symlinks to user-level skill systems can be v1.1, not v1.0.
- references: `skills/resume-session.md`, `skills/README.md`

### Finding 64: Review local material with delta safety checks
- severity: info
- target: new `skills/review-local-layer.md`
- detail: The harness does not need to re-review the whole base for every local skill. It needs to prove the local layer is an extension that cannot weaken base constraints.
- suggested_action: Codex review checklist for local material: declares inherited HC-1~9; contains no override language for approvals; identifies HC-7/8/9 domain risks; has activation rules; has test/observability expectations; has rollback/supersede path. User approval makes it authoritative for that project only.
- references: `HARNESS.md HC-1~9`, F57

### Finding 65: Treat project-types as seeds, not coverage strategy
- severity: minor
- target: `project-types/README.md`, ADR-005
- detail: The current README frames new types as base repo additions. That conflicts with the clarified vision.
- suggested_action: Rewrite `project-types/README.md`: project-types are optional starter packs. If no type fits, `_generic` + Local Capability Synthesis is the normal path. Base project-type promotion requires evidence from local dogfood.
- references: ADR-005, `project-types/README.md`

### Finding 66: Define promotion criteria from local to base
- severity: info
- target: `HARNESS.md`, `skills/promote-local-capability.md`
- detail: Without promotion rules, local layers either rot forever or get prematurely copied into base.
- suggested_action: Promote only when a local capability has been used in at least two projects or one non-trivial dogfood, passed Codex review, produced fewer than a threshold of reopened findings, and is generalizable without domain secrets. Promotion uses `harness-amend`, ADR, Codex review, user approval.
- references: `skills/harness-amend.md`, `HARNESS.md §6`

### Finding 67: Extend `new-project.sh` to create adaptive skeletons
- severity: minor
- target: `scripts/new-project.sh`
- detail: Bootstrap currently creates `.harness/docs`, `reviews`, `decisions`, `postmortems`, `prompts`, `inbox`, but not adaptive layer directories.
- suggested_action: Add `.harness/skills/`, `.harness/roles/`, `.harness/capabilities/`, and `.harness/capabilities.md` initialized from templates. The manifest should start with “no approved local capabilities yet.”
- references: `scripts/new-project.sh`, F53

## Part C — Realism check

- minimum_viable_adaptive_v1: Keep the current base harness and add a file-based local layer only: `.harness/capabilities.md`, `.harness/skills/*.md`, `.harness/roles/*.md`, templates, and a `00.5 Local Capability Synthesis` gate. Claude drafts local material from intake, Codex reviews it as text, the user approves it, and subsequent Blueprint/Module Plan prompts explicitly include the manifest. This is realistic with today’s Claude + Codex CLI because it uses files and prompts, not dynamic agent runtime features.

- deferred_to_v1.1+:
  - Automatic installation/symlinking into Claude Code skill directories.
  - Dynamic agent spawning based on local role manifests.
  - Local capability lint tooling beyond simple schema/front-matter checks.
  - Cross-project promotion analytics.
  - Rich inheritance/override semantics; v1.0 should be extension-only.

- key_risks:
  - Local layer drift from base constraints if override rules are ambiguous.
  - Agent identity confusion if domain roles are treated as execution authority rather than advisory specialization.
  - Role explosion: every minor checklist becomes a “role.”
  - Expanded security review surface per project, especially for HC-7/8/9 domain-specific workflows.
  - Prompt bloat and review cost if every local skill is always loaded instead of manifest-scoped.
  - Stale local capabilities after base harness upgrades.

- recommended_dogfood_to_validate_adaptivity: Run a second dogfood that is intentionally not web-service, preferably firmware or AI model evaluation. Start from `_generic`, require the harness to synthesize local roles such as `firmware-safety-reviewer` or `ml-eval-reviewer`, plus local skills for HIL/simulator validation or dataset/eval reproducibility. Success means the project reaches approved Blueprint and at least one Module Plan using only base + project-local layer, without adding `project-types/firmware` or `project-types/ai-model` to the base first.

## Overall verdict

- new_blockers: 2
- new_majors: 4
- new_minors: 3
- new_infos: 7
- ready_for_next_phase: no
- rationale: The current harness is a strong static/process harness, but not yet the adaptive base + local layer system the user described. The blocker is not implementation quality; it is missing architecture: no local capability directory, no synthesis gate, no loading semantics, and no approval model for project-local skills/roles.

## Assumptions (if any)

- Assumption A1: Claude/Codex sessions only reliably use files that startup docs, STATUS required reads, or prompts explicitly include; arbitrary `.harness/skills/` discovery is not automatic today.
- Assumption A2: “agents” in the user vision can be represented in v1.0 as role/capability specs and prompt-loaded personas, not necessarily separate runtime processes.
- Assumption A3: Project-local material should be allowed to specialize review/checklists but not override HC-1~9 or base phase gates.

## Related artifacts read

- `HARNESS.md` v0.5
- `phases/README.md`, `phases/00-intake.md` through `phases/06-handoff.md`
- `skills/README.md` and all 9 skill docs
- `roles/README.md` and all 4 role docs
- `templates/README.md` and all 6 templates
- `scripts/README.md`, `new-project.sh`, review wrappers, pre-review gate, postprocess helper
- `project-types/README.md`, `_generic/`, `web-service/`
- `examples/todo-api/.harness/` live dogfood files
- `examples/todo-api/.harness/reviews/` bp.1, bp.2, bp.3, m-service-r1
