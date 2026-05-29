---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.24 anchor→button + fetch spy hardening
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e71bf-087b-7912-b656-a9cfcf5aef88
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 89062
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T03:20
  prompt_source: examples/starpin/.harness/prompts/v024-polish-review.md
---

**REVIEW**

Finding 1  
severity: `minor`  
위치: [sky-highlight-cache-only.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/unit/web/sky-highlight-cache-only.test.ts:107)  
근거: `does NOT call fetch even when cache is empty`는 실제로 empty cache를 보장하지 않습니다. 같은 파일 앞 테스트가 `addInterest(keep)` 후 non-matching entry를 남기므로, spy describe 진입 시 `memoryCache`는 보통 non-null/non-empty입니다. 따라서 “empty cache” branch에 대한 fetch-spy hardening이라는 커버리지 주장은 약합니다.  
제안: fresh module instance로 `removeInterestFromCacheOnly`를 import하거나, cache를 명시적으로 초기화하는 테스트 seam을 두세요. 최소한 테스트 이름을 “missing target”으로 바꾸면 현재 동작과 일치합니다.

**검토 메모**

- anchor → button migration은 기능상 타당합니다. DOM click listener가 먼저 실행되고 anchor default hash navigation은 그 뒤에 일어나므로, 기존도 `closeInterestsModal()` 후 hash 변경 순서였습니다. 새 button handler는 그 순서를 명시화한 형태입니다.
- `type="button"`과 `aria-label`은 적절합니다. Enter/Space keyboard activation도 button 쪽이 자연스럽고, hash routing과도 맞습니다.
- CSS reset은 주요 button 기본값을 제거합니다. focus ring은 UA 차이가 남을 수 있지만 접근성 관점에서는 제거하지 않은 것이 더 안전합니다.
- fetch spy 복원은 `afterEach`에서 원복되어 cross-test contamination 위험은 낮습니다. `addInterest()` 후 `mockClear()`도 현재 `apiCall()` 구현에서는 POST fetch가 동기적으로 spy에 기록된 뒤 clear되므로 측정 분리가 됩니다.

Verdict: `minor`  
핵심 구현은 ship 가능해 보입니다. 다만 3개 spy 테스트 중 “empty cache” 케이스가 이름 그대로의 상태를 만들지 못해, 커버리지 설명과 실제 검증 사이에 작은 불일치가 있습니다.

검증: `npm --prefix examples/starpin/backend test -- tests/unit/web/sky-highlight-cache-only.test.ts --runInBand` 통과, 7 tests pass.
