---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: <see body>
target: Hara v2.1 enforcement gap pass (ADR-022)
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e6bc8-f6b6-78f1-853f-2bc7ce8f709d
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 87159
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T23:33
  prompt_source: .harness/prompts/harness-v21-enforcement-r1.md
---

**Findings**

- `severity: major`  
  `위치`: [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:73), [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:80), [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:111)  
  `근거`: `harness(v2.0.0)`는 `primary=v2.0.0`, `scope=""`가 됩니다. 그래서 `v20` variant 매칭 시 `scope_ok` guard가 실행되지 않고, `04-...-starpin-v20.md` + `04-...-starpin-v20-r2.md`만 있어도 r1/r2가 모두 충족됩니다. 로컬 시뮬레이션 결과도 `primary=v2.0.0 scope=<> ... result r1=1 r2=1`였습니다. 즉 “unrelated starpin-v20 must fail”이라는 주석/의도와 달리 unscoped harness ship은 여전히 HC-11을 다른 scope 리뷰로 만족할 수 있습니다.  
  `제안`: `harness(...)`에서 parenthesized slug에 scope가 없으면 commit type `harness`를 fallback scope로 쓰세요. 그러면 `harness-20260527-v20-trim(.r2).md`는 통과하고 `starpin-v20`은 차단됩니다. 또는 version-only variant 매칭은 scope가 non-empty일 때만 허용해야 합니다.

**Checks**

A.1은 현재 로직상 통과합니다. 다만 그 이유가 `scope=""`라서 scope guard가 꺼지는 것이고, 이것이 위 finding의 원인입니다.  
A.3/A.4는 큰 문제 없습니다. `r3`~`r9`는 r2+로 bucket되고, per-ship `has_r1/has_r2`는 loop 안에서 reset됩니다.  
B는 확인했습니다. `examples/starpin/backend/package.json`은 depth-2 scan에 잡히고, `attempt/pass/fail`은 subshell 밖에서 호출되어 counter가 유지됩니다. `bash scripts/pre-review-gate.sh --root examples/starpin`도 `backend npm lint/typecheck/test` 3 checks PASS였습니다.  
C는 OK입니다. PATTERNS.md §drift에 signals/procedure/postmortem trigger가 남아 있고, HC-6 carveout은 root hook enforcement 범위만 명시합니다.  
D는 OK에 가깝습니다. HARNESS/PATTERNS/STATUS operational docs net은 거의 0이고, DECISIONS에 ADR-022가 +61 lines 추가된 형태입니다.

**Verdict: block**

v2.1의 핵심이 HC-11 enforcement gap closure라서, unscoped `harness(vN.N.N)`가 unrelated same-version reviews로 통과하는 경로는 ship 전에 막는 게 맞습니다.
