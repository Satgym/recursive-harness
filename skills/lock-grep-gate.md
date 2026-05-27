---
artifact: base_skill
version: v0.1
date: 2026-05-27
author: claude
status: proposed
references:
  - HARNESS.md §14.8 (lock & invariant enforcement)
  - starpin-fleet v1.2 findings F87, F90
---

# Base Skill: `lock-grep-gate`

> Fleet Phase 05 merge-collection에서 parent가 호출. interface lock + cross-cutting invariant의 *first-line grep gap detection*.
>
> **honest 제한 (F102 v1.2 codex finding)**: 본 skill은 *gap을 detect*하지만 *완전한 mechanical enforcement는 아님*. alias/namespace/multiline import, re-export helper, 하위 디렉토리 파일은 grep 못 잡음. MERGE-REPORT evidence cross-check + codex review가 second-line defense. AST/ESLint 기반 강화는 v1.3 후보.

## When to invoke

Phase 05 merge-collection의 *boundary verify* 직후, integration test 직전.

## Inputs

- SPLIT-DECISION-ADR (locked-interface allowlist)
- 모든 child의 MERGE-REPORT (INV evidence 인용)
- Repo root (grep target)

## Procedure

### Step 1 — Consume allowlist 추출

ADR의 ownership matrix + 각 locked-interface §"Consumed interface"에서:

```
allowed_imports[<consumer>][<provider>] = [<method1>, <method2>, ...]
allowed_type_imports[<consumer>][<provider>] = [<type1>, <type2>, ...]
```

예 (starpin-fleet):
- `claim → auth`: runtime = `verifySession`; type-only = `SessionToken`, `UserId`
- `sky → catalog`: runtime = `lookupById`, `listAll`; type-only = `CatalogId`, `StarRecord`

### Step 2 — Grep consumer src

각 consumer 디렉토리에 대해:

```bash
# runtime import 추출
grep -nE "^import \{[^}]*\} from '\.\./(<provider>)/index\.js'" src/<consumer>/*.ts

# type-only import는 type 키워드 포함 — 별도 처리
grep -nE "^import type \{[^}]*\} from '\.\./(<provider>)/index\.js'" src/<consumer>/*.ts
```

추출된 import name list를 allowlist와 비교:
- runtime import에 *allowlist 외* method 있음 → **lock violation** (severity: major, MERGE-REPORT escalate)
- type-only import는 비교적 자유 (lock에 명시 안 됐어도 OK — 단 *runtime 사용 흔적* 있으면 violation)

### Step 3 — Invariant util 호출 검증 (F87)

각 child가 import한 invariant util (예: `redactToken`, `redactCoords`, `safeError`)에 대해:

```bash
# import line 추출
IMPORTS=$(grep -nE "import .* from '\.\./shared/redact\.js'" src/<child>/*.ts)
# 실제 호출 흔적 grep
for util in redactToken redactCoords safeError; do
  CALLS=$(grep -nE "\b${util}\(" src/<child>/*.ts)
  # CALLS가 비어있는데 IMPORTS에 있으면 dead import → finding
  if echo "$IMPORTS" | grep -q "$util" && [ -z "$CALLS" ]; then
    # 단 `// @invariant-guard: $util` marker 있으면 허용
    GUARD=$(grep -n "@invariant-guard: $util" src/<child>/*.ts)
    [ -n "$GUARD" ] || echo "DEAD INVARIANT IMPORT: $util in src/<child>/ (no call site, no @invariant-guard marker)"
  fi
done
```

### Step 4 — INV evidence cross-check

각 MERGE-REPORT의 "Cross-cutting invariant 준수" 섹션에 인용된 evidence line이 *실제 코드와 일치*하는지 확인:

```bash
# MERGE-REPORT에 "INV-3: src/claim/index.ts:28 — import { verifySession } from '../auth/index.js'" 같은 인용 추출
# 해당 파일:line이 실제로 그 내용인지 비교
```

mismatch → child re-work (false evidence).

### Step 5 — Verdict 출력

```yaml
lock_grep_gate_verdict:
  consume_allowlist:
    violations: <list>
  invariant_util_calls:
    dead_imports: <list>
  inv_evidence_crosscheck:
    mismatches: <list>
  overall: PASS | FAIL
```

PASS 시 Phase 05 integration test 진행. FAIL 시 *해당 child re-work* 요청 (parent가 SPLIT-DECISION-ADR amend 또는 child SUBTREE-PROMPT 갱신).

## Output goes to

`.harness/reviews/05-lock-grep-gate-<date>.md` (해당 dogfood의 starpin-fleet에서 *manual grep 결과*가 본 skill의 first dogfood evidence).

## Anti-patterns

- consume allowlist를 lock에 명시 안 했는데 본 skill 호출 — 결과 의미 없음. 먼저 locked-interface 정비
- type-only import 구분 안 함 — false positive 폭증
- invariant util을 grep으로 검증 — child가 *간접적으로* 호출 (helper fn 통해) 시 false negative. 본 skill은 *direct call site*만 검증; 간접은 별도 codex review 권장
