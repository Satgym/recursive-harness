#!/usr/bin/env bash
# codex-exec-review.sh — Wrapper around `codex exec` for text-level review
# of Blueprint / Module Plan / ADR / harness docs.
#
# Usage:
#   scripts/codex-exec-review.sh --prompt-file <path>
#                                [--phase <id>] [--slug <name>]
#                                [--skip-git-repo-check]

set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

PHASE=""; SLUG="exec-review"; PROMPT_FILE=""; SKIP_GIT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2;;
    --slug) SLUG="$2"; shift 2;;
    --prompt-file) PROMPT_FILE="$2"; shift 2;;
    --skip-git-repo-check) SKIP_GIT=1; shift;;
    -h|--help) sed -n '2,/^set/p' "$0" | sed '$d'; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$PROMPT_FILE" || ! -f "$PROMPT_FILE" ]]; then
  echo "Required: --prompt-file <path>" >&2
  exit 2
fi

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
DEST="$DEST_DIR/${PHASE:+${PHASE}-}${DATE}-${SLUG}.md"

RAW="$(mktemp -t codex-exec-review.XXXXXX)"
trap 'rm -f "$RAW"' EXIT

echo "[codex-exec-review] cmd: ${CMD[*]} < $PROMPT_FILE" >&2
echo "[codex-exec-review] dest: $DEST" >&2

"${CMD[@]}" < "$PROMPT_FILE" 2>&1 | tee "$RAW"

python3 "$ROOT/scripts/_codex_postprocess.py" "$RAW" "$DEST"
echo "[codex-exec-review] saved: $DEST" >&2
