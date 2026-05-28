#!/usr/bin/env bash
# check-subagent-prompt.sh — Hara v2.4 helper (v2.4.1: --mode flag added).
#
# SCOPE: This lint is for *implementer* subagent prompts (Phase 03 work). It is
# NOT meant for codex *review* prompts — reviewers don't produce deliverables,
# they evaluate them. Reviewer prompts will (correctly) fail 5/5 if forced
# through impl mode.
#
# Lints a subagent prompt file for PATTERNS §deliverable-categories 5 headings:
#   1. Code
#   2. Styling
#   3. Tests
#   4. Fixture
#   5. impl review (or "impl-review")
#
# Each heading must appear as a markdown subsection. Missing headings → fail
# with the list. Headings present but explicitly "N/A — <reason>" → pass.
#
# Usage:
#   scripts/check-subagent-prompt.sh [--mode=auto|impl|review] [--strict] <file.md>
#
# Modes (v2.4.1):
#   auto   (default) — filename heuristic: suffix `-impl.md` or `-impl-r<N>.md`
#                      → impl mode, else review mode (graceful skip).
#                      Substring like `*impl*.md` is NOT matched — convention is
#                      strict suffix to prevent drift (e.g. `-implementation.md`
#                      stays review-mode by default).
#   impl              — enforce 5/5 (use for any new implementer prompt)
#   review            — skip lint, exit 0 (for codex/peer review prompts)
#
# Exit codes:
#   0  all 5 headings present (or explicit N/A), OR mode=review
#   1  one or more headings missing (impl mode only)
#   2  prompt file not found
#   3  invalid mode

set -uo pipefail

MODE="auto"
STRICT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)            STRICT=1; shift;;
    --mode=*)            MODE="${1#--mode=}"; shift;;
    --mode)
      # v2.4.1 r1 codex major: bare `--mode` without value previously caused
      # an infinite loop (shift 2 silently failed under `set -uo pipefail`).
      # Require a value that doesn't look like another flag.
      if [[ $# -lt 2 || -z "${2:-}" || "${2:0:1}" == "-" ]]; then
        echo "[check-subagent-prompt] --mode requires a value (auto|impl|review)" >&2
        exit 3
      fi
      MODE="$2"; shift 2;;
    -h|--help)
      sed -n '2,/^set -uo/p' "$0" | sed '$d' | sed 's/^# //'
      exit 0;;
    --) shift; break;;
    -*) echo "Unknown flag: $1" >&2; exit 3;;
    *) break;;
  esac
done

PROMPT="${1:?usage: scripts/check-subagent-prompt.sh [--mode=auto|impl|review] [--strict] <file.md>}"
[[ ! -f "$PROMPT" ]] && { echo "[check-subagent-prompt] file not found: $PROMPT" >&2; exit 2; }

# v2.4.1 mode resolution
case "$MODE" in
  auto)
    # Heuristic: filename suffix `-impl.md` or `-impl-r<N>.md` → impl mode.
    # Strict suffix only — `*impl*` substring would silently match
    # `*-implementation.md` / `*-impl-notes.md` etc. and is rejected here.
    if [[ "$(basename "$PROMPT")" =~ -impl(-r[0-9]+)?\.md$ ]]; then
      MODE="impl"
    else
      MODE="review"
    fi
    ;;
  impl|review) ;;
  *) echo "[check-subagent-prompt] invalid --mode: $MODE (expected auto|impl|review)" >&2; exit 3;;
esac

if [[ "$MODE" == "review" ]]; then
  echo "[check-subagent-prompt] SKIP — review-mode prompt (no deliverables lint)"
  exit 0
fi

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
  # v2.4.2 ARIA imperative enforcement — v0.17.2 + v0.19 dogfood: subagent 가
  # interactive input/button 에 aria-label 누락 → Maestro WKWebView tap 실패
  # → coordinator post-hoc patch. prompt 에 "aria-label" 단어 의무.
  if ! grep -qiE '\baria[- ]?label\b' "$PROMPT"; then
    echo "[check-subagent-prompt] FAIL (--strict): no 'aria-label' imperative in prompt" >&2
    echo "[check-subagent-prompt]   PATTERNS §deliverable-categories ARIA imperative —" >&2
    echo "[check-subagent-prompt]   all interactive button/input MUST have aria-label." >&2
    echo "[check-subagent-prompt]   add an ARIA imperative section to your subagent prompt." >&2
    exit 1
  fi
fi

echo "[check-subagent-prompt] PASS — 5/5 deliverable categories present"
exit 0
