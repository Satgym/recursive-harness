#!/usr/bin/env bash
# codex-review.sh — Wrapper around `codex review` for cross-review on code changes.
# Reads model / effort / base_branch from .harness/config.toml. Runs pre-review-gate
# first. Saves canonical REVIEW to .harness/reviews/<phase>-<date>-<slug>.md with
# full §5.3 review determinism metadata.
#
# Usage:
#   scripts/codex-review.sh [--phase <id>] [--slug <name>]
#                           [--base <branch> | --commit <sha> | --uncommitted]
#                           [--prompt-file <path>] [--no-gate]
#                           [--review-round <e.g. A.5>] [--prior-review <path>]
#                           [--severity <enum>] [--target <text>]

set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"     # project root (cwd for config/output)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"      # harness scripts/ dir (F27)
cd "$ROOT"

# --- argument helpers (F22) ---
need_value() {
  if [[ -z "${2:-}" || "$2" == --* ]]; then
    echo "Error: $1 requires a value" >&2
    exit 2
  fi
}

PHASE=""; SLUG="review"; BASE=""; COMMIT=""; UNCOMMITTED=0
PROMPT_FILE=""; SKIP_GATE=0
REVIEW_ROUND=""; PRIOR_REVIEW=""; SEVERITY=""; TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)         need_value "$1" "${2:-}"; PHASE="$2"; shift 2;;
    --slug)          need_value "$1" "${2:-}"; SLUG="$2"; shift 2;;
    --base)          need_value "$1" "${2:-}"; BASE="$2"; shift 2;;
    --commit)        need_value "$1" "${2:-}"; COMMIT="$2"; shift 2;;
    --uncommitted)   UNCOMMITTED=1; shift;;
    --prompt-file)   need_value "$1" "${2:-}"; PROMPT_FILE="$2"; shift 2;;
    --no-gate)       SKIP_GATE=1; shift;;
    --review-round)  need_value "$1" "${2:-}"; REVIEW_ROUND="$2"; shift 2;;
    --prior-review)  need_value "$1" "${2:-}"; PRIOR_REVIEW="$2"; shift 2;;
    --severity)      need_value "$1" "${2:-}"; SEVERITY="$2"; shift 2;;
    --target)        need_value "$1" "${2:-}"; TARGET="$2"; shift 2;;
    -h|--help)       sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# //'; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

# --- source mutual exclusion (F22) ---
src_count=0
[[ $UNCOMMITTED -eq 1 ]] && src_count=$((src_count+1))
[[ -n "$COMMIT" ]] && src_count=$((src_count+1))
[[ -n "$BASE" ]] && src_count=$((src_count+1))
if [[ $src_count -gt 1 ]]; then
  echo "Error: --base, --commit, --uncommitted are mutually exclusive" >&2
  exit 2
fi

# --- config helper with tomllib + tomli fallback (F21) ---
read_config() {
  local key="$1" default="${2:-}"
  local py_script
  py_script='
import sys, os
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("__NO_TOML__"); sys.exit(0)
key, default = sys.argv[1], sys.argv[2]
p = ".harness/config.toml"
if not os.path.exists(p):
    print(default); sys.exit(0)
with open(p, "rb") as f:
    c = tomllib.load(f)
v = c
for k in key.split("."):
    if isinstance(v, dict) and k in v:
        v = v[k]
    else:
        print(default); sys.exit(0)
print(v)
'
  local py out
  for py in python3.13 python3.12 python3.11 python3; do
    command -v "$py" >/dev/null 2>&1 || continue
    out="$("$py" -c "$py_script" "$key" "$default" 2>/dev/null)" || continue
    if [[ "$out" == "__NO_TOML__" ]]; then
      continue
    fi
    echo "$out"
    return 0
  done
  echo "[config] WARNING: no python with tomllib/tomli; .harness/config.toml is being IGNORED. Install python 3.11+ or 'pip install tomli'." >&2
  echo "$default"
}

BASE="${BASE:-$(read_config git.base_branch main)}"
MODEL="$(read_config models.review)"
EFFORT="$(read_config reasoning.review high)"

# --- pre-review gate (HC-1, §5.4) — invoke sibling from harness scripts dir (F27) ---
if [[ $SKIP_GATE -eq 0 && -x "$SCRIPT_DIR/pre-review-gate.sh" ]]; then
  echo "[codex-review] running pre-review-gate..." >&2
  if ! "$SCRIPT_DIR/pre-review-gate.sh"; then
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
DEFAULT_PROMPT='Review the diff per templates/REVIEW.template.md. Use canonical English enums (severity: blocker|major|minor|nit|info; status: open|resolved|deferred|disputed). HC-7/8/9 violations are severity: blocker by definition. Number findings monotonically across rounds.'
if [[ -n "$PROMPT_FILE" ]]; then
  [[ -f "$PROMPT_FILE" ]] || { echo "prompt file not found: $PROMPT_FILE" >&2; exit 2; }
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
INVOKED_AT="$(date -u +%Y-%m-%dT%H:%M)"
echo "[codex-review] cmd: ${CMD[*]}" >&2
echo "[codex-review] dest: $DEST" >&2

RAW="$(mktemp -t codex-review.XXXXXX)"
trap 'rm -f "$RAW"' EXIT
"${CMD[@]}" "$PROMPT" 2>&1 | tee "$RAW"

# --- post-process with rich metadata (F20) ---
PP_ARGS=()
[[ -n "$PHASE" ]]         && PP_ARGS+=(--phase "$PHASE")
[[ -n "$SLUG" ]]          && PP_ARGS+=(--slug "$SLUG")
[[ -n "$REVIEW_ROUND" ]]  && PP_ARGS+=(--review-round "$REVIEW_ROUND")
[[ -n "$PRIOR_REVIEW" ]]  && PP_ARGS+=(--prior-review "$PRIOR_REVIEW")
[[ -n "$SEVERITY" ]]      && PP_ARGS+=(--severity "$SEVERITY")
[[ -n "$TARGET" ]]        && PP_ARGS+=(--target "$TARGET")
if [[ $UNCOMMITTED -eq 1 ]]; then
  PP_ARGS+=(--uncommitted)
elif [[ -n "$COMMIT" ]]; then
  PP_ARGS+=(--commit "$COMMIT")
else
  PP_ARGS+=(--base-ref "$BASE")
fi
[[ -n "$PROMPT_FILE" ]] && PP_ARGS+=(--prompt-source "$PROMPT_FILE") || PP_ARGS+=(--prompt-source "default")
PP_ARGS+=(--invoked-at "$INVOKED_AT")

python3 "$SCRIPT_DIR/_codex_postprocess.py" "$RAW" "$DEST" "${PP_ARGS[@]}"
echo "[codex-review] saved: $DEST" >&2
