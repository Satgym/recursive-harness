#!/usr/bin/env bash
# check-subagent-prompt.sh — Hara v2.4 helper.
#
# SCOPE: This lint is for *implementer* subagent prompts (Phase 03 work). It is
# NOT meant for codex *review* prompts — reviewers don't produce deliverables,
# they evaluate them. Reviewer prompts will (correctly) fail 5/5 if run through
# this wrapper. If unsure: only run on prompts that dispatch background work
# expected to write code/styling/tests/fixtures.
#
# Lints a subagent prompt file for PATTERNS §deliverable-categories 5 headings:
#   1. Code
#   2. Styling
#   3. Tests
#   4. Fixture
#   5. impl review (or "impl-review")
#
# Each heading must appear as a markdown subsection under "## Deliverables" or
# at the top level. Missing headings → fail with the list. Headings present but
# explicitly "N/A — <reason>" → pass (per v2.3.2 discipline).
#
# Usage:
#   scripts/check-subagent-prompt.sh <prompt-file.md>
#   scripts/check-subagent-prompt.sh --strict <prompt-file.md>   # also require an impl-review path
#
# Exit codes:
#   0  all 5 headings present (or explicit N/A)
#   1  one or more headings missing
#   2  prompt file not found

set -uo pipefail

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
  shift
fi

PROMPT="${1:?usage: scripts/check-subagent-prompt.sh [--strict] <prompt-file.md>}"
[[ ! -f "$PROMPT" ]] && { echo "[check-subagent-prompt] file not found: $PROMPT" >&2; exit 2; }

# Heading patterns — line starting with '#' (any level), followed by a category
# keyword. Case-insensitive. Matches `### 1. Code`, `## Code`, `### Code (NEW)`,
# `### 2. Styling (...)`, etc.
declare -a CATEGORIES=("Code" "Styling" "Tests?" "Fixture" "impl[ -]?review")
declare -a LABELS=("Code" "Styling" "Tests" "Fixture" "impl-review")

missing=()
for i in "${!CATEGORIES[@]}"; do
  cat="${CATEGORIES[$i]}"
  label="${LABELS[$i]}"
  # Match: ^#{1,6}\s+(?:\d+\.\s*)?<cat>\b
  if ! grep -qiE "^#{1,6}[[:space:]]+([0-9]+\.[[:space:]]*)?${cat}([[:space:]]|/|\(|$)" "$PROMPT"; then
    missing+=("$label")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "[check-subagent-prompt] FAIL: missing $((${#missing[@]})) of 5 deliverable categories:" >&2
  for m in "${missing[@]}"; do echo "  - $m" >&2; done
  echo "[check-subagent-prompt]   add each as a markdown heading (e.g. '### 1. Code'). For" >&2
  echo "[check-subagent-prompt]   genuinely irrelevant categories use 'N/A — <reason>' body." >&2
  echo "[check-subagent-prompt]   see PATTERNS.md §deliverable-categories for template." >&2
  exit 1
fi

# --strict: also require an explicit impl-review path mention.
# v2.4 r1 codex #1: regex was too loose (matched *-implementation-notes.md);
# tighten to require the literal `-impl.md` suffix.
if [[ $STRICT -eq 1 ]]; then
  if ! grep -qE '\.harness/reviews/[^[:space:]`)]*-impl\.md([[:space:]`),.]|$)' "$PROMPT"; then
    echo "[check-subagent-prompt] FAIL (--strict): no '.harness/reviews/...-impl.md' path in prompt" >&2
    echo "[check-subagent-prompt]   subagent needs explicit destination for impl-review doc" >&2
    exit 1
  fi
fi

echo "[check-subagent-prompt] PASS — 5/5 deliverable categories present"
exit 0
