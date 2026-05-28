You are conducting r1 review of Hara v2.4 — promotion of v2.3.2's §deliverable-categories self-checklist to an enforceable gate via `scripts/check-subagent-prompt.sh`.

## Context

- v2.3.2 (c2a1726) introduced PATTERNS §deliverable-categories with 5 categories (Code / Styling / Tests / Fixture / impl-review).
- starpin v0.18 (dc97fb7) was the first production dogfood — 5/5 categories delivered, 30x speedup vs v0.16.
- v2.4 promotes the self-checklist to an enforceable lint script.

## Files changed

1. `scripts/check-subagent-prompt.sh` (NEW, chmod +x):
   - input: prompt markdown file path
   - check: 5 categories as markdown headings via regex `^#{1,6}[[:space:]]+([0-9]+\.[[:space:]]*)?<cat>`
   - `--strict` flag: additionally require `.harness/reviews/...-impl.md` path mention
   - exit codes: 0 PASS / 1 missing / 2 file not found

2. `PATTERNS.md` §deliverable-categories — "v2.4 carry" → "v2.4 enforced" with script path

3. `HARNESS.md`:
   - title v2.3.2 → v2.4
   - §11 version history row

4. `STATUS.md` + `DECISIONS.md` — ADR-034 added

## YOUR REVIEW (r1)

### Section A — Script logic
1. Regex pattern `^#{1,6}[[:space:]]+([0-9]+\.[[:space:]]*)?<cat>` — catches all reasonable heading forms (`### 1. Code` / `## Code` / `### Code (NEW + MODIFY)`)?
2. `Tests?` category regex handles both "Test" and "Tests" singular/plural?
3. `impl[ -]?review` matches "impl-review" AND "impl review" — both styles in PATTERNS doc?
4. Case-insensitivity (`grep -qiE`) won't accidentally over-match (e.g. "ImplementationReview" → false positive)? Word boundary present?
5. `--strict` impl-review path regex `\.harness/reviews/.*impl.*\.md` — too permissive (matches any review file with "impl" anywhere)? Should require `-impl.md` suffix specifically?

### Section B — Integration / future-proofing
1. PATTERNS template 의 v2.3.2 example 5 카테고리 헤딩 (Code / Styling / Tests / Fixture / impl review) 가 모두 wrapper detection 에 통과? — backward compat
2. starpin v0.18 의 subagent prompt (Agent() inline string, 파일로 안 저장됨) 같은 *inline prompt* 케이스 → 이 wrapper 가 detect 못 함. PATTERNS 에 명시 필요?
3. v2.4.1+ carry: Agent() invocation 자동 호출 — 현 wrapper 가 이 future automation 에 적합한 API 형태 (단순 exit code)?

### Section C — Doc consistency
1. PATTERNS §deliverable-categories 의 "v2.4 enforced" 표현 + DECISIONS ADR-034 + HARNESS §11 row 가 일관?
2. PATTERNS §deliverable-categories 의 5-카테고리 markdown heading example (`### 1. Code` 등) 이 실제 wrapper 가 매칭하는 pattern 과 일치?

### Section D — Regression / dogfood readiness
1. v0.16 sensor prompt (v2.3.2 이전, 5/5 missing) → wrapper FAIL detected 됨. correct.
2. 좋은 prompt (5 categories present) → wrapper PASS 됨. correct.
3. v2.4 dogfood 계획: v0.19 starpin OR next Hara ship 의 subagent dispatch 직전 wrapper 호출. coordinator 가 잊고 호출 안 하면? — 그건 manual discipline (v2.5 carry: pre-Agent hook).

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose freely.
