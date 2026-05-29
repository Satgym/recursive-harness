# Codex review prompt — Hara v2.8 jest tsconfig rootDir override

You are an independent reviewer for a *very small surface* Hara ship that
closes the v0.23 carry "jest tsconfig override unlocks public/lib/ frontend
test imports".

## Target

`harness(v2.8)` — Adds `rootDir: '.'` to the ts-jest inline tsconfig in
`starpin/backend/jest.config.mjs`, widening the test compilation rootDir from
the project tsconfig's `./src` to backend/. This lets test files import
production frontend code (`public/lib/*.js`) directly without TS6059.

## Files in scope

- `examples/starpin/backend/jest.config.mjs` (+12 lines: 1 line config + 11 line comment)
- `examples/starpin/backend/tests/unit/web/shell-escape-html.test.ts` (-30 lines duplicate, +1 line import)
- `examples/starpin/backend/tests/unit/web/sky-highlight-cache-only.test.ts` (-5 lines `@ts-nocheck` block)
- `examples/starpin/backend/tests/unit/web/claim-message.test.ts` (-9 lines BLOCKER comment, +5 lines v2.8 status — DOM-sim duplicate KEPT)
- `HARNESS.md` (+1 v2.8 row in §11 history)
- `DECISIONS.md` (+62 lines ADR-045)
- `STATUS.md` (v2.7 retro SHIPPED, v2.8 pending)

## Diff details

### A. jest.config.mjs

```diff
  tsconfig: {
    target: 'ES2023',
    module: 'ES2022',
    moduleResolution: 'bundler',
+   // v2.8 (Hara) — widen rootDir from project tsconfig's './src' to '.'
+   // (backend/) so tests can `import from '../../../public/lib/...'`
+   // without TS6059. Production build (tsconfig.json + tsconfig.web.json)
+   // is unaffected; this override applies only to ts-jest transforms.
+   rootDir: '.',
    strict: false,
    esModuleInterop: true,
    allowJs: true,
  },
```

### B. shell-escape-html.test.ts migration

```diff
- BLOCKER (PATCH-CANDIDATE for parent — see merge-report.md): tsconfig rootDir './src' ...
- // import { escapeHtml } from '../../../public/lib/shell.js'; // blocked by rootDir
- // Contract-regression duplicate — MUST stay byte-identical to ...
- const ESCAPE_MAP: Readonly<...> = Object.freeze({ ... });
- function escapeHtml(text: string): string { ... }
+ v2.8 (Hara) — jest tsconfig rootDir widened. duplicate 패턴 제거.
+ import { escapeHtml } from '../../../public/lib/shell.js';
```

8 test cases unchanged — all pass against the real import.

### C. sky-highlight-cache-only.test.ts (v0.23)

`@ts-nocheck` pragma + 4-line comment removed. Imports were already direct;
just bypassed by pragma. 4 tests unchanged.

### D. claim-message.test.ts — partial

Comment updated to note v2.8 unlocks the import but `renderInbox` test uses
StubNode DOM simulator (no jsdom in test env), so the byte-equivalent
duplicate stays. Full migration requires jsdom (v2.9 candidate).

## Validation

- `npm --prefix backend run build` clean (production tsc unaffected by jest config)
- `npm --prefix backend test`: **42 suites / 435 pass / 3 skip / 0 fail / 0 regression**
  (baseline 435 from v0.23 ship)

## What to evaluate

### A. Override scope correctness

1. `rootDir: '.'` in jest inline tsconfig — does this REPLACE or MERGE with the
   project tsconfig.json's `rootDir: './src'`? ts-jest semantics: inline
   tsconfig is the full config object for transform purposes (not a merge with
   project tsconfig). So `rootDir: '.'` becomes the effective rootDir for
   transformed files. Confirm or refute.
2. Does this introduce a production-build risk? The 2 production builds use
   tsconfig.json (`include: src/**/*.ts`) and tsconfig.web.json. Neither
   references jest.config.mjs. Confirmed by `npm run build` clean post-change.
3. Any concern with widened rootDir letting test files import outside backend/
   (e.g., `../../../../examples/starpin-fleet/...` if multi-project)?

### B. Test migration correctness

1. shell-escape-html: direct import of `escapeHtml` works because
   - test env is node
   - shell.ts has a `document`-guarded bootstrap that no-ops in node
   - escapeHtml is a pure function
   8 test cases pass identical assertions. Acceptable migration?
2. Was anything lost in removing the contract-duplicate? (e.g., test now fails
   to catch a refactor that renames escapeHtml — but that's the POINT: the
   real import provides contract-coupling that the duplicate could silently
   drift from.)

### C. claim-message DOM simulator decision

The decision to NOT migrate claim-message.test.ts (which uses StubNode) — is
this acceptable? The v2.9 carry is "jsdom 도입 → real DOM migration". Should
v2.8 also add jsdom now, or is the staged approach (jest tsconfig unlock
first, jsdom infra second) the right chunking?

### D. Verdict

`pass | minor | major | block` + 1-2 sentence rationale.
