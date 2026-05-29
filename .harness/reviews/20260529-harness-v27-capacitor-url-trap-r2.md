---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.7) CAPACITOR_SERVER_URL trap — r2 post-patch
review_round: r2
prior_review: .harness/reviews/20260529-harness-v27-capacitor-url-trap-r1.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7181-e155-7903-a044-659b78e01246
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 71212
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T02:13
  prompt_source: .harness/prompts/harness-v27-capacitor-server-url-trap-review-r2.md
---

**REVIEW**

- `severity: blocker`  
  `위치`: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:77), [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:463)  
  `근거`: redaction regex only matches values with `scheme://` followed by a non-empty authority. For edge cases it no-ops and logs the full value:
  - `example.com/foo?token=secret` → leaks full query
  - `user:pass@example.com/foo?token=secret` → leaks userinfo + query
  - `file:///tmp/foo?token=secret` → leaks path + query
  Also, `@` in a path can misparse the host: `https://example.com/foo@bar?token=secret` → `https://bar`.  
  `제안`: replace the single sed with authority-based parsing that first strips `#` and `?`, then extracts only the authority segment, then strips userinfo from that authority. For unsupported/no-authority schemes, print a generic marker like `<non-http-url-redacted>` rather than the original value.

- `severity: nit`  
  `위치`: [DECISIONS.md](/Users/satgym/work/harness/DECISIONS.md:38)  
  `근거`: ADR still says “6-line warning” and “value 노출”, but current behavior is redacted and the emitted warning is longer.  
  `제안`: update wording to “redacted origin 표시” and current line count, or avoid hardcoding the count.

**Answers**

1. `${CAPACITOR_SERVER_URL+x}` correctly fixes the precedence bug. Set-but-empty now preserves the force-local intent and does not fall through to `.env.local`.

2. The sed works for normal `http(s)://host`, userinfo-bearing valid URLs, no-userinfo URLs, and bracketed IPv6 like `https://[::1]:3000/...`. It does not safely handle no-scheme or no-authority schemes such as `file://`.

3. The “full value redacted” line is clear enough once redaction is actually total. Right now it can be false for the failing cases above.

4. New concern: the reusable PATTERNS snippet carries the same redaction weakness, so the issue can propagate to other projects.

**Verdict: `block`**

The env precedence fix is good, but the HC-7 redaction patch is incomplete for explicitly requested edge cases. I verified `bash -n examples/starpin/scripts/run-mobile-smoke.sh` passes.
