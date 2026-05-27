# Codex Cross-Review — starpin v0.2 Fleet round (real-world product application of Hara v1.3)

## Context

Hara v1.3 Fleet Mode 첫 *real product* 적용. starpin v0.1.1 ship 후 v0.2 4 features를 4 background subagents parallel spawn으로 구현:
- F1 neighbors (`/v1/claim/neighbors` real query) — 19/19 unit tests
- F2 admin2fa (TOTP RFC 6238) — 13/13 unit tests
- F3 oauth-google (production Google OAuth + PKCE + id_token JWKS) — 11/11 unit tests
- F4 docker-integration (Postgres 17 + cube/q3c + Redis 7 + integration test fixture, HC-7 secrets) — 5 tests (2 pass + 3 CI-skip)

Hara v1.3 검증:
- 4 children parallel spawn via Agent run_in_background
- ESLint AST lock (`lock-eslint-gen`) — 4 ESLint configs 자동 생성 → 모든 child source lock conformance PASS
- File ownership boundary — 4 children 모두 0 violation
- v1.4 patches 즉시 적용: F120 (gen_eslint_lock recursive subtree path), F121 (owned-paths from locked-interface §File ownership)

Final test: **16 suites / 177 pass + 3 skip / 0 fail**. typecheck clean. ESLint lock clean.

## Review scope

### 신규 v0.2 source files
- `examples/starpin/backend/src/sky/neighbors.ts` (322 LOC) — NeighborsService class
- `examples/starpin/backend/tests/unit/sky/neighbors.test.ts` (344 LOC)
- `examples/starpin/backend/src/auth/admin-2fa.ts` — Admin2faService (TOTP)
- `examples/starpin/backend/tests/unit/auth/admin-2fa.test.ts`
- `examples/starpin/backend/migrations/0020_create_admin_totp.sql`
- `examples/starpin/backend/src/auth/providers/google.ts` — GoogleOAuthProvider
- `examples/starpin/backend/tests/unit/auth/providers/google.test.ts`
- `examples/starpin/docker-compose.yml` + `examples/starpin/.docker-secrets/.gitignore` + `examples/starpin/scripts/init-docker-secrets.sh`
- `examples/starpin/backend/tests/integration/setup-db-fixture.ts` + `tests/integration/db-e2e.test.ts`

### Parent-side patches (Phase 05 merge-collection)
- `src/server.ts` — Admin2faService + NeighborsService + GoogleOAuthProvider DI; google env-gated fallback to Mock
- `src/routes/claim-routes.ts` — `/v1/claim/neighbors` real handler (replaces v0.1 placeholder); admin revoke TOTP wire (`admin2faService.verify` + `x-admin-user-id` header)
- `src/catalog/service.ts` — `byId(id)` method 추가 (nullable lookup — Patch A from neighbors)
- `package.json` — `docker:up`, `docker:down`, `test:integration:db` scripts

### Hara v1.4 patches (v1.3 dogfood가 trigger)
- `scripts/fleet/gen_eslint_lock.py` — `discover_child_lockfiles()` recursive (F120) + `parse_owned_paths()` (F121)

### Dogfood evidence
- ADR-008 split-decision (v0.2 4-feature Fleet)
- 4 locked-interfaces + 4 SUBTREE-PROMPTs + 4 MERGE-REPORTs
- 4 ESLint configs 생성 + 모두 lock PASS (자동 mechanical evidence)
- HC-7 evidence: TOTP secret prefix-only logs / OAuth token redact / docker-compose secrets (NO password literal) / GPS lat_1km/lon_1km
- HC-8 evidence: google adapter는 *injected fetch*만 (direct `fetch(` grep: 0 matches)

## Review focus

### 1. v0.2 production code 품질

- **F1 neighbors**: angular vs 3d 모드 분기가 정확? `unknown_catalog_id` 처리가 base lookup + viewport 모두 cover?
- **F2 admin2fa**: TOTP RFC 6238 spec 100% — RFC §A.1 test vector PASS confirmed. ±1 window tolerance 정확? replay protection PRIMARY KEY constraint이 충분?
- **F3 oauth-google**: 
  - PKCE code_challenge 정확?
  - id_token 검증 — signature (JWKS) + audience + issuer + azp + optional nonce — 모두 cover?
  - jose v5 limit (`createRemoteJWKSet` httpClient inject 미지원) workaround (`createLocalJWKSet` + httpClient fetch + 10min cache) — 안전?
- **F4 docker-integration**:
  - docker-compose secrets 사용 정확 (no env-var password)?
  - q3c extension 부재 시 fallback 패턴 (migration 0010의 EXCEPTION block) 안전?

### 2. Cross-cutting invariant 준수 (Blueprint §8.5 + v0.2 추가)

- INV-1 (HC-7): owner_user_id (neighbors), TOTP secret (admin2fa), clientSecret/code/id_token (oauth-google), pg password (docker) — *모든 child 로그/error msg에서 평문 0*?
- INV-2 (Result): production 코드 throw 0? (test infrastructure는 throw OK)
- F16 collapse (check-neighbor 403 body `{eligible:false}`만) — 본 v0.2가 깨뜨리지 않았는지 확인
- 신규 HC-7 (Docker secrets): docker-compose에 password literal *commit 안 됨*?

### 3. Parent wiring 적정성

- `server.ts` v0.2 wiring (env-gated google provider + admin2fa DI + neighbors DI + CatalogReader adapter) — 적정?
- `claim-routes.ts` 변경 — 기존 v0.1 admin revoke의 `admin-worker-deploy` hard-coded adminUserId가 *real TOTP-verified adminUserId*로 교체됨. tests/unit/claim/*가 새 시그니처 호환?
- `catalog/service.ts.byId` 추가 — 기존 `getObjectDetail` throw 인터페이스와 *함께 존재* (caller 선택). OK?

### 4. Fleet Mode v1.3 enforcement 작동 검증

- 4 children boundary violation 0 (실 확인)
- 4 ESLint configs 자동 생성 + 4 children lock PASS (실 확인)
- v1.4 helper patches (F120/F121) 적용 후에야 ESLint 정확 path catch
- 즉, Hara v1.3 + v1.4 patches가 *real product에서 mechanical enforcement 도달*

### 5. v1.4 carry-over 후보

- F122 (?): 본 round에서 추가로 발견된 harness gap (있다면)
- F123 (?): cross-cutting integration codex review가 4 child × codex 호출보다 효율인가 검증
- helper script generic 강화 (gen_stub/gen_ambient도 recursive subtree path 미지원 — 다음 round 적용 시 노출 예상)

### 6. HC-7/8/9 보안 점검 (의무)

- HC-7: 위 모든 redact path 검증 (코드 grep + test assertion)
- HC-8: oauth-google direct `fetch(` 0 (이미 self-check) — codex 재확인 요청
- HC-9: docker-compose `down -v` (volume 삭제) 등 destructive op — 사용자 승인 path 명시되었는지?

### 7. Test coverage 적정성

- 4 children unit tests 합 = 48 cases (19+13+11+5). 충분?
- Integration test (db-e2e)는 docker 의존 — CI fallback skip 정확?
- e2e missing: `/v1/claim/neighbors` HTTP layer test 부재 (라우트 wiring 후 in-process inject 가능했음)

## Review format

REVIEW 양식 — severity (blocker/major/minor/nit/info) + 위치 + 근거 + 제안.
HC-7/8/9 위반 → 자동 blocker. v1.4 carry-over 후보는 minor/info로.

## Out of scope

- 4 children의 *코드 스타일* (각자 reasonable)
- v0.3 후보 (Apple OAuth / Kakao OAuth / Mobile apps / ingest worker 등)
- Hara v1.4 carry-over (이미 STATUS.md Next action에 명시)
