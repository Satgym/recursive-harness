# Codex r4 — Hara v2.7 CAPACITOR_SERVER_URL trap (post-r3 control-char blocker patch)

r3 verdict was `block` for control-char log injection (authority with `\n` / `\t` would emit multi-line warning carrying header-like content).

## r3 → r4 patch

Added 1-line defensive guard to `redact_url_for_log()`:

```bash
if [[ -z "$host_port" || "$host_port" =~ [[:cntrl:][:space:]] ]]; then
  echo "${scheme}://<host-redacted>"
else
  echo "${scheme}://${host_port}"
fi
```

PATTERNS snippet + ADR-043 r3-patch block synchronized.

## Self-test (11 cases — 8 regression + 3 new)

```
PASS: https://user:pass@example.com/foo?token=secret#x   → https://example.com
PASS: example.com/foo?token=secret                        → <non-http-url-redacted>
PASS: user:pass@example.com/foo?token=secret              → <non-http-url-redacted>
PASS: file:///tmp/foo?token=secret                        → file://<host-redacted>
PASS: https://example.com/foo@bar?token=secret            → https://example.com
PASS: https://[::1]:3000/api?token=secret                 → https://[::1]:3000
PASS: https://roundup-grating.ngrok-free.dev              → https://roundup-grating.ngrok-free.dev
PASS: http://192.168.1.1:8080/?x=y                        → http://192.168.1.1:8080
PASS: https://example.com\nX-Token: secret/path?x=y       → https://<host-redacted>
PASS: https://example.com\tinjection/path                 → https://<host-redacted>
PASS: https://example com/path                            → https://<host-redacted>
```

## What to evaluate (r4)

Codex has now flagged blockers in 3 rounds (r1 major env precedence / r2 blocker redaction edge cases / r3 blocker control-char). Each fix passed self-test against the cited case. After r3's patch, is there any remaining HC-7 leak path?

If yes, identify (precise input + expected redact behavior). If no, verdict `pass` to close the v2.7 ship cycle.

Note: the function is consumed only inside this single shell script's stderr emission of `CAPACITOR_SERVER_URL` for a developer-controlled `.env.local` value. There is no external untrusted input path (it's not a web-facing redaction). The threat model is "operator pasted a URL containing a token into `.env.local` and the warning leaks that token to terminal logs / CI output". Defense-in-depth is welcome but the realistic attack surface is narrow.

## Files

- `examples/starpin/scripts/run-mobile-smoke.sh:74-81` (redact_url_for_log)
- `PATTERNS.md` §smoke-setup v2.7 (snippet sync)
- `DECISIONS.md` ADR-043 (r3 patch block above r2 patch block)
