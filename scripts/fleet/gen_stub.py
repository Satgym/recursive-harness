#!/usr/bin/env python3
"""
gen_stub.py — Generate TypeScript stub file from a Fleet locked-interface markdown.

Strategy (a) helper (HARNESS §14.9 — F101 v1.3 implementation).
parent invokes this BEFORE spawning a consumer child, to provide a typecheck-passing
stub of the provider module. Stub bodies all `throw new Error('not-implemented')`.
The provider child later overwrites the stub completely.

Usage:
    python3 scripts/fleet/gen_stub.py <locked-interface.md> [--out src/<provider>/index.ts]

Reads the first fenced code block under the `## Public interface (제공)` header
(or `## Public interface`) and replaces function bodies with throw stubs.
Re-exports type aliases as-is.
"""
import argparse
import re
import sys
from pathlib import Path


def extract_public_interface(md_path: Path) -> str:
    """Find first ts code block under '## Public interface' heading."""
    content = md_path.read_text(encoding="utf-8")
    # Match `## Public interface[...]` followed by a fenced ts block (any text in between)
    pattern = re.compile(
        r"##\s+Public interface[^\n]*\n.*?```ts\n(.*?)\n```",
        re.DOTALL,
    )
    m = pattern.search(content)
    if m is None:
        raise SystemExit(f"FAIL: no '## Public interface' ts block in {md_path}")
    return m.group(1)


def stub_function_bodies(ts: str) -> str:
    """
    Replace `export function NAME(...): RT;` (declaration-only) → add throw stub body.

    F113 v1.3 codex patch: previous regex broke on multi-line return types containing
    object literal semicolons (Result<{ session: Session; token: SessionToken }, ...>).
    Use balanced-brace + balanced-angle walker instead.

    Walks from `export function NAME(` forward, balancing `()`, `<>`, `{}` until top-level
    `;` (declaration end) or `{` (body start). Only handles declaration-only export functions.
    """
    out_parts = []
    i = 0
    n = len(ts)
    pattern = re.compile(r"export\s+function\s+(\w+)\s*", re.MULTILINE)

    while i < n:
        m = pattern.search(ts, i)
        if m is None:
            out_parts.append(ts[i:])
            break
        out_parts.append(ts[i:m.start()])
        name = m.group(1)
        j = m.end()
        # Walk balanced: count <>, (), {} depth
        depth_paren = 0
        depth_angle = 0
        depth_brace = 0
        end_idx = None
        while j < n:
            c = ts[j]
            if c == "<":
                depth_angle += 1
            elif c == ">" and depth_angle > 0:
                depth_angle -= 1
            elif c == "(":
                depth_paren += 1
            elif c == ")" and depth_paren > 0:
                depth_paren -= 1
            elif c == "{" and depth_paren == 0 and depth_angle == 0:
                # Body start (not stub-eligible)
                end_idx = None
                break
            elif c == ";" and depth_paren == 0 and depth_angle == 0 and depth_brace == 0:
                # Top-level declaration end
                end_idx = j
                break
            j += 1

        if end_idx is None:
            # Either body-start or unparseable — leave as-is, skip past
            out_parts.append(ts[m.start():j + 1] if j < n else ts[m.start():])
            i = j + 1 if j < n else n
            continue

        decl = ts[m.start():end_idx]  # without trailing ;
        stub = (
            f"{decl} {{\n"
            f"  throw new Error('not-implemented: {name} is a Fleet stub — provider child must overwrite');\n"
            f"}}"
        )
        out_parts.append(stub)
        i = end_idx + 1

    result = "".join(out_parts)

    # Fail-fast: if any declaration-only export function remains, this generator
    # missed something. F113 v1.3 codex requirement.
    leftover = re.search(r"export\s+function\s+\w+[^{]*;\s*$", result, re.MULTILINE)
    if leftover is not None:
        raise SystemExit(
            f"FAIL: gen_stub left declaration-only export function (regex parser limitation): "
            f"'{leftover.group(0).strip()}'. Use a TS parser (e.g. @typescript-eslint/parser) "
            f"or fix the locked-interface to keep return types on one line."
        )

    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("locked_interface", type=Path, help="path to locked-interface.md")
    ap.add_argument("--out", type=Path, default=None, help="output ts path (default: stdout)")
    args = ap.parse_args()

    if not args.locked_interface.exists():
        raise SystemExit(f"FAIL: locked-interface not found: {args.locked_interface}")

    ts = extract_public_interface(args.locked_interface)
    stub = stub_function_bodies(ts)

    header = (
        "// AUTO-GENERATED stub (Fleet F101 strategy=a)\n"
        f"// source: {args.locked_interface}\n"
        "// Provider child MUST overwrite this file with real implementation.\n"
        "// All function bodies throw 'not-implemented' — consumer typecheck passes; tests use real impl post-merge.\n\n"
    )
    output = header + stub + "\n"

    if args.out is None:
        sys.stdout.write(output)
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(output, encoding="utf-8")
        print(f"[gen_stub] wrote {args.out} ({len(output)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
