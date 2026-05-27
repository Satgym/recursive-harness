# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식.
> 모든 세션 시작 시 읽고, 종료 시 갱신.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | **starpin v0.3.0 SHIPPED** (OAuth 3-provider production + Hara v1.3+v1.5 inflight) |
| Active sub-phase | (대기) — v1.6 trigger F123 또는 starpin v0.4 (sky-3d / mobile / ingest) |
| Strictness | autonomous-within-delegation |
| Harness version | **v1.3** + v1.4/v1.5 inflight (F120/F121/F122/F124 applied; F123 v1.6 carry-over) |
| Git | main; v1.3 commit `b71324d` + v0.2 commit `bdc1d24` + v0.3 commits pending |
| Last updated | 2026-05-27 by Claude (starpin v0.3.0 SHIPPED — 18 suites/198 pass; codex 0 blocker + 5 major + 1 minor 모두 closed) |

## Active gate

- (none — starpin v0.2.0 + Hara v1.3 ship 완료)

### v1.4 patches inflight (실 dogfood가 노출)
- **F120** (resolved): gen_eslint_lock nested subtree path 미지원 — `discover_child_lockfiles()` rglob recursive 적용
- **F121** (resolved): `src/<child>/**` hard-coded path — locked-interface `## File ownership` 섹션에서 `parse_owned_paths()` 추출
- **F122** (open, v1.5 carry-over): ESLint lock이 stable parent module (catalog/service.js 등) reach-around 미차단 — `consumed_stable_modules` field 신설 + helper enhancement 필요

## Required reads (이 세션 시작 시)

1. `HARNESS.md` v1.0 (→ v1.1 작성 중)
2. `STATUS.md` (본 파일)
3. `DECISIONS.md` (최근 ADR-008 ~ ADR-010 작성 중)
4. `CLAUDE.md` / `AGENTS.md`
5. `INBOX/` (현재 0 unread)
6. (Fleet Mode 작업 중) `phases/02-module-plan.md` + `phases/05-integration.md` (amend 대상)

## Approved artifacts

> v0.1~v0.6 시기의 누적 approval record는 git log + DECISIONS.md ADR-001~ADR-007에 보존.
> 본 섹션은 *현재 유효한 최신 버전*만 유지.

```yaml
- artifact: HARNESS.md
  version_or_hash: "v1.2"
  approver: user
  mode: strict
  approved_at: 2026-05-27
  scope: ADR-011 Fleet enforcement 강화 — §14.8/9/10 + lock-grep-gate + LOCKED-INTERFACE template + Phase 05 gate

- artifact: skills/lock-grep-gate.md + skills/spawn-subtree-prompts.md (v1.2 amend)
  version_or_hash: "v0.1 / amend"
  approver: user
  approved_at: 2026-05-27
  scope: lock+invariant gap detection skill + spawn skill 강화 (per-child config, LOCKED-INTERFACE 인스턴스화, strategy 실 절차)

- artifact: templates/LOCKED-INTERFACE.template.md + SUBTREE-PROMPT/MERGE-REPORT/SPLIT-DECISION-ADR (v1.2 amend)
  version_or_hash: "v0.1 / amend"
  approver: user
  approved_at: 2026-05-27
  scope: 6 필수 섹션 + runtime/type-only 구분 + INV evidence 의무 + inter_child_consume_strategy field

- artifact: examples/starpin-fleet/
  version_or_hash: "v0.1.0 real-world dogfood (same-worktree)"
  approver: user
  approved_at: 2026-05-27
  scope: 4-child Fleet pattern evidence (45 tests PASS, 11 unique v1.2 findings)

- artifact: HARNESS.md (v1.1)
  version_or_hash: "v1.1"
  approver: user
  approved_at: 2026-05-27
  scope: ADR-010 Fleet Mode 도입 (v1.2로 superseded)

- artifact: phases/01-blueprint.md + phases/02-module-plan.md + phases/05-integration.md
  version_or_hash: "v1.1-fleet-amend"
  approver: user
  mode: strict
  approved_at: 2026-05-27
  scope: cross-cutting invariant 의무 + split-decision step + merge-collection step

- artifact: templates/SUBTREE-PROMPT + SUBTREE-STATUS + SPLIT-DECISION-ADR + MERGE-REPORT + BLUEPRINT(§8.5/§8.6 amend)
  version_or_hash: "v0.1 / amend"
  approver: user
  mode: strict
  approved_at: 2026-05-27
  scope: Fleet Mode 4 신규 templates + BLUEPRINT cross-cutting/expected-modules 추가

- artifact: skills/estimate-project-scope.md + skills/spawn-subtree-prompts.md
  version_or_hash: "v0.1"
  approver: user
  mode: strict
  approved_at: 2026-05-27
  scope: Fleet Mode 2 신규 base skills — split heuristic + worktree/prompt 자동 생성 (F73/F74/F76 mechanical 강제 포함)

- artifact: examples/fleet-mini/
  version_or_hash: "v0.1.0 mechanical simulation"
  approver: user
  mode: strict
  approved_at: 2026-05-27
  scope: Fleet pattern 작동 evidence (32 tests PASS, dogfood_simulation:true flag); 정식 dogfood는 v1.2 real-world로 후속

- artifact: HARNESS.md (v1.0)
  version_or_hash: "v1.0"
  approver: user
  approved_at: 2026-05-27
  scope: ADR-009 Phase E ship + 3 dogfood 검증 (v1.1로 superseded)

- artifact: examples/starpin/v0.1.0
  version_or_hash: "RELEASE.md v0.1.0/v0.1.1"
  approver: user
  mode: autonomous (delegated)
  approved_at: 2026-05-27
  scope: 3차 dogfood ship

- artifact: examples/temp-sensor/v0.1.0
  version_or_hash: "RELEASE.md v0.1.0"
  approver: user
  mode: strict
  scope: 2차 dogfood ship — embedded 도메인 검증

- artifact: skills/budget-binary-size.md
  version_or_hash: "v0.1"
  approver: user
  approved_at: 2026-05-27
  scope: 첫 base promotion (ADR-008) — domain-agnostic Strategy
```

## Decision summary

최근 ADR만 (전체는 DECISIONS.md):

- **ADR-012** (proposed 2026-05-27): v1.3 AST-level lock + Strategy helper scripts 실 구현 — §14.8 promote (ESLint AST primary, grep fallback) + 4 helper scripts (gen_stub/gen_ambient/topo_sort/gen_eslint_lock) + lock-eslint-gen skill + mid-work escalation + codex 대체 heuristic + ESM jest seed
- **ADR-011** (accepted): v1.2 Fleet enforcement 강화 — §14.8 lock+invariant grep gate / §14.9 inter-child consume timing / §14.10 scope-bounded gates + lock-grep-gate skill + LOCKED-INTERFACE template
- **ADR-010** (accepted): v1.1 Fleet Mode — 재귀 coordinator + Phase 02 split-decision + Phase 05 merge-collection + 9 Fleet rules
- **ADR-009**: Hara v1.0 승격 — Phase E §10 5 criteria 충족 (3 dogfood)
- **ADR-008**: 첫 base promotion — `budget-binary-size`
- **ADR-001~ADR-007**: 초기 골격 — DECISIONS.md 참조

## Roadmap

- [x] Phase A~E (v0.1~v1.0) — 골격 + skill 풀 + project-type seed + 자기보호 + 3 dogfood ship
- [x] Phase F (v1.1) — Fleet Mode ✓ SHIPPED 2026-05-27 (ADR-010 accepted)
- [x] Phase G (v1.2) — Fleet enforcement amend ✓ SHIPPED (ADR-011 accepted)
- [x] **Phase H (v1.3) — AST lock + Strategy helper scripts** ✓ proposed (ADR-012, awaiting user)
  - 4 helper scripts (gen_stub / gen_ambient / topo_sort / gen_eslint_lock) — *실 작동* + retroactive validation PASS
  - lock-eslint-gen skill — fail-closed (sibling internal path + named allowlist) AST gate; v1.2 lock-grep-gate는 fallback
  - mid-work escalation 명세 (F70-fleet-1), codex 대체 heuristic 4 조건 (F70-fleet-3), ESM jest seed (F86)
  - codex review 2 blocker + 5 major + 1 minor 모두 patched (F110~F117)
- [ ] Phase I (v1.4 후보) — custom AST walker (re-export barrel / namespace import) + real git worktree dogfood + wall-time benefit 측정 + out-of-band confirmation + new-project.sh esm-jest seed 자동화

## Next action

- v1.3 사용자 승인 대기 → ADR-012 accepted + commit
- v1.4 trigger 후보:
  - custom AST walker (re-export barrel + namespace import — v1.3 partial)
  - real git worktree dogfood (F70-fleet-2 / F92)
  - wall-time benefit 측정 (large project)
  - out-of-band confirmation 통합 (F100 production-grade — Slack/email)
  - `new-project.sh` esm-jest seed 자동화 (F116)
  - SPLIT-DECISION-ADR의 codex_review_replacement preflight heuristic 자동 평가 (F117)

## Open findings (carry-over)

dogfood 진행 중 발견된 하니스 자체 결함 후보 — Phase F 또는 v1.2에서 처리 후보:

| ID | severity | 제목 | 상태 |
|---|---|---|---|
| F41 | minor | `plan-blueprint` skill이 spec-first 프로젝트의 minimal API spec 강제 안 함 | open (v1.2 후보) |
| F42 | minor | `codex-exec-review.sh` root에서 호출 시 sub-project 모호 — manual cd 우회 가능 | open (v1.2 후보) |
| F43 | info | autonomous 재리뷰 빈도 카운터 발동 mechanism 부재 — self-test schema에 통합 후보 | tracked |
| F44 | info | ADR-005 v1.3 self-test schema → base `templates/SELF-TEST.template.md` promotion 후보 (≥2 precedent 대기) | tracked |
| F47 | info | self-test PASS가 race condition 같은 동적 invariant catch 못함 (ADR-005 v1.3로 명문화 완료) | resolved-meta (정책 명문화로 처리) |

## INBOX

- **0 unread** ✓
- 처리 완료: `INBOX/processed/` (Phase A 시기 seed + v0.3 review)

## Notes

- **Cumulative codex tokens** (대략): A.0a + A.0f + A.5 + BC.1 + dogfood reviews 합 = 약 600K+ (참고용; 정확치는 codex 응답 헤더)
- **v1.1 작업 원칙** (사용자 지시 2026-05-27): "하니스가 길어지면 claude가 규칙을 안 지킴 → obsolete 적극 제거, 단순 append 금지"
