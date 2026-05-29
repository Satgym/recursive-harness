---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.23 interest modal race fix + cache unit test
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7199-53a2-70b1-b770-508978b31e4b
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 95433
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T02:38
  prompt_source: examples/starpin/.harness/prompts/v023-race-fix-review.md
---

**Verdict: pass**

No blocking or major findings. The duplicate backend DELETE race is closed: `interests-modal.performRemove()` now issues exactly one server DELETE and then calls the synchronous cache-only helper at [interests-modal.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/interests-modal.ts:83). The only remaining frontend caller of full-cycle `removeInterest()` is the detail-page toggle at [sky-detail-page.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/sky-detail-page.ts:193), which does not pre-DELETE the server.

Notes:
- `removeInterest()` still preserves the intended full-cycle behavior: cache eviction via `removeInterestFromCacheOnly()`, then best-effort backend DELETE at [sky-highlight.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/sky-highlight.ts:186).
- The bare synchronous call in the modal is correct; there is no promise to discard.
- The focused Jest file passes locally: `4 passed`.
- Test coverage is sufficient for this ship. One useful future hardening would be a `fetch` spy asserting `removeInterestFromCacheOnly()` makes no backend call, since “cache-only” is the core race-fix contract.
- `@ts-nocheck` is acceptable as a scoped workaround given the existing public/lib tsconfig blocker and the recorded v2.8 carry.
