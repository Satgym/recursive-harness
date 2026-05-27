#!/usr/bin/env python3
"""
validate_capabilities.py — Schema validator for .harness/capabilities.md (v1.6 M4 closure).

Checks:
  1. front-matter is valid yaml-like with `artifact: capability_manifest`
  2. Active sections list count matches actual `- path:` entries
  3. Each listed skill/role file actually exists on disk
  4. status values are canonical enum (approved/proposed/superseded/rejected)
  5. Frozen state — emits hash + last-modified for git-diff comparison

Usage:
    python3 scripts/fleet/validate_capabilities.py <path/to/capabilities.md>

Exit codes:
    0: PASS
    1: schema violation (block downstream gates)
    2: usage error
"""
import argparse
import hashlib
import re
import sys
from pathlib import Path


def parse_frontmatter(content: str) -> dict[str, str]:
    """Extract simple key: value pairs from YAML front-matter."""
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not m:
        return {}
    result: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.lstrip().startswith("-"):
            key, _, val = line.partition(":")
            result[key.strip()] = val.strip()
    return result


def find_active_lists(content: str) -> dict[str, list[tuple[str, str]]]:
    """
    Parse Active section yaml-block entries. Supports:
      - inline bullet: `- path: .harness/skills/X.md`
      - yaml block form (starpin style):
        ```yaml
        # Skills (N Active)
        - id: foo
          path: .harness/skills/X.md
          status: approved
        ```
    Returns {section_label: [(path, status)...]}.
    """
    result: dict[str, list[tuple[str, str]]] = {}
    yaml_blocks = re.findall(r"```yaml\n(.*?)\n```", content, re.DOTALL)
    for block in yaml_blocks:
        # v1.6 cleanup M5 (codex fix) — inline section comments are *boundaries*, not just block header.
        # `# Skills` and `# Roles` within same yaml block → separate sections.
        cur_section = "Unknown"
        cur_entries: list[tuple[str, str]] = []
        cur_path: str | None = None
        cur_status: str | None = None
        in_entry = False

        def commit_entry() -> None:
            nonlocal cur_path, cur_status
            if cur_path is not None:
                cur_entries.append((cur_path, cur_status or ""))
            cur_path = None
            cur_status = None

        def flush_section() -> None:
            nonlocal cur_entries
            if cur_entries:
                if cur_section in result:
                    result[cur_section].extend(cur_entries)
                else:
                    result[cur_section] = list(cur_entries)
                cur_entries = []

        for line in block.splitlines():
            sec_match = re.match(r"^#\s*(\w+)\b", line)
            if sec_match:
                commit_entry()
                flush_section()
                cur_section = sec_match.group(1)
                in_entry = False
                continue
            if re.match(r"^\s*-\s+id:\s*", line) or re.match(r"^\s*-\s+name:\s*", line):
                commit_entry()
                in_entry = True
                continue
            if not in_entry:
                continue
            p_match = re.match(r"^\s+path:\s*([^\s]+)", line)
            if p_match:
                cur_path = p_match.group(1).strip().strip(',"\'')
                continue
            s_match = re.match(r"^\s+status:\s*([^\s]+)", line)
            if s_match:
                cur_status = s_match.group(1).strip().strip(',"\'')
        commit_entry()
        flush_section()
    return result


def count_in_yaml_comment(content: str, label: str) -> int | None:
    """Extract count from yaml comments like '# Skills (5 Active)' → 5."""
    pattern = re.compile(rf"^#\s*{re.escape(label)}.*?\((\d+)\s+Active\)?", re.IGNORECASE | re.MULTILINE)
    m = pattern.search(content)
    if m:
        return int(m.group(1))
    return None


CANONICAL_STATUS = {"approved", "proposed", "superseded", "rejected", "draft", "deprecated"}


def validate(path: Path) -> int:
    if not path.exists():
        print(f"FAIL: {path} not found", file=sys.stderr)
        return 1
    content = path.read_text(encoding="utf-8")

    fm = parse_frontmatter(content)
    errors: list[str] = []
    warnings: list[str] = []

    # 1. front-matter check
    if fm.get("artifact") != "capability_manifest":
        errors.append(f"front-matter missing 'artifact: capability_manifest' (got: {fm.get('artifact')})")

    # 2/3. Active sections — count + file existence + status canonical
    active_lists = find_active_lists(content)
    project_root = path.parent.parent if path.name == "capabilities.md" else path.parent

    for section, entries in active_lists.items():
        approved_count = sum(1 for _, status in entries if status == "approved")
        # Header advertised count (in yaml comment) vs actual approved count
        header_count = count_in_yaml_comment(content, section)
        if header_count is not None and header_count != approved_count:
            errors.append(
                f"section '{section}': yaml comment advertises {header_count} Active, "
                f"actual approved count = {approved_count}"
            )

        # File existence + canonical status
        for rel, status in entries:
            full = project_root / rel
            if not full.exists():
                errors.append(f"section '{section}': path '{rel}' does not exist (looked at {full})")
            if status and status not in CANONICAL_STATUS:
                errors.append(f"section '{section}': entry '{rel}' has non-canonical status '{status}' (allowed: {CANONICAL_STATUS})")

    # 4. Frozen hash (for downstream diff comparison)
    file_hash = hashlib.sha256(path.read_bytes()).hexdigest()[:16]
    print(f"[validate_capabilities] manifest hash: {file_hash}")
    print(f"[validate_capabilities] active sections found: {list(active_lists.keys())}")
    for section, entries in active_lists.items():
        approved = sum(1 for _, s in entries if s == "approved")
        print(f"[validate_capabilities]   {section}: {len(entries)} entries ({approved} approved)")

    if warnings:
        print("WARNINGS:", file=sys.stderr)
        for w in warnings:
            print(f"  - {w}", file=sys.stderr)
    if errors:
        print("FAIL — schema violations:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(f"PASS — capabilities.md valid ({path})")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("capabilities_md", type=Path)
    args = ap.parse_args()
    return validate(args.capabilities_md)


if __name__ == "__main__":
    sys.exit(main())
