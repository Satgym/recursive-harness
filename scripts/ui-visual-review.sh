#!/usr/bin/env bash
# ui-visual-review.sh — HC-13 Visual-Review helper (Hara v2.3).
# Orchestrates the codex-side r2 verify + evidence JSON patch.
# Claude (coordinator) side review file is written *before* this script runs.
#
# Usage:
#   scripts/ui-visual-review.sh --slug <slug> --platform ios|android \
#       --screenshots <dir> --ui-spec <path> --claude-review <path> \
#       --evidence <path> [--codex-prompt <path>]
#
# Inputs:
#   --slug              evidence file slug (e.g. login-smoke)
#   --platform          ios | android (must match evidence platform)
#   --screenshots       directory of PNG files (label.png form) + manifest.json
#   --ui-spec           path to .harness/docs/ui-spec.md (design intent SoT)
#   --claude-review     path to coordinator's already-written review file
#   --evidence          path to mobile-e2e-*.json to patch with ui_review field
#   --codex-prompt      (optional) custom prompt; default uses canonical template
#
# Outputs:
#   - Codex review at .harness/reviews/ui-codex-<date>-<slug>.md
#   - Evidence JSON patched with canonical ui_review schema
#
# Exit codes:
#   0  pass (Claude + Codex both pass + blocker_count=0)
#   1  Claude review reports blocker or claude_pass=false
#   2  Codex review reports blocker or codex_pass=false
#   3  inputs missing or invalid
#   4  evidence JSON patch failed

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SLUG=""; PLATFORM=""; SHOTS=""; SPEC=""; CLAUDE_REVIEW=""; EVIDENCE=""; CODEX_PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)             SLUG="$2"; shift 2;;
    --platform)         PLATFORM="$2"; shift 2;;
    --screenshots)      SHOTS="$2"; shift 2;;
    --ui-spec)          SPEC="$2"; shift 2;;
    --claude-review)    CLAUDE_REVIEW="$2"; shift 2;;
    --evidence)         EVIDENCE="$2"; shift 2;;
    --codex-prompt)     CODEX_PROMPT="$2"; shift 2;;
    -h|--help)
      sed -n '2,/^set -uo/p' "$0" | sed '$d' | sed 's/^# //'
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 3;;
  esac
done

# --- validate ---
[[ -z "$SLUG" || -z "$PLATFORM" || -z "$SHOTS" || -z "$SPEC" || -z "$CLAUDE_REVIEW" || -z "$EVIDENCE" ]] && {
  echo "[ui-visual-review] FAIL: missing required arg" >&2
  echo "  Usage: $0 --slug <slug> --platform ios|android --screenshots <dir> --ui-spec <path> --claude-review <path> --evidence <path>" >&2
  exit 3
}
[[ ! -d "$SHOTS" ]]            && { echo "[ui-visual-review] FAIL: screenshots dir not found: $SHOTS" >&2; exit 3; }
[[ ! -f "$SPEC" ]]             && { echo "[ui-visual-review] FAIL: ui-spec not found: $SPEC" >&2; exit 3; }
[[ ! -f "$CLAUDE_REVIEW" ]]    && { echo "[ui-visual-review] FAIL: Claude review file not found: $CLAUDE_REVIEW" >&2; exit 3; }
[[ ! -f "$EVIDENCE" ]]         && { echo "[ui-visual-review] FAIL: evidence file not found: $EVIDENCE" >&2; exit 3; }

SHOT_COUNT=$(find "$SHOTS" -maxdepth 1 -name "*.png" -type f 2>/dev/null | wc -l | tr -d ' ')
[[ "$SHOT_COUNT" -lt 1 ]] && {
  echo "[ui-visual-review] FAIL: 0 screenshots in $SHOTS (HC-13 requires at least 1 when ui-spec.md present)" >&2
  exit 3
}
echo "[ui-visual-review] screenshots: $SHOT_COUNT" >&2

# --- parse Claude review (front-matter expected: ui_visual_review with severity_counts) ---
parse_review_field() {
  local file="$1" field="$2"
  python3 - "$file" "$field" <<'PYEOF' 2>/dev/null
import sys, re
try:
    txt = open(sys.argv[1]).read()
    # YAML-ish key: value extraction within front-matter or anywhere
    m = re.search(r'(?m)^\s*' + re.escape(sys.argv[2]) + r'\s*:\s*(.+?)\s*$', txt)
    print(m.group(1) if m else '')
except Exception:
    print('')
PYEOF
}

CLAUDE_PASS=$(parse_review_field "$CLAUDE_REVIEW" "claude_pass")
CLAUDE_BLOCKER=$(parse_review_field "$CLAUDE_REVIEW" "blocker_count")
CLAUDE_MAJOR=$(parse_review_field "$CLAUDE_REVIEW" "major_count")
CLAUDE_MINOR=$(parse_review_field "$CLAUDE_REVIEW" "minor_count")

[[ -z "$CLAUDE_PASS" ]] && CLAUDE_PASS="false"
[[ -z "$CLAUDE_BLOCKER" ]] && CLAUDE_BLOCKER=0
[[ -z "$CLAUDE_MAJOR" ]] && CLAUDE_MAJOR=0
[[ -z "$CLAUDE_MINOR" ]] && CLAUDE_MINOR=0

if [[ "$CLAUDE_PASS" != "true" ]]; then
  echo "[ui-visual-review] FAIL: claude_pass = $CLAUDE_PASS (review: $CLAUDE_REVIEW)" >&2
  exit 1
fi

echo "[ui-visual-review] Claude review: pass (blocker=$CLAUDE_BLOCKER major=$CLAUDE_MAJOR minor=$CLAUDE_MINOR)" >&2

# --- codex review (independent r2 verify) ---
DATE=$(date -u +%Y%m%d)
PROJ_ROOT="$(cd "$(dirname "$EVIDENCE")/../.." && pwd)"
CODEX_REVIEW_OUT="$PROJ_ROOT/.harness/reviews/ui-codex-${DATE}-${SLUG}.md"

if [[ -z "$CODEX_PROMPT" ]]; then
  CODEX_PROMPT=$(mktemp)
  cat > "$CODEX_PROMPT" <<EOF
You are conducting HC-13 visual-review r2 — independent visual verify of starpin/<project> UI flow.

## Inputs (read each)
- Design intent SoT: $SPEC
- Screenshots dir: $SHOTS (PNG files = key flow states)
- Claude (coordinator) review (r1): $CLAUDE_REVIEW

## Task
1. Read ui-spec.md sections + each screenshot
2. Independently evaluate: mobile-first / tap target (≥ 44pt iOS HIG) / a11y color contrast / user-friendly info / design intent match
3. Per screen: PASS/FAIL + finding (severity: blocker/major/minor/nit)
4. Verify Claude (r1) findings: agree / refine / dispute / add
5. Output structured front-matter with: codex_pass: true|false, blocker_count, major_count, minor_count

## Output
Standard REVIEW format. Front-matter must include:
  codex_pass: true|false
  blocker_count: N
  major_count: N
  minor_count: N
EOF
fi

# Run codex visual review via existing wrapper
"$SCRIPT_DIR/codex-exec-review.sh" \
  --phase ui-visual --slug "$SLUG-codex" --review-round r2 \
  --prior-review "$CLAUDE_REVIEW" \
  --prompt-file "$CODEX_PROMPT" \
  --target "HC-13 visual review (codex r2 verify)" || {
  echo "[ui-visual-review] FAIL: codex review invocation error" >&2
  exit 2
}

# Find the codex output file (codex-exec-review writes to .harness/reviews/)
CODEX_GENERATED=$(ls -t "$PROJ_ROOT/.harness/reviews"/*"ui-visual-${DATE}-${SLUG}-codex"*.md 2>/dev/null | head -1)
[[ -z "$CODEX_GENERATED" || ! -f "$CODEX_GENERATED" ]] && {
  echo "[ui-visual-review] FAIL: codex review output not found" >&2
  exit 2
}

# Move to canonical name + parse
cp "$CODEX_GENERATED" "$CODEX_REVIEW_OUT"
CODEX_PASS=$(parse_review_field "$CODEX_REVIEW_OUT" "codex_pass")
CODEX_BLOCKER=$(parse_review_field "$CODEX_REVIEW_OUT" "blocker_count")
CODEX_MAJOR=$(parse_review_field "$CODEX_REVIEW_OUT" "major_count")
CODEX_MINOR=$(parse_review_field "$CODEX_REVIEW_OUT" "minor_count")

[[ -z "$CODEX_PASS" ]] && CODEX_PASS="false"
[[ -z "$CODEX_BLOCKER" ]] && CODEX_BLOCKER=0
[[ -z "$CODEX_MAJOR" ]] && CODEX_MAJOR=0
[[ -z "$CODEX_MINOR" ]] && CODEX_MINOR=0

if [[ "$CODEX_PASS" != "true" ]]; then
  echo "[ui-visual-review] FAIL: codex_pass = $CODEX_PASS (review: $CODEX_REVIEW_OUT)" >&2
  exit 2
fi

# --- canonical ui_review schema + evidence patch ---
TOTAL_BLOCKER=$((CLAUDE_BLOCKER + CODEX_BLOCKER))
TOTAL_MAJOR=$((CLAUDE_MAJOR + CODEX_MAJOR))
TOTAL_MINOR=$((CLAUDE_MINOR + CODEX_MINOR))
TOTAL_FINDINGS=$((TOTAL_BLOCKER + TOTAL_MAJOR + TOTAL_MINOR))

if [[ $TOTAL_BLOCKER -gt 0 ]]; then
  echo "[ui-visual-review] FAIL: blocker_count = $TOTAL_BLOCKER (Claude: $CLAUDE_BLOCKER, Codex: $CODEX_BLOCKER)" >&2
  exit 1
fi

# Patch evidence JSON with canonical ui_review schema
python3 - "$EVIDENCE" "$CLAUDE_REVIEW" "$CODEX_REVIEW_OUT" \
  "$CLAUDE_BLOCKER" "$CODEX_BLOCKER" "$TOTAL_FINDINGS" "$TOTAL_BLOCKER" "$TOTAL_MAJOR" "$TOTAL_MINOR" <<'PYEOF'
import sys, json
ev_path, claude_rev, codex_rev, cb, cxb, total_f, total_b, total_m, total_mn = sys.argv[1:]
try:
    d = json.load(open(ev_path))
except Exception as e:
    print(f"evidence parse error: {e}", file=sys.stderr); sys.exit(4)
# Canonical ui_review schema (v2.3 — single source of truth)
d['ui_review'] = {
    'claude_pass': True,
    'codex_pass': True,
    'findings_count': int(total_f),
    'blocker_count': int(total_b),
    'severity_counts': {
        'blocker': int(total_b),
        'major': int(total_m),
        'minor': int(total_mn),
    },
    'claude_review': claude_rev,
    'codex_review': codex_rev,
}
json.dump(d, open(ev_path, 'w'), indent=2)
print(f"[ui-visual-review] evidence patched: {ev_path}")
PYEOF
PATCH_EXIT=$?
[[ $PATCH_EXIT -ne 0 ]] && exit 4

echo "[ui-visual-review] PASS — claude_pass + codex_pass + blocker_count=0" >&2
echo "[ui-visual-review]   evidence: $EVIDENCE" >&2
echo "[ui-visual-review]   Claude review: $CLAUDE_REVIEW" >&2
echo "[ui-visual-review]   Codex review: $CODEX_REVIEW_OUT" >&2
exit 0
