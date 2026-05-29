---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.6) DOM mutation grep enforcement
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7120-9df8-74d3-9759-2f4cebd94680
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 86541
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T00:27
  prompt_source: .harness/prompts/harness-v26-dom-mutation-grep-review.md
---

**Findings**

1. `severity: minor`  
   `위치`: [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:371), [DECISIONS.md](/Users/satgym/work/harness/DECISIONS.md:31), [scripts/check-subagent-prompt.sh](/Users/satgym/work/harness/scripts/check-subagent-prompt.sh:21)  
   `근거`: 문서는 “backend-only prompt 는 trigger 안 됨 / false-fire 0”처럼 읽히지만, 실제 trigger는 `public/lib/` substring이라 `backend/public/lib/...`를 문서적으로 언급하거나 pure frontend helper 작업만 해도 firing 합니다. ADR은 뒤에서 이 false-fire 가능성을 인정해 약간 상충합니다. 또 `--help`는 v2.6 존재만 보이고 required keyword set은 설명하지 않습니다. 실패 시 error message는 충분히 discoverable합니다.  
   `제안`: “backend-only prompt without frontend lib path or DOM API does not trigger” 정도로 좁혀 쓰고, `--help` 주석에 strict 추가 검사 2개(ARIA, DOM mutation order)를 짧게 추가하세요.

**Heuristic 평가**

Trigger set은 v0.20 계열의 `firstChild/removeChild/appendChild` mount-order bug는 잘 잡습니다. 다만 path 없이 DOM API만 언급하는 prompt에서는 `replaceChildren`, `insertBefore`, `replaceChild`, `replaceWith`, `textContent = ''` 같은 common surface가 빠집니다. 보통 subagent prompt가 파일 경로를 포함한다면 `public/lib/`가 넓게 커버하므로 ship blocker는 아닙니다.

Imperative set은 실무상 충분합니다. 추가한다면 `mount after clear`, `clear before mount`, `after cleanup` 정도가 자연어 phrasing 누락을 줄입니다. `mount AFTER`는 다소 generic하지만 DOM/path trigger 안에서만 요구되므로 위험은 낮습니다.

`public/lib/` coupling은 의도한 broad sentinel로 보입니다. pure helper false-fire는 실제로 있을 수 있지만, 비용은 prompt에 짧은 DOM mutation-order N/A/imperative 섹션을 넣는 수준이라 v2.6 small gate로는 수용 가능합니다.

**Self-Test**

현재 4개는 ship 판단에는 충분합니다. 보강한다면 두 케이스가 좋습니다: `public/lib/`만 있는 pure helper prompt가 의도대로 FAIL하는지, 그리고 `replaceChildren`/`textContent=''`처럼 현재 API set 밖 DOM-clear prompt가 slip하는지. 후자는 v2.6.1 carry 후보입니다.

**Docs**

PATTERNS의 carry 제거 방향과 HARNESS §11 row cadence는 맞습니다. ADR-041도 변경점과 trade-off를 대체로 잘 나눴습니다. 단, “backend-only false-fire 0” 표현은 위 finding처럼 좁히는 편이 정확합니다.

`verdict: minor`

lint 자체는 v0.20 재발 방지 목적에 맞고 ship 가능한 수준입니다. 남은 문제는 regex coverage 확장과 문서 표현 정밀도라 patch-before-ship 필수는 아닙니다.
