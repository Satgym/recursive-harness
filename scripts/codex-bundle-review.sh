#!/usr/bin/env bash
# codex-bundle-review.sh — Wrapper for `codex review` on a *bundle of files*
# (the actual workflow used in v0.5/v0.6 dogfood). This is the formally
# supported path for reviews where:
#   - the review target is a curated set of files (not a clean branch diff)
#   - some/all files are gitignored (e.g., examples/ in this repo)
#   - the prompt must drive the review (not just a diff narrative)
#
# Distinct from:
#   - codex-review.sh: clean branch diff via `codex review --base <branch>`.
#     Use when there's a real PR-sized commit range and prompt is secondary.
#   - codex-exec-review.sh: text-only review (Blueprints / Module Plans /
#     ADRs). Bundle review is the *code* analog of that text path.
#
# Implementation: this is a thin alias to codex-exec-review.sh because
# `codex exec` is the only CLI verb that accepts both a custom prompt and
# uncommitted state on codex 0.132 (v1.8 F129 — `codex review` rejects
# PROMPT + --uncommitted/--commit/--base as mutually exclusive). The shell
# layer normalizes the metadata so postprocess records `review_type=bundle`.
#
# Usage:
#   scripts/codex-bundle-review.sh --prompt-file <path>
#                                  [--phase <id>] [--slug <name>]
#                                  [--review-round <e.g. r2>] [--prior-review <path>]
#                                  [--severity <enum>] [--target <text>]
#
# All arguments forward to codex-exec-review.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# v1.8 r1 #8 — intercept --help so users see bundle-wrapper documentation
# instead of the underlying codex-exec-review.sh help. All other flags pass
# through.
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      sed -n '2,/^set -euo pipefail/p' "$0" | sed '$d' | sed 's/^# //;s/^#$//'
      echo ""
      echo "All other flags forward to codex-exec-review.sh. Run:"
      echo "  $SCRIPT_DIR/codex-exec-review.sh --help"
      echo "for the full flag list (this wrapper is a thin alias)."
      exit 0
      ;;
  esac
done

exec "$SCRIPT_DIR/codex-exec-review.sh" "$@"
