You are conducting r2 functional review of Hara v2.3.1 — verifying that the r1 codex blockers + major are closed.

## r1 findings → r2 patches

**Blocker #1** (postprocess strips inner FM verdict keys without merging):
→ `scripts/_codex_postprocess.py`:
  - Added `extract_canonical_verdict(raw_or_body)` helper that pulls
    `codex_pass / blocker_count / major_count / minor_count` from the codex's
    own front-matter using line-anchored regex.
  - `build_front_matter` calls it on the *body region* (sliced from raw between
    `\ncodex\n` marker and `\ntokens used\n` — avoids matching `---` separators
    in codex CLI metadata header) and appends the canonical verdict keys to the
    wrapper FM before the `codex_meta:` block.
  - Inner FM is still stripped by `_strip_leading_frontmatter` for body
    cleanliness; only the canonical verdict values are merged forward.

**Blocker #2** (body fallback `\b` accepts trailing prose):
→ `scripts/ui-visual-review.sh` `parse_review_field`:
  - bool fallback regex tightened to `^\s*key\s*:\s*(true|false)\s*$`
  - int fallback regex tightened to `^\s*key\s*:\s*(\d+)\s*$`
  - End-anchoring forces strict line-only — `"codex_pass: true. HC-13 ..."` is
    now rejected; codex (or coordinator) must emit clean YAML in either FM or
    body.

**Major #3** (`ui-codex-*` canonical copy round-suffix missing + codex round
hardcoded `r2`):
→ `scripts/ui-visual-review.sh`:
  - New `--review-round <r1|r2|r3|...>` flag, default `r1`.
  - `CODEX_REVIEW_OUT` now `ui-codex-<date>-<slug>-<round>.md`.
  - Inner `codex-exec-review.sh` invocation passes `--review-round` through.
  - File-glob lookup checks round-suffixed name first, falls back to legacy
    (no-suffix) for backward compat.

## YOUR REVIEW (r2)

### Section A — postprocess canonical merge

1. `extract_canonical_verdict` correctly handles:
   - Clean inner FM with all 4 keys → all merged?
   - Partial inner FM (e.g. only `codex_pass`) → just that key merged?
   - No inner FM (codex emitted body-only) → empty dict, wrapper unchanged?
   - Inner FM with trailing punctuation/comments → stripped correctly?
2. `body_region` slicing — what if `\ncodex\n` marker not found? what if
   `\ntokens used\n` missing (codex CLI changes)? Resilient or silent failure?
3. The merge order in `build_front_matter` — verdict keys appear between
   `prior_review` and `codex_meta:`. Is this a stable position for
   `ui-visual-review.sh`'s parser to read first-block FM?

### Section B — body fallback end-anchoring

1. `^\s*key\s*:\s*(true|false)\s*$` — does this still accept legitimate
   single-line FM-style entries that happen to be in body? Or does it require
   the line to be ONLY the key:value pair?
2. Edge cases: trailing whitespace (`true  `) — `\s*$` matches; trailing
   tab — same; trailing CR `\r` on Windows-style files — `\s` matches.
3. False rejection risk: legitimate `codex_pass: true` written as last line of
   a paragraph (no trailing newline) — `$` matches end-of-string with MULTILINE.

### Section C — round suffix path consistency

1. New `CODEX_REVIEW_OUT` path is round-aware. Does `ui-visual-review.sh`'s
   evidence-JSON patch step record this correct path?
2. The `evidence['ui_review']['codex_review']` value — does it now reflect the
   round-suffixed name? If r2 runs after r1, does evidence point to r2 file?
3. Backward compat: an old pre-v2.3.1 caller (no `--review-round`) gets
   default `r1` — does that break anything?

### Section D — regression sweep

1. Run the postprocess change against a real existing codex review (e.g.
   `harness-20260528-v231-r1.md` or `examples/starpin/.harness/reviews/
   ui-codex-20260528-telescope-features-smoke.md`). Does it still produce
   identical output for the body section, with verdict keys correctly
   appearing in wrapper FM?
2. Body fallback strict regex — does the existing manually-canonical-patched
   codex review files still pass parsing? (They have canonical FM so parser
   should hit FM path, not body fallback.)
3. Round suffix — re-running ui-visual-review.sh with `--review-round r1` then
   `--review-round r2` against same evidence — both files exist (r1 + r2)?

### Section E — Coverage of r1 issues

For each r1 finding, mark **closed / partial / open**:
- Finding 1 (postprocess strip without merge)
- Finding 2 (body fallback `\b` not strict)
- Finding 3 (canonical copy + codex round hardcoded)

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose. Do NOT write `codex_pass: true.` in body — parser will reject.
