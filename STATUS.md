# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식.
> 모든 세션 시작 시 읽고, 종료 시 갱신.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | **v1.1 Fleet Mode SHIPPED (accepted 2026-05-27)** |
| Active sub-phase | (대기) — 다음 real-world Fleet dogfood 또는 별도 ask |
| Strictness | strict (하니스 자체 변경은 항상 strict) |
| Harness version | **v1.1** |
| Git | main; v1.1 commit `817885e` |
| Last updated | 2026-05-27 by Claude (v1.1 ADR-010 accepted, Approved artifacts 등재) |

## Active gate

- (none — v1.1 ship 완료)

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
  version_or_hash: "v1.1"
  approver: user
  mode: strict
  approved_at: 2026-05-27
  scope: ADR-010 Fleet Mode 도입 — §14 신설 + 9 rules + 재귀 coordinator (depth ≤ 2)

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

- **ADR-010** (accepted 2026-05-27): v1.1 Fleet Mode — 재귀 coordinator + Phase 02 split-decision + Phase 05 merge-collection + 9 Fleet rules + cleanup pass
- **ADR-009**: Hara v1.0 승격 — Phase E §10 5 criteria 충족 (3 dogfood)
- **ADR-008**: 첫 base promotion — `budget-binary-size` (starpin + temp-sensor → domain-agnostic)
- **ADR-001~ADR-007**: 초기 골격 (git + Codex 호출 채널 + config + Strictness + Phase A) — DECISIONS.md 참조

## Roadmap

- [x] Phase A~E (v0.1~v1.0) — 골격 + skill 풀 + project-type seed + 자기보호 + 3 dogfood ship
- [x] **Phase F (v1.1) — Fleet Mode** (재귀 coordinator) ✓ SHIPPED 2026-05-27 (ADR-010 accepted)
- [ ] Phase G (v1.2 후보) — real-world Fleet dogfood + F70-fleet-1~3 처리 + wall-time benefit 측정

## Next action

- v1.1 ship 완료. 대기 — 다음 사용자 ask 또는 real-world Fleet dogfood 시작.
- v1.2 trigger 후보: 실 large project에 Fleet 적용 → wall-time benefit 측정 + F70-fleet-1~3 (escalation 위치, 실 git worktree, codex 대체 heuristic) 처리

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
