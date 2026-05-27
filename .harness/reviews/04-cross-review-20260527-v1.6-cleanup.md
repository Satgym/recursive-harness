---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: <see body>
target: <see body>
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e67fb-96c5-7d41-be31-71e41671e191
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 106051
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T05:50
  prompt_source: .harness/prompts/v1.6-cleanup-bundle.md
---

# REVIEW — Hara v1.6 cleanup round

## Findings

### Finding 1: m11 split broke Active capability loading
- **severity**: blocker
- **위치**: [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:70), [SUBTREE-PROMPT.template.md](/Users/satgym/work/harness/templates/SUBTREE-PROMPT.template.md:69)
- **근거**: `claim-exclusivity-contract.md` / `sky-coords-fixture.md` were renamed into directories, but the manifest still points to the deleted `.md` paths. `python3 scripts/fleet/validate_capabilities.py examples/starpin/.harness/capabilities.md` fails on both missing paths. Since SUBTREE-PROMPT now requires children to read every Active local skill file, M3 is not enforceable for these two skills.
- **제안**: Update manifest schema and entries to support split skills explicitly, e.g. `path: .../checklist.md` plus optional `rationale_path`, or keep compatibility shim files at the old `.md` paths. Also fix `# Skills (5 Active)` to the actual active count.
- **capability_candidate**: yes — `capability-manifest-split-skill-schema`, kind: `template_field + validator`.

### Finding 2: M9 same-dir sibling ESLint gate does not catch the starpin v0.3 OAuth case
- **severity**: major
- **위치**: [gen_eslint_lock.py](/Users/satgym/work/harness/scripts/fleet/gen_eslint_lock.py:350), [oauth-apple locked-interface](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v03/oauth-apple/locked-interface.md:1)
- **근거**: Layer 4 only activates when `public_module_path` exists, but the v03 OAuth locked-interfaces do not have that field. Generated `eslint.config.oauth-apple.mjs` contains no `./google.js` deny pattern. Manual test in `examples/starpin/backend`:
  `printf "import { GoogleOAuthProvider } from './google.js';\n..." | ./node_modules/.bin/eslint --config eslint.config.oauth-apple.mjs --no-config-lookup --stdin --stdin-filename src/auth/providers/apple.ts`
  exited `0`, so `apple.ts -> ./google.js` is not caught.
- **제안**: Retrofit v03 locked-interfaces with `public_module_path`, regenerate configs, and add a regression test that lints a stdin/file fixture importing `./google.js` from `apple.ts` and expects failure. Consider failing closed when a child has file ownership for a single `.ts` file but no `public_module_path`.
- **capability_candidate**: yes — `eslint-lock-regression-fixtures`, kind: `skill/test`.

### Finding 3: m12 archive left live references to moved artifacts
- **severity**: major
- **위치**: [synthesize-local-layer.md](/Users/satgym/work/harness/skills/synthesize-local-layer.md:38), [templates/README.md](/Users/satgym/work/harness/templates/README.md:17), [new-project.sh](/Users/satgym/work/harness/scripts/new-project.sh:139), [DECISIONS.md](/Users/satgym/work/harness/DECISIONS.md:31)
- **근거**: `templates/LOCAL-ROLE.template.md` and `project-types/_generic/esm-jest-pattern.md` moved to `_incubating/`, but active docs/scripts still point to the old paths. `synthesize-local-layer` still instructs copying a nonexistent role template, and `new-project.sh` emits a broken README link.
- **제안**: Either restore active artifacts or update all live references to mark them incubating/non-working. For local roles, provide a current active creation path if role synthesis remains supported.
- **capability_candidate**: yes — `dead-artifact-reference-scan`, kind: `skill`.

### Finding 4: root STATUS is not current-only and contradicts the v1.6 cleanup state
- **severity**: major
- **위치**: [STATUS.md](/Users/satgym/work/harness/STATUS.md:11), [STATUS.md](/Users/satgym/work/harness/STATUS.md:150)
- **근거**: Root STATUS still says harness version is `v1.3 + v1.4/v1.5/v1.7 inflight`, ADR-012 is awaiting approval, and next action is v1.3 approval. The user’s review bundle describes v1.6 cleanup already applied. starpin local STATUS cross-references this root STATUS, so B1 stranger-proof closure is incomplete.
- **제안**: Rewrite root STATUS to current-only v1.6 cleanup review state, with exact open findings and next action from this review round.
- **capability_candidate**: yes — `status-current-only-handoff-check`, kind: `template_field/checklist`.

### Finding 5: validate_capabilities.py mis-parses roles as skills
- **severity**: major
- **위치**: [validate_capabilities.py](/Users/satgym/work/harness/scripts/fleet/validate_capabilities.py:55)
- **근거**: The parser assigns one section name per fenced YAML block, so starpin’s `# Roles` entries inside the same block are counted under `Skills`. The validator reports `Skills: 8 entries` and finds no `Roles` section. This makes M4’s validator unreliable even after the missing path issue is fixed.
- **제안**: Treat `# Skills` / `# Roles` comments inside a YAML block as section boundaries, or require separate fenced blocks and validate that shape. Align the canonical status set with the stated schema.
- **capability_candidate**: no — validator implementation bug, not a reusable project capability.

## Overall verdict

- **new_blockers**: 1
- **new_majors**: 4
- **ready_for_next_phase**: no

HARNESS body size did shrink to 559 lines, and the checklist/rationale split is valuable in shape, but it is not wired through the manifest yet. M3/M9/M12 are therefore not closed as claimed.
