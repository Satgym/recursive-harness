---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: <see body>
target: Hara v2.1 r2 verify
review_round: r2
prior_review: .harness/reviews/harness-20260528-v21-enforcement.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e6bcc-e4d8-7033-8467-6e6e67c24a96
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 93445
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T23:37
  prompt_source: .harness/prompts/harness-v21-enforcement-r2.md
---

**Verdict: ship**

No blocking findings.

`harness(v2.0.0)` closure works:
- Real files `harness-20260527-v20-trim.md` + `harness-20260527-v20-trim-r2.md`: `scope=harness`, `variant=v20`, `scope_ok=1`, buckets `r1=1 r2=1`.
- Adversarial `04-fp-starpin-v20.md` + `-r2`: `scope=harness`, `variant=v20`, `scope_ok=0`, buckets `r1=0 r2=0`.

`note(starpin-v0.11.0)` remains exempt. The hook trigger is still `^(code|harness)\(...vN.N.N...)` at [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:26), so `note(...)` is not brought into HC-11 file-presence enforcement.

`code(starpin-v0.6.0)` detail:
- `primary=starpin-v0.6.0`
- `scope=starpin`
- `version=v0.6.0`
- variants include `starpin-v0.6.0`, `v0.6.0`, `v060`, `v06`
- For bare version variants like `v06`, the filename must also contain `starpin`.

So `04-20260527-v06-ingest-r2.md` alone does **not** match. `04-20260527-starpin-v06-ingest-r2.md` does. It does not need the full `starpin-v0.6.0` substring, but it does need both scope and version somewhere in the filename.

Other r1 closures re-confirmed:
- `scripts/pre-review-gate.sh --root examples/starpin` passes: backend lint/typecheck/test, 288 tests passed.
- HARNESS v2.1 edits preserve HC-6 carveout, remove §6 theater text with rationale, and add ADR-022 to version history.
- ADR-022 is dense enough for the enforcement change and validation evidence. Minor wording drift only: the ADR/comment phrase about “scope empty” is now mostly historical because the fallback makes code/harness scoped. Not ship-blocking.
