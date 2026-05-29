---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.28 today widget ISS — r2 post-3-finding patch
review_round: r2
prior_review: .harness/reviews/20260529-starpin-v028-today-iss-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7358-1519-7d92-ba32-be9ecdf5f271
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 110705
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T10:46
  prompt_source: examples/starpin/.harness/prompts/v028-today-iss-integration-review-r2.md
---

**REVIEW**

1. `severity: major`  
   `위치`: [today-widget.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/today-widget.ts:30), [today-widget.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/today-widget.ts:93), [today-route.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/today-route.ts:81)  
   `근거`: observer-flavored `/v1/today`는 서버에서 `private, max-age=300`으로 의도적으로 5분 캐시인데, widget client cache는 observer 응답도 1시간 재사용합니다. ISS “다음 패스”는 시간이 지나면 과거 패스가 되므로, remount/refresh 시 최대 1시간 동안 이미 지난 패스를 “다음 ISS 패스”로 표시할 수 있습니다.  
   `제안`: cache TTL을 key별로 분리하세요. 최소 `observer === null ? 1h : 5min`, 더 좋게는 `iss_next_pass.set_at <= Date.now()`이면 즉시 miss 처리.

2. `severity: minor`  
   `위치`: [iss-observer.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/iss-observer.ts:108)  
   `근거`: `peekObserverPosition()`이 cache timestamp를 무시합니다. `getObserverPosition()`의 5분 TTL 및 “stale-location-after-travel 방지” 전략과 달리, 한번 positive cache가 생기면 만료 후에도 계속 raw observer를 반환합니다.  
   `제안`: pure read는 유지하되 만료된 cache면 `null`을 반환하세요. `navigator.geolocation` 호출은 여전히 없어야 합니다.

3. `severity: minor`  
   `위치`: [today-route.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/unit/routes/today-route.test.ts:22)  
   `근거`: r1의 partial-observer 회귀는 구현상 고쳐졌지만 route regression test가 없습니다. 현재 test file은 no-observer path만 검증합니다.  
   `제안`: `?lat=37`, `?alt=0.1`, `?lat=&lon=`가 모두 400을 반환하는 테스트를 추가하세요.

확인 결과:
- `peekObserverPosition()`은 cache empty node env에서 `null`이고, 코드상 navigator probe는 없습니다.
- widget cache key는 `none` ↔ observer state 전환 시 miss가 나도록 바뀌었습니다.
- partial observer route는 코드상 `anyObserverPresent` 경로로 들어가므로 세 예시는 400입니다.
- 제가 실행한 targeted test: `today-route.test.ts` + `today/service.test.ts` = 25 pass. 전체 514 suite는 재실행하지 않았습니다.

**Verdict: `major`**  
r1의 3개 finding 자체는 닫혔지만, observer ISS 응답을 client가 1시간 캐시하는 새 freshness 문제가 ship 전 수정 대상입니다.
