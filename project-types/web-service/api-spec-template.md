# API Spec Template — web-service

> [intake-checklist §2.1](intake-checklist.md)의 "API 명세 우선" 원칙을 실현. 명세 파일은 `.harness/docs/api/openapi.yaml` (또는 도구별 위치)에 저장.

## OpenAPI 3.1 minimal example

```yaml
openapi: 3.1.0
info:
  title: <Project> API
  version: 0.1.0  # 명세 자체의 버전 (코드 버전과 별개)
  description: |
    See .harness/docs/blueprint.md for module boundaries.
    Auth: <Bearer JWT | session cookie | API key>
    Errors: see #/components/schemas/Error
servers:
  - url: https://api.<domain>/v1
    description: prod
  - url: http://localhost:8080/v1
    description: local dev

security:
  - BearerAuth: []   # 디폴트 (특정 endpoint에서 무인증 명시)

paths:
  /health:
    get:
      summary: Liveness check
      security: []     # 무인증
      responses:
        '200':
          description: ok
          content:
            application/json:
              schema:
                type: object
                required: [status]
                properties:
                  status: { type: string, enum: [ok] }

  /<resource>:
    get:
      summary: List <resource>
      parameters:
        - in: query
          name: limit
          schema: { type: integer, minimum: 1, maximum: 100, default: 20 }
        - in: query
          name: cursor
          schema: { type: string }
      responses:
        '200':
          description: ok
          content:
            application/json:
              schema:
                type: object
                required: [items]
                properties:
                  items:
                    type: array
                    items: { $ref: '#/components/schemas/<Resource>' }
                  next_cursor:
                    type: string
        '401': { $ref: '#/components/responses/Unauthorized' }

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    <Resource>:
      type: object
      required: [id]
      properties:
        id: { type: string, format: uuid }
        # ...

    Error:
      type: object
      required: [code, message, request_id]
      properties:
        code: { type: string, description: machine-readable }
        message: { type: string }
        request_id: { type: string, description: trace correlation id }
        details:
          type: object
          additionalProperties: true

  responses:
    Unauthorized:
      description: Missing or invalid credentials
      content:
        application/json:
          schema: { $ref: '#/components/schemas/Error' }
```

## 규칙

1. **request_id는 모든 에러 응답에 필수** — 로그 grep 직결, 디버깅 일관성
2. **`code`는 enum / 정수** (i18n / 모니터링용)
3. **`message`는 사람용** — i18n 시 변경 가능
4. **`details`는 자유 형식** — 인입 검증 실패 시 필드별 사유 등
5. **Pagination은 cursor 권장** (offset은 큰 데이터에서 성능 저하)
6. **버전은 URL prefix** (`/v1`) — Header-based는 캐시·로그 추적 어려움
7. **Auth scheme은 components.securitySchemes 한 곳에만** 정의, endpoint마다 적용/면제
8. **`additionalProperties: false`를 *요청 body*에 강제** — 알 수 없는 필드를 silent ignore 하지 말 것

## Phase 02 ModulePlan과의 연결

`M-api-handler` 모듈 plan의 `Public interface`는 본 OpenAPI 명세의 `paths` + `components.schemas`와 *1:1 매핑*되어야 함. Drift 발견 시 즉시 §6.2.

## 도구

- 명세 검증: `redocly lint openapi.yaml` / `spectral lint`
- 코드 생성 (server stub / client): `openapi-generator` / `oapi-codegen`
- contract test: `schemathesis run openapi.yaml --url <server>` / `dredd`
- mock server (프론트엔드용): `prism mock openapi.yaml`
