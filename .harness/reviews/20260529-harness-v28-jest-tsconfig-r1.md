---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.8) jest tsconfig override + 2 frontend test migration
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e71b4-a5bb-7003-a8a3-a07e95e05205
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 85789
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T03:08
  prompt_source: .harness/prompts/harness-v28-jest-tsconfig-override-review.md
---

**REVIEW**

Findings: no blocker / major / minor findings.

`info` — ts-jest semantics correction  
위치: [config-set.js](/Users/satgym/work/harness/examples/starpin/backend/node_modules/ts-jest/dist/legacy/config/config-set.js:513), [jest.config.mjs](/Users/satgym/work/harness/examples/starpin/backend/jest.config.mjs:21)  
근거: ts-jest 29.4.11 does read the discovered project `tsconfig.json`, then overlays inline `compilerOptions` via `{ ...config.compilerOptions, ...compilerOptions }`. So the prompt’s “inline tsconfig is the full config object, not a merge” premise is refuted.  
제안: no code change needed. The effective result is still correct: inline `rootDir: '.'` wins over project `rootDir: './src'`.

**Evaluation**

A. Override scope: acceptable. `rootDir: '.'` is an effective compilerOptions override for ts-jest transforms, while production builds still use [tsconfig.json](/Users/satgym/work/harness/examples/starpin/backend/tsconfig.json:8) and [tsconfig.web.json](/Users/satgym/work/harness/examples/starpin/backend/tsconfig.web.json:7). It widens test compilation to `backend/`, not outside it; imports above `backend/` should still be outside `rootDir` and fail rather than silently expand scope.

B. Test migration: acceptable. [shell-escape-html.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/unit/web/shell-escape-html.test.ts:22) now tests the real `escapeHtml` export, and shell boot is document-guarded. Removing the duplicate improves drift detection.

C. Claim-message staging: acceptable. [claim-message.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/unit/web/claim-message.test.ts:4) clearly documents that the duplicate remains because the test relies on a StubNode DOM simulator. Keeping jsdom as v2.9 is the right chunking.

Validation run locally:
- `npm --prefix backend run build`: pass
- scoped Jest web tests: 3 suites / 27 tests pass

Verdict: `pass` — the implementation is scoped correctly, production build risk is contained, and the only correction is explanatory: ts-jest merges compilerOptions, but the override still has the intended effect.
