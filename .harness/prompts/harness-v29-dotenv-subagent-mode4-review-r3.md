# Codex r3 — Hara v2.9 (post-r2 empty-file edge fix)

r2 verdict was `minor`: empty-value edge case (`.env.local` has empty
`CAPACITOR_SERVER_URL=` while `.env` has non-empty) — detector kept walking
to `.env` and warned, but Capacitor at runtime sees empty (dotenv first-set-
wins). False positive.

## r2 → r3 patch

`examples/starpin/scripts/run-mobile-smoke.sh` — change loop break condition
from "value non-empty" to "key line found":

```diff
- from_file=$(grep -E '^CAPACITOR_SERVER_URL=' "$f" ... | ... )
- [[ -n "$from_file" ]] && break
+ if grep -qE '^CAPACITOR_SERVER_URL=' "$f" 2>/dev/null; then
+   from_file=$(grep -E '^CAPACITOR_SERVER_URL=' "$f" ... | ... )
+   break
+ fi
```

Final emit guard `[[ -n "$effective" ]]` still filters empty → no warning
emitted when first match defines but doesn't populate.

PATTERNS.md §smoke-setup snippet sync'd.

## Validation

**7-case self-test PASS**:
1. no env file → no warning ✓
2. `.env.local` with URL → warning ✓
3. `.env` only with URL → warning ✓
4. `.env.production` only with URL → warning ✓
5. `.env.local` empty + `.env` URL → no warning (r2 edge — was false pos) ✓
6. `.env.local` quoted-empty + `.env` URL → no warning (r2 edge variant) ✓
7. `.env.local` non-CAPACITOR var + `.env` URL → warning (fallthrough OK) ✓

`bash -n` clean. `npm test` 472 pass / 0 regression.

## What to confirm

1. Loop now matches dotenv first-set-wins semantics for both empty AND
   non-empty values.
2. PATTERNS snippet stays in sync with script.
3. Final verdict.
