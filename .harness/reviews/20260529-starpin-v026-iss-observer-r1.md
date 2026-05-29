---
artifact: review
date: 2026-05-29
author: codex
status: open
severity: minor
target: starpin v0.26 sky-canvas observer-aware ISS overlay
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e7322-74e6-7572-8056-4f5adce90360
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 106373
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-29T09:48
  prompt_source: examples/starpin/.harness/prompts/v026-iss-observer-review.md
---

**REVIEW**

Verdict: `block` before patch, now patched and tests pass. Rationale: the ISS enrichment correctly uses topocentric coordinates, but raw observer lat/lon leaked through `apiCall` error logs because the request path included `/v1/iss?lat=&lon=&alt=`.

Finding:
- `severity`: `blocker`
- `위치`: [shell.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/shell.ts:292)
- `근거`: `apiCall` logged `{ path }` on network and non-OK errors. For the new ISS observer call, that path contains raw geolocation query params, violating HC-7.
- `제안`: strip query strings from `apiCall` diagnostic logs.

Patch applied:
- Added `safeLogPath()` and changed both `network error` and `non-ok` logs to emit only the path without query params: [shell.ts](/Users/satgym/work/harness/examples/starpin/backend/public/lib/shell.ts:272).
- Added HC-7 regression coverage for ISS network-error degradation: [sky-highlight-enrich-iss.test.ts](/Users/satgym/work/harness/examples/starpin/backend/tests/unit/web/sky-highlight-enrich-iss.test.ts:116).

Other review points:
- Negative cache: 5 minutes is acceptable for this refresh cadence; longer denial caching is a UX policy choice, not required for correctness.
- `enableHighAccuracy: false`: acceptable for the stated degree-scale overlay target.
- Enrichment passthrough/degrade behavior and sky-canvas ordering look sound after the log redaction fix.

Validation:
- `npm --prefix backend run build`: pass
- `npm --prefix backend test -- sky-highlight-enrich-iss.test.ts iss-observer.test.ts`: 16 pass
- `npm --prefix backend test`: 488 pass / 3 skip / 0 fail
diff --git a/examples/starpin/backend/public/lib/shell.ts b/examples/starpin/backend/public/lib/shell.ts
index 5814de37a98115b64535cc74476ac8cd45aff5d7..3e36c3ea2c9d8e5931b5e57c334656b8dc8f12a8
--- a/examples/starpin/backend/public/lib/shell.ts
+++ b/examples/starpin/backend/public/lib/shell.ts
@@ -269,6 +269,11 @@
   return rid.slice(0, 8);
 }
 
+function safeLogPath(path: string): string {
+  const queryStart = path.indexOf('?');
+  return queryStart === -1 ? path : path.slice(0, queryStart);
+}
+
 export async function apiCall<T>(path: string, init: RequestInit = {}): Promise<ApiResult<T>> {
   const session = loadSession();
   const headers = new Headers(init.headers ?? {});
@@ -289,7 +294,7 @@
     // Network error — surface generic error code, never log token.
     const reason = err instanceof Error ? err.name : 'network_error';
     // eslint-disable-next-line no-console
-    console.warn('[shell.apiCall] network error', { path, reason });
+    console.warn('[shell.apiCall] network error', { path: safeLogPath(path), reason });
     return { ok: false, status: 0, error: 'network_error' };
   }
 
@@ -340,9 +345,10 @@
     }
   }
 
-  // INV-1: log status + req-id prefix only. NO Authorization header, NO token, NO body.
+  // INV-1: log status + req-id prefix only. NO Authorization header, NO token,
+  // NO body, NO query string (query may carry observer coords).
   // eslint-disable-next-line no-console
-  console.warn('[shell.apiCall] non-ok', { path, status: response.status, rid: ridPrefix });
+  console.warn('[shell.apiCall] non-ok', { path: safeLogPath(path), status: response.status, rid: ridPrefix });
 
   return { ok: false, status: response.status, error: errorCode };
 }
diff --git a/examples/starpin/backend/tests/unit/web/sky-highlight-enrich-iss.test.ts b/examples/starpin/backend/tests/unit/web/sky-highlight-enrich-iss.test.ts
index a6c9354df41a928813b158796838a1411c6ad402..4c8b7af99f28e52a7464ae89485d2a6705701088
--- a/examples/starpin/backend/tests/unit/web/sky-highlight-enrich-iss.test.ts
+++ b/examples/starpin/backend/tests/unit/web/sky-highlight-enrich-iss.test.ts
@@ -113,6 +113,26 @@
     expect(issOut.dec_deg).toBe(20);
   });
 
+  it('network error log redacts observer query params (HC-7)', async () => {
+    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
+    fetchSpy.mockImplementationOnce(async () => {
+      throw new Error('offline');
+    });
+    const entries: HighlightEntry[] = [
+      { objectId: 'iss', kind: 'iss', name: 'ISS', ra_deg: 100, dec_deg: 20 },
+    ];
+    const out = await enrichIssTopocentric(entries, SEOUL);
+    const issOut = out.find((e) => e.kind === 'iss')!;
+    expect(issOut.ra_deg).toBe(100);
+    expect(issOut.dec_deg).toBe(20);
+    const logged = JSON.stringify(warnSpy.mock.calls);
+    expect(logged).toContain('/v1/iss');
+    expect(logged).not.toContain('37.5665');
+    expect(logged).not.toContain('126.978');
+    expect(logged).not.toContain('0.05');
+    warnSpy.mockRestore();
+  });
+
   it('non-iss entries pass through unchanged', async () => {
     const entries: HighlightEntry[] = [
       { objectId: 'hip:1', kind: 'self', name: null },
