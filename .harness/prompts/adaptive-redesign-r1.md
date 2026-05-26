You are reviewing the entire harness design at /Users/satgym/work/harness against a target vision the user just clarified. Treat this as a strategic redesign review (not a defect hunt).

CONTEXT — CURRENT STATE (commit be694b7):
- HARNESS.md v0.5 with 12 sections (HC-1~9, strictness modes, phases, STATUS format, dogfood criteria, conflict protocol, branch/git).
- phases/ (7 docs), roles/ (4 docs), templates/ (6 docs), scripts/ (5 tools + helper), skills/ (9 procedural docs), project-types/ (web-service deep, _generic skeleton).
- Phase E dogfood underway at examples/todo-api/ — Phase 00 + Phase 01 (Blueprint approved at bp.3) + Phase 02 (M-service plan at m-service-r1, 2 majors + 3 minors).
- 7 codex review rounds so far (A.0a / A.0f / A.5 on HARNESS / BC.1 on B+C / 3 bp on todo-api Blueprint / m-service-r1), 681K cumulative tokens.

USER'S CLARIFIED VISION (Korean original below, then translation):
"프로젝트의 기획을 받았을 때 이 하니스의 베이스 스킬과 에이전트에 추가할 적응형 프로젝트 로컬 스킬과 에이전트를 자체적으로 구성할 수 있는 종합 적응형 하니스"

Translation: The harness should be a **base + adaptive local layer** system. Given a project intake, the harness should **self-construct** project-local skills and agents (roles) that extend or specialize the base, because no static catalog of project types can cover every domain (web, firmware, AI, hardware, scientific computing, etc.). The user explicitly notes that pre-baked project-types/ cannot cover all cases — the harness must adapt.

READ in full to ground your analysis:
- /Users/satgym/work/harness/HARNESS.md v0.5 (entire constitution)
- /Users/satgym/work/harness/phases/ (all 7 + README)
- /Users/satgym/work/harness/skills/ (all 9 + README) — especially kickoff-project, harness-amend, drift-check
- /Users/satgym/work/harness/roles/ (all 4 + README)
- /Users/satgym/work/harness/templates/ (all 6 + README)
- /Users/satgym/work/harness/scripts/ (all 5 + README + _codex_postprocess.py)
- /Users/satgym/work/harness/project-types/ (README + _generic/ + web-service/)
- /Users/satgym/work/harness/examples/todo-api/.harness/ (the live dogfood — see how a real project sits on top of the base)
- /Users/satgym/work/harness/examples/todo-api/.harness/reviews/ (bp.1 / bp.2 / bp.3 / m-service-r1)

YOUR TASK — three-part strategic review:

PART A — Gap analysis: how far is the current harness from the user's adaptive vision?
- Where in the current design is "adaptive" supported well? (harness-amend, drift-check, ADR mechanism, dogfood loop)
- Where does "adaptive" leak / break / not exist?
  - Does kickoff-project / Phase 00 Intake actually trigger creation of project-local skills or roles?
  - Are project-types/ a static catalog or an extensible mechanism?
  - Can a project create a new role (domain SME) without modifying the base harness repo?
  - Is there any `.harness/skills/` or `.harness/roles/` local layer mechanism today?
  - When Phase E dogfood discovered F41 (spec-first not enforced) — did the harness *adapt* automatically, or just log it as a finding for later?

PART B — Concrete redesign proposals (numbered findings F52+)
- Propose specific structural changes: new HARNESS sections, new phases or sub-phases, new base skills, directory layout for the per-project local layer.
- Address each:
  - How does a project author declare "I need a new role X / new skill Y"?
  - How does the harness ensure the new local material obeys HC-1~9 (hard constraints) without re-validating the whole base?
  - How does this differ from harness-amend (which is base-level)?
  - How do project-local skills get loaded into Claude's working set when a session starts? CLAUDE.md inheritance? Discovery from .harness/skills/? Symbolic linking? Explicit import in CLAUDE.md?
  - How is project-local material itself reviewed (codex cross-review) and approved (user) before becoming authoritative?
  - Promotion path: when does a project-local skill prove useful enough to be promoted into the base harness?

PART C — Realism check
- Is the user's vision realistic with the current Claude + Codex CLI toolchain? What is the smallest viable v1.0 of "adaptive harness"?
- What should be deferred to v1.1+?
- What risks does this redesign introduce? (local layer drifting from base, agent identity confusion, role explosion, security review surface growing per-project)
- What dogfood would actually validate adaptive behavior? (E.g., a *different* project type — firmware or AI model — bootstrapped to prove the base can adapt.)

OUTPUT FORMAT — strict templates/REVIEW.template.md compliance. Front-matter first. Finding IDs start at F52 (monotonic; prior rounds used F1-F51). Canonical English enums. Be honest about your own limits where you have to make assumptions about Claude's session behavior.

---
date: 2026-05-25
author: codex
severity: <highest finding severity>
target: harness v0.5 vs adaptive-harness vision (strategic redesign)
status: open
review_round: adaptive-redesign-r1
prior_review: examples/todo-api/.harness/reviews/02-module-plan-20260525-m-service.md
---

# Adaptive Harness Redesign Review (adaptive-redesign-r1)

## Summary
<one paragraph: where the harness sits vs. the adaptive vision, biggest gaps, high-level recommendation>

## Part A — Gap analysis

### Finding 52: <short title>
- severity: blocker | major | minor | nit | info
- target: <file:section>
- detail: <observation + reasoning>
- suggested_action: <concrete change>
- references: <files / ADR ids / prior finding IDs>

(continue monotonically for the Part A surface)

## Part B — Concrete redesign proposals

(continue numbering; each proposal as a finding with severity = info or minor unless it patches a real defect)

## Part C — Realism check

- minimum_viable_adaptive_v1: <one paragraph>
- deferred_to_v1.1+: <bulleted list>
- key_risks: <bulleted list>
- recommended_dogfood_to_validate_adaptivity: <one paragraph — what concrete second-project-type dogfood would prove the harness adapts>

Make assumptions when needed, labeled "Assumption: ..." inside the relevant finding.
