---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.9) dotenv + Mode 4 — r2 post-alignment fix
review_round: r2
prior_review: .harness/reviews/20260529-harness-v29-dotenv-mode4-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7278-7a2f-7740-8f6b-013cfe4dfe4d
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 56308
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T06:42
  prompt_source: .harness/prompts/harness-v29-dotenv-subagent-mode4-review-r2.md
---

**REVIEW**

Finding 1  
`severity`: minor  
`위치`: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:106), [capacitor.config.ts](/Users/satgym/work/harness/examples/starpin/capacitor.config.ts:8)  
`근거`: non-empty 값에서는 detector와 Capacitor loader가 맞습니다. 다만 `.env.local`에 `CAPACITOR_SERVER_URL=` 또는 `CAPACITOR_SERVER_URL=""`처럼 빈 값이 있고 `.env`에 non-empty 값이 있으면 불일치합니다. `dotenv`는 빈 값도 “이미 set된 key”로 보고 이후 파일이 overwrite하지 않으므로 실제 `server.url`은 비활성화됩니다. 반면 detector는 `[[ -n "$from_file" ]]`일 때만 break해서 `.env`까지 내려가 warning을 냅니다.  
`제안`: detector에서 “값이 non-empty인가”가 아니라 “키 라인을 찾았는가”로 break하고, 최종 warning은 지금처럼 effective가 non-empty일 때만 출력하면 됩니다.

확인 결과:

1. `.env.local` → `.env` → `.env.production` 순서와 dotenv first-set-wins는 맞습니다. 단, detector는 현재 “first non-empty wins”라서 empty file override case만 어긋납니다.
2. 현재 lockfile은 `dotenv@16.6.1`이고 default `override`는 `false`입니다. README와 `lib/main.js` 모두 “first value wins / existing `process.env` not overwritten” 동작을 확인했습니다. 역사적으로는 v5에서 falsy existing env도 덮어쓰지 않도록 바뀐 적이 있고, v14.1에서 `override` 옵션이 추가됐지만 default는 여전히 non-overwrite입니다.
3. Mode 4 intro의 `3 → 4` 수정은 맞습니다.
4. Final verdict: `minor`. Non-empty 일반 케이스는 r1 major를 닫지만, empty `.env.local` override edge에서 false positive가 남아 있습니다.
