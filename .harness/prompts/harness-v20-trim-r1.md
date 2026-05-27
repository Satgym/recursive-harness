You are reviewing **Hara v2.0 — trim discipline pass (ADR-020)**. This is a harness *self-change*; all harness self-changes require codex r1+r2 (HC-11).

## Context

User direction (2026-05-27, recorded in memory `feedback_harness_minimalism`): the harness has been growing each version through a "not-followed → add rule → harder-to-read → less-followed" loop. They want the opposite gradient — aggressive trimming of what isn't load-bearing, tolerance for natural session drift if the project outcome is fine. No new HC; collapse what's documentation theater.

## Changes under review

Single commit (uncommitted at review time):
- `HARNESS.md`: preamble adds "Trim over append" operating principle (v2.0). HC-12 row compressed (130-char single line → core rule + ADR-017 pointer for scope detail). Version history table collapsed (v1.0/v1.1/v1.8/v1.9/v2.0 kept; v1.2~v1.7 archived to PATTERNS.md §history).
- `STATUS.md`: full rewrite. 180 → 49 lines. Removed sections: `Approved artifacts` (v1.0~v1.2 era records — historical bedrock, never re-consulted), `Decision summary` (duplicates DECISIONS.md), `Roadmap` (stale Phase H/I), `Open findings F41-F47` (untouched 20+ ships, never escalated), `Notes cumulative tokens` (stale). Preserved: `Current`, `Active gate`, `Required reads`, `Recent ships`, user-direction `Notes`.
- `PATTERNS.md`: `§session-bridging` removed (duplicates STATUS Required reads + CLAUDE.md). `§history` recast as version archive table.
- `DECISIONS.md`: ADR-020 added documenting all of the above.
- `FLEET.md`: unchanged.
- No hook changes. No HC added/removed.

## YOUR REVIEW

### PART A — Trim safety

A.1 Does any removed STATUS section contain *load-bearing* information (not retrievable from git log + DECISIONS.md + memory)? Walk the diff for anything that future-sessions would actually need.

A.2 The HC-12 row was compressed: the "scope explicit" elaboration moved to ADR-017. Verify ADR-017 *does* contain the elaboration (it should — ADR-017 was the v1.9 introducing ADR), so the pointer is honored.

A.3 PATTERNS.md `§session-bridging` is gone. Verify STATUS.md "Required reads" + CLAUDE.md cover the same ground (5-step session start). If there's a gap, surface it.

A.4 v1.2~v1.7 version detail moved from HARNESS §11 to PATTERNS §history. Verify the archive table preserves the ADR pointers + key feature labels.

### PART B — Anti-bloat regression risk

B.1 Did ADR-020 itself become a new flavor of bloat? (e.g., 100+ lines of trim-discipline meta-text). Read the ADR and judge whether it's a fact-rich record or just self-congratulation.

B.2 Future-Claude reading `HARNESS.md` cold — is the "Trim over append" preamble strong enough to actually *deter* the next rule-bloat instinct, or is it cosmetic? Suggest a stronger phrasing if helpful.

### PART C — Behavior preservation

C.1 All HCs HC-1~HC-12 present with their original meaning? (HC-12 was compressed but the rule itself unchanged.)
C.2 Hook enforcement (HC-6/HC-11/HC-12) untouched? `.githooks/` not modified?
C.3 `scripts/` workflow unchanged?

### PART D — Ship readiness

Final verdict: **ship | block | minor-followup**.

## OUTPUT

Standard REVIEW format. Apply harness-minimalism direction even to your own review: skip cosmetic findings unless they signal a real risk. Be concise. Under-flagging is preferred over over-flagging in this round.
