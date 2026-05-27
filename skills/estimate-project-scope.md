---
artifact: base_skill
version: v0.1
date: 2026-05-27
author: claude
status: proposed
references:
  - HARNESS.md §14 Fleet Mode
  - HARNESS.md §14.3 split-decision heuristic
---

# Base Skill: `estimate-project-scope`

> Phase 02에서 root coordinator가 *Fleet Mode 진입 여부*를 판단하는 결정 절차.
> 출력: `no-split` (단일 coordinator 진행) 또는 `split` (SPLIT-DECISION-ADR 작성 필요).

## When to invoke

Phase 02 module-plan의 *마지막 module plan을 완료한 직후*. Phase 03 진입 직전.

## Inputs

- `.harness/docs/blueprint.md` (approved)
- 모든 `.harness/docs/modules/*/plan.md` (approved)
- Blueprint §4 Dependency graph
- Blueprint *횡단 invariant 목록* (§14.2 F2)

## Procedure

### Step 1 — 객관 신호 수집

| 지표 | 측정 방법 | 결과 |
|---|---|---|
| 모듈 수 | `ls .harness/docs/modules/` | <n> |
| 예상 총 LOC | 모든 module plan §6 Implementation notes의 LOC estimate 합 | <est> |
| 순환 의존 | Blueprint dependency graph 분석 | <count> |
| 횡단 invariant 수 | Blueprint 또는 별도 invariant 섹션 카운트 | <count> |
| 모듈 간 shared 인터페이스 (types/DB/config) | grep across module plans | <count> |
| 도메인 동질성 | 모든 모듈이 동일 언어·런타임? | <yes/no> |

### Step 2 — Heuristic 적용 (HARNESS §14.3 표)

```
if 모듈 수 ≤ 3:                                  → no-split (오버헤드 손해)
elif 순환 의존 ≥ 1:                              → no-split (lock 위험 큼)
elif 횡단 invariant ≥ 4 AND 모듈 수 < 6:         → no-split (lock 부담 > 병렬 이득)
elif 예상 LOC < 1500:                            → no-split (작은 프로젝트)
elif 모듈 수 4~7 AND 결합도 낮음:                → split (root + N leaves, depth=1)
elif 모듈 수 ≥ 8:                                → split (leaf가 또 split 가능, depth=2 권장)
else:                                            → 명시적 판단 필요 (coordinator 직접 결정 + ADR rationale)
```

### Step 3 — 정성 점검 (heuristic을 항상 override 가능)

다음 중 하나라도 yes면 **no-split 강제**:
- 인터페이스가 *implementation 도중에 자주 바뀔 것 같다* (prototype/POC 성격)
- 모듈 간 *공유 도메인 모델*이 크다 (예: starpin의 catalog_id가 모든 모듈 관통)
- 같은 *외부 의존성*을 N개 모듈이 동시 호출 (mock vs real boundary 정책이 모듈마다 동일)

다음 중 하나라도 yes면 **split 강제 권장** (heuristic이 no-split이어도):
- 모듈이 *전혀 다른 언어/런타임*으로 분리 (예: Python ingest + Node backend + Swift mobile)
- 사용자가 다중 개발자 시뮬레이션을 의도 (실 팀 분배 학습 목적)

### Step 4 — 출력 결정

```yaml
decision: no-split | split
rationale:
  signals: <Step 1 표 요약>
  heuristic_result: <Step 2 적용 결과>
  qualitative_override: <Step 3 적용 결과>
final: <decision>
suggested_split_layout:    # split일 때만
  - child_name: <slug>
    own_modules: [M2]
    own_paths: [src/<a>/, tests/<a>/]
    est_loc: 1200
    depends_on_lock: [shared/types.ts, shared/db-schema.sql]
  - child_name: <slug>
    own_modules: [M3, M4]
    ...
crosscutting_invariants:    # split일 때만 — Fleet F2 의무
  - <invariant 1>
  - <invariant 2>
estimated_walltime_savings: <ratio — 단일 직렬 대비 병렬 단축 비율 estimate>
```

### Step 5 — 후속 액션

- **no-split**: 본 결정을 STATUS Notes에 1줄 기록. Phase 03 진입.
- **split**: `templates/SPLIT-DECISION-ADR.template.md` 인스턴스화 → `.harness/decisions/ADR-NNNN-split-decision-<slug>.md` → 사용자 승인 게이트 (HC-8/9와 별개로 항상 사용자 승인 필수) → 승인 후 [skills/spawn-subtree-prompts.md](spawn-subtree-prompts.md) 호출.

## Anti-patterns

- **무조건 split** — 작은 프로젝트(<1500 LOC)는 단일 세션이 빠름. coordination overhead가 병렬 이득보다 큼.
- **무조건 no-split** — 4+ 독립 모듈을 단일 세션이 직렬 처리하면 wall-time 손해. autonomous에서 사용자 답답함.
- **인터페이스 안 확정한 채 split** — Phase 02 미완 상태에서 split 시도 → child가 lock 받지 못함 → 즉시 escalation 폭주.
- **횡단 invariant 식별 누락** — Blueprint §X에 cross-cutting 항목 없는데 split하면 child가 invariant 자체를 모름 → 깨진 채 merge.

## Output goes to

- `.harness/decisions/ADR-NNNN-split-decision-<slug>.md` (split일 때)
- STATUS.md Next action 갱신
- (split 시) `.harness/subtrees/<child>/` 디렉토리 준비 (spawn-subtree-prompts skill이 채움)
