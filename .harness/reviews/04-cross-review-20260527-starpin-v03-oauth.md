---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: <see body>
target: <see body>
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e67b6-2ece-73c1-b8f7-f864f94cf095
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 112667
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T04:34
  prompt_source: .harness/prompts/starpin-v03-oauth-bundle.md
---

**REVIEW**

- `severity: major`  
  `위치`: [auth-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/auth-routes.ts:49), [auth-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/auth-routes.ts:62), [google.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/providers/google.ts:277), [apple.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/providers/apple.ts:158)  
  `근거`: `/start`에서 `code_challenge`가 optional이고 빈 문자열로 저장/전달됩니다. Google/Apple provider는 challenge가 비어 있으면 authorize URL에 PKCE challenge를 넣지 않으므로, callback에서 `code_verifier`만 요구해도 authorization code 자체가 PKCE-bound였다는 보장이 없습니다.  
  `제안`: `provider === 'apple' || provider === 'google'`이면 `/start`에서 non-empty `code_challenge`를 필수로 400 reject하고, empty string 저장/전달을 없애세요. route integration test도 추가해야 합니다.

- `severity: major`  
  `위치`: [auth-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/auth-routes.ts:109)  
  `근거`: provider가 던지는 `invalid_request:code_verifier_required`, `id_token_invalid:nonce_mismatch`, token 4xx류까지 전부 `503 oauth_provider_unavailable`로 매핑됩니다. Google provider 주석은 caller가 400 매핑한다고 되어 있어 실제 계약과도 불일치합니다.  
  `제안`: provider error prefix/detail을 안정 코드로 분류해 client/input/id_token 검증 실패는 400 계열, network/JWKS unreachable만 503으로 매핑하세요. 응답 detail은 raw provider message 대신 allowlisted error code로 제한하는 편이 좋습니다.

- `severity: major`  
  `위치`: [apple.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/providers/apple.ts:301), [apple.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/unit/auth/providers/apple.test.ts:184), [locked-interface.md](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v03/oauth-apple/locked-interface.md:47)  
  `근거`: Apple client_secret JWT의 `aud`는 spec/locked-interface상 항상 `https://appleid.apple.com`이어야 하는데, 구현은 `config.issuer`를 audience로 사용하고 테스트도 `cfg.issuer`를 기대합니다. test issuer override가 client_secret audience까지 바꾸는 구조입니다.  
  `제안`: client_secret JWT audience는 고정 상수 `https://appleid.apple.com`로 두고, `config.issuer`는 id_token 검증용 override에만 사용하세요. 테스트도 mock issuer가 있어도 client_secret `aud`는 Apple 고정값을 assert해야 합니다.

- `severity: major`  
  `위치`: [gen_eslint_lock.py](/Users/satgym/work/harness/scripts/fleet/gen_eslint_lock.py:116)  
  `근거`: `parse_consumed_stable_modules`가 multi-module front-matter를 정확히 파싱하지 못합니다. 샘플에 두 모듈을 넣어 실행하니 `{'../catalog/service.js': ['CatalogService']}`만 반환되고 두 번째 `../claim/service.js`는 누락됐습니다.  
  `제안`: regex 대신 YAML parser를 쓰거나, 최소한 indentation 기반 state machine으로 `- module:` 블록을 끝까지 순회하세요. quoted/unquoted module, multi-item `allowed_imports` golden test를 추가해야 합니다.

- `severity: major`  
  `위치`: [gen_eslint_lock.py](/Users/satgym/work/harness/scripts/fleet/gen_eslint_lock.py:214), [eslint.config.oauth-apple.mjs](/Users/satgym/work/harness/examples/starpin/backend/eslint.config.oauth-apple.mjs:23)  
  `근거`: v0.3 OAuth children의 실제 파일은 같은 디렉터리 `src/auth/providers/{google,apple,kakao}.ts`인데, generated lock은 child 이름 기반 `../oauth-google-pkce/*`, `../oauth-apple/*` 같은 존재하지 않는 module path만 막습니다. 따라서 `apple.ts`가 `./google.js`를 import하는 위반은 이 ESLint lock으로 잡히지 않습니다. “boundary violation 0” evidence가 실제 sibling boundary를 기계적으로 증명하지 못합니다.  
  `제안`: locked-interface에서 실제 public/internal module path를 machine-readable로 받거나, file ownership 기반으로 same-directory sibling provider paths를 deny pattern에 포함하세요.

- `severity: minor`  
  `위치`: [google.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/providers/google.ts:442), [apple.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/providers/apple.ts:376)  
  `근거`: review focus는 timing-safe nonce compare를 요구하지만 구현은 일반 문자열 비교입니다. 실질 위험은 낮아도 보안 요구와 불일치합니다.  
  `제안`: 길이 체크 후 `crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b))`를 쓰는 helper로 Google/Apple 공통 처리하세요.

HC-7/8/9 blocker는 못 찾았습니다. Kakao는 jose import 0이고, provider source의 실제 network call은 injected `httpClient` 경유입니다.

검증: `npm run test:unit ...` 실행 결과 unit 16 suites / 186 tests pass. 세 OAuth ESLint lock config도 현재 파일 기준 pass. 다만 위 lock finding 때문에 그 PASS는 sibling boundary 증거로는 부족합니다.
