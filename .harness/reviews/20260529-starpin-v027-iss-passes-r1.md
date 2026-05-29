---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.27 ISS pass calendar /v1/iss/passes
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e733f-0649-7df1-aea1-b5141656f6b7
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 97488
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T10:19
  prompt_source: examples/starpin/.harness/prompts/v027-iss-passes-review.md
---

**REVIEW**

1. `severity: major`  
   `위치`: [service.ts](/Users/satgym/work/harness/examples/starpin/backend/src/iss/service.ts:211), [types.ts](/Users/satgym/work/harness/examples/starpin/backend/src/iss/types.ts:64)  
   `근거`: `startDate`가 이미 패스 중이면 `riseMs = startDate`로 설정됩니다. 실제 rise crossing이 아닌 시간이 `rise_at`이 되고, peak 시점에서 시작하면 `rise_at === peak_at`까지 가능합니다. 직접 확인한 예: Seoul fixture에서 `startDate=2026-05-29T02:32:15Z`이면 `rise_at`과 `peak_at`이 둘 다 `02:32:15Z`로 반환됩니다. 이는 `rise_at = 0° altitude rising moment` 타입 계약과 테스트의 `rise < peak < set` 불변식에 어긋납니다.  
   `제안`: v0.27에서는 in-progress pass를 제외하고 다음 rise부터 emit하거나, 시작 시 `prevAlt > 0`이면 역방향으로 실제 rise를 찾는 보정 로직을 추가하세요. 최소한 mid-pass start fixture를 서비스 테스트에 추가해야 합니다.

2. `severity: major`  
   `위치`: [iss-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/iss-routes.ts:57)  
   `근거`: `Number('') === 0`이라 `/v1/iss/passes?lat=&lon=`이 observer missing/invalid로 400이 아니라 `(0,0)` 관측자로 200을 반환합니다. observer-mandatory endpoint에서 빈 form/query 값이 Gulf of Guinea 기준 패스로 조용히 바뀌는 것은 계약 위반입니다.  
   `제안`: `lat`, `lon`, `alt`는 `trim() === ''`를 invalid로 처리하세요. passes route에서는 빈 lat/lon을 `observer_required` 또는 `invalid_lat/lon` 중 하나로 명확히 고정하고 테스트를 추가하세요.

3. `severity: minor`  
   `위치`: [iss-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/iss-routes.ts:117), [iss-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/iss-routes.ts:130)  
   `근거`: prompt/comment는 `hours/max clamp`라고 하지만 구현과 테스트는 out-of-range를 400으로 reject합니다. 또 `max=1.5`는 통과하며 `result.length < 1.5` 때문에 최대 2개까지 emit될 수 있습니다.  
   `제안`: clamp가 계약이면 실제 clamp로 바꾸고 테스트도 수정하세요. reject가 계약이면 comment/prompt를 “range-check”로 고치고 `max`는 정수만 허용하세요.

**A-D 평가**

A. 60s coarse search로 ultra-grazing pass를 놓치는 것은 v0.27 “rough pass time” 범위에서는 acceptable입니다. 다만 mid-pass start는 scope issue가 아니라 contract bug입니다. 5s boundary refinement는 성능상 문제 없고, binary는 optional입니다. 10s peak sampling도 rough surface에는 acceptable이나 near-zenith에서는 `<0.1°`라고 단정하긴 어렵습니다.

B. `altDegAt`, `refineCrossing`, `findPeak`를 file-scope helper로 둔 경계는 적절합니다. satrec/observer를 명시적으로 받는 순수 계산 helper라 테스트/리팩터링에 유리합니다.

C. `parseObserver` 재사용과 passes route의 `observer_required` asymmetry는 acceptable입니다. 단, 빈 문자열 처리는 보강해야 합니다.

D. visibility filter 미포함은 acceptable입니다. 타입/문서가 “above-horizon, not necessarily visible”을 명시하고 있어서 v0.28 carry로 충분합니다.

**Verdict: major**

핵심 알고리즘 방향과 WGS84 look-angle basis는 맞지만, 현재 패스 중 호출 시 `IssPass` 시간 계약이 깨지고 빈 observer query가 잘못된 위치로 200 처리됩니다. API가 v0.28 UI에 붙기 전에 이 두 validation/edge path는 닫는 게 맞습니다. Full suite는 다시 돌리지 않았고, 위 edge cases는 dist 기반 Node probe로 확인했습니다.
