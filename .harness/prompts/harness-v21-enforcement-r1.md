You are reviewing **Hara v2.1 — enforcement gap pass (ADR-022)**. Harness self-change; HC-11 r1+r2 required.

## Context

User-requested audit (2026-05-28) of base + project-local harness revealed 3 enforcement gaps + 1 documentation theater. v2.1 closes all 4 in a single ship. Memory: `feedback_harness_minimalism` direction applies (trim over append; hook-enforce over documentation).

## Changes under review

Single uncommitted diff:

- `.githooks/pre-push`: HC-11 slug matching logic rewritten.
  - Before: scope+version concatenated (e.g. `harness-v2.0.0`) used as filename substring → false negatives when reviewer's natural slug differs (e.g. `harness-20260527-v20-trim.md`).
  - After: scope (`harness`/`starpin`/...) and version (`vN.N.N` + compressed `vNNN` + short `vNN`) matched *independently*. Bare round-suffix-less file counts as r1 (matches starpin convention since v0.7).
  - Validation: `git push --dry-run` for v2.0.0 commit — before FAIL, after PASS.

- `scripts/pre-review-gate.sh`: monorepo subdir discovery (F42 close from v1.2 era).
  - Before: ROOT has `.harness/` but project package lives in `<sub>/package.json` → "0 checks attempted FAIL" → all night codex calls used `--no-gate`.
  - After: discover JS/Python project markers at depth-1 subdirs (skip node_modules/.venv/.git) and run tooling per-subdir.
  - Validation: from `examples/starpin/`, gate now reports `PASS: backend npm lint/typecheck/test` (3 checks).

- `HARNESS.md`:
  - Preamble bumped to v2.1.
  - HC-6 row gains a `Scope:` clause clarifying root STATUS is hook-enforced but project-local `.harness/status.md` is the sub-project's own concern. starpin/.harness/status.md staleness during night work was a silent design assumption; this makes it explicit.
  - §6 "3-question self-check" deleted. Replaced with inline note documenting why (10+ ship invocation count = 0). Cross-link to PATTERNS.md §drift retained.
  - §11 version history table gains v2.1 row.

- `DECISIONS.md`: ADR-022 added at the top.

- `STATUS.md`: Active gate + Recent ships updated for v2.1 prep.

## YOUR REVIEW

Apply harness-minimalism. Skip cosmetic issues.

### PART A — Hook correctness

A.1 **pre-push slug matching**: walk through `harness(v2.0.0)` case end-to-end with the new logic. variants = {primary `v2.0.0`, version `v2.0.0`, compressed `v200`, short `v20`}. scope = `""` (no `-v` separator). Files in last 30 commits include `.harness/reviews/harness-20260527-v20-trim.md` (bare → r1) and `harness-20260527-v20-trim-r2.md` (`r2` suffix). Both contain `v20`. Should pass. Verify the scope_ok logic doesn't accidentally block when scope is empty.

A.2 **False-positive risk**: scope `harness` ship at version `v2.0.0` — could a starpin review file `04-...-starpin-v20.md` falsely satisfy this? The scope_ok branch requires the scope token in filename when matching by bare version. With scope="" (the v2.0.0 case), scope_ok skips → any file containing `v20` would count. Is that acceptable? Consider whether to require scope to be non-empty when matching by version-only variants.

A.3 **r1 default-round inference**: filename with `r3`/`r4`/...  also bucketed as r2. Acceptable — the rule is "at least one round-2-or-later exists". Verify the regex `r[2-9]` handles the realistic round counts.

A.4 **multi-ship push** (e.g. push containing both `harness(v2.0.0)` and `harness(v2.1.0)`): per-ship counters reset each iteration. Confirm.

### PART B — pre-review-gate correctness

B.1 **subdir discovery**: `find . -mindepth 2 -maxdepth 2 -name package.json` correctly excludes node_modules via `-not -path '*/node_modules/*'`. What about deeper node_modules in monorepo packages? Confirm depth-2 is sufficient for the starpin layout and the common monorepo (root + 1 level of packages).

B.2 **attempted counter from subshell**: the original v1.9 logic ran checks directly in the gate script's shell so `attempt` and `ok` were updated in-place. The new v2.1 logic uses `( cd "$d" && ... )` subshells but `attempt`/`pass`/`fail` are called *outside* the subshell. Verify `attempted` counter still increments correctly.

B.3 **Python sed compatibility**: `sed -E -e 's|/pyproject\.toml$||' -e 's|/setup\.py$||'` — verify portable across BSD (macOS) and GNU.

### PART C — HARNESS edits

C.1 HC-6 carveout wording: clear that root enforcement vs project-local responsibility is intentional. Doesn't accidentally weaken HC-6.
C.2 §6 deletion: PATTERNS.md §drift still contains the drift signals + procedure (verify with grep). The inline rationale for the cut is appropriate (helps future Claude understand why §6 is short).
C.3 §11 row added; no row removed.

### PART D — Scope creep check

D.1 ADR-022 fact-density: not self-congratulation; concrete diffs and validation evidence.
D.2 v2.0 trim discipline preserved: did v2.1 add net bloat? Estimate line-count delta across HARNESS/PATTERNS/STATUS/DECISIONS.

## Verdict

**ship | block | minor-followup**.
