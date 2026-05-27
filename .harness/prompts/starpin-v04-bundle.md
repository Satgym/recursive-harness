# Codex Cross-Review — starpin v0.4 Fleet round (3 features)

## Context

starpin v0.3.0 ship 후 v0.4 round (사용자 추천 채택 — "진행해"):
- **F1 sky-3d-native**: PG `cube` extension native 3D query — codex v0.2 M3 closure (기존 30° angular approximate 한계 제거)
- **F2 rate-limit**: zero-dep token bucket rate-limit middleware — production hardening
- **F3 pkce-integration-test**: Google PKCE HTTP layer integration test (`buildServer + Fastify.inject`) — v0.3 review noted gap closure

Fleet v1.3+v1.5 evidence:
- 3 children parallel spawn (Agent run_in_background)
- 2 children rate-limited (F1, F3) before writing merge-report → parent verified artifacts manually (산출물은 완성됨; child agent의 retry/recovery pattern은 v1.6/v1.7 후보 finding)
- ESLint lock 3개 (gen_eslint_lock 재사용; F123 sibling-file boundary 한계 그대로)
- Final test: **20 suites / 227 pass + 3 CI-skip / 0 fail** (+29 from v0.3)

## Review scope

### v0.4 신규/amend source
- `src/sky/neighbors.ts` (amend: catalog3D optional 4th constructor arg + 3d mode native dispatch + graceful fallback)
- `src/catalog/repository.ts` (amend: `byCartesianDistance3D` + `NotSupportedError`)
- `migrations/0021_cube_distance_index.sql` (NEW — DO $$ EXCEPTION graceful skip)
- `src/lib/rate-limit.ts` (NEW — sliding-window counter, zero deps, HC-7 sha256 key, 429 body minimal)
- `tests/unit/sky/neighbors.test.ts` (amend — 29 cases, includes 3d native + fallback)
- `tests/unit/lib/rate-limit.test.ts` (NEW — 11 cases)
- `tests/integration/auth-pkce.test.ts` (NEW — 21 cases, full PKCE/nonce HTTP layer coverage)

### Parent wiring (Phase 05)
- `src/server.ts` — CatalogRepository 인스턴스 → catalog3D 4th arg to NeighborsService + rate-limit preHandler hook (NODE_ENV=test 또는 `disableRateLimit:true` 시 skip)
- `src/server.ts` — `disableRateLimit?: boolean` buildServer option
- `jest.config.mjs` — `process.env.NODE_ENV ??= 'test'` (rate-limit auto-disable for tests)

### Dogfood evidence
- ADR-010 v04-split-decision (3-feature Fleet)
- 3 locked-interfaces + 3 SUBTREE-PROMPTs + 3 MERGE-REPORTs (F1 parent-authored due to rate-limit)
- 3 ESLint lock configs generated; F123 sibling-file limitation persists

## Review focus

### 1. F1 sky-3d-native — codex v0.2 M3 closure 완전성

- migration 0021 `cube_make(ARRAY[x_pc, y_pc, z_pc])` — `objects` table에 `x_pc/y_pc/z_pc` column 존재? 아니면 backfill query 실패?
- `byCartesianDistance3D`의 SQL composition — `cube_distance(cartesian, cube_make($args))` 정확?
- graceful fallback path: `NotSupportedError` catch → angular path로 자동 — 실 prod에서 cube extension 미존재 시 신뢰 가능?
- INV-PG-CUBE: production은 의무라고 했는데, server.ts wiring은 catalog3D 항상 inject — 만약 cube 미존재면 *매번 실패* 후 fallback (overhead?)

### 2. F2 rate-limit — production-grade

- in-memory Map은 *single-process only* — Fastify multi-worker / k8s pod scale 시 *per-instance* limit. doc 명시?
- HC-7: sha256 prefix 8자 — 충돌 가능성 (256 entries당 충돌 1)?
- 429 body minimal 검증 (`{error, retry_after_seconds}`만)
- cleanup: 매 check마다 expired GC — busy path에서 overhead?
- preHandler hook이 *모든 route*에 등록 — URL pattern matching이 정확? 다른 route 영향 0?

### 3. F3 pkce-integration-test — coverage 적정성

- 21 cases — locked-interface 의 ≥7 초과 (좋음)
- 실 `buildServer({pool: mockPool, sharedSecret})` 사용 (mock 아님) 확인
- mock provider가 capture한 `expected_nonce`가 state.nonce와 *real binding*인지 검증?
- v0.3 M1 (`code_challenge_required`) + M2 (provider error 분류) 모두 cover?

### 4. Parent wiring 정합성

- `disableRateLimit` option vs `NODE_ENV=test` 둘 다 — 충분히 다단계 escape?
- `jest.config.mjs`의 `process.env.NODE_ENV ??= 'test'` — jest는 본디 NODE_ENV=test 설정함; 본 라인이 *redundant*인가 *defensive*인가?
- `catalog3DRepo = new CatalogRepository(db)` 별도 instance — `catalogService.repo`와 중복 (private이라 inject 못함). v0.5에서 reflection / DI container 개선?

### 5. v1.5/v1.6 carry-over

- F123 (ESLint sibling-file boundary) 그대로 — 본 v0.4는 sky/rate-limit/integration *서로 다른 dir*이라 영향 적음, 단 *증거 부족*
- 새 finding: child agent rate-limit 시 merge-report 누락 → parent recovery pattern 필요 (v1.7?)
- 새 finding: parent wiring 시 rate-limit이 tests에 *불의의 영향* — F2 child가 *test escape*까지 설계 의무인가? (현재 parent wire에서 handle)

### 6. HC-7/8/9 의무

- HC-7: rate-limit IP redact + 429 body minimal (자체 검증)
- HC-7: PKCE test 시 expected_nonce / code_verifier 평문 log 0
- HC-9: docker-related 변경 없음 (v0.2 patch 유지)

### 7. Test coverage

- 20 suites / 227 pass: sky-3d 새 cases / rate-limit 11 / pkce 21 — 충분?
- Integration test가 *real DB* 미사용 (DATABASE_URL_TEST skip) — production 의무 안 통과; v0.5에서 dockerized CI 후보

## Review format

REVIEW 양식 — severity (blocker/major/minor/nit/info) + 위치 + 근거 + 제안.
HC-7/8/9 위반 → 자동 blocker.

## Out of scope

- code 스타일
- v0.5+ (mobile / ingest / snapshot fetch)
- Hara v1.6+ carry-over (F123 sibling-file, F12X parent-child wiring contract 등)
