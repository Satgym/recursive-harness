---
artifact: merge_report
version: v0.1
child_name: <kebab-case>
parent_path: <absolute or repo-relative>
split_decision_adr: ADR-NNNN
date_completed: <YYYY-MM-DD>
branch: feat/<child_name>
commit_sha: <full sha>
status: ready_for_merge | blocked | escalation
---

# MERGE-REPORT — `<child_name>` → parent

> 본 파일은 child sub-coordinator가 *parent에게 handoff*하는 최종 보고서.
> parent는 Phase 05 merge-collection에서 본 파일들(N개)을 회수해 통합 review + ADR 결정.

## Status

- **completion status**: <ready_for_merge | blocked | escalation>
- **branch**: `feat/<child_name>` @ `<commit_sha>`
- **lock 준수**: ✓ / ✗ (✗면 §5 escalation)

## 작업 요약

- **소유 모듈 완료**: <list>
- **LOC 변경**: +<additions> / -<deletions>
- **테스트**: <unit count> unit / <integration count> integration / 모두 PASS / lint+typecheck PASS
- **Codex review (자기 scope)**: <review_id>, finding <count> 모두 resolved/deferred

## Public interface (실제 구현된 것 — locked-interface와 대조)

```
<함수 시그니처 / API 엔드포인트 / 타입 등 — locked-interface.md와 완전히 일치해야 함>
```

**Lock 일치 확인**: ✓ / ✗
- ✗면 §5 escalation 사유 명시

## Cross-cutting invariant 준수 (F87 v1.2 — 실제 코드 path 인용 의무)

| invariant | enforce 방식 | 코드 evidence (path:line + 내용) |
|---|---|---|
| <inv 1> | <runtime gate / @invariant-guard marker / unit test> | `src/<child>/index.ts:<line>` — `<actual code snippet>` |
| ... | ... | ... |

> parent의 [`lock-grep-gate`](../../skills/lock-grep-gate.md) skill이 본 evidence를 *실제 코드와 cross-check*. mismatch 시 child re-work.

## File ownership 준수

- 본 child가 *쓴* 파일이 모두 SPLIT-DECISION-ADR-NNNN의 ownership matrix 안에 있는가? ✓ / ✗
- shared 파일 *변경 필요* 발견 시: §4 patch candidate로 제출

## Patch candidates (shared 파일 변경 제안)

본 child는 shared 파일을 변경 *불가*. 변경 *필요* 발견 시 여기에 제안만 기록:

```
파일: <path>
이유: <왜 변경이 필요한가>
제안 변경: <diff or 설명>
대안: <변경 없이 우회 가능한 방법>
```

## Capability candidates (parent capability manifest에 추가 제안)

본 child가 자기 scope에서 발견한 *generalizable* skill/role 후보. parent가 merge phase에서 채택 여부 결정:

```
- candidate_name: <slug>
  type: skill | role
  scope_observed: <어느 child 어느 모듈에서 유용했나>
  promotion_rationale: <왜 base 또는 parent capability로 승격해야 하는가>
  draft_path: <child worktree 내 .harness/skills/<name>.md>
```

## Open findings (parent에 escalate)

| ID | severity | 요약 | child 처리 결과 |
|---|---|---|---|
| F-<child>-1 | <blocker/major/minor> | <text> | resolved / disputed / *needs parent decision* |

## Escalations (parent의 ADR 발행 필요)

(있을 때만)

| 사유 | 상세 | 영향 |
|---|---|---|
| lock 위반 필요 | <어떤 lock을 어떻게 깰 필요> | <child stop 여부> |
| 횡단 invariant 신규 발견 | <invariant> | <영향 받는 다른 child> |
| 결합도 재평가 | <왜 split이 부적합했는지> | <Fleet drift 신호> |

## Conflict decision matrix (F77 — parent merge phase가 회수해서 결정)

> shared file 또는 lock 충돌이 있을 때 *어떤 child의 제안이 우선되는가* 판단 근거.
> 본 child가 *자기 측 정보만* 채움; parent는 N개 child의 matrix를 종합 후 결정 + ADR.

| 충돌 항목 | 본 child 입장 | lock conformance | invariant impact | test evidence | rejected alternatives | ADR 필요 여부 |
|---|---|---|---|---|---|---|
| <shared 파일 / interface 항목> | <본 child가 원하는 변경 또는 유지> | <locked-interface와 정합> | <어떤 invariant에 영향> | <어떤 test가 본 입장 지지> | <고려했으나 거부한 대안> | <yes/no — major 이상이면 §11 user escalation> |

(충돌 없으면 본 표는 비워 두고 "no conflicts" 명시)

## Handoff checklist

- [ ] 자기 scope codex review 완료 + 모든 finding resolved/deferred
- [ ] MERGE-REPORT.md 작성 + commit
- [ ] STATUS.md (subtree) 최종 갱신
- [ ] lock 준수 확인
- [ ] parent에 완료 통보 (수동: 본 파일 경로 + commit sha 전달)
