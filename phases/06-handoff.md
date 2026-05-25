# Phase 06 — Handoff

> 세션 / 모듈 / Phase A 전체의 종료 시 핸드오프 게이트. STATUS가 *stranger-proof* 상태에 도달했음을 보장.

## Entry 입력

- 직전 phase(00~05)의 산출물 + Exit 통과 상태
- 누적된 INBOX unread (있다면)
- 미해결 finding (있다면)

## Activities

1. **STATUS.md 갱신** — HARNESS §7의 10섹션 양식 *전체*를 다시 확인:
   - Current (Last updated, by 누구)
   - Active gate (현재 / 다음 / Blocked on / Approval needed)
   - Required reads (다음 세션이 읽을 목록)
   - Approved artifacts (Approval record 6필드)
   - Decision summary (누적 ADR)
   - Roadmap (체크박스 갱신)
   - Next action (사용자 / Claude / Codex)
   - Open findings (carry-over 명시)
   - INBOX (unread 카운트)
   - Notes (토큰 누적, 알려진 한계)
2. **INBOX 처리**:
   - 모든 unread 파일을 `resolved` / `deferred` (+ `deferred_reason`) / `disputed`로 status 결정
   - 처리 완료된 파일은 `INBOX/processed/`로 이동
3. **Approved artifacts 등재** — 본 라운드 산출물 6필드 (artifact / version_or_hash / approver / mode / approved_at / scope) 모두 채움
4. **git commit** — HARNESS §12.3 메시지 양식:
   ```
   <type>(<scope>): <subject>

   <body>

   Refs: <related files / ADR ids>
   Co-Authored-By: ...
   ```
5. **Stranger-proof 자기점검** — 다음 세션 사람/에이전트가 *이 STATUS.md 만* 읽고 다음 액션을 명확히 알 수 있는지 mental check. 못 한다면 STATUS 보강.

## Outputs

- 갱신된 STATUS.md
- INBOX 정리 결과 (`INBOX/processed/`로 이동된 파일)
- 새 git commit (commit message가 §12.3 양식 준수)

## Exit 기준

- [ ] STATUS의 10섹션 모두 채워짐 (양식 위반 없음)
- [ ] *Active gate*가 다음 단계 명확히 가리킴
- [ ] *Next action*에 누가 / 무엇을 명시
- [ ] *Approved artifacts*에 본 라운드 산출물 등재 (6필드 모두)
- [ ] INBOX unread = 0 또는 carry-over 명시
- [ ] git status가 clean (또는 의도된 dirty 상태가 STATUS Notes에 기록)
- [ ] Stranger-proof 자기점검 통과 (subjective, claude-implementer 판단)

## 주도 역할

- **claude-implementer** 단독 (사용자 / Codex 개입 없음 — 본 phase는 정리·기록·commit 자체)

## 발생 가능한 드리프트 / 위험

- ❌ STATUS 갱신 *생략* → HC-6 위반, 해당 작업 미완료로 간주
- ❌ "다음 action"이 "계속 진행"처럼 모호 → 다음 세션이 path를 못 찾음 → broken handoff 트리거 (Postmortem)
- ❌ INBOX unread를 그대로 두고 다음 phase 진입 → AGENTS.md / CLAUDE.md 의무 위반
- ❌ commit message 양식 위반 → §12.3 위반, 누적되면 grep / 자동화 불가

## 다음 phase

- 다음 모듈이 있다면 → [02-module-plan.md](02-module-plan.md) (M+1 모듈)
- 모든 모듈 완료 → Phase A 종결 (해당 프로젝트는 운영·유지보수 단계)
- 새 요구 발생 → 일부 케이스 [00-intake.md](00-intake.md) 재진입 (Blueprint 수정 동반)
