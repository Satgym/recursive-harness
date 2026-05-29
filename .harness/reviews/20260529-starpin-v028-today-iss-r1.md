---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.28 today widget ISS next-pass integration
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7350-f921-7990-a8aa-cfb2b914a9b1
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 125505
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T10:39
  prompt_source: examples/starpin/.harness/prompts/v028-today-iss-integration-review.md
---

**REVIEW**

1. `severity: major`  
   `위치`: [today-widget.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/today-widget.ts:80), [iss-observer.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/iss-observer.ts:65)  
   `근거`: `getObserverPosition(false)`는 cache-only가 아닙니다. `force=false`는 “캐시가 있으면 재사용”일 뿐, 캐시가 없고 `navigator.geolocation`이 있으면 바로 `getCurrentPosition()`을 호출해서 permission prompt가 뜹니다. 따라서 “today-widget은 절대 prompt하지 않는다”는 C 설계와 주석이 깨집니다.  
   `제안`: `iss-observer.ts`에 진짜 cache-only/peek API를 추가하세요. 예: `peekObserverPosition(): ObserverPosition | null` 또는 `getCachedObserverPosition()`. `today-widget`은 이 API만 사용해야 합니다.

2. `severity: major`  
   `위치`: [today-widget.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/today-widget.ts:73)  
   `근거`: client cache hit을 observer 확인보다 먼저 반환합니다. 의도대로 cache-only로 고치면, 첫 render에서 no-observer 응답이 1시간 캐시되고 이후 sky-canvas가 geolocation을 얻어도 widget refresh/remount는 계속 ISS 없는 모델을 반환합니다. D의 “next widget refresh picks up observer”가 현재 구조상 성립하지 않습니다.  
   `제안`: cache key에 observer state를 포함하세요. 최소 `cache = { key: 'none' | `${lat},${lon},${alt}`, ... }`로 두고, 먼저 cached observer를 확인한 뒤 key가 맞을 때만 cache hit 처리해야 합니다. no-observer cache는 observer가 생기면 miss/evict되어야 합니다.

3. `severity: minor`  
   `위치`: [today-route.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/today-route.ts:51)  
   `근거`: `?lat=37`, `?lon=126`, `?lat=&lon=`, `?alt=0.1` 같은 malformed observer query가 400이 아니라 observer-less public response로 처리됩니다. “observer-flavored path + 400 validation” 계약과 맞지 않고, client bug를 조용히 숨깁니다.  
   `제안`: `lat/lon/alt` 중 하나라도 존재하면 observer parse path로 진입하고, lat/lon 둘 다 non-empty가 아니면 400을 반환하세요. `/v1/iss`의 `parseObserver`와 같은 정책을 재사용하거나 공통화하면 좋습니다.

**A-E 평가**

A. `IssLookup` structural boundary는 적절합니다. `today`가 `IssService` concrete class를 알 필요가 없고 테스트 stub도 단순합니다.

B. server-side split은 맞습니다. observer-less는 `public, max-age=3600`, observer-flavored는 shared cache를 피하는 `private, max-age=300`이 합리적입니다. observer 요청을 기존 public cache hit 때문에 reject할 필요는 없고, 지금처럼 bypass가 맞습니다.

C. 현재 구현은 의도와 다르게 widget이 prompt할 수 있으므로 acceptable하지 않습니다.

D. acceptable하지 않습니다. observer가 뒤늦게 생기는 UX를 지원하려면 client cache key/eviction이 필요합니다.

E. 형식은 compact widget에는 충분합니다. 다만 `HH:MM`이 `peak_at`이면 “다음 ISS 패스”가 시작 시각처럼 읽힐 수 있어, 문구를 `최고 HH:MM` 또는 rise time 사용 중 하나로 명확히 하면 좋습니다. direction은 modal/expanded surface로 미뤄도 됩니다.

**Verdict: `major`**

서비스 decoupling과 server cache 방향은 좋지만, widget의 핵심 UX 계약 두 개가 깨져 있습니다. 특히 `getObserverPosition(false)`를 cache-only로 오해한 부분은 ship 전에 고치는 게 맞습니다. Tests는 제가 재실행하지 않았고, 제공된 validation과 코드 inspection 기준입니다.
