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
  session_id: 019e6784-693a-7643-9828-71aee6b7a91c
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 145001
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T03:39
  prompt_source: .harness/prompts/starpin-v02-fleet-bundle.md
---

**REVIEW**

1. `severity: blocker`  
   `위치`: [package.json](/Users/satgym/work/harness/examples/starpin/backend/package.json:19), [docker-compose.yml](/Users/satgym/work/harness/examples/starpin/docker-compose.yml:12)  
   `근거`: `docker:down`이 `docker compose down -v`를 직접 노출합니다. `-v`는 DB volume 삭제라 HC-9 destructive 작업인데, 사용자 승인/확인 경로가 없습니다.  
   `제안`: 기본 `docker:down`은 volume 미삭제로 바꾸고, `docker:destroy` 같은 별도 스크립트에서 `CONFIRM_DESTROY_STARPIN_DB=...` 확인을 강제하세요.

2. `severity: blocker`  
   `위치`: [google.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/providers/google.ts:196), [google.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/providers/google.ts:290), [auth-routes.ts](/Users/satgym/work/harness/examples/starpin/backend/src/routes/auth-routes.ts:100)  
   `근거`: OAuth start는 `code_challenge`를 저장/전달하지만 callback의 `code_verifier`가 Google token request body에 들어가지 않습니다. 또한 Google nonce는 start에서 생성되지 않고(`needNonce: provider === 'apple'`), adapter path도 `expectedNonce: undefined`입니다. “production Google OAuth + PKCE + nonce 검증”으로는 실제 Google 교환이 실패하거나 nonce binding이 빠집니다.  
   `제안`: `OAuthCallbackInput.code_verifier`를 `exchangeCodeInternal`까지 전달해 `code_verifier` form field를 포함하세요. Google도 nonce를 생성하고 state consume 결과의 nonce를 검증하는 provider-specific callback path 또는 공통 adapter contract 확장이 필요합니다.

3. `severity: major`  
   `위치`: [neighbors.ts](/Users/satgym/work/harness/examples/starpin/backend/src/sky/neighbors.ts:108), [neighbors.ts](/Users/satgym/work/harness/examples/starpin/backend/src/sky/neighbors.ts:162)  
   `근거`: `3d` 모드가 30도 angular viewport 후보만 가져온 뒤 parsec distance를 계산합니다. 3D로는 100pc 이내여도 각거리 30도 밖이면 누락됩니다. 즉 `/v1/claim/neighbors?mode=3d`가 complete query가 아닙니다.  
   `제안`: 3D 모드는 DB에서 `cube`/cartesian distance로 직접 후보를 조회하거나, 현재 구현을 명시적으로 approximate로 낮추고 API/테스트 기대를 바꾸세요.

4. `severity: major`  
   `위치`: [neighbors.ts](/Users/satgym/work/harness/examples/starpin/backend/src/sky/neighbors.ts:149), [neighbors.ts](/Users/satgym/work/harness/examples/starpin/backend/src/sky/neighbors.ts:166), [admin-2fa.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/admin-2fa.ts:184), [admin-2fa.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/admin-2fa.ts:225), [admin-2fa.ts](/Users/satgym/work/harness/examples/starpin/backend/src/auth/admin-2fa.ts:287)  
   `근거`: locked-interface의 INV-2는 production public methods Result 반환/throw 금지인데, DB/catalog/claim 호출 예외가 그대로 전파됩니다. Fastify route에서는 이 예외가 500으로 새어 나갑니다.  
   `제안`: `db_error`/`dependency_error` 같은 Result variant를 추가하거나 route layer에서 명시적으로 catch해 canonical response로 collapse하세요.

5. `severity: major`  
   `위치`: [package.json](/Users/satgym/work/harness/examples/starpin/backend/package.json:17), [docker-compose.yml](/Users/satgym/work/harness/examples/starpin/docker-compose.yml:27), [docker-compose.yml](/Users/satgym/work/harness/examples/starpin/docker-compose.yml:15)  
   `근거`: Postgres는 `POSTGRES_PASSWORD_FILE`로 password를 설정하지만 문서와 `test:integration:db` 기본 `DATABASE_URL_TEST`에는 password가 없습니다. compose 기동 후 기본 명령으로 DB 연결이 실패할 가능성이 큽니다.  
   `제안`: password를 출력하지 않는 wrapper script가 `.docker-secrets/pg_password.txt`를 읽어 `DATABASE_URL_TEST`를 구성하게 하거나, `.pgpass` 기반 절차를 문서화하세요.

6. `severity: minor`  
   `위치`: [setup-db-fixture.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/integration/setup-db-fixture.ts:30), [db-e2e.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/integration/db-e2e.test.ts:91), [0020_create_admin_totp.sql](/Users/satgym/work/harness/examples/starpin/backend/migrations/0020_create_admin_totp.sql:17)  
   `근거`: 새 `admin_totp_secrets`, `admin_totp_used_codes` 테이블이 integration cleanup truncate 목록에 없습니다. 이후 admin2fa integration test가 추가되면 fixture isolation이 깨집니다.  
   `제안`: `KNOWN_TABLES`와 hard-coded truncate test에 두 테이블을 추가하세요.

7. `severity: major`  
   `위치`: [gen_eslint_lock.py](/Users/satgym/work/harness/scripts/fleet/gen_eslint_lock.py:163), [eslint.config.neighbors.mjs](/Users/satgym/work/harness/examples/starpin/backend/eslint.config.neighbors.mjs:17)  
   `근거`: v1.3/v1.4 ESLint lock evidence가 현재 v0.2 실제 import boundary를 거의 검증하지 않습니다. generator가 child 이름을 `../<child>/index.js` provider module로 가정해 `../oauth-google/*`, `../admin2fa/*` 같은 비현실 경로만 제한하고, 실제 consumed modules인 `../catalog/service.js`, `../claim/service.js`, `../auth/service.js` reach-around는 막지 않습니다. “mechanical enforcement 도달” claim은 과장입니다.  
   `제안`: F122로 carry-over: locked-interface의 consumed module paths를 machine-readable로 만들고, parent/stable module allowlist까지 `no-restricted-imports`에 반영하세요.

검증 메모: 전체 test suite는 재실행하지 않았습니다. 코드 리뷰와 `rg`/`git check-ignore` 기반 점검을 했고, Google provider 본문에는 direct `fetch(` 호출이 없으며 `.docker-secrets/pg_password.txt`는 gitignore에 걸립니다.
