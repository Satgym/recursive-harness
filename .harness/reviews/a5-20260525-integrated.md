---
artifact: review
date: 2026-05-25
author: codex
status: open
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e5d7c-966d-7b63-9c77-896d390a1c5c
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: medium
  tokens_used: 107011
---

---
date: 2026-05-25
author: codex
severity: major
target: Phase A integrated cross-review (harness v0.4)
status: open
review_round: A.5
prior_review: INBOX/processed/codex-feedback-20260525-v0.3-review.md
---

# Phase A Integrated Cross-Review (A.5)

## Summary
v0.4의 큰 구조는 Phase A 산출물로서 방향이 맞다. roles/templates/phases는 대부분 서로 맞물리고, HC-7/8/9도 문서 표면에서는 유지된다. 다만 §9 폐기 이후의 SoT 정리가 덜 끝났고, `scripts/`가 HARNESS §5.3의 review determinism을 실제로 만족하지 못한다. 특히 현재 macOS 기본 `python3`에서는 `.harness/config.toml`이 조용히 무시될 수 있어 첫 dogfood wrapper의 신뢰성이 흔들린다. 현재 상태 그대로 v0.5 태그나 Phase B 진입은 이르다.

## Part A — Cross-consistency findings

### Finding 16: §9 deprecation이 HARNESS 본문 전체에 반영되지 않음
- **severity**: major
- **target**: HARNESS.md:11, HARNESS.md:21, HARNESS.md:61, HARNESS.md:228
- **detail**: ADR-007과 `phases/README.md`는 A.4 완료 후 §9가 폐기되고 `phases/<phase>.md`가 정식 Exit 기준이라고 선언한다. 그러나 HARNESS §0/HC-4/§3은 여전히 “Phase A 동안은 §9 임시 게이트” 또는 “Phase A.4에서 작성 예정”이라고 말한다. 같은 헌법 안에서 §9 적용 여부가 양쪽으로 읽힌다.
- **suggested_action**: HARNESS v0.5에서 §0, HC-4, §3의 Phase A/§9 문구를 “§9는 historical record이며 현재는 phases/ 기준 적용”으로 갱신하고, §9 본문은 archival 섹션으로 이동하거나 명확히 non-normative로 표시.
- **references**: ADR-007, phases/README.md:5, HARNESS.md §9

### Finding 17: CLAUDE.md가 금지된 `deferred(<reason>)` status를 지시함
- **severity**: major
- **target**: CLAUDE.md:28-31
- **detail**: HARNESS §4.3과 INBOX/README.md는 `status: deferred`와 `deferred_reason` 분리를 강제한다. CLAUDE.md는 처리 완료 후 `status`를 `deferred(<이유>)`로 바꾸라고 지시해 canonical enum을 직접 위반한다.
- **suggested_action**: CLAUDE.md:31을 `status: deferred` + `deferred_reason: <이유>`로 변경.
- **references**: HARNESS.md:117-121, INBOX/README.md:51-56, prior F14

### Finding 18: ADR-007 승인 상태와 STATUS handoff가 서로 충돌함
- **severity**: major
- **target**: DECISIONS.md:21-37, STATUS.md:12-23, STATUS.md:147-161, STATUS.md:189-203
- **detail**: DECISIONS.md는 ADR-007을 `Status: accepted`로 두면서 Approval은 `pending`이라고 한다. 반면 STATUS Approved artifacts는 ADR-007과 §9 patch를 user-approved로 기록하고, `approved_at`도 중복 키로 들어가 있다. 또한 STATUS Current/Active gate는 아직 A.4 승인 대기와 HEAD `95ab860`을 말하지만 실제 HEAD는 `15bf6fb`이고 이번 요청은 A.5 수행이다. §7의 stranger-proof SoT 기준을 만족하지 못한다.
- **suggested_action**: DECISIONS.md의 ADR-007 Approval을 실제 승인 timestamp로 갱신하거나 `accepted`를 `proposed`로 되돌린다. STATUS는 HEAD, Active gate, Next action, Roadmap 중복 A.4/A.5 항목을 현재 A.5 상태로 정리하고 중복 `approved_at` 키를 제거.
- **references**: HARNESS.md §7, ADR-007, phases/04-cross-review.md:22, phases/06-handoff.md:6-36

### Finding 19: reviewer-swap approver 값이 HARNESS enum에 없음
- **severity**: minor
- **target**: HARNESS.md:97-101, roles/claude-reviewer.md:24-29
- **detail**: HARNESS approval approver enum은 `user | codex-review | claude-self-test`만 허용한다. 그런데 Claude reviewer-swap은 `approval.approver: claude-reviewer`를 쓰라고 한다. 역할 스왑이 발생하면 산출물 front-matter가 헌법 enum 밖으로 나간다.
- **suggested_action**: HARNESS §4.3 approver enum에 `claude-reviewer`를 추가하거나, claude-reviewer 산출물은 approval이 아니라 REVIEW `author: claude` + `role: reviewer-swap`로만 표현한다고 정리.
- **references**: roles/claude-reviewer.md:28, templates/REVIEW.template.md

## Part B — New surface findings

### Finding 20: `_codex_postprocess.py`가 REVIEW 필수 front-matter와 §5.3 metadata를 누락함
- **severity**: major
- **target**: scripts/_codex_postprocess.py:69-84
- **detail**: REVIEW.template은 `severity`, `target`, `review_round`, `prior_review`, 그리고 `codex_meta.base_ref`, `included_paths`, `invoked_at`, `prompt_source`를 요구한다. postprocess는 이 중 다수를 쓰지 않는다. phases/04 Exit 기준의 “REVIEW 양식, codex_meta 채워짐”을 wrapper가 자동으로 만족시키지 못한다.
- **suggested_action**: wrapper에서 phase/slug/base/commit/uncommitted/prompt_source/included_paths/invoked_at을 postprocess 인자로 넘기고, postprocess가 template 필드를 모두 채우게 한다. `severity`/`target`은 prompt나 wrapper 옵션으로 명시 입력받아야 한다.
- **references**: templates/REVIEW.template.md:1-24, HARNESS.md:150-157, phases/04-cross-review.md:32

### Finding 21: config TOML parsing이 macOS 기본 Python에서 조용히 실패함
- **severity**: major
- **target**: scripts/codex-review.sh:31-57, scripts/codex-exec-review.sh:31-55, scripts/README.md:20-27
- **detail**: 현재 환경의 `python3`는 3.9.6이고 `tomllib`이 없다. `read_config()`는 ImportError를 stderr 숨김 후 default로 fallback한다. 결과적으로 `.harness/config.toml`의 `[reasoning] exec = "high"` 같은 dogfood 설정이 조용히 무시될 수 있다. README는 python 3.11+를 요구하지만 스크립트는 이를 검증하지 않는다.
- **suggested_action**: 시작 시 `python3 -c 'import tomllib'`를 명시 검증해 실패 시 actionable error를 내거나, `python3.11` 탐색/`tomli` fallback을 구현. fallback이 발생하면 stderr에 “config ignored”를 반드시 출력.
- **references**: .harness/config.toml, ADR-003, HARNESS.md §5.2

### Finding 22: review wrapper 인자 검증이 부족함
- **severity**: minor
- **target**: scripts/codex-review.sh:17-29, scripts/codex-exec-review.sh:15-24
- **detail**: `--phase`처럼 값이 필요한 옵션을 값 없이 주면 `set -u`의 `$2: unbound variable`로 종료한다. 또한 `--base`, `--commit`, `--uncommitted`를 함께 줘도 우선순위로 조용히 하나만 선택한다.
- **suggested_action**: `need_value()` helper를 추가하고, review source 옵션은 exactly one-of로 검증. 사용자 오류는 exit 2와 명확한 usage 메시지로 처리.
- **references**: scripts/codex-review.sh:72-78

### Finding 23: pre-review-gate가 “검사 0개”도 PASS로 만들 수 있음
- **severity**: major
- **target**: scripts/pre-review-gate.sh:11-50, phases/03-implement.md:30-39, phases/04-cross-review.md:5-10
- **detail**: 지원되는 toolchain 파일이 없거나 해당 명령이 설치되지 않은 프로젝트는 `ok=1` 그대로 `ALL PASS`가 된다. Phase 04 Entry의 pre-review-gate PASS가 실제 lint/typecheck/unit 검증을 의미하지 않을 수 있다.
- **suggested_action**: attempted check count를 추적하고 0개면 fail 또는 `--allow-no-checks` 명시 옵션을 요구. 하니스 self-build도 최소 `bash -n scripts/*.sh`, `_codex_postprocess.py` compile, markdown link/enum lint 정도를 Phase D 후보가 아니라 현재 gate smoke로 넣는 것을 검토.
- **references**: HARNESS.md §5.4, phases/03-implement.md:35, phases/04-cross-review.md:8

### Finding 24: `new-project.sh`가 project name/type을 TOML·sed에 escape 없이 삽입함
- **severity**: minor
- **target**: scripts/new-project.sh:50-79, scripts/new-project.sh:95-110
- **detail**: `NAME`/`TYPE`에 quote, slash, newline 등이 들어오면 `.harness/config.toml`, STATUS 치환, ADR-000 내용이 깨질 수 있다. 현재는 로컬 bootstrap이라 HC 위반은 아니지만 새 프로젝트 첫 산출물의 결정성을 해친다.
- **suggested_action**: project name/type 허용 문자를 제한하거나 Python TOML writer/JSON escaping을 사용. `TYPE`은 실제 `project-types/` 디렉토리 이름 또는 `_generic` enum으로 검증.
- **references**: scripts/new-project.sh:15-17

### Finding 25: Phase 02 autonomous 설명에 Phase A 전용 A.5가 남아 있음
- **severity**: minor
- **target**: phases/02-module-plan.md:35-38
- **detail**: autonomous Module Plan Exit 기준이 “A.5 통합 리뷰에서 사후 검증”이라고 한다. A.5는 하니스 self-build Phase A 전용 라운드라 일반 프로젝트의 Phase 02 규칙에 남으면 재사용 시 의미가 없다.
- **suggested_action**: “다음 정식 cross-review 또는 periodic audit에서 사후 검증”처럼 일반 phase 언어로 바꾸고, 하니스 self-build 특례는 STATUS/ADR-006에만 둔다.
- **references**: ADR-006, phases/README.md:33-45

### Finding 26: ADR template이 HARNESS §4.3 front-matter 규칙과 맞지 않음
- **severity**: minor
- **target**: templates/ADR.template.md:1-19, HARNESS.md:86-121
- **detail**: HARNESS §4.3은 `artifact: adr` 산출물의 YAML front-matter와 status enum을 표준으로 제시한다. ADR.template은 DECISIONS.md inline 형식만 제공하고 front-matter가 없다. `.harness/decisions/ADR-NNNN-*.md`로 분리될 때 표준을 따를 템플릿이 없다.
- **suggested_action**: ADR.template에 YAML front-matter를 추가하거나, “DECISIONS.md inline ADR은 front-matter 예외, standalone ADR은 별도 template 사용”이라고 명시.
- **references**: templates/README.md:9-15, HARNESS.md:92-117

## Part C — Security / HC violations
HC-7/HC-8/HC-9 직접 위반은 발견하지 못했다. `rm -f "$RAW"`는 `mktemp`로 만든 임시 파일 cleanup이라 HC-9 blocker로 보지 않는다. 외부 mutation(push/deploy/API write) 실행 경로도 현재 scripts 표면에서는 발견되지 않았다.

## Part D — Phase A verdict
- **ready_for_v0.5_tag**: no
- **ready_for_phase_B**: no
- **new_blockers**: 0
- **new_majors**: 6
- **new_minors**: 5
- **new_infos**: 0
- **rationale**: Phase A 구조 자체는 v0.5 후보에 가깝지만, SoT 충돌(§9/ADR-007/STATUS)과 review wrapper metadata 누락은 v0.5 태그 전에 고쳐야 한다. 특히 scripts는 앞으로 모든 formal review의 증거 생산 경로이므로, config parsing과 REVIEW front-matter 보존을 먼저 안정화해야 Phase B 산출물 리뷰가 재현 가능해진다.

## Assumptions
- Assumption A1: 이번 A.5 리뷰 결과는 최종적으로 `.harness/reviews/`에 저장될 예정이며, 현재 응답은 그 파일 내용으로 사용할 수 있는 REVIEW 본문이다.
- Assumption A2: 사용자 prompt의 HEAD `15bf6fb`가 현재 truth이고, STATUS.md의 `95ab860`은 stale handoff 정보다.

## Related artifacts read
- HARNESS.md v0.4
- CLAUDE.md, AGENTS.md
- STATUS.md, DECISIONS.md
- .gitignore, .harness/config.toml
- roles/README.md and 4 role files
- templates/README.md and 6 templates
- scripts/README.md, 4 shell scripts, `_codex_postprocess.py`
- phases/README.md and 7 phase files
- INBOX/README.md
- INBOX/processed/codex-feedback-20260525-seed-review.md
- INBOX/processed/codex-feedback-20260525-v0.3-review.md
