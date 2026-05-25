#!/usr/bin/env bash
# new-project.sh — Bootstrap a harness-managed project (creates .harness/ skeleton).
#
# Usage:
#   scripts/new-project.sh <project-name> [project-type]
#
# project-name : [a-z0-9][a-z0-9_-]{0,63} (lowercase kebab/snake; F24)
# project-type : exact directory name in project-types/, or '_generic'
# HC-9: aborts if .harness/ already exists (no overwrite).

set -euo pipefail

HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

NAME="${1:-}"
TYPE="${2:-_generic}"

usage() {
  cat >&2 <<EOF
Usage: $0 <project-name> [project-type]

Constraints (F24):
  project-name must match: ^[a-z0-9][a-z0-9_-]{0,63}\$
  project-type must be one of:
EOF
  if [[ -d "$HARNESS_ROOT/project-types" ]]; then
    ls -1 "$HARNESS_ROOT/project-types/" 2>/dev/null | sed 's/^/    - /' >&2
  else
    echo "    (project-types/ not present in $HARNESS_ROOT — Phase C output)" >&2
    echo "    For now only '_generic' is supported." >&2
  fi
}

if [[ -z "$NAME" ]]; then
  usage; exit 2
fi

# --- F24: validation ---
if ! [[ "$NAME" =~ ^[a-z0-9][a-z0-9_-]{0,63}$ ]]; then
  echo "Error: project-name '$NAME' violates pattern ^[a-z0-9][a-z0-9_-]{0,63}\$" >&2
  exit 2
fi
if ! [[ "$TYPE" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]; then
  echo "Error: project-type '$TYPE' contains disallowed characters" >&2
  exit 2
fi
if [[ "$TYPE" != "_generic" ]]; then
  if [[ ! -d "$HARNESS_ROOT/project-types/$TYPE" ]]; then
    echo "Error: project-type '$TYPE' not found at $HARNESS_ROOT/project-types/$TYPE" >&2
    echo "  Available types: $(ls -1 "$HARNESS_ROOT/project-types/" 2>/dev/null | tr '\n' ' ')" >&2
    exit 2
  fi
fi

if [[ -d ".harness" ]]; then
  echo "Error: .harness/ already exists in $(pwd). Aborting (HC-9: no overwrite)." >&2
  exit 3
fi

if [[ ! -f "$HARNESS_ROOT/HARNESS.md" ]]; then
  echo "Error: HARNESS_ROOT does not look like a harness repo: $HARNESS_ROOT" >&2
  exit 4
fi

# --- read harness version pin from HARNESS.md header ---
HARNESS_VERSION="$(grep -m1 -E '^# HARNESS\.md' "$HARNESS_ROOT/HARNESS.md" | sed -E 's/.*\(([^)]+)\).*/\1/')"
HARNESS_VERSION="${HARNESS_VERSION:-unknown}"

# --- skeleton ---
mkdir -p .harness/{docs/modules,reviews,decisions,postmortems,prompts}

# --- config.toml (F24: NAME/TYPE already validated above) ---
cat > .harness/config.toml <<EOF
# .harness/config.toml — harness configuration for this project
# See HARNESS.md §5.2 and ADR-003 for model selection.

project_name = "$NAME"
project_type = "$TYPE"

[strictness]
mode = "strict"   # strict | balanced | autonomous

[git]
base_branch = "main"

[models]
# review = "<model id for cross-review>"
# exec   = "<model id for text review>"

[reasoning]
review = "high"     # medium | high | xhigh (cost guardrail §5.4)
exec   = "medium"
EOF

# --- version pin ---
echo "$HARNESS_VERSION" > .harness/VERSION-PIN

# --- STATUS.md from template (use awk to avoid sed escape issues) ---
awk -v name="$NAME" -v hv="$HARNESS_VERSION" '
  { gsub(/<project name>/, name); gsub(/<e\.g\. v0\.5>/, hv); print }
' "$HARNESS_ROOT/templates/STATUS.template.md" > .harness/status.md

# --- project-type specific templates ---
if [[ -d "$HARNESS_ROOT/project-types/$TYPE" ]]; then
  cp -R "$HARNESS_ROOT/project-types/$TYPE/." .harness/docs/
  echo "[bootstrap] copied project-type templates from $HARNESS_ROOT/project-types/$TYPE" >&2
else
  echo "[bootstrap] project-type '$TYPE' templates not found — using bare _generic skeleton" >&2
fi

# --- Blueprint placeholder ---
if [[ ! -f .harness/docs/blueprint.md ]]; then
  cp "$HARNESS_ROOT/templates/BLUEPRINT.template.md" .harness/docs/blueprint.md
fi

# --- ADR-000 bootstrap decision (heredoc preserves literal $; NAME/TYPE validated) ---
cat > .harness/decisions/ADR-000-bootstrap.md <<EOF
## ADR-000 — Project bootstrap

**Date**: $(date +%Y-%m-%d) · **Status**: accepted
**Amends**: —

**Context**: New project '$NAME' (type=$TYPE) bootstrapped via scripts/new-project.sh from harness $HARNESS_VERSION.

**Decision**: Adopt harness at version $HARNESS_VERSION pinned in .harness/VERSION-PIN. Strictness=strict (default).

**Consequences**:
- Future harness upgrades require migration ADR (see HARNESS.md §6 amend procedure).
- Project follows HARNESS.md phases 00 Intake → 06 Handoff.

**Approval**: pending — fill in after first user signoff
EOF

# --- friendly summary ---
cat <<EOF >&2

[bootstrap] project '$NAME' created
    project-type: $TYPE
    harness pin:  $HARNESS_VERSION
    location:     $(pwd)/.harness/

Next steps:
  1. Edit .harness/config.toml — set [models] entries you have access to
  2. Fill .harness/docs/blueprint.md (Phase 01 Blueprint)
  3. git init && first commit
  4. scripts/codex-exec-review.sh --phase 01-blueprint --slug initial \\
       --prompt-file .harness/prompts/blueprint-review.md  (when ready)
EOF
