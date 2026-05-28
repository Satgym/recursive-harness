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
        body = raw[start:end].rstrip()
    else:
        body = raw.rstrip()
    return _strip_leading_frontmatter(body)


def _strip_leading_frontmatter(body: str) -> str:
    """
    v1.8 (F128) — codex sometimes wraps its review with its *own* YAML
    frontmatter (since the prompt asked for REVIEW.template.md format which
    starts with `---`). build_front_matter() then prepends another wrapper,
    producing two consecutive YAML blocks in the saved file — flagged by
    meta-review codex Q2.3. Strip the inner one here so postprocess output
    has exactly one canonical frontmatter (built from invocation metadata).
    """
    stripped = body.lstrip()
    if not stripped.startswith("---\n"):
        return body
    # Find the closing `\n---\n` of the leading frontmatter block.
    after_open = stripped[4:]
    close_match = re.search(r"\n---\n", after_open)
    if not close_match:
        return body  # malformed; leave alone
    inner_end = 4 + close_match.end()
    leading_space = body[: len(body) - len(stripped)]
    return leading_space + stripped[inner_end:].lstrip("\n")


# v2.3.1 (Hara HC-13 dogfood lesson — harness-v231-r1 codex blocker #1):
# When codex emits canonical verdict keys in its inner front-matter,
# _strip_leading_frontmatter discards them. The wrapper FM did not preserve
# those values, so ui-visual-review.sh had to fall back to body parsing —
# which was the exact failure mode v2.3.1 set out to fix. This helper pulls
# the canonical verdict keys out of the inner FM before stripping so
# build_front_matter can merge them into the wrapper.
_CANONICAL_VERDICT_KEYS = ("codex_pass", "blocker_count", "major_count", "minor_count")


def extract_canonical_verdict(raw_or_body: str) -> dict:
    """Pull canonical verdict keys (codex_pass, *_count) from any leading YAML
    front-matter block found in the codex output. Works on both the raw codex
    stdout and the already-stripped body (since _strip_leading_frontmatter is
    called inside extract_review_body before build_front_matter sees it). We
    scan the entire input for the first `---\\n ... \\n---\\n` block."""
    m_open = re.search(r"(?m)^---\s*$", raw_or_body)
    if m_open is None:
        return {}
    rest = raw_or_body[m_open.end():]
    m_close = re.search(r"(?m)^---\s*$", rest)
    if m_close is None:
        return {}
    inner = rest[: m_close.start()]
    fields: dict = {}
    for key in _CANONICAL_VERDICT_KEYS:
        # v2.3.1 r2 — allow optional inline YAML comment after the value
        # (e.g. "codex_pass: true   # or: false"). Without the comment-aware
        # alternative the `\s*$` anchor refused such lines silently.
        m = re.search(
            r"(?m)^\s*" + re.escape(key) + r"\s*:\s*([^\n#]+?)\s*(?:#[^\n]*)?\s*$",
            inner,
        )
        if m:
            v = m.group(1).strip().rstrip(".,;")
            fields[key] = v
    return fields


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
    # v2.3.1: merge canonical verdict keys from codex's inner FM (codex_pass,
    # blocker_count, major_count, minor_count). v2.3.1 r2 minor fix — when
    # the codex CLI markers (`\ncodex\n` / `\ntokens used\n`) change shape
    # the body_region was empty and merge silently disabled. Fall back to the
    # already-stripped body parameter, which still contains the original FM
    # block (extract_review_body strips it but we get a copy of the inner
    # content via the `body` argument before strip happened — except it's
    # already stripped). So as a final fallback scan the raw output but
    # restrict to FM blocks that contain at least one canonical verdict key.
    end = raw.find("\ntokens used\n")
    codex_marks = list(re.finditer(r"\ncodex\n", raw))
    body_region = ""
    if codex_marks and end > 0:
        body_region = raw[codex_marks[-1].end():end]
    canonical_verdict = extract_canonical_verdict(body_region)
    if not canonical_verdict:
        # Fallback: scan raw for any FM block that mentions any verdict key.
        for fm_match in re.finditer(r"(?ms)^---\s*$(.+?)^---\s*$", raw):
            candidate = extract_canonical_verdict(
                "---\n" + fm_match.group(1) + "\n---\n"
            )
            if candidate:
                canonical_verdict = candidate
                break
    for key in _CANONICAL_VERDICT_KEYS:
        if key in canonical_verdict:
            fm_lines.append(f"{key}: {canonical_verdict[key]}")
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
    tokens = extract_tokens(raw)
    print(f"[postprocess] wrote {dest} (tokens={tokens})", file=sys.stderr)

    # v1.6 M7 — append to canonical token ledger (machine-readable JSONL)
    try:
        update_token_ledger(dest, args, tokens, meta)
    except Exception as e:
        print(f"[postprocess] WARN: ledger update failed: {e}", file=sys.stderr)
    return 0


def update_token_ledger(review_path: Path, args, tokens_str: str, meta: dict) -> None:
    """
    v1.6 M7 (meta-review codex finding) — auto-append review event to canonical ledger
    at `.harness/codex-token-ledger.jsonl`. Each line = single review event with
    machine-parseable fields. STATUS.md "Cumulative codex tokens" 라인이 더 이상
    수동 추정 아닌 — `wc -l` + `jq` 등으로 정확 산출 가능.
    """
    import json
    from datetime import datetime, timezone
    ledger_root = review_path
    while ledger_root.name != ".harness" and ledger_root.parent != ledger_root:
        ledger_root = ledger_root.parent
    if ledger_root.name != ".harness":
        return  # not under .harness/ — skip
    ledger_path = ledger_root / "codex-token-ledger.jsonl"
    tokens_int = 0
    try:
        tokens_int = int(str(tokens_str).replace(",", "")) if tokens_str else 0
    except (ValueError, TypeError):
        tokens_int = 0
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "phase": getattr(args, "phase", "") or "",
        "slug": getattr(args, "slug", "") or "",
        "review_round": getattr(args, "review_round", "") or "",
        "tokens": tokens_int,
        "model": meta.get("model", ""),
        "review_path": str(review_path.relative_to(ledger_root.parent)) if ledger_root.parent in review_path.parents else str(review_path),
    }
    with ledger_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    print(f"[postprocess] ledger appended to {ledger_path.name}", file=sys.stderr)


if __name__ == "__main__":
    sys.exit(main())
