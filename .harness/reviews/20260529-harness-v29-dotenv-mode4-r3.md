---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.9) dotenv + Mode 4 — r3 empty-edge fix
review_round: r3
prior_review: .harness/reviews/20260529-harness-v29-dotenv-mode4-r2.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e727d-456e-7990-bd08-c83481bfa07d
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 79496
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T06:47
  prompt_source: .harness/prompts/harness-v29-dotenv-subagent-mode4-review-r3.md
---

**REVIEW — verdict: `minor`**

Finding:

- `severity: minor`
- `위치`: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:111), [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:504)
- `근거`: r3 fixes the exact `CAPACITOR_SERVER_URL=` and `CAPACITOR_SERVER_URL=""` cases, and priority now aligns with the three-file `dotenv` loader. But the detector still uses `^CAPACITOR_SERVER_URL=`, while `dotenv` also accepts forms like `CAPACITOR_SERVER_URL =`, `export CAPACITOR_SERVER_URL=`, and `CAPACITOR_SERVER_URL= # disabled`. Those can still diverge from runtime first-set-wins behavior.
- `제안`: Use the same parser as runtime for detection, ideally `dotenv.parse(...)` with `hasOwnProperty('CAPACITOR_SERVER_URL')`, or at least broaden the grep/extraction regex and handle inline-empty comments.

Confirmations:

1. Exact empty/non-empty forms now match first-set-wins semantics: yes.
   Full `dotenv` grammar: not yet.
2. PATTERNS snippet is synced with the script, including the same limitation.
3. Final verdict: `minor`, not clear-pass.

Validation I ran: `bash -n examples/starpin/scripts/run-mobile-smoke.sh` clean, plus Node `dotenv.parse` spot checks for whitespace/export/comment forms.
