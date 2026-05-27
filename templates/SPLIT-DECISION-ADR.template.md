---
artifact: adr
adr_id: ADR-NNNN
slug: split-decision-<scope-slug>
date: <YYYY-MM-DD>
status: proposed
type: fleet_split_decision
parent_phase: 02-module-plan
parent_scope: <root | child:<name>>
depth_resulting: <1 or 2>
references:
  - HARNESS.md §14
  - .harness/docs/blueprint.md
---

# ADR-NNNN — Split decision (`<scope-slug>`)

**Status**: proposed → accepted (사용자 승인 후)

## Context

- 현재 scope: `<root | child:<name>>` (depth=<n>)
- Blueprint 모듈 수: <count>
- 예상 LOC: <est>
- 횡단 invariant 식별 수: <count> (목록은 §6)
- 모듈 간 결합도: <low | medium | high>
- `skills/estimate-project-scope.md` heuristic 결과: split *recommended* (근거: §3)

## Decision

본 scope를 **N개 child로 split**한다.

| child name | 소유 모듈 | 소유 디렉토리 | 예상 LOC | 인터페이스 lock 파일 |
|---|---|---|---|---|
| <child-a> | M2 | src/<a>/, tests/<a>/ | ~1200 | subtrees/<child-a>/locked-interface.md |
| <child-b> | M3 | src/<b>/, tests/<b>/ | ~900 | subtrees/<child-b>/locked-interface.md |
| ... | ... | ... | ... | ... |

## File ownership matrix (HARNESS §14.2 F4)

| 경로 | 소유자 | 다른 child 권한 |
|---|---|---|
| src/<a>/ | <child-a> | read-only |
| src/<b>/ | <child-b> | read-only |
| src/shared/types.ts | **parent** | read-only |
| .harness/capabilities.md | **parent (frozen)** | read-only |
| .harness/decisions/ | parent | (각 child는 자기 worktree의 .harness/decisions/에만) |

## 횡단 invariant 목록 (변경 불가)

본 invariant는 *모든 child가 동시에 지킨다*. split 후 신규 발견은 §6 escalation.

1. <invariant 1 — 예: F16 collapse: check-neighbor 응답 body는 {eligible:bool}만>
2. <invariant 2>
3. ...

## Codex review 분배 (Fleet F7)

- 각 child가 자기 scope의 Phase 04 codex review 1회 (`scripts/codex-review.sh` from child worktree)
- parent는 merge phase에서 *cross-cutting integration review* 1회 별도 (의무)
- 토큰 예산: child × 1회 + parent integration × 1회

## Consequences

- positive:
  - 병렬 진행으로 wall-time 단축 (예상 N배에 -overhead)
  - 각 child 컨텍스트가 깔끔 (parent context 노이즈 없음)
- negative:
  - 인터페이스 lock 실패 시 escalation 비용
  - merge phase의 통합 부담 (parent 단독 작업)
  - 사용자가 N개 세션을 직접 spawn해야 함 (수동)
- risk:
  - shared 파일 변경 필요 발견 시 → patch candidate 모드 (child가 MERGE-REPORT에 제안만)
  - 횡단 invariant 누락 시 → 전체 stop + parent replan

## Spawn 절차 (사용자 행동)

1. parent가 `skills/spawn-subtree-prompts.md` 실행 완료 — `.harness/subtrees/<child>/{prompt.md,locked-interface.md}` + 각 worktree 준비됨
2. 사용자가 N개 Claude Code 세션 열기
3. 각 세션에 SUBTREE-PROMPT 본문 전달 (`cat .harness/subtrees/<child>/prompt.md` 결과)
4. 각 child가 자기 worktree에서 작업 → 완료 시 MERGE-REPORT.md commit
5. 모든 child 완료 후 parent 세션에 통보 → parent가 Phase 05 merge-collection 실행

## Approval

- **사용자 승인 필수 (모든 모드)** — autonomous도 예외. 이유: 사용자가 직접 N개 세션을 spawn하는 행동을 해야 함
- approver: user
- approved_at: <ISO> (승인 후 기입)
- approval scope: 위 split 구성 + N개 child 인터페이스 lock + 횡단 invariant 목록
