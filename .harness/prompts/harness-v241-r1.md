You are conducting r1 review of Hara v2.4.1 — `--mode=auto|impl|review` flag added to `scripts/check-subagent-prompt.sh`.

## Context

v2.4 (e4ba304) introduced 5-카테고리 lint enforcement. Dogfood revealed:
- 30+ existing harness review prompts + 25+ starpin prompts all FAIL 5/5 (correct — they're review prompts, not impl prompts)
- No way to mass-lint a prompt directory without false negatives
- Need to distinguish *impl* vs *review* prompts automatically

## v2.4.1 changes

`scripts/check-subagent-prompt.sh`:
1. New `--mode=auto|impl|review` flag (default `auto`)
2. `auto`: filename heuristic `*-impl.md` or `*-impl-r<N>.md` → impl mode, else review mode
3. `impl`: enforce 5/5 (current v2.4 behavior; explicit override forces impl on any filename)
4. `review`: skip lint, exit 0 with message (explicit override skips even on impl filename)

Self-test verified:
- impl prompt (`04-20260529-v019-friends-share-impl.md`) → auto → impl → PASS 5/5
- review prompt (`harness-v24-r1.md`) → auto → review → SKIP
- `--mode=impl` on review prompt → FAIL (override works)
- `--mode=review` on impl prompt → SKIP (override works)

## YOUR REVIEW (r1)

### Section A — heuristic
1. Regex `-impl(-r[0-9]+)?\.md$` matches `*-impl.md` and `*-impl-r1.md`/`*-impl-r2.md`. Edge: `*-implementation.md` filename — does NOT match (correct, that's not the convention). `*-impl-vN.md` — does NOT match.
2. Should the heuristic also recognize `*impl*` (substring) for stricter convention adherence? Or is `-impl` suffix enough?
3. What about prompts in nested dir like `examples/<proj>/.harness/prompts/04-v019-friends-share-impl.md` — basename match works?

### Section B — flag parsing
1. Both `--mode=value` AND `--mode value` accepted — bash parsing correct?
2. `--strict` order-independent with `--mode`? Verified by self-test? (current code: while loop accepts in any order)
3. Unknown flag → exit 3 (was 2 before, now 3 for "invalid mode"). Backward compat with callers?

### Section C — backward compat
1. Pre-v2.4.1 callers (no `--mode`) → default `auto` → impl filename → enforce (same as v2.4). Review filename → skip (changed: v2.4 would have failed). Acceptable?
2. PATTERNS §deliverable-categories 의 "v2.4 enforced" line 갱신 필요? — v2.4.1 promote 표현 (`auto` 가 review prompt 도 graceful 처리)

### Section D — Doc fidelity
1. Script header docstring + Usage line 갱신됨. PATTERNS / HARNESS 갱신 필요?
2. HC-11 r1+r2 review file 의무 — 본 v2.4.1 은 어떻게 처리? (harness(v2.4.1) ship 이면 r1+r2)

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose.
