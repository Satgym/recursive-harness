---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: harness(v2.7) CAPACITOR_SERVER_URL trap — r4 post-control-char patch
review_round: r4
prior_review: .harness/reviews/20260529-harness-v27-capacitor-url-trap-r3.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7189-2727-7963-938d-7b827ae0a6f6
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 68665
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T02:21
  prompt_source: .harness/prompts/harness-v27-capacitor-server-url-trap-review-r4.md
---

REVIEW

Verdict: `block`

Finding:
- `severity`: `blocker`
- `위치`: [run-mobile-smoke.sh](/Users/satgym/work/harness/examples/starpin/scripts/run-mobile-smoke.sh:72), [PATTERNS.md](/Users/satgym/work/harness/PATTERNS.md:457)
- `근거`: `redact_url_for_log()` only treats `/` as the authority terminator. A backslash path stays inside `host_port`, so path-like secret material can still be emitted.
- Repro input: `https://example.com\api\secret-token?x=y`
- Actual output: `https://example.com\api\secret-token`
- Expected behavior: either `https://example.com` if `\` is treated as a path separator, or more conservatively `https://<host-redacted>`.

Suggested fix: treat `\` as unsafe in `host_port` and fall back to `<host-redacted>`, or normalize/split on both `/` and `\` before extracting authority. Given the current conservative r3 pattern, adding backslash to the redaction guard is the lowest-risk patch.

Assumption: I’m applying the same HC-7 strictness as r2/r3, where malformed but copy-pasteable URL values are still in scope for log redaction. If the scope is reduced to RFC-valid URL strings only, I did not find a remaining leak in the cited query/userinfo/control-char cases.
