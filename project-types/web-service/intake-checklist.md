# Intake Checklist — web-service

> 웹 백엔드 + (선택) 프론트엔드 연결 프로젝트의 Phase 00 Intake. `_generic` 항목 위에 도메인 특화 질문 추가.

## 1. Identity
- One-line: ...
- 공개 API 형태: REST / GraphQL / gRPC / RPC / mixed
- 사용자: 1차 (앱/브라우저/내부) / 2차 (B2B integration)
- 도메인: ...

## 2. 시스템 경계 (가장 먼저 정의)

### 2.1 API 명세 우선 (Spec-first) ⭐
> 프론트엔드/소비자가 *코드 없이도* 통신 시뮬레이션 가능해야 함.

- 명세 도구: OpenAPI 3.x / GraphQL SDL / proto3
- 위치: `.harness/docs/api/openapi.yaml` (또는 양식 디렉토리)
- 버전 정책: URL prefix(`/v1`) / Header(`Accept-Version`) / 없음
- Breaking change 정책: 미리 정해두기

### 2.2 인증·인가
- 인증 방식: JWT / session cookie / OAuth2 / API key / mTLS
- 토큰 저장 위치 (클라이언트): localStorage / httpOnly cookie / memory
- 인가 모델: RBAC / ABAC / 모듈별 명시 / 무인가
- 세션 수명: ...
- 갱신 정책: refresh token / sliding session

### 2.3 데이터 저장
- 주 DB: PostgreSQL / MySQL / SQLite / DynamoDB / MongoDB / ...
- 캐시: Redis / Memcached / in-memory / 없음
- 검색: Elastic / Meilisearch / pgvector / 없음
- 마이그레이션 도구: ...
- 백업·복구 정책: ...

### 2.4 배포·호스팅
- 환경: 자체 서버 / VPS / 컨테이너 (Docker/K8s) / 서버리스 (Lambda/Cloud Run)
- 환경 분리: dev / staging / prod (각 환경의 데이터는 격리)
- CI/CD: ...
- 도메인·TLS: ...
- 콜드 스타트 / autoscale 가정: ...

### 2.5 프론트엔드 연결 (있다면)
- 분리도: 모놀리식(SSR) / SPA / 하이브리드 / 분리 레포
- CORS 정책: 허용 origin / preflight / credentials
- 빌드 / 배포: ...

## 3. 비기능 요구

| 항목 | 목표 |
|---|---|
| 응답 시간 p95 | ... ms |
| 동시 사용자 가정 | ... |
| 가용성 SLA | ... % |
| 데이터 보존 | ... |
| RTO / RPO | ... |

## 4. 보안 (HC-7/HC-8) ⭐
- 시크릿 관리: env / vault / secrets manager
- HTTPS 강제: yes/no
- CORS: ...
- CSRF 보호 (cookie 인증 시 필수)
- 입력 검증·sanitize: ...
- Rate limit / DDoS: ...
- WAF: ...
- 의존 라이브러리 취약점 스캔: ...
- PII redaction in logs: ...

## 5. 외부 영향 작업 (HC-8) 사전 식별
- 외부로 mutation을 일으키는 endpoint / job: ...
- 메일·푸시·SMS 발송: ...
- 결제·서드파티 API: ...

## 6. Destructive 작업 (HC-9) 사전 식별
- DELETE endpoint들: ...
- 일괄 삭제·정리 job: ...
- DB drop·migration revert: ...
- soft-delete vs hard-delete 정책

## 7. 관측·로그
- 구조화 로그 (JSON): yes/no
- correlation id (request id) 전파: yes/no
- log redaction: ...
- metric: Prometheus / OpenTelemetry / 클라우드
- tracing: ...
- error tracking: Sentry / ...

## 8. 테스트 (web-service 특화는 test-strategy.md 참조)
- contract test (API 명세 기반): yes/no
- e2e 도구: Playwright / Cypress / k6 / locust
- 스크린샷 자동 저장 위치: `.harness/screens/<date>-<scenario>/`
- staging 환경에서의 smoke test: ...

## 9. 협업·소비자 흐름 (spec-first 운영 가능성 ⭐)

> yes/no 대신 *실제 산출물 / 명령 경로*로 채움. 비어 있으면 "프론트엔드가 spec만으로 작업 시작 가능"이 false.

- [ ] **`openapi.yaml` (또는 SDL) lint PASS** — 명령: `redocly lint .harness/docs/api/openapi.yaml` (또는 등가)
- [ ] **Mock server 실행 명령** — 예: `prism mock .harness/docs/api/openapi.yaml -p 4010`
- [ ] **Request / response fixture 예시 위치** — `.harness/docs/api/examples/` (또는 명시)
- [ ] **Generated client / types 위치** — 예: `frontend/src/api-client/` (openapi-generator로)
- [ ] **CORS / credentials policy** — origin allowlist, `withCredentials` 여부 명시
- [ ] **Breaking-change 알림 채널** — Slack / 이메일 / PR 라벨 / API spec changelog
- 모바일 클라이언트 / B2B 파트너 등 외부 소비자: ...

## 10. Open questions / Strictness
- Open questions: ...
- Strictness: strict (기본)
