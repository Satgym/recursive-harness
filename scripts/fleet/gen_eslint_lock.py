#!/usr/bin/env python3
"""
gen_eslint_lock.py — Generate per-child ESLint config that enforces interface lock
                    at *AST level* (not grep).

F102 v1.3 patch — replaces grep-only `lock-grep-gate` with AST-grade enforcement.
Reads SPLIT-DECISION-ADR + each child's locked-interface §"Consumed interface" and
emits `.eslintrc.<child>.json` with `no-restricted-imports` rules that block any
runtime import not in the allowlist.

Usage:
    python3 scripts/fleet/gen_eslint_lock.py <split-decision-adr.md> [--out-dir .]

Output: one .eslintrc.<child>.json per child, e.g.
{
  "rules": {
    "no-restricted-imports": ["error", {
      "paths": [
        {
          "name": "../auth/index.js",
          "importNames": ["createSession", "revokeSession"],
          "message": "Lock violation (Fleet F1): child 'claim' may only import 'verifySession' from '../auth/index.js'. See .harness/subtrees/claim/locked-interface.md."
        }
      ]
    }]
  }
}

Limitations:
- Only handles direct named imports. Namespace imports (`import * as X`) and re-exports
  via barrel files require AST-walker or @typescript-eslint custom rule (v1.4 후보).
- ESLint must run during the child's pre-review-gate; spawn-subtree-prompts injects
  `npx eslint --config .eslintrc.<child>.json src/<child>/**/*.ts` into the prompt.
"""
import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path


def parse_owned_paths(locked_iface_path: Path) -> tuple[list[str], list[str]]:
    """
    F121 v1.4 patch — parse `## File ownership` section of locked-interface to extract
    the *actual* writable paths (real projects don't always have `src/<child>/` layout).

    Returns (file_globs, test_globs) for ESLint `files:` pattern.
    Falls back to `src/<child>/**/*.ts` if section missing.
    """
    content = locked_iface_path.read_text(encoding="utf-8")
    m = re.search(r"##\s+File ownership[^\n]*\n(.*?)(?=\n##\s|\Z)", content, re.DOTALL)
    if m is None:
        return [], []
    section = m.group(1)
    files: list[str] = []
    tests: list[str] = []
    # Match `쓰기...: <path1>, <path2>, ...` or bullet list `- <path>` or backticks
    # Strategy: extract all backtick-quoted paths in the "쓰기" (write) bullet
    write_match = re.search(r"\b쓰기[^:]*[::]([^\n]*(?:\n\s+[^\n]+)*)", section)
    if not write_match:
        # Also support English "Write" / "writable"
        write_match = re.search(r"\b[Ww]rit[a-z]*[^:]*[::]([^\n]*(?:\n\s+[^\n]+)*)", section)
    if write_match:
        write_block = write_match.group(1)
        # Extract backtick paths
        for path_m in re.finditer(r"`([^`]+)`", write_block):
            p = path_m.group(1).strip()
            # Skip non-path entries like merge-report.md within .harness/
            if p.startswith(".harness/") or p.endswith(".md"):
                continue
            # Categorize: tests/ → test, else → src
            if "tests/" in p or p.startswith("test"):
                # Path may be a file or dir; ESLint pattern needs glob
                if p.endswith(".ts"):
                    tests.append(p)
                elif p.endswith("/") or "*" not in p:
                    tests.append(f"{p.rstrip('/')}/**/*.ts")
                else:
                    tests.append(p)
            elif p.endswith(".ts"):
                files.append(p)
            elif p.endswith(".sql") or p.endswith(".yml") or p.endswith(".yaml") or p.endswith(".sh"):
                # Non-ts files — skip ESLint (it only lints .ts)
                continue
            elif p.endswith("/") or "*" not in p:
                files.append(f"{p.rstrip('/')}/**/*.ts")
            else:
                files.append(p)
    return files, tests


def parse_runtime_allowlist(locked_iface_path: Path) -> dict[str, list[str]]:
    """
    Parse `## Consumed interface` section. Look for `import { ... } from '...';` lines
    inside ts code blocks. These define the *allowed* runtime imports per provider.
    Returns {provider_module_path: [allowed_method_names]}.
    """
    content = locked_iface_path.read_text(encoding="utf-8")
    # Find section header (variations supported)
    m = re.search(
        r"##\s+Consumed interface[^\n]*\n(.*?)(?=\n##\s|\Z)", content, re.DOTALL
    )
    if m is None:
        return {}
    section = m.group(1)

    allowlist: dict[str, list[str]] = defaultdict(list)
    # Extract runtime named imports — multi-line supported:
    #   import { a, b } from '../X/index.js';
    #   import {
    #     a,
    #     b,
    #   } from '../X/index.js';
    # SKIP `import type { ... }` (type-only is not runtime).
    runtime_pattern = re.compile(
        r"import\s+\{([^}]+)\}\s+from\s+['\"]([^'\"]+)['\"]\s*;?",
        re.MULTILINE | re.DOTALL,
    )
    type_only_pattern = re.compile(
        r"import\s+type\s+\{[^}]+\}\s+from\s+['\"][^'\"]+['\"]\s*;?",
        re.MULTILINE | re.DOTALL,
    )
    # Remove type-only first so they don't confuse runtime matching
    cleaned = type_only_pattern.sub("", section)
    for m_import in runtime_pattern.finditer(cleaned):
        names_raw = m_import.group(1)
        module_path = m_import.group(2)
        names = [n.strip() for n in names_raw.split(",") if n.strip()]
        allowlist[module_path].extend(names)
    return dict(allowlist)


def discover_child_lockfiles(split_decision_path: Path) -> dict[str, Path]:
    """
    F120 v1.4 patch — recursive discovery of all `locked-interface.md` under
    `.harness/subtrees/`. Supports nested round prefixes (e.g. `subtrees/v02/<child>/`)
    used by long-lived projects with multiple Fleet rounds.

    Returns {child_name: locked_interface_path}.
    Child name = parent directory name of the locked-interface.md.
    """
    project_root = split_decision_path.parents[2]
    subtrees_dir = project_root / ".harness" / "subtrees"
    if not subtrees_dir.exists():
        return {}

    children: dict[str, Path] = {}
    for li in subtrees_dir.rglob("locked-interface.md"):
        child_name = li.parent.name
        # Round prefix (e.g. 'v02') itself shouldn't be a child — skip directories that contain
        # only sub-subtrees, no locked-interface.md
        if child_name in children:
            # Duplicate name across rounds — collision; prefer most-recent-modified
            existing = children[child_name]
            if li.stat().st_mtime > existing.stat().st_mtime:
                children[child_name] = li
        else:
            children[child_name] = li
    return children


def find_all_provider_modules(split_decision_path: Path) -> dict[str, list[str]]:
    """
    Discover all provider modules a child *might* import (across all locked-interfaces).
    Returns {provider_module_path: [exported_method_names]}.
    """
    providers: dict[str, list[str]] = {}
    for child_name, li in discover_child_lockfiles(split_decision_path).items():
        provider_module = f"../{child_name}/index.js"
        content = li.read_text(encoding="utf-8")
        m = re.search(
            r"##\s+Public interface[^\n]*\n.*?```ts\n(.*?)\n```",
            content, re.DOTALL,
        )
        if m:
            ts = m.group(1)
            names = re.findall(r"export\s+function\s+(\w+)", ts)
            providers[provider_module] = names
    return providers


def child_names(split_decision_path: Path) -> list[str]:
    return sorted(discover_child_lockfiles(split_decision_path).keys())


def build_eslint_flat_config(
    child: str,
    allowlist: dict[str, list[str]],
    all_providers: dict[str, list[str]],
    owned_src_globs: list[str] | None = None,
    owned_test_globs: list[str] | None = None,
) -> str:
    """
    Emit ESLint v9+ flat config (eslint.config.<child>.mjs) — F110 v1.3 codex patch:
    **fail-closed** approach.

    Layer 1 (patterns): block ALL `../<provider>/**` paths except `../<provider>/index.js`
                       → catches internal sibling reach-around (../auth/store.js etc.)
    Layer 2 (paths):   on `../<provider>/index.js`, deny named imports not in allowlist
                       → catches direct allowlist violations (createSession from claim)

    Limitation (still v1.4 후보):
    - `export { x } from '...'` re-export barrels (custom AST walker)
    - `export const` / `export class` (gen_eslint_lock currently parses `export function` only;
      provider 측 인터페이스에 const/class 있으면 deny-list 불완전 — 단 Layer 1 path block이
      partial mitigation)
    - namespace import (`import * as X from '...'`) — Layer 2의 importNames는 안 잡지만
      Layer 1의 wildcard path block이 막음 (단 `../<provider>/index.js`로 직접 namespace
      import은 통과 — custom rule v1.4)
    """
    own_module = f"../{child}/index.js"
    own_dir_pattern = f"../{child}/**"
    paths_rules = []
    patterns_rules = []
    for provider_module, all_exports in all_providers.items():
        if provider_module == own_module:
            continue
        provider_name = provider_module.replace("../", "").replace("/index.js", "")
        provider_dir = f"../{provider_name}/**"
        own_provider_pattern = f"../{provider_name}/!(index.js)*"

        # Layer 1: block all sibling internal paths (deny pattern; allow only index.js)
        patterns_rules.append({
            "group": [f"../{provider_name}/*", f"!{provider_module}"],
            "message": (
                f"Lock violation (Fleet F1 / F90 — F110 v1.3 fail-closed): child '{child}' may not "
                f"import from internal paths of '{provider_name}' (only '{provider_module}' is permitted). "
                f"See .harness/subtrees/{child}/locked-interface.md."
            ),
        })

        # Layer 2: on index.js, deny named imports not in allowlist
        allowed = sorted(set(allowlist.get(provider_module, [])))
        denied = sorted(set(all_exports) - set(allowed))
        if denied:
            allowlist_str = repr(allowed) if allowed else "(none — provider not consumed)"
            msg = (
                f"Lock violation (Fleet F1 / F90): child '{child}' may not import "
                f"the listed names from '{provider_module}'. "
                f"Allowlist: {allowlist_str}. "
                f"See .harness/subtrees/{child}/locked-interface.md."
            )
            paths_rules.append({
                "name": provider_module,
                "importNames": denied,
                "message": msg,
            })

    paths_json = json.dumps(paths_rules, indent=2, ensure_ascii=False)
    patterns_json = json.dumps(patterns_rules, indent=2, ensure_ascii=False)
    paths_indented = "\n".join("        " + ln for ln in paths_json.splitlines())
    patterns_indented = "\n".join("        " + ln for ln in patterns_json.splitlines())

    # F121 v1.4 — use owned_paths from locked-interface, fallback to src/<child>/**
    src_globs = owned_src_globs if owned_src_globs else [f"src/{child}/**/*.ts"]
    test_globs = owned_test_globs if owned_test_globs else [f"tests/{child}/**/*.ts"]
    all_globs = src_globs + test_globs
    files_str = json.dumps(all_globs)

    return f"""// AUTO-GENERATED by scripts/fleet/gen_eslint_lock.py (Fleet F102 v1.3 + F110 fail-closed + F121 v1.4 owned-paths)
// child: {child}
// Layer 1 (patterns): blocks sibling internal paths (../<provider>/store.js etc.)
// Layer 2 (paths):    on ../<provider>/index.js, denies named imports outside allowlist
// Limitation (v1.4+ 후보): export const/class + re-export barrel + namespace import partial

import tsParser from '@typescript-eslint/parser';

export default [
  {{
    files: {files_str},
    languageOptions: {{
      parser: tsParser,
      parserOptions: {{ ecmaVersion: 2023, sourceType: 'module' }},
    }},
    rules: {{
      'no-restricted-imports': ['error', {{
        paths:
{paths_indented},
        patterns:
{patterns_indented},
      }}],
    }},
  }},
];
"""


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("adr", type=Path, help="path to SPLIT-DECISION-ADR.md")
    ap.add_argument("--out-dir", type=Path, default=None, help="output dir (default: ADR's project root)")
    args = ap.parse_args()
    if not args.adr.exists():
        raise SystemExit(f"FAIL: ADR not found: {args.adr}")

    project_root = args.adr.parents[2]  # .harness/decisions/X.md → root
    out_dir = args.out_dir or project_root

    all_providers = find_all_provider_modules(args.adr)
    children = child_names(args.adr)
    if not children:
        raise SystemExit(f"FAIL: no children found under {project_root}/.harness/subtrees/")

    # F120 v1.4 — use recursive discovery (supports nested round prefixes)
    li_map = discover_child_lockfiles(args.adr)
    for child, li_path in sorted(li_map.items()):
        allowlist = parse_runtime_allowlist(li_path)
        # F121 v1.4 — parse owned paths from locked-interface
        src_globs, test_globs = parse_owned_paths(li_path)
        config_text = build_eslint_flat_config(
            child, allowlist, all_providers,
            owned_src_globs=src_globs or None,
            owned_test_globs=test_globs or None,
        )
        out = out_dir / f"eslint.config.{child}.mjs"
        out.write_text(config_text, encoding="utf-8")
        print(f"[gen_eslint_lock] wrote {out} (src globs: {src_globs or '[fallback]'}, test globs: {test_globs or '[fallback]'})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
