---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: major
target: Hara v1.8 r1 patches verification
review_round: r2
prior_review: .harness/reviews/04-20260527-v18-minimize-hook-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e68d0-c4ab-7c42-bf17-37691383e5f3
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 127661
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T09:42
  prompt_source: .harness/prompts/04-cross-review-v18-minimize-hook-r2.md
---

# Hara v1.8 r2 Review

## Summary

Most r1 closures hold, but ship is still not ready. Two r1 items remain unresolved enough to block: HC-11 is fixed for the single-ship happy path but still passes a multi-ship push when only one ship has r1+r2 evidence, and the capability collector still fails the requested extraction scenario with a Python traceback.

## r1 Closure Verification

### r1 #1 — pre-push HC-11 weak
- status: partial
- evidence: [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:81) uses global `found_r1=0; found_r2=0`; [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:95) passes once any slug has both.
- evidence: requested single-ship scenario passed: `harness(v1.8.0): ship` + `v18...r1` + `v18...r2` -> `exit=0`.
- evidence: requested only-r1 scenario failed: `r1 found: 1, r2 found: 0` -> `exit=1`.
- if partial/open: multi-ship push still false-passes. Repro: commits `harness(v1.8.0): ship` and `harness(v1.9.0): ship`, reviews only for `v18`, hook output: `OK — HC-11 r1+r2 evidence found (slug match: v18)`, `exit=0`. HC-11 says every ship-style commit needs r1+r2.

### r1 #2 — pre-commit STATUS narrow
- status: closed
- evidence: [.githooks/pre-commit](/Users/satgym/work/harness/.githooks/pre-commit:31) includes `HARNESS.md|DECISIONS.md|PATTERNS.md|FLEET.md|CLAUDE.md|AGENTS.md`.
- evidence: [.githooks/pre-commit](/Users/satgym/work/harness/.githooks/pre-commit:36) fails when governance or release changed and no `STATUS.md`.
- evidence: HARNESS without STATUS -> `exit=1`; HARNESS + STATUS -> `exit=0`; pure `scripts/` change -> `exit=0`.

### r1 #3 — capability collector regex narrow
- status: open
- evidence: [.githooks/pre-commit](/Users/satgym/work/harness/.githooks/pre-commit:91) has the widened markdown regex.
- evidence: [.githooks/pre-commit](/Users/satgym/work/harness/.githooks/pre-commit:111) calls `src_path.relative_to(pathlib.Path.cwd())`.
- evidence: staging `.harness/reviews/04-cross-review-20260527-v1.6-cleanup.md` produced `ValueError: '.harness/reviews/...' is not in the subpath of '/private/tmp/...'`; candidates file stayed header-only.
- if partial/open: use a safe display path for relative git paths, fail or warn deterministically on collector errors, and anchor/word-bound the marker to avoid collecting quoted examples after this traceback is fixed.

### r1 #4 — pre-review-gate root walks above git toplevel
- status: closed
- evidence: [scripts/pre-review-gate.sh](/Users/satgym/work/harness/scripts/pre-review-gate.sh:22) reads `git rev-parse --show-toplevel`; [scripts/pre-review-gate.sh](/Users/satgym/work/harness/scripts/pre-review-gate.sh:26) stops at toplevel.
- evidence: nested temp repo under outer `.harness/` selected inner repo root: `[gate] root: .../outer/inner`.
- evidence: outside git fallback: no `.harness` -> current directory; with ancestor `.harness` -> nearest ancestor.

### r1 #5 — HARNESS cut weakened HC-10 + dispute
- status: closed
- evidence: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:30) restores `base phase Exit 기준의 결정 권한은 항상 base에 있음`.
- evidence: [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:173) blocks `blocker` or `major` disputed findings from phase progress.

### r1 #6 — CLAUDE.md dropped INBOX
- status: closed
- evidence: [CLAUDE.md](/Users/satgym/work/harness/CLAUDE.md:10) lists `ls INBOX/` and project `.harness/inbox/` as step 4.

### r1 #7 — codex-review.sh early-error after gate
- status: closed
- evidence: [scripts/codex-review.sh](/Users/satgym/work/harness/scripts/codex-review.sh:113) places the CLI incompatibility block before the gate at [scripts/codex-review.sh](/Users/satgym/work/harness/scripts/codex-review.sh:131).
- evidence: `scripts/codex-review.sh --uncommitted --prompt-file /tmp/x` exited `4` with only the argument error and no gate output.

### r1 #8 — codex-bundle-review.sh --help shows wrong script
- status: closed
- evidence: [scripts/codex-bundle-review.sh](/Users/satgym/work/harness/scripts/codex-bundle-review.sh:33) intercepts `-h|--help`.
- evidence: help output begins `codex-bundle-review.sh — Wrapper for codex review on a bundle of files`.

## Findings

No new numbered findings beyond the residual r1 #1 and r1 #3 failures.

## Regression Scan

- Broader STATUS rule: acceptable trade-off for core governance files; pure `scripts/` changes do not over-fire.
- HC-11 fuzzy slug: `harness(test-stuff-v1.0.0)` did not match unrelated `v10` reviews because scoped slugs include `test-stuff-`.
- pre-review-gate outside git: fallback is current directory or nearest `.harness`; no regression found.
- capability collector false positives: still a risk because the regex is unanchored, but current extraction fails earlier with the `relative_to` exception.

## Overall verdict

- r1_closed: 6
- r1_partial: 1
- r1_open: 1
- new_blockers: 0
- new_majors: 0
- new_minors: 0
- ready_for_ship: no
- recommendation: patch-before-ship

Verification also run: `/bin/bash -n` on patched hooks/scripts, `python3 -m py_compile scripts/_codex_postprocess.py`, and `scripts/pre-review-gate.sh --allow-no-checks`; all passed.
