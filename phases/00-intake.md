# Phase 00 — Intake

> 프로젝트 성격을 식별하고 project-type을 선택. Blueprint를 작성하기 위한 *기획 자료*를 모은다.

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
2. **project-type 선택** — `ls project-types/`에서 가장 가까운 디렉토리. 매칭 없으면 `_generic`. 향후 deep template 필요 시 새 project-type을 만드는 것 자체가 하니스 작업 (메타 부트스트랩).
3. **intake-checklist 작성** — 해당 project-type의 `intake-checklist.md`를 인스턴스화. project-type별 핵심 결정 (예: web — API 명세 우선 / firmware — MCU 선택 / ai-model — 평가셋·베이스라인 / etc.).
4. **테스트 환경 약속** — 어떻게 디버그·검증할지 *기획 단계에서* 명시: 콘솔 디버그 메시지 prefix / GUI 스크린샷 저장 위치 / HIL 시뮬레이터 등. 이 약속은 Blueprint §6 Observability로 이어진다.
5. **초기 STATUS 작성** — `scripts/new-project.sh`로 부트스트랩, `.harness/status.md` 채움.

## Outputs

- `.harness/config.toml` (project_name, project_type, strictness, [models], [reasoning], [git])
- `.harness/VERSION-PIN`
- `.harness/docs/intake.md` (intake-checklist 결과)
- `.harness/status.md` (초기 STATUS, 10섹션)
- `.harness/decisions/ADR-000-bootstrap.md` (자동)

## Exit 기준

- [ ] `.harness/config.toml` 완성 (strictness 모드 결정됨)
- [ ] `.harness/docs/intake.md`의 모든 핵심 결정 답변됨 (또는 명시적으로 *Blueprint에서 결정*으로 deferred)
- [ ] 테스트 환경 약속 1줄 이상 명시 (모호한 "테스트 잘 해라" 불충분)
- [ ] STATUS의 *Active gate*가 "01 Blueprint" 가리킴
- [ ] **strict / balanced 모드: 사용자 승인** (intake 결과 + project-type 선택)
- [ ] **autonomous 모드**: skip 가능. 단 명시적 user-given autonomy가 ADR로 기록되어 있어야 함

## 주도 역할

- **claude-implementer** — 대화 진행, checklist 작성, 산출물 생성
- **user** — 핵심 결정 / 제약 / 승인 (strict/balanced)

## 발생 가능한 드리프트 / 위험

- ❌ project-type을 너무 일찍 _generic으로 떨어뜨림 → 도메인 특화 체크리스트 누락 → 향후 Blueprint에서 재발견 (드리프트 신호)
- ❌ "테스트 환경"을 "나중에 결정" 처리 → Phase 03/04에서 디버깅 인프라 없어 임시방편 발생
- ❌ 사용자 승인 없이 Blueprint로 점프 (HC-4 위반)

## 다음 phase

[01-blueprint.md](01-blueprint.md) — intake 결과를 바탕으로 모듈 경계와 의존성을 정의.
