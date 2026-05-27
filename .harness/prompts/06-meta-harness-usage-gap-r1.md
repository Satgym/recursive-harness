You are doing a **harness self-review** — analyzing the Hara (Claude+Codex collaboration harness) for usage gaps + missing structure, NOT analyzing the starpin project that lives in `examples/starpin/`. starpin is mentioned only as *evidence of how the harness was actually used*.

## CONTEXT

This repo is the Hara harness itself (currently v1.7). It has been dogfooded on starpin (5 versions, v0.1 through v0.6) over the last few weeks. The most recent rounds are v0.5 (web-demo Fleet, 4 parallel children, 2 codex review rounds) and v0.6 (sequential — Python ingest worker + Node loader + ADR-002 Gate A closure, 2 codex review rounds).

## YOUR TASK — 5 questions, in order

### Q1 — Which harness structures were actually USED in v0.5 + v0.6?

Inspect git log + reviews to map usage:
- `scripts/codex-exec-review.sh` vs `scripts/codex-review.sh` — which one actually fires?
- `scripts/fleet/*.py` — which ones got invoked? Check the reviews + RELEASE.md files for evidence.
- `templates/*.md` — which got applied (REVIEW, MERGE-REPORT, SUBTREE-PROMPT)?
- `phases/*.md` — were the canonical phase docs read/followed, or did the work flow fluidly without explicit phase gates?
- `roles/*.md` — was any role explicitly invoked during reviews?
- `INBOX/` workflow — produce/process activity?
- `.harness/skills/` — which were *applied* (per skill enforcement) vs merely *mentioned*?
- `.harness/decisions/ADR-*` — which were referenced / amended?
- `.harness/capabilities.md` — was the discovery flow followed, or were capabilities picked ad-hoc?

Read:
- Last 5 commits (git log)
- `examples/starpin/RELEASE.md` (both v0.5 and v0.6 sections)
- `examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md` and `-r2.md`
- `examples/starpin/.harness/reviews/04-20260527-v06-ingest-r1.md` and `-r2.md`
- (those reviews are gitignored from the public repo but exist locally)

Report a table: `harness component → used in v0.5? → used in v0.6? → frequency → role played`.

### Q2 — Where did the harness FAIL to support the work?

Specifically look for:
- Wrapper scripts that broke vs current CLI tooling (codex CLI 0.132, ESLint v9, etc.)
- Templates that were re-derived because they don't exist
- Patterns repeated by hand that should be helpers
- Knowledge that didn't propagate (e.g., one child finds a bug, siblings rediscover the same)
- Findings that surfaced in codex but had no follow-through path (capability_candidate: yes hits — were any promoted?)
- Anything where Claude clearly worked around the harness instead of through it

Concrete file:line evidence required.

### Q3 — Which harness structures look DEAD (defined but never used in real dogfood)?

For each, decide: alive-but-undocumented vs truly-dead-deprecate vs needs-activation-tooling.

### Q4 — What NEW structures would close the gaps?

Propose 5-10 concrete additions. For each:
- Name
- Type (script, template, skill, ADR, doc)
- Trigger condition (when should it fire / be consulted)
- Owner agent (Claude / Codex / both)
- Estimated 1-round implementation cost (S/M/L)

### Q5 — What's the prioritization?

Rank the proposed additions: which should be done in the next "harness maturation" round, which are v1.8 carry, which are nice-to-have / discard.

## OUTPUT

Plain markdown report. Be concrete: file paths, line numbers, specific findings — not generic engineering platitudes. If you cannot find evidence for a claim, say so. Aim for a report that a future maintainer can act on directly without re-doing your investigation.

Length: as much as needed (this is a meta-review, comprehensive > terse).

## EXPLICIT NON-GOALS

- Do NOT review starpin's product correctness — that was done in 4 prior codex rounds.
- Do NOT propose changes to active code under `examples/starpin/backend/src/` or `ingest/`.
- The focus is the HARNESS scaffold: `HARNESS.md`, `phases/`, `scripts/`, `templates/`, `roles/`, `skills/`, `project-types/`, `.harness/`, the `INBOX/` workflow, the `DECISIONS.md` index.
