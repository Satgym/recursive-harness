# Codex Cross-Review — starpin v0.3 OAuth Fleet round

## Context

starpin v0.2.0 ship 후 codex B2 (Google PKCE+nonce 미완) + v0.1.1 OAuth Mock-only Apple/Kakao 잔존 → v0.3 round로 **OAuth 3-provider production 적용**.

3 children parallel spawn (Agent run_in_background):
- F1 oauth-google-pkce: 기존 google.ts amend (code_verifier thread + expected_nonce 검증; B2 closure) — 15/15 tests
- F2 oauth-apple: new apple.ts (ES256 client_secret JWT + PKCE + nonce) — 7/7 tests
- F3 oauth-kakao: new kakao.ts (2-step access_token + userinfo; no PKCE/nonce/id_token) — 10/10 tests

Parent wiring (선행 — children 작업과 non-overlapping):
- types.ts amend: OAuthCallbackInput에 `expected_nonce?: string` 추가
- auth-routes amend: state.nonce → expected_nonce thread; google도 needNonce=true
- server.ts amend: apple/kakao 모두 env-gated provider (Mock fallback safe default)

Hara v1.5 inflight (this round):
- F122: gen_eslint_lock에 `consumed_stable_modules` parse_consumed_stable_modules 신설 + Layer 3 internal-path block (named-import allowlist enforcement은 v1.6 후보)

Final test: **18 suites / 198 pass + 3 CI-skip / 0 fail** (was 16/177 post-v0.2). typecheck clean. ESLint Fleet locks clean (3 new v0.3 + 4 v0.2).

## Review scope

### v0.3 신규 source files
- `src/auth/providers/google.ts` (amend: PKCE thread + nonce validation)
- `src/auth/providers/apple.ts` (NEW — ES256 + PKCE + JWKS + nonce)
- `src/auth/providers/kakao.ts` (NEW — 2-step access_token + userinfo)
- `tests/unit/auth/providers/{google,apple,kakao}.test.ts`

### Parent wiring (Phase 05)
- `src/auth/providers/types.ts` — `expected_nonce` field
- `src/routes/auth-routes.ts` — state.nonce thread + google needNonce
- `src/server.ts` — 3 providers env-gated DI (Mock fallback)

### Hara v1.5 inflight patch
- `scripts/fleet/gen_eslint_lock.py` — `parse_consumed_stable_modules` + Layer 3

### Dogfood evidence
- ADR-009 v03-split-decision (3-OAuth Fleet)
- 3 locked-interfaces + 3 SUBTREE-PROMPTs + 3 MERGE-REPORTs
- ESLint configs 3 신규 (gen_eslint_lock 실 사용)

## Review focus

### 1. OAuth 3-provider 보안 정밀도

**Google (F1)**:
- code_verifier가 token POST body에 정확히 들어가는가?
- expected_nonce 비교가 id_token.nonce와 strict (timing-safe) 비교?
- v0.2 기존 11 cases 깨지지 않았는가?

**Apple (F2)**:
- ES256 JWT 생성: header.alg=ES256, kid=keyId, payload.iss=teamId, sub=clientId, aud=`https://appleid.apple.com`, exp=now+300 — 모두 정확?
- response_mode=form_post 명시?
- jose `createLocalJWKSet` + injected httpClient — `createRemoteJWKSet` 회피 워크어라운드 안전?
- privateKeyPem이 in-memory만; commit/log 0?

**Kakao (F3)**:
- 2-step exchange (token endpoint → userinfo endpoint) 순서 정확?
- token endpoint 4xx 시 raw body 노출 안 함?
- access_token이 `Authorization: Bearer` header에 정확 placement?
- `kakao_account.email` 사용자 동의 거부 case (email field optional) 처리?
- jose import 0 (Kakao 본질상 미사용)?

### 2. Parent wiring 정합성

- `types.ts.OAuthCallbackInput.expected_nonce?` field 추가가 기존 Mock/test에 영향?
- `auth-routes` state.nonce 조건 `stateRecord.nonce !== undefined` 정확 (null vs undefined 구분)?
- `auth-routes` `needNonce: provider === 'apple' || provider === 'google'` — Kakao는 nonce 안 만들도록 정확?
- `server.ts` 3 providers 모두 env-gated + Mock fallback — production env unset 시 safe default?

### 3. Hara v1.5 F122 patch 정밀도

- `parse_consumed_stable_modules` regex가 multi-module yaml 정확 parse?
- ESLint `patterns:` (group with `!` exception)이 ESLint v9에서 정확 작동?
- v0.3 locked-interfaces는 *아직 `consumed_stable_modules` 미사용* — backwards-compat OK?

### 4. Fleet Mode v1.3+v1.5 enforcement evidence

- 3 children boundary violation 0 (실 확인)
- 3 children ESLint lock PASS (실 확인)
- F1 (google amend): 기존 v0.2 file *수정*인데 ownership 안 깨졌나? (apple/kakao 형제 read 안 함 확인)

### 5. v0.3 RELEASE 누락 항목

- v0.3에 미포함: sky 3d native (PG cube) → v0.4
- mobile full app, ingest worker → v0.4+
- snapshot fetch script → v0.4+
- production rate-limit middleware → v0.4+

본 review는 v0.3 scope 한정.

### 6. HC-7/8/9 의무 점검

- HC-7: 3 providers 모두 raw secret/code/token redact (코드 grep)
- HC-8: direct `fetch(` grep 0 across 3 providers
- HC-9: 새 destructive op 없음 (auth state consume은 idempotent UPDATE)

### 7. v1.5/v1.6 carry-over 확장

- F122 v1.5는 internal-path block만 — named-import allowlist enforcement는 v1.6 custom AST rule 후보
- google.ts amend 시 *기존 v0.2 tests 11/11 깨뜨리지 않음* 확인 의무

## Review format

REVIEW 양식 — severity (blocker/major/minor/nit/info) + 위치 + 근거 + 제안.
HC-7/8/9 위반 → 자동 blocker.

## Out of scope

- 3 providers 의 *비교적 적은 코드 스타일*
- v0.4 carry-over (sky 3d / mobile / ingest)
- F122 v1.6 후보 (custom AST rule)
