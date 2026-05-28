#!/usr/bin/env bash
# codex-exec-review.sh — Wrapper around `codex exec` for text-level review
# of Blueprint / Module Plan / ADR / harness docs. Same metadata guarantees as
# codex-review.sh (§5.3 review determinism).
#
# Usage:
#   scripts/codex-exec-review.sh --prompt-file <path>
#                                [--phase <id>] [--slug <name>]
#                                [--review-round <e.g. A.5>] [--prior-review <path>]
#                                [--severity <enum>] [--target <text>]
#                                [--skip-git-repo-check]

set -euo pipefail

# Find nearest .harness/ ancestor as project root (handles monorepo sub-projects).
# Fall back to git toplevel, then $PWD.
find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    [[ -d "$dir/.harness" ]] && { echo "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  git rev-parse --show-toplevel 2>/dev/null || pwd
}
ROOT="$(find_project_root)"                                     # project root (cwd for config/output)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"      # harness scripts/ dir (F27)
cd "$ROOT"

need_value() {
  if [[ -z "${2:-}" || "$2" == --* ]]; then
    echo "Error: $1 requires a value" >&2
    exit 2
  fi
}

PHASE=""; SLUG="exec-review"; PROMPT_FILE=""; SKIP_GIT=0
REVIEW_ROUND=""; PRIOR_REVIEW=""; SEVERITY=""; TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)                 need_value "$1" "${2:-}"; PHASE="$2"; shift 2;;
    --slug)                  need_value "$1" "${2:-}"; SLUG="$2"; shift 2;;
    --prompt-file)           need_value "$1" "${2:-}"; PROMPT_FILE="$2"; shift 2;;
    --review-round)          need_value "$1" "${2:-}"; REVIEW_ROUND="$2"; shift 2;;
    --prior-review)          need_value "$1" "${2:-}"; PRIOR_REVIEW="$2"; shift 2;;
    --severity)              need_value "$1" "${2:-}"; SEVERITY="$2"; shift 2;;
    --target)                need_value "$1" "${2:-}"; TARGET="$2"; shift 2;;
    --skip-git-repo-check)   SKIP_GIT=1; shift;;
    -h|--help)               sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# //'; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$PROMPT_FILE" || ! -f "$PROMPT_FILE" ]]; then
  echo "Required: --prompt-file <existing path>" >&2
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

MODEL="$(read_config models.exec)"
EFFORT="$(read_config reasoning.exec medium)"

CMD=(codex exec)
[[ $SKIP_GIT -eq 1 ]] && CMD+=(--skip-git-repo-check)
[[ -n "$MODEL" ]] && CMD+=(-c "model=\"$MODEL\"")
CMD+=(-c "model_reasoning_effort=$EFFORT")
CMD+=(-)

DATE="$(date +%Y%m%d)"
DEST_DIR=".harness/reviews"
mkdir -p "$DEST_DIR"
# Hara v2.3.1: when REVIEW_ROUND is set, suffix DEST so r1/r2/r3 don't overwrite.
# Pattern: <phase>-<date>-<slug>-<round>.md (e.g. 04-20260528-v015-shell-impl-r2.md).
ROUND_SUFFIX=""
[[ -n "$REVIEW_ROUND" ]] && ROUND_SUFFIX="-${REVIEW_ROUND}"
DEST="$DEST_DIR/${PHASE:+${PHASE}-}${DATE}-${SLUG}${ROUND_SUFFIX}.md"

RAW="$(mktemp -t codex-exec-review.XXXXXX)"
trap 'rm -f "$RAW"' EXIT

INVOKED_AT="$(date -u +%Y-%m-%dT%H:%M)"
echo "[codex-exec-review] cmd: ${CMD[*]} < $PROMPT_FILE" >&2
echo "[codex-exec-review] dest: $DEST" >&2

"${CMD[@]}" < "$PROMPT_FILE" 2>&1 | tee "$RAW"

PP_ARGS=()
[[ -n "$PHASE" ]]         && PP_ARGS+=(--phase "$PHASE")
[[ -n "$SLUG" ]]          && PP_ARGS+=(--slug "$SLUG")
[[ -n "$REVIEW_ROUND" ]]  && PP_ARGS+=(--review-round "$REVIEW_ROUND")
[[ -n "$PRIOR_REVIEW" ]]  && PP_ARGS+=(--prior-review "$PRIOR_REVIEW")
[[ -n "$SEVERITY" ]]      && PP_ARGS+=(--severity "$SEVERITY")
[[ -n "$TARGET" ]]        && PP_ARGS+=(--target "$TARGET")
PP_ARGS+=(--prompt-source "$PROMPT_FILE")
PP_ARGS+=(--invoked-at "$INVOKED_AT")

python3 "$SCRIPT_DIR/_codex_postprocess.py" "$RAW" "$DEST" "${PP_ARGS[@]}"
echo "[codex-exec-review] saved: $DEST" >&2
