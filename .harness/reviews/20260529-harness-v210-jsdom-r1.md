---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.10) jsdom infra + claim-message real-DOM test
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e732d-7c04-7d90-974d-6c2bc7d43626
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 121339
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T10:00
  prompt_source: .harness/prompts/harness-v210-jsdom-claim-message-review.md
---

**REVIEW Verdict: `minor`**

**Findings**

- `severity: minor`  
  위치: [package.json](/Users/satgym/work/harness/examples/starpin/backend/package.json:42)  
  근거: `jest` / `ts-jest`는 29.x인데 `jest-environment-jsdom`만 30.4.1입니다. 현재 focused test는 통과하지만 lockfile상 `@jest/environment@30.4.1`도 같이 들어와 Jest internals major가 섞입니다.  
  제안: `jest-environment-jsdom@^29.7.0`로 맞추거나, Jest stack 전체를 30.x로 올리는 별도 ship으로 분리하세요.

- `severity: minor`  
  위치: [claim-message.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/claim-message.ts:598), [claim-message-real-dom.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/unit/web/claim-message-real-dom.test.ts:23)  
  근거: `renderInbox` import만 해도 top-level auto-bootstrap이 실행되고, 세션 없음 → `window.location.assign('/login.html')`가 jsdom에서 `Not implemented: navigation` console.error를 냅니다. 제가 focused test를 돌려도 6 pass와 함께 이 log가 재현됐습니다.  
  제안: test-env feature detect보다는 `document.location.pathname.endsWith('/claim.html')` 같은 page-path guard 또는 별도 claim page entrypoint로 bootstrap을 분리하는 게 낫습니다.

- `severity: nit`  
  위치: [STATUS.md](/Users/satgym/work/harness/STATUS.md:17)  
  근거: Current는 v2.10 pending인데 Active gate가 아직 “Hara v2.9 codex r1/r2”로 남아 있습니다. stranger-proof status 기준과 어긋납니다.  
  제안: Active gate를 v2.10 review로 갱신하세요.

**질문별 답변**

A. per-file pragma 선택은 맞습니다. DOM이 필요한 파일만 jsdom으로 올리고 나머지 47개 node-env suite를 유지하는 게 현재 범위에 적절합니다.

B. bootstrap side effect는 이번 ship을 막을 수준은 아니지만, 계속 방치할 건 아닙니다. guard를 넣는 쪽에 찬성합니다.

C. v2.10 범위로는 acceptable입니다. `renderInbox`의 실제 DOM/XSS/구조 contract를 직접 검증하는 게 이번 carry의 핵심입니다.

D. full StubNode migration을 v2.10.x carry로 미루는 것도 합리적입니다. 다만 그때 `wireInboxSection` optimistic delete도 jsdom + mocked API로 production path를 타게 옮기는 게 좋습니다.

E. 최종 verdict는 `minor`: 방향은 맞고 테스트도 통과하지만, Jest major skew와 import-time bootstrap noise는 정리하고 ship하는 편이 낫습니다.
