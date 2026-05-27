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
  session_id: 019e67d1-2b3e-79b1-8904-89f37c13e049
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 185430
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T05:03
  prompt_source: .harness/prompts/starpin-v04-bundle.md
---

REVIEW

Finding 1  
severity: major  
위치: [locked-interface.md](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v04/sky-3d-native/locked-interface.md:49), [repository.ts](/Users/satgym/work/harness/examples/starpin/backend/src/catalog/repository.ts:140)  
근거: F1 locked-interface는 `byCartesianDistance3D` 정상/미지원 repository 테스트를 요구하지만, 현재 테스트는 `NeighborsService`에서 `CatalogRepository3D`를 mock으로 대체합니다. 그래서 실제 SQL의 `cube_distance(...)`, `cartesian <-> ...`, SQLSTATE→`NotSupportedError` 매핑은 테스트되지 않습니다. `rg` 기준 `byCartesianDistance3D` 검증은 `tests/unit/sky/neighbors.test.ts` mock 호출뿐입니다.  
제안: `tests/unit/catalog/repository.test.ts`를 추가해 mock `pg.Pool.query`로 SQL/params/정렬/limit/SQLSTATE fallback을 검증하고, 가능하면 `DATABASE_URL_TEST` DB integration에 0021 migration + native 3D query smoke를 추가하세요.

Finding 2  
severity: major  
위치: [0010_create_objects.sql](/Users/satgym/work/harness/examples/starpin/backend/migrations/0010_create_objects.sql:15), [0010_create_objects.sql](/Users/satgym/work/harness/examples/starpin/backend/migrations/0010_create_objects.sql:61), [0021_cube_distance_index.sql](/Users/satgym/work/harness/examples/starpin/backend/migrations/0021_cube_distance_index.sql:16)  
근거: 0021은 `cube` unavailable 시 graceful skip을 표방하지만, fresh DB에서는 0010이 이미 `CREATE EXTENSION IF NOT EXISTS cube`와 `cube(ARRAY[x_pc,...])` GiST index를 예외 처리 없이 실행합니다. 따라서 cube 없는 환경은 0021까지 도달하기 전에 migration이 실패할 수 있습니다.  
제안: production에서 cube가 mandatory라면 INV-PG-CUBE 문구를 “legacy runtime fallback only; migrations require cube”로 낮추고 boot/preflight에서 cube 존재를 확인하세요. Graceful migration을 진짜 의도한다면 0010의 cube extension/index도 0021처럼 DO/EXCEPTION 처리해야 합니다.

Finding 3  
severity: major  
위치: [server.ts](/Users/satgym/work/harness/examples/starpin/backend/src/server.ts:57), [rate-limit.ts](/Users/satgym/work/harness/examples/starpin/backend/src/lib/rate-limit.ts:47)  
근거: limiter key는 `req.ip`인데 Fastify 서버 옵션에 `trustProxy`가 없습니다. k8s ingress/LB 뒤에서는 모든 요청이 프록시 IP로 합쳐져 전체 사용자가 하나의 bucket을 공유하거나, 반대로 실제 client IP 정책이 의도와 다르게 동작할 수 있습니다. production hardening 기능으로는 배포 토폴로지 의존성이 문서/설정에 노출되어야 합니다.  
제안: `buildServer`에 `trustProxy` 옵션 또는 env 기반 설정을 추가하고, 운영 문서에 “direct exposure vs trusted proxy” 전제를 명시하세요. production-mode inject 테스트로 `x-forwarded-for` 처리도 검증하는 게 좋습니다.

Finding 4  
severity: minor  
위치: [repository.ts](/Users/satgym/work/harness/examples/starpin/backend/src/catalog/repository.ts:155), [neighbors.ts](/Users/satgym/work/harness/examples/starpin/backend/src/sky/neighbors.ts:271)  
근거: fallback path는 `distance > q.radius`만 제외하므로 radius 경계값을 포함하지만, native SQL은 `cube_distance(...) < $4`라 정확히 반경과 같은 별을 제외합니다. 같은 API가 cube availability에 따라 boundary 결과가 달라질 수 있습니다.  
제안: contract를 inclusive로 유지하려면 SQL을 `<= $4`로 맞추고 boundary test를 추가하세요. exclusive가 의도라면 fallback filter도 `<` 기준으로 바꾸고 명세에 적어야 합니다.

Finding 5  
severity: minor  
위치: [rate-limit.ts](/Users/satgym/work/harness/examples/starpin/backend/src/lib/rate-limit.ts:2), [ADR-010-v04-split-decision-3-features.md](/Users/satgym/work/harness/examples/starpin/.harness/decisions/ADR-010-v04-split-decision-3-features.md:40)  
근거: prompt/ADR는 token bucket 또는 production rate-limit를 말하지만 구현은 per-key fixed window counter입니다. 동작 자체는 단순하고 테스트도 통과하지만, token bucket/sliding-window semantics는 아닙니다.  
제안: 명세를 fixed-window로 정정하거나, 실제 token bucket 구현으로 바꾸세요. 8-char sha256 key는 256개 수준에서 충돌이 흔한 것은 아니지만 32-bit bucket key이므로 운영 규모가 커질 경우 16 hex 이상이 더 방어적입니다.

정보성 확인:
- F3 PKCE integration은 real `buildServer({ pool, sharedSecret })` + `Fastify.inject`를 사용하고, `expected_nonce`/`code_verifier` threading 및 v0.3 M1/M2 에러 매핑을 충분히 커버합니다.
- HC-7/8/9 blocker는 확인되지 않았습니다.
- 실행 확인: `npm test -- --runInBand tests/unit/sky/neighbors.test.ts tests/unit/lib/rate-limit.test.ts tests/integration/auth-pkce.test.ts` → 48 pass. `npm run typecheck` → pass.
