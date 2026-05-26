# Skill: resume-session

## Purpose

새 Claude 세션이 STATUS.md만 읽고 직전 세션의 작업을 이어받기. AGENTS.md / CLAUDE.md의 세션 시작 의무를 실제 절차로 풀어둔 것.

## When to invoke

- 새 세션 시작 시 (사용자가 인사 또는 첫 질문)
- 컨텍스트 압축 후 (대화가 길어 자동 압축이 발생한 경우)
- `/resume` 같은 명시 호출

## Inputs

- 작업 디렉토리의 STATUS.md
- HARNESS.md, DECISIONS.md
- AGENTS.md / CLAUDE.md
- INBOX/ unread (능동 피드백)
- git log (commit 이력)

## Procedure

1. **세션 시작 의무 파일 읽기** (CLAUDE.md / AGENTS.md 명시 순서):
   1. `CLAUDE.md` (또는 codex 세션이면 `AGENTS.md`)
   2. `HARNESS.md` (현재 적용 헌법; STATUS에 pin된 version)
   3. `STATUS.md` (가장 중요 — 단일 진실 출처)
   4. `DECISIONS.md` (ADR 누적)
   5. **`.harness/capabilities.md` (조건부 — v0.6)**:
      - 프로젝트 컨텍스트면(`.harness/` 존재 + bootstrapped): 파일을 읽고 *Active* 섹션의 local skills/roles를 working set에 포함 (HARNESS §13.3)
      - harness self-build에는 capability manifest 없을 수 있음 — `Active local capabilities = none`으로 간주
      - 프로젝트 부트스트랩 후 manifest *부재*는 Phase 00 위반 (synthesize-local-layer 미실행 신호)
   6. (필요 시) Active 섹션에 명시된 모든 local skill / role 파일
2. **INBOX 점검** (위치는 컨텍스트에 따라):
   - **프로젝트 컨텍스트** (`.harness/`가 존재): `ls .harness/inbox/` — unread = `.harness/inbox/codex-feedback-*.md` with `status: open`
   - **하니스 self-build**: `ls INBOX/` — unread = `INBOX/codex-feedback-*.md` with `status: open`
   - 둘 다 `processed/` 하위와 README.md는 제외
   - unread 발견 시 STATUS *Open findings*와 일치하는지 cross-check
3. **STATUS *Current* 파악**:
   - 현재 Phase / Active sub-phase
   - Last updated 시각 + by 누구 (자기 자신인지 다른 에이전트인지)
   - Strictness 모드
   - Git HEAD가 stale 아닌지 (`git log -1 --oneline`과 비교 — F18 학습)
4. **STATUS *Active gate* 파악**:
   - 현재 막힌 게이트
   - Blocked on (사용자 승인 / Codex 응답 / pre-review-gate / 등)
   - Approval needed?
5. **STATUS *Required reads* 읽기**:
   - 그 목록의 모든 파일 읽기 (Blueprint, 현재 Module Plan, 최근 review 등)
6. **STATUS *Next action* 확인**:
   - "사용자 / Claude / Codex" 각각 무엇을 해야 하는지
   - 본인(Claude) 액션이 있다면 어떤 skill을 invoke해야 하는지 식별
7. **drift-check 트리거** (HARNESS HC-3):
   - 마지막 작업 이후 시간 / commit이 충분히 흘렀다면 [skills/drift-check.md](drift-check.md) 실행
   - 또는 STATUS와 실제 상태가 불일치하는 신호가 보이면
8. **사용자에게 1줄 보고**:
   - "현재 Phase X.Y, gate=<...>, next action=<...>. <Skill Z>를 진행하시겠어요?"
9. **작업 진행** — 사용자 확인 후 다음 skill 호출 또는 직접 작업.

## Outputs / Side effects

- 본인(Claude)이 컨텍스트를 완전히 회복
- 사용자에게 1줄 상황 보고
- (필요 시) STATUS *Current* Last updated 갱신 (단순 "읽기"만으론 갱신 불필요)

## Failure modes

- **STATUS 불완전** (§7 양식 위반) → 추측으로 채우지 말 것. 사용자에게 직접 질문 + STATUS 보강을 다음 작업으로.
- **STATUS HEAD ↔ git log 불일치** → drift 신호. drift-check 즉시.
- **INBOX unread가 STATUS 카운트와 다름** → 한쪽이 stale. 실제 파일 우선.
- **Required reads 중 파일 누락** → 누가 지웠는지 git log로 확인 (HC-9 영향 검사) + 복구 또는 STATUS 갱신.

## Related

- [phases/06-handoff.md](../phases/06-handoff.md)
- [skills/drift-check.md](drift-check.md)
- [skills/checkpoint-handoff.md](checkpoint-handoff.md)
- HARNESS §7 (STATUS stranger-proof)
- CLAUDE.md / AGENTS.md (세션 시작 의무)
- F18 (STATUS HEAD stale 학습)
