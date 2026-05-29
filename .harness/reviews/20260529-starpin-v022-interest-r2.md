---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.22 interest watchlist — r2 post-patch
review_round: r2
prior_review: .harness/reviews/20260529-starpin-v022-interest-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7166-e38a-7301-a0f1-8cdb287afa08
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 103778
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T01:43
  prompt_source: examples/starpin/.harness/prompts/v022-interest-watchlist-review-r2.md
---

**REVIEW**

Findings:

- `severity: minor`  
  `위치`: [interests-modal.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/interests-modal.ts:80), [sky-highlight.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/sky-highlight.ts:186)  
  `근거`: cache eviction itself is now correct for both 200 and 404 paths: `removeInterest()` writes the cache synchronously before its backend call. Remaining issue: modal first DELETEs server, then calls `removeInterest()`, which fires a second best-effort DELETE. A same-object re-add from another tab/detail surface before that second DELETE lands could be deleted by the late duplicate request.  
  `제안`: split a pure cache eviction helper, or add an option like `removeInterest(objectId, { persist: false })` for the modal’s post-server-delete path.

- `severity: minor`  
  `위치`: [impl review](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260529-v022-interest-watchlist-impl.md:54), [today-search-smoke.yaml](/Users/satgym/work/harness/examples/starpin/tests/mobile/flows/today-search-smoke.yaml:146)  
  `근거`: the later notes correctly explain Enter substitution and ngrok stale assets, but the top summary still says “result-row tap re-introduced” and “modal PNG”, while the YAML uses `pressKey: Enter` and stops at dropdown visibility. YAML comments also imply modal-level coverage is validated by Jest, but the listed 47 tests are backend/routes/highlights, not `interests-modal` frontend behavior.  
  `제안`: update the summary to “Enter deterministic path” and “profile dropdown interest item only”; keep modal empty-state and direct touch as v0.23 carry.

A. Cache invalidation: fixed functionally for 200/404 cache eviction, with the narrow duplicate-DELETE race above.

B. FK/CASCADE: `ON DELETE CASCADE` is appropriate for a user-owned watchlist. `SET NULL` would not fit the `(user_id, object_id)` PK/ownership model.

C. Evidence path: clarified in the later notes, but not consistently corrected in the summary/YAML comments.

D. New concerns: only the duplicate DELETE race and small doc/schema drift; [repository.ts](/Users/satgym/work/harness/examples/starpin/backend/src/interests/repository.ts:4) still says `user_id text`.

E. `verdict: minor`  
The r1 major user-visible cache bug is closed, and the backend FK fix is sound. Remaining issues are patch hygiene/evidence accuracy plus a narrow concurrency race introduced by using a server-mutating API as a cache eviction helper.

Verification run: `npm --prefix backend run build` passed; targeted 47 interest/highlight tests passed.
