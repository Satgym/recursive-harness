# Test Strategy — web-service

> _generic test pyramid 위에 *웹 도메인 특화* 검증 추가.

## 1. Contract test (가장 먼저)

API 명세 우선 정책 (intake §2.1)을 강제하려면 *contract test*가 핵심:

- 명세 (OpenAPI / proto / SDL)를 *single source of truth*
- 서버 핸들러 출력 ↔ 명세 일치 검증 (도구: `dredd` / `schemathesis` / `prism`)
- 프론트엔드 / 소비자는 명세 기반 mock으로 작업 가능

## 2. Unit
- handler: 입력 검증, 의존성 mock, 응답 형태만 검증
- service: 비즈니스 로직, DB mock
- repository: DB와 인터페이스 contract (실 DB 또는 testcontainer)

## 3. Integration
- HTTP server + 실 DB (testcontainer): happy path + auth 실패 + 권한 실패 + 입력 검증 실패 + 동시성
- 트랜잭션 / 격리 수준 검증

## 4. E2E
- 도구: Playwright (browser) / Cypress / Postman / Newman / k6
- 시나리오: 가입 → 로그인 → 핵심 워크플로우 → 로그아웃 (사용자 관점)
- 스크린샷: **`.harness/screens/<date>-<scenario>/<step-N>.png`**에 자동 저장 → 사용자/Claude가 시각 확인 가능
- DOM snapshot도 옵션

## 5. 로드 / 성능
- 도구: k6 / locust / wrk / vegeta
- 목표: intake §3에서 정의한 p95, RPS
- 정기 측정 (회귀 방지)

## 6. 보안 테스트
- SQL injection / XSS / CSRF 자동 점검
- Dependency vulnerability scan (`npm audit` / `pip-audit` / `cargo audit` / Snyk)
- HTTPS / cipher 점검
- 시크릿 grep (commit hook): `git secrets` / `truffleHog`

## 7. 디버그 hook
- request_id를 *모든 로그·응답 헤더*에 부착 (correlation)
- 개발 모드 콘솔 prefix: `[handler:<name>]`, `[service:<name>]`, `[repo:<name>]`
- 응답 body에 `_debug` 필드 (개발 환경 only) — auth 정보 redact 후
- DB query 로그 (slow query threshold)
- 에러 응답에는 항상 request_id 포함 → 로그 grep 직결

## 8. 환경 분리
- test / dev / staging / prod 데이터 *완전 격리*
- 테스트는 격리된 DB instance (testcontainer 또는 임시 schema)
- 시크릿: 환경별 분리, .env.example만 repo에

## 9. CI 통합
- pre-review-gate가 unit + lint + typecheck (빠른 것)
- CI는 integration + contract + (선택) e2e + security scan
- e2e는 staging deploy 후 자동 실행 옵션

## 10. 검증 hooks (Phase 03 Implement 동안)
- 각 endpoint 구현 시점에 OpenAPI spec 갱신 → contract test 즉시 PASS 확인
- 새 endpoint마다 자동 e2e 시나리오 1개 (smoke)
- 모든 outgoing 외부 호출은 mock 또는 명시적 실 환경 (HC-8)
