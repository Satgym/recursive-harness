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


def find_all_provider_modules(split_decision_path: Path) -> dict[str, list[str]]:
    """
    Discover all provider modules a child *might* import (across all locked-interfaces
    in the same project). Used to deny ALL imports of non-listed providers too.

    Returns {provider_module_path: [exported_method_names]} — for emitting `restrictedImports`
    on the entire module (when consumer didn't list it at all).
    """
    project_root = split_decision_path.parents[2]  # .harness/decisions/X.md → project root
    subtrees_dir = project_root / ".harness" / "subtrees"
    if not subtrees_dir.exists():
        return {}

    providers: dict[str, list[str]] = {}
    for child_dir in subtrees_dir.iterdir():
        if not child_dir.is_dir():
            continue
        li = child_dir / "locked-interface.md"
        if not li.exists():
            continue
        # Module path the provider exposes
        provider_module = f"../{child_dir.name}/index.js"
        # Extract exported function names from `## Public interface`
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
    project_root = split_decision_path.parents[2]
    subtrees_dir = project_root / ".harness" / "subtrees"
    if not subtrees_dir.exists():
        return []
    return sorted([d.name for d in subtrees_dir.iterdir() if d.is_dir() and (d / "locked-interface.md").exists()])


def build_eslint_flat_config(child: str, allowlist: dict[str, list[str]], all_providers: dict[str, list[str]]) -> str:
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

    return f"""// AUTO-GENERATED by scripts/fleet/gen_eslint_lock.py (Fleet F102 v1.3 + F110 fail-closed)
// source: .harness/subtrees/{child}/locked-interface.md
// Layer 1 (patterns): blocks sibling internal paths (../<provider>/store.js etc.)
// Layer 2 (paths):    on ../<provider>/index.js, denies named imports outside allowlist
// Limitation (v1.4 후보): export const/class + re-export barrel + namespace import partial

import tsParser from '@typescript-eslint/parser';

export default [
  {{
    files: ['src/{child}/**/*.ts', 'tests/{child}/**/*.ts'],
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

    for child in children:
        li_path = project_root / ".harness" / "subtrees" / child / "locked-interface.md"
        allowlist = parse_runtime_allowlist(li_path)
        config_text = build_eslint_flat_config(child, allowlist, all_providers)
        out = out_dir / f"eslint.config.{child}.mjs"
        out.write_text(config_text, encoding="utf-8")
        print(f"[gen_eslint_lock] wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
