---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: blocker
target: Hara v1.8 minimize + hook (HARNESS cut + .githooks/ + P0 fixes)
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e68c6-e4c9-72a2-84d0-19a769f86543
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 102423
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T09:32
  prompt_source: .harness/prompts/04-cross-review-v18-minimize-hook-r1.md
---

# Hara v1.8 Review

## Summary

v1.8 direction is right: HARNESS cut mostly preserved the load-bearing rules, and `PATTERNS.md` / `FLEET.md` anchors referenced from HARNESS do exist. But ship is not ready. The new hook layer overclaims enforcement: HC-11 says r1+r2 is mandatory, while `pre-push` accepts any one recent review file, and HC-6 can still be missed for this exact v1.8 patch because `STATUS.md` is stale and `pre-commit` passes.

## Findings

### Finding 1: HC-11 is not actually enforced by `pre-push`
- **severity**: blocker
- **target**: [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:44), [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:31)
- **detail**: HARNESS requires r1+r2 codex review for every ship-style commit, but the hook only checks whether at least one `.harness/reviews/*` file was added in the last 20 commits. I verified a temp repo with one `r1` review plus `harness(v1.8): ...`; `pre-push` returned `0`. This also allows unrelated old reviews to satisfy a new ship.
- **suggested_action**: Require two relevant review artifacts for the ship slug/version, e.g. `*-v18-*-r1.md` and `*-v18-*-r2.md`, or require machine-readable metadata linking review files to the ship commit/version.
- **references**: HC-11, B.3, E.1
- **capability_candidate**: no — direct hook correctness bug.

### Finding 2: v1.8 passes `pre-commit` while `STATUS.md` is still v1.7
- **severity**: blocker
- **target**: [.githooks/pre-commit](/Users/satgym/work/harness/.githooks/pre-commit:21), [STATUS.md](/Users/satgym/work/harness/STATUS.md:11)
- **detail**: The staged v1.8 patch passed `pre-commit` in a temp copy, but current `STATUS.md` still says starpin v0.6 / Hara v1.7 and has duplicated required-read sections. HC-6 says all work ends with STATUS updated, and HARNESS §10 requires STATUS update for harness changes. The hook only catches `RELEASE.md` edits.
- **suggested_action**: For ship-style commits, require `STATUS.md` staged, not only when `RELEASE.md` changes. At minimum, require it for `harness(...vN.N.N)` commits.
- **references**: HC-6, B.1, C.1, E.4
- **capability_candidate**: no — direct hook false negative.

### Finding 3: Capability candidate collector misses existing repo review format
- **severity**: major
- **target**: [.githooks/pre-commit](/Users/satgym/work/harness/.githooks/pre-commit:83)
- **detail**: Existing reviews use markdown like `- **capability_candidate**: yes — \`name\``, but the hook searches only `capability_candidate:\s*yes`. I staged a copy of `.harness/reviews/04-cross-review-20260527-v1.6-cleanup.md`; the hook created only the header and collected 0 candidates despite four `yes` findings.
- **suggested_action**: Accept bold markdown markers and inline candidate names, e.g. regex allowing `**capability_candidate**: yes` and extracting the first backticked slug after `yes`.
- **references**: B.7
- **capability_candidate**: yes — `capability-candidate-format-regression`, kind: `hook-test`.

### Finding 4: `pre-review-gate.sh` can select `.harness/` outside the git repo
- **severity**: major
- **target**: [scripts/pre-review-gate.sh](/Users/satgym/work/harness/scripts/pre-review-gate.sh:17)
- **detail**: `find_project_root()` walks above the git toplevel. In a temp repo nested under an outer directory with `.harness/`, the script selected the outer `.harness` root instead of the repo root. That can run the wrong gate or zero checks.
- **suggested_action**: Determine git toplevel first, then search for nearest `.harness/` only between `$PWD` and that toplevel. Allow escaping only via explicit `--root`.
- **references**: D.1
- **capability_candidate**: no — direct root-detection bug.

### Finding 5: HARNESS cut weakens two load-bearing rules
- **severity**: major
- **target**: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:30), [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:172)
- **detail**: Old HC-10 explicitly said base phase Exit authority always remains with base; new HC-10 omits that invariant. Old dispute protocol blocked both blocker and major disputes; new PATTERNS blocks only blocker disputes and allows major disputes to proceed with ADR/user confirmation. These are semantic cuts, not just reference extraction.
- **suggested_action**: Restore the base phase Exit authority sentence to HC-10 or PATTERNS §adaptive-layer, and either restore major dispute blocking or document the intentional policy change in ADR-013.
- **references**: A.1
- **capability_candidate**: no — governance text regression.

### Finding 6: CLAUDE read order drops INBOX from must-read
- **severity**: major
- **target**: [CLAUDE.md](/Users/satgym/work/harness/CLAUDE.md:5), [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:193)
- **detail**: AGENTS and the old entry flow require `INBOX/` at session start, but new CLAUDE must-read stops at items 1–4 and moves no equivalent INBOX check into the active path. That reintroduces the “only part of the harness is read” gap for codex feedback.
- **suggested_action**: Add `INBOX/` / `.harness/inbox/` unread check back to CLAUDE must-read, or make HARNESS §6’s three-question drift check explicitly include unread feedback.
- **references**: A.3
- **capability_candidate**: no.

### Finding 7: `codex-review.sh` early error still runs after the gate
- **severity**: minor
- **target**: [scripts/codex-review.sh](/Users/satgym/work/harness/scripts/codex-review.sh:113)
- **detail**: The CLI-incompatible `--base/--commit/--uncommitted + --prompt-file` check is after `pre-review-gate`. I verified it runs the gate first, then exits `4`.
- **suggested_action**: Move the incompatible-argument check immediately after argument parsing/source mutual exclusion.
- **references**: D.3
- **capability_candidate**: no.

### Finding 8: `codex-bundle-review.sh --help` reports the underlying script
- **severity**: nit
- **target**: [scripts/codex-bundle-review.sh](/Users/satgym/work/harness/scripts/codex-bundle-review.sh:31)
- **detail**: Because it directly execs `codex-exec-review.sh`, `--help` prints `codex-exec-review.sh`, not bundle-review usage.
- **suggested_action**: Intercept `-h|--help` in the alias and print the bundle wrapper’s own header.
- **references**: D.4
- **capability_candidate**: no.

## Overall verdict

- **new_blockers**: 2
- **new_majors**: 4
- **new_minors**: 1
- **new_infos**: 0
- **ready_for_ship**: no
- **recommendation**: patch-before-ship
- **rationale**: The minimization is broadly acceptable, but the core premise of v1.8 is “replace doc-only critical rules with hooks.” The two most important hook claims, HC-11 cadence and HC-6 freshness, currently have false positives/false negatives on the v1.8 ship path itself.

## Self-Test Notes

Temp-copy hook run against the staged v1.8 patch:
- `pre-commit`: pass
- `commit-msg` with `harness(v1.8): minimize + hook`: pass
- `pre-push`: pass, but only because the hook accepts any recent review file.

Other checks:
- Cross-reference anchors for `PATTERNS.md §front-matter`, `§drift`, `§adaptive-layer`, `§history` exist.
- CRLF frontmatter stripping did not reproduce as a bug; Python normalized newlines in the tested path.
- Hook install is configured in this clone: `core.hooksPath = .githooks`.

## Related artifacts read

- `HARNESS.md`, `PATTERNS.md`, `FLEET.md`, `CLAUDE.md`, `DECISIONS.md`, `STATUS.md`
- `.githooks/pre-commit`, `.githooks/commit-msg`, `.githooks/pre-push`
- `scripts/pre-review-gate.sh`, `_codex_postprocess.py`, `codex-review.sh`, `codex-bundle-review.sh`
- `templates/REVIEW.template.md`
- `.harness/reviews/06-20260527-meta-harness-usage-gap-r1.md`
