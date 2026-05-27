# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식을 따른다.
> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | **adaptive-redesign — v0.6+ → v1.0 승격 ADR 발행 (ADR-009)** |
| Active sub-phase | **starpin v0.1.1 SHIPPED 2026-05-27** (codex batch3 6 patches + Fastify routes + buildServer + integration test) — 3차 dogfood 완주 후 hardening round |
| Strictness | strict (project-self) — 단 dogfood projects (starpin)는 autonomous transition 가능 (ADR-005 v1.3) |
| Harness version | **v1.0** (ADR-009 — starpin Phase E §10 5 criteria 충족) |
| Git | main; starpin 19 commits (v0.1.0 ship + v0.1.1 hardening) + base skill promotion + root DECISIONS ADR-008 + ADR-009 |
| Last updated | 2026-05-27 by Claude (Executor, autonomous within dogfood scope) — v0.1.1 commit `9e04d24` |

## Active gate

- **Gate**: v0.6 적응형 재설계 core 작성 완료 → codex v0.6 통합 cross-review → 사용자 승인 → commit
- **Blocked on**: codex v0.6 cross-review 호출 결과 + finding 처리 + 사용자 승인
- **Approval needed**: yes — v0.6 전체 변경 묶음 (HC-10 + §13 + 3 templates + 2 base skills + phases/00 sub-step + new-project.sh + project-types/README + CLAUDE/AGENTS/resume-session). codex review가 검증.

## Required reads (이 세션 시작 시)

1. `HARNESS.md` v0.4
2. `STATUS.md`
3. `DECISIONS.md`
4. `AGENTS.md` / `CLAUDE.md`
5. `INBOX/README.md`
6. `roles/README.md` + 4개 역할 파일 (A.1 결과)
7. `templates/README.md` + 6개 양식 파일 (A.2 결과)
8. `scripts/README.md` + 4 main + 1 helper (A.3 결과; smoke-tested)
9. `phases/README.md` + 7 phases (A.4 결과 — 00-intake ~ 06-handoff Exit 기준 정식 명세)
10. `skills/README.md` + 9 skills (Phase B 결과 — procedural docs)
11. `project-types/README.md` + `_generic/` (3) + `web-service/` (4, api-spec 포함) (Phase C 결과)
7. (참고) `INBOX/processed/codex-feedback-20260525-v0.3-review.md`
8. (참고) `INBOX/processed/codex-feedback-20260525-seed-review.md`

## Approved artifacts

```yaml
- artifact: HARNESS.md
  version_or_hash: "v0.2"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:03
  scope: HC-7/8/9, Strictness 통일, §7 STATUS 양식, §9 Bootstrap exception, §5 Review determinism

- artifact: STATUS.md
  version_or_hash: "v0.2-format"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:03
  scope: 10섹션 stranger-proof 양식

- artifact: HARNESS.md
  version_or_hash: "v0.3"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: §4.3 front-matter / §5.4 cost guardrails / §6.3-6.4 postmortem / §10 dogfood / §11 분쟁 / §12 branch+git

- artifact: AGENTS.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: INBOX 체크 의무, INBOX 쓰기 예외, canonical enum, HC-7/8/9 강조

- artifact: CLAUDE.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: HC-7/8/9 강조 + enum 참조

- artifact: DECISIONS.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: ADR 양식 표준화, ADR-003 ADR-003a 표기 수정

- artifact: INBOX/README.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: unread 정의, Codex 쓰기 예외

- artifact: .gitignore
  version_or_hash: "seed"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: OS/editor noise + .claude/settings.local.json

- artifact: HARNESS.md
  version_or_hash: "v0.4"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:34
  scope: §12.2 base branch wording(F13), §4.3 artifact-specific status enum + deferred_reason(F14), §9 disputed 처리 cross-ref(F15)

- artifact: INBOX/README.md
  version_or_hash: "v0.1+A.0g-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:34
  scope: deferred reason 분리(F14)

- artifact: roles/ (5 files — README, claude-implementer, codex-reviewer, claude-reviewer, codex-implementer)
  version_or_hash: "v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:39
  scope: 4개 역할 책임/입력/출력/제약 + 발동 규칙 + 도구 권한 매트릭스 + 안티 패턴

- artifact: DECISIONS.md (ADR-006 추가)
  version_or_hash: "v0.1+ADR-006"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:39
  scope: ADR-006 — Phase A sub-phase별 codex 리뷰 시점 (3 timepoints: A.0a / A.0f / A.5)

- artifact: templates/ (7 files — README + BLUEPRINT + MODULE-PLAN + REVIEW + ADR + POSTMORTEM + STATUS)
  version_or_hash: "v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-25T12:09
  scope: 6 산출물 양식 정식 확정 (HARNESS §4.3 artifact-specific status enum 인스턴스화)

- artifact: scripts/ (6 files — README + codex-review.sh + codex-exec-review.sh + pre-review-gate.sh + new-project.sh + _codex_postprocess.py)
  version_or_hash: "v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-25T13:25
  scope: codex 호출 자동화 wrapper, pre-review-gate(lint/test), new-project 부트스트랩, raw stdout → REVIEW 변환 헬퍼. 모두 chmod +x, smoke-tested.

- artifact: phases/ (8 files — README + 00-intake + 01-blueprint + 02-module-plan + 03-implement + 04-cross-review + 05-integration + 06-handoff)
  version_or_hash: "v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-25T13:44
  scope: 7단계 phase Entry/Activities/Outputs/Exit 정식 명세 + 모드별 승인 매트릭스. §9 Bootstrap exception을 대체.

- artifact: DECISIONS.md (ADR-007)
  version_or_hash: "v0.1+ADR-007"
  approver: user
  mode: strict
  approved_at: 2026-05-25T13:44
  scope: §9 Bootstrap exception 폐기 명문화. phases/ 정식 게이트가 §9를 대체.

- artifact: HARNESS.md §9 deprecation patch
  version_or_hash: "v0.4+A.4-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T13:44
  scope: §9 헤더에 deprecated 상태 표시 + ADR-007 참조. 본문은 v0.5에서 archival 검토.

- artifact: .harness/config.toml + .harness/prompts/a5-integrated-review.md
  version_or_hash: "dogfood-v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-25T13:44
  scope: A.5 dogfood — harness 자신을 프로젝트로 다루는 임시 .harness/. NOTE F21(아래 Open findings) 미해결로 reasoning.review="high" 설정이 실제 호출엔 적용되지 않음 (medium 사용됨).

- artifact: .harness/reviews/a5-20260525-integrated.md (Codex A.5 cross-review)
  version_or_hash: "codex-session-019e5d7c"
  approver: codex-review
  mode: strict
  approved_at: 2026-05-25T13:50
  scope: A.5 통합 cross-review 결과 — 11 findings (F16~F26), 0 blocker, 6 major, 5 minor, HC 위반 없음, verdict ready_for_v0.5=no

- artifact: HARNESS.md v0.5 + CLAUDE.md A.5b patch + DECISIONS.md ADR-007 approval + scripts/ (5 files) + templates/ADR.template.md + phases/02-module-plan.md (A.5b 모든 finding 처리)
  version_or_hash: "v0.5"
  approver: user
  mode: strict
  approved_at: 2026-05-25T14:22
  scope: A.5 11 findings (F16~F26) 모두 resolved. Phase A 종결판 = HARNESS v0.5. pre-review-gate self-smoke 5 checks PASS.

- artifact: skills/ (10 files — README + kickoff-project + plan-blueprint + plan-module + request-codex-review + apply-review + checkpoint-handoff + resume-session + drift-check + harness-amend)
  version_or_hash: "v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-25T14:28
  scope: 9 procedural docs + index. 각 skill의 Purpose / When / Inputs / Procedure / Outputs / Failure modes / Related 6섹션 양식.

- artifact: project-types/ (8 files — README + _generic/{intake,test,module} + web-service/{intake,test,module,api-spec})
  version_or_hash: "v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-25T14:44
  scope: ADR-005에 따라 web-service 깊이 (API spec-first 강조) + _generic 골격. firmware/ai-model/cli-tool/data-pipeline은 실 필요 시 추가.

- artifact: .harness/reviews/bc1-20260525-integrated.md (Codex BC.1 cross-review)
  version_or_hash: "codex-session-019e5db9"
  approver: codex-review
  mode: strict
  approved_at: 2026-05-25T17:00
  scope: B+C 통합 cross-review — 8 findings (F27~F34), 1 blocker (HC-8 F34), 2 major, 5 minor, verdict ready_for_phase_D=no

- artifact: BC.2 patch (HARNESS §4.2 + scripts/new-project.sh + scripts/codex-review.sh + scripts/codex-exec-review.sh + skills/{plan-blueprint,plan-module,request-codex-review,resume-session,checkpoint-handoff} + project-types/web-service/{test-strategy,module-skeleton,intake-checklist,api-spec-template} + project-types/_generic/module-skeleton)
  version_or_hash: "bc.2"
  approver: user
  mode: strict
  approved_at: 2026-05-25T17:29
  scope: BC.1 8 findings (F27~F34) 모두 resolved. F34 (HC-8 blocker)는 dry-run≠user-approval 명확화. F27/F28는 new-project.sh + sibling path + Phase 00 artifact 매핑으로 실 사용 가능. smoke-test 통과 (pre-review-gate 5/5 + new-project.sh 실 실행).
```

## Decision summary

- **ADR-001**: git repo 배포 + 메타 부트스트랩 — 실행됨 (seed commit `0dbba69`, A.0g `d138d05`)
- **ADR-002**: Codex 개입은 파일 기반 비동기(A) 기본, 사용자 codex 세션(C) 보조, MCP(B) 후순위
- **ADR-003**: 모델/계정은 `.harness/config.toml`에서 설정, 코드 하드코딩 금지
- **ADR-004**: Strictness `strict/balanced/autonomous`, 디폴트 strict. Blueprint는 모든 모드 사용자 승인 (v0.2)
- **ADR-005**: 프로젝트 타입 우선순위 — `web-service` 깊이, 나머지 `_generic` 골격만
- **ADR-006**: Phase A codex 리뷰는 A.0a / A.0f / A.5 3시점에만 (sub-phase별 별도 리뷰 면제)
- **ADR-007**: §9 Bootstrap exception 폐기 (A.4 완료) — 정식 phase Exit 기준으로 전환

## Roadmap

### Phase A — 골격 구축 (✓ 종결, v0.5 태그)
- [x] **A.0** 사용자 5개 결정 + 씨앗 문서 6종
- [x] **A.0a** Codex seed-review 수령
- [x] **A.0b** Blocker + 핵심 major → HARNESS v0.2
- [x] **A.0c** v0.2 사용자 승인
- [x] **A.0d** 작은 finding 5종 패치
- [x] **A.0e** F7 + 추가 제안 5개 → HARNESS v0.3 + git init
- [x] **A.0f** Codex 재리뷰 (3 new minor)
- [x] **A.0g** F13/F14/F15 정리 → HARNESS v0.4 (commit `d138d05`)
- [x] **A.1** `roles/` 5파일 (README + 4 역할)
- [x] **A.2** `templates/` 7파일 — §4.3 status enum 인스턴스화
- [x] **A.3** `scripts/` 6파일; smoke-tested
- [x] **A.4** `phases/` 8파일 + ADR-007 (§9 폐기) + HARNESS §9 deprecation patch
- [x] **A.5** Phase A 통합 cross-review 수령 (codex `019e5d7c`, tokens 107,011, 11 findings)
- [x] **A.5b** F16~F26 모두 resolved → HARNESS v0.5 + CLAUDE/DECISIONS/scripts/templates/phases patch + pre-review-gate 5 checks PASS
- [ ] **A.4** `phases/` — 00-intake ~ 06-handoff (완성 시 §9 자동 폐기 → ADR로 명문화)
- [ ] **A.5** Phase A 전체 cross-review → HARNESS v0.5 정식

### Phase B — 스킬 풀 (✓ 작업 완료 + commit `85e6915`)
- [x] **B** `skills/` 10파일

### Phase C — 프로젝트 타입 템플릿 (✓ commit `62aa964`)
- [x] **C** `project-types/` 8파일 + commit
- [x] **BC.1** B+C 통합 cross-review (codex `019e5db9`, tokens 129,594, 1 blocker + 2 major + 5 minor)
- [x] **BC.2** 8 findings 모두 resolved + smoke test 통과
- [ ] **BC.2 commit** — 사용자 승인 후

### 이후 phases
- **Phase D**: 자기보호 메커니즘 정식화 — drift / postmortem / conflict 실 운영 노하우 축적
- **Phase E**: Dogfood + v1.0 (HARNESS §10 기준)

## Next action

- **사용자**: BC.2 결과 검토 + 승인 → commit + Phase D 또는 Phase E 진입 결정. (재리뷰는 토큰 비용 추가, 권장 skip)
- **Claude**: 승인 후 commit → Phase D (자기보호 메커니즘 정식화) 또는 Phase E (Dogfood + v1.0)로
- **Codex**: 대기 (재리뷰 호출되면 BC.2-verify 라운드)

## Open findings

### A.5 통합 cross-review (codex `019e5d7c`, `.harness/reviews/a5-20260525-integrated.md`)

| ID | severity | 제목 | 상태 |
|---|---|---|---|
| F16 | major | §9 deprecation HARNESS 본문 미반영 | **resolved** (HARNESS §0/HC-4/§3 + 헤더 + §8 v0.5) |
| F17 | major | CLAUDE.md `deferred(<이유>)` 잔존 | **resolved** (CLAUDE.md INBOX 의무 갱신) |
| F18 | major | ADR-007 approval ↔ STATUS 충돌 + HEAD stale + 중복 키 | **resolved** |
| F19 | minor | approver enum에 claude-reviewer 없음 | **resolved** |
| F20 | major | postprocess REVIEW 필수 필드 누락 | **resolved** |
| F21 | major | tomllib silent ignore (python 3.9) | **resolved** |
| F22 | minor | wrapper 인자 검증 부족 | **resolved** |
| F23 | major | pre-review-gate 0 checks도 PASS | **resolved** (self-smoke 5 checks) |
| F24 | minor | new-project.sh escape | **resolved** |
| F25 | minor | phases/02 "A.5 통합 리뷰" 잔존 | **resolved** |
| F26 | minor | ADR.template front-matter 없음 | **resolved** |

### BC.1 통합 cross-review (codex `019e5db9`, .harness/reviews/bc1-20260525-integrated.md)

| ID | severity | 제목 | 상태 |
|---|---|---|---|
| F27 | major | 생성 프로젝트가 scripts/ 명령 실행 불가 | **resolved** (new-project.sh 갱신 + skills/phases `$HARNESS_ROOT/scripts/...` + wrapper SCRIPT_DIR sibling) |
| F28 | major | Phase 00 artifact 이름·위치 mismatch | **resolved** (intake-checklist→intake.md / api-spec→openapi.yaml placeholder) |
| F29 | minor | _generic module-skeleton 의존 방향 모순 | **resolved** (depends-on 명확화 + 의존성 역전 설명 + 그래프 라벨) |
| F30 | minor | malformed REVIEW validation 부재 | **resolved** (skills/request-codex-review step 5 추가) |
| F31 | minor | API spec template 너무 thin | **resolved** (CRUD + 표준 errors + X-Request-Id + auth variants + ErrorCode enum) |
| F32 | minor | frontend collab gate 측정 불가 | **resolved** (intake §9 artifact-based 체크리스트) |
| F33 | minor | 생성 프로젝트에 INBOX 위치 없음 | **resolved** (HARNESS §4.2 .harness/inbox/ + new-project.sh + skills) |
| F34 | **blocker** | HC-8 위반 (dry-run ≠ user approval) | **resolved** (web-service/test-strategy §10 강화 + module-skeleton HC-8/9 hook 의무) |

**남은 open: 0개** ✓ (HC 위반 0, blocker 0)

### Phase E (Dogfood) 발견 — 하니스 자체 결함 후보

| ID | severity | 제목 | 상태 | 발견 dogfood |
|---|---|---|---|---|
| F40 | minor | wrapper의 `ROOT="$(git rev-parse --show-toplevel)"`가 monorepo sub-project (예: `examples/todo-api/`)에선 *상위 repo*를 가리킴 → `.harness/config.toml` 못 찾음 | **resolved** (codex-review.sh + codex-exec-review.sh에 `find_project_root()` 추가, 가장 가까운 `.harness/` 조상 탐색) | todo-api |
| F41 | minor | `plan-blueprint` skill / web-service bootstrap이 "Blueprint codex review 전 minimal API spec 채우기"를 명시 강제 안 함 → spec-first 프로젝트에서 빈 명세로 contract test 통과 가능 (todo-api bp.1에서 발견 — codex가 F35로 잡음) | open (Phase E 종결 시 처리 또는 후속 라운드) | todo-api |
| F42 | minor | `codex-exec-review.sh`를 *repo root* (`/Users/satgym/work/harness/`)에서 호출하면 `find_project_root()`가 git toplevel로 fall-through → `cd "$ROOT"` 후 `.harness/prompts/...` relative path는 존재 안 함 → "Required: --prompt-file <existing path>" 에러. F40 fix가 *위 → 아래* monorepo 케이스는 해결했지만 *root → 어떤 sub-project?* 케이스는 모호. **개선안**: root에서 호출 시 (a) `--project examples/<name>` 인자 의무, (b) 또는 `.harness/` sub-dir 자동 탐색 (단 다중 sub-project 시 모호함 — 사용자 confirm), (c) 또는 명확한 error message ("not a starpin project root; cd into examples/<name>/") | open — Phase E 종결 또는 후속 라운드에서 처리 (현재 manual cd로 우회 가능) | starpin Phase 02 |
| F43 | info | HARNESS §5.4 재리뷰 빈도 "3회 초과 시 사용자 확인" — autonomous 모드에서 *누가* 이 의무를 발동하는지 mechanism 부재. starpin Phase 02 batch1+m4+batch2 합 5회였으나 *산출물 단위*로 보면 동일 산출물 3회 미만 — 발동 안 함. autonomous에서 self-test에 `codex_round_count_per_artifact` 추적 추가 후보. **개선안**: HARNESS §5.4 본문에 "autonomous 모드는 self-test의 `drift_trigger_check`에 codex_round_count_per_artifact 항목으로 갈음" 명문화. | open — Phase E 종결 시 base HARNESS §5.4 amend 후보 | starpin Phase 02 (ADR-005 작성 중 발견) |
| F44 | info | ADR-005 v1.1에서 만든 self-test schema (`capability_sensing` / `base_drift_signals` / `base_promotion_signals` / `drift_trigger_check`)가 *autonomous 모드 모든 프로젝트에 generalize 가능* — base `templates/SELF-TEST.template.md` 또는 base `skills/autonomous-self-test.md` promotion 후보. 단 starpin이 autonomous v0.6 *첫 dogfood*이라 ≥1 검증 evidence만 누적; ≥2 precedent 필요 (HARNESS §13.6) — todo-api Phase 02 재개 또는 다른 autonomous 프로젝트에서 동일 패턴 사용되면 promotion ADR 작성. | tracked — promotion candidate | starpin Phase 02 (ADR-005 v1.1 작성 시 발견) |
| F45 | minor | `claim-exclusivity-contract` v0.3 Step 2 enforcement matrix는 `backend/src/claim/api.ts`의 transfer-API-grep을 *claim invariant 검증의 일부*로 명시하지만, 실제 enforcement는 *jest unit test* (M4 plan §5.1)에서만 이루어짐 — skill 자체엔 transfer grep step 없음. M4 plan §3.2 claim-admin-paths.yaml의 `transfer_scan` entry도 *informational*로 표기. → I-2 (영구 — no transfer) invariant가 *skill로 결정적 enforce되지 않음*. 개선안: skill을 v0.4로 bump, Step 6 신규 ("transfer-scan in YAML.transfer_scan paths") 추가. 그 시점에 `transfer_scan` entry를 informational → enforced로 격상. | tracked — `claim-exclusivity-contract` v0.4 후보 (M4 implement 시점) | starpin Phase 02 (Designer sensing call afccb16c) |
| F46 | minor | `geolocation-pii-redaction` v0.4의 sinks_deny regex가 Sentry-Cocoa의 *modern API*를 놓침. 현재 패턴 `Sentry\.(captureMessage\|captureException\|setExtra\|setContext\|addBreadcrumb\|configureScope)`는 *legacy Sentry namespace* 만 매치 — modern iOS Sentry SDK는 `SentrySDK.capture(error:)` / `SentrySDK.capture(message:)` / `SentrySDK.configureScope { scope in scope.setExtra(...) }` 사용. Firebase Crashlytics Swift도 `Crashlytics.crashlytics().log(...)` / `setCustomValue(_:forKey:)` 사용 — 현 패턴 `FirebaseCrashlytics\.getInstance\(\)\.(log\|setCustomKey)`는 *Android API only*. → M6 client-app iOS code에서 token/GPS가 silently leak될 risk. 개선안: skill을 v0.5로 bump, `SentrySDK\.` + `Crashlytics\.crashlytics\(\)` + `setCustomValue` 패턴 추가 (Designer round 의무). | **resolved** v0.5 Active 2026-05-26T13:55 | starpin Phase 02 (Designer sensing call afccb16c) |
| F47 | minor | ADR-005 v1.2 self-test §user_gate_required_check가 *runtime atomicity* (race condition) 같은 *동적 안전 invariant*를 *static grep*만으로는 catch 못함. 증거: starpin M1 r1 self-test verdict가 `ready_for_codex_review`였으나 codex가 BLOCKER (F50 SELECT-then-UPDATE race window) 감지. autonomous 모드에서 self-test PASS → 사용자 우회 진행 가능한데, 핵심 안전 결함을 놓침. **개선안 (ADR-005 v1.3 amend 후보)**: (a) self-test에 `race_pattern_grep` 신규 check — `SELECT.*WHERE.*token_hash` followed by separate `UPDATE.*WHERE.*token_hash` 같은 *split critical section* pattern 발견 시 `needs_codex_review` 강제, (b) self-test PASS 자체가 *codex review를 대체하지 않음* 명문화. | tracked — ADR-005 v1.3 amend 의무 (M1 r3 closure 동반) | starpin M1 r1 r2 (codex F50 + r2 F64) |

**메타 dogfood 학습 채널** — todo-api + temp-sensor + starpin 진행 중 발견되는 하니스 자체 결함을 이 표에 누적 (HARNESS §10 dogfood 임시 변경 한도 3회 — F40/F42는 *변경 발생 안 함, 추적만*이라 한도 미포함). F45/F46은 *local skill 변경*이라 base 한도와 무관.

**Designer sensing source** — `afccb16c` (2026-05-26T13:00 — starpin Phase 02 closure 직후, Phase 03 진입 전 능동 sensing). 7 권장 액션 출처. 본 표의 F45/F46이 그 결과 등재.

## INBOX

- **0 unread** ✓
- 처리 완료: `INBOX/processed/codex-feedback-20260525-seed-review.md`, `codex-feedback-20260525-v0.3-review.md`

## Notes

### Codex 토큰·재리뷰
- **Cumulative tokens**: A.0a = 79,748 / A.0f = 131,909 / A.5 = 107,011 / BC.1 = 129,594 / **누적 = 448,262**
- **재리뷰 횟수** (HARNESS 대상, §5.4): 3회 (A.0a, A.0f, A.5). A.5c spot-check가 4회째 — 사용자 명시 확인 필요.
- **HARNESS.md 대상 cross-review**: 2회 (A.0a seed, A.0f v0.3). 3회 째 가능, 4회 째 §5.4에 따라 사용자 확인 필요.

### §9 #2 해석 — A.1 별도 리뷰 vs 통합
- HARNESS §9 임시 게이트 Exit #2는 "Codex review를 받음" — 엄격 해석 시 sub-phase마다 별도 리뷰 필요
- 그러나 A.0b/c/d/e/g는 wording/패치 수준이라 별도 리뷰 안 받음 (직전 라운드 리뷰가 가이드 역할)
- A.1 roles/ 5파일은 *새* 산출물이라 의미 있는 리뷰 대상
- **트레이드오프**:
  - **별도 리뷰 즉시**: 더 안전, 그러나 토큰 추가 소비 (예상 ~50K), HARNESS 외 대상 1회차
  - **A.5 통합 cross-review**: 비용 효율, 그러나 A.2/A.3/A.4 작업 중 roles/ 결함이 누적될 위험
- §9 정의 자체에 이 모호함이 있다는 점은 다음 라운드(예: A.5 통합 리뷰)에서 새 finding으로 표면화될 가능성

### A.1 산출물 개요
- `roles/README.md` — 4개 역할 안내 + 도구 권한 매트릭스 + 역할 간 흐름
- `roles/claude-implementer.md` — 기본 역할 1 (Claude=구현자) 책임/입력/출력/제약/워크플로우/안티패턴
- `roles/codex-reviewer.md` — 기본 역할 2 (Codex=리뷰어) 책임/REVIEW 양식/검토 체크리스트/INBOX 권한
- `roles/claude-reviewer.md` — 역할 스왑 (드뭄) 발동 조건/차이점/anti-self-review
- `roles/codex-implementer.md` — 역할 스왑 (드뭄) 발동 조건/워크플로우/제약

### 알려진 한계
- codex 비대화형 stdout이 INBOX 양식을 따르지 않음 → A.3 `codex-exec-review.sh`가 변환 책임
