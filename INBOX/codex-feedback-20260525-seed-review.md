OpenAI Codex v0.132.0
--------
workdir: /Users/satgym/work/harness
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: xhigh
reasoning summaries: none
session id: 019e5ccc-e45e-7892-944d-5d61e4a976dc
--------
user
You are reviewing the seed documents of a Claude+Codex collaboration harness located at /Users/satgym/work/harness. Your default role is REVIEWER (see AGENTS.md).

Step 1 — Read these files in this exact order:
1. AGENTS.md
2. HARNESS.md
3. STATUS.md
4. DECISIONS.md
5. CLAUDE.md
6. INBOX/README.md

Step 2 — Evaluate:
- Internal consistency: do these files contradict each other?
- HARNESS.md completeness as a constitution: missing rules, ambiguous phase gates, weak Exit criteria, edge cases
- Whether AGENTS.md and CLAUDE.md sufficiently bootstrap a fresh session that has zero prior context
- Whether STATUS.md format supports clean session handoff (could a stranger pick up from STATUS alone?)
- Whether DECISIONS.md ADRs adequately and unambiguously capture the 5 user decisions
- Whether the INBOX channel design is workable in practice
- Things missing entirely (conflict resolution between Claude/Codex, postmortem flow, ADR superseding rules, security/secrets, cost guardrails, dogfood criteria, what counts as "Blueprint approved", etc.)
- Whether Korean+English mix in files will cause issues
- Whether the meta-bootstrap framing (harness builds itself) is fully consistent

Step 3 — Output a single review report in this STRICT format. Do not modify any files. Only output to stdout.

# Seed Document Review (v0.1)

## Summary
<one paragraph: overall impression>

## Findings

### Finding 1: <short title>
- severity: blocker | major | minor | nit | info
- target: <file:section-or-line>
- detail: <observation and reasoning>
- suggested_action: <concrete change>
- references: <files / ADR ids / section nums>

### Finding 2: ...
(repeat, numbered sequentially)

## Additional proposals (things missing entirely)
- <bullet>
- <bullet>

## Overall verdict
- ready_for_phase_A1: yes | no | yes_with_minor_fixes
- rationale: <one paragraph>

Begin now. Do not ask clarifying questions; make reasonable assumptions and label them as "Assumption: ..." inside the relevant finding.

codex
I’ll read the seed docs in the required order and keep this to a review report only. I won’t modify files.
exec
/bin/zsh -lc "sed -n '1,240p' AGENTS.md" in /Users/satgym/work/harness
 succeeded in 0ms:
# AGENTS.md — Codex 진입점

이 디렉토리는 **Claude+Codex 협업 하니스**를 빌드하는 작업장이다.
Codex의 기본 역할: **리뷰어(reviewer)** — 직접 코드 작성보다는 검토/지적/제안이 우선.

## 세션 시작 시 읽을 순서
1. [HARNESS.md](HARNESS.md) — 헌법, 절대 규칙, 페이즈 정의
2. [STATUS.md](STATUS.md) — 현재 진행 상황과 다음 액션
3. [DECISIONS.md](DECISIONS.md) — 결정 로그 (ADR)
4. 리뷰 대상이 명시되어 있다면 해당 산출물 (Blueprint / Module Plan / diff)

## Codex의 기본 역할: 리뷰어
- 직접 코드 작성/수정 제출은 **사용자가 명시 요청한 경우에만**
- 기본 출력 형식: REVIEW
  - 각 finding: `severity` (blocker | major | minor | nit), `위치`, `근거`, `제안`
  - 양식 파일이 만들어지면(`templates/REVIEW.template.md`) 그대로 따른다
- 검토 포인트:
  - Blueprint·Module Plan과의 일관성
  - 모듈 경계와 인터페이스 안정성
  - 테스트 가능성·관측 가능성
  - 보안·자원·예외 경로
  - 명세 누락, 모호한 가정
- 가정이 필요한 경우 명시: `Assumption: ...` (검증 후 확정/철회)

## 능동적 피드백 채널 — INBOX/
하니스 자체에 대한 개선 아이디어, 다음 Claude 세션이 알아야 할 사항, 리뷰 외 코멘트는 `INBOX/`에 파일로 남긴다.

- 파일명: `codex-feedback-YYYYMMDD-<short-slug>.md`
- 양식: [INBOX/README.md](INBOX/README.md) 참조

## Codex 호출 규약 (사용자/Claude가 사용하는 방식)
| 용도 | 명령 |
|---|---|
| 정식 cross-review (코드 변경) | `codex review --base <branch>` + 표준 PROMPT |
| 텍스트 검토 (Blueprint/Plan/ADR) | `codex exec -` + stdin PROMPT |
| 모델 지정 | `-c model="..."` (사용자의 `.harness/config.toml`에서 읽음) |

스크립트가 만들어지면 `scripts/codex-review.sh`가 표준 진입점.

## 절대 규칙
- 사용자가 명시 요청하지 않는 한 코드/문서를 직접 수정·커밋하지 말 것
- 리뷰는 결정적·재현 가능: 동일 입력에 동일 양식 출력
- HARNESS.md를 위반하는 결정/계획이 보이면 `severity: blocker`로 표시
- 자신의 한계/가정/불확실성을 숨기지 말 것 (명시할 것)

## 다른 세션의 흔적
- 가장 최근 STATUS.md 업데이트가 "by Claude"라면 Claude가 일했음 → 리뷰 모드로 진입
- 가장 최근 업데이트가 "by Codex"라면 이미 검토 결과를 남긴 것 → 중복 리뷰 금지, STATUS의 다음 액션 참조

exec
/bin/zsh -lc "sed -n '1,260p' HARNESS.md" in /Users/satgym/work/harness
 succeeded in 0ms:
# HARNESS.md — 하니스 헌법 (v0.1)

> 이 파일은 Claude와 Codex 모두가 따르는 **절대 규칙**과 **워크플로우 정의**다.
> 변경은 §6 "하니스 수정 절차"를 거쳐야 한다.

---

## 0. 메타-원칙

이 하니스는 자기 자신도 하니스 규칙으로 빌드한다 (메타 부트스트랩, dogfood).
하니스로 만든 프로젝트가 새 규칙/스킬이 필요해지면, 그것도 하니스를 사용해 만든다.

## 1. 절대 규칙 (Hard Constraints)

| # | 규칙 | 의미 |
|---|---|---|
| HC-1 | **Plan-First, Code-Late** | Blueprint 승인 전 코드 X. Module Plan 승인 전 해당 모듈 코드 X |
| HC-2 | **File-Persistent** | 모든 결정·계획·리뷰는 파일로 영속화. 대화 기억에 의존 금지 |
| HC-3 | **Drift-Aware** | phase 경계와 세션 시작 시 "지금 Blueprint와 일치하나?" 자가점검 |
| HC-4 | **Gate-Bound** | phase 간 이동은 해당 phase 문서의 Exit 기준을 만족해야 함 |
| HC-5 | **Role-Default** | Claude=구현자, Codex=리뷰어. 역할 스왑은 명시적 결정 + ADR |
| HC-6 | **Status-Updated** | 모든 작업 종료 시 STATUS.md 갱신. 생략 시 그 작업은 미완으로 간주 |

## 2. Strictness 모드

프로젝트의 `.harness/config.toml`에서 선택:

| 모드 | 사용자 승인이 필요한 것 |
|---|---|
| **strict** (디폴트) | Intake, Blueprint, **모든** Module Plan, 모든 ADR 변경, 하니스 자체 변경 |
| **balanced** | Blueprint, 새 ADR, 하니스 자체 변경. Module Plan은 Codex 리뷰로 갈음 |
| **autonomous** | Destructive 또는 외부 영향 작업(deploy, delete, external API mutation), 하니스 자체 변경 |

- 모든 모드에서 **하니스 자체 변경은 항상 사용자 승인** 필요.
- 하니스 자체 빌드(이 작업) = **strict** 모드.

## 3. 페이즈 (Workflow)

```
[00 Intake]    프로젝트 성격·제약·목표 식별 → project-type 선택
                ↓ 사용자 승인 (strict)
[01 Blueprint] 전체 밑그림: 모듈 경계 / 의존성 그래프 / 테스트 전략 / 리스크
                ↓ Codex 리뷰 → 사용자 승인 (모든 모드)
[02 ModulePlan] 다음 모듈의 인터페이스·계약·테스트를 먼저 정의
                ↓ Codex 리뷰 → (strict일 때만) 사용자 승인
[03 Implement] 코드 작성 (Claude)
                ↓ pre-review-gate: lint / typecheck / unit test 통과
[04 CrossReview] codex review --base <branch> → REVIEW 파일 생성
                ↓ Claude가 각 finding에 resolved/disputed/deferred로 응답·반영, 필요 시 재리뷰
[05 Integration] 모듈 결합 + 통합 테스트
                ↓
[06 Handoff]   STATUS.md 갱신 → 다음 모듈로 또는 종료
```

각 phase의 Exit 기준은 `phases/<phase>.md`에 상세 명시 (Phase A.4에서 작성 예정).

## 4. 산출물 표준 위치

### 하니스 자체 빌드 (이 레포)
| 산출물 | 위치 |
|---|---|
| 현황 | `STATUS.md` |
| 결정 로그 | `DECISIONS.md` (작아질 때까지) → 커지면 `decisions/ADR-NNNN-*.md`로 분리 |
| Codex 피드백 | `INBOX/`, 처리 후 `INBOX/processed/` |
| 리뷰 결과 | `.harness/reviews/<date>-<slug>.md` (Phase A.3 스크립트 도입 후) |

### 하니스로 만드는 프로젝트
| 산출물 | 위치 |
|---|---|
| 설정 | `.harness/config.toml` (strictness, 모델 등) |
| Blueprint | `.harness/docs/blueprint.md` |
| Module Plan | `.harness/docs/modules/<name>/plan.md` |
| 리뷰 | `.harness/reviews/<phase>-<date>-<slug>.md` |
| ADR | `.harness/decisions/ADR-NNNN-<slug>.md` |
| 현황 | `.harness/status.md` |
| 하니스 버전 pin | `.harness/VERSION-PIN` |

## 5. Codex 호출 규약

| 채널 | 명령 | 용도 |
|---|---|---|
| A (기본) | `scripts/codex-review.sh` → `codex review --base <branch>` | 코드 변경 cross-review |
| A2 | `scripts/codex-exec-review.sh` → `codex exec - < prompt` | 텍스트(Blueprint/Plan/ADR) 검토 |
| B (옵션) | `codex mcp-server` + Claude MCP 등록 | 대화 중 즉석 호출 |
| C (보조) | 사용자가 직접 별도 터미널에서 `codex` | 깊은 검토, 능동 INBOX 피드백 |

- 모델 선택: `.harness/config.toml`의 `[models]` 섹션에서. 코드 어디에도 모델명 하드코딩 금지.
  ```toml
  [models]
  review = "<사용자 지정>"
  exec   = "<사용자 지정>"
  ```
- 미설정 시 `codex` CLI 디폴트 사용.

## 6. 드리프트 감지 & 하니스 수정 절차

### 드리프트 신호
- Blueprint에 없는 모듈을 새로 만들고 있음
- 페이즈 게이트 통과 없이 다음 단계로 진입 시도
- Codex가 같은 종류 결함을 두 번 잡음 → 체크리스트 보강 신호
- 사용자가 같은 지적을 두 번 함 → 규칙 추가 신호
- HARNESS.md / STATUS.md / DECISIONS.md 와 실제 코드/문서 상태가 불일치

### 감지 시 절차
1. 현재 작업 일시 정지. STATUS.md에 드리프트 사실 + 신호 기록
2. `harness-amend` 진입: 무엇이/왜 어긋났는지 임시 노트 작성
3. 필요 시 ADR 추가 (DECISIONS.md)
4. 하니스 변경안 작성 → Codex 리뷰 → **사용자 승인** → 적용
5. 적용 후 원래 작업 재개. STATUS.md에 재개 시점 기록

## 7. 세션 핸드오프

모든 작업 종료 시 STATUS.md를 다음 형태로 갱신:
- 현재 phase
- 직전 완료 항목 (한 줄)
- 다음 액션 (누가 / 무엇을)
- 미해결 finding 목록
- INBOX 상태

다음 세션은 STATUS.md만 읽으면 즉시 이어받을 수 있어야 한다. 이걸 못 한다면 STATUS.md 양식부터 고친다.

## 8. 버전

- HARNESS.md 버전: **v0.1** (씨앗)
- 다음 마일스톤: v0.2 — Phase A 전체 완료 후 Codex 리뷰 반영본

exec
/bin/zsh -lc "sed -n '1,260p' CLAUDE.md" in /Users/satgym/work/harness
exec
/bin/zsh -lc "sed -n '1,240p' STATUS.md" in /Users/satgym/work/harness
exec
/bin/zsh -lc "sed -n '1,240p' INBOX/README.md" in /Users/satgym/work/harness
 succeeded in 0ms:
# CLAUDE.md — Claude 진입점

이 디렉토리는 **Claude+Codex 협업 하니스**를 빌드하는 작업장이다.
하니스 자체도 하니스의 규칙을 따른다 (메타 부트스트랩 / dogfood).

## 세션 시작 시 읽을 순서
1. [HARNESS.md](HARNESS.md) — 헌법, 절대 규칙, 페이즈 정의
2. [STATUS.md](STATUS.md) — 현재 어디까지 됐고 다음 액션은 무엇인지
3. [DECISIONS.md](DECISIONS.md) — 이미 내려진 결정들 (ADR)
4. [INBOX/](INBOX/) — `ls INBOX/`로 codex가 남긴 피드백 확인 (비어있을 수 있음)

위 4개를 안 읽고 작업 시작 금지.

## Claude의 기본 역할
- **구현자(implementer)**. 코드/문서를 직접 작성.
- 단, Codex의 리뷰 결과를 받아 반영하는 책임도 Claude에게 있음.
- Codex에게 리뷰를 의뢰할 때는 표준 스크립트(`scripts/codex-review.sh`, 추후 작성)를 통한다.

## 절대 규칙 (전체는 HARNESS.md 참조)
- Blueprint 승인 전 코드 작성 금지
- Module Plan 승인 전 해당 모듈 코드 작성 금지
- pre-review-gate(lint/typecheck/test) 통과 전 Codex 리뷰 요청 금지
- 하니스 자체 변경은 별도 절차 (HARNESS.md §6 "하니스 수정 절차")
- 모든 작업 종료 시 STATUS.md 갱신 (생략 금지)

## INBOX 처리 의무
- 세션 시작 시 `ls INBOX/` 확인
- 새 파일 발견 → STATUS.md "Open findings"에 항목 추가
- 처리 완료 후 파일 상단 `status`를 `resolved` 또는 `deferred(<이유>)`로 변경하고 `INBOX/processed/`로 이동

## 메모리 vs 프로젝트 문서
- 사용자 선호도/스타일: `~/.claude/.../memory/` (자동 메모리 시스템)
- 프로젝트 사실/결정/계획/리뷰: 이 디렉토리(하니스 빌드 중)의 파일들
- 둘은 섞지 않는다.

 succeeded in 0ms:
# INBOX — Codex 능동 피드백 채널

이 디렉토리는 **Codex가 비동기로 하니스/프로젝트에 의견을 남기는 채널**이다.

## 누가 무엇을 남기는가

- **Codex가** 이 디렉토리에 진입했을 때(사용자가 띄운 별도 codex 세션) 능동적으로 남기는 피드백
- 하니스 자체에 대한 개선 아이디어, 다음 Claude 세션이 알아야 할 사항, 정식 리뷰 외 코멘트
- 정식 cross-review 결과는 여기가 아니라 `.harness/reviews/`(Phase A.3 이후)에 저장

## 파일명 규칙

```
codex-feedback-YYYYMMDD-<short-slug>.md
```

예:
- `codex-feedback-20260525-blueprint-gap.md`
- `codex-feedback-20260526-strictness-edge-case.md`

## 양식 (front-matter 필수)

```markdown
---
date: 2026-05-25
author: codex
severity: blocker | major | minor | nit | info
target: <어떤 파일/phase/모듈에 대한 피드백인지>
status: open
---

## Summary
한 단락.

## Detail
관찰 / 근거 / 재현 경로.

## Suggested action
구체적 변경안 (가능하면 패치 형태나 문장 단위 수정안).

## References
- 파일:라인 / ADR 번호 / HARNESS.md 섹션
```

## Claude의 처리 의무

1. 세션 시작 시 `ls INBOX/` 실행 (디렉토리만 비어있는지 확인)
2. 새 피드백 파일 발견 → STATUS.md "Open findings"에 항목 추가, "INBOX" 카운트 갱신
3. 각 피드백 처리:
   - 반영 → 해당 파일 상단의 `status: open` → `status: resolved` 로 변경
   - 보류 → `status: deferred(<이유>)` 변경, STATUS의 Open findings에는 남김
   - 분쟁 → `status: disputed`, ADR로 결론 기록
4. 처리 끝난 파일은 `INBOX/processed/`로 이동 (시간 순으로 쌓임)

## 디렉토리 구조

```
INBOX/
├── README.md           ← 이 파일
├── *.md                ← 미처리 피드백
└── processed/          ← 처리 완료 (자동 생성)
    └── *.md
```

 succeeded in 0ms:
# STATUS

> 이 파일은 현재 작업의 단일 진실 출처(Single Source of Truth).
> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | **A — 골격 구축** (sub-phase A.0 진행 중) |
| Strictness | strict |
| Harness version | v0.1 (씨앗) |
| Last updated | 2026-05-25 by Claude |

## Roadmap

### Phase A — 골격 구축
- [x] **A.0** 사용자 5개 결정 수집 (DECISIONS.md ADR-001~005)
- [x] **A.0** 씨앗 문서 작성: CLAUDE.md, AGENTS.md, HARNESS.md, STATUS.md, DECISIONS.md, INBOX/README.md
- [ ] **A.1** `roles/` — claude-implementer.md, codex-reviewer.md, claude-reviewer.md(swap), codex-implementer.md(rare)
- [ ] **A.2** `templates/` — BLUEPRINT, MODULE-PLAN, REVIEW, ADR, POSTMORTEM, STATUS 양식
- [ ] **A.3** `scripts/` — codex-review.sh, codex-exec-review.sh, pre-review-gate.sh, new-project.sh
- [ ] **A.4** `phases/` — 00-intake ~ 06-handoff 각각 Exit 기준 명시
- [ ] **A.5** Phase A 전체 Codex 리뷰 → 반영 → HARNESS.md v0.2 태깅

### Phase B — 스킬 풀
- [ ] `skills/` 9종 (kickoff-project, plan-blueprint, plan-module, request-codex-review, apply-review, checkpoint-handoff, resume-session, drift-check, harness-amend)

### Phase C — 프로젝트 타입 템플릿 (web 우선)
- [ ] `project-types/_generic/`
- [ ] `project-types/web-service/` 깊이 작성
- [ ] 기타 타입은 실 필요 시 dogfood

### Phase D — 자기보호 메커니즘 정식화
- [ ] drift-check 자동화, harness-amend 절차, ADR/Postmortem 워크플로우, 충돌 조정 프로토콜

### Phase E — Dogfood
- [ ] `examples/`에 작은 웹 프로젝트(예: TODO API)를 하니스로 처음부터 굴림 → 발견된 결함 역반영
- [ ] git 레포 정식 출시 + VERSION 태깅 + 설치 가이드

## Next action

- **사용자**: 씨앗 문서 6개 검토 (CLAUDE/AGENTS/HARNESS/STATUS/DECISIONS/INBOX). 의견 있으면 알려주기. OK면 "A.1 진행" 지시.
- **Claude (이 세션)**: 사용자 지시 대기.
- **Codex**: 사용자가 별도 세션을 띄워 씨앗 문서를 검토하고 싶다면 INBOX에 피드백 남기는 것 환영.

## Open findings

- 없음

## INBOX

- 0 unread (`ls INBOX/`로 확인)

## Notes / 메모

- 메타 부트스트랩 중 — 하니스가 하니스를 빌드하는 단계.
- 사용자 보유 모델: codex5.3 + gpt-5.5 (정확한 모델 식별자는 사용자가 추후 명시 시 ADR-003 업데이트 + `.harness/config.toml` 작성).
- git init은 Phase A 완료 시점에 사용자 확인 받고 수행 예정 (현재 untracked).

exec
/bin/zsh -lc "sed -n '1,260p' DECISIONS.md" in /Users/satgym/work/harness
 succeeded in 0ms:
# DECISIONS — Architecture Decision Records

> 새 ADR은 **위에** 추가. 기존 ADR을 뒤집을 땐 새 ADR을 쓰고 기존을 `Status: superseded by ADR-NNN`으로 변경.
> 양식: Context / Decision / Consequences.
> 파일이 100개 이상으로 늘면 `decisions/ADR-NNNN-*.md`로 분리.

---

## ADR-005 — 프로젝트 타입 우선순위

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스는 다양한 프로젝트 타입(web, firmware, ai-model, cli, data-pipeline 등)을 지원해야 한다. 모두 동시에 깊이 만들면 빌드 부담이 크고 dogfood 검증이 어렵다.

**Decision**: `project-types/web-service/`를 가장 깊이 만든다. 나머지 타입은 `project-types/_generic/` 골격만 제공하고, 실제 필요할 때 dogfood로 빌드한다.

**Consequences**:
- 첫 실사용은 웹 프로젝트가 될 가능성이 높음.
- 다른 타입은 일반 페이즈 절차로만 가능(특화 체크리스트 없음).
- 펌웨어/AI 모델 같은 도메인 특화 검증은 그 시점에 별도 ADR + Phase C 확장으로 다룸.

---

## ADR-004 — Strictness 모드 도입

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스가 자율적으로 얼마나 진행할 수 있어야 하는지는 신뢰 수준에 따라 다르다. 초기엔 모든 plan을 사용자가 검토해야 안전하지만, 검증된 후엔 자동화를 늘리고 싶다.

**Decision**: 세 모드 정의 — `strict` / `balanced` / `autonomous`. 프로젝트별 `.harness/config.toml`에서 선택. 디폴트 `strict`. 하니스 자체 변경은 모든 모드에서 항상 사용자 승인.

**Consequences**:
- 각 phase 문서의 Exit 기준에 "어느 모드에서 사용자 승인 필요한지" 명시 필요.
- 하니스 자체 빌드는 strict 모드로 진행.
- 모드 전환 자체가 ADR 대상 (신뢰가 검증되면 사용자가 명시적으로 balanced로 전환).

---

## ADR-003 — Codex 모델/계정은 사용자 설정

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 사용자마다 접근 가능한 codex/openai 모델이 다르다. 사용자는 현재 codex5.3 + gpt-5.5까지 사용 가능하며 추후 업그레이드 예정.

**Decision**: 모델명은 코드/스크립트에 하드코딩 금지. `.harness/config.toml`의 `[models]` 섹션에서 `review`, `exec` 모델을 각각 지정한다. 미설정 시 `codex` CLI 디폴트 사용.

```toml
# .harness/config.toml 예시 (사용자가 채움)
[models]
review = "gpt-5.5"
exec   = "codex5.3"
```

**Consequences**:
- 정확한 모델 식별자는 사용자가 채워야 함 (예: 위 문자열이 codex CLI가 실제로 받는 모델명과 일치해야 함).
- 모델 업그레이드 시 ADR-003a 같은 후속 노트로 변경 사항 기록.
- 스크립트는 `-c model="$(yq '.models.review' .harness/config.toml)"` 같은 식으로 주입.

---

## ADR-002 — Codex 개입은 파일 기반 비동기를 기본으로

**Date**: 2026-05-25 · **Status**: accepted

**Context**: VSCode 환경 + Claude가 주 대화 상대. Codex 개입 방식 후보: (A) 파일 기반 비동기 호출 (B) MCP 즉석 호출 (C) 사용자가 별도 codex 세션 운영.

**Decision**: A를 기본 채널로. B는 후순위(설정 복잡·컨텍스트 비용 큼). C는 `AGENTS.md` + `INBOX/` 컨벤션으로 자연스럽게 지원.

**Consequences**:
- 모든 리뷰가 파일로 남아 재현/감사 가능.
- 즉석 협의 필요 시 사용자가 직접 별도 codex 세션을 띄울 수 있고, codex는 `AGENTS.md`로 자기 역할을 자동 인지.
- MCP는 v1.0 이후 옵션으로 검토.

---

## ADR-001 — 하니스는 git repo로 배포, 메타-부트스트랩

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스 배포 방식 후보: (a) 단일 SoT + 심볼릭링크 (b) 프로젝트마다 복사 (c) git repo로 만들어 clone/submodule.

**Decision**: (c) git repo. 프로젝트는 하니스 repo를 reference. 프로젝트별 적응적 규칙/스킬은 하니스 자체를 사용해 만든다 (메타 부트스트랩).

**Consequences**:
- 하니스 자체에 버전 필요 (`VERSION` 파일, Phase A.3에서 생성).
- 프로젝트는 `.harness/VERSION-PIN`으로 사용한 버전 기록.
- 하니스 업그레이드 시 마이그레이션 가이드 필요 (Phase D 항목).
- 이 디렉토리는 결국 GitHub 레포가 될 후보 — 파일 작성 시 그 점을 의식 (라이선스, README, .gitignore 등은 Phase E에서).

codex
I’ve got the contents. I’m going back through them with line numbers in the requested order so the findings can point to exact locations.
exec
/bin/zsh -lc "nl -ba AGENTS.md | sed -n '1,220p'" in /Users/satgym/work/harness
 succeeded in 0ms:
     1	# AGENTS.md — Codex 진입점
     2	
     3	이 디렉토리는 **Claude+Codex 협업 하니스**를 빌드하는 작업장이다.
     4	Codex의 기본 역할: **리뷰어(reviewer)** — 직접 코드 작성보다는 검토/지적/제안이 우선.
     5	
     6	## 세션 시작 시 읽을 순서
     7	1. [HARNESS.md](HARNESS.md) — 헌법, 절대 규칙, 페이즈 정의
     8	2. [STATUS.md](STATUS.md) — 현재 진행 상황과 다음 액션
     9	3. [DECISIONS.md](DECISIONS.md) — 결정 로그 (ADR)
    10	4. 리뷰 대상이 명시되어 있다면 해당 산출물 (Blueprint / Module Plan / diff)
    11	
    12	## Codex의 기본 역할: 리뷰어
    13	- 직접 코드 작성/수정 제출은 **사용자가 명시 요청한 경우에만**
    14	- 기본 출력 형식: REVIEW
    15	  - 각 finding: `severity` (blocker | major | minor | nit), `위치`, `근거`, `제안`
    16	  - 양식 파일이 만들어지면(`templates/REVIEW.template.md`) 그대로 따른다
    17	- 검토 포인트:
    18	  - Blueprint·Module Plan과의 일관성
    19	  - 모듈 경계와 인터페이스 안정성
    20	  - 테스트 가능성·관측 가능성
    21	  - 보안·자원·예외 경로
    22	  - 명세 누락, 모호한 가정
    23	- 가정이 필요한 경우 명시: `Assumption: ...` (검증 후 확정/철회)
    24	
    25	## 능동적 피드백 채널 — INBOX/
    26	하니스 자체에 대한 개선 아이디어, 다음 Claude 세션이 알아야 할 사항, 리뷰 외 코멘트는 `INBOX/`에 파일로 남긴다.
    27	
    28	- 파일명: `codex-feedback-YYYYMMDD-<short-slug>.md`
    29	- 양식: [INBOX/README.md](INBOX/README.md) 참조
    30	
    31	## Codex 호출 규약 (사용자/Claude가 사용하는 방식)
    32	| 용도 | 명령 |
    33	|---|---|
    34	| 정식 cross-review (코드 변경) | `codex review --base <branch>` + 표준 PROMPT |
    35	| 텍스트 검토 (Blueprint/Plan/ADR) | `codex exec -` + stdin PROMPT |
    36	| 모델 지정 | `-c model="..."` (사용자의 `.harness/config.toml`에서 읽음) |
    37	
    38	스크립트가 만들어지면 `scripts/codex-review.sh`가 표준 진입점.
    39	
    40	## 절대 규칙
    41	- 사용자가 명시 요청하지 않는 한 코드/문서를 직접 수정·커밋하지 말 것
    42	- 리뷰는 결정적·재현 가능: 동일 입력에 동일 양식 출력
    43	- HARNESS.md를 위반하는 결정/계획이 보이면 `severity: blocker`로 표시
    44	- 자신의 한계/가정/불확실성을 숨기지 말 것 (명시할 것)
    45	
    46	## 다른 세션의 흔적
    47	- 가장 최근 STATUS.md 업데이트가 "by Claude"라면 Claude가 일했음 → 리뷰 모드로 진입
    48	- 가장 최근 업데이트가 "by Codex"라면 이미 검토 결과를 남긴 것 → 중복 리뷰 금지, STATUS의 다음 액션 참조

exec
/bin/zsh -lc "nl -ba HARNESS.md | sed -n '1,280p'" in /Users/satgym/work/harness
 succeeded in 0ms:
     1	# HARNESS.md — 하니스 헌법 (v0.1)
     2	
     3	> 이 파일은 Claude와 Codex 모두가 따르는 **절대 규칙**과 **워크플로우 정의**다.
     4	> 변경은 §6 "하니스 수정 절차"를 거쳐야 한다.
     5	
     6	---
     7	
     8	## 0. 메타-원칙
     9	
    10	이 하니스는 자기 자신도 하니스 규칙으로 빌드한다 (메타 부트스트랩, dogfood).
    11	하니스로 만든 프로젝트가 새 규칙/스킬이 필요해지면, 그것도 하니스를 사용해 만든다.
    12	
    13	## 1. 절대 규칙 (Hard Constraints)
    14	
    15	| # | 규칙 | 의미 |
    16	|---|---|---|
    17	| HC-1 | **Plan-First, Code-Late** | Blueprint 승인 전 코드 X. Module Plan 승인 전 해당 모듈 코드 X |
    18	| HC-2 | **File-Persistent** | 모든 결정·계획·리뷰는 파일로 영속화. 대화 기억에 의존 금지 |
    19	| HC-3 | **Drift-Aware** | phase 경계와 세션 시작 시 "지금 Blueprint와 일치하나?" 자가점검 |
    20	| HC-4 | **Gate-Bound** | phase 간 이동은 해당 phase 문서의 Exit 기준을 만족해야 함 |
    21	| HC-5 | **Role-Default** | Claude=구현자, Codex=리뷰어. 역할 스왑은 명시적 결정 + ADR |
    22	| HC-6 | **Status-Updated** | 모든 작업 종료 시 STATUS.md 갱신. 생략 시 그 작업은 미완으로 간주 |
    23	
    24	## 2. Strictness 모드
    25	
    26	프로젝트의 `.harness/config.toml`에서 선택:
    27	
    28	| 모드 | 사용자 승인이 필요한 것 |
    29	|---|---|
    30	| **strict** (디폴트) | Intake, Blueprint, **모든** Module Plan, 모든 ADR 변경, 하니스 자체 변경 |
    31	| **balanced** | Blueprint, 새 ADR, 하니스 자체 변경. Module Plan은 Codex 리뷰로 갈음 |
    32	| **autonomous** | Destructive 또는 외부 영향 작업(deploy, delete, external API mutation), 하니스 자체 변경 |
    33	
    34	- 모든 모드에서 **하니스 자체 변경은 항상 사용자 승인** 필요.
    35	- 하니스 자체 빌드(이 작업) = **strict** 모드.
    36	
    37	## 3. 페이즈 (Workflow)
    38	
    39	```
    40	[00 Intake]    프로젝트 성격·제약·목표 식별 → project-type 선택
    41	                ↓ 사용자 승인 (strict)
    42	[01 Blueprint] 전체 밑그림: 모듈 경계 / 의존성 그래프 / 테스트 전략 / 리스크
    43	                ↓ Codex 리뷰 → 사용자 승인 (모든 모드)
    44	[02 ModulePlan] 다음 모듈의 인터페이스·계약·테스트를 먼저 정의
    45	                ↓ Codex 리뷰 → (strict일 때만) 사용자 승인
    46	[03 Implement] 코드 작성 (Claude)
    47	                ↓ pre-review-gate: lint / typecheck / unit test 통과
    48	[04 CrossReview] codex review --base <branch> → REVIEW 파일 생성
    49	                ↓ Claude가 각 finding에 resolved/disputed/deferred로 응답·반영, 필요 시 재리뷰
    50	[05 Integration] 모듈 결합 + 통합 테스트
    51	                ↓
    52	[06 Handoff]   STATUS.md 갱신 → 다음 모듈로 또는 종료
    53	```
    54	
    55	각 phase의 Exit 기준은 `phases/<phase>.md`에 상세 명시 (Phase A.4에서 작성 예정).
    56	
    57	## 4. 산출물 표준 위치
    58	
    59	### 하니스 자체 빌드 (이 레포)
    60	| 산출물 | 위치 |
    61	|---|---|
    62	| 현황 | `STATUS.md` |
    63	| 결정 로그 | `DECISIONS.md` (작아질 때까지) → 커지면 `decisions/ADR-NNNN-*.md`로 분리 |
    64	| Codex 피드백 | `INBOX/`, 처리 후 `INBOX/processed/` |
    65	| 리뷰 결과 | `.harness/reviews/<date>-<slug>.md` (Phase A.3 스크립트 도입 후) |
    66	
    67	### 하니스로 만드는 프로젝트
    68	| 산출물 | 위치 |
    69	|---|---|
    70	| 설정 | `.harness/config.toml` (strictness, 모델 등) |
    71	| Blueprint | `.harness/docs/blueprint.md` |
    72	| Module Plan | `.harness/docs/modules/<name>/plan.md` |
    73	| 리뷰 | `.harness/reviews/<phase>-<date>-<slug>.md` |
    74	| ADR | `.harness/decisions/ADR-NNNN-<slug>.md` |
    75	| 현황 | `.harness/status.md` |
    76	| 하니스 버전 pin | `.harness/VERSION-PIN` |
    77	
    78	## 5. Codex 호출 규약
    79	
    80	| 채널 | 명령 | 용도 |
    81	|---|---|---|
    82	| A (기본) | `scripts/codex-review.sh` → `codex review --base <branch>` | 코드 변경 cross-review |
    83	| A2 | `scripts/codex-exec-review.sh` → `codex exec - < prompt` | 텍스트(Blueprint/Plan/ADR) 검토 |
    84	| B (옵션) | `codex mcp-server` + Claude MCP 등록 | 대화 중 즉석 호출 |
    85	| C (보조) | 사용자가 직접 별도 터미널에서 `codex` | 깊은 검토, 능동 INBOX 피드백 |
    86	
    87	- 모델 선택: `.harness/config.toml`의 `[models]` 섹션에서. 코드 어디에도 모델명 하드코딩 금지.
    88	  ```toml
    89	  [models]
    90	  review = "<사용자 지정>"
    91	  exec   = "<사용자 지정>"
    92	  ```
    93	- 미설정 시 `codex` CLI 디폴트 사용.
    94	
    95	## 6. 드리프트 감지 & 하니스 수정 절차
    96	
    97	### 드리프트 신호
    98	- Blueprint에 없는 모듈을 새로 만들고 있음
    99	- 페이즈 게이트 통과 없이 다음 단계로 진입 시도
   100	- Codex가 같은 종류 결함을 두 번 잡음 → 체크리스트 보강 신호
   101	- 사용자가 같은 지적을 두 번 함 → 규칙 추가 신호
   102	- HARNESS.md / STATUS.md / DECISIONS.md 와 실제 코드/문서 상태가 불일치
   103	
   104	### 감지 시 절차
   105	1. 현재 작업 일시 정지. STATUS.md에 드리프트 사실 + 신호 기록
   106	2. `harness-amend` 진입: 무엇이/왜 어긋났는지 임시 노트 작성
   107	3. 필요 시 ADR 추가 (DECISIONS.md)
   108	4. 하니스 변경안 작성 → Codex 리뷰 → **사용자 승인** → 적용
   109	5. 적용 후 원래 작업 재개. STATUS.md에 재개 시점 기록
   110	
   111	## 7. 세션 핸드오프
   112	
   113	모든 작업 종료 시 STATUS.md를 다음 형태로 갱신:
   114	- 현재 phase
   115	- 직전 완료 항목 (한 줄)
   116	- 다음 액션 (누가 / 무엇을)
   117	- 미해결 finding 목록
   118	- INBOX 상태
   119	
   120	다음 세션은 STATUS.md만 읽으면 즉시 이어받을 수 있어야 한다. 이걸 못 한다면 STATUS.md 양식부터 고친다.
   121	
   122	## 8. 버전
   123	
   124	- HARNESS.md 버전: **v0.1** (씨앗)
   125	- 다음 마일스톤: v0.2 — Phase A 전체 완료 후 Codex 리뷰 반영본

exec
/bin/zsh -lc "nl -ba STATUS.md | sed -n '1,240p'" in /Users/satgym/work/harness
 succeeded in 0ms:
     1	# STATUS
     2	
     3	> 이 파일은 현재 작업의 단일 진실 출처(Single Source of Truth).
     4	> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.
     5	
     6	## Current
     7	
     8	| 항목 | 값 |
     9	|---|---|
    10	| Project | 하니스 자체 빌드 (메타 부트스트랩) |
    11	| Phase | **A — 골격 구축** (sub-phase A.0 진행 중) |
    12	| Strictness | strict |
    13	| Harness version | v0.1 (씨앗) |
    14	| Last updated | 2026-05-25 by Claude |
    15	
    16	## Roadmap
    17	
    18	### Phase A — 골격 구축
    19	- [x] **A.0** 사용자 5개 결정 수집 (DECISIONS.md ADR-001~005)
    20	- [x] **A.0** 씨앗 문서 작성: CLAUDE.md, AGENTS.md, HARNESS.md, STATUS.md, DECISIONS.md, INBOX/README.md
    21	- [ ] **A.1** `roles/` — claude-implementer.md, codex-reviewer.md, claude-reviewer.md(swap), codex-implementer.md(rare)
    22	- [ ] **A.2** `templates/` — BLUEPRINT, MODULE-PLAN, REVIEW, ADR, POSTMORTEM, STATUS 양식
    23	- [ ] **A.3** `scripts/` — codex-review.sh, codex-exec-review.sh, pre-review-gate.sh, new-project.sh
    24	- [ ] **A.4** `phases/` — 00-intake ~ 06-handoff 각각 Exit 기준 명시
    25	- [ ] **A.5** Phase A 전체 Codex 리뷰 → 반영 → HARNESS.md v0.2 태깅
    26	
    27	### Phase B — 스킬 풀
    28	- [ ] `skills/` 9종 (kickoff-project, plan-blueprint, plan-module, request-codex-review, apply-review, checkpoint-handoff, resume-session, drift-check, harness-amend)
    29	
    30	### Phase C — 프로젝트 타입 템플릿 (web 우선)
    31	- [ ] `project-types/_generic/`
    32	- [ ] `project-types/web-service/` 깊이 작성
    33	- [ ] 기타 타입은 실 필요 시 dogfood
    34	
    35	### Phase D — 자기보호 메커니즘 정식화
    36	- [ ] drift-check 자동화, harness-amend 절차, ADR/Postmortem 워크플로우, 충돌 조정 프로토콜
    37	
    38	### Phase E — Dogfood
    39	- [ ] `examples/`에 작은 웹 프로젝트(예: TODO API)를 하니스로 처음부터 굴림 → 발견된 결함 역반영
    40	- [ ] git 레포 정식 출시 + VERSION 태깅 + 설치 가이드
    41	
    42	## Next action
    43	
    44	- **사용자**: 씨앗 문서 6개 검토 (CLAUDE/AGENTS/HARNESS/STATUS/DECISIONS/INBOX). 의견 있으면 알려주기. OK면 "A.1 진행" 지시.
    45	- **Claude (이 세션)**: 사용자 지시 대기.
    46	- **Codex**: 사용자가 별도 세션을 띄워 씨앗 문서를 검토하고 싶다면 INBOX에 피드백 남기는 것 환영.
    47	
    48	## Open findings
    49	
    50	- 없음
    51	
    52	## INBOX
    53	
    54	- 0 unread (`ls INBOX/`로 확인)
    55	
    56	## Notes / 메모
    57	
    58	- 메타 부트스트랩 중 — 하니스가 하니스를 빌드하는 단계.
    59	- 사용자 보유 모델: codex5.3 + gpt-5.5 (정확한 모델 식별자는 사용자가 추후 명시 시 ADR-003 업데이트 + `.harness/config.toml` 작성).
    60	- git init은 Phase A 완료 시점에 사용자 확인 받고 수행 예정 (현재 untracked).

exec
/bin/zsh -lc "nl -ba DECISIONS.md | sed -n '1,280p'" in /Users/satgym/work/harness
 succeeded in 0ms:
     1	# DECISIONS — Architecture Decision Records
     2	
     3	> 새 ADR은 **위에** 추가. 기존 ADR을 뒤집을 땐 새 ADR을 쓰고 기존을 `Status: superseded by ADR-NNN`으로 변경.
     4	> 양식: Context / Decision / Consequences.
     5	> 파일이 100개 이상으로 늘면 `decisions/ADR-NNNN-*.md`로 분리.
     6	
     7	---
     8	
     9	## ADR-005 — 프로젝트 타입 우선순위
    10	
    11	**Date**: 2026-05-25 · **Status**: accepted
    12	
    13	**Context**: 하니스는 다양한 프로젝트 타입(web, firmware, ai-model, cli, data-pipeline 등)을 지원해야 한다. 모두 동시에 깊이 만들면 빌드 부담이 크고 dogfood 검증이 어렵다.
    14	
    15	**Decision**: `project-types/web-service/`를 가장 깊이 만든다. 나머지 타입은 `project-types/_generic/` 골격만 제공하고, 실제 필요할 때 dogfood로 빌드한다.
    16	
    17	**Consequences**:
    18	- 첫 실사용은 웹 프로젝트가 될 가능성이 높음.
    19	- 다른 타입은 일반 페이즈 절차로만 가능(특화 체크리스트 없음).
    20	- 펌웨어/AI 모델 같은 도메인 특화 검증은 그 시점에 별도 ADR + Phase C 확장으로 다룸.
    21	
    22	---
    23	
    24	## ADR-004 — Strictness 모드 도입
    25	
    26	**Date**: 2026-05-25 · **Status**: accepted
    27	
    28	**Context**: 하니스가 자율적으로 얼마나 진행할 수 있어야 하는지는 신뢰 수준에 따라 다르다. 초기엔 모든 plan을 사용자가 검토해야 안전하지만, 검증된 후엔 자동화를 늘리고 싶다.
    29	
    30	**Decision**: 세 모드 정의 — `strict` / `balanced` / `autonomous`. 프로젝트별 `.harness/config.toml`에서 선택. 디폴트 `strict`. 하니스 자체 변경은 모든 모드에서 항상 사용자 승인.
    31	
    32	**Consequences**:
    33	- 각 phase 문서의 Exit 기준에 "어느 모드에서 사용자 승인 필요한지" 명시 필요.
    34	- 하니스 자체 빌드는 strict 모드로 진행.
    35	- 모드 전환 자체가 ADR 대상 (신뢰가 검증되면 사용자가 명시적으로 balanced로 전환).
    36	
    37	---
    38	
    39	## ADR-003 — Codex 모델/계정은 사용자 설정
    40	
    41	**Date**: 2026-05-25 · **Status**: accepted
    42	
    43	**Context**: 사용자마다 접근 가능한 codex/openai 모델이 다르다. 사용자는 현재 codex5.3 + gpt-5.5까지 사용 가능하며 추후 업그레이드 예정.
    44	
    45	**Decision**: 모델명은 코드/스크립트에 하드코딩 금지. `.harness/config.toml`의 `[models]` 섹션에서 `review`, `exec` 모델을 각각 지정한다. 미설정 시 `codex` CLI 디폴트 사용.
    46	
    47	```toml
    48	# .harness/config.toml 예시 (사용자가 채움)
    49	[models]
    50	review = "gpt-5.5"
    51	exec   = "codex5.3"
    52	```
    53	
    54	**Consequences**:
    55	- 정확한 모델 식별자는 사용자가 채워야 함 (예: 위 문자열이 codex CLI가 실제로 받는 모델명과 일치해야 함).
    56	- 모델 업그레이드 시 ADR-003a 같은 후속 노트로 변경 사항 기록.
    57	- 스크립트는 `-c model="$(yq '.models.review' .harness/config.toml)"` 같은 식으로 주입.
    58	
    59	---
    60	
    61	## ADR-002 — Codex 개입은 파일 기반 비동기를 기본으로
    62	
    63	**Date**: 2026-05-25 · **Status**: accepted
    64	
    65	**Context**: VSCode 환경 + Claude가 주 대화 상대. Codex 개입 방식 후보: (A) 파일 기반 비동기 호출 (B) MCP 즉석 호출 (C) 사용자가 별도 codex 세션 운영.
    66	
    67	**Decision**: A를 기본 채널로. B는 후순위(설정 복잡·컨텍스트 비용 큼). C는 `AGENTS.md` + `INBOX/` 컨벤션으로 자연스럽게 지원.
    68	
    69	**Consequences**:
    70	- 모든 리뷰가 파일로 남아 재현/감사 가능.
    71	- 즉석 협의 필요 시 사용자가 직접 별도 codex 세션을 띄울 수 있고, codex는 `AGENTS.md`로 자기 역할을 자동 인지.
    72	- MCP는 v1.0 이후 옵션으로 검토.
    73	
    74	---
    75	
    76	## ADR-001 — 하니스는 git repo로 배포, 메타-부트스트랩
    77	
    78	**Date**: 2026-05-25 · **Status**: accepted
    79	
    80	**Context**: 하니스 배포 방식 후보: (a) 단일 SoT + 심볼릭링크 (b) 프로젝트마다 복사 (c) git repo로 만들어 clone/submodule.
    81	
    82	**Decision**: (c) git repo. 프로젝트는 하니스 repo를 reference. 프로젝트별 적응적 규칙/스킬은 하니스 자체를 사용해 만든다 (메타 부트스트랩).
    83	
    84	**Consequences**:
    85	- 하니스 자체에 버전 필요 (`VERSION` 파일, Phase A.3에서 생성).
    86	- 프로젝트는 `.harness/VERSION-PIN`으로 사용한 버전 기록.
    87	- 하니스 업그레이드 시 마이그레이션 가이드 필요 (Phase D 항목).
    88	- 이 디렉토리는 결국 GitHub 레포가 될 후보 — 파일 작성 시 그 점을 의식 (라이선스, README, .gitignore 등은 Phase E에서).

exec
/bin/zsh -lc "nl -ba CLAUDE.md | sed -n '1,220p'" in /Users/satgym/work/harness
 succeeded in 0ms:
     1	# CLAUDE.md — Claude 진입점
     2	
     3	이 디렉토리는 **Claude+Codex 협업 하니스**를 빌드하는 작업장이다.
     4	하니스 자체도 하니스의 규칙을 따른다 (메타 부트스트랩 / dogfood).
     5	
     6	## 세션 시작 시 읽을 순서
     7	1. [HARNESS.md](HARNESS.md) — 헌법, 절대 규칙, 페이즈 정의
     8	2. [STATUS.md](STATUS.md) — 현재 어디까지 됐고 다음 액션은 무엇인지
     9	3. [DECISIONS.md](DECISIONS.md) — 이미 내려진 결정들 (ADR)
    10	4. [INBOX/](INBOX/) — `ls INBOX/`로 codex가 남긴 피드백 확인 (비어있을 수 있음)
    11	
    12	위 4개를 안 읽고 작업 시작 금지.
    13	
    14	## Claude의 기본 역할
    15	- **구현자(implementer)**. 코드/문서를 직접 작성.
    16	- 단, Codex의 리뷰 결과를 받아 반영하는 책임도 Claude에게 있음.
    17	- Codex에게 리뷰를 의뢰할 때는 표준 스크립트(`scripts/codex-review.sh`, 추후 작성)를 통한다.
    18	
    19	## 절대 규칙 (전체는 HARNESS.md 참조)
    20	- Blueprint 승인 전 코드 작성 금지
    21	- Module Plan 승인 전 해당 모듈 코드 작성 금지
    22	- pre-review-gate(lint/typecheck/test) 통과 전 Codex 리뷰 요청 금지
    23	- 하니스 자체 변경은 별도 절차 (HARNESS.md §6 "하니스 수정 절차")
    24	- 모든 작업 종료 시 STATUS.md 갱신 (생략 금지)
    25	
    26	## INBOX 처리 의무
    27	- 세션 시작 시 `ls INBOX/` 확인
    28	- 새 파일 발견 → STATUS.md "Open findings"에 항목 추가
    29	- 처리 완료 후 파일 상단 `status`를 `resolved` 또는 `deferred(<이유>)`로 변경하고 `INBOX/processed/`로 이동
    30	
    31	## 메모리 vs 프로젝트 문서
    32	- 사용자 선호도/스타일: `~/.claude/.../memory/` (자동 메모리 시스템)
    33	- 프로젝트 사실/결정/계획/리뷰: 이 디렉토리(하니스 빌드 중)의 파일들
    34	- 둘은 섞지 않는다.

exec
/bin/zsh -lc "nl -ba INBOX/README.md | sed -n '1,240p'" in /Users/satgym/work/harness
 succeeded in 0ms:
     1	# INBOX — Codex 능동 피드백 채널
     2	
     3	이 디렉토리는 **Codex가 비동기로 하니스/프로젝트에 의견을 남기는 채널**이다.
     4	
     5	## 누가 무엇을 남기는가
     6	
     7	- **Codex가** 이 디렉토리에 진입했을 때(사용자가 띄운 별도 codex 세션) 능동적으로 남기는 피드백
     8	- 하니스 자체에 대한 개선 아이디어, 다음 Claude 세션이 알아야 할 사항, 정식 리뷰 외 코멘트
     9	- 정식 cross-review 결과는 여기가 아니라 `.harness/reviews/`(Phase A.3 이후)에 저장
    10	
    11	## 파일명 규칙
    12	
    13	```
    14	codex-feedback-YYYYMMDD-<short-slug>.md
    15	```
    16	
    17	예:
    18	- `codex-feedback-20260525-blueprint-gap.md`
    19	- `codex-feedback-20260526-strictness-edge-case.md`
    20	
    21	## 양식 (front-matter 필수)
    22	
    23	```markdown
    24	---
    25	date: 2026-05-25
    26	author: codex
    27	severity: blocker | major | minor | nit | info
    28	target: <어떤 파일/phase/모듈에 대한 피드백인지>
    29	status: open
    30	---
    31	
    32	## Summary
    33	한 단락.
    34	
    35	## Detail
    36	관찰 / 근거 / 재현 경로.
    37	
    38	## Suggested action
    39	구체적 변경안 (가능하면 패치 형태나 문장 단위 수정안).
    40	
    41	## References
    42	- 파일:라인 / ADR 번호 / HARNESS.md 섹션
    43	```
    44	
    45	## Claude의 처리 의무
    46	
    47	1. 세션 시작 시 `ls INBOX/` 실행 (디렉토리만 비어있는지 확인)
    48	2. 새 피드백 파일 발견 → STATUS.md "Open findings"에 항목 추가, "INBOX" 카운트 갱신
    49	3. 각 피드백 처리:
    50	   - 반영 → 해당 파일 상단의 `status: open` → `status: resolved` 로 변경
    51	   - 보류 → `status: deferred(<이유>)` 변경, STATUS의 Open findings에는 남김
    52	   - 분쟁 → `status: disputed`, ADR로 결론 기록
    53	4. 처리 끝난 파일은 `INBOX/processed/`로 이동 (시간 순으로 쌓임)
    54	
    55	## 디렉토리 구조
    56	
    57	```
    58	INBOX/
    59	├── README.md           ← 이 파일
    60	├── *.md                ← 미처리 피드백
    61	└── processed/          ← 처리 완료 (자동 생성)
    62	    └── *.md
    63	```

codex
# Seed Document Review (v0.1)

## Summary
The seed set is coherent enough to show the intended Claude=implementer / Codex=reviewer operating model, but it is not yet internally safe as a constitution. The biggest issue is bootstrap deadlock: HARNESS.md requires Blueprint/phase gates before proceeding, while the phase gate documents and approval definitions are explicitly deferred to later work. A fresh session can orient itself, but STATUS.md and the approval/ADR/INBOX mechanics need tighter, auditable rules before Phase A.1 should proceed.

## Findings

### Finding 1: Bootstrap rules deadlock Phase A
- severity: blocker
- target: HARNESS.md:17, HARNESS.md:20, HARNESS.md:55, STATUS.md:21-25
- detail: HARNESS.md requires Plan-First and Gate-Bound execution, but the phase Exit criteria that make gates satisfiable are deferred until Phase A.4. That means A.1, A.2, and A.3 have no constitutional gate they can legally pass. Assumption: seed docs are intended to be reviewed before A.1, not treated as an exception outside the harness.
- suggested_action: Add an explicit “seed bootstrap exception” with temporary Exit criteria for A.0-A.4, or reorder A.4 before A.1 so gates exist before other phase work proceeds.
- references: HC-1, HC-4, HARNESS.md §3, STATUS.md Roadmap

### Finding 2: Blueprint approval is required but undefined
- severity: major
- target: HARNESS.md:17, HARNESS.md:42-45
- detail: The workflow depends on “Blueprint 승인,” but no file says what counts as approved: explicit user phrase, timestamped status field, ADR, review file, signed-off checksum, or STATUS entry. Without an auditable approval record, later sessions cannot tell whether a gate was actually passed.
- suggested_action: Define an approval record format: artifact path, version/hash or date, approver, approval mode, approval timestamp, and scope. Store it in STATUS.md or the artifact front matter.
- references: HARNESS.md HC-1, HARNESS.md §3, ADR-004

### Finding 3: Strictness table contradicts workflow
- severity: major
- target: HARNESS.md:28-32, HARNESS.md:42-45
- detail: The strictness table says autonomous mode only requires approval for destructive/external-impact work and harness changes, but the workflow says Blueprint approval is required in all modes. The same ambiguity may later affect Module Plans and ADR changes.
- suggested_action: Make the table and phase diagram use the same approval matrix. If Blueprint is always user-approved, list it under autonomous too.
- references: HARNESS.md §2, HARNESS.md §3, ADR-004

### Finding 4: STATUS says A.0 is both done and in progress
- severity: major
- target: STATUS.md:11, STATUS.md:18-25, STATUS.md:42-46
- detail: Current phase says “sub-phase A.0 진행 중,” but both A.0 checklist items are complete and Next action is external seed review before A.1. A stranger can infer the state, but STATUS alone does not clearly say whether A.0 is awaiting approval, completed, or blocked by review.
- suggested_action: Add explicit fields such as `Current gate`, `Blocked on`, `Last completed`, and `Approval needed`. Set phase to something like `A.0 complete; awaiting seed-doc review/approval`.
- references: HARNESS.md §7, STATUS.md Current/Roadmap/Next action

### Finding 5: Codex fresh-session bootstrap omits INBOX check
- severity: minor
- target: AGENTS.md:6-10, AGENTS.md:25-29, CLAUDE.md:6-10
- detail: CLAUDE.md requires checking INBOX at session start, but AGENTS.md does not. A fresh Codex session may miss prior async feedback or duplicate an already captured finding.
- suggested_action: Add INBOX/README.md and unread INBOX check to AGENTS.md session-start order, or explicitly state Codex only reads INBOX when asked to leave async feedback.
- references: AGENTS.md §세션 시작, CLAUDE.md §세션 시작, INBOX/README.md

### Finding 6: INBOX write permission conflicts with Codex reviewer default
- severity: major
- target: AGENTS.md:13, AGENTS.md:25-29, AGENTS.md:40-41, INBOX/README.md:7-9
- detail: Codex is told not to modify code/docs unless explicitly requested, but INBOX is also described as a place Codex may proactively write feedback. This needs a clear exception, otherwise Codex cannot know whether writing an INBOX file is allowed.
- suggested_action: Define INBOX writes as either explicitly permitted reviewer output, or require user instruction before Codex creates files. Include the exception in AGENTS.md absolute rules.
- references: AGENTS.md §Codex 역할, AGENTS.md §절대 규칙, INBOX/README.md

### Finding 7: Dispute and conflict resolution are under-specified
- severity: major
- target: HARNESS.md:48-49, INBOX/README.md:49-53
- detail: Findings can be resolved, disputed, or deferred, but no rule says who arbitrates Claude/Codex disagreement, when user decision is required, how long deferral may persist, or whether disputed findings block phase exit.
- suggested_action: Add a conflict protocol: owner, required evidence, user escalation threshold, ADR requirement, and whether each status blocks the next phase.
- references: HARNESS.md §3, INBOX/README.md §Claude 처리 의무, STATUS.md Open findings

### Finding 8: ADR lifecycle has weak superseding/version rules
- severity: minor
- target: DECISIONS.md:3-5, DECISIONS.md:54-57
- detail: DECISIONS.md defines superseding, but ADR-003 suggests “ADR-003a,” which conflicts with the numeric ADR pattern. It also lacks fields for `Supersedes`, `Superseded by`, `Amends`, and approval evidence.
- suggested_action: Standardize ADR IDs and lifecycle metadata before templates are created. Use new numeric ADRs for amendments and add explicit lifecycle fields.
- references: DECISIONS.md header, ADR-003

### Finding 9: STATUS handoff is not yet stranger-proof
- severity: major
- target: STATUS.md:16-60, HARNESS.md:111-120
- detail: HARNESS.md says STATUS alone must let the next session continue, but current STATUS requires reading other files to know the 5 decisions, approval state, active gate, artifact paths, and whether the seed docs are accepted. The roadmap is useful, but it is not a complete handoff.
- suggested_action: Add compact sections for `Active gate`, `Required reads`, `Approved artifacts`, `Decision summary`, `Open blockers`, and `Resume command / next prompt`.
- references: HARNESS.md §7, STATUS.md

### Finding 10: INBOX unread counting is not operationally precise
- severity: minor
- target: STATUS.md:52-54, INBOX/README.md:47-53, INBOX/README.md:55-63
- detail: STATUS says “0 unread (`ls INBOX/`로 확인),” but `ls INBOX/` will show README.md and maybe processed/. The rule needs an exact definition of unread feedback files.
- suggested_action: Define unread as `INBOX/codex-feedback-*.md` with `status: open`, excluding README.md and `processed/`. Later scripts can enforce this.
- references: STATUS.md INBOX, INBOX/README.md §디렉토리 구조

### Finding 11: Security, secrets, and external effects are not constitutional rules
- severity: major
- target: HARNESS.md:13-35, HARNESS.md:95-109
- detail: Security appears only as a Codex review point in AGENTS.md, and external-impact work appears only in autonomous mode. There is no hard rule for secrets, credentials, network calls, generated tokens, logs, or destructive commands across all modes.
- suggested_action: Add hard constraints for secrets handling, external API mutation, deploy/delete operations, credential redaction, and required user approval.
- references: HARNESS.md §1-2, AGENTS.md:17-22

### Finding 12: Korean/English mix is workable but needs canonical enums
- severity: info
- target: all seed docs
- detail: The bilingual prose is understandable, but machine-facing states mix Korean labels and English enums. This is acceptable for humans, but scripts/templates will need stable canonical values.
- suggested_action: Keep prose bilingual if desired, but define canonical enum strings for phase, severity, status, role, strictness, and approval state.
- references: AGENTS.md review format, STATUS.md tables, INBOX front matter

## Additional proposals (things missing entirely)
- Define Phase A bootstrap policy explicitly: what can be built before full Blueprint/Module Plan templates exist.
- Add postmortem triggers: repeated drift, escaped blocker, failed review loop, or broken handoff.
- Add cost guardrails: model tier defaults, max review scope, when to ask before expensive deep reviews.
- Add dogfood success criteria for Phase E: minimum project size, required artifacts, failure capture, and promotion criteria for v1.0.
- Add branch/git policy: when git init happens, branch naming, review base, commit ownership, and dirty worktree rules.
- Add artifact front matter standards for Blueprint, Module Plan, Review, ADR, and STATUS.
- Add “review determinism” inputs: exact base ref, command, model config source, and included files.

## Overall verdict
- ready_for_phase_A1: no
- rationale: The direction is sound, but the current constitution blocks its own next steps because phase gates and approval definitions are deferred. Fix the bootstrap exception or temporary gates, align strictness approval rules, and make STATUS/INBOX handoff mechanics precise before starting A.1.
tokens used
79,748
# Seed Document Review (v0.1)

## Summary
The seed set is coherent enough to show the intended Claude=implementer / Codex=reviewer operating model, but it is not yet internally safe as a constitution. The biggest issue is bootstrap deadlock: HARNESS.md requires Blueprint/phase gates before proceeding, while the phase gate documents and approval definitions are explicitly deferred to later work. A fresh session can orient itself, but STATUS.md and the approval/ADR/INBOX mechanics need tighter, auditable rules before Phase A.1 should proceed.

## Findings

### Finding 1: Bootstrap rules deadlock Phase A
- severity: blocker
- target: HARNESS.md:17, HARNESS.md:20, HARNESS.md:55, STATUS.md:21-25
- detail: HARNESS.md requires Plan-First and Gate-Bound execution, but the phase Exit criteria that make gates satisfiable are deferred until Phase A.4. That means A.1, A.2, and A.3 have no constitutional gate they can legally pass. Assumption: seed docs are intended to be reviewed before A.1, not treated as an exception outside the harness.
- suggested_action: Add an explicit “seed bootstrap exception” with temporary Exit criteria for A.0-A.4, or reorder A.4 before A.1 so gates exist before other phase work proceeds.
- references: HC-1, HC-4, HARNESS.md §3, STATUS.md Roadmap

### Finding 2: Blueprint approval is required but undefined
- severity: major
- target: HARNESS.md:17, HARNESS.md:42-45
- detail: The workflow depends on “Blueprint 승인,” but no file says what counts as approved: explicit user phrase, timestamped status field, ADR, review file, signed-off checksum, or STATUS entry. Without an auditable approval record, later sessions cannot tell whether a gate was actually passed.
- suggested_action: Define an approval record format: artifact path, version/hash or date, approver, approval mode, approval timestamp, and scope. Store it in STATUS.md or the artifact front matter.
- references: HARNESS.md HC-1, HARNESS.md §3, ADR-004

### Finding 3: Strictness table contradicts workflow
- severity: major
- target: HARNESS.md:28-32, HARNESS.md:42-45
- detail: The strictness table says autonomous mode only requires approval for destructive/external-impact work and harness changes, but the workflow says Blueprint approval is required in all modes. The same ambiguity may later affect Module Plans and ADR changes.
- suggested_action: Make the table and phase diagram use the same approval matrix. If Blueprint is always user-approved, list it under autonomous too.
- references: HARNESS.md §2, HARNESS.md §3, ADR-004

### Finding 4: STATUS says A.0 is both done and in progress
- severity: major
- target: STATUS.md:11, STATUS.md:18-25, STATUS.md:42-46
- detail: Current phase says “sub-phase A.0 진행 중,” but both A.0 checklist items are complete and Next action is external seed review before A.1. A stranger can infer the state, but STATUS alone does not clearly say whether A.0 is awaiting approval, completed, or blocked by review.
- suggested_action: Add explicit fields such as `Current gate`, `Blocked on`, `Last completed`, and `Approval needed`. Set phase to something like `A.0 complete; awaiting seed-doc review/approval`.
- references: HARNESS.md §7, STATUS.md Current/Roadmap/Next action

### Finding 5: Codex fresh-session bootstrap omits INBOX check
- severity: minor
- target: AGENTS.md:6-10, AGENTS.md:25-29, CLAUDE.md:6-10
- detail: CLAUDE.md requires checking INBOX at session start, but AGENTS.md does not. A fresh Codex session may miss prior async feedback or duplicate an already captured finding.
- suggested_action: Add INBOX/README.md and unread INBOX check to AGENTS.md session-start order, or explicitly state Codex only reads INBOX when asked to leave async feedback.
- references: AGENTS.md §세션 시작, CLAUDE.md §세션 시작, INBOX/README.md

### Finding 6: INBOX write permission conflicts with Codex reviewer default
- severity: major
- target: AGENTS.md:13, AGENTS.md:25-29, AGENTS.md:40-41, INBOX/README.md:7-9
- detail: Codex is told not to modify code/docs unless explicitly requested, but INBOX is also described as a place Codex may proactively write feedback. This needs a clear exception, otherwise Codex cannot know whether writing an INBOX file is allowed.
- suggested_action: Define INBOX writes as either explicitly permitted reviewer output, or require user instruction before Codex creates files. Include the exception in AGENTS.md absolute rules.
- references: AGENTS.md §Codex 역할, AGENTS.md §절대 규칙, INBOX/README.md

### Finding 7: Dispute and conflict resolution are under-specified
- severity: major
- target: HARNESS.md:48-49, INBOX/README.md:49-53
- detail: Findings can be resolved, disputed, or deferred, but no rule says who arbitrates Claude/Codex disagreement, when user decision is required, how long deferral may persist, or whether disputed findings block phase exit.
- suggested_action: Add a conflict protocol: owner, required evidence, user escalation threshold, ADR requirement, and whether each status blocks the next phase.
- references: HARNESS.md §3, INBOX/README.md §Claude 처리 의무, STATUS.md Open findings

### Finding 8: ADR lifecycle has weak superseding/version rules
- severity: minor
- target: DECISIONS.md:3-5, DECISIONS.md:54-57
- detail: DECISIONS.md defines superseding, but ADR-003 suggests “ADR-003a,” which conflicts with the numeric ADR pattern. It also lacks fields for `Supersedes`, `Superseded by`, `Amends`, and approval evidence.
- suggested_action: Standardize ADR IDs and lifecycle metadata before templates are created. Use new numeric ADRs for amendments and add explicit lifecycle fields.
- references: DECISIONS.md header, ADR-003

### Finding 9: STATUS handoff is not yet stranger-proof
- severity: major
- target: STATUS.md:16-60, HARNESS.md:111-120
- detail: HARNESS.md says STATUS alone must let the next session continue, but current STATUS requires reading other files to know the 5 decisions, approval state, active gate, artifact paths, and whether the seed docs are accepted. The roadmap is useful, but it is not a complete handoff.
- suggested_action: Add compact sections for `Active gate`, `Required reads`, `Approved artifacts`, `Decision summary`, `Open blockers`, and `Resume command / next prompt`.
- references: HARNESS.md §7, STATUS.md

### Finding 10: INBOX unread counting is not operationally precise
- severity: minor
- target: STATUS.md:52-54, INBOX/README.md:47-53, INBOX/README.md:55-63
- detail: STATUS says “0 unread (`ls INBOX/`로 확인),” but `ls INBOX/` will show README.md and maybe processed/. The rule needs an exact definition of unread feedback files.
- suggested_action: Define unread as `INBOX/codex-feedback-*.md` with `status: open`, excluding README.md and `processed/`. Later scripts can enforce this.
- references: STATUS.md INBOX, INBOX/README.md §디렉토리 구조

### Finding 11: Security, secrets, and external effects are not constitutional rules
- severity: major
- target: HARNESS.md:13-35, HARNESS.md:95-109
- detail: Security appears only as a Codex review point in AGENTS.md, and external-impact work appears only in autonomous mode. There is no hard rule for secrets, credentials, network calls, generated tokens, logs, or destructive commands across all modes.
- suggested_action: Add hard constraints for secrets handling, external API mutation, deploy/delete operations, credential redaction, and required user approval.
- references: HARNESS.md §1-2, AGENTS.md:17-22

### Finding 12: Korean/English mix is workable but needs canonical enums
- severity: info
- target: all seed docs
- detail: The bilingual prose is understandable, but machine-facing states mix Korean labels and English enums. This is acceptable for humans, but scripts/templates will need stable canonical values.
- suggested_action: Keep prose bilingual if desired, but define canonical enum strings for phase, severity, status, role, strictness, and approval state.
- references: AGENTS.md review format, STATUS.md tables, INBOX front matter

## Additional proposals (things missing entirely)
- Define Phase A bootstrap policy explicitly: what can be built before full Blueprint/Module Plan templates exist.
- Add postmortem triggers: repeated drift, escaped blocker, failed review loop, or broken handoff.
- Add cost guardrails: model tier defaults, max review scope, when to ask before expensive deep reviews.
- Add dogfood success criteria for Phase E: minimum project size, required artifacts, failure capture, and promotion criteria for v1.0.
- Add branch/git policy: when git init happens, branch naming, review base, commit ownership, and dirty worktree rules.
- Add artifact front matter standards for Blueprint, Module Plan, Review, ADR, and STATUS.
- Add “review determinism” inputs: exact base ref, command, model config source, and included files.

## Overall verdict
- ready_for_phase_A1: no
- rationale: The direction is sound, but the current constitution blocks its own next steps because phase gates and approval definitions are deferred. Fix the bootstrap exception or temporary gates, align strictness approval rules, and make STATUS/INBOX handoff mechanics precise before starting A.1.
