You are reviewing **Hara v1.9 (HC-12 User-Flow-Verified) + starpin v0.10 (login fix)**. Two paired changes triggered by user sharp post-mortem ("시작부터 겪을 버그에 대한 검증 절차도 없었어?") — starpin v0.5~v0.9 shipped a broken login flow 5 times because no gate ever validated "click Login → reach app". v1.9 closes the gap; v0.10 = the dogfood fix that *would have been blocked* by the new gate.

## Artifacts under review

**Harness (in-repo)**:
- `HARNESS.md` — HC-12 row added to §1
- `.githooks/pre-push` — UI surface detection + e2e evidence check
- `.githooks/README.md` — HC-12 documentation
- `DECISIONS.md` — ADR-017 (Hara v1.9 HC-12) + ADR-018 (starpin v0.10 fixes)

**starpin (gitignored examples/ — review by reading filesystem)**:
- `backend/playwright.config.ts` (NEW)
- `backend/tests/e2e/login-smoke.spec.ts` (NEW)
- `scripts/run-e2e-smoke.sh` (NEW)
- `backend/package.json` — `+ @playwright/test` devDep
- `backend/src/auth/providers/mock.ts` — doc comment only (logic unchanged; accepts relative authorize_url base)
- `backend/src/server.ts` — `mockAuthorizeBase()` helper returns `/dev-oauth-stub.html`
- `backend/public/dev-oauth-stub.html` + `lib/dev-oauth-stub.ts` (NEW)
- `backend/public/lib/auth-client.ts::handleCallback` — nickname null tolerance

## Direct dogfood evidence

- E2E smoke `tests/e2e/login-smoke.spec.ts` ran against starpin v0.9-shipped state → FAILED (timed out reaching /sky.html). HC-12 caught the bug v0.5~v0.9 had.
- After Mock OAuth + frontend nickname fixes → smoke PASSED.
- Evidence: `.harness/runs/e2e-20260527-login-smoke.json` (`status: pass`, `duration_ms: 1389`).

## YOUR REVIEW

### PART A — HC-12 design + enforcement

A.1 **HC-12 wording in HARNESS.md** — calibrated correctly? Specifically: "UI surface가 있는 프로젝트" — is the heuristic (`public/` or `frontend/` tracked path) too narrow / broad? What about pure SPA projects without those dir names? Mobile native (iOS/Android)?

A.2 **Pre-push hook detection logic** — `git ls-tree -r --name-only HEAD | grep public/|frontend/`. Edge cases: monorepos with multiple UI surfaces, projects with `dist/public/` only, projects naming differently (`web/`, `client/`).

A.3 **24h evidence freshness** — too tight (fails on weekend if smoke ran Friday)? Too loose (allows stale gating)? What if dev machine clock is wrong?

A.4 **Bypass policy** — `--no-verify` still possible; documented as "explicit user authorization required". Acceptable, matches HC-11 pattern.

A.5 **HC-11 vs HC-12 ordering** — current hook runs HC-11 first then HC-12. Is HC-12 useful when HC-11 already gates codex review? (Codex review catches code-level; HC-12 catches composition. Complementary.)

### PART B — Playwright infra correctness

B.1 **Single-test smoke vs multi-test** — only 1 test (login flow). When user has more flows (claim, message), should v1.10 require *each* user-facing entry point to have a smoke? Or is "first user flow" sufficient?

B.2 **Headless chromium only** — adequate for catch-rate? Will real Safari quirks (mobile users on iOS) be caught only after prod incident?

B.3 **`scripts/run-e2e-smoke.sh` evidence JSON shape** — minimal but parseable. Should it include test names (currently just `slug`)? Should pre-push verify count > 0?

B.4 **Smoke depends on prod-sim being up** — operator must start compose first. Should the wrapper auto-start + auto-shutdown? (Currently doesn't, so smoke result reflects compose state operator chose.)

B.5 **Console error filter** — ignores `Failed to load resource.*\(Not Found\)`. Could hide real product bugs (e.g., a critical asset 404). Should this be tightened to specific resource patterns (favicon, robots.txt) only?

### PART C — starpin v0.10 fix correctness

C.1 **Mock authorize_url relative URL** — `/dev-oauth-stub.html` (no origin). Browser resolves against current origin. What about cross-origin OAuth flows in real prod? (Doesn't apply — Mock is dev-only.)

C.2 **dev-oauth-stub.ts code synthesis** — `mock-devuser001-dev@starpin.local`. Same dev user every time → same `(provider, sub)` upsert → idempotent dev session. Acceptable for dev. v0.11+ carry: per-session unique sub so concurrent devs don't collide.

C.3 **dev-oauth-stub timing** — 400ms delay before redirect. Smoke test 15s timeout / actual flow ~600ms. Adequate.

C.4 **nickname fallback in handleCallback** — `user-${user_id.slice(0,8)}`. Predictable but not user-friendly. v0.11 carry to nickname-setup screen. Confirm: no XSS risk (escapeHtml runs on display anyway).

C.5 **HC-9 implications** — dev-oauth-stub is a backdoor that could be misused in production. Currently gated by Mock provider being constructed (provider config absent). Add an additional `NODE_ENV !== 'production'` guard at the route layer? Or rely on the construction gate?

### PART D — Cross-cutting + harness discipline

D.1 **v1.8 minimize discipline** — v1.9 adds HC-12 to HARNESS.md. Net length: +3 lines for HC-12 row + 1 line addition to enforcement summary. Within the "minimize" spirit (only critical gates).

D.2 **Hook enforces ≠ Claude can skip** — HC-12 hook actually runs `find -mmin -60*24` etc.; Claude can't fake the JSON file because timestamps/content are verifiable. But what if Claude writes a `pass` JSON without actually running tests? (Hook only checks file content + mtime — could be forged.) Acceptable risk or harden?

D.3 **Skill template missing** — ADR mentions `.harness/skills/ui-flow-smoke.md` as v1.10 carry. Currently no template. Local projects must improvise. Acceptable for v1.9 ship.

D.4 **HC-11 carve-out interaction** — `note(...)` ship type still exempts HC-11; does it also exempt HC-12? (Yes — `note(...)` doesn't match the ship_pattern that triggers the UI-surface check. Confirmed by reading the hook code.)

D.5 **Self-test** — runs the new pre-push hook against the v1.9 ship commit (which has `public/` in examples/starpin/ but examples/ is gitignored, so git ls-tree won't find `public/`). What does HC-12 do for *this* commit? (Should not fire — harness repo has no UI surface itself.)

### PART E — overall

E.1 **5 ship rounds of regression** — does v0.5/v0.7/v0.9 STATUS need amendment ("ship was incomplete; v0.10 fixes")?

E.2 **Future regression prevention** — could this same class of "composition bug" appear in non-UI surfaces? (e.g., CLI tool's first-command-doesn't-work). Should HC-12 generalize to "first user action verified"?

E.3 **What's NOT in HC-12 scope** — performance regressions, security regressions, data-loss regressions. v1.9 only covers first-flow happy path. Should that limit be explicit in HC-12 wording?

## Output

REVIEW.template.md format. Severity: blocker / major / minor / nit. HC-7/8/9/11/12 violations = blocker. Final verdict: ready_for_ship + recommendation.
