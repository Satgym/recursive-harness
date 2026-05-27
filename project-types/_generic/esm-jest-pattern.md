---
artifact: project_type_seed
seed: esm-jest-pattern
version: v0.1
date: 2026-05-27
status: seed
purpose: ESM + ts-jest 환경의 *known footguns* + 표준 회피 패턴. F86 v1.3 (starpin-fleet + starpin v0.1.0 양쪽 dogfood 신호).
---

# Seed: ESM + ts-jest pattern (Node 22 + TypeScript 5.6)

> 본 seed는 *Node 22 ESM* + `ts-jest/presets/default-esm` 사용 시 *반복 발견되는 함정* + 해결책 표준화.
> 신규 TS ESM 프로젝트는 본 seed 패턴부터 시작 권장.

## §1. `jest` global 미주입

**증상**: `ReferenceError: jest is not defined` 또는 `expect is not defined`

**원인**: ESM 모드 (`--experimental-vm-modules`)에선 jest globals 자동 주입 안 됨

**해결**:
```ts
// 모든 test 파일 상단 명시 import
import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
```

## §2. `jest.isolateModulesAsync` 미지원

**증상**: ESM에서 `jest.isolateModulesAsync(() => import(...))` 미작동 (jest 29.7 기준)

**원인**: ESM 캐시는 native — jest module registry와 별도

**해결** (module-level mutable state 격리 필요 시):
```ts
beforeEach(() => {
  jest.resetModules();   // 일부 도움 — 완전 격리는 아님
});

it('with fresh module', async () => {
  // dynamic import — every it() block가 새 import
  const { someFunc } = await import('../src/some-module.js');
  // ... test
});
```

**권장 회피**: module-level mutable state 패턴 자체를 피함. *factory function*으로 fresh instance 반환:
```ts
// 나쁨 — module-level mutable
const _store = new Map();
export function add(k, v) { _store.set(k, v); }

// 좋음 — factory
export function makeStore() {
  const _store = new Map();
  return { add: (k, v) => _store.set(k, v) };
}
```

## §3. `.js` extension in TS import (ESM strict requirement)

**증상**: `Cannot find module '../foo'`

**원인**: Node ESM은 `.js` extension 의무 (TS는 `.js`로 적되 실제 컴파일된 결과 가리킴)

**해결**:
```ts
// 나쁨
import { x } from '../foo';
// 좋음
import { x } from '../foo.js';   // TS 파일이지만 .js로 (jest moduleNameMapper가 처리)
```

`jest.config.mjs`에 매핑:
```js
export default {
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',   // .js → .ts in tests
  },
};
```

## §4. ts-jest transform option for ESM

**최소 jest.config.mjs**:
```js
/** @type {import('jest').Config} */
export default {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  extensionsToTreatAsEsm: ['.ts'],
  moduleNameMapper: { '^(\\.{1,2}/.*)\\.js$': '$1' },
  transform: { '^.+\\.ts$': ['ts-jest', { useESM: true }] },
  testMatch: ['**/tests/**/*.test.ts'],
};
```

⚠️ **함정**: `tsconfig: { strict: false }` override 추가 시 `tsconfig.json`의 `exactOptionalPropertyTypes: true`와 충돌 → TS5052 에러. 이미 fleet-mini F-add-1로 발견. *override 추가 자제*.

## §5. test script

`package.json`:
```json
{
  "scripts": {
    "test": "node --experimental-vm-modules node_modules/jest/bin/jest.js"
  }
}
```

`--experimental-vm-modules` 빠뜨리면 ESM 안 됨.

## §6. CI에서

CI는 위 패턴 그대로 동작. `--experimental-vm-modules` warning은 noise — `--no-warnings` 추가 가능.

## §7. 관련 dogfood evidence

- starpin v0.1.0 backend (`examples/starpin/backend/`) — astronomy-engine ESM transformIgnorePatterns 추가 필요했음
- fleet-mini (`examples/fleet-mini/`) — `tsconfig: { strict: false }` override 부적절 (F-add-1)
- starpin-fleet (`examples/starpin-fleet/`) — auth child가 `jest` import 누락으로 fail (V12-AUTH-2 → F86)

## §8. 신규 프로젝트 적용 (현재 manual; v1.4 자동화 후보)

본 seed는 *읽기 자료*. `new-project.sh`는 현 시점 (v1.3) 자동 적용 안 함 (`test-strategy.md` / `module-skeleton.md`만 복사).

**Manual 적용 절차** (TS ESM 프로젝트 시작 시):
1. `package.json`에 §5 test script + jest/ts-jest devDeps 추가
2. `jest.config.mjs`를 §4 양식으로 생성
3. 본 seed 1회 통독 (특히 §1~§4 함정)
4. (Fleet Mode 사용 시) ESLint v9+ + @typescript-eslint/parser 추가 — lock-eslint-gen 의존

**v1.4 후보** — `new-project.sh --seed esm-jest-pattern` 옵션 또는 `project-types/_generic/seeds/esm-jest/` 디렉토리 신설 후 `new-project.sh`가 자동 복사. ADR-012 §C에 v1.3 한계로 명시됨.
