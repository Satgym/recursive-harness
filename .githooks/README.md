# Hara git hooks (v1.8)

These hooks enforce the few rules Claude+codex dogfood proved get forgotten.
Hooks fire whether the agent remembers the harness rules or not — that's the
point.

## Install (once per clone)

```bash
git config core.hooksPath .githooks
```

That's it. The hooks live in this directory and are committed to the repo
(unlike `.git/hooks/` which is per-clone local state).

## What each hook does

### `pre-commit`

1. **Status freshness** — if `RELEASE.md` is staged, `STATUS.md` must be staged in the same commit. (Catches the v0.6 r2 #21 pattern.)
2. **Capability-candidate auto-collect** — when a `reviews/*.md` or `merge-report.md` is staged, extract every `capability_candidate: yes` block and append to `.harness/capability-candidates.md`. The updated file is auto-staged.
3. **Best-effort typecheck** — runs `npx tsc --noEmit` on `.ts` changes when present. Warning only, not blocking.

### `commit-msg`

1. **WIP residue** — if the new commit subject matches the ship pattern `(code|harness|note)(…vN.N.N)` and any of the last 10 commits start with `wip(`, fail. Squash WIPs into the ship commit first.

### `pre-push`

1. **Codex evidence** — if any pushed commit subject matches `(code|harness|note)(…vN.N.N)` (the ship form), at least one codex review file must have landed in the last 20 commits. Otherwise fail with the bundle-review command to run.

## Bypass

`git commit --no-verify` / `git push --no-verify` bypass the hooks. **Claude must not use these without explicit user authorization** — they exist for human emergency use, not autonomous agent shortcuts.

## Why hooks (not more harness docs)

v0.5/v0.6 dogfood data: the harness *prescribed* most of what these hooks now enforce, but Claude skipped steps under context pressure / fluid work. Hooks remove the "agent might forget" failure mode by making the rule fire automatically at git operation time. See `DECISIONS.md` ADR-012 for the rationale.
