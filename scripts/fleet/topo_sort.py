#!/usr/bin/env python3
"""
topo_sort.py — Topological sort of Fleet child dependencies from SPLIT-DECISION-ADR.

Strategy (c) helper (HARNESS §14.9 — F101 v1.3 implementation, F115 v1.3 codex patch).
Reads SPLIT-DECISION-ADR:
  1. `## Decision` child table (first column = child name) for the *full child set*
     OR `## File ownership matrix` first column (paths like `src/<child>/`)
  2. `## Dependency graph` section (text-form arrows `A -> B`) for dependencies
Outputs the spawn order: providers first, then consumers, grouped in waves.
Each wave can be spawned in parallel; next wave waits for current wave's completion.

Independent children (no deps) appear in wave_1 even if not in dep graph.

Usage:
    python3 scripts/fleet/topo_sort.py <split-decision-adr.md>

Output (stdout):
    wave_1: <child1> <child2>      # no dependencies
    wave_2: <child3>               # depends on wave_1
    wave_3: <child4>               # depends on wave_2
"""
import argparse
import re
import sys
from collections import defaultdict, deque
from pathlib import Path


def parse_children(adr_path: Path) -> set[str]:
    """
    Parse child names from SPLIT-DECISION-ADR. Tries 2 sources:
    1. `## Decision` markdown table — first column = child name (excluding header)
    2. `## File ownership matrix` — extract `<child>` from `src/<child>/` paths
    """
    content = adr_path.read_text(encoding="utf-8")
    children: set[str] = set()

    # Source 1: Decision child table
    decision_m = re.search(r"##\s+Decision\s*\n(.*?)(?=\n##\s|\Z)", content, re.DOTALL)
    if decision_m:
        section = decision_m.group(1)
        # Match markdown table rows; first cell = child name
        # Skip header/separator (--- or ----)
        for line in section.splitlines():
            line = line.strip()
            if not line.startswith("|") or "---" in line:
                continue
            cells = [c.strip() for c in line.strip("|").split("|")]
            if len(cells) >= 2 and cells[0] and cells[0].lower() not in {"child", "name", "id"}:
                # Strip backticks etc.
                name = re.sub(r"[`*]", "", cells[0])
                if re.match(r"^[\w-]+$", name):
                    children.add(name)

    # Source 2: File ownership matrix
    fo_m = re.search(r"##\s+File ownership matrix.*?(?=\n##\s|\Z)", content, re.DOTALL)
    if fo_m:
        for path_m in re.finditer(r"src/([\w-]+)/", fo_m.group(0)):
            name = path_m.group(1)
            if name not in {"shared", "cli"}:
                children.add(name)

    if not children:
        raise SystemExit(
            f"FAIL: no children found in {adr_path}. "
            "Expected '## Decision' child table or '## File ownership matrix'."
        )
    return children


def parse_deps(adr_path: Path, children: set[str]) -> dict[str, set[str]]:
    """
    Parse '## Dependency graph' section. Only `consumer -> provider` arrows supported.
    Lines like `cli (parent) -> child` are skipped (parent isn't a child).
    Returns {consumer: {providers...}} adjacency.
    """
    content = adr_path.read_text(encoding="utf-8")
    m = re.search(r"##\s+Dependency graph.*?(?=\n##\s|\Z)", content, re.DOTALL)
    if m is None:
        return defaultdict(set)
    section = m.group(0)

    deps: dict[str, set[str]] = defaultdict(set)
    for match in re.finditer(r"([\w-]+)\s*->\s*([\w-]+)", section):
        consumer, provider = match.group(1), match.group(2)
        # Only include edges where BOTH endpoints are real children
        if consumer in children and provider in children:
            deps[consumer].add(provider)
    return deps


def topological_waves(deps: dict[str, set[str]], children: set[str]) -> list[list[str]]:
    """Group nodes into waves; each wave is independent of the others within it."""
    # in_degree counts how many providers each consumer depends on
    in_deg: dict[str, int] = {c: 0 for c in children}
    rev: dict[str, set[str]] = defaultdict(set)  # provider -> consumers
    for consumer, providers in deps.items():
        for p in providers:
            in_deg[consumer] = in_deg.get(consumer, 0) + 1
            rev[p].add(consumer)

    waves: list[list[str]] = []
    remaining = dict(in_deg)
    while remaining:
        wave = sorted([n for n, d in remaining.items() if d == 0])
        if not wave:
            raise SystemExit(f"FAIL: cycle detected in dependency graph: {remaining}")
        waves.append(wave)
        for n in wave:
            del remaining[n]
            for c in rev.get(n, set()):
                if c in remaining:
                    remaining[c] -= 1
    return waves


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("adr", type=Path)
    args = ap.parse_args()
    if not args.adr.exists():
        raise SystemExit(f"FAIL: ADR not found: {args.adr}")
    children = parse_children(args.adr)
    deps = parse_deps(args.adr, children)
    waves = topological_waves(deps, children)
    for i, wave in enumerate(waves, start=1):
        print(f"wave_{i}: {' '.join(wave)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
