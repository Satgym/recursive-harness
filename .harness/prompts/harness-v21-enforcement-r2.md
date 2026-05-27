r2 verification of Hara v2.1 enforcement gap pass (ADR-022).

## r1 history (`.harness/reviews/harness-20260528-v21-enforcement.md`)

**Verdict**: block. 1 major finding:
- Subjects with no scope in parens (e.g. `harness(v2.0.0)`) had `scope=""`, so the scope_ok guard was disabled, allowing unrelated `04-...-starpin-v20.md` reviews to satisfy the gate.

**Closure**: pre-push hook now extracts the *commit type* (`harness`/`code`/`note`) as a fallback scope when the parenthesized slug is just a version. Verification:
- `git push --dry-run` for `harness(v2.0.0)` still PASSES (real review files contain `harness` substring → scope_ok=1)
- Simulation `04-fp-starpin-v20.md`: scope=`harness`, variant=`v20`, scope_ok=0 → would NOT satisfy. False-positive closed.

## r2 task

1. Walk through the closure logic with `harness(v2.0.0)` again to confirm both halves work:
   - Real files `harness-20260527-v20-trim.md` (r1) + `harness-20260527-v20-trim-r2.md` (r2) → both pass scope_ok and round bucketing.
   - Adversarial `04-...-starpin-v20.md` + `-r2` → scope_ok=0 → not counted.

2. Edge case: `note(starpin-v0.11.0)` is still exempt from HC-11 file presence (the `ship_pattern` at line 26 excludes `note(`). Confirm exemption still holds — v2.1 didn't accidentally bring note() into the gate.

3. Edge case: `code(starpin-v0.6.0)` (which DOES have explicit scope in parens) — primary=`starpin-v0.6.0`, scope=`starpin` (from `${primary%-v*}` strip), version=`v0.6.0`. commit_type fallback doesn't activate. variants={primary, version, v060, v06}. Confirm filenames like `04-20260527-v06-ingest-r2.md` match (contain `v06` AND `starpin` not required since variant=primary covers it... wait, does it?).

   Walk through this case in detail. Does the `code(starpin-v0.6.0)` ship find r1+r2 in starpin-v06-* files? Or do they need `starpin-v0.6.0` substring?

4. monorepo gate + HARNESS edits + ADR-022 fact density — re-confirm r1 closures.

Verdict: ship | block | minor-followup. Concise.
