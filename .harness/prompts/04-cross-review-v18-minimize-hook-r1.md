You are reviewing **Hara v1.8 — minimize + hook**, the harness self-maturation round triggered by the meta-review codex finding `.harness/reviews/06-20260527-meta-harness-usage-gap-r1.md`.

## Context

v0.5 + v0.6 dogfood showed ~60% of the harness was spec-only / bypassed. Adding more structure would worsen that. v1.8 instead:
- CUT HARNESS.md 559 → 185 lines (must-read), split reference content into PATTERNS.md / FLEET.md
- ADD git hooks (.githooks/) that enforce HC-6 (status freshness), HC-11 (codex cadence), WIP residue, capability-candidates auto-collect
- FIX 3 P0 bugs (pre-review-gate root, postprocess double-frontmatter, codex-review.sh CLI 0.132 incompat)

## Artifacts under review

**Hard rule + governance**:
- `HARNESS.md` (rewritten 559→185)
- `PATTERNS.md` (NEW — reference content extracted)
- `FLEET.md` (NEW — Fleet Mode details extracted)
- `CLAUDE.md` (updated read order)
- `DECISIONS.md` ADR-013 (v1.8 minimize+hook rationale)

**Hooks (NEW)**:
- `.githooks/pre-commit` — STATUS freshness + capability_candidates auto-collect
- `.githooks/commit-msg` — WIP residue block on ship-style commits
- `.githooks/pre-push` — codex review evidence required for ship-style commits
- `.githooks/README.md` — install + bypass policy

**P0 bug fixes (Wave 1)**:
- `scripts/pre-review-gate.sh` — nearest `.harness/` ancestor + `--root` flag (was: git toplevel, monorepo-hostile)
- `scripts/_codex_postprocess.py` — `_strip_leading_frontmatter` helper (was: duplicate YAML blocks in saved reviews)
- `scripts/codex-review.sh` — early-error when `--uncommitted/--commit/--base` combined with `--prompt-file` (codex CLI 0.132+ rejects this combo)
- `scripts/codex-bundle-review.sh` (NEW) — alias for `codex-exec-review.sh`; formalizes the bundle-review path that v0.5/v0.6 actually used

**NOT under review**:
- `examples/starpin/**` (gitignored, prior dogfood)
- Existing `phases/` `roles/` `templates/` `skills/` directories — full audit deferred to v1.9 (ADR-013 §"후속")
- `scripts/fleet/*.py` (covered by v1.7 reviews)

## YOUR REVIEW — section by section

### PART A — HARNESS.md cut correctness

A.1 **Information loss** — verify that every truly load-bearing rule from old HARNESS.md v1.7 is present in either new HARNESS.md v1.8 or PATTERNS.md/FLEET.md. Specifically: HC-1 through HC-10, the 7 phases, artifact locations, codex protocol channels, drift signals, postmortem triggers, dispute resolution, HC-10 invariants. Flag any genuine cut.

A.2 **HC-11 introduction** — new constraint requires r1+r2 codex review for ship commits, enforced by pre-push hook. Is this calibrated correctly? Does v0.5/v0.6 dogfood data actually require *two* rounds (or was one round enough sometimes)?

A.3 **Reading order in CLAUDE.md** — does the new order (HARNESS → STATUS → DECISIONS → project-specific → PATTERNS/FLEET on-demand) close the loop the meta-review identified (only ~40% read)?

A.4 **Cross-references** — HARNESS.md references PATTERNS.md and FLEET.md by section anchor. Are those anchors actually present in those files?

### PART B — Hook safety + correctness

B.1 **pre-commit STATUS freshness rule** — only fires when `RELEASE.md` is among staged files. Catches the v0.6 r2 #21 pattern (forgot STATUS update). Any false-positive: e.g., RELEASE.md typo fix shouldn't require STATUS update — does the hook handle this? Currently it doesn't differentiate.

B.2 **commit-msg WIP residue** — fires for `code|harness|note(...vN.N.N)` only. What about ship via `release(...)` or version tags that don't match the regex? Bypass risk?

B.3 **pre-push codex evidence** — checks "last 20 commits" for review file additions. Edge case: cherry-pick / rebase that introduces ship commit but the review file was added 25 commits ago in original branch. Hook fails — is that acceptable?

B.4 **Hook bypass** — `--no-verify` allowed. Claude told not to use without user approval. Realistic? Should hooks fail-closed even with --no-verify in certain catastrophic cases (e.g., commits containing API keys)?

B.5 **Install adoption** — `git config core.hooksPath .githooks` is one-time per clone but easy to forget. Should HARNESS.md / CLAUDE.md surface a session-start check (`git config --get core.hooksPath` returns `.githooks` or warn)?

B.6 **Hook portability** — bash + python3. Confirmed working on macOS (dogfood). Will the python3-embedded heredoc in pre-commit work on Windows git bash? on alpine images?

B.7 **capability-candidates collector** — extracts `capability_candidate: yes` plus nearest `### Finding` heading and optional `candidate_name`. Does the extraction correctly handle the v0.5 / v0.6 review formats already in the repo? (Test: run the hook against existing files and verify count.)

### PART C — Hooks vs documentation

C.1 **Did hooks actually replace doc-only rules?** — for each hook, is there a corresponding HARNESS.md rule that's now downgraded? Verify the HC-6 / HC-11 wording explicitly says "hook enforces this".

C.2 **Hook escape valves** — pre-push fails on missing review evidence. Genuine release-hotfix may need to skip codex review. Is `--no-verify` the only escape, and is that documented?

### PART D — P0 bug fix correctness

D.1 **pre-review-gate.sh root detection** — `find_project_root()` walks up looking for `.harness/`. Edge case: `.harness/` exists outside the repo (e.g., user's `~/work/.harness`). Test path tries to escape git root?

D.2 **_codex_postprocess.py `_strip_leading_frontmatter`** — what if codex emits the frontmatter with `\r\n` line endings (Windows codex CLI)? regex uses `\n---\n` literal. Could fail.

D.3 **codex-review.sh early-error path** — the new check fires after pre-review-gate. If pre-review-gate is slow (full test suite), user waits N seconds for an immediate error. Should the check move before pre-review-gate?

D.4 **codex-bundle-review.sh aliasing** — `exec "$SCRIPT_DIR/codex-exec-review.sh" "$@"` passes args through. Does `--help` correctly report `codex-bundle-review.sh` or fall through to `codex-exec-review.sh`?

### PART E — Cross-cutting

E.1 **HC-11 calibration** — for tiny changes (typo fix), is r1+r2 codex obligation overkill? Define what counts as "ship-style" vs "internal".

E.2 **ADR-013 references** — does the ADR cite the meta-review file path? Does it list the v1.9 carry-over items concretely so they don't get lost?

E.3 **Anything from the meta-review that should have been done in v1.8 but was deferred** — codex meta-review proposed 10 structures; v1.8 implemented 4 (hooks) + 3 (P0 fixes) + 3 (rewrite). Are any of the 6 deferred items actually urgent (i.e., bugs masking as features)?

E.4 **Self-test (most important)** — run the hooks against the v1.8 commit itself. Does the v1.8 ship commit pass its own pre-commit / commit-msg / pre-push?

## Output

REVIEW.template.md format. Severity: blocker / major / minor / nit. HC-7/8/9/11 violations are blocker by definition. Final verdict: ready_for_ship (yes/no) + recommendation (ship / patch-before-ship).
