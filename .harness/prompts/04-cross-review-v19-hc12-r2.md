You are running **codex r2** on Hara v1.9 (HC-12) + starpin v0.10. r1 produced 7 findings (1 blocker + 2 major + 3 minor + 1 nit). Prior: `.harness/reviews/04-20260527-v19-hc12-r1.md`.

## r1 re-verify

**r1 #1 (blocker) — HC-12 wording broader than enforcement**
- Patch: HARNESS.md HC-12 row narrowed to "*web UI surface* (detection: tracked `public/`/`frontend/`)" + explicit scope-limit sentence ("first-flow happy-path composition; multi-flow / perf / xbrowser / a11y / security 별도 gate"). Non-web surfaces marked v1.10 carry.

**r1 #2 (major) — JSON evidence validation loose**
- Patch: `.githooks/pre-push` now parses JSON via python3, requires `status=pass + exit_code=0 + test_count>=1 + ran_at within 24h (clock-skew 5min slack)`. Hand-written false-pass JSON without these fields → rejected.

**r1 #3 (major) — Mock OAuth construction gate insufficient**
- Patch: server.ts `requireMockEnabled()` — throws boot error unless `STARPIN_ENABLE_MOCK_OAUTH=true` OR `NODE_ENV ∈ {test, development}`. Production deploy with missing real OAuth env → boot fails LOUDLY instead of silently exposing Mock. `docker-compose.prod.yml` sets `STARPIN_ENABLE_MOCK_OAUTH: true` explicitly (prod-sim opt-in).

**r1 #4 (minor) — STARPIN_E2E_PORT not used in wrapper health check**
- Patch: `scripts/run-e2e-smoke.sh` — `PORT="${STARPIN_E2E_PORT:-3000}"`, used in both curl + npx playwright invocation.

**r1 #5 (minor) — console 404 filter too broad**
- Patch: removed broad console filter. New: `page.on('response')` catches all same-origin status>=400, allowlist limited to `/favicon.ico|/robots.txt|/apple-touch-icon*.png`. Real asset 404s now FAIL the smoke (proven: caught missing `/v1/catalog/viewport` route).

**r1 #6 (minor) — HC-12 scope-limit explicit**
- Patch: same row as #1 (combined).

**r1 #7 (nit) — version labels v1.8**
- Patch: HARNESS.md, .githooks/{README, pre-push, pre-commit, commit-msg} all bumped to v1.9.

## Side-finding from r1 #5

While patching #5, the tightened smoke caught a *separate* product bug: `/v1/catalog/viewport` returns 404. Root cause: no Fastify route file for catalog viewport — the v0.5 web-demo called this endpoint, but no route was ever wired. Silent for 5 ship rounds (v0.5~v0.9).

**Fix**: `backend/src/routes/catalog-routes.ts` (NEW) — exposes existing `CatalogService.viewport()` as `GET /v1/catalog/viewport`, auth-gated. Rate-limited via existing preHandler.

This is exactly the failure mode HC-12 + tightened #5 was designed for.

## Verification expected

- npm run typecheck / lint clean
- 23 unit test suites / 256 tests pass
- E2E smoke pass with evidence JSON (status=pass, exit_code=0, test_count=1, ran_at recent)
- Mock OAuth requires `STARPIN_ENABLE_MOCK_OAUTH=true` to construct in production-shape boot

## Regression scan

- Does the JSON evidence validator handle malformed JSON gracefully? (try/except → exit 1)
- Does the response.status check break when backend serves intentional 401/403 (e.g., /readyz before snapshot loaded)? — login flow doesn't hit these endpoints
- Does the env-gated Mock OAuth break existing backend integration tests? (NODE_ENV=test → mockOAuthEnabled=true → tests OK)
- Does the new `/v1/catalog/viewport` route accidentally bypass rate-limit or auth? — verify hook chain

## Output

REVIEW.template.md. Final verdict:
- r1_closed / r1_partial / r1_open
- new_blockers / new_majors / new_minors
- ready_for_ship: yes | no
- recommendation: ship | patch-before-ship
