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
REVIEW_ROUND="r1"   # v2.3.1 Hara harness-v231-r1 codex major #3 — caller selects round
while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)             SLUG="$2"; shift 2;;
    --platform)         PLATFORM="$2"; shift 2;;
    --screenshots)      SHOTS="$2"; shift 2;;
    --ui-spec)          SPEC="$2"; shift 2;;
    --claude-review)    CLAUDE_REVIEW="$2"; shift 2;;
    --evidence)         EVIDENCE="$2"; shift 2;;
    --codex-prompt)     CODEX_PROMPT="$2"; shift 2;;
    --review-round)     REVIEW_ROUND="$2"; shift 2;;
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

# --- parse review field (Hara v2.3.1 robustness) ---
# Codex sometimes emits canonical key/value only in *narrative* body (e.g.
# "codex_pass: true. HC-13 visual gate ..."). v2.3.0 regex captured that whole
# trailing prose. v2.3.1 logic:
#   1. Prefer YAML front-matter block (--- ... ---) — strict key: value lines.
#   2. Body fallback: only extract canonical boolean (true/false) or integer.
# This kills the "true. HC-13 gate ..." class of false-pass without breaking
# legitimate front-matter parsing.
parse_review_field() {
  local file="$1" field="$2" kind="${3:-string}"
  python3 - "$file" "$field" "$kind" <<'PYEOF' 2>/dev/null
import sys, re
path, key, kind = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    txt = open(path).read()
except Exception:
    print(''); sys.exit(0)
key_re = re.escape(key)
# Step 1: front-matter (first --- ... --- block, if any).
fm = re.search(r'^---\s*$(.+?)^---\s*$', txt, re.MULTILINE | re.DOTALL)
if fm:
    # v2.3.1 r2 — comment-aware: allow `key: value   # inline comment`
    m = re.search(r'(?m)^\s*' + key_re + r'\s*:\s*([^\n#]+?)\s*(?:#[^\n]*)?\s*$', fm.group(1))
    if m:
        v = m.group(1).strip().rstrip('.,;')
        print(v); sys.exit(0)
# Step 2: body fallback — STRICTLY end-anchored. Per ADR-030 + harness-v231-r1
# codex blocker #2 the previous `\b` boundary still accepted "codex_pass: true.
# HC-13 ..." style narrative lines. v2.3.1 hardens to `$` so trailing prose is
# rejected; codex must emit clean YAML in the body too if it has to fall back.
if kind == 'bool':
    m = re.search(r'(?m)^\s*' + key_re + r'\s*:\s*(true|false)\s*(?:#[^\n]*)?\s*$', txt, re.IGNORECASE)
    if m: print(m.group(1).lower()); sys.exit(0)
elif kind == 'int':
    m = re.search(r'(?m)^\s*' + key_re + r'\s*:\s*(\d+)\s*(?:#[^\n]*)?\s*$', txt)
    if m: print(m.group(1)); sys.exit(0)
else:
    m = re.search(r'(?m)^\s*' + key_re + r'\s*:\s*([^\n#]+?)\s*(?:#[^\n]*)?\s*$', txt)
    if m:
        v = m.group(1).strip().rstrip('.,;')
        print(v); sys.exit(0)
print('')
PYEOF
}

CLAUDE_PASS=$(parse_review_field "$CLAUDE_REVIEW" "claude_pass" bool)
CLAUDE_BLOCKER=$(parse_review_field "$CLAUDE_REVIEW" "blocker_count" int)
CLAUDE_MAJOR=$(parse_review_field "$CLAUDE_REVIEW" "major_count" int)
CLAUDE_MINOR=$(parse_review_field "$CLAUDE_REVIEW" "minor_count" int)

[[ -z "$CLAUDE_PASS" ]] && CLAUDE_PASS="false"
[[ -z "$CLAUDE_BLOCKER" ]] && CLAUDE_BLOCKER=0
[[ -z "$CLAUDE_MAJOR" ]] && CLAUDE_MAJOR=0
[[ -z "$CLAUDE_MINOR" ]] && CLAUDE_MINOR=0

if [[ "$CLAUDE_PASS" != "true" ]]; then
  echo "[ui-visual-review] FAIL: claude_pass = $CLAUDE_PASS (review: $CLAUDE_REVIEW)" >&2
  exit 1
fi

echo "[ui-visual-review] Claude review: pass (blocker=$CLAUDE_BLOCKER major=$CLAUDE_MAJOR minor=$CLAUDE_MINOR)" >&2

# --- codex review (independent verify; round-suffixed per harness-v231 #3) ---
DATE=$(date -u +%Y%m%d)
PROJ_ROOT="$(cd "$(dirname "$EVIDENCE")/../.." && pwd)"
CODEX_REVIEW_OUT="$PROJ_ROOT/.harness/reviews/ui-codex-${DATE}-${SLUG}-${REVIEW_ROUND}.md"

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

## Output format (STRICT — Hara v2.3.1)

Start the file with YAML front-matter delimited by '---' lines, *then* the
markdown body. The front-matter MUST contain these 4 keys on their own lines.
Use clean values — no trailing prose, no comments:

---
codex_pass: true
blocker_count: 0
major_count: 0
minor_count: 1
---

Acceptable values:
  codex_pass: true       OR  codex_pass: false
  *_count: any integer

Rejected:
  codex_pass: true. HC-13 verdict ...     (trailing prose)
  codex_pass: true (see body)             (trailing parenthetical)

The body that follows the closing '---' can use any prose freely.
EOF
fi

# Run codex visual review via existing wrapper (round-aware)
"$SCRIPT_DIR/codex-exec-review.sh" \
  --phase ui-visual --slug "$SLUG-codex" --review-round "$REVIEW_ROUND" \
  --prior-review "$CLAUDE_REVIEW" \
  --prompt-file "$CODEX_PROMPT" \
  --target "HC-13 visual review (codex $REVIEW_ROUND verify)" || {
  echo "[ui-visual-review] FAIL: codex review invocation error" >&2
  exit 2
}

# Find the codex output file (codex-exec-review now suffixes with REVIEW_ROUND)
CODEX_GENERATED=$(ls -t "$PROJ_ROOT/.harness/reviews"/*"ui-visual-${DATE}-${SLUG}-codex-${REVIEW_ROUND}"*.md 2>/dev/null | head -1)
# Backward compat: pre-v2.3.1 callers may have written without suffix
[[ -z "$CODEX_GENERATED" || ! -f "$CODEX_GENERATED" ]] && \
  CODEX_GENERATED=$(ls -t "$PROJ_ROOT/.harness/reviews"/*"ui-visual-${DATE}-${SLUG}-codex"*.md 2>/dev/null | head -1)
[[ -z "$CODEX_GENERATED" || ! -f "$CODEX_GENERATED" ]] && {
  echo "[ui-visual-review] FAIL: codex review output not found" >&2
  exit 2
}

# Move to canonical name + parse
cp "$CODEX_GENERATED" "$CODEX_REVIEW_OUT"
CODEX_PASS=$(parse_review_field "$CODEX_REVIEW_OUT" "codex_pass" bool)
CODEX_BLOCKER=$(parse_review_field "$CODEX_REVIEW_OUT" "blocker_count" int)
CODEX_MAJOR=$(parse_review_field "$CODEX_REVIEW_OUT" "major_count" int)
CODEX_MINOR=$(parse_review_field "$CODEX_REVIEW_OUT" "minor_count" int)

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
