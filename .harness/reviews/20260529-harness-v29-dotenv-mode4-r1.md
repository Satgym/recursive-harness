---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.9) dotenv extension + subagent Mode 4 codify
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7273-df87-7bb3-b7f5-5a78893500e9
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 85418
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T06:37
  prompt_source: .harness/prompts/harness-v29-dotenv-subagent-mode4-review.md
---

**REVIEW**

Finding 1  
`severity`: major  
`위치`: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:106), [capacitor.config.ts](/Users/satgym/work/harness/examples/starpin/capacitor.config.ts:3)  
`근거`: detector는 `.env.local → .env → .env.production`을 검사하지만, 실제 Capacitor config는 `dotenv`를 `.env.local` 한 파일로만 로드합니다. 따라서 `.env` 또는 `.env.production`에만 `CAPACITOR_SERVER_URL`이 있는 case 3/4는 현재 런타임 기준으로 “WKWebView remote load”가 아닌데도 warning을 냅니다. v2.9가 “trap detection close”라고 주장하려면 detector와 실제 `server.url` source가 같아야 합니다.  
`제안`: `capacitor.config.ts`도 동일한 3-file priority loader로 맞추거나, detector를 실제 loader에 맞춰 `.env.local`만 유지하고 `.env/.env.production`은 future carry로 남기는 쪽이 맞습니다.

Finding 2  
`severity`: nit  
`위치`: [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:179)  
`근거`: Mode 4가 추가됐지만 intro가 아직 “3 가지 모드”라고 되어 있습니다.  
`제안`: “4 가지 모드”로 갱신.

**Questions / Scope Notes**

A. 3-file scope 자체는 v2.9 small carry로 acceptable입니다. `.env.development`, `.env.test`, `.env.<NODE_ENV>.local`은 ADR-048의 v2.9.x carry 처리로 충분합니다. 다만 현재 구현은 실제 Capacitor loader와 불일치합니다.

B. bash loop는 “first non-empty value wins”입니다. `.env.local`에 라인이 없으면 `.env`로 계속 가는 해석은 맞습니다. 단, `.env.local`에 `CAPACITOR_SERVER_URL=` 빈 값이 있으면 lower-priority 파일로 fall through하므로 “first match wins”는 아닙니다. Bash 3.2 호환성은 문제 없어 보입니다.

C. Mode 4는 별도 mode로 둘 가치가 있습니다. `total_tokens=0 + tool_uses>0 + explicit rate-limit message`는 Mode 2의 `total_tokens>0` socket close와 충분히 구분되고, recovery가 같아도 원인 라벨과 재시도 판단에 의미가 있습니다.

**Verdict: major**

dotenv detector가 실제 `capacitor.config.ts` 로딩 경로와 맞지 않아 `.env`/`.env.production` self-test가 false positive로 보입니다. 이 불일치를 맞추면 나머지는 pass 수준입니다.
