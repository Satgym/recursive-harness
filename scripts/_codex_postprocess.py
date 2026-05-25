#!/usr/bin/env python3
"""Convert raw codex stdout into a canonical REVIEW file with full front-matter.

Wrappers pass review metadata via CLI args so the resulting REVIEW satisfies
templates/REVIEW.template.md (F20 fix).

Usage:
  _codex_postprocess.py <raw_stdout_file> <dest_md_file>
      [--phase <id>] [--slug <name>] [--review-round <e.g. A.5>]
      [--prior-review <path>] [--target <text>] [--severity <enum>]
      [--base-ref <ref>] [--commit <sha>] [--uncommitted]
      [--included-paths <p1,p2,...>] [--prompt-source <path-or-stdin>]
      [--invoked-at <ISO8601>]
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import datetime, timezone
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
    """Return body after the last `codex` marker up to `tokens used` line."""
    end = raw.find("\ntokens used\n")
    codex_marks = list(re.finditer(r"\ncodex\n", raw))
    if codex_marks and end > 0:
        start = codex_marks[-1].end()
        return raw[start:end].rstrip()
    return raw.rstrip()


def extract_tokens(raw: str) -> str:
    m = re.search(r"\ntokens used\n([\d,]+)", raw)
    return m.group(1).replace(",", "") if m else "unknown"


def extract_codex_version(raw: str) -> str:
    first_line = raw.splitlines()[0] if raw else ""
    cv = re.match(r"OpenAI Codex v(\S+)", first_line)
    return cv.group(1) if cv else "unknown"


def build_front_matter(args: argparse.Namespace, meta: dict, body: str, raw: str) -> str:
    tokens = extract_tokens(raw)
    codex_version = extract_codex_version(raw)
    today = datetime.now(timezone.utc).date().isoformat()
    invoked_at = args.invoked_at or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M")

    # Determine base_ref from args (one-of: base-ref, commit, uncommitted)
    if args.uncommitted:
        base_ref = "uncommitted"
    elif args.commit:
        base_ref = f"commit:{args.commit}"
    elif args.base_ref:
        base_ref = args.base_ref
    else:
        base_ref = ""

    # Severity / target are review-content fields; wrapper can hint but the body itself is authoritative.
    severity_hint = args.severity or "<see body>"
    target_hint = args.target or "<see body>"

    fm_lines = [
        "---",
        "artifact: review",
        f"date: {today}",
        "author: codex",
        "status: open",
        f"severity: {severity_hint}",
        f"target: {target_hint}",
    ]
    if args.review_round:
        fm_lines.append(f"review_round: {args.review_round}")
    if args.prior_review:
        fm_lines.append(f"prior_review: {args.prior_review}")
    fm_lines += [
        "codex_meta:",
        f"  codex_version: {codex_version}",
        f"  model: {meta.get('model', '')}",
        f"  provider: {meta.get('provider', '')}",
        f"  session_id: {meta.get('session id', '')}",
        f"  workdir: {meta.get('workdir', '')}",
        f"  sandbox_policy: {meta.get('sandbox', '')}",
        f"  reasoning_effort: {meta.get('reasoning effort', '')}",
        f"  tokens_used: {tokens}",
        f"  base_ref: {base_ref}",
        f"  included_paths: {args.included_paths or ''}",
        f"  invoked_at: {invoked_at}",
        f"  prompt_source: {args.prompt_source or ''}",
        "---",
        "",
    ]
    return "\n".join(fm_lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="Postprocess codex raw stdout into canonical REVIEW.")
    ap.add_argument("raw", help="Raw codex stdout file")
    ap.add_argument("dest", help="Destination .md file")
    ap.add_argument("--phase")
    ap.add_argument("--slug")
    ap.add_argument("--review-round")
    ap.add_argument("--prior-review")
    ap.add_argument("--target")
    ap.add_argument("--severity")
    ap.add_argument("--base-ref")
    ap.add_argument("--commit")
    ap.add_argument("--uncommitted", action="store_true")
    ap.add_argument("--included-paths")
    ap.add_argument("--prompt-source")
    ap.add_argument("--invoked-at")
    args = ap.parse_args()

    src = Path(args.raw)
    dest = Path(args.dest)
    if not src.exists():
        print(f"[postprocess] error: raw file not found: {src}", file=sys.stderr)
        return 2

    raw = src.read_text(encoding="utf-8", errors="replace")
    meta = parse_header_meta(raw)
    body = extract_review_body(raw)
    front_matter = build_front_matter(args, meta, body, raw)

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(front_matter + body + "\n", encoding="utf-8")
    print(f"[postprocess] wrote {dest} (tokens={extract_tokens(raw)})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
