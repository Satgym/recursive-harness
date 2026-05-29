---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.10) jsdom — r2 post-patches
review_round: r2
prior_review: .harness/reviews/20260529-harness-v210-jsdom-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7332-c104-7ae1-8465-2d0d566c29cc
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 95109
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T10:06
  prompt_source: .harness/prompts/harness-v210-jsdom-claim-message-review-r2.md
---

**REVIEW Verdict: major, r2 not accepted yet.**

Finding:
- `severity: major`
- `위치`: [package.json](/Users/satgym/work/harness/examples/starpin/backend/package.json:43), [package-lock.json](/Users/satgym/work/harness/examples/starpin/backend/package-lock.json:29)
- `근거`: 실제 review target인 `examples/starpin/backend`는 아직 `jest-environment-jsdom@^30.4.1`입니다. lockfile도 `jest-environment-jsdom@30.4.1` 및 nested `@jest/*@30.4.1`를 유지합니다. 반면 root의 untracked `backend/`에는 `^29.7.0`만 설치된 별도 npm artifact가 생겨 있어, r1 patch가 잘못된 package context에 적용된 것으로 보입니다.
- `제안`: `examples/starpin/backend/package.json`에서 `jest-environment-jsdom`을 `^29.7.0`으로 낮추고, 해당 디렉토리에서 lockfile을 재생성하세요. root-level untracked `backend/` artifact는 review target이 아니므로 제거/정리 대상입니다.

확인 결과:
1. Jest stack 29 family throughout? **No**. 실제 target lockfile에 30.x Jest internals가 남아 있습니다.
2. Bootstrap guard? **Yes**. `/claim.html`/`/claim`만 bootstrap하며 jsdom default `about:blank`은 차단됩니다.
3. jsdom tests? **Yes**. `examples/starpin/backend` 기준 targeted 6 tests pass, full test도 `494 pass / 3 skip / 0 fail`.

Validation I ran:
- `npm --prefix examples/starpin/backend run build`: pass
- `npm --prefix examples/starpin/backend test`: pass, `494 passed / 3 skipped`
- `npm --prefix backend run build/test` from repo root: fails because root `backend/` has no scripts.
