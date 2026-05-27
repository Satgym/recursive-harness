---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: <see body>
target: <see body>
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e6760-9251-7ec0-87bc-c5a23557e820
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 130400
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T03:00
  prompt_source: .harness/prompts/v1.3-ast-lock-bundle.md
---

REVIEW

Assumption: v1.3 ship 기준은 “스크립트가 존재함”이 아니라 spawn/pre-review/Phase05 경로에서 자동 실행되어 lock 위반을 막는 상태입니다.

**Finding 1**
severity: blocker  
위치: [gen_eslint_lock.py](/Users/satgym/work/harness/scripts/fleet/gen_eslint_lock.py:104), [gen_eslint_lock.py](/Users/satgym/work/harness/scripts/fleet/gen_eslint_lock.py:134)  
근거: ESLint rule이 `../<child>/index.js`의 `export function` 이름만 deny-list로 생성합니다. sibling 내부 경로(`../auth/store.js`, `../auth/internal.js`)나 `export const`, `export class`, `export { x } from ...` 기반 public export는 rule 자체가 생성되지 않아 lock을 우회합니다. 이는 namespace/re-export barrel 같은 v1.4 후보를 떠나, v1.3의 “locked-interface allowlist 외 모든 named import AST error” 주장과 충돌합니다.  
제안: deny-list가 아니라 fail-closed allow-list로 바꾸세요. provider child 전체 패턴(`../auth/**`)은 기본 금지하고, locked `../auth/index.js`의 허용 named import만 통과시키는 방식이 필요합니다. ESLint 기본 rule로 어려우면 v1.3 ship 문구를 “partial AST gate”로 낮추거나 custom rule을 v1.3 범위에 포함해야 합니다.

**Finding 2**
severity: blocker  
위치: [SUBTREE-PROMPT.template.md](/Users/satgym/work/harness/templates/SUBTREE-PROMPT.template.md:73), [phases/05-integration.md](/Users/satgym/work/harness/phases/05-integration.md:23), [spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:201)  
근거: `lock-eslint-gen`이 primary라고 HARNESS는 말하지만, child pre-review-gate template에는 ESLint 명령이 없고, Phase 05 Exit도 여전히 `lock-grep-gate` PASS만 요구합니다. spawn skill Step 3.5도 tsconfig/jest 생성만 명시하고 ESLint config 생성/명령 주입을 실제 절차에 포함하지 않습니다. 따라서 v1.3 시작 시 spawn이 ESLint config를 자동 생성/실행하지 않습니다.  
제안: spawn Step 3.5에 `scripts/fleet/gen_eslint_lock.py` 호출, SUBTREE-PROMPT에 `npx eslint --config eslint.config.<child>.mjs --no-config-lookup ...`, Phase 05에 per-child ESLint PASS를 Exit 기준으로 추가하세요. grep은 그 다음 fallback이어야 합니다.

**Finding 3**
severity: major  
위치: [spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:117), [spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:125), [spawn-subtree-prompts.md](/Users/satgym/work/harness/skills/spawn-subtree-prompts.md:160)  
근거: v1.3 helper가 `scripts/fleet/*.py`에 생겼지만 spawn skill은 아직 `.harness/scripts/gen_stub.py`, `.harness/scripts/gen_ambient.py`, `.harness/scripts/topo_sort.py`를 호출합니다. `$LOCKED_INTERFACE_PATH`, `$PROVIDER_LOCK`, `$CONSUMERS`도 정의되지 않았고, v1.2 한계 문구가 그대로 남아 있습니다. 이 절차대로는 helper script가 production spawn에 통합되지 않습니다.  
제안: 경로를 `$HARNESS_ROOT/scripts/fleet/...`로 통일하고, ADR/locked-interface에서 provider-consumer 매핑을 파싱하는 단일 helper를 쓰세요. 남은 v1.2 limitation 문구도 제거해야 합니다.

**Finding 4**
severity: major  
위치: [gen_stub.py](/Users/satgym/work/harness/scripts/fleet/gen_stub.py:55)  
근거: stub generator가 regex로 함수 선언을 치환하는데, return type 내부 object literal의 세미콜론 때문에 실제 dogfood auth interface의 `createSession(...): Result<{ session: Session; token: SessionToken }, ...>;`가 stub body 없이 남습니다. 제가 실행한 출력도 `createSession`은 declaration-only로 남고 `verifySession`/`revokeSession`만 body가 붙었습니다. `.ts` runtime stub로 쓰면 typecheck가 깨질 수 있습니다.  
제안: TS parser를 쓰거나 최소한 `export function ...;` 잔존 시 fail-fast 하세요. overload/generic/object return type을 지원하기 전까지 “helper PASS”로 보기는 어렵습니다.

**Finding 5**
severity: major  
위치: [gen_ambient.py](/Users/satgym/work/harness/scripts/fleet/gen_ambient.py:38)  
근거: ambient generator가 모든 `import` line을 삭제하지만 public signature는 `Result`, `CatalogId` 같은 imported type을 그대로 참조합니다. 실제 auth ambient 출력도 `Result`가 unresolved로 남습니다. “consumer already has its own Result type”이라는 가정은 TypeScript name resolution과 맞지 않습니다.  
제안: 삭제하지 말고 `import type`을 보존하거나, signature를 `import('../shared/types.js').Result<...>` 형태로 rewrite하세요. 생성 후 `tsc --noEmit` smoke test를 helper validation에 넣어야 합니다.

**Finding 6**
severity: major  
위치: [topo_sort.py](/Users/satgym/work/harness/scripts/fleet/topo_sort.py:40), [topo_sort.py](/Users/satgym/work/harness/scripts/fleet/topo_sort.py:27)  
근거: topo_sort는 dependency edge에 등장한 node만 children에 넣습니다. 독립 child가 `cli (parent) -> child` 식으로만 표시되면 regex가 매칭하지 않아 wave에서 누락됩니다. 또한 docstring은 `consumer <- provider`도 지원한다고 쓰지만 구현은 `->`만 처리합니다.  
제안: child node set은 ADR의 Decision child table 또는 ownership matrix에서 먼저 읽고, dependency edge는 그 위에 overlay하세요. `<-` 문법은 구현하거나 문서에서 제거해야 합니다.

**Finding 7**
severity: major  
위치: [scripts/new-project.sh](/Users/satgym/work/harness/scripts/new-project.sh:161), [esm-jest-pattern.md](/Users/satgym/work/harness/project-types/_generic/esm-jest-pattern.md:122)  
근거: `esm-jest-pattern` seed는 “new-project.sh가 jest.config.mjs 양식을 default로 emit”한다고 하지만, `new-project.sh`는 `test-strategy.md`와 `module-skeleton.md`만 복사합니다. ESLint primary enforcement 역시 신규 프로젝트 bootstrap에서 `eslint`/`@typescript-eslint/parser` dependency나 fallback 정책을 보장하지 않습니다.  
제안: seed 적용 경로를 실제로 만들거나 문구를 낮추세요. TS ESM project-type 옵션, package scaffold, 또는 Phase 00 checklist에 “ESLint v9+ 설치 여부 및 fallback 선택” gate가 필요합니다.

**Finding 8**
severity: minor  
위치: [SPLIT-DECISION-ADR.template.md](/Users/satgym/work/harness/templates/SPLIT-DECISION-ADR.template.md:1), [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:449)  
근거: HARNESS F7은 `codex_review_replacement: self_test | codex_full` field를 명시한다고 하지만 SPLIT template front-matter에는 해당 필드가 없습니다. preflight의 heuristic 자동 평가도 구현되어 있지 않습니다.  
제안: template 필드와 spawn preflight 검증을 맞추세요. 특히 LOC는 estimate인지 measured인지, read-only DB/partial auth 같은 회색 영역은 `codex_full` default로 두는 게 안전합니다.

검증: `topo_sort.py`는 starpin-fleet 기존 ADR에서 `wave_1: auth catalog`, `wave_2: claim sky` 출력. `gen_eslint_lock.py` 생성 및 claim ESLint happy path는 PASS. 다만 `gen_stub.py`/`gen_ambient.py` 출력에서 위 결함이 재현됐습니다. HC-7/8/9 위반은 이 변경 범위에서 보이지 않았습니다.
