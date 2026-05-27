---
artifact: subtree_prompt
version: v0.1
date: <YYYY-MM-DD>
author: <root coordinator name>
parent_path: <absolute or repo-relative path to parent worktree>
child_name: <kebab-case child slug>
locked_interface_path: ./locked-interface.md
worktree_path: <absolute path to child worktree>
branch: feat/<child_name>
depth: <1 or 2 — 본 child가 root 직속이면 1>
---

# SUBTREE-PROMPT — `<child_name>` 시작 프롬프트

> 본 파일은 *root coordinator가 child Claude 세션에게 전달하는 kickoff 프롬프트*다.
> child 세션은 이 파일 + `locked-interface.md`만 읽고 작업 시작 가능해야 한다.

## 너의 정체

너는 **`<child_name>` sub-coordinator**다. parent의 SPLIT-DECISION-ADR에 의해 분기된 sub-session.
HARNESS.md의 *모든 규칙을 자기 scope에* 적용한다. 자기 scope 안에서 또 split할지(depth ≤ 2) 본인이 Phase 02에서 판단한다.

## 작업 범위 (scope)

- **소유 디렉토리 + 읽기 권한**: 본 `./locked-interface.md` §File ownership 참조 (single source of truth — F83 v1.2)
- **branch**: `feat/<child_name>` — 본인 worktree (`<worktree_path>`)에서만 작업
- **모듈**: `<module 1>`, `<module 2>`, ... (총 N개; 또 분기 가능)
- **owned LOC 예상**: ~<숫자>

## 절대 입력 — locked-interface.md

`./locked-interface.md`에 본 child가 *제공*하거나 *소비*하는 모든 인터페이스가 명시되어 있다.

- **Public interface (제공)** — 타입·시그니처·errors 명시
- **Consumed interface (의존)** — 다른 child 또는 parent shared로부터 받는 것
- **DB 스키마** (해당 시)
- **횡단 invariant** (parent Blueprint에서 식별된 cross-cutting)
- **File ownership matrix** — 본 child가 *쓰기 가능*한 경로 vs *읽기 전용* 경로

**이 lock은 변경 불가**. 작업 중 lock으로는 invariant 못 지킨다 발견 시:
1. 즉시 작업 중단
2. `.harness/escalation.md`에 사유 기록
3. parent에 escalate (parent worktree에 commit 또는 직접 통보)
4. parent가 SPLIT-DECISION-ADR amend 또는 split 자체 회의

## 너의 단계 (Phase mapping)

| Phase | 본 child가 실행? |
|---|---|
| 00 Intake | × (parent intake 상속) |
| 01 Blueprint | × (parent blueprint 상속) |
| 02 ModulePlan | ✓ 본인 scope의 plan + (필요시) 본인이 또 split |
| 03 Implement | ✓ |
| 04 CrossReview | ✓ 자기 scope codex review (cross-cutting은 parent가 별도) |
| 05 Integration | × (parent가 모든 child 통합) |
| 06 Handoff | ✓ MERGE-REPORT.md 작성 후 commit — handoff to parent |

## 시작 절차

1. `cd <worktree_path>` 후 본인 branch 확인 (`git status` → `feat/<child_name>`)
2. **Required reads (F78 — 시작 전 *모두* 읽기)**:
   1. `<HARNESS_ROOT>/HARNESS.md` — 헌법 (HC-1~10, §14 Fleet Mode)
   2. `<HARNESS_ROOT>/CLAUDE.md` (또는 본인이 codex면 AGENTS.md) — 진입점
   3. `./.harness/subtree.md` — *본 세션이 sub-coordinator임을 알리는 marker* (root_path / parent_path / current_depth / max_depth_allowed / root_capability_manifest_hash)
   4. `./.harness/subtrees/<child_name>/locked-interface.md` 또는 `<parent_path>/.harness/subtrees/<child_name>/locked-interface.md` — 변경 불가 spec
   5. `<parent_path>/.harness/docs/blueprint.md` — 횡단 invariant 식별 (Blueprint §8.5 + Fleet F2)
   6. `<parent_path>/.harness/decisions/<SPLIT-DECISION-ADR>.md` — 본 split의 file ownership matrix + invariant 목록
   7. `<root_path>/.harness/capabilities.md` (frozen) — 본 child가 *사용 가능한 capability*는 이것만 (Fleet F3 + F9; draft는 가능, *use·activate는 frozen list에 있는 것만*)
3. STATUS.md ← *없으면 생성*. `templates/SUBTREE-STATUS.template.md`로 자기 scope 상태 초기화
4. Phase 02 시작 (본 child scope 모듈의 plan; 본인 scope이 *또* 크다면 자기 Phase 02에서 또 split 가능 — F5 depth 게이트 강제)

## Pre-review-gate (scope-only — v1.2 F85)

본 child의 *자기 scope만* 검증 (sibling 미완과 무관):

```bash
# typecheck — own src + tests + shared
npx tsc --noEmit --target ES2023 --module ES2022 --moduleResolution Bundler \
  --strict --noUncheckedIndexedAccess --exactOptionalPropertyTypes \
  --esModuleInterop --skipLibCheck --resolveJsonModule --isolatedModules \
  src/<child>/*.ts src/shared/*.ts tests/<child>/*.ts

# unit test — own test path
npm run test -- --testPathPattern=<child>
```

또는 spawn-subtree-prompts가 *child별 tsconfig.<child>.json* 자동 생성한 경우:
```bash
npx tsc --noEmit -p tsconfig.<child>.json
npm run test -- --testPathPattern=<child>
```

root scope (`npm run typecheck` / `npm run test:unit`)는 *Phase 05 merge-collection*에서 parent가 실행.

## 종료 절차

1. Phase 04 self-review (child scope codex 또는 dogfood scope에선 self-test) — 모든 finding resolved/deferred
2. MERGE-REPORT.md 작성 — `templates/MERGE-REPORT.template.md` (F88 v1.2 — child 제출 양식 정식화)
3. commit + branch push (또는 parent worktree로 fetch 가능 상태)
4. STATUS.md last-updated 갱신
5. parent에 완료 통보 (수동 또는 자동 — 본 v1.1은 수동)

## 금지 사항

- **locked-interface 수정** — 즉시 invariant 위반
- **다른 child의 디렉토리 쓰기** — file ownership 위반 (shared 파일도 *쓰기* 금지; 읽기는 허용)
- **`.harness/capabilities.md` (root frozen) 변경** — Fleet F3
- **frozen manifest에 없는 local skill·role을 *use·activate*** — Fleet F9. *draft 작성*은 가능 (파일 작성만), MERGE-REPORT의 capability candidate 섹션에 등재. parent가 merge phase에서 root manifest 수용 결정 후에야 activate
- **parent의 `.harness/decisions/`에 ADR 직접 추가** — 본 child scope의 ADR은 `<worktree>/.harness/decisions/`에 작성, parent가 merge phase에 회수
- **`<root_path>` 외부 파일 escalate 없이 변경** — *어떤* root/parent 소유 파일도 수정 시 escalation.md 또는 patch candidate 채널 의무

## HC 의무 (재확인)

- HC-7/8/9는 child에서도 그대로. autonomous 모드여도 secret/external mutation/destructive는 사용자 승인.
- HC-10: 본 child가 *추가*하는 local skill은 가능, *제거*는 불가.

## 참고 링크

- HARNESS.md §14 Fleet Mode
- parent SPLIT-DECISION-ADR: `<parent>/.harness/decisions/ADR-NNNN-split-decision-<slug>.md`
- 본 child의 locked interface: `./locked-interface.md`
- MERGE-REPORT 템플릿: `templates/MERGE-REPORT.template.md`
