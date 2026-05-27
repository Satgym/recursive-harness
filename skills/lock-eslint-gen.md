---
artifact: base_skill
version: v0.1
date: 2026-05-27
author: claude
status: proposed
references:
  - HARNESS.md §14.8 (lock & invariant enforcement)
  - scripts/fleet/gen_eslint_lock.py
  - codex F102 v1.2 review (advisory → mechanical)
---

# Base Skill: `lock-eslint-gen`

> Fleet F1 (interface lock)을 **AST-level**로 enforce. F102 v1.2 codex finding 응답.
> v1.2의 `lock-grep-gate`는 *grep first-line*이지만 본 skill은 *AST mechanical*.

## When to invoke

Phase 02 split-decision 후 — `spawn-subtree-prompts` skill Step 3.5 (per-child config 생성) 직후, child kickoff prompt 발송 전.

## What it generates

각 child별 **flat ESLint config** (`eslint.config.<child>.mjs`):
- `no-restricted-imports` rule
- locked-interface §"Consumed interface" runtime allowlist *외* 모든 named import → error
- 본 child가 *consume조차 안 한* provider module도 *모든 import 금지*

## Procedure

```bash
python3 scripts/fleet/gen_eslint_lock.py <SPLIT-DECISION-ADR-path> --out-dir <project-root>
```

생성 결과:
```
eslint.config.auth.mjs       # auth가 import할 수 있는 method 명시
eslint.config.catalog.mjs    # catalog가 ...
eslint.config.<child>.mjs    # ...
```

각 child의 SUBTREE-PROMPT Pre-review-gate 섹션에 추가됨:
```bash
npx eslint --config eslint.config.<child>.mjs --no-config-lookup src/<child>/**/*.ts tests/<child>/**/*.ts
```

ESLint failure → child re-work (Lock violation; allowlist + locked-interface 참조).

## Strength vs `lock-grep-gate` (v1.2)

| 측면 | `lock-grep-gate` (v1.2 grep) | `lock-eslint-gen` (v1.3 AST) |
|---|---|---|
| Direct named import | ✓ | ✓ |
| Multi-line import | partial | **✓** |
| Alias (`import { x as y }`) | ✗ | **✓** (ESLint normalizes) |
| Namespace import (`import * as`) | ✗ | partial (rule supports `importNamePattern`) |
| Re-export barrel | ✗ | ✗ (별도 AST walker v1.4 후보) |
| 실시간 IDE feedback | ✗ | **✓** (ESLint extension) |
| pre-commit hook | partial | **✓** |

## When to fall back to `lock-grep-gate`

- yq/python3 미설치 환경
- ESLint v9+ 미설치 (legacy ESLint v8 .eslintrc.json 필요 시 helper 분기)
- spawn 직후 첫 import 검증 (eslint setup 전)

## Output goes to

- `<project-root>/eslint.config.<child>.mjs` (각 child)
- 각 SUBTREE-PROMPT의 Pre-review-gate 섹션에 *명령 자동 주입* (spawn-subtree-prompts Step 3.5에서 추가)
- Phase 05 merge-collection에서 *최종 검증 1회 더* (parent가 모든 child config 일괄 실행)

## Anti-patterns

- locked-interface §"Consumed interface" 누락 → 본 skill이 allowlist=∅로 처리; 결과적으로 *모든* provider import 금지 → child가 막힘. locked-interface 채우는 게 root coordinator 의무 (F105 v1.2 patch)
- ESLint config를 child가 *수정* → Fleet F4 violation (parent-owned config). spawn 시 read-only marker (gitattributes 또는 commit hook) 권장
- `--no-config-lookup` 빠뜨림 → eslint가 상위 config와 merge하면서 의도 외 rule 추가 risk
