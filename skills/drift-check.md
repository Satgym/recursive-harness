# Skill: drift-check

## Purpose

HC-3 자가점검: "지금 하고 있는 작업이 Blueprint / Plan과 일치하나?" 드리프트 발견 시 즉시 HARNESS §6.2 절차로.

## When to invoke

- Phase 경계 (한 phase 끝 → 다음 phase 진입 직전)
- 새 세션 시작 시 ([skills/resume-session.md](resume-session.md) 안에서)
- 의심 신호 발생 시:
  - Blueprint에 없는 모듈을 새로 만들고 있음
  - 사용자가 같은 지적을 두 번 함
  - Codex가 같은 종류 결함을 두 번 잡음
  - STATUS와 실제 디렉토리 상태 불일치
  - commit history와 Roadmap 진행이 어긋남

## Inputs

- 현재 작업 컨텍스트
- HARNESS.md (특히 §6.1 드리프트 신호 목록)
- STATUS.md (현재 Active gate)
- Blueprint, 진행 중 Module Plan
- git status, git log

## Procedure

1. **§6.1 신호 체크리스트** (HARNESS):
   - [ ] 현재 작업이 Blueprint §3 Modules에 매핑되는가?
   - [ ] 현재 phase의 정식 Exit 기준(phases/<phase>.md)을 만족하는 경로인가?
   - [ ] HC-1 (Plan-First) 위반 가능성? (코드를 plan 없이 작성)
   - [ ] HC-3 (Drift-Aware) 자가점검을 이번 세션에 했나?
   - [ ] STATUS *Active gate*와 실제 작업이 일치하는가?
   - [ ] git log의 최근 commit이 Roadmap 진행과 일치하는가?
   - [ ] Codex review가 같은 종류 결함을 2회 이상 잡았는가?
   - [ ] 사용자가 같은 지적을 2회 이상 했는가?
2. **물리적 일치 점검**:
   - `ls`로 디렉토리 구조 ↔ HARNESS.md §4의 표준 위치
   - `git log --oneline` ↔ STATUS Roadmap
   - `git status` ↔ STATUS Current "Git" 행
   - INBOX `ls` ↔ STATUS *INBOX* 카운트
3. **드리프트 발견 시** (HARNESS §6.2):
   1. 현재 작업 *일시 정지* (실수로 커밋하지 말 것)
   2. STATUS *Notes*에 드리프트 사실 + 감지 신호 기록
   3. STATUS *Open findings*에 새 finding (severity 추정 — drift 자체는 보통 major)
   4. [skills/harness-amend.md](harness-amend.md) 트리거 가능성 평가
   5. 사용자에게 escalation (드리프트는 일반적으로 사용자 결정이 필요)
4. **드리프트 없음**:
   - STATUS *Notes*에 짧게 기록: "drift-check passed @ <timestamp> by claude"
   - 작업 재개

## Outputs / Side effects

- STATUS *Notes* 갱신 (passed 또는 detected)
- (드리프트 발견 시) 새 Open finding 추가
- (드리프트 발견 시) 일시 작업 정지

## Failure modes

- **drift-check 자체를 건너뛰고 작업 진행** → 누적 시 broken handoff / failed review loop의 원인. HC-3 위반.
- **신호 모호 — drift인지 정상 변화인지 판단 어려움** → 사용자에게 직접 질문. 추측 금지.
- **drift 발견 후 무시** → escaped blocker 후보. Postmortem 트리거.
- **drift 발견을 review finding으로 둔갑** → drift는 *프로세스* 결함이라 별도 카테고리.

## Related

- HARNESS §6 (드리프트 감지·수정 절차)
- HARNESS HC-3 (Drift-Aware)
- [skills/harness-amend.md](harness-amend.md)
- [skills/resume-session.md](resume-session.md)
- HARNESS §6.3 (Postmortem triggers — 반복 드리프트)
