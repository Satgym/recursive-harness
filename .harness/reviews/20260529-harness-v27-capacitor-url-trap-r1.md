---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.7) CAPACITOR_SERVER_URL trap detection
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e717d-bd7c-75d0-bf5f-a9253ed33358
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 72695
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T02:08
  prompt_source: .harness/prompts/harness-v27-capacitor-server-url-trap-review.md
---

**REVIEW Verdict: major**

Finding 1  
severity: `major`  
위치: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:51), [capacitor.config.ts](/Users/satgym/work/harness/examples/starpin/capacitor.config.ts:3)  
근거: `CAPACITOR_SERVER_URL= bash $0 ...`는 dotenv 기준으로 `.env.local`을 override해서 실제 Capacitor config는 local bundle로 돌아갑니다. 그런데 detector는 `${CAPACITOR_SERVER_URL:-}`와 `[[ -z "$from_env" ]]`를 써서 “빈 env가 명시적으로 set됨”을 unset과 구분하지 못합니다. 그래서 권장 fix를 사용해도 `.env.local` 값을 다시 읽고 stale remote warning을 계속 띄웁니다.  
제안: env 존재 여부를 `${CAPACITOR_SERVER_URL+x}`로 판단하세요. 예: env가 set되어 있으면 빈 값도 env precedence로 인정하고, env가 unset일 때만 `.env.local`을 읽기.

Finding 2  
severity: `minor`  
위치: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:62)  
근거: full URL을 stderr에 그대로 출력합니다. 현재 ngrok URL은 운영상 유용하지만, URL에 basic auth/userinfo/query token이 들어가면 HC-7 관점에서 로그 유출 리스크가 생깁니다.  
제안: 최소한 userinfo/query/fragment를 redacted 처리하거나 origin만 보여주고, 필요하면 “full value in env/.env.local” 정도로 안내하세요.

A-F 답변:

A. 비어 있지 않은 env precedence는 맞습니다. 다만 빈 env override가 깨져 있어서 문서화된 force-local 경로는 현재 detector 기준 false warning이 납니다. `.env.local` parsing 범위는 v2.7 small surface로는 acceptable입니다. no-fire case와 placement는 맞습니다.

B. warn-not-probe 결정은 sound합니다. `SMOKE_PROBE_REMOTE=1`은 지금 넣지 않는 쪽이 맞습니다. freshness probe는 permission/auth/false-positive 비용이 크고, 이 ship의 핵심은 “remote routing 여부를 즉시 인지”시키는 것입니다.

C. starpin-local implementation + Hara-level pattern 문서화는 acceptable입니다. 두 번째 Capacitor project에서 동일 블록이 반복되면 그때 shared helper로 빼는 게 더 낫습니다.

D. warning copy는 충분히 강합니다. 색상이나 fix time은 불필요합니다. 다만 위 major 때문에 `CAPACITOR_SERVER_URL= bash ...`가 detector 관점에서도 조용해지도록 고쳐야 합니다.

E. ADR-043은 signal matrix, 9 reruns, warn-not-probe, `.env`/`.env.production` carry를 잘 담고 있습니다. PATTERNS subsection은 carry path 언급이 빠져 있는데 ADR/STATUS에 있으므로 nit 수준입니다.

최종 판정: `major`  
이유: 탐지 자체는 방향이 맞지만, 권장 remediation command가 detector에 의해 계속 경고되는 precedence 버그가 있어 v2.7의 핵심 운영 경험을 흐립니다.
