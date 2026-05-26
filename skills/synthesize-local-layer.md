# Skill: synthesize-local-layer

## Purpose

[HARNESS.md §13.5](../HARNESS.md)의 Local Capability Synthesis (phase 00 sub-step)을 실행. Intake 결과 분석 후 base + project-type seed로 *부족한* 도메인 특화 skill/role/checklist를 식별하고 local layer로 draft 생성. Codex review + 사용자 승인 후 capability manifest 등재.

## When to invoke

- Phase 00 Intake 완료 직후 (`.harness/docs/intake.md` 작성됨)
- Phase 01 Blueprint *전*
- 또는 진행 중 새 도메인 결함이 발견되어 local capability가 필요할 때 (예: dogfood F41)

## Inputs

- `.harness/docs/intake.md` (Phase 00 결과)
- `.harness/config.toml` (project_type seed)
- base: HARNESS.md, skills/, roles/, templates/, phases/, project-types/<seed>/
- (선택) 사용자의 도메인 추가 정보

## Procedure

1. **Gap 분석** — Intake 답변과 base + seed를 비교:
   - Intake §6 (테스트 환경 약속) — base test-strategy seed로 충분한가? 새 도메인 도구 / HIL / 시뮬레이터 / 평가셋이 필요한가?
   - Intake §8 (HC-7/8/9 사전 식별) — base 룰로 충분한가? 도메인 특화 보호 hook이 필요한가?
   - Intake §1 도메인 — base에 없는 *전문 영역*인가? (firmware safety / ML eval / hardware control / 보안 감사 등)
   - Blueprint 진입 시 *없으면 막힐* 자료가 있는가? (예: spec-first → API 명세 양식, firmware → 메모리 예산 표)

2. **Capability 후보 식별** (3 카테고리):
   - **Local skill 후보**: 도메인 특화 절차 (예: `validate-fmea-table`, `run-hil-smoke`, `score-ml-baseline`)
   - **Local role (advisory) 후보**: 도메인 SME (예: `firmware-safety-reviewer`, `ml-eval-judge`)
   - **Checklist 추가**: 기존 base 체크리스트에 *추가* 항목 (Blueprint §승인 체크, MODULE-PLAN §DoD, codex-reviewer 체크리스트)

3. **사용자 협의** (strict 모드 — 모든 모드 사용자 승인 필수):
   - 각 후보를 사용자에게 *드래프트 의도*로 보고
   - 사용자가 "X 필요" / "Y 생략" 결정
   - 결정된 후보만 draft 작성으로 진행

4. **Draft 작성**:
   - skills: `cp templates/LOCAL-SKILL.template.md .harness/skills/<id>.md` 후 채움
   - roles: `cp templates/LOCAL-ROLE.template.md .harness/roles/<id>.md` 후 채움
   - 모든 draft는 `status: draft` (아직 Active 아님)

5. **Manifest 초기화 / 갱신**:
   - `.harness/capabilities.md` 없으면 `cp templates/CAPABILITY-MANIFEST.template.md .harness/capabilities.md`
   - 새 draft를 *Draft / pending* 섹션에 등재 (Active 아님 — review/approval 후 이동)

6. **Codex review 의뢰** ([skills/review-local-layer.md](review-local-layer.md))

7. **사용자 승인** — review 통과 후

8. **Manifest 갱신**: draft → Active로 이동. STATUS *Approved artifacts*에 manifest 등재.

9. **Capability synthesis 종료** → Phase 01 Blueprint 진입 가능

## Outputs / Side effects

- `.harness/skills/*.md` (local skill drafts → approved)
- `.harness/roles/*.md` (local role drafts → approved)
- `.harness/capabilities.md` (manifest, 처음 생성 또는 갱신)
- `.harness/reviews/00.5-capability-*.md` (Codex review 결과)
- STATUS *Approved artifacts* 갱신

## Failure modes

- **gap 분석에서 *너무 많은* capability를 draft** → role/skill 폭발. 사용자 협의에서 "꼭 필요한 것만"으로 가지치기. 의심 시 *나중에* synthesize 재발동 (Phase 진행 중에도 가능).
- **HC-10 위반 draft** (base 약화) → Codex review가 blocker로 표시. 재작성.
- **base만으로 충분한데 over-engineering** → drift 신호. base + _generic seed로 시작 후 *실제 발견 시점*에 synthesize.

## Anti-patterns

- ❌ 모든 프로젝트마다 동일한 local capability를 매번 다시 만들기 (→ base 승격 후보, HARNESS §13.6)
- ❌ Local role에 execution authority 부여 (HC-10 위반)
- ❌ approver enum에 새 값 추가 (HC-10 위반)
- ❌ Capability manifest 우회 — `.harness/skills/`에 파일 두고 manifest 등재 안 하기 (working set 안 들어감)

## Related

- [HARNESS.md §13](../HARNESS.md) (Project-local Adaptive Layer)
- [skills/review-local-layer.md](review-local-layer.md)
- [templates/LOCAL-SKILL.template.md](../templates/LOCAL-SKILL.template.md)
- [templates/LOCAL-ROLE.template.md](../templates/LOCAL-ROLE.template.md)
- [templates/CAPABILITY-MANIFEST.template.md](../templates/CAPABILITY-MANIFEST.template.md)
- [phases/00-intake.md](../phases/00-intake.md) (Local Capability Synthesis sub-step)
- [skills/harness-amend.md](harness-amend.md) (base 변경 절차와 차이 명시)
