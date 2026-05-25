#!/usr/bin/env python3
"""Convert raw codex stdout into a canonical REVIEW file with front-matter.

Usage: _codex_postprocess.py <raw_stdout_file> <dest_md_file>

Strips the codex CLI session trace and emits a templates/REVIEW.template.md
style document with a populated `codex_meta` front-matter block.
"""
from __future__ import annotations

import re
import sys
from datetime import date
from pathlib import Path


def parse_header_meta(raw: str) -> dict:
    """Codex prints a `key: value` block between the first two `--------` lines."""
    meta = {}
    m = re.search(r"^--------\n((?:.*\n)+?)^--------\n", raw, re.MULTILINE)
    if not m:
        return meta
    for line in m.group(1).splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        meta[key.strip()] = value.strip()
    return meta


def extract_review_body(raw: str) -> str:
    """Return the actual review body.

    Codex echoes the prompt, then emits multiple `codex` sections containing
    its reasoning / tool calls, and finally a clean answer followed by
    `tokens used`. We take the slice after the last `codex` marker up to
    `tokens used`.
    """
    end = raw.find("\ntokens used\n")
    codex_marks = list(re.finditer(r"\ncodex\n", raw))
    if codex_marks and end > 0:
        start = codex_marks[-1].end()
        return raw[start:end].rstrip()
    return raw.rstrip()


def extract_tokens(raw: str) -> str:
    m = re.search(r"\ntokens used\n([\d,]+)", raw)
    return m.group(1).replace(",", "") if m else "unknown"


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: _codex_postprocess.py <raw> <dest>", file=sys.stderr)
        return 2
    src, dest = Path(sys.argv[1]), Path(sys.argv[2])
    raw = src.read_text(encoding="utf-8", errors="replace")
    meta = parse_header_meta(raw)
    body = extract_review_body(raw)
    tokens = extract_tokens(raw)

    today = date.today().isoformat()
    codex_version = "unknown"
    first_line = raw.splitlines()[0] if raw else ""
    cv = re.match(r"OpenAI Codex v(\S+)", first_line)
    if cv:
        codex_version = cv.group(1)

    front_matter = (
        "---\n"
        "artifact: review\n"
        f"date: {today}\n"
        "author: codex\n"
        "status: open\n"
        "codex_meta:\n"
        f"  codex_version: {codex_version}\n"
        f"  model: {meta.get('model', '')}\n"
        f"  provider: {meta.get('provider', '')}\n"
        f"  session_id: {meta.get('session id', '')}\n"
        f"  workdir: {meta.get('workdir', '')}\n"
        f"  sandbox_policy: {meta.get('sandbox', '')}\n"
        f"  reasoning_effort: {meta.get('reasoning effort', '')}\n"
        f"  tokens_used: {tokens}\n"
        "---\n\n"
    )

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(front_matter + body + "\n", encoding="utf-8")
    print(f"[postprocess] wrote {dest} (tokens={tokens})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
