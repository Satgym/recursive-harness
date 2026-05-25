You are performing the first formal cross-review of skills/ and project-types/ added during Phase B and Phase C of the harness self-build at /Users/satgym/work/harness. Apply phases/04-cross-review.md Exit criteria.

CONTEXT:
- Phase A is sealed at HARNESS v0.5 (commit 2267d76). All 26 prior findings (F1-F26) are closed.
- Phase B added skills/ (10 files — README + 9 skills) at commit 85e6915.
- Phase C added project-types/ (8 files — README + _generic/ 3 + web-service/ 4 with API spec template) at commit 62aa964.
- Per ADR-006 the bootstrap cadence is retired; this is a normal cross-review under phases/04 Exit criteria.

REVIEW SCOPE (read all):

Phase B — skills/
- skills/README.md
- skills/kickoff-project.md
- skills/plan-blueprint.md
- skills/plan-module.md
- skills/request-codex-review.md
- skills/apply-review.md
- skills/checkpoint-handoff.md
- skills/resume-session.md
- skills/drift-check.md
- skills/harness-amend.md

Phase C — project-types/
- project-types/README.md
- project-types/_generic/intake-checklist.md
- project-types/_generic/test-strategy.md
- project-types/_generic/module-skeleton.md
- project-types/web-service/intake-checklist.md
- project-types/web-service/test-strategy.md
- project-types/web-service/module-skeleton.md
- project-types/web-service/api-spec-template.md

Reference (already approved; scan for consistency only):
- HARNESS.md v0.5, CLAUDE.md, AGENTS.md, STATUS.md, DECISIONS.md
- phases/<all>, roles/<all>, templates/<all>, scripts/<all>, INBOX/README.md

YOUR TASK — produce a REVIEW with 4 parts:

PART A — Cross-consistency
- Do skill procedures invoke real script flags / phase Exit criteria? Any drift between cited HARNESS sections and actual v0.5 content?
- Does scripts/new-project.sh actually copy project-types/<type>/ correctly given the current layout (per Phase C)?
- project-types/_generic vs project-types/web-service: deepening points sensible, no duplication, no contradiction?
- web-service intake/test/module/api-spec ↔ HC-7/8/9: are security gates honored across these artifacts?
- skills citing HARNESS § / ADR — are those sections actually present in v0.5?

PART B — New surface findings
- skills/: completeness of procedures; missing edge cases (INBOX missing, codex returns malformed output, network failure, sandbox denial); failure_modes coverage
- project-types/: are checklists genuinely actionable or just rephrasings? Are HC items measurable? Does web-service intake actually unlock spec-first frontend collaboration?
- api-spec-template.md: OpenAPI completeness, error format, security scheme, pagination, versioning
- _generic vs web-service: rules in web-service that should be promoted to _generic? content in _generic that is too web-leaning?

PART C — HC violations (forced severity: blocker if any)
- HC-7: any skill or template guiding the user toward secret/PII leakage in normal use?
- HC-8: any procedure that performs external mutation without explicit user approval?
- HC-9: any procedure with destructive defaults?

PART D — Phase B/C verdict
- ready_for_phase_D: yes | yes_with_minor_fixes | no
- ready_for_phase_E (dogfood): yes | yes_with_minor_fixes | no
- minor_fixes_blocking_phase_D: list (if any)

OUTPUT FORMAT — strict templates/REVIEW.template.md compliance. Finding IDs start at F27 (monotonic across all rounds; prior rounds used F1-F26). Use canonical English enums (severity: blocker|major|minor|nit|info; status: open|resolved|deferred|disputed). HC-7/8/9 violations are severity: blocker by definition.

---
date: 2026-05-25
author: codex
severity: <highest finding severity>
target: Phase B (skills/) + Phase C (project-types/) integrated cross-review
status: open
review_round: BC.1
prior_review: .harness/reviews/a5-20260525-integrated.md
---

# Phase B + C Integrated Cross-Review (BC.1)

## Summary
<one paragraph>

## Part A — Cross-consistency findings

### Finding 27: <short title>
- severity: blocker | major | minor | nit | info
- target: <file:section-or-line>
- detail: <observation + reasoning>
- suggested_action: <concrete change>
- references: <file paths / ADR ids / prior finding IDs>

(continue monotonically)

## Part B — New surface findings
(continued numbering)

## Part C — Security / HC violations
(forced blocker if any; otherwise state explicitly none)

## Part D — Phase B/C verdict
- ready_for_phase_D: ...
- ready_for_phase_E: ...
- new_blockers: <count>
- new_majors: <count>
- new_minors: <count>
- new_infos: <count>
- rationale: <one paragraph>

Make assumptions when needed, labeled "Assumption: ..." inside the relevant finding.
