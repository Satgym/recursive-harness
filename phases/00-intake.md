# Phase 00 — Intake (+ Local Capability Synthesis sub-step, v0.6)

> 프로젝트 성격을 식별하고 project-type *seed*를 선택. Blueprint를 작성하기 위한 *기획 자료* + *프로젝트 로컬 capability layer* (HARNESS §13)를 모은다.
>
> **v0.6 변경**: project-types/는 catalog가 아니라 *seed*. Phase 00 안에 Local Capability Synthesis sub-step이 추가되어 base + seed로 부족한 도메인 특화 skill/role/checklist를 자체 구성한다.

## Entry 입력

- 사용자가 가져온 프로젝트 아이디어 / 요구사항 / 제약
- 사용 가능한 자원 (인력, 시간, 예산, 모델 접근)
- (선택) 기존 자료, 참고 시스템

## Activities

1. **프로젝트 nature 파악** — 사용자와 대화로 다음 정리:
   - 무엇을 만드는가 (한 문장)
   - 누구를 위한가 (사용자/고객)
   - 왜 (비즈니스/연구/학습 동기)
   - 절대 안 되는 것 (non-goals)
2. **project-type seed 선택** (v0.6) — `ls project-types/`에서 가장 가까운 *seed* 선택. 매칭 없거나 seed가 얕으면 `_generic`으로 시작하고 Activity 6 (Local Capability Synthesis)에서 프로젝트 로컬 skill/role/checklist를 구성한다. 새 base project-type 추가는 HARNESS §13.6 promotion 기준(≥2 프로젝트 사용 또는 1 non-trivial dogfood) 충족 후 §6 base 변경 절차로만 (v0.5 잔존 표현 폐기).
3. **intake-checklist 작성** — 해당 project-type의 `intake-checklist.md`를 인스턴스화. project-type별 핵심 결정 (예: web — API 명세 우선 / firmware — MCU 선택 / ai-model — 평가셋·베이스라인 / etc.).
4. **테스트 환경 약속** — 어떻게 디버그·검증할지 *기획 단계에서* 명시: 콘솔 디버그 메시지 prefix / GUI 스크린샷 저장 위치 / HIL 시뮬레이터 등. 이 약속은 Blueprint §6 Observability로 이어진다.
5. **초기 STATUS 작성** — `scripts/new-project.sh`로 부트스트랩, `.harness/status.md` 채움.
6. **Local Capability Synthesis sub-step** ⭐ (v0.6, HARNESS §13.5):
   - Intake 답변과 base + project-type seed 비교 → gap 식별
   - 도메인 특화 skill / role (advisory) / 체크리스트 후보 사용자와 협의
   - 결정된 후보를 [skills/synthesize-local-layer.md](../skills/synthesize-local-layer.md) 절차로 draft 작성
   - [skills/review-local-layer.md](../skills/review-local-layer.md) Codex review (HC-10 delta safety check) → 사용자 승인
   - `.harness/capabilities.md` manifest의 *Active* 섹션에 등재
   - **gap 없으면 본 sub-step은 짧게 종료** (manifest는 빈 Active로 생성 후 다음 phase로). 진행 중 발견 시 재발동 가능.

## Outputs

- `.harness/config.toml` (project_name, project_type, strictness, [models], [reasoning], [git], [harness])
- `.harness/VERSION-PIN`
- `.harness/docs/intake.md` (intake-checklist 결과)
- `.harness/status.md` (초기 STATUS, 10섹션)
- `.harness/decisions/ADR-000-bootstrap.md` (자동)
- `.harness/skills/`, `.harness/roles/`, `.harness/capabilities.md` (v0.6 — adaptive skeleton, manifest는 sub-step 후 *Active* 채움)

## Exit 기준

- [ ] `.harness/config.toml` 완성 (strictness 모드 + harness root + base branch 결정됨)
- [ ] `.harness/docs/intake.md`의 모든 핵심 결정 답변됨 (또는 명시적으로 *Blueprint에서 결정*으로 deferred)
- [ ] 테스트 환경 약속 1줄 이상 명시 (모호한 "테스트 잘 해라" 불충분)
- [ ] **Local Capability Synthesis sub-step 종료** (v0.6): `.harness/capabilities.md` 생성됨 + (gap 있으면) draft Codex review 통과 + 사용자 승인 + Active 등재 완료. gap 없으면 빈 Active로 명시 통과.
- [ ] STATUS의 *Active gate*가 "01 Blueprint" 가리킴
- [ ] **strict / balanced 모드: 사용자 승인** (intake 결과 + capability manifest)
- [ ] **autonomous 모드**: skip 가능. 단 명시적 user-given autonomy가 ADR로 기록되어 있어야 함

## 주도 역할

- **claude-implementer** — 대화 진행, checklist 작성, 산출물 생성, capability synthesis 진행
- **codex-reviewer** — capability synthesis sub-step에서 local material delta safety check (HC-10)
- **user** — 핵심 결정 / 제약 / 승인 (strict/balanced) + capability manifest *Active* 등재 승인

## 발생 가능한 드리프트 / 위험

- ❌ project-type을 너무 일찍 _generic으로 떨어뜨림 → 도메인 특화 체크리스트 누락 → 향후 Blueprint에서 재발견 (드리프트 신호)
- ❌ "테스트 환경"을 "나중에 결정" 처리 → Phase 03/04에서 디버깅 인프라 없어 임시방편 발생
- ❌ 사용자 승인 없이 Blueprint로 점프 (HC-4 위반)

## 다음 phase

[01-blueprint.md](01-blueprint.md) — intake 결과를 바탕으로 모듈 경계와 의존성을 정의.
