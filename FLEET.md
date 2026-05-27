# FLEET.md — Fleet Mode (다중 세션 병렬 coordinator) — v1.8

> Read this **when about to split / when working as a child / when collecting merges**.
> Not a session-start must-read.
>
> Fleet Mode was added in v1.1 (ADR-010). v1.2~v1.7에 enforcement / lock / 회복 패치들이 누적됨. v1.8에 본 파일로 분리.

---

## 1. 핵심 모델

```
[Root coordinator]
  Phase 00~02 실행
  Phase 02 종료: split-decision (skill: estimate-project-scope)
    │
    ├─ no-split  → 본인이 Phase 03~06
    │
    └─ split (Fleet)
        ↓ SPLIT-DECISION-ADR 발행 (HC-8/9 무관 사용자 승인 의무)
        ↓ skill: spawn-subtree-prompts → child별 worktree + SUBTREE-PROMPT.md
        ↓ 사용자가 N개 Claude Code 세션 열어 prompt 전달
        │
        ├─ [Child M2]  자기 worktree, branch, STATUS. depth ≤ 2 재귀 가능
        │     완료 시 MERGE-REPORT.md commit
        ├─ [Child M3] 동일
        └─ ...
        ↓
[Root 복귀]
  Phase 05: child branch fetch → integration test → finding 회수
  Phase 06: handoff
```

## 2. Fleet 규칙 (F1~F10)

| # | 규칙 | 의미 |
|---|---|---|
| F1 | **Interface lock at split** | SPLIT-DECISION-ADR의 인터페이스·DB 스키마·invariant·file ownership은 child가 수정 불가. 변경 필요 시 child가 멈춤 + parent escalate |
| F2 | **횡단 invariant 식별 의무** | parent Phase 01 Exit에 *cross-cutting invariant 목록* 필수. split 후 신규 발견 시 전체 stop + parent replan |
| F3 | **Capability manifest freeze** | split 시점 root의 `.harness/capabilities.md` freeze. child는 *읽기만* + candidate 제출 가능 |
| F4 | **File ownership 명시** | SPLIT-DECISION-ADR에 디렉토리 단위 ownership 명시. shared 파일은 parent 소유 — child는 *읽기만*, 변경은 patch candidate로 |
| F5 | **재귀 depth ≤ 2** | root(0) → child(1) → grandchild(2). `spawn-subtree-prompts`이 기계적 강제 |
| F6 | **승인 게이트 (mechanical)** | SPLIT-DECISION-ADR는 production Fleet에서 `approver: user` 의무. `examples/` 경로에 한해 `user-delegated` / `dogfood_simulation: true` 허용 |
| F7 | **Codex review 분배** | 각 child가 자기 scope codex review. parent는 merge 후 cross-cutting integration review 1회. self-test 갈음 조건 4가지 모두 충족 시만 (examples 경로 + <1500 LOC + HC-7/8/9 영향 없음 + 외부 통신/DB write/auth 부재) |
| F8 | **STATUS 위계** | parent STATUS = tree 구조 dashboard. 각 child STATUS = 자기 scope만 |
| F9 | **HC-10 + draft/activate 분리** | child는 `.harness/skills/`에 *draft만*. load·use·activate는 frozen root manifest만 |
| F10 | **Child failure recovery** | child가 rate-limit/crash로 merge-report 작성 못한 경우 parent 대리 작성 가능 — `parent_authored: true` + `evidence_confidence: high|medium|low` 명시 |

## 3. 언제 split할까 — split-decision heuristic

skill [`estimate-project-scope`](skills/estimate-project-scope.md)이 입력 기반 추천:

| 신호 | 임계 | 결정 |
|---|---|---|
| 모듈 수 | ≤ 3 | no-split |
| 모듈 수 | 4~7, 결합도 낮음 | split (root + N leaves) |
| 모듈 수 | 8+ | split + leaf 또 split (depth=2) |
| 모듈 간 순환 의존 | 1+ | no-split (lock 위험) |
| 횡단 invariant | 3+ | no-split or 신중 split |
| 예상 LOC | < 1500 | no-split |
| 예상 LOC | ≥ 5000 + 모듈 ≥4 | split 권장 |

휴리스틱은 참고. 최종 판단은 SPLIT-DECISION-ADR에 근거 명시.

## 4. Subtree workspace

```
parent-repo/                # parent worktree (main)
├── .harness/
│   ├── status.md           # root STATUS — tree dashboard
│   ├── capabilities.md     # frozen at split
│   ├── subtrees/<child>/
│   │   ├── prompt.md       # SUBTREE-PROMPT (child kickoff)
│   │   ├── locked-interface.md   # 변경 불가 spec
│   │   └── merge-report.md       # child fetch+commit으로 제공
│   └── decisions/ADR-NNNN-split-decision-<slug>.md

../parent-repo-<child>/     # child worktree (feat/<child> branch)
├── .harness/
│   ├── subtree.md          # 본 세션이 sub-coordinator
│   ├── status.md           # child scope의 STATUS
│   └── (자기 모듈 코드)
```

git worktree로 *독립 디렉토리 + 독립 컨텍스트 + 독립 branch*. merge phase에 parent가 `git fetch` + `git merge`.

> **Same-worktree mode (v0.5 dogfood)**: production Fleet은 별도 worktree 의무지만, examples/ 경로에서는 *경량 same-worktree*도 허용됨. SPLIT-DECISION-ADR에 `same_worktree_mode: true` 명시 + child별 file ownership grep으로 boundary 강제. v1.8 carry — production-grade 강화는 v1.9+ ADR 후보.

## 5. Phase mapping

| Phase | Root | Child |
|---|---|---|
| 00 Intake | 본인 | (parent 상속) |
| 01 Blueprint | 본인 (횡단 invariant 의무) | (parent 상속) |
| 02 ModulePlan | 본인 scope + split-decision | 본인 scope (재귀 가능, depth ≤ 2) |
| 03 Implement | (split 시 spawn만) | 본인 scope만 |
| 04 CrossReview | (split 시 integration review만) | 본인 scope codex |
| 05 Integration | merge-collection | (해당 없음) |
| 06 Handoff | 본인 | MERGE-REPORT 작성 + commit |

## 6. Lock + invariant enforcement (v1.3+ AST-level)

**Single-method consume lock**: locked-interface §"Consumed interface"가 runtime import allowlist. `spawn-subtree-prompts` skill이 `lock-eslint-gen` 호출 → child별 `eslint.config.<child>.mjs` 생성. `no-restricted-imports` rule이 allowlist 외 import를 AST-level error.

**Layer 1**: cross-dir sibling deny (`../sibling/internal-path-block`).
**Layer 2**: named-import allowlist via `paths.allowImportNames` (v1.7 F126).
**Layer 3**: stable module deny — `consumed_stable_modules` allowlist (v1.5 F122).
**Layer 4**: same-dir sibling deny (v1.6 F123), with stable-allowlist exemption (v1.7 F125).

**Honest 한계** (v1.6 meta-review M9): AST enforcement는 *direct named import + alias*까지 catch. re-export barrel walker + namespace import (`import * as X`) deep analysis는 v1.7+ custom rule 후보. codex review가 2nd-line defense.

**Invariant-guard**:
- (a) **권장** — 횡단 invariant를 runtime gate function으로 redesign. import가 자연스럽게 호출됨
- (b) **fallback** — `// @invariant-guard: <util>` marker. codex review가 실제 호출 책임

**MERGE-REPORT INV evidence**: child가 각 invariant별 실제 코드 path 인용 의무. parent merge 시 evidence 누락/false면 child re-work.

## 7. Inter-child consume timing (v1.2 F81 patch)

child A가 child B의 module을 consume할 때 race 방지. SPLIT-DECISION-ADR에 `inter_child_consume_strategy: a|b|c` field 의무:

| 옵션 | 절차 | helper | case |
|---|---|---|---|
| **(a) lock-spec stub** | parent가 spawn 전 consumer-stub 작성 (signature + `throw not-implemented`). merge phase에 real impl 덮어쓰기 검증 | `python3 scripts/fleet/gen_stub.py` | type + 가벼운 runtime call |
| **(b) type-only ambient** | consumer가 자기 worktree에 `<provider>.d.ts` 작성. merge phase에 ambient 제거 + real import 검증 | `python3 scripts/fleet/gen_ambient.py` | type-only dependency |
| **(c) topological spawn order** | `spawn-subtree-prompts`이 dependency graph topo sort → provider 완료 후 consumer spawn | `python3 scripts/fleet/topo_sort.py` | parallel 이득 일부 포기 OK |

## 8. Scope-bounded pre-review-gate (v1.2 F85)

parallel spawn 중 `npm run typecheck` (root scope)는 sibling 미완에서 fail. child가 자기 PASS 선언 못함. `spawn-subtree-prompts` skill이 SUBTREE-PROMPT 생성 시 child scope 명령 자동 주입:

```bash
# scope-only typecheck — child의 owned src + shared만
npx tsc --noEmit src/<child>/*.ts src/shared/*.ts tests/<child>/*.ts

# scope-only test
npm test -- --testPathPattern=<child>
```

또는 child별 `tsconfig.<child>.json` + `jest.config.<child>.json` 생성.

## 9. Drift 신호

- child가 locked interface 수정 (git diff에 lock 파일 변경)
- MERGE-REPORT에 capability candidate 5+ (manifest freeze 압박)
- 횡단 invariant가 split 후 신규 발견 (parent Phase 01 미흡)
- merge 시 shared 파일에서 conflict 다수 (file ownership 명세 미흡)

drift 시 HARNESS.md §6 + ADR. 반복되면 *Fleet Mode 자체 회의 후보*.

## 10. 신규 산출물

- **Templates** (4): `templates/{SUBTREE-PROMPT, SUBTREE-STATUS, SPLIT-DECISION-ADR, MERGE-REPORT}.template.md`
- **Base skills** (2): `skills/estimate-project-scope.md`, `skills/spawn-subtree-prompts.md`
- **Fleet helpers**: `scripts/fleet/{gen_stub, gen_ambient, topo_sort, gen_eslint_lock, validate_capabilities}.py`

## 11. Carry-over (v1.9+)

- **Same-worktree mode formalization**: v0.5 dogfood이 worktree spec 우회. ADR 발행 — 명시 모드 정의 or worktree 의무화
- **Shared findings broadcast**: child A가 발견한 parent/harness/sibling 영향 버그를 sibling이 즉시 보도록 (F125 case 재발 방지)
- **Patch candidates collector**: `scripts/fleet/collect_merge_reports.py` — parent merge 시 child별 patch_candidates / open_findings / capability_candidates 자동 aggregate
- **Re-export barrel walker**: lock enforcement Layer 5 후보 — namespace import deep AST analysis
