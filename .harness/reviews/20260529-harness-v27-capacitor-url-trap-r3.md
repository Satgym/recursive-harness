---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.7) CAPACITOR_SERVER_URL trap — r3 post-blocker patch
review_round: r3
prior_review: .harness/reviews/20260529-harness-v27-capacitor-url-trap-r2.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7186-2134-7091-b284-5a2f3d435709
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 122007
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T02:17
  prompt_source: .harness/prompts/harness-v27-capacitor-server-url-trap-review-r3.md
---

REVIEW verdict: `block`

Finding:
- `severity: blocker`
- `위치`: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:74), [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:459)
- `근거`: r2의 4개 leak case는 닫혔고 8-case self-test도 재현상 pass입니다. 다만 control character가 authority 안에 들어오면 redacted log가 다시 multi-line/raw text를 출력합니다. 예: `$'https://example.com\nX-Token: secret/path?x=y'` → `$'https://example.com\nX-Token: secret'`. newline이 path의 `/` 뒤에 있으면 안전하지만, `/` 전 authority 영역이면 HC-7/log injection surface가 남습니다.
- `제안`: `host_port` 출력 전 control/whitespace를 차단하세요. 예: `[[ "$host_port" =~ [[:cntrl:][:space:]] ]] && echo "${scheme}://<host-redacted>"; return` 또는 allowlist 기반으로 authority display 문자를 제한. PATTERNS snippet에도 동일 반영 필요.

문서 전파 자체는 됐습니다. `PATTERNS.md`에 두 함수가 포함됐고 r1/r2 반영 note도 있습니다. 작은 문서 drift로 ADR-043의 “value 노출” 표현은 이제 “redacted value 표시” 정도가 맞지만, 위 blocker가 우선입니다.
