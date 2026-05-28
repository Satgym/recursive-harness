You are conducting r2 review of Hara v2.4.1 — verifying r1 1 major + 1 minor closures.

## r1 findings → r2 patches

**Major** (bare `--mode` infinite loop — `shift 2` silently fails):
→ `scripts/check-subagent-prompt.sh:41` `--mode` branch:
  - Validate `$# -ge 2` AND `${2:-}` non-empty AND `${2:0:1} != "-"` before shift
  - If invalid → echo error + exit 3 (matches "invalid mode" exit class)
  - Verified: `bash check-subagent-prompt.sh --mode` → exit 3 in <1s (was hang)
  - Verified: `bash check-subagent-prompt.sh --mode --strict <file>` → exit 3 (next arg is flag)

**Minor** (docstring drift — `*-impl*.md` substring vs actual `-impl(-r<N>)?\.md$` suffix):
→ `scripts/check-subagent-prompt.sh` header docs (around line 30):
  - Mode `auto` description rewritten: "suffix `-impl.md` or `-impl-r<N>.md` → impl mode, else review mode. Substring like `*impl*.md` NOT matched — strict suffix prevents drift (`-implementation.md` stays review)"
  - inline comment at the auto branch updated to match (suffix-only language)

## YOUR REVIEW (r2)

### Section A — bare --mode closure
1. New validation `$# -lt 2 || -z "${2:-}" || "${2:0:1}" == "-"` 정확? edge cases:
   - `--mode` alone (no further args) — caught?
   - `--mode --strict file.md` — caught (next is flag)?
   - `--mode "" file.md` (empty string) — caught (`-z` check)?
   - `--mode auto file.md` — passes through correctly?
2. Exit code 3 matches "invalid mode" semantics? Or should it be a different code (e.g. 2 like "missing arg")?

### Section B — docstring suffix clarity
1. New mode `auto` description in header — clear about *suffix* convention?
2. Inline comment near auto branch — matches header doc?
3. Anyone reading PATTERNS.md §deliverable-categories vs script header — consistent terminology (suffix vs substring)?

### Section C — Regression sweep
1. self-test pass (impl prompt PASS, review prompt SKIP, --mode impl override force-enforce, --mode review override skip) — verified before r2?
2. New error path (`bare --mode → exit 3`) — affect any existing caller? (PATTERNS doesn't yet show callers using `--mode` without value, so OK)

### Section D — HC-11 readiness
1. v2.4.1 ship 시 r1+r2 review file 의무 — 본 r2 가 그 두 번째. file naming `harness-20260529-v241-r2.md` correct.

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose.
