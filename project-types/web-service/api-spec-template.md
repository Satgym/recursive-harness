# API Spec Template — web-service

> [intake-checklist §2.1](intake-checklist.md)의 "API 명세 우선" 원칙을 실현. 명세 파일은 `.harness/docs/api/openapi.yaml` (또는 도구별 위치)에 저장.

## OpenAPI 3.1 minimal example (CRUD + 표준 error responses + X-Request-Id)

```yaml
openapi: 3.1.0
info:
  title: <Project> API
  version: 0.1.0  # 명세 자체의 버전 (코드 버전과 별개)
  description: |
    See .harness/docs/blueprint.md for module boundaries.
    Auth: <Bearer JWT | session cookie | API key | OAuth2>
    Every error response carries `X-Request-Id` header for log correlation.
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
      operationId: getHealth
      tags: [meta]
      summary: Liveness check
      security: []
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
      operationId: list<Resource>
      tags: [<resource>]
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
          headers:
            X-Request-Id: { $ref: '#/components/headers/RequestId' }
          content:
            application/json:
              schema:
                type: object
                required: [items]
                properties:
                  items:
                    type: array
                    items: { $ref: '#/components/schemas/<Resource>' }
                  next_cursor: { type: string }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '429': { $ref: '#/components/responses/RateLimited' }
        '500': { $ref: '#/components/responses/ServerError' }
    post:
      operationId: create<Resource>
      tags: [<resource>]
      summary: Create <resource>
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/<Resource>Create' }
      responses:
        '201':
          description: created
          headers:
            X-Request-Id: { $ref: '#/components/headers/RequestId' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/<Resource>' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '409': { $ref: '#/components/responses/Conflict' }
        '422': { $ref: '#/components/responses/ValidationFailed' }

  /<resource>/{id}:
    parameters:
      - in: path
        name: id
        required: true
        schema: { type: string, format: uuid }
    get:
      operationId: get<Resource>
      tags: [<resource>]
      responses:
        '200':
          description: ok
          headers:
            X-Request-Id: { $ref: '#/components/headers/RequestId' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/<Resource>' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '404': { $ref: '#/components/responses/NotFound' }
    patch:
      operationId: update<Resource>
      tags: [<resource>]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/<Resource>Update' }
      responses:
        '200': { description: ok, content: { application/json: { schema: { $ref: '#/components/schemas/<Resource>' } } } }
        '404': { $ref: '#/components/responses/NotFound' }
        '422': { $ref: '#/components/responses/ValidationFailed' }
    delete:
      operationId: delete<Resource>
      tags: [<resource>]
      responses:
        '204': { description: deleted }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '404': { $ref: '#/components/responses/NotFound' }

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    CookieAuth:
      type: apiKey
      in: cookie
      name: session
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
    OAuth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.<domain>/authorize
          tokenUrl: https://auth.<domain>/token
          scopes:
            read: read access
            write: write access

  headers:
    RequestId:
      schema: { type: string }
      description: trace correlation id; mirrors response body request_id

  schemas:
    <Resource>:
      type: object
      additionalProperties: false
      required: [id]
      properties:
        id: { type: string, format: uuid }
        # ...

    <Resource>Create:
      type: object
      additionalProperties: false
      required: [...]
      properties: {}

    <Resource>Update:
      type: object
      additionalProperties: false
      properties: {}

    ErrorCode:
      type: string
      enum:
        - validation_failed
        - unauthorized
        - forbidden
        - not_found
        - conflict
        - rate_limited
        - server_error
        # ... 도메인 별 추가

    Error:
      type: object
      required: [code, message, request_id]
      properties:
        code: { $ref: '#/components/schemas/ErrorCode' }
        message: { type: string }
        request_id: { type: string }
        details:
          type: array
          items:
            type: object
            additionalProperties: false
            required: [field, reason]
            properties:
              field:  { type: string }
              reason: { type: string }
              # i18n key, etc.

  responses:
    BadRequest:
      description: Malformed request
      headers: { X-Request-Id: { $ref: '#/components/headers/RequestId' } }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
    Unauthorized:
      description: Missing or invalid credentials
      headers: { X-Request-Id: { $ref: '#/components/headers/RequestId' } }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
    Forbidden:
      description: Authenticated but not allowed
      headers: { X-Request-Id: { $ref: '#/components/headers/RequestId' } }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
    NotFound:
      description: Resource not found
      headers: { X-Request-Id: { $ref: '#/components/headers/RequestId' } }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
    Conflict:
      description: State conflict
      headers: { X-Request-Id: { $ref: '#/components/headers/RequestId' } }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
    ValidationFailed:
      description: Body failed validation
      headers: { X-Request-Id: { $ref: '#/components/headers/RequestId' } }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
    RateLimited:
      description: Too many requests
      headers:
        Retry-After: { schema: { type: integer } }
        X-Request-Id: { $ref: '#/components/headers/RequestId' }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
    ServerError:
      description: Server failure
      headers: { X-Request-Id: { $ref: '#/components/headers/RequestId' } }
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
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
