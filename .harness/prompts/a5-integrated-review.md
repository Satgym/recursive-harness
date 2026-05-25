You are performing the FIRST formal cross-review of the Claude+Codex harness at /Users/satgym/work/harness, after deprecation of §9 Bootstrap exception (per ADR-007). Apply phases/04-cross-review.md Exit criteria.

The harness is a meta-bootstrap repository — it built itself via its own phases/sub-phases (A.0 through A.4). HEAD = 15bf6fb. This is also the first time scripts/codex-exec-review.sh is invoked as designed (dogfood).

REVIEW SCOPE — read the following surfaces:

ROOT FILES:
- HARNESS.md (v0.4 with §9 now deprecated per ADR-007)
- CLAUDE.md, AGENTS.md
- STATUS.md, DECISIONS.md
- .gitignore, .harness/config.toml (this dogfood)

DIRECTORIES (all added since A.0e):
- roles/      — 4 agent role definitions + README (A.1)
- templates/  — 6 artifact form templates + README (A.2)
- scripts/    — 4 main shells + 1 python helper + README (A.3)
- phases/     — 7 phase Exit criteria docs + README (A.4)

PRIOR REVIEWS (both closed):
- INBOX/processed/codex-feedback-20260525-seed-review.md (A.0a)
- INBOX/processed/codex-feedback-20260525-v0.3-review.md (A.0f)

YOUR TASK — produce a comprehensive REVIEW in templates/REVIEW.template.md format with 4 parts:

PART A — Cross-consistency findings
Check internal consistency across v0.4 surface:
- roles/ ↔ AGENTS.md ↔ CLAUDE.md: permission and obligation alignment
- templates/*.template.md ↔ HARNESS §4.3 artifact-specific status enums
- scripts/ documented behavior ↔ HARNESS §5 call protocols
- phases/<phase>.md Exit criteria ↔ HARNESS §7 STATUS handoff ↔ §11 dispute blocking
- ADR-007 (§9 deprecation) ↔ HARNESS §9 deprecation patch ↔ phases/ taking over
- INBOX/README.md status enum ↔ AGENTS.md canonical enums ↔ templates/REVIEW status

PART B — New surface findings (look for NEW issues introduced by A.1-A.4)
- roles/   — completeness of responsibility/IO/constraints; permission matrix accuracy; anti-pattern coverage
- templates/ — missing fields, ambiguity, project-type independence, status enum correctness
- scripts/ — shell safety (set -euo pipefail), error handling, HC-7 secret exposure risks, portability (macOS bash, python 3.11+ tomllib), argument validation, edge cases in _codex_postprocess.py
- phases/  — measurability of Exit criteria, drift signal completeness, role assignment correctness, mode×phase approval matrix internal consistency with HARNESS §2/§3 and ADR-004

PART C — HC violations (forced severity: blocker if any)
- HC-7: secret/credential/PII leakage in scripts, logs, templates, or examples
- HC-8: unauthorized external mutation paths (push, deploy, third-party API write)
- HC-9: destructive operations without explicit user gate (rm, drop, force-push, branch -D, reset --hard)

PART D — Phase A overall verdict
- ready_for_v0.5_tag: can HARNESS.md be tagged v0.5 (Phase A final) after addressing this review? yes | yes_with_minor_fixes | no
- ready_for_phase_B: can Phase B (skills/) work begin? yes | yes_with_minor_fixes | no

OUTPUT FORMAT — strict adherence to templates/REVIEW.template.md. Front-matter first, then sections. Finding IDs MUST start at F16 (monotonic across rounds; prior rounds used F1-F15). Use canonical English enums (severity: blocker|major|minor|nit|info; status: open|resolved|deferred|disputed). HC-7/8/9 violations are severity: blocker by definition.

Example structure (fill in real content):

---
date: 2026-05-25
author: codex
severity: <highest finding severity>
target: Phase A integrated cross-review (harness v0.4)
status: open
review_round: A.5
prior_review: INBOX/processed/codex-feedback-20260525-v0.3-review.md
---

# Phase A Integrated Cross-Review (A.5)

## Summary
<one paragraph: overall impression + verdict signal>

## Part A — Cross-consistency findings

### Finding 16: <short title>
- severity: blocker | major | minor | nit | info
- target: <file:section-or-line>
- detail: <observation + reasoning>
- suggested_action: <concrete change>
- references: <files / ADR ids / prior finding IDs>

(continue numbering monotonically)

## Part B — New surface findings
(continued numbering)

## Part C — Security / HC violations
(forced blocker — if none, state that explicitly)

## Part D — Phase A verdict
- ready_for_v0.5_tag: ...
- ready_for_phase_B: ...
- new_blockers: <count>
- new_majors: <count>
- new_minors: <count>
- new_infos: <count>
- rationale: <one paragraph>

Make assumptions when needed, labeled "Assumption: ..." inside the relevant finding.
