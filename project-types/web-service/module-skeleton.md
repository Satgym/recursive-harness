# Module Skeleton — web-service

> Blueprint §3 Modules 시작점. 실제 프로젝트의 책임에 따라 합치거나 분할.

## 표준 분할

```
                    ┌───────────────┐
   (client) ──HTTP──▶  M-api-handler│  (입력 검증 + 라우팅)
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  M-auth       │  (인증 / 권한)
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  M-service    │  (도메인 로직)
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  M-repository │  (DB 접근)
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  M-storage    │  (DB / cache, 외부)
                    └───────────────┘

   cross-cutting:  M-config, M-observability, M-schema (API spec)
   비동기:         M-jobs, M-events
```

## 모듈 카탈로그

| Module | 책임 | 의존 |
|---|---|---|
| `M-api-handler` | HTTP route → service. 입력 검증, 응답 직렬화 | M-auth, M-service, M-schema, M-observability |
| `M-auth` | 인증 (token/cookie) + 인가 (RBAC/ABAC) | M-config, M-repository(user) |
| `M-service` | 도메인 비즈니스 로직 | M-repository |
| `M-repository` | DB query / persistence | M-storage, M-config |
| `M-storage` | DB driver / migration | (외부) |
| `M-schema` | API 명세 (OpenAPI/proto/SDL). single source of truth | — |
| `M-config` | env / secret 로드 (HC-7) | (외부) |
| `M-observability` | 구조화 로그 / metric / tracing / correlation id | M-config |
| `M-jobs` | 비동기 job (cron / queue) | M-service |
| `M-events` | pub-sub / 외부 알림 (HC-8) | M-config |
| `M-migrations` | DB schema 변경 | M-storage |
| `M-frontend-contract` (선택) | 프론트엔드와의 합의된 타입 / fixture | M-schema |

## 분할 원칙 (web 특화)

1. **handler 안에 비즈니스 로직 두지 말 것** — service로 빼서 다른 진입점(CLI, job)에서도 재사용
2. **repository는 DB 디테일을 service에 숨김** — service는 도메인 객체만 알면 됨
3. **M-schema가 spec-first의 root** — 명세를 코드에서 생성하지 말고 명세로부터 코드가 생성되게
4. **auth는 middleware로 — handler 안에 인가 로직 두지 말 것**
5. **HC-8/9 mutation 작업은 service 안에 명시적 hook** — `if dry_run: return`처럼 보호 + 로그

## API 명세 위치 약속

- `.harness/docs/api/openapi.yaml` (OpenAPI) 또는
- `.harness/docs/api/schema.proto` (gRPC) 또는
- `.harness/docs/api/schema.graphql` (GraphQL)

이 파일은 [project-types/web-service/api-spec-template.md](api-spec-template.md)를 참고해 작성.

## 일반적인 함정 (anti-patterns)

- ❌ handler가 DB query 직접 호출 (M-repository 우회)
- ❌ auth 정보를 handler가 직접 파싱 (M-auth 우회)
- ❌ 비즈니스 로직이 SQL 안에 (M-service 빈 껍데기)
- ❌ M-schema와 실제 응답이 drift (contract test 부재)
- ❌ 시크릿이 코드/로그에 평문 (HC-7 위반)
- ❌ 사용자 입력을 검증 없이 DB / 외부 API로 전달
