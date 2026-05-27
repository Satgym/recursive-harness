# HARNESS.md — 하니스 헌법 (v1.1)

> Claude와 Codex 모두가 따르는 **절대 규칙**과 **워크플로우 정의**.
> 변경은 §6 "하니스 수정 절차"를 거쳐야 한다. 버전 이력은 §8.

---

## 0. 메타-원칙

이 하니스는 자기 자신도 하니스 규칙으로 빌드한다 (메타 부트스트랩, dogfood).
모든 phase 진행은 [phases/](phases/)의 정식 Exit 기준을 따른다.

## 1. 절대 규칙 (Hard Constraints)

| # | 규칙 | 의미 |
|---|---|---|
| HC-1 | **Plan-First, Code-Late** | Blueprint 승인 전 코드 X. Module Plan 승인 전 해당 모듈 코드 X |
| HC-2 | **File-Persistent** | 모든 결정·계획·리뷰는 파일로 영속화. 대화 기억에 의존 금지 |
| HC-3 | **Drift-Aware** | phase 경계와 세션 시작 시 "지금 Blueprint와 일치하나?" 자가점검 |
| HC-4 | **Gate-Bound** | phase 간 이동은 [phases/<phase>.md](phases/)의 Exit 기준 만족 필수 |
| HC-5 | **Role-Default** | Claude=구현자, Codex=리뷰어. 역할 스왑은 명시적 결정 + ADR |
| HC-6 | **Status-Updated** | 모든 작업 종료 시 STATUS.md 갱신 (생략 시 그 작업은 미완으로 간주) |
| HC-7 | **Secrets-Redacted** | 시크릿/자격증명/PII는 모든 산출물·로그·리뷰에서 즉시 redact. 어떤 모드에서도 평문 저장 금지 |
| HC-8 | **External-Effects-Gated** | 외부 영향 mutation(deploy, 외부 API write, message send, push to remote)은 **모든 모드에서 사용자 승인** |
| HC-9 | **Destructive-Confirmed** | Destructive 작업(rm/drop/truncate/force-push/branch -D/reset --hard 등)은 **모든 모드에서 사용자 승인** |
| HC-10 | **Local-Extends-Only** | Project-local layer(`.harness/skills/`, `.harness/roles/`, `.harness/capabilities.md`)는 base HC-1~9를 약화·재정의·우회할 수 없다. extension·specialization만 허용. base phase Exit 기준의 결정 권한은 항상 base에 있음. (§13 참조) |

> HC-7/HC-8/HC-9는 strictness 모드와 무관하게 항상 적용된다. HC-10은 적응형 v0.6+의 핵심 안전장치.

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

각 phase Exit 기준은 [phases/](phases/)에 정식 명시 (00-intake.md ~ 06-handoff.md).
v1.1+ Fleet Mode (다중 세션 병렬 모듈 구현)는 §14 참조.

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
| Intake 결과 | `.harness/docs/intake.md` |
| Blueprint | `.harness/docs/blueprint.md` |
| Module Plan | `.harness/docs/modules/<name>/plan.md` |
| 리뷰 | `.harness/reviews/<phase>-<date>-<slug>.md` |
| ADR | `.harness/decisions/ADR-NNNN-<slug>.md` |
| 현황 | `.harness/status.md` |
| Postmortem | `.harness/postmortems/YYYY-MM-DD-<slug>.md` |
| INBOX (Codex 능동 피드백) | `.harness/inbox/` (`.harness/inbox/processed/` 포함) |
| 하니스 버전 pin | `.harness/VERSION-PIN` |
| (web-service) API 명세 | `.harness/docs/api/openapi.yaml` (또는 도구별) |
| project-type 참조 자료 | `.harness/docs/test-strategy.md`, `module-skeleton.md` (read-only 참조 — seed) |
| **Project-local skills** ⭐ | `.harness/skills/*.md` (§13) |
| **Project-local roles** ⭐ | `.harness/roles/*.md` (§13) |
| **Capability manifest** ⭐ | `.harness/capabilities.md` (active local capability 목록 — manifest 기반 loading) |

> 본 레포(하니스 self-build)의 INBOX는 root `INBOX/` 그대로. project-level INBOX는 `.harness/inbox/`.

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
  approver: user | codex-review | claude-reviewer | claude-self-test
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
  approver: user | codex-review | claude-reviewer | claude-self-test
  mode: strict | balanced | autonomous
  approved_at: 2026-05-25T15:30
  scope: <어디까지 승인되는지>
```
승인 없이 다음 phase로 이동 금지 (HC-4).

다음 세션은 **STATUS.md만 읽으면** 즉시 이어받을 수 있어야 한다.

## 8. 버전 이력

상세 rationale은 root DECISIONS.md ADR 참조. 본 표는 한 줄 요약.

| 버전 | 핵심 변경 | Trigger |
|---|---|---|
| v0.1~v0.5 | 골격 + HC-1~9 + STATUS 양식 + Codex 규약 + ADR/postmortem/git policy 확립 | Phase A 자체 부트스트랩 |
| v0.6 | **Adaptive redesign** — HC-10 + §13 Local Adaptive Layer (`.harness/skills`,`/roles`,`/capabilities.md`) | adaptive-redesign-r1 review |
| v1.0 | Phase E ship — 3 dogfood 검증 (todo-api/temp-sensor/starpin) + base promotion 첫 사례(`budget-binary-size`) + autonomous mode 검증 | ADR-009 |
| v1.1 | **Fleet Mode** — §14 신설. Phase 02 split-decision + Phase 05 merge-collection. 재귀 coordinator 패턴 (root → leaf, depth ≤ 2). 4 templates + 2 base skills | ADR-010 |
| v1.2 | **Fleet enforcement 강화** — §14.8 lock & invariant enforcement (grep gate) + §14.9 inter-child consume timing (stub/ambient/topo) + §14.10 scope-bounded gates. F80 (user-delegated approval path). 신규 base skill `lock-grep-gate`. SUBTREE-PROMPT + MERGE-REPORT + locked-interface template 정비 | ADR-011 |
| v1.3 | **AST-level lock enforcement** — §14.8 promote: lock-grep-gate → `lock-eslint-gen` skill (ESLint flat config + `no-restricted-imports`) primary, grep fallback. §14.9 strategy a/b/c *helper script 실 구현* (`scripts/fleet/{gen_stub,gen_ambient,topo_sort,gen_eslint_lock}.py`). Small wins: mid-work escalation 명세 (F70-fleet-1), codex 대체 heuristic (F70-fleet-3), ESM jest pattern (F86) | ADR-012 |

## 9~10. (history) — archived

- §9 Bootstrap exception (Phase A 임시 게이트): ADR-007로 폐기. git log + ADR-007 참조.
- §10 Phase E dogfood 성공 기준: v1.0 승격 (ADR-009) 시 충족 완료. 본 criteria는 [docs/history/phase-e-dogfood-criteria.md](docs/history/phase-e-dogfood-criteria.md)로 archive (v1.6 cleanup). 신규 dogfood는 base §3 phase Exit 기준만 따름.

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

## 13. Project-local Adaptive Layer

> **추가일**: v0.6 (2026-05-25, adaptive-redesign-r1)
> **목적**: base harness는 *모든 프로젝트의 공통 규칙·페이즈·구조*만 정의하고, 도메인 특화된 skills/roles/checklists는 *프로젝트 로컬*에서 자체 구성하게 한다. base는 정적 catalog가 아니라 적응을 가능케 하는 *프레임워크*.

### 13.1 두 layer

| Layer | 위치 | 권한 | 누가 |
|---|---|---|---|
| **Base** | 본 레포 (HARNESS.md, phases/, roles/, templates/, scripts/, skills/, project-types/, INBOX/) | HC-1~9 (절대), phase Exit 기준, role 권한 매트릭스, 모든 산출물 양식 | 하니스 자체 변경 절차 (§6) + 사용자 승인 |
| **Local** | 각 프로젝트의 `.harness/skills/`, `.harness/roles/`, `.harness/capabilities.md` | base에 *추가*되는 도메인 특화 절차·역할·체크리스트 (extension only) | Local Capability Synthesis (phase 00 sub-step) + Codex review + 사용자 승인 |

### 13.2 HC-10 의미 (Local-Extends-Only)

Local layer는 다음을 **할 수 없다**:
- HC-1~9 약화·재정의·우회
- base phase Exit 기준의 항목을 *제거*
- base role 권한 매트릭스의 항목을 *권한 추가* 방향으로 변경 (codex-reviewer가 commit하게 만든다든지)
- `approval.approver` enum 확장 (사용자/codex-review/claude-reviewer/claude-self-test만 — F19)
- 사용자 승인 게이트 우회

Local layer가 **할 수 있는 것**:
- base 양식에 *추가* 필드·체크리스트
- 도메인 특화 role (advisory reviewer / domain checklist owner / 구현 제약 제공자) — 단 execution authority는 base 4 roles에만
- 도메인 특화 skill (특수 도구 호출 / 도메인 lint / 특수 review 체크리스트)
- 도메인 특화 phase Exit *추가* 항목 (base 항목에 더해)

### 13.3 Loading semantics (manifest 기반)

세션 시작 시 (CLAUDE.md / AGENTS.md 의무):

1. base files (HARNESS / STATUS / DECISIONS / CLAUDE 또는 AGENTS) 읽기 — *항상*
2. `.harness/capabilities.md` 존재하면 읽기 — *active* local capabilities 목록
3. 그 manifest에 *명시된* local skills/roles만 working set에 포함

> **암묵적 discovery 금지**: `.harness/skills/*.md`를 자동 ls해서 읽지 않음. manifest에 명시되어 *승인된* 항목만 활성. 미승인 draft는 working set에 들어가지 않음.

### 13.4 Capability manifest 양식

`templates/CAPABILITY-MANIFEST.template.md` 참조. 최소 구조:

```markdown
---
artifact: capability_manifest
version: v0.1
project_name: <name>
approved_at: <ISO timestamp>
approver: user
---

# Active local capabilities

## Skills (extension)
- path: .harness/skills/<name>.md
  scope: <어느 phase / 어느 모듈 / 어느 도메인>
  extends: <base skill ID 또는 none>
  approved_at: <ISO timestamp>

## Roles (advisory)
- path: .harness/roles/<name>.md
  scope: ...
  authority: advisory  # 항상 — execution authority는 base 4 roles만
  approved_at: ...
```

manifest 자체도 *산출물*이며, HARNESS §7의 Approval record 6필드로 STATUS Approved artifacts에 등재된다.

### 13.5 Local Capability Synthesis (phase 00 sub-step)

phase 00 Intake 후, phase 01 Blueprint 전에 발동. 절차는 [skills/synthesize-local-layer.md](skills/synthesize-local-layer.md) 참조.

요약:
1. Intake 결과 분석 — base + 가까운 project-type seed가 *충분히* 커버하는가?
2. gap 식별 — 어떤 domain SME / 특수 체크리스트 / 도메인 테스트 패턴 / 특수 review 룰이 빠졌는가?
3. local skill/role draft 작성 (templates 사용)
4. **Codex review** ([skills/review-local-layer.md](skills/review-local-layer.md) — HC-10 delta safety check)
5. **사용자 승인** (모든 모드 필수 — 하니스 자체 변경에 준함)
6. capability manifest 갱신 → STATUS Approved artifacts 등재
7. Blueprint 단계로 진입

### 13.6 Promotion (local → base)

local capability가 다음 *모두* 만족하면 base 승격 후보:
- 서로 다른 ≥ 2 프로젝트에서 활성 사용
- 또는 1개 non-trivial dogfood에서 검증
- Codex review 통과 + reopened finding 누적 < 임계
- 도메인 시크릿·고유 정보 없음 (generalizable)

승격은 base 변경이므로 §6.2 + ADR + Codex review + 사용자 승인. (v1.1 도구화 예정 — v0.6은 *수동* 승격)

### 13.7 Local layer drift 신호

- manifest와 디렉토리 실제 파일 불일치
- local skill이 base phase Exit 기준의 *제거*를 시도 (HC-10 위반)
- 같은 도메인의 3+ 프로젝트가 동일 local skill을 만드는 패턴 (승격 후보)
- base 업그레이드 후 local capability가 새 base 규칙과 충돌

drift 발견 시 §6.2 절차 + ADR.

## 14. Fleet Mode (재귀 coordinator 패턴)

> **추가일**: v1.1 (2026-05-27, ADR-010)
> **목적**: 모듈 수가 많거나 결합도가 낮은 프로젝트에서 *다중 Claude 세션 병렬*로 Phase 03 implement를 진행. coordinator는 Phase 02에서 split 여부를 판단하고, Phase 05에서 결과를 회수한다. 각 coordinator는 같은 7-phase 루프를 *자기 scope에* 실행 — **재귀**.

### 14.1 핵심 모델

```
[Root coordinator session]   ← 사용자가 처음 띄운 세션
  Phase 00~02 본인이 실행
  Phase 02 종료 직전: split-decision (skill: estimate-project-scope)
    │
    ├─ 단일 모드(no-split)    → 본인이 Phase 03~06 그대로 진행 (현재까지 패턴)
    │
    └─ Fleet 모드(split)
        ↓ SPLIT-DECISION-ADR 발행 (사용자 승인 의무 — HC-8/9 무관 별도)
        ↓ skill: spawn-subtree-prompts → 각 child별 worktree + SUBTREE-PROMPT.md 생성
        ↓ 사용자가 N개 Claude Code 세션 열어 prompt 전달
        │
        ├─ [Child coordinator M2]    ← 자기 worktree, 자기 branch, 자기 STATUS
        │     Phase 02~04 본인 scope만 (재귀적으로 또 split 가능 — depth ≤ 2 in v1.1)
        │     완료 시 MERGE-REPORT.md 작성 + commit
        │
        ├─ [Child coordinator M3]   동일
        └─ ...
        ↓ 모든 child 완료까지 wait
[Root coordinator session 복귀]
  Phase 05 merge-collection: 각 child branch fetch → integration test → finding 회수
  Phase 06 handoff
```

### 14.2 Fleet Mode 규칙

| # | 규칙 | 의미 |
|---|---|---|
| F1 | **인터페이스 lock at split** | parent의 SPLIT-DECISION-ADR에 명시된 각 child의 *인터페이스·DB 스키마·타입·invariant·file ownership*은 child가 수정 불가. 변경 필요 시 child가 작업 중단 → parent에 escalate |
| F2 | **횡단 invariant 식별 의무** | parent Phase 01 Blueprint Exit에 *cross-cutting invariant 목록* 필수. split 후 발견되는 횡단 invariant는 전체 stop + parent replan |
| F3 | **capability manifest 동결** | split 시점에 *root*의 `.harness/capabilities.md` freeze. child는 *읽기만*; 신규 capability 후보는 MERGE-REPORT에 candidate로 제출, parent가 merge phase에서 결정. (recursion 시 root의 manifest가 *모든 depth의 ground truth*) |
| F4 | **file ownership 명시** | SPLIT-DECISION-ADR에 *디렉토리 단위 ownership* 명시. shared 파일(types.ts, config, root 산출물)은 parent 소유 — child는 *읽기 허용, 쓰기 금지*. 변경 필요 시 patch candidate로 (MERGE-REPORT에) |
| F5 | **재귀 depth ≤ 2 (v1.1)** | root(depth=0) → child(depth=1) → grandchild(depth=2)까지. *기계적 강제*: SPLIT-DECISION-ADR `current_depth`+1 = `resulting_depth`, `resulting_depth > max_depth_allowed`면 spawn-subtree-prompts skill이 die. 더 깊은 split은 ADR 별도 정당화. v1.2에서 완화 가능 |
| F6 | **승인 게이트 (기계적 강제)** | SPLIT-DECISION-ADR는 production Fleet에서 **`approver: user` (직접 승인) 의무**. 예외 2 (examples/ 경로 한정 — *production 금지*): (b) `approver: user-delegated` + `delegation_source` field (autonomous session 안의 user delegation 인용 — 본질적으로 자기-진술이라 위조 가능성 인정. examples 외 사용 시 spawn skill이 die), (c) `dogfood_simulation: true` flag. spawn-subtree-prompts preflight가 paths 검증: production code path는 *(a)만*. **F100 v1.2 codex finding**: (b) `user-delegated`는 *검증 불가능한 claim* — production은 hard rule로 (a) 또는 사용자가 별도 confirmation artifact 직접 sign-off. v1.3 후보: out-of-band confirmation (Slack/email signature 등) 통합 |
| F7 | **Codex review 분배** | 각 child는 *자기 scope에 대한* codex review (Phase 04)를 독립 수행. parent는 merge 후 *cross-cutting integration review*를 별도 1회 수행. **v1.3 self-test 대체 heuristic** (F70-fleet-3): self-test로 갈음 가능한 조건은 *모두* 충족 시만 — (i) `examples/` 또는 `dogfood/` 경로, (ii) 총 LOC < 1500, (iii) HC-7/8/9 영향 없음 (Blueprint에서 no라고 명시), (iv) 외부 통신 / DB write / 인증 / 결제 모듈 *부재*. 위 4 모두 아니면 codex 의무. SPLIT-DECISION-ADR의 `codex_review_replacement: self_test \| codex_full` field에 명시 (preflight가 heuristic 자동 평가 + override 시 사유) |
| F8 | **STATUS 위계** | parent STATUS는 *tree 구조*만 표시 (child별 상태 dashboard). 각 child는 *자기 scope*만 자기 `.harness/status.md`에. root는 `current_depth=0`, child의 `parent_subtree` field가 immediate parent 식별 |
| F9 | **HC-10 invariant 유지 + draft/activate 분리** | child는 본인의 `.harness/skills/` 파일을 *draft만* 가능 (extension 후보 작성). **load·use·activate는 frozen root manifest에 이미 있는 capability만 허용**. 신규 draft는 MERGE-REPORT의 capability candidate 섹션에 등재만; parent merge phase에서 root manifest 수용 결정 후에야 activate. parent의 active manifest를 *제거*하는 것은 불가 |
| **F10** | **Child failure recovery (v1.6 M10)** | child가 rate-limit / crash / timeout 등으로 *merge-report 작성 못한* 경우: parent가 *대리 작성* 가능 — 단 frontmatter에 `parent_authored: true` + `child_completion_status: rate_limited\|crashed\|timeout` + `evidence_confidence: high\|medium\|low` 명시 의무. parent는 child가 작성한 *partial artifacts*만으로 lock/invariant 검증 가능한 경우 high; 추가 추론 필요한 경우 low. low의 경우 codex review에 *evidence_confidence flag 명시* + parent의 대리 결정 명시. starpin v0.4 F1 case (rate-limit으로 merge-report 누락) 가 본 규칙 첫 dogfood evidence |

### 14.3 언제 split할까 (Phase 02 split-decision)

skill [`estimate-project-scope`](skills/estimate-project-scope.md) 호출. 결정 휴리스틱 (참고):

| 신호 | 임계 | 결정 |
|---|---|---|
| 모듈 수 | ≤ 3 | no-split |
| 모듈 수 | 4~7, 결합도 낮음 | split (root + N leaves) |
| 모듈 수 | 8+ | split + 잎이 또 split (depth=2) |
| 모듈 간 *순환 의존* | 1개 이상 | no-split (인터페이스 lock 위험) |
| 횡단 invariant | 3+개 식별됨 | no-split 또는 신중 split (lock 부담) |
| 예상 LOC | < 1500 | no-split |
| 예상 LOC | ≥ 5000 + 모듈 ≥4 | split 권장 |

휴리스틱은 *참고*. 최종 판단은 coordinator + SPLIT-DECISION-ADR에 근거 명시.

### 14.4 Subtree workspace 구조

```
parent-repo/                  # parent worktree (main branch)
├── .harness/
│   ├── status.md             # root STATUS — tree dashboard
│   ├── capabilities.md       # frozen at split time
│   ├── subtrees/             # parent가 child에 전달하는 *입력*
│   │   ├── <child-name>/
│   │   │   ├── prompt.md     # SUBTREE-PROMPT (child kickoff)
│   │   │   ├── locked-interface.md   # 변경 불가 spec
│   │   │   └── (merge 시점) merge-report.md  # child가 fetch+commit으로 제공
│   └── decisions/
│       └── ADR-NNNN-split-decision-<slug>.md

../parent-repo-<child>/       # child worktree (feat/<child> branch)
├── .harness/
│   ├── subtree.md            # 본 세션이 sub-coordinator임을 알리는 marker
│   │                         #   parent_path, locked_interface_path, child_name
│   ├── status.md             # child 본인 scope의 STATUS
│   └── (자기 모듈 코드)
```

git worktree로 분리하므로 각 child 세션은 **독립 디렉토리 + 독립 컨텍스트 + 독립 branch**. parent와 child의 file write는 서로 보이지 않음 (각자 branch에서만). merge phase에 parent가 `git fetch` + `git merge` 또는 PR 통합.

### 14.5 Phase mapping

| Phase | Root coordinator | Child coordinator (sub-session) |
|---|---|---|
| 00 Intake | 본인 실행 | (해당 없음 — parent의 intake 상속) |
| 01 Blueprint | 본인 실행 (횡단 invariant 명시 의무) | (해당 없음 — parent의 blueprint 상속) |
| 02 ModulePlan | 본인 scope의 모듈 plan + split-decision step | 본인 scope의 모듈 plan (다시 split 가능 — depth ≤ 2) |
| 03 Implement | (split 시 본인이 직접 코드 짜지 않고 spawn만) | 본인 scope만 |
| 04 CrossReview | (split 시 cross-cutting integration review만) | 본인 scope의 codex review |
| 05 Integration | merge-collection — child branch들 fetch + 통합 test + finding 회수 | (해당 없음) |
| 06 Handoff | 본인 실행 | MERGE-REPORT.md 작성 + commit (handoff to parent) |

### 14.6 새 산출물

- **Templates** (4): `templates/SUBTREE-PROMPT.template.md`, `templates/SUBTREE-STATUS.template.md`, `templates/SPLIT-DECISION-ADR.template.md`, `templates/MERGE-REPORT.template.md`
- **Base skills** (2): `skills/estimate-project-scope.md`, `skills/spawn-subtree-prompts.md`

### 14.7 Fleet Mode drift 신호

- child가 locked interface를 수정한 흔적 (git diff에 lock 파일 변경)
- child의 MERGE-REPORT에 capability candidate가 5+개 (manifest 동결 압박)
- 횡단 invariant가 split 후 신규 발견됨 (parent Phase 01 미흡)
- merge 시 conflict가 모듈 boundary가 아닌 *shared 파일*에서 다수 발생 (file ownership 명세 미흡)

drift 시 §6.2 절차 + ADR. 반복되면 *Fleet Mode 자체 회의 후보* — split 패턴이 본 프로젝트에 안 맞을 수 있음.

### 14.8 Lock & invariant enforcement (v1.2 + v1.3 — F87/F90/F82/F102 patches)

**관찰**: F1 (interface lock) + F2 (cross-cutting invariant)는 *명세는 명확*하지만 *enforcement는 child의 self-discipline*에 의존했었음. TypeScript typecheck로 막히지 않는 invariant (예: "verifySession만 import" / "redact util을 *실제 호출*") 다수.

**v1.3 핵심 변경**: F1 (single-method consume lock)이 **AST-level enforcement** (ESLint `no-restricted-imports`)로 격상. v1.2의 grep은 fallback.

> **honest 한계 (v1.6 meta-review M9)**: 본 enforcement는 *child name = module name* 가정 시에만 정합. starpin v0.3의 OAuth 3 providers처럼 *같은 디렉토리에 sibling 파일*로 공존하는 경우 child-vs-child boundary 자동 catch 못함 (`apple.ts`가 `./google.js` import 가능). 또한 *stable parent module* (catalog/service.js 등) reach-around도 `consumed_stable_modules` field 명시 시에만 partial 차단. F122 (parent reach-around named-import allowlist) + F123 (sibling-file boundary)는 v1.6/v1.7 open carry-over — codex review가 2nd-line defense 의무. 본 enforcement는 *"grep-better gap detection"*에서 *"AST-better gap detection"*으로 격상; *완전한 mechanical*은 v1.7+ AST custom rule 후보.

**규칙**:
1. **Single-method consume (lock-eslint-gen — primary, v1.3)**: locked-interface §"Consumed interface"가 *runtime import allowlist*. spawn-subtree-prompts skill이 [`lock-eslint-gen`](skills/lock-eslint-gen.md) 호출 → 각 child용 `eslint.config.<child>.mjs` (flat config) 자동 생성. `no-restricted-imports` rule이 allowlist 외 모든 named import를 *AST error*로 차단. child의 pre-review-gate + Phase 05 merge-collection에서 *기계적 실패*. ESLint v9+ 의존; 미설치 시 [`lock-grep-gate`](skills/lock-grep-gate.md) fallback.
2. **Invariant-guard import 검증**: import만 하고 호출 안 함을 막기 위한 두 옵션:
   - (a) **권장 default** — 횡단 invariant를 *runtime gate function*으로 redesign (예: `safeError(code, ...rawValues)` wrapper) — import가 자연스럽게 호출됨. tree-shaker도 못 제거
   - (b) **fallback** — `// @invariant-guard: <util>` 표준 주석 marker. 단 marker 있어도 *실제 호출 보장은 codex review 책임*
3. **MERGE-REPORT INV evidence 의무**: child는 각 invariant별 *실제 코드 path 인용*. parent가 회수 시 evidence 누락/false면 child re-work.
4. **v1.4 roadmap**: re-export barrel walker + namespace import (`import * as X`)에 대한 deeper AST analysis (현 v1.3 ESLint rule은 direct named import + alias까지만). custom `@typescript-eslint` rule 후보.

### 14.9 Inter-child consume timing (v1.2 — F81 patch)

**관찰**: child A가 child B의 module을 consume할 때 parallel spawn은 race. 본 v1.1 dogfood는 *우연히 topological order* 일치 — production은 random.

**규칙**: SPLIT-DECISION-ADR의 child 구성에 dependency graph 명시 + 3 옵션 중 하나 선택 의무:

| option | 절차 | helper (v1.3 실 구현) | 권장 case |
|---|---|---|---|
| **(a) lock-spec stub** | parent가 spawn 전 *consumer 위한 stub*을 placeholder로 작성 (`src/<provider>/index.ts`에 lock signature만 + `throw new Error('not-implemented')`). consumer는 stub에 typecheck PASS. parent merge phase에 real impl 덮어쓰기 검증 | `python3 scripts/fleet/gen_stub.py <locked-interface.md> --out src/<provider>/index.ts` | dependency 가 *type + 가벼운 runtime call*일 때 |
| **(b) type-only ambient** | consumer가 자기 worktree에 `<provider>.d.ts` ambient declaration 작성 (lock-spec 복제). parent merge phase에 ambient 제거 + real import 검증 | `python3 scripts/fleet/gen_ambient.py <provider-locked-interface.md> --out src/<consumer>/<provider>.d.ts` | type-only dependency가 대부분일 때 |
| **(c) topological spawn order** | spawn-subtree-prompts skill이 dependency graph topological sort → provider child가 *완료된 후* consumer child spawn (parent가 sequential dispatch) | `python3 scripts/fleet/topo_sort.py <SPLIT-DECISION-ADR.md>` → wave별 spawn 안내 | parallel 이득 일부 포기 OK 또는 인터페이스 lock confidence 낮음 |

SPLIT-DECISION-ADR에 `inter_child_consume_strategy: a|b|c` field 의무. spawn skill이 검증.

### 14.10 Scope-bounded pre-review-gate (v1.2 — F85 patch)

**관찰**: parallel spawn 중 `npm run typecheck` / `npm run test:unit` (root scope)는 sibling 미완 동안 fail. child가 자기 PASS 선언 못함.

**규칙**: spawn-subtree-prompts skill이 SUBTREE-PROMPT 생성 시 *child별 scope 명령*을 자동 주입:

```bash
# scope-only typecheck — child의 owned src + shared만
npx tsc --noEmit --target ES2023 --module ES2022 ... \
  src/<child>/*.ts src/shared/*.ts tests/<child>/*.ts

# scope-only test — child의 own test path만
npm run test -- --testPathPattern=<child>
```

또는 spawn skill이 *child별 `tsconfig.<child>.json` + `jest.config.<child>.json`*을 자동 생성. SUBTREE-PROMPT의 "Pre-review-gate" 섹션에 명시.

Fleet F4 (ownership matrix)의 *write boundary* 옆에 *gate scope rule* 신설: **child's gate = files it owns + shared transitive imports only**. sibling 상태와 무관해야 함.
