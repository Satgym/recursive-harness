You are conducting r1 functional review of Hara v2.3.1 ship — HC-13 dogfood carry consolidation. 6 surface changes in scripts/skills/PATTERNS/HARNESS/DECISIONS.

## Context

4 ship dogfood (starpin v0.13~v0.17) of HC-13 (v2.3 신설) surfaced 7+ carry items. v2.3.1 consolidates into single ship.

## Files changed

1. `scripts/ui-visual-review.sh`:
   - `parse_review_field()` rewritten with front-matter preference + body strict bool/int fallback. Type hint param added (`bool` / `int` / default string).
   - Call sites pass type hints: `claude_pass` + `codex_pass` as `bool`, all `*_count` as `int`.
   - Default codex prompt strengthened with explicit strict YAML example + "body narrative 거부" warning.

2. `scripts/codex-exec-review.sh`:
   - `DEST` filename now includes `-${REVIEW_ROUND}` suffix when REVIEW_ROUND is set, so r1/r2/r3 don't overwrite.

3. `skills/ui-visual-review.md` v0.2 → v0.3 promotion:
   - Added §Known platform limitations (iOS sim setOrientation noop / DeviceOrientation absent / Maestro takeScreenshot region absent / Maestro openLink WKWebView hash route)
   - Added §Self-diagnostic — chunking discipline (PNG/step thresholds)
   - Added §Codex prompt addendum (strict YAML + symmetric-pair check)
   - Added §v0.3 carry resolved (7 carry id ↔ resolution table)

4. `PATTERNS.md` NEW sections:
   - §subagent-recovery (3 modes: 529 / socket-close / spec-incomplete + precedents + prevention)
   - §scope-chunking (분할 필요 vs 과한 분할 신호 + 자가 진단 기준 표)

5. `HARNESS.md`:
   - title v2.3 → v2.3.1
   - HC 표 아래 *Chunking discipline* 안내 1단락
   - §11 version history row added (v2.3.1 → ADR-030)

6. `STATUS.md` + `DECISIONS.md`:
   - STATUS reflects v2.3.1 + recent ships row
   - ADR-030 added

## YOUR REVIEW (r1)

### Section A — parser robustness (ui-visual-review.sh)

- front-matter regex (`^---\s*$(.+?)^---\s*$` MULTILINE DOTALL) correctly extracts first FM block?
- body fallback strict pattern: `(true|false)` for bool, `(\d+)` for int — correct exclusion of trailing prose?
- type hint dispatch — bool/int/default handled?
- backward compatible — review files that ARE clean canonical front-matter still parse correctly?
- edge cases: empty front-matter, FM with comments (`# ...`), value with trailing punctuation (`true.` / `true,`)

### Section B — round suffix (codex-exec-review.sh)

- DEST format: `${PHASE:+${PHASE}-}${DATE}-${SLUG}${ROUND_SUFFIX}.md` — backward compat when REVIEW_ROUND empty?
- collision avoidance: r1 file preserved when r2 runs? r2 preserved when r3 runs?
- callers (codex-bundle-review.sh, ui-visual-review.sh) still work?

### Section C — prompt strengthening

- strict YAML example concrete enough? prose acceptable?
- iOS / Android / desktop reviewer cognitive load — codex more likely to comply now?

### Section D — skill v0.3 + PATTERNS sections

- v0.3 promotion (proposed → accepted) appropriate given 4-ship dogfood evidence?
- §subagent-recovery covers 3 failure modes encountered? prevention actionable?
- §scope-chunking 진단 기준 표 — measurable in practice?

### Section E — HARNESS.md chunking note

- chunking discipline 문장 길이 적절 (HARNESS.md 의 trim 원칙 따라)?
- HC 표 자체는 그대로 — 새 HC 추가 안 함 (chunking 은 *discipline*, hard constraint X) 합리적?

### Section F — Regression sweep

- starpin v0.17 ship 이 v2.3.1 changes 와 incompatible 한 부분? (예: v0.17 의 evidence JSON 이 v2.3.1 parser 로 다시 검증 가능?)
- 모든 v0.14~v0.17 review files 가 새 parser 로 여전히 pass 하는가?
- 4 dogfood ship 의 manual canonical patch 가 본 v2.3.1 이후 발생 안 할 것이라 보는가? (parser 가 narrative-only output 도 strict bool 만 추출 → 가능)

## Output format (STRICT — Hara v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: 평문 narrative 자유. *codex_pass: true.* 같은 line 을 body 에 쓰지 말 것 (parser 가 거부).
