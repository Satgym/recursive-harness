You are conducting r1 review of Hara v2.4.2 — ARIA imperative enforcement + ui-visual-review race retry.

## Context

v2.4.1 (1f9eb22) ship 후 starpin v0.17.2 + v0.19 dogfood 모두 *subagent 가 interactive input/button 에 aria-label 누락* 패턴 반복. coordinator 가 post-hoc patch + Maestro rerun 으로 cleanup. v2.4.2 = 이 패턴을 *prompt-side* 에서 enforce.

또한 v0.19 dogfood 에서 ui-visual-review.sh 가 "codex review output not found" 로 fail (race: codex postprocess file write 가 wrapper glob 보다 약 O(100ms) 지연). v2.4.2 = retry loop 추가.

## v2.4.2 changes

1. `scripts/check-subagent-prompt.sh` `--strict` block:
   - 기존 impl-review path 검사 + 신규 ARIA imperative grep
   - `grep -qiE '\baria[- ]?label\b'` — prompt body 에 "aria-label" 또는 "aria label" 단어 존재 의무
   - 누락 시 exit 1 + 친절한 안내 (PATTERNS §deliverable-categories 참조 + recommended snippet 위치)

2. `scripts/ui-visual-review.sh` codex output find:
   - 기존 single glob → 5-iteration retry loop with 1s sleep
   - postprocess write 가 wrapper glob 보다 늦게 와도 5초 안에 detect

3. `PATTERNS.md` §deliverable-categories `### ARIA label imperative for Maestro` 섹션:
   - "v2.4.2 enforced" tag + precedent (v0.17.2 + v0.19)
   - recommended prompt snippet (copy-paste form) — coordinator 가 future subagent prompt 에 그대로 포함하면 lint 통과

## Self-test verified

- v0.19 friends-share prompt (no aria-label) → --strict FAIL ✓ (would have caught the v0.19 issue)
- v0.20 today-search prompt (has aria-label section in spec) → --strict PASS ✓
- review prompt (no -impl suffix) → SKIP regardless

## YOUR REVIEW (r1)

### Section A — ARIA grep
1. Regex `\baria[- ]?label\b` 정확? matches:
   - `aria-label` (standard HTML attr) ✓
   - `aria label` (loose form in prose) ✓
   - `aria_label` — does NOT match (intentional? or should match snake_case?)
   - `ARIA-LABEL` (case-insensitive flag `-i` set) ✓
2. False positives: prompt mentions `aria-labelledby` — currently matches (`\b` word boundary가 `-by` 전에 끊김? `\b` after `aria-label` → 다음 char 가 word char 면 fail). Edge — `aria-labelledby` 가 prompt 의 ARIA section 안 있으면 OK 같이 처리되어야?
3. Edge: prompt has `<!-- aria-label test -->` (comment) — still grep matches. Acceptable (count as mention).

### Section B — race retry
1. 5 iterations × 1s sleep = 최대 5s. v0.19 race 가 100ms 였으면 1st retry 에서 잡힘.
2. retry 가 너무 길면 CI 시간 증가 — 5s budget 합리?
3. 첫 시도가 성공하면 break 후 sleep 안 함 — 정상 path 영향 없음 확인.

### Section C — PATTERNS clarity
1. recommended prompt snippet 가 한국어 + 영어 hybrid (한국어 설명 + 영어 attribute name). 일관성?
2. precedent 표 (v0.17.2 + v0.19) — 실제 dogfood 사례 잘 represents?

### Section D — Regression
1. v0.20 today-search prompt (이미 subagent 진행 중) 가 v2.4.2 grep 에 통과? — verified.
2. v0.19 friends-share prompt 가 v2.4.2 grep 에 fail — historical 이지만 historical 은 OK.
3. 미래 subagent prompt 작성 시 coordinator 가 ARIA section 빠뜨림 → lint 가 잡음 → workflow 가 1 iteration 줄어듬 — 예상 효과 측정 어떻게?

## Output format (STRICT — v2.3.1)

Front-matter MUST include:
  codex_pass: true        # or false
  blocker_count: 0
  major_count: 0
  minor_count: 0          # or actual counts

Body: prose.
