---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.27 ISS passes — r2 post-3-finding patch
review_round: r2
prior_review: .harness/reviews/20260529-starpin-v027-iss-passes-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7345-16e2-7760-8a8d-ed206cbcd878
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 50026
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T10:26
  prompt_source: examples/starpin/.harness/prompts/v027-iss-passes-review-r2.md
---

**REVIEW**

- `severity: nit`  
  `위치`: [iss-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/iss-routes.ts:122), [DECISIONS.md](/Users/satgym/work/harness/DECISIONS.md:54)  
  `근거`: 구현은 `hours/max`를 clamp하지 않고 400으로 reject합니다. 그런데 상단 route 주석과 ADR에는 아직 “clamps/clamped” 표현이 남아 있습니다. r1의 doc mismatch가 일부만 정리된 상태입니다.  
  `제안`: “range-checks / rejects out-of-range”로 통일.

확인 결과:

1. Mid-pass: `riseMs = null` + `riseMs !== null` gate로 in-progress pass는 emit되지 않습니다. 반환되는 `rise_at`은 다음 실제 rise crossing입니다.
2. Empty observer: `/v1/iss/passes?lat=&lon=`은 `observer_required` 400으로 떨어지며 `(0,0)` silent observer가 아닙니다.
3. `max=1.5`: `Number.isInteger(max)`로 400 `invalid_max` 확인.
4. 새 behavioral edge는 못 찾았습니다. 남은 것은 위 문서/주석 nit입니다.

검증 실행:
- `npm --prefix examples/starpin/backend run build`: pass
- `npm --prefix examples/starpin/backend test -- --runTestsByPath ...`: 38 pass
- `npm --prefix examples/starpin/backend test -- --runInBand`: 506 pass / 3 skip / 0 fail

Verdict: `pass` with one non-blocking `nit`.
