---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.23 race fix — r2 HC-11 confirmation pass
review_round: r2
prior_review: .harness/reviews/20260529-starpin-v023-race-fix-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e719b-e722-76e2-a51f-c753d5c20c7d
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 95476
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T02:41
  prompt_source: examples/starpin/.harness/prompts/v023-race-fix-review-r2.md
---

pass

r2 confirmation is written to [.harness/reviews/20260529-starpin-v023-race-fix-r2.md](/Users/satgym/work/harness/.harness/reviews/20260529-starpin-v023-race-fix-r2.md).

Confirmed:
- No new commits since r1; HEAD remains `3556939`.
- Scoped files’ mtimes predate r1 and current SHA-256s are recorded in the r2 review.
- Modal path now does exactly one backend DELETE plus cache-only eviction.
- Remaining full-cycle `removeInterest` frontend caller is detail-page, which does not pre-DELETE.
- Build passes.
- Full backend tests pass: `435 passed / 3 skipped / 0 failed`.

The fetch-spy hardening remains a non-blocking v0.24 carry. Ship can proceed.
diff --git a/.harness/reviews/20260529-starpin-v023-race-fix-r2.md b/.harness/reviews/20260529-starpin-v023-race-fix-r2.md
new file mode 100644
index 0000000000000000000000000000000000000000..bf321d65e81d420ff2ca1dbda61465a2304ee73d
--- /dev/null
+++ b/.harness/reviews/20260529-starpin-v023-race-fix-r2.md
@@ -0,0 +1,41 @@
+---
+artifact: review
+date: 2026-05-29
+author: codex
+status: open
+severity: info
+target: starpin v0.23 interest modal race fix confirmation
+review_round: r2
+---
+
+**Verdict: pass**
+
+No findings. r1 still holds and no source patch was needed between r1 and r2.
+
+## Confirmation
+
+- No new commits since r1: current HEAD remains `3556939 harness(v2.7): smoke script CAPACITOR_SERVER_URL trap detection (ADR-043)`.
+- Root working tree drift is limited to existing metadata/review artifacts (`STATUS.md`, `DECISIONS.md`, review files). The three scoped source/test files are outside the root tracked index, and their mtimes all predate the r1 review artifact:
+  - `.harness/reviews/20260529-starpin-v023-race-fix-r1.md`: `2026-05-29 11:41:09 +0900`
+  - `examples/starpin/backend/public/lib/sky-highlight.ts`: `2026-05-29 11:33:59 +0900`
+  - `examples/starpin/backend/public/lib/interests-modal.ts`: `2026-05-29 11:34:23 +0900`
+  - `examples/starpin/backend/tests/unit/web/sky-highlight-cache-only.test.ts`: `2026-05-29 11:36:24 +0900`
+- Current SHA-256s for the scoped files:
+  - `35e78959603456c05f3fe24de126b88bbd55de4330135e0188a471d4aaab12e5` `examples/starpin/backend/public/lib/sky-highlight.ts`
+  - `47cd4460586149f2d790ae3c94263283443dcdfe189811e824c4ff5f9bd21c1b` `examples/starpin/backend/public/lib/interests-modal.ts`
+  - `8e12277f09be88728f0139873ee6df059007f541691557204551a28dcefce44d` `examples/starpin/backend/tests/unit/web/sky-highlight-cache-only.test.ts`
+
+## Race Reasoning
+
+The split still closes the duplicate-DELETE race:
+
+- `interests-modal.performRemove()` sends one backend `DELETE /v1/interests/:id`, then calls synchronous `removeInterestFromCacheOnly(objectId)` on success or 404. That helper only evicts cache; it has no `apiCall`.
+- `removeInterest(objectId)` remains the full-cycle helper: cache eviction via `removeInterestFromCacheOnly`, then best-effort backend `DELETE`.
+- Search confirms the remaining frontend full-cycle caller is `sky-detail-page.ts` (`removeInterest as removeHighlightInterest` in the detail toggle). That caller does not pre-DELETE the server, so the full-cycle helper is still the correct behavior there.
+
+## Validation
+
+- `npm --prefix examples/starpin/backend run build`: pass.
+- `npm --prefix examples/starpin/backend test`: pass, 42 suites, 435 passed / 3 skipped / 0 failed.
+
+The r1 future-hardening note remains a good v0.24 carry: add a fetch spy asserting `removeInterestFromCacheOnly()` makes no backend call. It is not blocking this ship.
