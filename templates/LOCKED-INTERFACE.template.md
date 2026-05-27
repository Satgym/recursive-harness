---
artifact: locked_interface
child_name: <kebab-case>
provider_of: [<other-child-or-parent>, ...]
consumer_of: [<other-child>, ...]
sha_at_split: <computed at spawn time>
---

# Locked interface — `<child_name>`

> 변경 불가. 본 child가 spawn된 시점에 고정. 변경 필요 시 parent에 escalate (SPLIT-DECISION-ADR amend).

## Public interface (제공)

```ts
// src/<child>/index.ts
export type <Type1> = ...;
export function <fn1>(...): Result<T, E>;
```

### 행동 spec (F84 — edge case 명시 의무)

각 함수의 *valid range* + *invalid 처리 policy*:
- `<fn1>` param `<x>: number` — valid: `>=1, integer`; invalid → `empty result` (또는 `err('invalid_x')`)
- `<fn1>` returns: `<spec>` (예: "empty input → ok with empty array, not err")

명세 누락 시 child별 비결정성 — 본 섹션은 *생략 금지*.

## Consumed interface (소비 — Fleet F1/F90 strict)

본 child가 다른 child / parent의 module을 *소비*하는 경우, **runtime import vs type-only import 구분 명시**:

### Runtime imports (allowlist)

```ts
import { <method1>, <method2> } from '../<provider>/index.js';
```

위 명시된 method *외* runtime import 금지. parent Phase 05 [`lock-grep-gate`](../skills/lock-grep-gate.md) 자동 검증.

### Type-only imports

```ts
import type { <Type1>, <Type2> } from '../<provider>/index.js';
```

type-only는 비교적 자유 — 단 runtime 사용 흔적 발견 시 lock violation.

## File ownership (single source of truth — F83)

> SUBTREE-PROMPT는 본 섹션을 *참조*만; 중복 명시 금지.

- 쓰기 가능: `src/<child>/`, `tests/<child>/`, `.harness/subtrees/<child>/merge-report.md`
- 읽기 가능: 그 외 모든 파일 (shared 포함; *쓰기*는 patch candidate로)

## 횡단 invariant 준수 (Blueprint §8.5 복제)

본 child가 *동시에* 지켜야 할 횡단 invariant:

- INV-1: ...
- INV-2: ...

각 invariant별 *enforcement 방식* 명시 권장 (직접 호출 / @invariant-guard marker / runtime gate wrapper 등 — F87 patch).

## Defensive validation policy (F89)

본 child가 *받는 input*에 대한 trust 수준:

- branded type input: trust brand OR re-validate on entry (선택 + 이유 명시)
- 외부 string input: 항상 re-validate

선택을 *문서화*하여 child간 비결정성 방지.
