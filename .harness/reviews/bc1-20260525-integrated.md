---
artifact: review
date: 2026-05-25
author: codex
status: open
severity: <see body>
target: skills/ + project-types/
review_round: BC.1
prior_review: .harness/reviews/a5-20260525-integrated.md
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e5db9-fd61-7b23-b4f8-f7f4591c975a
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: medium
  tokens_used: 129594
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-25T06:02
  prompt_source: .harness/prompts/bc1-integrated-review.md
---

---
date: 2026-05-25
author: codex
severity: blocker
target: Phase B (skills/) + Phase C (project-types/) integrated cross-review
status: open
review_round: BC.1
prior_review: .harness/reviews/a5-20260525-integrated.md
---

# Phase B + C Integrated Cross-Review (BC.1)

## Summary
Phase B/C의 방향은 HARNESS v0.5와 대체로 맞고, `codex-review.sh` / `codex-exec-review.sh` 플래그 인용도 대부분 실제 구현과 일치한다. 다만 새 프로젝트에서 실제로 실행 가능한 진입점과 산출물 경로가 어긋나는 major 2건이 있고, web-service 테스트/모듈 문구가 HC-8의 “사용자 승인” 게이트를 dry-run/실환경 선택으로 약화해 blocker로 봐야 한다. 이 상태로 Phase D는 진행 불가다.

## Part A — Cross-consistency findings

### Finding 27: Generated projects do not have the script paths that skills tell them to run
- severity: major
- target: `scripts/new-project.sh:142-147`, `skills/plan-blueprint.md:36-43`, `skills/request-codex-review.md:25-46`
- detail: `new-project.sh`는 `.harness/`만 만들고 `scripts/`를 새 프로젝트 루트에 복사하지 않는다. 그런데 bootstrap summary와 skills는 새 프로젝트 루트에서 `scripts/codex-exec-review.sh`, `scripts/codex-review.sh`, `scripts/pre-review-gate.sh`를 실행하라고 지시한다. 실제로 `/private/tmp`에서 web-service bootstrap을 smoke-test하면 `.harness/docs/*`만 생성되고 `scripts/`는 없다. 따라서 Phase 01/02/04의 표준 명령이 새 프로젝트에서 즉시 실패한다.
- suggested_action: 둘 중 하나로 통일한다. 1) `new-project.sh`가 root `scripts/` wrapper를 복사하거나 symlink한다. 2) 모든 skill/phase/summary 명령을 `"$HARNESS_ROOT/scripts/..."` 형태로 바꾸고, `.harness/config.toml` 또는 STATUS에 HARNESS_ROOT 확인 절차를 추가한다.
- references: `HARNESS.md §5.1`, `phases/01-blueprint.md`, `phases/04-cross-review.md`, `scripts/new-project.sh`

### Finding 28: Project-type copy does not instantiate required Phase 00 artifacts
- severity: major
- target: `scripts/new-project.sh:103-113`, `scripts/new-project.sh:142-147`, `project-types/README.md:1-4`, `phases/00-intake.md:24-31`
- detail: Phase 00 Output은 `.harness/docs/intake.md`를 요구하지만 `new-project.sh`는 `project-types/<type>/intake-checklist.md`를 그대로 `.harness/docs/intake-checklist.md`로 복사한다. 또한 web-service의 `api-spec-template.md`도 `.harness/docs/api/openapi.yaml` 위치가 아니라 `.harness/docs/api-spec-template.md`로 남는다. bootstrap summary는 intake 작성 대신 바로 blueprint 작성으로 안내해 Phase 00 Exit와 drift가 난다.
- suggested_action: bootstrap 시 `intake-checklist.md -> .harness/docs/intake.md`를 인스턴스화하고, 나머지 project-type 자료는 `.harness/docs/project-type/` 같은 참조 위치에 보존한다. web-service는 `.harness/docs/api/openapi.yaml` placeholder를 만들거나, 최소한 api spec 생성 step을 bootstrap next steps에 넣는다.
- references: `phases/00-intake.md`, `project-types/web-service/api-spec-template.md`, `skills/kickoff-project.md`

### Finding 29: _generic module dependency direction contradicts itself
- severity: minor
- target: `project-types/_generic/module-skeleton.md:7-18`
- detail: 표는 `M-storage`가 `M-core`에 의존한다고 쓰지만, 바로 아래 원칙은 `M-io → M-core → M-storage`라고 적어 의존 방향 해석이 반대가 된다. Blueprint dependency graph의 출발점이 되는 파일이라 작은 표현 모순도 후속 Module Plan에서 사이클/경계 혼선을 만든다.
- suggested_action: “의존” 컬럼의 의미를 depends-on으로 고정하고, 예: `M-core`는 storage port/interface만 소유, `M-storage`는 `M-core`의 port를 구현한다처럼 방향을 명시한다. 화살표도 `caller -> callee`인지 `depends-on`인지 라벨링한다.
- references: `HARNESS.md HC-1`, `phases/01-blueprint.md`

## Part B — New surface findings

### Finding 30: Malformed Codex review output has no validation/recovery path
- severity: minor
- target: `skills/request-codex-review.md:47-67`, `skills/apply-review.md:19-55`
- detail: request/apply 절차는 `_codex_postprocess.py`가 항상 REVIEW front-matter와 finding 목록을 정상 생성한다고 가정한다. 네트워크 실패는 언급하지만, codex가 템플릿을 어기거나 finding ID가 비단조/누락되거나 front-matter enum이 malformed인 경우의 판정 기준이 없다. Phase 04 Exit는 REVIEW 양식과 codex_meta를 요구하므로, malformed output은 “리뷰 받음”으로 처리되면 안 된다.
- suggested_action: request-codex-review에 “REVIEW validation” 단계를 추가한다. 필수 front-matter, `codex_meta`, finding ID monotonicity, canonical enum을 검사하고 실패 시 raw 파일 경로를 STATUS Open findings에 올린 뒤 review status를 `open`이 아닌 “invalid review attempt”로 명시하도록 한다.
- references: `templates/REVIEW.template.md`, `phases/04-cross-review.md`, `HARNESS.md §5.3`

### Finding 31: API spec template is too thin for a spec-first frontend contract
- severity: minor
- target: `project-types/web-service/api-spec-template.md:41-110`
- detail: OpenAPI 예시는 list endpoint와 401만 있어 프론트엔드/소비자가 실제 구현 없이 개발하기에 부족하다. `operationId`, tags, requestBody 예시, create/update/delete 응답, 공통 400/403/404/409/422/429/5xx, validation error 형태, request id header, auth variant(cookie/API key/OAuth2) 선택지가 빠져 있다. 또한 규칙은 `code`를 enum/정수라고 하지만 schema는 그냥 string이다.
- suggested_action: 최소 CRUD 예시와 표준 error responses를 components에 추가하고, `Error.code`를 enum placeholder로 바꾼다. `X-Request-Id` response header, validation error details shape, auth scheme 선택 블록을 포함한다.
- references: `project-types/web-service/intake-checklist.md:13-19`, `project-types/web-service/test-strategy.md:5-12`

### Finding 32: Frontend collaboration gate is stated as yes/no, not artifact-based
- severity: minor
- target: `project-types/web-service/intake-checklist.md:93-96`
- detail: “프론트엔드 팀이 API spec만으로 작업 시작 가능한가? yes여야 함”은 좋은 방향이지만 측정 가능하지 않다. 실제로는 mock server URL, generated client/types, fixture examples, CORS/credentials policy, breaking-change notification rule 같은 산출물이 있어야 spec-first 협업이 열린다.
- suggested_action: 이 섹션을 체크리스트로 바꾼다: `openapi.yaml lint PASS`, `mock server command`, `example request/response fixtures`, `generated client/types location`, `CORS credentials policy`, `change notification channel`을 yes/no가 아니라 파일/명령 경로로 채우게 한다.
- references: `project-types/web-service/api-spec-template.md`, `project-types/web-service/test-strategy.md`

### Finding 33: INBOX procedures assume a directory that generated projects do not create
- severity: minor
- target: `skills/resume-session.md:19-33`, `skills/checkpoint-handoff.md:22-37`, `scripts/new-project.sh:69-101`
- detail: resume/checkpoint skills require `INBOX/` checks, but project bootstrap does not create `INBOX/`, and HARNESS §4.2 project artifact table also does not list a project INBOX location. This leaves generated projects with a session-start/checkpoint procedure that can fail or become optional by accident.
- suggested_action: Decide whether project INBOX is root `INBOX/` or `.harness/inbox/`. Add it to HARNESS §4.2, create it in `new-project.sh`, and update resume/checkpoint paths accordingly. If INBOX is harness-self only, remove it from generic project skills.
- references: `HARNESS.md §4.1-4.2`, `INBOX/README.md`

## Part C — Security / HC violations

### Finding 34: Web-service test/module guidance weakens HC-8 approval into “real environment” or dry-run
- severity: blocker
- target: `project-types/web-service/test-strategy.md:56-59`, `project-types/web-service/module-skeleton.md:53-60`
- detail: HC-8 requires external-effect mutation to have user approval in all modes. The test strategy says all outgoing external calls are “mock 또는 명시적 실 환경 (HC-8)” but does not require user approval before real external calls. The module skeleton says HC-8/9 mutation paths need a service hook like `if dry_run: return`, but dry-run is not equivalent to explicit user approval, and HC-9 destructive paths also require confirmation. In normal use this can guide implementers toward real external API writes or destructive code paths once an environment is “explicit,” without the HARNESS-required user gate.
- suggested_action: Replace with: “external calls are mocked by default; any real external mutation requires explicit user approval recorded in STATUS/ADR for that run, non-prod credentials, and dry-run where supported.” For destructive actions, require explicit confirmation plus irreversible-action checklist, not just a dry-run branch.
- references: `HARNESS.md HC-8`, `HARNESS.md HC-9`, `phases/03-implement.md:7-8`

## Part D — Phase B/C verdict
- ready_for_phase_D: no
- ready_for_phase_E: no
- minor_fixes_blocking_phase_D: []
- new_blockers: 1
- new_majors: 2
- new_minors: 5
- new_infos: 0
- rationale: Phase B/C are close structurally, but Phase D should not start while generated projects cannot run the documented review commands and Phase 00 artifacts are not materialized under the required names. Independently, F34 is an HC-8 blocker and must be corrected before these templates are dogfooded. After F27/F28/F34 are resolved, the remaining findings are suitable as minor carry-over with explicit intent.
