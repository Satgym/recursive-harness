#!/usr/bin/env python3
"""
gen_ambient.py — Generate TypeScript ambient .d.ts declaration from a locked-interface.

Strategy (b) helper (HARNESS §14.9 — F101 v1.3 implementation).
Consumer child uses this when provider is not yet implemented at spawn time.
Output is a `.d.ts` ambient declaration that satisfies typecheck without runtime impl.
parent merge phase MUST verify the ambient file is *deleted* before merge (or replaced
by real provider import). Phase 05 Exit 기준 includes this check.

Usage:
    python3 scripts/fleet/gen_ambient.py <locked-interface.md> [--out src/<consumer>/<provider>.d.ts]

Wraps the locked-interface ts block in `declare module '../<provider>/index.js' { ... }`.
"""
import argparse
import re
import sys
from pathlib import Path


def extract_public_interface(md_path: Path) -> str:
    """Find first ts code block under '## Public interface' heading."""
    content = md_path.read_text(encoding="utf-8")
    pattern = re.compile(
        r"##\s+Public interface[^\n]*\n.*?```ts\n(.*?)\n```",
        re.DOTALL,
    )
    m = pattern.search(content)
    if m is None:
        raise SystemExit(f"FAIL: no '## Public interface' ts block in {md_path}")
    return m.group(1)


def to_ambient(ts: str, provider_module: str) -> tuple[str, list[str]]:
    """
    Wrap exports as a `declare module` block.

    F114 v1.3 codex patch: preserve `import type` statements OUTSIDE the declare block
    (TS allows top-level `import type` next to `declare module`). Runtime imports are
    stripped (ambient doesn't have runtime).

    Returns (ambient_block, top_level_type_imports).
    """
    type_imports: list[str] = []
    body_lines: list[str] = []
    for line in ts.splitlines():
        stripped = line.strip()
        if re.match(r"^\s*import\s+type\s+", line):
            type_imports.append(stripped)
            continue
        if re.match(r"^\s*import\s+", line):
            # runtime import — drop (ambient = no runtime)
            continue
        body_lines.append(line)
    body = "\n".join(body_lines).strip()
    ambient = (
        f"declare module '{provider_module}' {{\n"
        + "\n".join("  " + ln if ln else "" for ln in body.splitlines())
        + "\n}\n"
    )
    return ambient, type_imports


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("locked_interface", type=Path)
    ap.add_argument(
        "--module",
        default=None,
        help="declare module specifier (default: derived from <provider> in locked-interface filename like .harness/subtrees/<provider>/locked-interface.md → '../<provider>/index.js')",
    )
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    if not args.locked_interface.exists():
        raise SystemExit(f"FAIL: locked-interface not found: {args.locked_interface}")

    provider_name = args.locked_interface.parent.name
    module_spec = args.module or f"../{provider_name}/index.js"

    ts = extract_public_interface(args.locked_interface)
    ambient, type_imports = to_ambient(ts, module_spec)

    header = (
        "// AUTO-GENERATED ambient (Fleet F101 strategy=b, F114 v1.3 type-import preserved)\n"
        f"// source: {args.locked_interface}\n"
        f"// module: {module_spec}\n"
        "// Consumer child uses this during parallel spawn when provider is unimplemented.\n"
        "// Phase 05 merge-collection MUST verify this file is deleted before merge.\n\n"
    )
    type_import_block = ""
    if type_imports:
        type_import_block = "\n".join(type_imports) + "\n\n"
    output = header + type_import_block + ambient

    if args.out is None:
        sys.stdout.write(output)
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(output, encoding="utf-8")
        print(f"[gen_ambient] wrote {args.out} ({len(output)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
