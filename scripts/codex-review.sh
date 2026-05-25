#!/usr/bin/env bash
# codex-review.sh — Wrapper around `codex review` for cross-review on code changes.
# Reads model / effort / base_branch from .harness/config.toml. Runs pre-review-gate
# first. Saves canonical REVIEW to .harness/reviews/<phase>-<date>-<slug>.md.
#
# Usage:
#   scripts/codex-review.sh [--phase <id>] [--slug <name>]
#                           [--base <branch> | --commit <sha> | --uncommitted]
#                           [--prompt-file <path>] [--no-gate]

set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

PHASE=""; SLUG="review"; BASE=""; COMMIT=""; UNCOMMITTED=0
PROMPT_FILE=""; SKIP_GATE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2;;
    --slug) SLUG="$2"; shift 2;;
    --base) BASE="$2"; shift 2;;
    --commit) COMMIT="$2"; shift 2;;
    --uncommitted) UNCOMMITTED=1; shift;;
    --prompt-file) PROMPT_FILE="$2"; shift 2;;
    --no-gate) SKIP_GATE=1; shift;;
    -h|--help) sed -n '2,/^set/p' "$0" | sed '$d'; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

# --- config helper (TOML via python tomllib) ---
read_config() {
  python3 - "$1" "${2:-}" <<'PY' 2>/dev/null || echo "${2:-}"
import sys, os
try:
    import tomllib
except ImportError:
    sys.exit(1)
key, default = sys.argv[1], sys.argv[2]
path = ".harness/config.toml"
if not os.path.exists(path):
    print(default); sys.exit(0)
with open(path, "rb") as f:
    c = tomllib.load(f)
v = c
for k in key.split("."):
    if isinstance(v, dict) and k in v:
        v = v[k]
    else:
        print(default); sys.exit(0)
print(v)
PY
}

BASE="${BASE:-$(read_config git.base_branch main)}"
MODEL="$(read_config models.review)"
EFFORT="$(read_config reasoning.review high)"

# --- pre-review gate (HC-1, cost guardrail §5.4) ---
if [[ $SKIP_GATE -eq 0 && -x scripts/pre-review-gate.sh ]]; then
  echo "[codex-review] running pre-review-gate..." >&2
  if ! scripts/pre-review-gate.sh; then
    echo "[codex-review] pre-review-gate FAILED — fix issues first or pass --no-gate" >&2
    exit 3
  fi
fi

# --- assemble codex command ---
CMD=(codex review)
[[ -n "$MODEL" ]] && CMD+=(-c "model=\"$MODEL\"")
CMD+=(-c "model_reasoning_effort=$EFFORT")
if [[ $UNCOMMITTED -eq 1 ]]; then
  CMD+=(--uncommitted)
elif [[ -n "$COMMIT" ]]; then
  CMD+=(--commit "$COMMIT")
else
  CMD+=(--base "$BASE")
fi

# --- prompt ---
DEFAULT_PROMPT='Review the diff per templates/REVIEW.template.md. Use canonical English enums (severity: blocker|major|minor|nit|info; status: open|resolved|deferred|disputed). HC-7/8/9 violations are severity: blocker by definition. Number findings monotonically across rounds (consult prior reviews if cited).'
if [[ -n "$PROMPT_FILE" ]]; then
  PROMPT="$(cat "$PROMPT_FILE")"
else
  PROMPT="$DEFAULT_PROMPT"
fi

# --- destination ---
DATE="$(date +%Y%m%d)"
DEST_DIR=".harness/reviews"
mkdir -p "$DEST_DIR"
DEST="$DEST_DIR/${PHASE:+${PHASE}-}${DATE}-${SLUG}.md"

# --- invoke + capture ---
echo "[codex-review] cmd: ${CMD[*]}" >&2
echo "[codex-review] dest: $DEST" >&2

RAW="$(mktemp -t codex-review.XXXXXX)"
trap 'rm -f "$RAW"' EXIT
"${CMD[@]}" "$PROMPT" 2>&1 | tee "$RAW"

python3 "$ROOT/scripts/_codex_postprocess.py" "$RAW" "$DEST"
echo "[codex-review] saved: $DEST" >&2
