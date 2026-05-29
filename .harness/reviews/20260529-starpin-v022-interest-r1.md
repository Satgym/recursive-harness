---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.22 interest watchlist + v0.21 Maestro carry close
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7161-5fab-7fd3-aaa8-8291b50743e6
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 154115
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T01:37
  prompt_source: examples/starpin/.harness/prompts/v022-interest-watchlist-review.md
---

**Findings**
- `severity: major`  
  `위치`: [interests-modal.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/interests-modal.ts:76), [sky-highlight.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/sky-highlight.ts:148)  
  `근거`: 관심 모달의 `해제`는 `/v1/interests/:id`만 DELETE하고 로컬 highlight cache를 지우지 않습니다. 이후 `refreshHighlightSet()`은 서버에서 사라진 항목도 기존 localStorage `interest`와 merge해서 다시 살립니다. 결과적으로 모달에서는 사라졌는데 canvas/detail toggle은 계속 관심 상태로 남을 수 있습니다.  
  `제안`: 모달 삭제 경로가 `sky-highlight` 로컬 cache도 함께 evict하도록 공용 제거 API를 쓰거나, 서버 삭제 성공 후 local cache invalidation을 추가하세요. 이 케이스는 frontend 단위 테스트나 Maestro carry로 잡는 게 좋습니다.

- `severity: minor`  
  `위치`: [today-search-smoke.yaml](/Users/satgym/work/harness/examples/starpin/tests/mobile/flows/today-search-smoke.yaml:102), [impl review](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260529-v022-interest-watchlist-impl.md:54)  
  `근거`: 구현 리뷰/요약은 “row tap”과 “interest modal” 검증처럼 쓰였지만, 실제 YAML은 검색 결과를 `pressKey: Enter`로 선택하고 관심 쪽은 드롭다운의 “관심 천체” visibility에서 멈춥니다. 즉 direct touch row tap, recenter 자체, modal empty-state는 현재 flow로 검증되지 않습니다.  
  `제안`: 문서를 실제 evidence에 맞게 낮추거나, r2에서 모달 empty-state와 direct row tap 또는 더 강한 recenter assertion을 추가하세요.

- `severity: minor`  
  `위치`: [0034_create_user_interests.sql](/Users/satgym/work/harness/examples/starpin/backend/migrations/0034_create_user_interests.sql:17)  
  `근거`: `user_id TEXT` + no FK는 API privacy 문제는 아니지만, 기존 `claims.user_id UUID REFERENCES users(id)` / `sessions.user_id UUID REFERENCES users(id)` 패턴과 다릅니다. “claims와 같은 패턴”이라는 설명은 사실과 다릅니다.  
  `제안`: 의도적 비-FK면 ADR/코멘트에 정확히 남기고, 아니라면 `user_id UUID NOT NULL REFERENCES users(id)`로 맞추는 편이 일관됩니다.

**Assessment**
A. Security/privacy: routes는 모두 `verify.user_id` scoped라 caller가 다른 사용자의 interests를 읽거나 쓰는 path는 못 봤습니다.

B. Dedup: server non-dedup은 acceptable. `buildHighlightMap()` priority로 self가 interest보다 이기므로 owned X + interested X는 self 색 `#ffd166`이 맞습니다.

C. Frontend: `interests-modal.ts` clear-before-mount는 맞습니다. 다만 detail toggle은 직접 `/v1/interests`를 boot-time GET하지 않고 cached highlight set에 의존하므로 stale window가 있습니다. `pointer-events:none`은 nested span hit 문제에는 유효하지만, Maestro에서 입증된 fix는 Enter fallback입니다.

D. Test coverage: backend 47 tests는 좋지만 frontend cache/modal consistency가 빠져 있습니다. 100-char exact boundary, route limit clamp, modal remove cache invalidation을 추가 권장합니다. Interest highlight E2E는 v0.23 carry로 둘 수 있었겠지만, 위 cache bug 때문에 r2에서 최소한 targeted frontend test는 필요합니다.

E. v0.23 carry: modal anchor `<a href="#detail/:id">`는 defer 가능. `KNOWN_NAMES_BY_ID` 14-star fallback도 acceptable입니다.

**Verification**
- `npm --prefix backend run build` passed.
- Targeted 47 new Jest tests passed.

`verdict: major`  
핵심 backend scoping과 dedup 설계는 통과지만, 모달 삭제가 local highlight cache와 분리되어 backend persistence source-of-truth를 깨는 user-visible consistency bug가 있습니다. r2에서 cache invalidation + evidence drift 정리가 필요합니다.
