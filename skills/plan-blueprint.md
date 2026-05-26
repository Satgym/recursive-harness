# Skill: plan-blueprint

## Purpose

[phases/01-blueprint.md](../phases/01-blueprint.md)의 산출물(`.harness/docs/blueprint.md`)을 작성하고 Codex 리뷰 + 사용자 승인까지 완료.

## When to invoke

- Phase 00 Intake가 closed (STATUS Approved artifacts에 intake.md)
- STATUS *Active gate*가 "01 Blueprint" 가리킴
- 아직 `.harness/docs/blueprint.md`가 없거나 `status: draft`

## Inputs

- `.harness/docs/intake.md` (Phase 00 결과)
- `.harness/config.toml`
- **`.harness/capabilities.md`** (v0.6 — Active local capabilities; Blueprint 작성 시 반드시 활용)
- Active 섹션에 명시된 local skill / role 파일들 (working set)
- (선택) 도메인 참고 자료 / 기존 시스템 분석

## Procedure

1. **인스턴스화**:
   ```bash
   cp "$HARNESS_ROOT/templates/BLUEPRINT.template.md" .harness/docs/blueprint.md
   ```
2. **9 섹션 채움** (BLUEPRINT.template.md §1-9):
   - §1 Goals / Non-goals
   - §2 Constraints (기술 / 비용 / 시간 / 규제 / 인력)
   - §3 Modules — 각 모듈: Responsibility 1문장 + Interfaces in/out + Dependencies + Test strategy + Owner
   - §4 Dependency graph (사이클 금지 — 사이클이면 분할)
   - §5 Test strategy 전역 (unit / integration / e2e / GUI 또는 HIL — Intake §4 약속 구체화)
   - §6 Observability (구조화 로그 / metric / 디버그 hook — HC-7 redaction 포함)
   - §7 Risks (likelihood × impact, mitigation)
   - §8 Open questions (deferred 명시)
   - §9 승인 체크 (템플릿 6 항목)
3. **HC-7/8/9 영향 식별**: 시크릿이 들어가는 모듈, 외부 mutation을 일으키는 시점, destructive 작업이 발생할 곳을 미리 명시.
4. **Codex 리뷰 의뢰** (모든 strictness 모드 필수):
   - PROMPT 파일을 `.harness/prompts/blueprint-review.md`로 준비 (대상 명시, REVIEW 양식 요구)
   - 호출:
     ```bash
     "$HARNESS_ROOT/scripts/codex-exec-review.sh" --phase 01-blueprint --slug initial \
         --prompt-file .harness/prompts/blueprint-review.md \
         --review-round blueprint-r1 --target ".harness/docs/blueprint.md"
     ```
   - 결과: `.harness/reviews/01-blueprint-<date>-initial.md`
5. **finding 처리** (apply-review skill 호출):
   - blocker = 0 또는 사용자 명시 deferred
   - major: resolved 또는 deferred + reason
   - 변경 후 필요 시 재리뷰 (§5.4 cost guardrail)
6. **사용자 승인** (모든 strictness 모드 필수):
   - Blueprint 본문 + Codex review를 사용자에게 보고
   - 승인 받으면 blueprint front-matter `status: approved` + `approval` 6필드 채움
7. **STATUS 갱신**:
   - *Active gate*가 "02 ModulePlan (M1)" 가리키도록
   - *Approved artifacts*에 blueprint.md 등재

## Outputs / Side effects

- `.harness/docs/blueprint.md` (front-matter `status: approved`)
- `.harness/reviews/01-blueprint-*.md`
- (해당 시) ADR (예: 모듈 경계 결정의 근거)
- STATUS *Active gate* 업데이트

## Failure modes

- **의존성 그래프 사이클** → 모듈 분할 또는 이벤트화. 사이클 그대로 진행 금지 (drift 신호).
- **모듈 < 3** → Phase E dogfood 기준 부합 어려움. 사용자와 결정 (사이즈 작은 프로젝트면 명시적 deferred ADR).
- **Codex 리뷰가 blocker 보고** → 처리 전 phase 진입 금지 (HC-4).
- **사용자 승인 거부** → Intake 회귀 가능 (요구가 변경되었음을 의미).

## Related

- [phases/01-blueprint.md](../phases/01-blueprint.md)
- [templates/BLUEPRINT.template.md](../templates/BLUEPRINT.template.md)
- [skills/request-codex-review.md](request-codex-review.md)
- [skills/apply-review.md](apply-review.md)
- ADR-004 (Blueprint는 모든 모드 사용자 승인)
