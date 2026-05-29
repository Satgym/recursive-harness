# Codex review prompt — Hara v2.6 §dom-mutation-order grep enforcement

You are an independent reviewer for a *small surface* Hara harness ship.

## Target

`harness(v2.6)` — extends `scripts/check-subagent-prompt.sh --strict` with a
new grep rule that enforces PATTERNS §dom-mutation-order imperative on any
subagent prompt that mentions frontend lib paths or DOM mutation APIs. v2.5
codified the pattern; v2.6 makes it a lint-level gate.

## Files in scope

- `scripts/check-subagent-prompt.sh` — header comment + new --strict block
- `PATTERNS.md` — §dom-mutation-order "v2.6 carry" sentence replaced with
  enforcement description; §smoke-setup carry parenthetical removed
- `HARNESS.md` — title v2.5 → v2.6; v2.6 row added to §11 history table
- `DECISIONS.md` — ADR-041 added (above ADR-040, per "새 ADR은 위에" rule)
- `STATUS.md` — pending row for v2.6; v0.21 retained as last shipped

(`git diff --stat` shows 5 files, ~68 lines.)

## Diff summary

```
scripts/check-subagent-prompt.sh:
  Added v2.6 block after the v2.4.2 ARIA block (still inside --strict guard):
  - Trigger: grep '(public/lib/|removeChild|firstChild|appendChild|innerHTML)'
  - Required: grep -i '\b(DOM mutation|mutation order|dom-mutation-order|mount AFTER)\b'
  - Exit 1 on miss; same diagnostic shape as ARIA path.

PATTERNS.md:
  §dom-mutation-order — "향후 v2.6 carry: ... grep 으로 enforce" 1-line
  replaced with 5-line description of the new lint behavior + false-fire note.
  §smoke-setup — parenthetical "(v2.6 carry — DOM mutation grep enforcement ...)"
  removed.

HARNESS.md:
  Title v2.5 → v2.6. §11 history gains a v2.6 row above v2.5.

DECISIONS.md:
  ADR-041 inserted between the header rule block and ADR-040.

STATUS.md:
  Last ship pinned at 7b8f048; v2.6 entered as (pending). Active gate updated.
```

## What I want you to evaluate

### A. Correctness of the heuristic

1. **Trigger set** (`public/lib/|removeChild|firstChild|appendChild|innerHTML`):
   - Does this miss any common frontend DOM-touching surface that v0.20-class
     bugs could appear in? (e.g., `insertBefore`, `replaceChild`, `replaceWith`,
     `textContent = ''`, jQuery `.empty()`, React reconciler bypass.)
   - Does it over-fire on plausible backend-only or spec-only prompts? Note
     PATTERNS.md itself contains all those keywords — but the lint is invoked
     only against prompt files, not docs. Confirm or refute.

2. **Imperative set** (`DOM mutation|mutation order|dom-mutation-order|mount AFTER`):
   - Are there reasonable phrasings a future prompt author might use that
     would slip past all four alternates? Suggest additions if so.
   - Is "mount AFTER" too generic — could it fire on unrelated copy?

3. **Trigger vs requirement coupling**: the rule is "if any trigger keyword
   present → require imperative". A frontend prompt that *doesn't* touch DOM
   mutation but mentions `public/lib/` (e.g., add a new pure helper) will
   false-fire. Acceptable tradeoff or should the trigger be tighter (DOM
   APIs only, no path)?

### B. Self-test sufficiency

Self-test results recorded in DECISIONS ADR-041:
```
v0.19 (pre-v2.5):                          FAIL  (ARIA earlier — DOM would also)
v0.20 (the bug origin):                    FAIL  (DOM grep — intended catch)
v0.21 (post-v2.5 imperative present):      PASS
synthetic backend-only (no DOM, no lib):   PASS  (no false-fire)
```

Is this coverage adequate, or is there a missing case (e.g., frontend prompt
without lib path mention but with raw DOM API; impl prompt that *only*
documents reading a DOM-touching file but doesn't modify it)?

### C. Documentation drift

1. PATTERNS.md §dom-mutation-order: did the carry-removal text accurately
   describe the new lint? Is it discoverable from `--help` / error message?
2. HARNESS.md §11 row wording: matches v2.4.2 / v2.5 cadence?
3. ADR-041: does the Decision section cleanly enumerate what changed, and
   does the Consequences section call out both wins and risks?

### D. Verdict format

Conclude with one of: `verdict: pass | minor | major | block`, plus a 1-2
sentence rationale.
- `pass` — ship as-is.
- `minor` — non-blocking nits; ship + open carry.
- `major` — should patch before ship; describe fix.
- `block` — design flaw; describe.

Use this prompt as both r1 input AND r2 input (single-pass review acceptable
for a small-surface harness change; if r1 verdict is major/block, then r2
runs after the patch).
