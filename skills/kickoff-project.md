# Skill: kickoff-project

## Purpose

새 프로젝트를 하니스 관리 하에 부트스트랩. [phases/00-intake.md](../phases/00-intake.md)의 모든 산출물을 생성하고 Phase 01 Blueprint로 인계.

## When to invoke

- 사용자가 새 프로젝트를 시작하겠다고 명시 (예: "새 프로젝트 시작해줘, 웹 서비스")
- `.harness/` 디렉토리가 아직 없는 빈 디렉토리 또는 기존 코드베이스 위

## Inputs

- 사용자가 가져온 프로젝트 아이디어 / 요구사항 / 제약
- 사용 가능한 자원 (인력 / 시간 / 예산 / 모델)
- HARNESS_ROOT 환경변수 또는 본 하니스 repo 위치
- (선택) 프로젝트 타입 힌트 (사용자가 직접 지정 또는 대화로 추정)

## Procedure

1. **대화로 nature 파악**:
   - "한 문장으로 무엇을 만드는가?"
   - "누구를 위한 것인가?"
   - "절대 안 되는 것은? (non-goals)"
   - "테스트·검증을 어떻게 할 것인가?" (스크린샷 / 콘솔 / HIL / 평가셋 등)
2. **project-type 선택**:
   - `ls "$HARNESS_ROOT/project-types/"`로 후보 확인
   - 가장 가까운 매칭, 없으면 `_generic`
   - 사용자에게 확정 받기
3. **부트스트랩 실행**:
   ```bash
   "$HARNESS_ROOT/scripts/new-project.sh" "<project-name>" "<project-type>"
   ```
   이 결과: `.harness/{config.toml, VERSION-PIN, status.md, docs/, reviews/, decisions/, postmortems/, prompts/}`, `.harness/decisions/ADR-000-bootstrap.md`
4. **config.toml 채움**:
   - `[models]` review / exec에 사용자의 실제 모델 ID
   - `[reasoning]` review / exec effort (기본 high / medium)
   - `[strictness] mode` (디폴트 strict — 사용자가 명시적으로 balanced/autonomous 원하면 변경)
5. **intake-checklist 작성**:
   - `cp "$HARNESS_ROOT/project-types/$TYPE/intake-checklist.md" .harness/docs/intake.md` (있다면)
   - 또는 generic intake (project-type별 도메인 결정 + 테스트 환경 약속 + 핵심 제약)
6. **초기 STATUS 작성**:
   - `.harness/status.md`를 HARNESS.md §7 양식대로 채움 (10섹션)
   - Active gate = "00 Intake → 01 Blueprint"
   - ADR-000-bootstrap의 Approval timestamp 채움 (사용자 확인 후)
7. **git init** (선택 — 사용자 확인 후):
   ```bash
   git init -b "$(yq '.git.base_branch // "main"' .harness/config.toml)"
   git add -A && git commit -m "harness(kickoff): bootstrap <name>"
   ```
8. **사용자 승인**:
   - intake 결과 + project-type 선택을 사용자가 검토
   - 승인 후 STATUS.md *Approved artifacts*에 intake.md 등재

## Outputs / Side effects

- `.harness/` 디렉토리 완비
- `STATUS.md` *Active gate*가 "01 Blueprint" 가리킴
- (선택) git 초기 commit
- 사용자 승인 기록 (STATUS Approved artifacts)

## Failure modes

- **`.harness/` 이미 존재** → `new-project.sh`가 HC-9에 따라 abort. 사용자에게 의도 확인 (덮어쓰기는 명시적 허락 + 별도 ADR 필요).
- **project-type 매칭 없음 + 사용자도 모호** → `_generic`으로 시작하고 추후 도메인 깊어지면 새 project-type을 만드는 작업을 별도 ADR로 트리거.
- **테스트 환경 약속 누락** → 부트스트랩 중단. Phase 01 Blueprint에서 발견되면 메타 부트스트랩 비용 증가. 항상 step 1에서 명시.

## Related

- [phases/00-intake.md](../phases/00-intake.md)
- [scripts/new-project.sh](../scripts/new-project.sh)
- [templates/STATUS.template.md](../templates/STATUS.template.md)
- ADR-005 (project-type 우선순위)
