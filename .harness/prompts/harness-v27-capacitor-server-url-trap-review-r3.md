# Codex r3 — Hara v2.7 CAPACITOR_SERVER_URL trap (post-r2 blocker patch)

r2 verdict was `block` for HC-7 redaction edge cases. r3 re-evaluates after patch.

## r2 → r3 patch

**BLOCKER — redaction edge cases (FIXED)**:

Replaced the single-line `sed -E '...'` with a step-wise `redact_url_for_log()` function (new) called from `detect_capacitor_server_url`:

1. Strip fragment: `url="${url%%#*}"`
2. Strip query: `url="${url%%\?*}"`
3. Require scheme: `if [[ ! "$url" =~ ^([a-zA-Z][a-zA-Z0-9+.-]*)://(.*)$ ]]; then echo "<non-http-url-redacted>"; return; fi`
4. Extract authority: `local authority="${rest%%/*}"`
5. Strip userinfo from authority: `local host_port="${authority##*@}"`
6. Empty authority handling: `[[ -z "$host_port" ]] && echo "${scheme}://<host-redacted>" || echo "${scheme}://${host_port}"`

## Self-test (8 cases)

```
PASS: https://user:pass@example.com/foo?token=secret#x  → https://example.com
PASS: example.com/foo?token=secret                       → <non-http-url-redacted>
PASS: user:pass@example.com/foo?token=secret             → <non-http-url-redacted>
PASS: file:///tmp/foo?token=secret                       → file://<host-redacted>
PASS: https://example.com/foo@bar?token=secret           → https://example.com
PASS: https://[::1]:3000/api?token=secret                → https://[::1]:3000
PASS: https://roundup-grating.ngrok-free.dev             → https://roundup-grating.ngrok-free.dev
PASS: http://192.168.1.1:8080/?x=y                       → http://192.168.1.1:8080
```

Covers r2 codex's 4 leak cases + IPv6 + plain IP host + bare https://host.

## PATTERNS.md + ADR-043 updates

- PATTERNS.md §smoke-setup v2.7 subsection — bash snippet now shows both functions; "r1+r2 codex 반영" note.
- DECISIONS.md ADR-043 — "r2 codex patch" block enumerates the 4 specific leak cases + step-wise fix + 8-case self-test summary + carry note ("새 surface 발견 시 redact 함수 확장").

## What to evaluate (r3)

1. Does the new `redact_url_for_log()` correctly handle all r2-cited cases?
2. Any remaining redaction edge case missed (e.g., `mailto:`, `data:`, control chars in URL, `\n` in path)?
3. Did the documentation propagate the fix to the reusable PATTERNS snippet?
4. Final verdict — does the v2.7 ship now meet HC-7 + provide the right operator signal?

## Files

- `examples/starpin/scripts/run-mobile-smoke.sh` (added `redact_url_for_log` + simplified `detect_*` call)
- `PATTERNS.md` §smoke-setup v2.7 (both functions in bash snippet)
- `DECISIONS.md` ADR-043 (r2 codex patch block + 8-case self-test)
