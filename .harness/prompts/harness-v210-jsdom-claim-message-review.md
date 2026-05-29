# Codex review — Hara v2.10 jsdom infra + claim-message real-DOM test

Closes v2.8 carry (partial). v2.8 unlocked frontend test imports via jest
tsconfig rootDir override; claim-message.test.ts couldn't migrate to direct
production imports because its 6 tests used StubNode DOM simulator (node
test env has no `document`). v2.10 adds jest-environment-jsdom dep + a new
test file that uses real DOM via `@jest-environment jsdom` pragma.

## Files in scope

- `backend/package.json` — added `jest-environment-jsdom@^30.4.1` devDep
- `backend/tests/unit/web/claim-message-real-dom.test.ts` (NEW, ~110 LOC) —
  6 tests against real DOM exercising production `renderInbox`:
  1. empty inbox → "메시지 없음" placeholder
  2. INV-XSS: `<img>` body → no `<img>` created; text entity-escaped
  3. INV-XSS: `<script>` nickname → no `<script>` created; sender escaped
  4. 3 messages render in order + `data-message-id` attribute
  5. delete button has `type=button`, `data-action`, `data-message-id`
  6. subsequent renders cleanly swap content

Existing `claim-message.test.ts` (StubNode) untouched — full StubNode → real
DOM migration deferred to v2.10.x carry.

- `HARNESS.md` (title v2.9 → v2.10; §11 row added)
- `DECISIONS.md` (ADR-050 added)
- `STATUS.md` updated

## Validation

- `npm --prefix backend test`: **494 pass / 3 skip / 0 fail / 0 regression**
  (baseline 488 → +6 new)
- Coexistence: node env (default) + jsdom env (per-file pragma) both run in
  same suite without conflict.

## What to evaluate

### A. Activation strategy: per-file pragma vs global env

Two options for jsdom activation:
- (a) Per-file `@jest-environment jsdom` pragma (chosen) — explicit, opt-in,
  keeps 47 other test files in fast node env
- (b) Global `testEnvironment: 'jsdom'` in jest.config.mjs — every test
  pays ~50ms jsdom startup, but uniform

We picked (a). Is this the right call?

### B. claim-message.ts bootstrap side effect

`claim-message.ts` exports `renderInbox` (which we test) but ALSO has
`bootstrapClaimPage()` at the bottom + a window load-event hook that calls
`document.location.assign('/login.html')` when no session present. In jsdom
env this throws a non-fatal log: `Not implemented: navigation`. Tests still
pass (renderInbox is what we exercise). Is this acceptable? Or should we
guard the bootstrap behind a `document.location.pathname.includes('claim')`
check to avoid the noise?

### C. Test coverage choice

6 tests focus on renderInbox structural + XSS contracts. We do NOT test
the production `wireClaimSection` / `wireComposeSection` / `wireInboxSection`
which depend on event listeners + fetch. Those stay as the StubNode test's
optimistic-delete simulator. Acceptable v2.10 scope?

### D. v2.10.x carry plan

ADR-050 names "full StubNode migration" as the carry. Reasonable defer?

### E. Verdict

`pass | minor | major | block` + rationale.
