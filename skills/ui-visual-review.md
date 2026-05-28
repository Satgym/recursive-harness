---
artifact: base_skill
version: v0.3
supersedes: v0.2 (3-ship dogfood lessons — v0.14/v0.15/v0.16/v0.17 carry 반영)
date: 2026-05-28
author: claude
status: accepted
references:
  - hara_promotion: DECISIONS.md ADR-025 (Hara v2.3 — HC-13 신설 + 본 skill 도입), ADR-027/028/029 (3 dogfood ships)
  - precedent: examples/starpin/.harness/runs/ (4 visual review runs: login-smoke, shell-smoke, sensor-smoke, telescope-features-smoke)
  - harness: HARNESS.md §1 HC-13 (Visual-Review)
  - v0.3_changes: see §"v0.3 carry resolved" at bottom
---

# Base Skill: `ui-visual-review`

> Mobile/web *visual UX* 의 design intent 일치 검증을 *multi-modal LLM (Claude + Codex)* 으로 수행.
> Functional gate (HC-12) 와 별개 — *사용자가 보는 화면이 진짜 의도대로인지* 평가.

## Purpose

HC-12 의 functional smoke (assertVisible "text", id 검사 등) 는 *내부 contract* 만 검증.
*UX 차원* (mobile-first layout, tap target ≥ 44pt, 사용자 친화 정보 노출, 시각적 강조,
accessibility 색 대비) 은 *코드/text* 로 catch 불가 — visual 차원 review 필요.

본 skill 은:
1. Maestro flow 에 `takeScreenshot: <label>` 다수 명령 삽입 → 핵심 화면 PNG 캡쳐
2. coordinator (Claude root) 가 각 PNG 직접 read (multi-modal)
3. design intent (`.harness/docs/ui-spec.md`) 와 대조 → finding emit
4. Codex 가 동일 PNG + Claude finding 받아 independent r2 verify
5. evidence JSON 의 `ui_review.{claude_pass, codex_pass, findings[]}` field 채움
6. pre-push hook 이 (mobile evidence 있을 때) 둘 다 pass 의무

## When to use

- **trigger**: 프로젝트가 web UI surface (`public/`, `frontend/`) 또는 mobile UI surface (Capacitor / native) 를 갖고, **`.harness/docs/ui-spec.md` 가 존재** 할 때
- **frequency**: Phase 04 (CrossReview) 또는 Phase 05 (Integration) 에서 functional smoke 직후
- **scope**: HC-12 smoke 의 *시각적 layer* — Functional gate 가 pass 한 후에만 의미 있음 (망가진 flow 는 visual review 무의미)

## Inputs

| input | source | description |
|---|---|---|
| screenshots dir | `examples/<proj>/.harness/runs/ui-screenshots-<date>-<slug>/` | Maestro flow 의 `takeScreenshot` 산출물; PNG 파일들 + `manifest.json` (label → file path 매핑) |
| design intent doc | `examples/<proj>/.harness/docs/ui-spec.md` | 사용자 가 보는 화면 별 의도, mobile-first / a11y / 사용자 친화 정보 노출 등 명시 |
| review prompt template | `.harness/prompts/ui-review-<slug>.md` | Claude / Codex 에 전달할 review 지침 (skill 이 default 제공, project 별 amend 가능) |

## Outputs

| output | location | description |
|---|---|---|
| Claude review findings | `<proj>/.harness/reviews/ui-claude-<date>-<slug>.md` | Claude (coordinator) 의 visual finding (severity enum + front-matter `claude_pass/blocker_count/major_count/minor_count` 필수) |
| Codex review findings | `<proj>/.harness/reviews/ui-codex-<date>-<slug>.md` | Codex 의 independent verify (r2 역할) — front-matter `codex_pass/blocker_count/major_count/minor_count` 필수 |
| Evidence JSON 보강 | `<proj>/.harness/runs/{e2e,mobile-e2e}-<date>-<platform>-<slug>.json` 의 `ui_review` field | **canonical schema** (v0.2): `claude_pass`, `codex_pass`, `findings_count`, `blocker_count`, `severity_counts.{blocker,major,minor}`, `claude_review` (path), `codex_review` (path) |

### Canonical `ui_review` schema (v0.2 — single source of truth)

```json
{
  "ui_review": {
    "claude_pass": true,
    "codex_pass": true,
    "findings_count": 3,
    "blocker_count": 0,
    "severity_counts": {
      "blocker": 0,
      "major": 1,
      "minor": 2
    },
    "claude_review": "<proj>/.harness/reviews/ui-claude-<date>-<slug>.md",
    "codex_review":  "<proj>/.harness/reviews/ui-codex-<date>-<slug>.md"
  }
}
```

hook 검증 (HC-13): `claude_pass==true && codex_pass==true && blocker_count==0 && both review paths exist`. hand-written `{claude_pass:true, codex_pass:true}` 우회는 review path 존재 의무로 차단.

## Procedure

### Phase 1: Maestro flow 에 screenshot 명령 삽입

`tests/mobile/flows/<flow>.yaml`:
```yaml
- launchApp
- takeScreenshot: "01-index"
- tapOn: "로그인 시작"
- takeScreenshot: "02-login"
# ... 흐름 중 핵심 4~8 화면 만 캡쳐 (너무 많으면 review 비용 ↑)
```

Maestro 가 `~/.maestro/tests/<run-id>/` 에 PNG 저장. wrapper script 가 그것을 evidence dir 로 copy + manifest.json 생성.

### Phase 2: Coordinator (Claude) visual review

skill helper script `scripts/ui-visual-review.sh`:
1. screenshot dir 안 PNG 목록 + ui-spec.md 읽음
2. Coordinator (root claude) 에게 prompt:
   - "이 PNG <label> 가 design intent <spec section> 와 일치하는지 평가. mobile-first / tap target / a11y / 사용자 친화도 5 dimension 별 PASS/FAIL + finding."
3. Coordinator 가 PNG read → finding list 작성 → `ui-claude-<date>-<slug>.md` 저장

### Phase 3: Codex independent r2

`scripts/codex-exec-review.sh` (또는 신규 `codex-visual-review.sh`) 로 codex 호출:
- 동일 screenshot dir + ui-spec.md + Claude finding 전달
- codex 가 PNG 직접 review (vision capable) + Claude finding 검증 (동의 / 반박 / 추가)
- `ui-codex-<date>-<slug>.md` 저장

### Phase 4: Evidence 통합

`scripts/ui-visual-review.sh` 가 두 review file front-matter parse → evidence JSON 의 `ui_review` field 작성 (canonical schema — Outputs 표 참조). 검증 통과 시 exit 0 + JSON patched. 실패 시 위 Failure modes 표 따라 exit.

## Failure modes (v0.2 — codex r1 #3 fix: ui-spec 있음 + screenshot 0 = fail 분리)

| mode | description | runner exit |
|---|---|---|
| `ui-spec.md` 없음 | design intent 미정의 → HC-13 opt-out | skip (skill 호출 안 함; hook 자동 skip) |
| `ui-spec.md` 있음 + screenshot 0 | design intent 정의됐는데 evidence 없음 | **3** (input invalid) — ship 차단 |
| `ui-spec.md` 있음 + Claude review file 없음 | coordinator 가 review 안 함 | **3** (input invalid) — ship 차단 |
| Claude review front-matter `claude_pass != true` | Claude 가 발견 | **1** — ship 차단 |
| Codex 호출 자체 실패 | codex CLI error | **2** — ship 차단 |
| Codex review front-matter `codex_pass != true` | Codex 가 발견 | **2** — ship 차단 |
| 양쪽 pass + combined `blocker_count > 0` | 합산 blocker | **1** — ship 차단 |
| 양쪽 pass + `blocker_count == 0` | green path | **0** — evidence JSON `ui_review` field patched |

## INV / HC

- **HC-13 Visual-Review** (Hara v2.3 신설): UI surface 프로젝트 + `ui-spec.md` 존재 시 visual review 의무
- INV-VR-1: Claude + Codex 둘 다 pass 만 hook 통과 (single-LLM verdict 신뢰 X)
- INV-VR-2: Claude (coordinator) 는 *내부 로직* 이 아니라 *사용자 시각* 으로 평가 (HC-13 의도)
- INV-VR-3: ui-spec.md 변경은 Blueprint amendment 의무 (design intent 는 spec 차원)

## Cost guardrails

- screenshot 4~8 장 권장 (cap 10)
- Claude review 1 round 약 10K~30K tokens (PNG 읽기 + 평가)
- Codex review 1 round 약 30K~80K tokens
- 1 mobile ship 의 total ui-review cost ≈ 40K~110K tokens (functional review 와 별개)
- Cost guardrails: skill spec 에 `MAX_SCREENSHOTS=10` 명시, prompt 도 concise 요구

## Promotion 조건 (이 skill 의 future)

본 skill 은 *base 도입 즉시 사용* (starpin v0.14 가 첫 dogfood). 향후 carry:
- **v0.4 carry**: 자동 a11y audit 통합 (Maestro a11y inspector + axe-core)
- **v0.5 carry**: VRT (visual regression) — baseline 안정화 후
- **v0.6 carry**: 자동 design system 일치 검증 (style guide doc + PNG 색/font 추출 비교)

## v0.3 carry resolved (4-ship dogfood lessons)

| carry id | 원인 | v0.3 resolution |
|---|---|---|
| codex narrative-only canonical fields | codex 가 가끔 `codex_pass: true.` 같은 narrative line 만 emit → script regex 가 long trailing 문구 capture | `scripts/ui-visual-review.sh` v2.3.1: front-matter 우선 + body fallback 은 strict `(true|false)` / `(\d+)` 만 |
| `ui-codex-<slug>.md` round suffix 누락 | r1 = r2 = r3 같은 filename → 이전 round overwrite | `scripts/codex-exec-review.sh` v2.3.1: REVIEW_ROUND 가 있으면 DEST 에 `-r<N>` suffix |
| Codex narrative-only verdict prompt 강도 부족 | 명시적 strict YAML example 부재 | ui-visual-review.sh 의 default prompt 에 strict format example + "prose 거부" 명시 |
| iOS sim `setOrientation` noop | iPhone 17 Pro sim 의 Capacitor WKWebView 가 Maestro orientation lock 무시 | Cost guardrails 옆 *Known platform limitations* 섹션 신설 (아래) |
| chunking discipline (ship 단위 너무 잘게) | ship 마다 review overhead vs 검증 양 mismatch | 본 skill 의 *self-diagnostic* 추가 (아래 §self-diagnostic) |
| symmetric component pair break | newsletter.ts vs news-modal.ts 같은 *대칭 component 쌍* 의 한 쪽 only 패치 시 codex 가 dispute | Codex prompt 에 "symmetric pair" 항목 추가 (아래 §codex prompt addendum) |
| subagent partial-completion socket close | 80% 작성 후 socket close → coordinator 가 어디까지 됐는지 진단 | PATTERNS.md 의 *subagent-recovery* 항목 cross-link (PATTERNS.md §recovery 참조) |

## Known platform limitations (v0.3)

| 도구 | 한계 | mitigation |
|---|---|---|
| iOS simulator (iPhone 17 Pro) | Maestro `setOrientation` noop. `screen.orientation.lock` 무시 | landscape 검증 = CSS spec match only; v0.3+: Android emulator OR 실 device matrix 추가 |
| iOS simulator | DeviceOrientation/Motion event 없음 (real sensor 불가) | sensor-pose 의 fake mode (URL `?simulate=sensor`) 필수 |
| Maestro `takeScreenshot` | full-screen only (region/crop X) | 핵심 부분 강조용 별도 Maestro flow 작성 OR carry to post-process tool |
| Maestro `openLink` (Capacitor WKWebView) | hash route 진입 신뢰성 낮음 (특히 deep link 안 통하는 경우) | 코드 TS check 로 fallback verify, visual evidence 는 carry |

## Self-diagnostic — chunking discipline (v0.3)

본 skill 호출 시 coordinator 가 다음 지표 자가 점검:
- screenshot 양: 2-3장 / Maestro step 5개 미만 → *ship 단위 너무 잘게 쪼개진 신호*. 별개 plan 문서들이 한 묶음 ship 으로 통합 가능한지 재고
- 같은 round 안에서 review cycle 이 3+ 회 반복 → *분할 부족 OR 명세 부족* 의심
- review 자원 (token / 시간) > impl 자원 → ship 단위 키우는 후보

기준값:
- *최소* 4 PNG / 8 Maestro step / 명확한 새 feature 1+개
- *적정* 6-12 PNG / 12-20 Maestro step / 통합된 feature 묶음

## Codex prompt addendum (v0.3 — strict YAML + symmetric-pair check)

`ui-visual-review.sh` 의 default codex prompt 는 v2.3.1 부터:

1. Strict YAML front-matter (boolean / int 필드 4개 — `codex_pass`, `blocker_count`, `major_count`, `minor_count`)
2. Body 의 narrative 안 verdict 같은 line 은 parser 가 거부 (strict bool / int 만 fallback)
3. **Symmetric-pair check**: 두 component 가 대칭 역할 (예: list 와 detail modal, hero card 와 thumb card) 일 때 *대칭성 깨짐* 자동 검사 항목 권고

이 보강은 4-ship dogfood (v0.14 ~ v0.17) 에서 발견된 *Claude + Codex disagree* 의 핵심 신호 — codex 가 *Claude 가 close 한 finding 을 reopen* 하는 패턴의 대부분이 위 4 항목 중 하나에 해당.
