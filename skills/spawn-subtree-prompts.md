---
artifact: base_skill
version: v0.1
date: 2026-05-27
author: claude
status: proposed
references:
  - HARNESS.md §14 Fleet Mode
  - skills/estimate-project-scope.md (선행 skill)
  - templates/SUBTREE-PROMPT.template.md
  - templates/SUBTREE-STATUS.template.md
  - templates/SPLIT-DECISION-ADR.template.md
---

# Base Skill: `spawn-subtree-prompts`

> `estimate-project-scope`가 `split` 결정 + SPLIT-DECISION-ADR 사용자 승인 완료 후 호출.
> 각 child를 위한 *worktree + locked-interface + kickoff prompt*를 자동 생성.

## When to invoke

- 선행 조건 1: `.harness/decisions/ADR-NNNN-split-decision-<slug>.md`가 `status: accepted` (사용자 승인 완료)
- 선행 조건 2: ADR이 본 split의 N개 child 구성·인터페이스 lock·file ownership matrix 완비
- 선행 조건 3: capability manifest가 freeze 상태 (split 시점)

## Inputs

- SPLIT-DECISION-ADR 파일 경로
- repo root path (parent worktree)
- (선택) base branch name (기본 `main`)

## Procedure

### Step 1 — Pre-flight 확인 (F73 + F74 fix — 기계적 게이트 강제)

```bash
# ADR 존재 확인
test -f "$ADR_PATH" || die "SPLIT-DECISION-ADR not found"

# F73 fix — status: accepted AND 유효한 approval 경로 확인 (모든 모드, F80 update)
grep -q "^status: accepted" "$ADR_PATH" || die "ADR not accepted"

# F80 (v1.2) — 3 valid approval paths:
#   (a) approver: user (직접 승인)
#   (b) approver: user-delegated + delegation_source: <quote> (autonomous session 안 사용자 명시 delegation)
#   (c) dogfood_simulation: true (example/test 한정 — production 금지)
APPROVED=0
if grep -q "^approver: user$" "$ADR_PATH"; then
  APPROVED=1
elif grep -q "^approver: user-delegated$" "$ADR_PATH"; then
  # F100 v1.2 codex blocker patch — user-delegated는 examples/ path만 허용 (production 금지)
  case "$ROOT_PATH" in
    */examples/*) ;;
    *) die "F100: approver: user-delegated는 examples/ 하위 dogfood만 허용 (production Fleet은 approver: user 직접 승인 또는 out-of-band confirmation artifact 의무)" ;;
  esac
  # delegation_source field 의무 + 비어있지 않음 (위조 가능성 인정 — examples 전용이라 weak gate 허용)
  DELEGATION=$(grep "^delegation_source:" "$ADR_PATH" | sed 's/^delegation_source: *//')
  if [ -z "$DELEGATION" ] || [ "$DELEGATION" = "<quote 또는 file ref>" ]; then
    die "F80: approver: user-delegated requires non-empty delegation_source field (quote of user delegation message)"
  fi
  APPROVED=1
  echo "[warn] user-delegated approval (examples-only mode; source: $DELEGATION) — NOT for production Fleet"
elif grep -q "^dogfood_simulation: true$" "$ADR_PATH"; then
  # production 금지 — path가 examples/로 시작해야 함
  case "$ROOT_PATH" in
    */examples/*) APPROVED=1 ;;
    *) die "F80: dogfood_simulation: true는 examples/ 하위만 허용 (production Fleet 금지)" ;;
  esac
  echo "[warn] dogfood_simulation mode — user approval bypassed (NOT for production Fleet)"
fi
[ "$APPROVED" -eq 1 ] || die "Fleet F6 violation: SPLIT-DECISION-ADR requires one of: approver:user / approver:user-delegated+source / dogfood_simulation:true"

# F74 fix — recursion depth enforcement
CURRENT_DEPTH=$(grep "^current_depth:" "$ADR_PATH" | awk '{print $2}')
MAX_DEPTH=$(grep "^max_depth_allowed:" "$ADR_PATH" | awk '{print $2}')
RESULTING_DEPTH=$((CURRENT_DEPTH + 1))
if [ "$RESULTING_DEPTH" -gt "$MAX_DEPTH" ]; then
  die "Fleet F5 violation: resulting_depth=$RESULTING_DEPTH > max_depth_allowed=$MAX_DEPTH (need ADR for exception)"
fi
# Root path tracking — child가 root까지 walk-up 가능해야 함
ROOT_PATH=$(grep "^root_path:" "$ADR_PATH" | awk '{print $2}')
test -n "$ROOT_PATH" || die "Fleet F74: root_path required in SPLIT-DECISION-ADR"

# capability manifest freeze 확인 — root path 기준으로
test -f "$ROOT_PATH/.harness/capabilities.md" || die "root capability manifest required"
ROOT_MANIFEST_HASH=$(sha256sum "$ROOT_PATH/.harness/capabilities.md" | cut -d' ' -f1)
# (freeze 확인은 git diff base_branch -- .harness/capabilities.md == empty;
#  본 hash는 child subtree marker에 root_capability_manifest_hash로 fixed)

# 모든 module plan approved 확인 — F76: expected module set 비교 의무
test -f .harness/docs/modules/index.md || die "F76: expected module set required at .harness/docs/modules/index.md"
EXPECTED_MODULES=$(grep -E "^- " .harness/docs/modules/index.md | wc -l)
APPROVED_PLANS=$(grep -l "^status: approved" .harness/docs/modules/*/plan.md 2>/dev/null | wc -l)
if [ "$EXPECTED_MODULES" -ne "$APPROVED_PLANS" ]; then
  die "F76 violation: expected=$EXPECTED_MODULES vs approved=$APPROVED_PLANS — split-decision premature"
fi
for m in .harness/docs/modules/*/plan.md; do
  grep -q "^status: approved" "$m" || die "module plan not approved: $m"
done

# F81 v1.2 — inter_child_consume_strategy 의무
STRATEGY=$(grep "^inter_child_consume_strategy:" "$ADR_PATH" | awk '{print $2}')
case "$STRATEGY" in
  a|b|c) echo "[info] inter-child consume strategy: $STRATEGY (a=stub, b=ambient, c=topo-order)" ;;
  *) die "F81: SPLIT-DECISION-ADR requires inter_child_consume_strategy ∈ {a, b, c} — see HARNESS §14.9" ;;
esac
```

### Step 1.5 — Strategy-specific 사전 작업 (F101 v1.2 + v1.3 helper 실 구현)

`$HARNESS_ROOT/scripts/fleet/*.py` 호출. (F112 v1.3 patch — 경로 통일).

**(a) lock-spec stub** — parent가 spawn 전 *consumer가 import할 provider stub* 작성:
```bash
if [ "$STRATEGY" = "a" ]; then
  # parse_children: ADR's '## Decision' child table OR ownership matrix
  CHILDREN=$($HARNESS_ROOT/scripts/fleet/topo_sort.py "$ADR_PATH" | sed 's/^wave_[0-9]*: //')
  for CHILD in $CHILDREN; do
    LI="$ROOT_PATH/.harness/subtrees/$CHILD/locked-interface.md"
    STUB_PATH="$ROOT_PATH/src/$CHILD/index.ts"
    if [ ! -f "$STUB_PATH" ]; then
      mkdir -p "$ROOT_PATH/src/$CHILD"
      $HARNESS_ROOT/scripts/fleet/gen_stub.py "$LI" --out "$STUB_PATH"
    fi
  done
fi
```
consumer test는 *integration test에서만 real provider 사용* (unit test는 stub signature 기반 OK).

**(b) type-only ambient** — consumer 자기 디렉토리에 `<provider>.d.ts`:
```bash
if [ "$STRATEGY" = "b" ]; then
  # For each (consumer, provider) edge in dep graph, emit ambient
  $HARNESS_ROOT/scripts/fleet/topo_sort.py "$ADR_PATH" >/dev/null  # validate
  # 명시적으로 ADR의 dependency graph 파싱
  grep -oE "[\w-]+\s*->\s*[\w-]+" "$ADR_PATH" | while IFS= read -r EDGE; do
    CONSUMER=$(echo "$EDGE" | awk '{print $1}')
    PROVIDER=$(echo "$EDGE" | awk '{print $3}')
    # Skip 'cli'/'parent' tokens
    [ "$CONSUMER" = "cli" ] && continue
    [ "$CONSUMER" = "parent" ] && continue
    PROVIDER_LI="$ROOT_PATH/.harness/subtrees/$PROVIDER/locked-interface.md"
    AMBIENT="$ROOT_PATH/src/$CONSUMER/$PROVIDER.d.ts"
    [ -f "$PROVIDER_LI" ] && $HARNESS_ROOT/scripts/fleet/gen_ambient.py "$PROVIDER_LI" --out "$AMBIENT"
  done
  # Phase 05 Exit checklist가 *모든 .d.ts 제거* 검증 의무
fi
```

**(c) topological spawn order** — parent가 wave별 sequential 안내:
```bash
if [ "$STRATEGY" = "c" ]; then
  ORDER=$($HARNESS_ROOT/scripts/fleet/topo_sort.py "$ADR_PATH")
  echo "Spawn order (topological — wave-by-wave):"
  echo "$ORDER" | while IFS= read -r LINE; do
    echo "  $LINE — wave 완료 후 다음 wave 진행 (parent가 wait gate 관리)"
  done
  # v1.3 한계: Step 6 사용자 안내에 wave 정보 포함 — 실 sequential dispatch는
  # Claude Code SDK multi-session API 가능 시 자동화 (v1.4 후보)
fi
```

### Step 1.6 — ESLint lock config 생성 (F111 v1.3 codex patch — primary AST gate)

각 child별 ESLint flat config 자동 생성:

```bash
# Strategy와 무관하게 항상 실행 — F1 lock의 primary mechanical gate
$HARNESS_ROOT/scripts/fleet/gen_eslint_lock.py "$ADR_PATH" --out-dir "$ROOT_PATH"
# 결과: eslint.config.<child>.mjs (per-child flat config with no-restricted-imports)
# child의 SUBTREE-PROMPT Pre-review-gate 섹션에 실 명령 주입 (Step 3에서 처리)

# eslint deps 확인
if ! [ -d "$ROOT_PATH/node_modules/eslint" ]; then
  echo "[warn] eslint not installed — F102 AST gate skipped, falls back to lock-grep-gate"
  echo "[hint] cd $ROOT_PATH && npm install -D eslint @typescript-eslint/parser"
fi
```

### Step 2 — Child별 worktree 생성

ADR의 N개 child 각각에 대해:

```bash
for child in $CHILDREN; do
  WORKTREE_PATH="../$(basename $PWD)-$child"
  BRANCH="feat/$child"

  # branch 생성 (없으면)
  git rev-parse --verify "$BRANCH" >/dev/null 2>&1 || git branch "$BRANCH" main

  # worktree add
  git worktree add "$WORKTREE_PATH" "$BRANCH"
done
```

### Step 3 — Child별 산출물 생성 (parent 측)

각 child에 대해 parent의 `.harness/subtrees/<child>/` 디렉토리 생성:

1. **`locked-interface.md`** — **`templates/LOCKED-INTERFACE.template.md` 인스턴스화 의무 (F105 v1.2 codex patch)**. ADR의 해당 child 인터페이스 섹션을 다음 *모든* 섹션에 채움:
   - Public interface 시그니처 (타입까지)
   - **행동 spec** (각 함수 valid range + invalid 처리 policy — F84)
   - Consumed interface (의존) — **runtime imports vs type-only imports 구분** (F90)
   - 횡단 invariant 목록 (ADR §6 그대로 복제) — enforcement 방식 명시 권장 (runtime gate / marker / wrapper)
   - File ownership (해당 child 행만 — single source of truth, F83)
   - **Defensive validation policy** (branded type input의 trust vs re-validate — F89)
   - DB 스키마 (해당 시)

   **die 조건**: 위 필수 섹션 중 하나라도 누락 시 spawn 거부. *생성된 locked-interface.md를 grep해서 §"Public interface" / §"행동 spec" / §"Consumed interface" / §"File ownership" / §"횡단 invariant" / §"Defensive validation policy" 6개 헤더 모두 존재 확인*. 누락 시 die + parent가 채울 것 요청.

2. **`prompt.md`** — `templates/SUBTREE-PROMPT.template.md` 인스턴스화:
   - `child_name`, `parent_path`, `locked_interface_path`, `worktree_path`, `branch`, `depth` 채움
   - Pre-review-gate 섹션은 Step 3.5의 *생성된* tsconfig/jest config 명령 주입
   - 본 prompt 자체가 child Claude 세션에 그대로 전달될 수 있어야 함 (stranger-proof)

3. **`README.md`** (선택) — 사용자가 본 subtree 디렉토리를 열었을 때 1줄 안내

### Step 3.5 — Per-child tsconfig / jest config 생성 (F104 v1.2 codex patch)

ownership matrix 기반으로 *child별 scope tsconfig + jest config* 자동 생성:

```bash
for CHILD in $CHILDREN; do
  OWNED_PATHS=$(yq ".ownership.\"$CHILD\".owned[]" "$ADR_PATH")
  SHARED_PATHS="src/shared/**/*.ts"

  # tsconfig.<child>.json
  cat > "tsconfig.$CHILD.json" <<EOF
{
  "extends": "./tsconfig.json",
  "include": [$(printf '"%s",' $OWNED_PATHS) "$SHARED_PATHS"],
  "exclude": ["node_modules", "dist"]
}
EOF

  # jest.config.<child>.mjs — testMatch만 override
  cat > "jest.config.$CHILD.mjs" <<EOF
import base from './jest.config.mjs';
export default { ...base, testMatch: ['**/tests/$CHILD/**/*.test.ts'] };
EOF
done
```

SUBTREE-PROMPT의 "Pre-review-gate" 섹션은 생성된 config 사용:
```bash
npx tsc --noEmit -p tsconfig.<child>.json
npm run test -- --config jest.config.<child>.mjs
```

**Fallback** (yq 미설치 등): inline `tsc` 명령 패턴 (HARNESS §14.10 참조). 단 fallback은 *fragile* — production Fleet은 위 config 생성 의무.

### Step 4 — Child worktree 내부 marker 작성

각 child worktree에서:

```bash
cd "$WORKTREE_PATH"
mkdir -p .harness

# subtree marker — 본 세션이 sub-coordinator임을 명시 (F74 — recursion tracking 필수)
cat > .harness/subtree.md <<EOF
---
root_path: $ROOT_PATH                         # F74 — 항상 root까지 trace 가능
parent_path: $PARENT_PATH                     # immediate parent (= root if depth=1)
parent_subtree: $PARENT_SUBTREE               # parent의 subtree name; root면 'root'
child_name: $CHILD
current_depth: $RESULTING_DEPTH               # 0=root, 1=root의 child, 2=grandchild
max_depth_allowed: $MAX_DEPTH                 # ADR에서 상속 — child가 또 split할 때 게이트
locked_interface_path: $PARENT_PATH/.harness/subtrees/$CHILD/locked-interface.md
locked_interface_hash: $(sha256sum $PARENT_PATH/.harness/subtrees/$CHILD/locked-interface.md | cut -d' ' -f1)
root_capability_manifest_hash: $ROOT_MANIFEST_HASH  # F75 — frozen at root, child read-only
split_decision_adr: $ADR_RELATIVE_PATH
created_at: $(date -Iseconds)
---
EOF

# parent의 capability manifest를 *읽기 전용 link*로 (실수 방지)
ln -sf "$PARENT_PATH/.harness/capabilities.md" .harness/capabilities.md
# 또는 cp -a (만약 symlink가 cross-branch 작업에 문제되면)

# 초기 SUBTREE-STATUS
cp $HARNESS_ROOT/templates/SUBTREE-STATUS.template.md .harness/status.md
# (수동 채움은 child session이 첫 작업으로)
```

### Step 5 — Parent STATUS 갱신

parent worktree에서:

```bash
# STATUS.md의 Current 표 갱신
# - Phase: 02-module-plan → wait-for-subtrees
# - Active sub-phase: spawned N children: <list>
# - Next action: 사용자 → N개 Claude Code 세션 열어 prompt 전달
```

### Step 6 — 사용자에게 spawn 안내

parent coordinator는 사용자에게 다음 메시지 출력:

```
✓ Spawned N subtrees (depth=<n>):
  - <child-a>  worktree=<path>  prompt=.harness/subtrees/<child-a>/prompt.md
  - <child-b>  worktree=<path>  prompt=.harness/subtrees/<child-b>/prompt.md
  - ...

Next steps (manual):
1. 각 child별 새 Claude Code 세션을 해당 worktree 디렉토리에서 열기
2. 각 세션 첫 입력으로 prompt.md 본문 paste (또는 'cat .harness/subtrees/<child>/prompt.md' 결과)
3. child 세션이 자기 Phase 02~04를 완주 후 MERGE-REPORT.md commit
4. 모든 child 완료 후 본 parent 세션에 통보 → Phase 05 merge-collection 진입
```

## Failure modes (모두 die early — 사용자 메시지 명확)

- ADR이 *unaccepted* 상태 → die
- ADR `approver: user`가 아닌데 `dogfood_simulation: true`도 없음 → die (F73)
- `resulting_depth > max_depth_allowed` → die (F74, Fleet F5)
- `root_path` field 누락 → die (F74)
- `.harness/docs/modules/index.md`의 expected module set과 approved plan 수 불일치 → die (F76)
- worktree path가 이미 존재 (다른 branch 사용 중) → die + clean 안내
- locked-interface 추출 시 ADR §6 (횡단 invariant) 누락 → die (Fleet F2 위반)
- capability manifest가 frozen 상태가 아님 → die (Fleet F3 위반)

## Anti-patterns

- **사용자 승인 없이 호출** — split-decision은 항상 사용자 게이트
- **인터페이스 lock 없이 spawn** — child가 "내 인터페이스 뭐냐" 질문 폭주
- **shared 파일을 child ownership에** — file ownership matrix 오류, merge 시 conflict 보장
- **capability manifest 동시 변경** — Fleet F3 위반, child가 모순된 manifest 본다

## Output goes to

- N개 git worktree (`../<repo>-<child>/`)
- parent `.harness/subtrees/<child>/{prompt.md,locked-interface.md}`
- 각 child worktree `.harness/{subtree.md,status.md,capabilities.md(link)}`
- parent STATUS.md 갱신 (wait-for-subtrees 상태)
