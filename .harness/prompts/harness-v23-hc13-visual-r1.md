You are reviewing **Hara v2.3 — HC-13 Visual-Review (ADR-025)**. Harness self-change; HC-11 r1+r2 required.

## Context

사용자 직접 요청: "기능적 구현은 잘 높이는데 UI/UX 차원 검증 mechanism 0". 사용자 결정 (HC-1):
- Path A: Claude multimodal + Codex visual independent review
- Scope: Hara v2.3 base + starpin v0.14 dogfood paired

v2.3 = base ship (visual review infrastructure). v0.14 = 그 first dogfood.

Memory: `feedback-harness-minimalism` 적용 — load-bearing 만, theater 금지.

## Changes under review

5 file diff:

1. **`skills/ui-visual-review.md`** (NEW, base_skill v0.1, ~129 라인):
   - Purpose: visual UX 의 design intent 일치 검증 (functional HC-12 와 분리)
   - 4-phase procedure: Maestro takeScreenshot → Claude review → Codex r2 verify → evidence 통합
   - Inputs: screenshots dir, ui-spec.md (design intent), prompt template
   - Outputs: Claude/Codex review files + evidence JSON 의 `ui_review` field
   - Failure modes: screenshot 0 / ui-spec.md 없음 (skip) / Claude blocker (차단)
   - Cost guardrails: screenshot 4~8 권장, MAX 10
   - HC-13 + INV-VR-1/2/3

2. **`HARNESS.md`**:
   - Preamble v2.2 → v2.3
   - HC-13 row 추가: trigger (UI surface + ui-spec.md), mechanism (Claude + Codex independent), enforcement (pre-push hook), opt-in skip (ui-spec 없으면)
   - "HC-13 은 ui-spec.md 존재 시에만 발동 (opt-in)" 명시
   - §11 version history v2.3 row

3. **`DECISIONS.md`**: ADR-025 추가 (~60 라인)

4. **`.githooks/pre-push`**: HC-13 block 추가 (mobile lane 안)
   - mobile evidence 확인 후 → ui-spec.md 가 tracked 인지 확인 (`git ls-tree | grep`)
   - 존재 시 → recent_mobile_pass JSON 의 `ui_review.{claude_pass, codex_pass}` 둘 다 true 의무
   - 둘 다 통과면 OK, 하나라도 false / missing → fail
   - `note()` carveout 그대로 — gitignored sub-project (starpin) 의 ui-spec.md 는 root 에서 안 보임 → starpin v0.14 의 visual review 는 manual gate

5. **`STATUS.md`**: v2.3 ship 준비 + v0.14 paired 명시

## YOUR REVIEW

### PART A — HC-13 설계 정확성

A.1 **opt-in trigger**: `git ls-tree | grep "*.harness/docs/ui-spec.md"` 가 정확히 작동? in-repo mobile project 가 `frontend/.harness/docs/ui-spec.md` 같은 nested 위치 placement 도 catch?

A.2 **independent r1/r2 패턴**: Claude (coordinator) + Codex 둘 다 visual review. r1 → r2 verify 패턴 그대로 적용. 단일 LLM 의 subjective finding 위험 → independent verify 로 완화 (HC-11 의 multi-round 가 functional 영역에서 잘 작동했던 패턴 그대로).

A.3 **evidence schema 확장**: `mobile-e2e-*.json` 에 `ui_review.{claude_pass, codex_pass, findings_count, blocker_count, claude_review, codex_review}` 추가. backward compat — HC-12 만 사용하는 project 는 ui_review field 없어도 OK (opt-in).

A.4 **opt-in skip vs 의무화 trade-off**: ui-spec.md 없는 project 는 HC-13 skip. 옳은가, 또는 *모든* mobile project 에 ui-spec.md 강제 해야 하는가? 의무화 하면 carry 발생 (모든 기존 mobile project 에 ui-spec.md 작성 의무) → opt-in 이 합리적.

### PART B — pre-push hook 정확성

B.1 hook block 위치 — mobile evidence valid 확인 *후* HC-13 발동. mobile evidence fail 이면 HC-13 까지 도달 안 함 (functional 실패면 visual 무의미).

B.2 ui-spec.md detection 의 `git ls-tree | grep "*.harness/docs/ui-spec.md"` regex — `*.harness/docs/ui-spec.md` 패턴이 모든 nested 위치 catch:
- 루트 `.harness/docs/ui-spec.md` ✓
- 서브프로젝트 `examples/starpin/.harness/docs/ui-spec.md` — gitignored 라 git ls-tree 안 보임 (carveout — 정상)
- `frontend/.harness/docs/ui-spec.md` ✓
- `web/.harness/docs/ui-spec.md` ✓

B.3 evidence JSON validation: `ur.get('claude_pass') is not True` (Python `is` operator) — JSON 의 boolean true 만 PASS, "true" string 이나 1 int 는 fail. 의도 정확? (의도: hand-written 우회 방지)

B.4 recursive self-validation: v2.3 자체 push 시 ui-spec.md 미존재 → HC-13 skip → PASS. recursive correctness.

### PART C — Skill `ui-visual-review.md` spec 완성도

C.1 4-phase procedure 가 Phase 03 background subagent / coordinator 가 그대로 받아서 실행 가능한 detail?

C.2 evidence JSON 의 `ui_review` schema 명시:
- `claude_pass: bool`
- `codex_pass: bool`
- `findings_count: int`
- `blocker_count: int`
- `claude_review: <relative path>`
- `codex_review: <relative path>`
적정? `severity` 별 breakdown 도 필요한가 (blocker/major/minor 각 count)?

C.3 cost guardrail (screenshot MAX 10, 1 ship 당 40K~110K tokens) 합리적?

C.4 ui-spec.md format 미명시 — Markdown 자유양식? 또는 structured template (sections per screen + design dimension 별 spec)?

### PART D — starpin v0.14 dogfood readiness

D.1 starpin v0.14 가 v2.3 ship 직후 받을 작업:
- `examples/starpin/.harness/docs/ui-spec.md` (NEW) — 4~6 핵심 화면 별 design intent
- Maestro flow 에 `takeScreenshot` 명령 4~8개 삽입
- UI 개선 코드 (sky.html responsive + login.html 정리 + star info user-friendly)
- visual review 첫 발동 (Claude + Codex)
- I-CAP-4 manual gate (note() carveout 라 hook 자동 발동 X)

D.2 starpin v0.14 가 ui-spec.md 작성 시 새 SoT — Phase 01 blueprint amendment 의무 (HC-1)? 아니면 implementation 단계의 design ref?

### PART E — Verdict

**ship | block | minor-followup**.

특히 PART B.2 (regex pattern) + PART C.2 (schema completeness) + PART D.2 (ui-spec ownership) 가 blocker 여부 평가.

## OUTPUT

표준 REVIEW format. harness-minimalism 적용 — 진짜 enforce 못하는 documentation theater 발견하면 flag.
