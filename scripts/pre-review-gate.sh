#!/usr/bin/env bash
# pre-review-gate.sh — Run lint / typecheck / unit tests before a cross-review.
# Detects project type from layout. Counts attempted checks; "0 attempted" is
# treated as FAIL unless `--allow-no-checks` is given (F23 fix).
#
# v1.8 (F127) — root detection uses nearest `.harness/` ancestor instead of
# git toplevel, fixing the monorepo case where `examples/<project>/` has its
# own `.harness/` but git toplevel returns the outer harness repo (which
# would run harness self-checks instead of the project's gates). Pass
# `--root <path>` to override explicitly.
#
# Usage:
#   scripts/pre-review-gate.sh [--allow-no-checks] [--root <path>]

set -uo pipefail

find_project_root() {
  # v1.8 r1 #4 — bound search to git toplevel so we never select a `.harness/`
  # outside the repo (catches the "outer user dir has .harness/" case).
  local dir="$PWD"
  local toplevel
  toplevel="$(git rev-parse --show-toplevel 2>/dev/null)" || toplevel=""
  while [[ "$dir" != "/" ]]; do
    [[ -d "$dir/.harness" ]] && { echo "$dir"; return 0; }
    # Stop at git toplevel — don't escape the repo.
    [[ -n "$toplevel" && "$dir" == "$toplevel" ]] && break
    dir="$(dirname "$dir")"
  done
  echo "${toplevel:-$PWD}"
}

ALLOW_NO_CHECKS=0
ROOT_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-no-checks) ALLOW_NO_CHECKS=1; shift;;
    --root)
      [[ -z "${2:-}" || "$2" == --* ]] && { echo "--root requires a value" >&2; exit 2; }
      ROOT_OVERRIDE="$2"; shift 2;;
    -h|--help) sed -n '2,/^set -uo/p' "$0" | sed '$d' | sed 's/^# //'; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -n "$ROOT_OVERRIDE" ]]; then
  ROOT="$ROOT_OVERRIDE"
else
  ROOT="$(find_project_root)"
fi
cd "$ROOT"
echo "[gate] root: $ROOT" >&2

ok=1
attempted=0
fail() { echo "[gate] FAIL: $*" >&2; ok=0; }
pass() { echo "[gate] PASS: $*" >&2; }
attempt() { attempted=$((attempted+1)); }

# --- JS / TS ---
if [[ -f package.json ]] && command -v npm >/dev/null 2>&1; then
  echo "[gate] detected JS/TS (package.json)" >&2
  attempt; npm run -s lint --if-present      && pass "npm lint"      || fail "npm lint"
  attempt; npm run -s typecheck --if-present && pass "npm typecheck" || fail "npm typecheck"
  attempt; npm test --silent --if-present    && pass "npm test"      || fail "npm test"
fi

# --- Python ---
if [[ -f pyproject.toml || -f setup.py ]]; then
  echo "[gate] detected Python" >&2
  command -v ruff   >/dev/null && { attempt; ruff check .  && pass "ruff"   || fail "ruff"; }
  command -v mypy   >/dev/null && { attempt; mypy .        && pass "mypy"   || fail "mypy"; }
  command -v pytest >/dev/null && { attempt; pytest -q     && pass "pytest" || fail "pytest"; }
fi

# --- Rust ---
if [[ -f Cargo.toml ]] && command -v cargo >/dev/null 2>&1; then
  echo "[gate] detected Rust" >&2
  attempt; cargo clippy --quiet -- -D warnings && pass "clippy"     || fail "clippy"
  attempt; cargo test --quiet                  && pass "cargo test" || fail "cargo test"
fi

# --- Go ---
if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then
  echo "[gate] detected Go" >&2
  attempt; go vet ./...   && pass "go vet"  || fail "go vet"
  attempt; go test ./...  && pass "go test" || fail "go test"
fi

# --- Harness self (this repo) ---
# If we look like the harness repo (HARNESS.md + roles + templates + scripts + phases),
# run minimal self smoke checks. F23: ensures attempted_count > 0.
if [[ -f HARNESS.md && -d roles && -d templates && -d scripts && -d phases ]]; then
  echo "[gate] detected harness self-build" >&2
  for sh in scripts/*.sh; do
    attempt; bash -n "$sh" && pass "bash -n $sh" || fail "bash -n $sh"
  done
  for py in scripts/*.py; do
    [[ -f "$py" ]] || continue
    attempt; python3 -m py_compile "$py" && pass "py_compile $py" || fail "py_compile $py"
  done
fi

# --- Empty-checks policy (F23) ---
if [[ $attempted -eq 0 ]]; then
  if [[ $ALLOW_NO_CHECKS -eq 1 ]]; then
    echo "[gate] WARNING: 0 checks attempted (allowed via --allow-no-checks)" >&2
    exit 0
  else
    echo "[gate] FAIL: 0 checks attempted. Add tooling or pass --allow-no-checks (HC-4 / phases/04 Entry intent)" >&2
    exit 1
  fi
fi

if [[ $ok -eq 1 ]]; then
  echo "[gate] ALL PASS ($attempted checks)"
  exit 0
else
  echo "[gate] one or more checks FAILED ($attempted attempted) — fix before requesting codex review" >&2
  exit 1
fi
