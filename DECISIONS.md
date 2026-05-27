# DECISIONS — Architecture Decision Records

> 새 ADR은 **위에** 추가. 기존 ADR을 뒤집을 땐 새 ADR을 쓰고 기존을 `Status: superseded by ADR-NNN`으로 변경.
> 파일이 100개 이상으로 늘면 `decisions/ADR-NNNN-*.md`로 분리.
>
> **ADR ID 규칙**: 정수 단조 증가 (`ADR-001`, `ADR-002`, ...). 알파벳 suffix(`ADR-003a`) 금지 — 수정/보완도 항상 새 정수 번호로.
>
> **ADR 양식** (필수 필드):
> - **Date**: YYYY-MM-DD
> - **Status**: `proposed | accepted | superseded | rejected`
> - **Supersedes**: 이 ADR이 대체하는 이전 ADR 번호 (없으면 생략)
> - **Superseded by**: 이 ADR이 나중에 대체된 경우 후속 ADR 번호 (없으면 생략)
> - **Amends**: 이 ADR이 부분 수정·보완하는 ADR 번호 (없으면 생략)
> - **Context**: 결정 배경, 문제 상황
> - **Decision**: 무엇을 결정했는가
> - **Consequences**: 영향, trade-off, 후속 작업
> - **Approval**: `approver` / `approved_at` (사용자 승인 받은 경우)

---

## ADR-011 — Hara v1.2 Fleet enforcement 강화 (starpin-fleet real-world dogfood trigger)

**Date**: 2026-05-27 · **Status**: accepted
**References**:
- HARNESS.md §14.8 (lock & invariant enforcement) + §14.9 (inter-child consume timing) + §14.10 (scope-bounded gates) 신설
- skills/lock-grep-gate.md (신설 v0.1)
- skills/spawn-subtree-prompts.md (preflight: inter_child_consume_strategy 의무)
- templates/SUBTREE-PROMPT (Pre-review-gate scope-only section 신설; ownership SoT 참조로 일원화)
- templates/MERGE-REPORT (INV evidence 코드 path 인용 의무)
- templates/SPLIT-DECISION-ADR (inter_child_consume_strategy field + root_path/current_depth/resulting_depth/max_depth_allowed field 의무)
- templates/LOCKED-INTERFACE.template.md (신설 — runtime/type-only import 구분 + 행동 spec + defensive validation policy 의무)
- examples/starpin-fleet/ v0.1.0 (real-world dogfood evidence + 11 v1.2 findings)
- F80 patch (ADR-001 split-decision 작성 즉시 발견 → HARNESS §14 F6 amend로 흡수)

**Context**: Hara v1.1 ship 후 사용자 지시 (2026-05-27): "이제 다시 알아서 진행해 ... 백그라운드 세션 부르는 방식으로 테스트 및 하니스 개선". starpin Blueprint 기반 *real-world Fleet dogfood* (starpin-fleet) 진행 — 4 children parallel spawn (Agent run_in_background) + inter-child consume (sky→catalog, claim→auth) + 4 cross-cutting invariants.

결과: Fleet pattern mechanically 작동 (45 tests PASS, lock 4/4, invariant 4/4, boundary 0 violation). **그러나** real-world에서 11 unique v1.2 finding 도출 — 모두 *enforcement gap* (TypeScript typecheck로 막히지 않는 lock 항목들).

**Decision**: Hara v1.2 amend.

### A. HARNESS §14 amendments (3 신규 subsections)

1. **§14.8 Lock & invariant enforcement** (F87/F90/F82 patch)
   - Single-method consume: locked-interface에 *runtime import vs type-only* 구분 의무
   - Invariant-guard import 검증: (a) runtime gate wrapper redesign 또는 (b) `// @invariant-guard: <util>` 표준 marker
   - MERGE-REPORT INV evidence는 *실제 코드 path 인용* 의무 (false evidence는 child re-work)
   - parent의 `lock-grep-gate` skill이 자동 검증

2. **§14.9 Inter-child consume timing** (F81 patch)
   - SPLIT-DECISION-ADR에 `inter_child_consume_strategy: a|b|c` field 의무
   - (a) lock-spec stub: parent가 provider stub 미리 작성
   - (b) type-only ambient: consumer가 ambient declaration 자체 작성
   - (c) topological spawn order: spawn skill이 provider 후 consumer dispatch
   - spawn preflight가 strategy field 검증

3. **§14.10 Scope-bounded pre-review-gate** (F85 patch)
   - spawn-subtree-prompts skill이 SUBTREE-PROMPT 생성 시 *child별 scope-only* typecheck/test 명령 자동 주입
   - Fleet F4 (ownership) 옆에 *gate scope rule* 신설 — child gate = files it owns + shared transitive imports

### B. 신규 base skill

- `skills/lock-grep-gate.md` v0.1 — parent Phase 05 merge-collection에서 자동 호출. consume allowlist + invariant util 호출 + INV evidence cross-check

### C. 신규 base template

- `templates/LOCKED-INTERFACE.template.md` — 그동안 *예제로만 존재*, 정식 template 신설. runtime/type-only import 명시 / 행동 spec / file ownership SoT / defensive validation policy 의무

### D. Template amendments

- `SUBTREE-PROMPT.template.md`: 작업 범위 섹션은 locked-interface §File ownership *참조*만 (F83 SoT). Pre-review-gate scope-only 섹션 신설 (F85). 종료 절차에서 MERGE-REPORT 양식 명시 (F88).
- `MERGE-REPORT.template.md`: 횡단 invariant 섹션에 *실제 코드 path 인용 의무* (F87)
- `SPLIT-DECISION-ADR.template.md`: front-matter에 `root_path/current_depth/resulting_depth/max_depth_allowed/inter_child_consume_strategy` field 의무화 (F74 강화 + F81)

### E. F80 patch (이미 적용 — 본 ADR에서 명시)

- HARNESS §14 F6: `approver: user` / `approver: user-delegated` + `delegation_source` / `dogfood_simulation: true` 3 path
- spawn-subtree-prompts preflight: 3 path 검증 + 추가 게이트 (delegated이면 source 비어있지 않음; simulation이면 path가 examples/)
- SPLIT-DECISION-ADR template: 3 path 양식 명시

### F. Carry-over (v1.2 미해결)

- F70-fleet-1: child mid-work escalation 위치 — v1.3 후보
- F70-fleet-2 / F92: real git worktree dogfood — v1.3 후보
- F70-fleet-3: parent codex review 대체 heuristic 명문화 — v1.3 후보
- F86: ESM jest module isolation 표준 패턴 — project-type seed에 가이드 추가 검토

**Consequences** (F106 v1.2 codex down-tone):

- **positive**:
  - lock enforcement에 **automated gap detection layer 추가** (lock-grep-gate skill — *typecheck 수준 아님*, grep first-line + MERGE-REPORT evidence + codex second-line)
  - inter-child consume timing 명세화 — 3 strategy (stub/ambient/topo) 절차 작성, 단 helper script (`gen_stub.py` 등)는 v1.3 후속
  - scope-bounded gates 명세 — spawn skill이 per-child tsconfig/jest config 생성 의무
  - **real-world dogfood가 gap discovery로서 효과적** (11 unique finding) — *simulation에서 못 본 것을 real에서 본다* evidence. **단 본 dogfood는 same-worktree boundary + self-test로 진행** — *진짜 mechanical enforcement* 검증은 real git worktree + AST rule 적용한 v1.3 후속 dogfood에서

- **negative**:
  - HARNESS body가 v1.1 → v1.2에서 ~80줄 추가 (cleanup pass 후에도). 470 → ~550줄. 사용자 지시 "하니스가 길어지면 claude가 규칙을 안 지킴"과 trade-off — v1.2 amendment는 *enforcement 강화*가 본질이라 줄이기 어려움
  - lock-grep-gate skill은 *grep 기반* — false positive/negative 가능 (간접 호출은 못 잡음). ESLint rule이 더 강할 수 있으나 본 v1.2는 grep으로 충분

- **risk**:
  - LOCKED-INTERFACE template은 *신규 양식* — 기존 fleet-mini/starpin-fleet의 locked-interface는 양식 후속 적용 필요 (또는 v1.2 template 적용 strict-only로 가능)
  - inter_child_consume_strategy = (c) topo-order는 *parallel 이득 일부 포기* — heuristic 가이드 부재 (어떤 case에 어떤 strategy?) → v1.3 후보

**Codex review evidence**:
- review file: `.harness/reviews/harness-amend-20260527-v1.2-fleet-enforcement.md` (tokens 97,740)
- verdict: 1 blocker + 5 major + 1 minor; HC-7/8/9 위반 0
- patches applied:
  - **F100 (blocker)**: `approver: user-delegated`는 examples/ 경로만 허용 (production은 `approver: user` 직접 승인 또는 out-of-band confirmation artifact 의무). v1.3 후보 — Slack/email signature 통합
  - **F101 (major)**: spawn skill에 strategy a/b/c별 *실제 절차* 추가 — (a) stub 자동 생성, (b) ambient declaration 생성 + merge phase 제거 검증, (c) topological order *안내* (강제 dispatch는 Claude Code SDK multi-session 의존 — v1.3 후속). helper script들은 v1.3 후속
  - **F102 (major)**: §14.8 + lock-grep-gate "mechanical" → "automated gap detection" language down-tone. AST/ESLint v1.3 carry-over 명시
  - **F103 (major)**: Phase 05 Activities Step 0 + Exit 기준에 lock-grep-gate PASS 명시
  - **F104 (major)**: spawn skill Step 3.5 신설 — per-child tsconfig.<child>.json + jest.config.<child>.mjs 자동 생성 (yq 의존; fallback은 inline)
  - **F105 (major)**: spawn skill Step 3 — LOCKED-INTERFACE template *인스턴스화* + 6 필수 섹션 모두 채움 의무. 누락 시 die
  - **F106 (minor)**: ADR-011 positive consequences "typecheck 수준에 근접" → "automated gap detection layer" 정직한 down-tone
- 후속 codex 재리뷰: 본 patches에 대해 *별도 round 불필요* (mechanical). real-world enforcement 검증은 v1.3 후속 dogfood

**Approval**:
- approver: user
- approved_at: 2026-05-27
- approval scope: §14.8/9/10 신설 + lock-grep-gate skill + LOCKED-INTERFACE template + SUBTREE-PROMPT/MERGE-REPORT/SPLIT-DECISION-ADR template amend + F80 + F100~F106 patches + starpin-fleet v0.1.0 dogfood evidence + Phase 05 lock-grep-gate gate
- 후속: v1.3 후보 (real git worktree dogfood + AST/ESLint lock rule + helper scripts + out-of-band confirmation + wall-time benefit 측정)

---

## ADR-010 — Hara v1.1 Fleet Mode 도입 (재귀 coordinator 패턴, depth ≤ 2)

**Date**: 2026-05-27 · **Status**: accepted
**References**:
- HARNESS.md §14 (신설)
- skills/estimate-project-scope.md (신설 v0.1)
- skills/spawn-subtree-prompts.md (신설 v0.1)
- templates/SUBTREE-PROMPT.template.md / SUBTREE-STATUS.template.md / SPLIT-DECISION-ADR.template.md / MERGE-REPORT.template.md (신설)
- examples/fleet-mini/ (신설 v0.1 dogfood)

**Context**: v1.0 검증 후 사용자가 다음 한계 지적:

1. 큰 프로젝트에서 메인 Claude 세션이 *순차 직렬* — Codex 호출/대기/응답 처리/구현/다시 호출의 반복으로 wall-time 병목
2. 모듈 간 결합도가 낮은 경우 *각 모듈은 독립 진행 가능*하지만 현재 v1.0은 single-session sequential phase만 정식 지원
3. 사용자 제안: **재귀 coordinator** — coordinator가 Phase 02에서 split 여부 판단, split이면 N개 child 세션 spawn, 각 child도 같은 7-phase 루프를 자기 scope에 실행. depth 제한 내에서 leaf가 또 split 가능

**Decision**: HARNESS를 **v1.1**로 amend. Fleet Mode (재귀 coordinator 패턴) 도입.

1. **HARNESS §14 신설** — Fleet Mode 정식 정의 (9 rules + workspace 구조 + phase mapping + drift signals)
2. **Phase 02 amend** — split-decision step 추가 (root coordinator scope의 마지막 plan 직후 의무)
3. **Phase 05 amend** — merge-collection step 추가 (모든 child branch fetch + integration + cross-cutting codex review)
4. **4 templates 추가** — SUBTREE-PROMPT / SUBTREE-STATUS / SPLIT-DECISION-ADR / MERGE-REPORT
5. **2 base skills 추가** — estimate-project-scope (heuristic + 정성 override) / spawn-subtree-prompts (worktree + 산출물 자동 생성)
6. **CLAUDE.md / AGENTS.md amend** — `.harness/subtree.md` marker 인식 + sub-coordinator 진입 모델
7. **재귀 depth ≤ 2 (v1.1)** — root → child → grandchild. 더 깊은 split은 ADR 별도 정당화. v1.2 후보 (precedent 누적 시 완화)
8. **사용자 승인 게이트 (Fleet F6)** — SPLIT-DECISION-ADR는 *모든 모드*에서 사용자 승인 필수. 이유: 사용자가 직접 N개 세션을 spawn하는 외부 행동 필요

**Cleanup pass (v1.1과 동반)**:
- HARNESS.md 헤더 v0.6→v1.0/v0.5→v0.6 transition note 제거 (§8 표로 통합)
- HARNESS.md §9 Bootstrap exception 본문 19줄 → 3줄 archival pointer
- HARNESS.md §8 버전 이력 paragraph → 1줄 표
- HARNESS.md §0/§1 HC-4/§3의 §9 deprecation 순환 참조 제거
- STATUS.md 340줄 → 120줄 (Phase A 과거 history 제거, 현재 v1.1 상태만)
- CLAUDE.md / AGENTS.md "(v0.6 — ...)" version tag noise 제거
- 사용자 지시 (2026-05-27): "하니스가 길어지면 claude가 규칙을 안 지킴 → obsolete 적극 제거"

**Consequences**:

- **positive**:
  - 모듈 ≥4 + 결합도 낮은 프로젝트에서 wall-time 단축 (예상 2~4×)
  - 각 child 컨텍스트가 깔끔 (parent의 다른 모듈 노이즈 없음)
  - 재귀 모델 — coordinator가 root인지 leaf인지 의식 안 함, 자기 scope만 처리
  - 인터페이스 lock + file ownership 명세가 *팀 분배* 시뮬레이션과 같음 → 실무 팀 분배 학습 효과
  - cleanup pass로 HARNESS body 가독성 향상 (long-prompt compliance 개선 기대)

- **negative**:
  - 인터페이스 lock 실패 시 escalation 비용 큼 (parent replan + 다른 child stop)
  - 횡단 invariant 누락이 가장 비싼 case (Blueprint Exit에 invariant 명시 의무 신설로 완화)
  - 사용자 UX 부담: parent가 prompt 작성 → 사용자가 직접 N개 세션 spawn → 결과 회수 통보. 자동화는 v1.2+ 후보
  - merge 시 conflict 부담 parent에 집중 (worktree 분리로 일부 완화)

- **risk**:
  - 첫 v1.1은 `examples/fleet-mini/` 단일 dogfood로만 검증 — real-world domain 검증은 v1.2부터
  - depth ≥ 3 시 coordination overhead가 병렬 이득 잠식 가능 (depth ≤ 2 cap으로 완화)
  - capability manifest freeze 규칙이 *long-running child*에서 답답함 줄 수 있음 (child의 candidate 채널로 완화)

**Codex review evidence**:
- review file: `.harness/reviews/harness-amend-20260527-v1.1-fleet-mode.md` (tokens 84,462)
- verdict: 1 blocker + 6 majors + 1 minor; HC-7/8/9 위반 0
- patches applied:
  - **F71 (blocker)**: fleet-mini를 *mechanical simulation only*로 demote — RELEASE/status/blueprint/ADR-001에 `dogfood_simulation: true` flag + DoD note. 정식 dogfood 격상 절차는 Blueprint §9에 명세
  - **F72**: Phase 01 + BLUEPRINT template §8.5 *Cross-cutting invariants* 섹션 의무 신설
  - **F73**: spawn-subtree-prompts preflight에 `approver: user` 검증 + `dogfood_simulation: true` 명시 예외만 통과
  - **F74**: SPLIT-DECISION-ADR + subtree marker에 `root_path / parent_subtree / current_depth / max_depth_allowed / root_capability_manifest_hash` 의무. spawn preflight가 `resulting_depth > max_depth_allowed` 시 die
  - **F75**: HARNESS §14 F9 명확화 — "child may DRAFT capability files, may not USE/ACTIVATE unless in frozen root manifest"
  - **F76**: Blueprint §8.6 *expected module set canonical list* + `.harness/docs/modules/index.md` 의무. Phase 02 split-decision은 expected == approved 일치 시에만 발동 (spawn preflight 강제)
  - **F77**: MERGE-REPORT에 *conflict decision matrix* 섹션 신설. Phase 05 merge-collection에 matrix 회수 + §11 사용자 escalation 의무 명시
  - **F78**: SUBTREE-PROMPT 시작 절차에 *required reads 7개 고정 list* (HARNESS / CLAUDE 또는 AGENTS / subtree marker / locked-interface / parent Blueprint / split ADR / root frozen capabilities)
- 후속 codex 재리뷰: 본 patch 묶음에 대해 *별도 round* 불필요 (mechanical patch). 다음 *real-world* dogfood에서 검증

**Approval**:
- approver: user
- approved_at: 2026-05-27
- approval scope: HARNESS §14 신설 + Phase 01/02/05 amend + BLUEPRINT template + 4 new templates + 2 new base skills + CLAUDE/AGENTS amend + ADR-010 + examples/fleet-mini *mechanical simulation* + cleanup pass + F71~F78 patches 일괄
- 후속: 다음 real-world Fleet dogfood가 v1.2 amendment 후보 (F70-fleet-1~3 + 미검증 wall-time benefit 측정 + 실 git worktree merge conflict 패턴 검증)

---

## ADR-009 — Hara v1.0 승격 (Phase E §10 5 criteria 충족, starpin v0.1.0 ship evidence)

**Date**: 2026-05-27 · **Status**: accepted
**Supersedes**: HARNESS.md v0.6 (v1.0 promotion)
**References**:
- HARNESS.md §10 (Phase E Dogfood 성공 기준)
- examples/temp-sensor/RELEASE.md (E2 — v0.1.0 ship Phase 06)
- examples/starpin/RELEASE.md (E3 — v0.1.0 ship Phase 06 autonomous)
- examples/starpin/.harness/decisions/ADR-005-mode-change-autonomous.md v1.3
- examples/starpin/.harness/decisions/ADR-006-base-promotion-binary-size-budget.md
- examples/starpin/.harness/decisions/ADR-007-phase-03-04-05-06-autonomous-closure.md
- root DECISIONS.md ADR-008 (base promotion 첫 사례)

**Context**: HARNESS §10 v1.0 승격 5 기준 자가 점검:

| # | 기준 | 충족 evidence |
|---|---|---|
| 1 | 최소 프로젝트 규모 (모듈 ≥3, Blueprint + Module Plan + cross-review ≥1회) | ✓ 3 dogfood (todo-api / temp-sensor / starpin) 모두 충족. starpin = 6 modules + 5 codex round |
| 2 | 필수 산출물 (Blueprint + Module Plans + Reviews + ADRs ≥3 + STATUS stranger-proof + Postmortem resolved) | ✓ starpin = 1 Blueprint + 6 Module Plans + 7 codex review + 7 ADRs (000~007) + 118 unit tests + STATUS 10-section |
| 3 | 결함 캡처 (모든 결함 INBOX/review 등재 + 처리) | ✓ F1~F46 등재 처리; F47/F50~F64 starpin Phase 03~04 자율 closure (M1 r1+r2 모두 patches resolved) |
| 4 | 하니스 임시 변경 한도 (3회 초과 시 재설계 trigger) | ✓ 0회 임시 변경 — F40만 *발견 즉시 fix* (한도 미포함); 모든 dogfood가 *base 강화 path*로만 진화 (ADR-008 first promotion) |
| 5 | stranger-proof (별도 사람/codex 30분 STATUS 파악) | ✓ 새 세션이 STATUS만 읽고 즉시 v0.2 scope 인지 가능 — starpin status.md `Current/Active gate/Required reads/Approved artifacts` 10 section 완전 |

**Decision**: HARNESS를 **v1.0**로 승격.

1. HARNESS.md 본문 version 표기 v0.6 → v1.0 (별도 commit; 본 ADR이 trigger)
2. v1.0 의미: *adaptive-redesign 완료* + *3 domain dogfood ship* + *base promotion procedure 검증* + *autonomous mode self-pace 검증* + *stranger-proof 검증*
3. v1.0 이후:
   - 신규 프로젝트는 *적응형 v1.0 base*로 부트스트랩
   - base 변경은 ADR-008 procedure 따름 (manual promotion → codex review → 사용자 승인)
   - autonomous mode는 ADR-005 v1.3 self-test schema 적용 (race_pattern_check + user_gate_required_check 포함)
4. v1.1 후보 (별도 dogfood로 검증):
   - `synthesize-local-layer` skill 도구화 (현 v0.6 manual)
   - `runtime-frame-budget` 분리 base skill (≥2 precedent 도달 시)
   - `autonomous-self-test` base template (F44 — ≥2 precedent 대기)
   - `auth-rotation-reuse` base 일반화 (todo-api auth 추가 시)

**Consequences**:
- positive:
  - HARNESS가 *3 domain (web/firmware/mobile)에서 검증된 v1.0* — 신규 프로젝트가 *재설계 risk 없이* 적용 가능
  - 적응형 vision (§13)의 *실 작동* 검증 — local layer / base layer 분리가 *실제로* 도메인 mix를 흡수
  - autonomous mode가 *사용자 click 최소화 + 안전 게이트 유지* trade-off에서 작동 가능 (M1 BLOCKER가 codex로 잡힌 evidence — self-test가 우회 대체 아님)
  - HARNESS §13.6 manual promotion procedure가 *살아있음* — `budget-binary-size` 첫 사례
- negative:
  - 본 v1.0은 *3 dogfood = 3 도메인* 검증; AI-pipeline / data-pipeline / IoT-edge 등 미검증 도메인은 *v1.1+ scope*
  - autonomous mode의 *long-running session* (밤동안 자율) 한계 검증은 1회 (starpin); 반복 검증 필요
  - codex review skip (M2~M5 자율 판단)이 *향후 hidden defect* risk; v1.1에 *codex coverage matrix* 추가 후보
- 후속:
  - HARNESS.md 본문 version 표기 v1.0 update (별도 commit)
  - 신규 프로젝트는 `scripts/new-project.sh` 결과 `.harness/VERSION-PIN`에 `v1.0` 기록 → 향후 base upgrade 추적
  - 본 ADR-009가 *v0.6 → v1.0 transition document* — 새 세션이 본 ADR 1개로 v1.0 컨텍스트 파악

**Approval**: user-implicit @ 2026-05-27 (autonomous 자율 위임 안에서 v1.0 승격 — "완전해진 하니스" 메시지가 v1.0 의도와 일치)

---

## ADR-008 — Base skill `budget-binary-size` 합성 (starpin Phase 03 + temp-sensor Phase 06 promotion)

**Date**: 2026-05-27 · **Status**: accepted · **Amends**: skills/ (신규 base skill 추가)
**References**: examples/starpin/.harness/decisions/ADR-006-base-promotion-binary-size-budget.md (starpin-side promotion proposal source)

**Context**: HARNESS §13.6 manual promotion 기준 (≥2 프로젝트 검증) 달성. starpin `mobile-bundle-budget` v0.3 (IPA/APK 50MB) + temp-sensor `budget-flash-ram` v0.2 (64KB flash/20KB SRAM) 두 local skill이 동일 *binary-size budget* 패턴 공유. 본 ADR로 base 합성 정식화.

**Decision**:
1. **신규 base skill 작성**: `/Users/satgym/work/harness/skills/budget-binary-size.md` v0.1 (proposed → accepted).
   - Domain-agnostic framework + Strategy pattern (local skill이 측정 함수 제공)
   - `--phase` arg로 blueprint/module-plan skip + implement/integration strict
   - Standard evidence schema `.harness/runs/binary-size-<stamp>.txt`
2. **HARNESS §13.6 manual promotion procedure 첫 사례** — 본 ADR이 procedural template.
3. **기존 local skills retain unchanged** (v0.6 dogfood scope에서 mechanical refactor는 deferred):
   - temp-sensor `budget-flash-ram` v0.2 (Phase 06 closed; retroactive extends는 future amend)
   - starpin `mobile-bundle-budget` v0.3 (현 dogfood active)
   - 양 local skill이 v+1 amend 시 `extends: skills/budget-binary-size.md` 추가 (별도 round)
4. **anti-bias 검증**: 5 도메인 (firmware/mobile/web/AI-model/desktop) 모두 applicable.

**Consequences**:
- positive: HARNESS §10 Phase E #4 정식 base 진화 첫 evidence + §13.6 procedure 실 작동 + 향후 신규 프로젝트가 binary size budget을 base inherit + `synthesize-local-layer` skill 도메인 별 부담 감소
- negative: base 변경 → 모든 미래 프로젝트가 영향 (HC-10 invariant); fps 같은 runtime budget은 본 추상화 범위 외 (`runtime-frame-budget` 별도 promotion 후보)
- 후속: F44 (ADR-005 v1.2 self-test schema base promotion) 도 ≥2 precedent 도달 시 동일 promotion path 활용 — 본 ADR이 template

**Approval**: user-implicit @ 2026-05-27 (사용자 자율 위임 메시지 "밤동안 알아서 진행해, 너의 결정에 맡길게" — autonomous mode 권한 위임 안에서 base 변경 진행)

---

## ADR-007 — §9 Bootstrap exception 폐기 (Phase A.4 완료)

**Date**: 2026-05-25 · **Status**: accepted · **Amends**: HARNESS.md §9

**Context**: HARNESS.md §9 본문은 "Phase A.4 (`phases/` 정식 문서) 완성 후 자동 폐기"가 명시되어 있다. A.4가 완성되어 `phases/00-intake.md` ~ `phases/06-handoff.md` 7개 + `phases/README.md`가 작성되었으므로 §9 폐기 조건이 만족됐다.

**Decision**: ADR-007 발행 시점부터 HARNESS §9 임시 게이트는 **deprecated**. 모든 phase 진행은 `phases/<phase>.md`의 정식 Exit 기준을 따른다.

§9 본문은 HARNESS micro-patch로 deprecation 헤더가 추가되었으며 (status: deprecated 표시), 향후 HARNESS v0.5 정식판(A.5 통합 cross-review 후)에서 §9 전체가 archival 섹션으로 이동되거나 별도 보관 (역사적 가치 보존).

**Consequences**:
- 이후 모든 sub-phase 진행은 [phases/](phases/)의 Exit 기준에 따름 — 모드별 승인 매트릭스(phases/README.md)가 §9 대체
- 현 진행 Phase A의 잔여 sub-phase(A.5)는 phases/04-cross-review.md의 정식 Exit 기준 적용 — A.5 통합 cross-review가 §9 폐기 후 *첫 정식 cross-review*
- ADR-006(Phase A 동안 codex 리뷰 시점 = A.0a/A.0f/A.5)도 A.5 완료 후 자연 종료 — 그 후엔 모듈마다 phase 04 cross-review가 표준
- v0.5 HARNESS 정식판에서 §9 본문을 archival 섹션 또는 `docs/history/` 같은 별도 위치로 이동 검토 (사용자 결정 사항)

**Approval**: user @ 2026-05-25T13:44, mode=strict

---

## ADR-006 — Phase A sub-phase별 Codex 리뷰 시점

**Date**: 2026-05-25 · **Status**: accepted · **Amends**: — · **Supersedes**: —

**Context**: HARNESS.md §9 (Bootstrap exception) 임시 게이트 Exit #2는 "Codex review를 받음"이라 명시되어 있다. 엄격 해석하면 모든 sub-phase(A.0b/c/d/e/g, A.1, A.2, A.3, A.4)마다 별도 codex 리뷰가 필요하나, 다수가 wording-level 또는 단일 디렉토리 추가 수준의 *증분 변경*이라 매번 리뷰는 토큰 낭비이고 cost guardrail(§5.4)과도 어긋난다.

**Decision**: Phase A 동안의 codex 리뷰는 다음 3시점에만 받는다.
1. **A.0a — seed review**: v0.1 씨앗 6문서 검토 (이미 완료, 12 findings + 7 proposals)
2. **A.0f — v0.3 re-review**: PART A 이전 finding 닫힘 검증 + PART B 신규 §에 대한 새 finding 탐색 (이미 완료, 3 minor findings)
3. **A.5 — Phase A 통합 cross-review**: roles/ + templates/ + scripts/ + phases/ 전체에 대해 마지막 통합 검증, HARNESS v0.5 정식화

그 외 sub-phase(A.0b/c/d/e/g, A.1, A.2, A.3, A.4)는 별도 codex 리뷰 없이 진행. 단 진행 중 의문/위험이 발견되면 즉시 STATUS *Open findings* 또는 `INBOX/`에 기록 → A.5에서 처리.

**Consequences**:
- 비용 효율: 누적 토큰 ~211K (현재) → A.5 단일 라운드로 추가 ~200K 이내 추정 (저렴).
- A.5에서 누적 finding이 많을 가능성 → 처리 라운드(A.5b/c/d 등) 길어질 수 있음. cost guardrail §5.4의 "재리뷰 3회 초과 시 사용자 확인"이 일찍 발동될 수 있음.
- A.2/A.3/A.4 작업 중 발견되는 *작은 의문*은 INBOX 능동 피드백(C 채널) 또는 STATUS Open findings로 항상 보존되어야 누락 방지.
- A.4 완료 시 §9 자동 폐기 → ADR-006도 자연 종료 (정식 phase Exit 기준이 §9를 대체).

**Approval**: user @ 2026-05-25T11:39, mode=strict

---

## ADR-005 — 프로젝트 타입 우선순위

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스는 다양한 프로젝트 타입(web, firmware, ai-model, cli, data-pipeline 등)을 지원해야 한다. 모두 동시에 깊이 만들면 빌드 부담이 크고 dogfood 검증이 어렵다.

**Decision**: `project-types/web-service/`를 가장 깊이 만든다. 나머지 타입은 `project-types/_generic/` 골격만 제공하고, 실제 필요할 때 dogfood로 빌드한다.

**Consequences**:
- 첫 실사용은 웹 프로젝트가 될 가능성이 높음.
- 다른 타입은 일반 페이즈 절차로만 가능(특화 체크리스트 없음).
- 펌웨어/AI 모델 같은 도메인 특화 검증은 그 시점에 별도 ADR + Phase C 확장으로 다룸.

---

## ADR-004 — Strictness 모드 도입

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스가 자율적으로 얼마나 진행할 수 있어야 하는지는 신뢰 수준에 따라 다르다. 초기엔 모든 plan을 사용자가 검토해야 안전하지만, 검증된 후엔 자동화를 늘리고 싶다.

**Decision**: 세 모드 정의 — `strict` / `balanced` / `autonomous`. 프로젝트별 `.harness/config.toml`에서 선택. 디폴트 `strict`. 하니스 자체 변경은 모든 모드에서 항상 사용자 승인.

**Consequences**:
- 각 phase 문서의 Exit 기준에 "어느 모드에서 사용자 승인 필요한지" 명시 필요.
- 하니스 자체 빌드는 strict 모드로 진행.
- 모드 전환 자체가 ADR 대상 (신뢰가 검증되면 사용자가 명시적으로 balanced로 전환).

---

## ADR-003 — Codex 모델/계정은 사용자 설정

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 사용자마다 접근 가능한 codex/openai 모델이 다르다. 사용자는 현재 codex5.3 + gpt-5.5까지 사용 가능하며 추후 업그레이드 예정.

**Decision**: 모델명은 코드/스크립트에 하드코딩 금지. `.harness/config.toml`의 `[models]` 섹션에서 `review`, `exec` 모델을 각각 지정한다. 미설정 시 `codex` CLI 디폴트 사용.

```toml
# .harness/config.toml 예시 (사용자가 채움)
[models]
review = "gpt-5.5"
exec   = "codex5.3"
```

**Consequences**:
- 정확한 모델 식별자는 사용자가 채워야 함 (예: 위 문자열이 codex CLI가 실제로 받는 모델명과 일치해야 함).
- 모델 업그레이드 시 새 정수 ADR을 발행해서 변경 사항을 `Amends: ADR-003` 으로 기록.
- 스크립트는 `-c model="$(yq '.models.review' .harness/config.toml)"` 같은 식으로 주입.

---

## ADR-002 — Codex 개입은 파일 기반 비동기를 기본으로

**Date**: 2026-05-25 · **Status**: accepted

**Context**: VSCode 환경 + Claude가 주 대화 상대. Codex 개입 방식 후보: (A) 파일 기반 비동기 호출 (B) MCP 즉석 호출 (C) 사용자가 별도 codex 세션 운영.

**Decision**: A를 기본 채널로. B는 후순위(설정 복잡·컨텍스트 비용 큼). C는 `AGENTS.md` + `INBOX/` 컨벤션으로 자연스럽게 지원.

**Consequences**:
- 모든 리뷰가 파일로 남아 재현/감사 가능.
- 즉석 협의 필요 시 사용자가 직접 별도 codex 세션을 띄울 수 있고, codex는 `AGENTS.md`로 자기 역할을 자동 인지.
- MCP는 v1.0 이후 옵션으로 검토.

---

## ADR-001 — 하니스는 git repo로 배포, 메타-부트스트랩

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스 배포 방식 후보: (a) 단일 SoT + 심볼릭링크 (b) 프로젝트마다 복사 (c) git repo로 만들어 clone/submodule.

**Decision**: (c) git repo. 프로젝트는 하니스 repo를 reference. 프로젝트별 적응적 규칙/스킬은 하니스 자체를 사용해 만든다 (메타 부트스트랩).

**Consequences**:
- 하니스 자체에 버전 필요 (`VERSION` 파일, Phase A.3에서 생성).
- 프로젝트는 `.harness/VERSION-PIN`으로 사용한 버전 기록.
- 하니스 업그레이드 시 마이그레이션 가이드 필요 (Phase D 항목).
- 이 디렉토리는 결국 GitHub 레포가 될 후보 — 파일 작성 시 그 점을 의식 (라이선스, README, .gitignore 등은 Phase E에서).
