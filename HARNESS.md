# HARNESS.md — 하니스 헌법 (v0.4)

> 이 파일은 Claude와 Codex 모두가 따르는 **절대 규칙**과 **워크플로우 정의**다.
> 변경은 §6 "하니스 수정 절차"를 거쳐야 한다.
> **v0.3 → v0.4**: A.0g micro-patch — F13/F14/F15 정리. 변경 내역은 §8 참조.

---

## 0. 메타-원칙

이 하니스는 자기 자신도 하니스 규칙으로 빌드한다 (메타 부트스트랩, dogfood).
다만 §9 "Bootstrap exception"이 정의하는 임시 게이트가 Phase A 동안 적용된다.

## 1. 절대 규칙 (Hard Constraints)

| # | 규칙 | 의미 |
|---|---|---|
| HC-1 | **Plan-First, Code-Late** | Blueprint 승인 전 코드 X. Module Plan 승인 전 해당 모듈 코드 X |
| HC-2 | **File-Persistent** | 모든 결정·계획·리뷰는 파일로 영속화. 대화 기억에 의존 금지 |
| HC-3 | **Drift-Aware** | phase 경계와 세션 시작 시 "지금 Blueprint와 일치하나?" 자가점검 |
| HC-4 | **Gate-Bound** | phase 간 이동은 해당 phase의 Exit 기준 만족 필수 (Phase A 동안은 §9 임시 게이트) |
| HC-5 | **Role-Default** | Claude=구현자, Codex=리뷰어. 역할 스왑은 명시적 결정 + ADR |
| HC-6 | **Status-Updated** | 모든 작업 종료 시 STATUS.md 갱신 (생략 시 그 작업은 미완으로 간주) |
| HC-7 | **Secrets-Redacted** | 시크릿/자격증명/PII는 모든 산출물·로그·리뷰에서 즉시 redact. 어떤 모드에서도 평문 저장 금지 |
| HC-8 | **External-Effects-Gated** | 외부 영향 mutation(deploy, 외부 API write, message send, push to remote)은 **모든 모드에서 사용자 승인** |
| HC-9 | **Destructive-Confirmed** | Destructive 작업(rm/drop/truncate/force-push/branch -D/reset --hard 등)은 **모든 모드에서 사용자 승인** |

> HC-7/HC-8/HC-9는 strictness 모드와 무관하게 항상 적용된다.

## 2. Strictness 모드

프로젝트의 `.harness/config.toml`에서 선택. **Blueprint 승인은 항상 사용자 필수**, 하니스 자체 변경도 항상 사용자 승인. 모드는 그 외 단계가 사용자 승인 대상인지를 결정한다.

| 모드 | 사용자 승인 항목 (HC-7/8/9 외) |
|---|---|
| **strict** (디폴트) | Intake, **Blueprint**, **모든** Module Plan, 모든 ADR, 하니스 자체 변경 |
| **balanced** | Intake, **Blueprint**, 새 ADR, 하니스 자체 변경. Module Plan은 Codex 리뷰로 갈음 |
| **autonomous** | **Blueprint**, 하니스 자체 변경 |

- 하니스 자체 빌드(현재 작업) = **strict** 모드.
- 모드 변경 자체가 ADR 대상.

## 3. 페이즈 (Workflow)

```
[00 Intake]    프로젝트 성격·제약·목표 식별 → project-type 선택
                ↓ 사용자 승인 (strict, balanced)
[01 Blueprint] 전체 밑그림: 모듈 경계 / 의존성 그래프 / 테스트 전략 / 리스크
                ↓ Codex 리뷰 → 사용자 승인 (모든 모드)
[02 ModulePlan] 다음 모듈의 인터페이스·계약·테스트를 먼저 정의
                ↓ Codex 리뷰 → 사용자 승인 (strict only)
[03 Implement] 코드 작성 (Claude)
                ↓ pre-review-gate: lint / typecheck / unit test 통과
[04 CrossReview] codex review --base <branch> → REVIEW 파일 생성
                ↓ Claude가 각 finding에 resolved/disputed/deferred로 응답·반영, 필요 시 재리뷰
[05 Integration] 모듈 결합 + 통합 테스트
                ↓
[06 Handoff]   STATUS.md 갱신 → 다음 모듈로 또는 종료
```

각 phase Exit 기준은 `phases/<phase>.md`에 상세 명시 (Phase A.4에서 작성 예정). 그 전까지는 §9 임시 게이트 적용.

## 4. 산출물 표준 위치 & Front-matter 표준

### 4.1 표준 위치 (하니스 자체 빌드 = 이 레포)
| 산출물 | 위치 |
|---|---|
| 현황 | `STATUS.md` |
| 결정 로그 | `DECISIONS.md` (→ 향후 `decisions/ADR-NNNN-*.md`로 분리 가능) |
| Codex 피드백 | `INBOX/`, 처리 후 `INBOX/processed/` |
| 리뷰 결과 | `.harness/reviews/<date>-<slug>.md` (Phase A.3 스크립트 도입 후) |
| Postmortem | `postmortems/YYYY-MM-DD-<slug>.md` (발생 시) |

### 4.2 표준 위치 (하니스로 만드는 프로젝트)
| 산출물 | 위치 |
|---|---|
| 설정 | `.harness/config.toml` |
| Blueprint | `.harness/docs/blueprint.md` |
| Module Plan | `.harness/docs/modules/<name>/plan.md` |
| 리뷰 | `.harness/reviews/<phase>-<date>-<slug>.md` |
| ADR | `.harness/decisions/ADR-NNNN-<slug>.md` |
| 현황 | `.harness/status.md` |
| Postmortem | `.harness/postmortems/YYYY-MM-DD-<slug>.md` |
| 하니스 버전 pin | `.harness/VERSION-PIN` |

### 4.3 Artifact front-matter 표준

다음 산출물 타입은 YAML front-matter로 메타데이터를 보유한다 (Phase A.2 `templates/`가 산출물별 필수/선택 필드를 확정):

```yaml
---
artifact: blueprint | module_plan | review | adr | status | postmortem | harness_doc | inbox_feedback
version: vX.Y                # 또는 'sha256:<hash>'
date: 2026-05-25
author: claude | codex | user
status: <artifact-specific enum, 아래 참조>
approval:                    # 승인된 경우만
  approver: user | codex-review | claude-self-test
  approved_at: 2026-05-25T11:03
  mode: strict | balanced | autonomous
  scope: <text>
supersedes: <id, optional>   # 예: ADR-003
amends: <id, optional>
references: [<file_or_id>, ...]
deferred_reason: <text, optional>   # status=deferred일 때만 사용
---
```

### Artifact-specific status enum

`status` 값은 산출물 타입별로 분리된다 (Phase A.2 templates에서 정식 확정):

| artifact | 허용 status |
|---|---|
| `blueprint`, `module_plan` | `draft \| approved \| superseded \| rejected` |
| `adr` | `proposed \| accepted \| superseded \| rejected` |
| `review`, `inbox_feedback` | `open \| resolved \| deferred \| disputed` |
| `postmortem` | `open \| resolved` |
| `status`, `harness_doc` | front-matter 불필요 (본문 상단 버전 표기로 대체) |

`status=deferred`인 경우 동일 front-matter의 `deferred_reason` 필드에 사유를 *분리* 기록한다. `status: deferred(<이유>)` 같은 결합 표기는 금지 (canonical 위반).

- HARNESS.md, AGENTS.md, CLAUDE.md, DECISIONS.md, INBOX/README.md 자체는 본문 상단에 버전 텍스트로 보유 — front-matter 의무 없음.
- STATUS.md는 본문 첫 표(Current)가 front-matter 역할 대신.

## 5. Codex 호출 규약 (+ Review determinism + Cost guardrails)

### 5.1 채널
| 채널 | 명령 | 용도 |
|---|---|---|
| A (기본) | `scripts/codex-review.sh` → `codex review --base <branch>` | 코드 변경 cross-review |
| A2 | `scripts/codex-exec-review.sh` → `codex exec - < prompt` | 텍스트(Blueprint/Plan/ADR) 검토 |
| B (옵션) | `codex mcp-server` + Claude MCP 등록 | 대화 중 즉석 호출 |
| C (보조) | 사용자가 별도 터미널에서 `codex` | 깊은 검토, 능동 INBOX 피드백 |

### 5.2 모델 설정
`.harness/config.toml`:
```toml
[models]
review = "<사용자 지정>"
exec   = "<사용자 지정>"
[reasoning]
review = "high"   # 디폴트
exec   = "medium" # 디폴트
[git]
base_branch = "main"
```
코드/스크립트 어디에도 모델명 하드코딩 금지.

### 5.3 Review determinism (재현성)
모든 codex 호출 결과 파일 상단에는 다음 메타정보를 보존:
- `codex_version` / `model` / `provider` / `session_id`
- `workdir` / `base_ref` (review의 경우) / `included_paths`
- `sandbox_policy` / `reasoning_effort`
- `invoked_at` (ISO 8601) / `prompt_source` (파일 경로 또는 "stdin")

codex의 비대화형 출력은 자동으로 헤더에 일부 메타를 포함한다. Phase A.3 스크립트가 표준 front-matter로 변환한다.

### 5.4 Cost guardrails
- **기본 reasoning_effort**: 텍스트 검토 `medium`, 정식 cross-review `high`. `xhigh`는 사용자 명시 요청 시만
- **Review scope 상한**: 한 호출이 100 파일 또는 5,000줄을 초과하면 사용자 확인 (분할 권장)
- **모델 tier**: 디폴트는 `.harness/config.toml`의 review 모델. 상위 tier 사용은 사용자 명시 요청 시만
- **재리뷰 빈도**: 동일 산출물 cross-review는 변경 시에만. 3회 초과 시 사용자 확인 + drift 점검
- **세션 토큰 누적**: codex 응답 헤더의 `tokens used`를 STATUS의 Notes에 누적 기록

## 6. 드리프트 감지·수정 절차 & Postmortem triggers

### 6.1 드리프트 신호
- Blueprint에 없는 모듈을 새로 만들고 있음
- 페이즈 게이트 통과 없이 다음 단계 진입 시도
- Codex가 같은 종류 결함을 두 번 잡음 → 체크리스트 보강 신호
- 사용자가 같은 지적을 두 번 함 → 규칙 추가 신호
- HARNESS / STATUS / DECISIONS와 실제 디렉토리 상태가 불일치

### 6.2 드리프트 감지 시 절차
1. 현재 작업 일시 정지. STATUS.md에 드리프트 사실 + 신호 기록
2. `harness-amend` 진입: 무엇이/왜 어긋났는지 임시 노트 작성
3. 필요 시 ADR 추가
4. 하니스 변경안 작성 → Codex 리뷰 → **사용자 승인** → 적용
5. 적용 후 원래 작업 재개. STATUS.md에 재개 시점 기록

### 6.3 Postmortem triggers
Postmortem(`postmortems/YYYY-MM-DD-<slug>.md`) 작성 의무가 발동되는 사건:
- **반복 드리프트** — 동일 종류 드리프트가 한 phase 내 2회 이상
- **escaped blocker** — Codex 리뷰가 놓친 blocker가 나중에 발견됨
- **failed review loop** — 같은 finding이 resolved 처리 후 재발견됨
- **broken handoff** — 새 세션이 STATUS.md만으로 이어받지 못함
- **HC-7/8/9 위반** — 시크릿 노출, 외부 mutation 발생, destructive 사고

### 6.4 Postmortem 양식
```
이벤트 / 영향 / 근본 원인 / 즉시 조치 / 하니스 변경안 (또는 ADR 링크) / 검증 방법 / 사후 확인 일정
```
Postmortem은 새 ADR 또는 HARNESS 변경으로 연결되어야 닫힘 (`status: resolved`).

## 7. 세션 핸드오프 & STATUS 양식 (stranger-proof)

STATUS.md는 다음 섹션을 **모두** 포함해야 한다 (없으면 양식 위반 → 보강 필요):

1. **Current** — Project / Phase / Active sub-phase / Strictness / Harness version / Last updated
2. **Active gate** — 현재 막힌 게이트 / Blocked on / Approval needed
3. **Required reads** — 이 세션 시작 시 반드시 읽을 파일 목록
4. **Approved artifacts** — 각 항목의 approval record
5. **Decision summary** — 누적 ADR 한 줄 요약
6. **Roadmap** — Phase별 체크박스
7. **Next action** — 누가 / 무엇을
8. **Open findings** — 미해결 finding (출처 명시)
9. **INBOX** — unread 카운트 (`INBOX/codex-feedback-*.md` with `status: open`)
10. **Notes** — 기타 메모 (누적 토큰 등)

### Approval record format
```yaml
- artifact: <상대 경로>
  version_or_hash: "v0.2"
  approver: user | codex-review | claude-self-test
  mode: strict | balanced | autonomous
  approved_at: 2026-05-25T15:30
  scope: <어디까지 승인되는지>
```
승인 없이 다음 phase로 이동 금지 (HC-4).

다음 세션은 **STATUS.md만 읽으면** 즉시 이어받을 수 있어야 한다.

## 8. 버전 이력

- **v0.1** (2026-05-25): 초기 6개 문서 골격
- **v0.2** (2026-05-25): Codex seed-review 5개 핵심 finding 반영 — HC-7/8/9 신설(F11), Strictness 통일(F3), §7 STATUS 양식 + Approval record(F2/F9), §9 Bootstrap exception(F1), §5 Review determinism(추가 제안 #7)
- **v0.3** (2026-05-25): A.0e 통합 — F7 분쟁 프로토콜(§11), Postmortem triggers(§6.3-6.4), Cost guardrails(§5.4), Dogfood criteria(§10), Branch/git policy(§12), Artifact front-matter 표준(§4.3)
- **v0.4** (2026-05-25, 본 파일): A.0g micro-patch — F13 §12.2 base branch 모순 해소, F14 §4.3 artifact-specific status enum 분리 + `deferred_reason` 필드 신설, F15 §9 임시 게이트가 §11 disputed 처리 cross-ref
- v0.5 (예정): Phase A.1~A.5 완료 통합 후 정식 cross-review 반영

## 9. Bootstrap exception (Phase A 한정) — **DEPRECATED**

> **Status**: deprecated since 2026-05-25 by [ADR-007](DECISIONS.md). Phase A.4 완료([phases/](phases/) 정식 문서)로 자동 폐기. 모든 phase 진행은 `phases/<phase>.md`의 정식 Exit 기준을 따른다.
>
> 본 §9는 history record로 유지. HARNESS v0.5 (A.5 통합 cross-review 후)에서 archival 섹션 또는 별도 보관소로 이동 검토.

Phase A의 sub-phase 진행 동안엔 정식 Blueprint/Module Plan/phases 양식이 아직 없으므로, HC-1/HC-4의 정식 게이트를 다음 **임시 게이트**로 대체:

### 임시 게이트 Exit 기준 (Phase A 동안만 유효)
A.x 완료 후 다음 조건을 모두 만족하면 A.(x+1) 진입 가능:
1. 본 sub-phase 산출물이 디렉토리에 모두 존재
2. Codex review를 받음 (codex exec, REVIEW 양식)
3. Blocker findings는 모두 `resolved` 또는 사용자가 명시 승인한 `deferred`
4. STATUS.md의 *Approved artifacts*에 본 sub-phase 결과가 등재 (사용자 승인 표시)
5. STATUS.md의 *Active gate*가 다음 sub-phase를 가리키도록 갱신
6. **Disputed findings는 §11에 따라 처리**. `severity ∈ {blocker, major}`로 disputed인 항목이 있으면 A.(x+1) 진입 차단 — 사용자 결정 필요

### 폐기 시점
Phase A.4 (`phases/` 정식 문서) 완성 후 §9는 **자동 폐기**된다. 폐기는 다음 ADR로 명문화.

## 10. Phase E — Dogfood 성공 기준

Phase E의 Exit / 승격 기준:

- **최소 프로젝트 규모**: 모듈 ≥3개, Blueprint + Module Plan + cross-review ≥1회 완료
- **필수 산출물**: Blueprint, Module Plans (per module), Reviews, ADRs (≥3), STATUS가 끝까지 stranger-proof 유지, 발생한 Postmortem은 모두 `resolved`
- **결함 캡처**: 발견된 모든 결함이 INBOX/review에 등재 + 처리(또는 명시 deferred)
- **하니스 임시 변경 한도**: dogfood 중 하니스 자체에 의도되지 않은 변경 3회 초과 시 → 하니스 재설계 트리거 (drift 신호로 격상)
- **v1.0 승격 기준**: 위 모두 충족 + 별도 사람(또는 별도 codex 세션)이 STATUS만 보고 30분 내 프로젝트 상태를 파악 가능

## 11. 분쟁 해결 프로토콜

Claude와 Codex의 의견이 충돌할 때:

1. **명시화** — finding/응답을 `status: disputed`로 표시. 양쪽 근거를 같은 파일에 정리
2. **재현 시도** — 분쟁 대상을 재검증 (테스트 추가, 사례 확인). Claude·Codex 모두 새 증거 추가 가능
3. **소유자 판단** — 모듈/산출물 owner(기본 Claude=구현자)가 결론 초안 작성. 결론은 ADR로 명문화 (commit 직전 압박 우위 차단)
4. **사용자 escalation** — 다음 중 하나라도 해당되면 즉시 사용자 결정:
   - HC-1~HC-9 영향
   - Blueprint 변경 필요
   - 2회 이상 핑퐁
   - 결론 deadline이 다음 phase gate를 막음

### disputed의 phase 차단 효과
| Severity | Phase 차단 |
|---|---|
| blocker | **차단** (어떤 모드에서도 다음 phase 진입 불가) |
| major | **차단** (autonomous 포함 사용자 결정 필요) |
| minor / nit | 정보로 carry-over, 진행 가능 |
| info | carry-over만 |

### 무한 핑퐁 방지
같은 finding에 대한 핑퐁이 2회 초과되면 사용자 escalation이 강제로 발동된다 (Claude/Codex 어느 쪽도 자체 종결 불가).

## 12. Branch / Git policy

### 12.1 git init 시점
- 늦어도 Phase A.1 진입 전 (codex review --base가 git 필요)
- 하니스 자체 빌드는 본 v0.3 시점에 git init 수행 (ADR-001 실행)

### 12.2 Branch 모델
- **base branch**: 디폴트 `main`. `.harness/config.toml`의 `[git] base_branch`에서 오버라이드 가능
- **feature branch**: `<phase>/<sub-phase>` 또는 `module/<name>` (예: `phase-a/roles`, `module/auth`)
- **Cross-review base**: 항상 *configured base branch* (디폴트 `main`). 표준 명령: `codex review --base "$(yq '.git.base_branch // "main"' .harness/config.toml)"` 또는 `scripts/codex-review.sh`가 config에서 읽어 자동 주입 (A.3 작성 시 구현)

### 12.3 Commit
- 메시지 형태: `<type>(<scope>): <subject>` (type ∈ `harness | plan | code | docs | test | fix | refactor | review`)
- 본문에 관련 ADR 번호 / finding ID 링크
- Co-author 라인은 작업한 모든 에이전트 명시 (Claude, Codex 등)

### 12.4 Dirty worktree 정책
- 리뷰 의뢰 시 dirty 허용: `codex review --uncommitted` 사용 가능
- 정식 cross-review는 commit 후 main 대비

### 12.5 Destructive git 작업
- `force-push`, `branch -D`, `reset --hard`, `clean -fd`, `rebase -i` 등은 HC-9 적용 (사용자 승인 필수)
- `main`에 force-push는 모든 모드에서 금지(사용자 명시 예외 시 외)
