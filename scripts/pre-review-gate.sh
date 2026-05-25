#!/usr/bin/env bash
# pre-review-gate.sh — Run lint / typecheck / unit tests before a cross-review.
# Detects project type from layout; runs whatever tooling is available.
# Exits 0 only if all attempted checks pass.

set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

ok=1
fail() { echo "[gate] FAIL: $*" >&2; ok=0; }
pass() { echo "[gate] PASS: $*" >&2; }

# --- JS / TS ---
if [[ -f package.json ]] && command -v npm >/dev/null 2>&1; then
  echo "[gate] detected JS/TS (package.json)" >&2
  npm run -s lint --if-present       && pass "npm lint"       || fail "npm lint"
  npm run -s typecheck --if-present  && pass "npm typecheck"  || fail "npm typecheck"
  npm test --silent --if-present     && pass "npm test"       || fail "npm test"
fi

# --- Python ---
if [[ -f pyproject.toml || -f setup.py ]]; then
  echo "[gate] detected Python" >&2
  command -v ruff   >/dev/null && { ruff check .       && pass "ruff"   || fail "ruff"; }
  command -v mypy   >/dev/null && { mypy .             && pass "mypy"   || fail "mypy"; }
  command -v pytest >/dev/null && { pytest -q          && pass "pytest" || fail "pytest"; }
fi

# --- Rust ---
if [[ -f Cargo.toml ]] && command -v cargo >/dev/null 2>&1; then
  echo "[gate] detected Rust" >&2
  cargo clippy --quiet -- -D warnings && pass "clippy"     || fail "clippy"
  cargo test --quiet                  && pass "cargo test" || fail "cargo test"
fi

# --- Go ---
if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then
  echo "[gate] detected Go" >&2
  go vet ./...   && pass "go vet"  || fail "go vet"
  go test ./...  && pass "go test" || fail "go test"
fi

# --- Harness self ---
# 본 레포(HARNESS.md + roles/ + templates/ + scripts/)에는 아직 자동 lint/test 없음.
# A.5 통합 cross-review 이후 shellcheck, markdownlint 등 도입 검토 (Phase D 후보).
if [[ -f HARNESS.md && -d roles && -d templates ]] && ! [[ -f package.json || -f pyproject.toml || -f Cargo.toml || -f go.mod ]]; then
  echo "[gate] harness self (no auto-checks yet; TODO: shellcheck / markdownlint)" >&2
fi

if [[ $ok -eq 1 ]]; then
  echo "[gate] ALL PASS"
  exit 0
else
  echo "[gate] one or more checks FAILED — fix before requesting codex review" >&2
  exit 1
fi
