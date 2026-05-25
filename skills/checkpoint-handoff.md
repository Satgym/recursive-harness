# Skill: checkpoint-handoff

## Purpose

[phases/06-handoff.md](../phases/06-handoff.md)를 실행하여 STATUS를 *stranger-proof*로 갱신하고 INBOX를 정리한 뒤 git commit. 세션 / 모듈 / phase 종료 시 항상 수행.

## When to invoke

- 세션 종료 직전 (사용자가 "끝낸다" 또는 명시적 handoff 요청)
- 모듈 완성 시 (Phase 05 Integration 통과 후 다음 모듈로 가기 전)
- Phase 전환 직전 (예: Phase 04 → 05, Phase 05 → 06 자체)
- HC-6 의무 — 매 작업 종료 시

## Inputs

- 직전 phase의 산출물
- 누적된 INBOX unread (`ls INBOX/`로 확인)
- 미해결 finding (STATUS Open findings + 진행 중 review 파일)
- git status (dirty / clean)

## Procedure

1. **STATUS *Current* 갱신**:
   - Last updated (ISO timestamp + `by claude`)
   - Active sub-phase / Harness version / Git HEAD (현재 HEAD sha)
2. **STATUS *Active gate***:
   - 현재 게이트 → 다음 게이트 명확히
   - Blocked on (누가 / 무엇을)
   - Approval needed (yes / no / 조건)
3. **STATUS *Required reads***:
   - 다음 세션이 시작할 때 읽어야 할 파일 목록 (현재 phase의 plan, 최근 review, INBOX 항목 포함)
4. **STATUS *Approved artifacts***:
   - 본 라운드 산출물을 6필드(artifact / version_or_hash / approver / mode / approved_at / scope) 모두로 등재
5. **STATUS *Decision summary*** 갱신 (새 ADR 발행한 경우만)
6. **STATUS *Roadmap*** 체크박스:
   - 완료된 sub-phase `[x]`
   - 다음 sub-phase에 ← **다음** 표시
7. **STATUS *Next action***:
   - 사용자: 무엇을
   - Claude: 무엇을
   - Codex: 무엇을 (또는 대기)
8. **STATUS *Open findings***:
   - 처리된 항목 상태 갱신
   - carry-over는 그대로 두되 출처 명시
9. **INBOX 정리**:
   - 모든 unread 파일을 `resolved` / `disputed` / `deferred` + `deferred_reason` 중 하나로 status 결정
   - 처리 완료된 파일 `INBOX/processed/`로 이동:
     ```bash
     git mv INBOX/codex-feedback-*.md INBOX/processed/   # tracked인 경우
     mv INBOX/codex-feedback-*.md INBOX/processed/       # untracked인 경우
     ```
   - STATUS *INBOX* 카운트 갱신 (unread 정의: `INBOX/codex-feedback-*.md` with `status: open`)
10. **STATUS *Notes*** 갱신:
    - Cumulative Codex tokens
    - 재리뷰 횟수
    - 알려진 한계 / 후속 ADR 후보
11. **git commit** (HARNESS §12.3 양식):
    ```bash
    git add -A
    git commit -m "$(cat <<EOF
    <type>(<scope>): <subject>

    <body>

    Refs: <files / ADR ids>
    Co-Authored-By: ...
    EOF
    )"
    ```
12. **Stranger-proof 자기점검**:
    - 다음 세션이 STATUS.md만 보고 다음 action을 명확히 알 수 있는가?
    - Required reads로 충분한가?
    - 안 된다면 STATUS 보강 후 step 11 다시 (amend가 아니라 새 commit).

## Outputs / Side effects

- 갱신된 STATUS.md
- 정리된 INBOX (unread 0 또는 명시 carry-over)
- 새 git commit (메시지 §12.3 양식 준수)
- Phase E dogfood 기준의 "STATUS stranger-proof 유지" 항목에 기여

## Failure modes

- **STATUS 일부 섹션 누락** → HARNESS §7 양식 위반. 즉시 보강.
- **INBOX unread 남은 채 commit** → 다음 세션이 처리 의무를 떠안음 (broken handoff 후보).
- **commit message 양식 위반** → §12.3 위반. amend 대신 다음 commit으로 fix (HC-9: amend는 사용자 승인).
- **dirty worktree + commit 빼먹기** → 다음 세션이 의도된 dirty인지 의도되지 않은 잔여물인지 못 구별. STATUS Notes에 명시 또는 commit.

## Related

- [phases/06-handoff.md](../phases/06-handoff.md)
- [templates/STATUS.template.md](../templates/STATUS.template.md)
- HARNESS §7 (STATUS 10섹션 양식), §12 (git policy)
- HC-6 (Status-Updated)
