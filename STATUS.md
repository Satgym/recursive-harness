# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식.
> 모든 세션 시작 시 읽고, 종료 시 갱신.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | **v1.1 Fleet Mode amend — codex review 통과 (1 blocker + 6 major + 1 minor 모두 resolved)** |
| Active sub-phase | F71~F78 patches 적용 완료 → 사용자 승인 게이트 → commit |
| Strictness | strict (하니스 자체 변경은 항상 strict) |
| Harness version | v1.0 ship 완료 → **v1.1 작성 완료, 승인 대기** |
| Git | main; v0.1.1 starpin hardening commit `9e04d24` + STATUS `a9a5b3f` |
| Last updated | 2026-05-27 by Claude (v1.1 codex review patches + fleet-mini simulation) |

## Active gate

- **Gate**: v1.1 묶음 사용자 승인 → commit
- **Blocked on**: 사용자 승인
- **Approval needed**: yes (v1.1 전체 묶음 — HARNESS §14 + Phase 02/05 amend + 4 templates + 2 base skills + ADR-010 + examples/fleet-mini *mechanical simulation* + F71~F78 patches + cleanup pass)

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
  version_or_hash: "v1.0"
  approver: user
  mode: strict
  approved_at: 2026-05-27
  scope: ADR-009 Phase E ship + 3 dogfood 검증 + base promotion 첫 사례

- artifact: examples/starpin/v0.1.0
  version_or_hash: "RELEASE.md v0.1.0/v0.1.1"
  approver: user
  mode: autonomous (delegated)
  approved_at: 2026-05-27
  scope: 3차 dogfood ship — adaptive vision 검증 완료

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

- **ADR-010** (in progress): v1.1 Fleet Mode — 재귀 coordinator + Phase 02 split-decision + Phase 05 merge-collection
- **ADR-009**: Hara v1.0 승격 — Phase E §10 5 criteria 충족 (3 dogfood)
- **ADR-008**: 첫 base promotion — `budget-binary-size` (starpin + temp-sensor → domain-agnostic)
- **ADR-001~ADR-007**: 초기 골격 (git + Codex 호출 채널 + config + Strictness + Phase A) — DECISIONS.md 참조

## Roadmap

- [x] Phase A~E (v0.1~v1.0) — 골격 + skill 풀 + project-type seed + 자기보호 + 3 dogfood ship
- [x] **Phase F (v1.1) — Fleet Mode** (재귀 coordinator)
  - [x] HARNESS §14 신설 + Phase 02/05 amend + 4 templates + 2 base skills
  - [x] CLAUDE.md / AGENTS.md 재귀 진입 모델
  - [x] ADR-010
  - [x] examples/fleet-mini *mechanical simulation* (32 tests PASS)
  - [x] Codex review (review id 84,462 tokens; 1 blocker + 6 major + 1 minor 모두 resolved)
  - [x] F71~F78 patches 적용
  - [ ] 사용자 승인 + commit ← *현재*
- [ ] Phase G (v1.2 후보) — real-world Fleet dogfood + F70-fleet-1~3 처리

## Next action

- **Claude**: 본 묶음 사용자 승인 대기. 승인 시 commit (`harness(v1.1): Fleet Mode + cleanup + codex F71~F78 closed`)
- **사용자**: v1.1 묶음 검토 — 핵심 결정 항목:
  1. HARNESS §14 9 rules가 의도와 맞는가?
  2. fleet-mini를 simulation으로 유지 OK? 정식 dogfood는 v1.2로 미루기?
  3. depth ≤ 2 cap, dogfood_simulation 예외 등 게이트 강도 적절한가?
- **Codex**: 본 라운드 review 완료. 다음 *real-world* dogfood 시 재호출

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
