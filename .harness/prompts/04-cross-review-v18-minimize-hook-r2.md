You are running **codex r2** on Hara v1.8 minimize+hook. r1 produced 8 findings (2 blocker / 4 major / 1 minor / 1 nit). Prior review: `.harness/reviews/04-20260527-v18-minimize-hook-r1.md`.

## Mode + scope

- autonomous; HC-7/8/9/11 + ADR change always gated
- Same files as r1 + STATUS.md (was stale at r1, now updated)
- All r1 patches applied — re-verify each closure + regression scan

## r1 findings — re-verify each

For EACH of 8 findings output:
```
### r1 #<N> — <title>
- status: closed | partial | open
- evidence: file:line + snippet
- if partial/open: what's still missing
```

**r1 #1 (blocker) — pre-push HC-11 weak**
- Patch: `.githooks/pre-push` now extracts ship slugs from each ship-style commit, generates compressed variants (v1.8.0 → v18), then requires *both* a `*r1*` AND `*r2*` review file whose name contains one of the slugs, within the last 30 commits. Portable to macOS bash 3.2 (no `mapfile`).
- Verify: real test scenario — `harness(v1.8.0): ship` + r1+r2 review files matching `*v18*r1*` and `*v18*r2*` → PASS. Same + only r1 → FAIL.

**r1 #2 (blocker) — pre-commit STATUS narrow**
- Patch: `.githooks/pre-commit` Rule 1 now fires when STATUS.md is not staged *and* either RELEASE.md is staged OR any core governance file changed (`HARNESS.md / DECISIONS.md / PATTERNS.md / FLEET.md / CLAUDE.md / AGENTS.md`). scripts/.githooks/phases/templates excluded to avoid over-firing on small fixes.
- Verify: HARNESS.md change without STATUS → FAIL. HARNESS + STATUS → PASS. Pure scripts/ change → PASS (intentional).

**r1 #3 (major) — capability collector regex narrow**
- Patch: pre-commit python heredoc regex now matches `(?:\*\*)?capability_candidate(?:\*\*)?\s*:\s*yes` + extracts inline backticked name after `yes` OR scans next 8 lines for `candidate_name:` or backticked slug.
- Verify: stage `.harness/reviews/04-cross-review-20260527-v1.6-cleanup.md` (which uses bold markdown markers) → hook should now extract candidates.

**r1 #4 (major) — pre-review-gate root walks above git toplevel**
- Patch: `scripts/pre-review-gate.sh::find_project_root` first reads `git rev-parse --show-toplevel`, then walks up looking for `.harness/` but STOPS at toplevel.
- Verify: in a temp repo nested under a dir with `.harness/`, the script picks the inner repo root, not the outer dir.

**r1 #5 (major) — HARNESS cut weakened HC-10 + dispute**
- Patch: HC-10 restored the "base phase Exit 기준의 결정 권한은 항상 base에 있음" sentence. PATTERNS.md §dispute restored blocking for both `blocker` AND `major` disputes (only `minor/nit` allowed to proceed with ADR).
- Verify: read HARNESS.md HC-10 + PATTERNS.md §dispute — sentences present.

**r1 #6 (major) — CLAUDE.md dropped INBOX**
- Patch: CLAUDE.md must-read re-added `ls INBOX/` (and `ls .harness/inbox/` for project work) as step 4.
- Verify: CLAUDE.md §"세션 시작 시 읽을 순서" lists INBOX.

**r1 #7 (minor) — codex-review.sh early-error after gate**
- Patch: early-error block moved before pre-review-gate invocation. Now fires immediately on bad arg combo, doesn't wait for gate.
- Verify: `scripts/codex-review.sh --uncommitted --prompt-file /tmp/x` (when /tmp/x exists) exits 4 *without* running gate.

**r1 #8 (nit) — codex-bundle-review.sh --help shows wrong script**
- Patch: bundle-review intercepts `-h|--help` and prints its own banner before delegating.
- Verify: `scripts/codex-bundle-review.sh --help` shows bundle-wrapper text, not codex-exec-review.sh text.

## Regression scan

Scan ONLY for new issues introduced by r1 patches:
- Does the broader STATUS rule (HARNESS.md change → STATUS staged) over-fire on legitimate single-file doc tweaks (e.g., typo in HARNESS.md)? Acceptable trade-off?
- HC-11 pre-push fuzzy slug matching: could a commit `harness(test-stuff-v1.0.0)` accidentally match an unrelated `04-...v10...r1.md` review? Edge case.
- pre-review-gate now stops at git toplevel — what if the user runs it OUTSIDE a git repo? Current fallback?
- capability collector now matches `**` markdown but does it correctly skip false positives where `yes` appears in a non-marker context (e.g., "yes" in a sentence)?

## Output

REVIEW.template.md format. Numbering continues from r1 (so new findings start at 9). Final verdict:
- r1_closed / r1_partial / r1_open counts
- new_blockers / new_majors / new_minors
- ready_for_ship: yes | no
- recommendation: ship | patch-before-ship
