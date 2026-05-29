# Codex r2 review — Hara v2.6 §dom-mutation-order grep (post-r1 patch)

You previously gave verdict `minor` on r1 (`.harness/reviews/20260529-harness-v26-dom-grep-r1.md`). r2 re-evaluates after the 4 patches below.

## Patches applied since r1

1. **scripts/check-subagent-prompt.sh `--help` docstring** — added a 5-line
   summary of the 3 `--strict` extra requirements (impl-review path / ARIA /
   DOM mutation), so `--help` users see what `--strict` adds.

2. **scripts/check-subagent-prompt.sh imperative regex** — extended from 4
   aliases to 7. New: `mount after clear`, `clear before mount`, `after cleanup`.
   r1 suggested these as natural-language phrasings authors might reach for.

3. **scripts/check-subagent-prompt.sh inline comment** — corrected the
   "backend-only" claim to "lib path + DOM API 둘 다 없으면 trigger 안 함"
   and noted v2.6.1 carry on API set extension.

4. **PATTERNS.md + DECISIONS.md ADR-041** — narrowed the "false-fire 0"
   wording per r1 minor #1. Both docs now state:
   - No-trigger case = pure backend / schema / spec (no path + no DOM API)
   - Possible false-fire = `backend/public/lib/` substring + pure helper without mutation
   - Cost of false-fire = imperative one line (≤30s)
   - v2.6.1 carry explicit: `replaceChildren` / `insertBefore` / `replaceWith` / `textContent = ''`

## Post-patch self-test

```
v0.19 (pre-v2.5):                                       FAIL  (ARIA earlier — DOM would also)
v0.20 (the bug origin):                                 FAIL  (DOM grep — intended catch)
v0.21 (post-v2.5 imperative present):                   PASS
synthetic backend-only (--mode=impl --strict):          PASS  (no false-fire)
synthetic frontend WITH new alias 'clear before mount': PASS  (new aliases recognized)
```

## What to evaluate now

1. **Did the patches resolve r1 minor concerns?** ARIA-docstring discoverability;
   imperative regex breadth; doc precision on false-fire.
2. **Any new concerns introduced?** Verbosity creep / docstring drift / regex
   over-broadening (e.g. `after cleanup` matches in unrelated copy).
3. **Final verdict**: `pass` / `minor` / `major` / `block` + 1-2 sentence rationale.

## Diff context

`git diff --stat` since r1:
```
DECISIONS.md                     | 7 ++++---  (3 lines softened in Decision/Consequences)
PATTERNS.md                      | 11 ++++++++++- (new no-trigger / false-fire / carry block)
scripts/check-subagent-prompt.sh | 13 +++++++++++- (--help docstring + imperative regex 4→7 + comment)
```
