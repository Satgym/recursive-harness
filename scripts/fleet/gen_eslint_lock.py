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


def parse_public_module_path(locked_iface_path: Path) -> str | None:
    """
    v1.6 M9 (codex meta-review) — parse `public_module_path:` from locked-interface
    front-matter. Returns absolute or relative path string (e.g. "src/auth/providers/apple.ts").
    When set, gen_eslint_lock uses *this* path as the child's "owns this file" marker
    for sibling-file deny patterns (F123 v1.6).
    """
    content = locked_iface_path.read_text(encoding="utf-8")
    fm_match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
    if not fm_match:
        return None
    for line in fm_match.group(1).splitlines():
        m = re.match(r"^public_module_path:\s*['\"]?([^'\"\s]+)['\"]?\s*$", line)
        if m and not m.group(1).startswith("<"):
            return m.group(1)
    return None


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


def parse_consumed_stable_modules(locked_iface_path: Path) -> dict[str, list[str]]:
    """
    F122 v1.5 patch — parse locked-interface front-matter `consumed_stable_modules:`
    section to extract child's allowed parent-module imports. Yields machine-readable
    allowlist for stable parent modules (e.g. `../catalog/service.js`).

    Front-matter format (yaml, under `---`):
      consumed_stable_modules:
        - module: ../catalog/service.js
          allowed_imports: [CatalogService]
        - module: ../claim/service.js
          allowed_imports: [ClaimService]

    Returns {module_path: [allowed_import_names]}.
    Falls back to empty dict if section absent (back-compat with pre-v1.5 locked-interfaces).
    """
    content = locked_iface_path.read_text(encoding="utf-8")
    fm_match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
    if not fm_match:
        return {}
    fm_lines = fm_match.group(1).splitlines()

    # F124 v1.5 codex M4 patch — state machine parser:
    #   1. find 'consumed_stable_modules:' line
    #   2. consume indented children until next top-level (unindented) field or EOF
    #   3. each block starts with `  - module:` and may include `    allowed_imports:`
    result: dict[str, list[str]] = {}
    in_section = False
    section_indent: int | None = None
    current_module: str | None = None
    for line in fm_lines:
        stripped = line.rstrip()
        if not stripped:
            continue
        # Top-level (zero indent) — exits section
        leading = len(line) - len(line.lstrip())
        if not in_section:
            if re.match(r"^consumed_stable_modules:\s*$", line):
                in_section = True
                section_indent = leading
            continue
        # In section — exit if we hit a sibling top-level field
        if leading <= (section_indent or 0):
            in_section = False
            continue
        # Inside section — match either `- module:` or `allowed_imports:`
        m_module = re.match(r"\s*-\s+module:\s*['\"]?([^'\"\s]+)['\"]?\s*$", line)
        if m_module:
            current_module = m_module.group(1)
            result[current_module] = []
            continue
        m_imports = re.match(r"\s*allowed_imports:\s*\[([^\]]*)\]\s*$", line)
        if m_imports and current_module is not None:
            names = [n.strip().strip("'\"") for n in m_imports.group(1).split(",") if n.strip()]
            result[current_module].extend(names)
    return result


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
    stable_module_allowlist: dict[str, list[str]] | None = None,
    public_module_path: str | None = None,
    sibling_public_paths: list[str] | None = None,
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
    paths_rules = []
    patterns_rules = []
    for provider_module, all_exports in all_providers.items():
        if provider_module == own_module:
            continue
        provider_name = provider_module.replace("../", "").replace("/index.js", "")

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

    # Layer 3 (F122 v1.5) — stable parent module internal-path block.
    #   locked-interface front-matter의 `consumed_stable_modules:` 명시 의무.
    #   본 layer는 *internal path reach-around*만 차단:
    #     - 명시된 module: ../catalog/service.js → ../catalog/* 다른 path 금지
    #   *Named-import allowlist*는 ESLint `no-restricted-imports` 한계로 v1.6 후보
    #   (custom @typescript-eslint rule 필요 — `restricted-imports` 단일 module에 allowlist 미지원).
    #   현재 v1.5는 *partial mitigation* — internal repo/store 접근 차단만.
    if stable_module_allowlist:
        for module_path, allowed_names in stable_module_allowlist.items():
            # parent module의 디렉토리 추출 (예: ../catalog/service.js → catalog)
            m_dir = re.match(r"\.\./([^/]+)/", module_path)
            if not m_dir:
                continue
            parent_dir = m_dir.group(1)
            patterns_rules.append({
                "group": [f"../{parent_dir}/*", f"!{module_path}"],
                "message": (
                    f"Lock violation (Fleet F122 v1.5 — consumed_stable_modules): child '{child}' may not reach "
                    f"into internal paths of stable parent '{parent_dir}' (only '{module_path}' permitted). "
                    f"locked-interface §consumed_stable_modules allowlist: {sorted(allowed_names)}. "
                    f"Named-import allowlist enforcement → codex review (v1.6 custom AST rule 후보)."
                ),
            })

    # Layer 4 (F123 v1.6 codex meta-review M5 closure) — same-directory sibling file deny
    #   본 child의 public_module_path와 *같은 디렉토리에 있는 sibling children의 public file*들을
    #   relative path (`./<sibling>.js`)로 deny. 같은 dir에 공존하는 OAuth providers 같은 케이스에서
    #   `apple.ts`가 `./google.js` import를 차단.
    if public_module_path and sibling_public_paths:
        own_file = Path(public_module_path)
        own_dir = own_file.parent
        for sibling_path in sibling_public_paths:
            sibling = Path(sibling_path)
            if sibling == own_file:
                continue
            if sibling.parent == own_dir:
                # Same directory — relative import would be `./<basename-without-ext>.js`
                sibling_stem = sibling.stem
                # Block both with-ext and without-ext + index variants
                for rel in [f"./{sibling_stem}.js", f"./{sibling_stem}", f"./{sibling.name}"]:
                    patterns_rules.append({
                        "group": [rel],
                        "message": (
                            f"Lock violation (Fleet F123 v1.6 — same-dir sibling): child '{child}' "
                            f"may not import from sibling file '{rel}' (owned by another child). "
                            f"Use external public module path or escalate as patch candidate."
                        ),
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

    # v1.6 M9 — pre-collect public_module_path for each child (sibling-file deny — F123 closure)
    public_paths: dict[str, str] = {}
    for child, li_path in li_map.items():
        pmp = parse_public_module_path(li_path)
        if pmp:
            public_paths[child] = pmp

    all_public_path_values = list(public_paths.values())

    for child, li_path in sorted(li_map.items()):
        allowlist = parse_runtime_allowlist(li_path)
        # F121 v1.4 — parse owned paths from locked-interface
        src_globs, test_globs = parse_owned_paths(li_path)
        # F122 v1.5 — parse consumed_stable_modules from front-matter (parent module reach-around block)
        stable_allowlist = parse_consumed_stable_modules(li_path)
        # v1.6 M9 — get own public_module_path + sibling list for F123 same-dir deny
        own_public = public_paths.get(child)
        sibling_publics = [p for c, p in public_paths.items() if c != child]
        config_text = build_eslint_flat_config(
            child, allowlist, all_providers,
            owned_src_globs=src_globs or None,
            owned_test_globs=test_globs or None,
            stable_module_allowlist=stable_allowlist or None,
            public_module_path=own_public,
            sibling_public_paths=sibling_publics if own_public else None,
        )
        out = out_dir / f"eslint.config.{child}.mjs"
        out.write_text(config_text, encoding="utf-8")
        stable_info = f", stable: {list(stable_allowlist.keys())}" if stable_allowlist else ""
        sibling_info = f", siblings: {len(sibling_publics)}" if own_public and sibling_publics else ""
        print(f"[gen_eslint_lock] wrote {out} (src: {src_globs or '[fb]'}, tests: {test_globs or '[fb]'}{stable_info}{sibling_info})")
    _ = all_public_path_values  # quiet linter
    return 0


if __name__ == "__main__":
    sys.exit(main())
