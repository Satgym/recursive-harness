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

# F73 fix — status: accepted AND approver: user 확인 (모든 모드)
grep -q "^status: accepted" "$ADR_PATH" || die "ADR not accepted"

# user approval 검증 — 예외는 명시적 dogfood_simulation: true flag만
if ! grep -q "^approver: user$" "$ADR_PATH"; then
  if ! grep -q "^dogfood_simulation: true$" "$ADR_PATH"; then
    die "Fleet F6 violation: SPLIT-DECISION-ADR requires approver: user (or explicit dogfood_simulation: true)"
  fi
  echo "[warn] dogfood_simulation mode — user approval bypassed (NOT for production Fleet)"
fi

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

1. **`locked-interface.md`** — ADR의 해당 child 인터페이스 섹션을 *순수 spec 형태*로 추출. 다음 필수 항목 포함:
   - Public interface 시그니처 (타입까지)
   - Consumed interface (의존)
   - DB 스키마 (해당 시)
   - 횡단 invariant 목록 (ADR §6 그대로 복제)
   - File ownership (해당 child 행만)

2. **`prompt.md`** — `templates/SUBTREE-PROMPT.template.md` 인스턴스화:
   - `child_name`, `parent_path`, `locked_interface_path`, `worktree_path`, `branch`, `depth` 채움
   - 본 prompt 자체가 child Claude 세션에 그대로 전달될 수 있어야 함 (stranger-proof)

3. **`README.md`** (선택) — 사용자가 본 subtree 디렉토리를 열었을 때 1줄 안내

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
