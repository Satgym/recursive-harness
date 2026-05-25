#!/usr/bin/env bash
# new-project.sh — Bootstrap a harness-managed project (creates .harness/ skeleton).
#
# Usage:
#   scripts/new-project.sh <project-name> [project-type]
#
# project-name : [a-z0-9][a-z0-9_-]{0,63} (lowercase kebab/snake; F24)
# project-type : exact directory name in project-types/, or '_generic'
# HC-9: aborts if .harness/ already exists (no overwrite).
#
# After bootstrap, the new project does NOT contain its own copy of harness
# scripts. Users invoke them via "$HARNESS_ROOT/scripts/codex-review.sh ..."
# (F27 fix). The bootstrap writes HARNESS_ROOT into .harness/config.toml
# under [harness] root so wrappers can detect it.

set -euo pipefail

HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

NAME="${1:-}"
TYPE="${2:-_generic}"

usage() {
  cat >&2 <<EOF
Usage: $0 <project-name> [project-type]

Constraints:
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

# F24: validation
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

# Read harness version pin
HARNESS_VERSION="$(grep -m1 -E '^# HARNESS\.md' "$HARNESS_ROOT/HARNESS.md" | sed -E 's/.*\(([^)]+)\).*/\1/')"
HARNESS_VERSION="${HARNESS_VERSION:-unknown}"

# F33: include inbox; F28: include api directory for web-service
mkdir -p .harness/{docs/modules,docs/api,reviews,decisions,postmortems,prompts,inbox/processed}

# config.toml (NAME/TYPE validated; HARNESS_ROOT recorded — F27)
cat > .harness/config.toml <<EOF
# .harness/config.toml — harness configuration for this project
# See HARNESS.md §5.2 and ADR-003 for model selection.

project_name = "$NAME"
project_type = "$TYPE"

[harness]
# Absolute path to the harness repo. Used by scripts to locate sibling
# wrappers when invoked from this project's directory.
root = "$HARNESS_ROOT"
version_pin = "$HARNESS_VERSION"

[strictness]
mode = "strict"   # strict | balanced | autonomous

[git]
base_branch = "main"

[models]
# review = "<model id for cross-review>"
# exec   = "<model id for text review>"

[reasoning]
review = "high"
exec   = "medium"
EOF

echo "$HARNESS_VERSION" > .harness/VERSION-PIN

# STATUS.md from template (awk for sed-safe substitution; F24)
awk -v name="$NAME" -v hv="$HARNESS_VERSION" '
  { gsub(/<project name>/, name); gsub(/<e\.g\. v0\.5>/, hv); print }
' "$HARNESS_ROOT/templates/STATUS.template.md" > .harness/status.md

# F28: instantiate Phase 00 artifacts with their intended names
TYPE_DIR="$HARNESS_ROOT/project-types/$TYPE"
if [[ ! -d "$TYPE_DIR" ]]; then
  TYPE_DIR="$HARNESS_ROOT/project-types/_generic"
  echo "[bootstrap] project-type '$TYPE' templates not found — falling back to _generic" >&2
fi

# intake-checklist.md -> .harness/docs/intake.md (Phase 00 expected artifact)
if [[ -f "$TYPE_DIR/intake-checklist.md" ]]; then
  cp "$TYPE_DIR/intake-checklist.md" .harness/docs/intake.md
fi
# test-strategy.md and module-skeleton.md kept as reference (read-only seeds)
for f in test-strategy.md module-skeleton.md; do
  [[ -f "$TYPE_DIR/$f" ]] && cp "$TYPE_DIR/$f" ".harness/docs/$f"
done
# web-service api-spec-template.md -> .harness/docs/api/openapi.yaml placeholder
if [[ "$TYPE" == "web-service" ]] || [[ -f "$TYPE_DIR/api-spec-template.md" ]]; then
  cp "$TYPE_DIR/api-spec-template.md" .harness/docs/api/openapi.yaml.notes.md 2>/dev/null || true
  # Empty placeholder for the actual spec — will be filled during Phase 01/02
  if [[ ! -f .harness/docs/api/openapi.yaml ]]; then
    cat > .harness/docs/api/openapi.yaml <<YAMLEOF
# Placeholder — fill with concrete OpenAPI 3.1 spec during Phase 01 Blueprint
# Reference: .harness/docs/api/openapi.yaml.notes.md (template + 8 rules)
# Reference: $HARNESS_ROOT/project-types/web-service/api-spec-template.md
openapi: 3.1.0
info:
  title: "$NAME API"
  version: "0.1.0"
paths: {}
components:
  schemas: {}
YAMLEOF
  fi
fi

# Blueprint placeholder (from generic template)
if [[ ! -f .harness/docs/blueprint.md ]]; then
  cp "$HARNESS_ROOT/templates/BLUEPRINT.template.md" .harness/docs/blueprint.md
fi

# ADR-000 (heredoc preserves literal $; NAME/TYPE already validated)
cat > .harness/decisions/ADR-000-bootstrap.md <<EOF
## ADR-000 — Project bootstrap

**Date**: $(date +%Y-%m-%d) · **Status**: accepted
**Amends**: —

**Context**: New project '$NAME' (type=$TYPE) bootstrapped via scripts/new-project.sh from harness $HARNESS_VERSION at $HARNESS_ROOT.

**Decision**: Adopt harness at version $HARNESS_VERSION pinned in .harness/VERSION-PIN. Strictness=strict (default). HARNESS_ROOT recorded in .harness/config.toml under [harness] root.

**Consequences**:
- Future harness upgrades require migration ADR (see HARNESS.md §6 amend procedure).
- Project follows HARNESS.md phases 00 Intake → 06 Handoff per [phases/](file://$HARNESS_ROOT/phases/).
- Harness scripts are invoked as "\$HARNESS_ROOT/scripts/<name>.sh" (no per-project copy).

**Approval**: pending — fill in after first user signoff
EOF

# Inbox README
cat > .harness/inbox/README.md <<EOF
# Project INBOX (.harness/inbox/)

Codex 능동 피드백 채널 (이 프로젝트 전용). HARNESS §4.2 / INBOX/README.md 컨벤션 따름.

- Unread: \`.harness/inbox/codex-feedback-*.md\` with front-matter \`status: open\`
- 처리 완료된 파일은 \`.harness/inbox/processed/\`로 이동

자세한 양식: $HARNESS_ROOT/INBOX/README.md
EOF

# Friendly summary
cat <<EOF >&2

[bootstrap] project '$NAME' created
    project-type: $TYPE
    harness pin:  $HARNESS_VERSION
    harness root: $HARNESS_ROOT
    location:     $(pwd)/.harness/

Next steps:
  1. export HARNESS_ROOT="$HARNESS_ROOT"
     (or rely on .harness/config.toml [harness] root — wrappers auto-detect)
  2. Edit .harness/config.toml — set [models] entries you have access to
  3. Fill .harness/docs/intake.md (Phase 00 Intake artifact)
  4. git init && first commit
  5. When ready for Blueprint review:
       "\$HARNESS_ROOT/scripts/codex-exec-review.sh" --phase 01-blueprint \\
           --slug initial --prompt-file .harness/prompts/blueprint-review.md
EOF
