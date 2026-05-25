# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식을 따른다.
> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | **B — 스킬 풀** |
| Active sub-phase | **B 작업 완료 → cross-review 시점 결정 대기** |
| Strictness | strict |
| Harness version | v0.5 (Phase A 종결 commit `2267d76`) |
| Git | main, HEAD = `2267d76` (v0.5 commit). skills/ 10파일 untracked |
| Last updated | 2026-05-25T14:28 by Claude |

## Active gate

- **Gate**: Phase B (skills/ 10파일 작성) → 다음 phase (사용자 결정 — cross-review 여부 + Phase C)
- **Blocked on**: 사용자가 Phase B 결과 검토 + 다음 액션 결정 (commit + cross-review vs commit만 + Phase C 진입).
- **Approval needed**: yes — skills/ 10파일 + 옵션: codex cross-review 호출 (skills/는 새 산출물 첫 리뷰, §5.4 cost는 누적 318K)

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

### Phase B — 스킬 풀 (✓ 작업 완료, cross-review 시점 미정)
- [x] **B** `skills/` 10파일 (README + 9 skills)
- [ ] **B-review** (선택) — codex cross-review 받을지 결정
- [ ] **B-commit** — 사용자 승인 후 commit

### 이후 phases
- **Phase C**: `project-types/` (web 우선)
- **Phase D**: 자기보호 메커니즘 정식화 (drift / postmortem / conflict 실 운영 노하우 축적)
- **Phase E**: Dogfood + v1.0 (HARNESS §10 기준)

## Next action

- **사용자**: Phase B 결과(skills/ 10파일) 검토 + 다음 액션 결정:
  1. 승인 → commit만 + 바로 Phase C 진입 (codex 호출 생략, 다음 통합 라운드로 묶음)
  2. 승인 → commit + codex cross-review (skills/ 새 산출물 첫 리뷰) → finding 처리 → Phase C
  3. 일부 수정 요청
- **Claude**: 사용자 결정에 따라 진행
- **Codex**: 옵션 2 선택 시 호출 대기. 그 외 대기.

## Open findings

### A.5 통합 cross-review (codex `019e5d7c`, `.harness/reviews/a5-20260525-integrated.md`)

| ID | severity | 제목 | 상태 |
|---|---|---|---|
| F16 | major | §9 deprecation HARNESS 본문 미반영 | **resolved** (HARNESS §0/HC-4/§3 + 헤더 + §8 v0.5) |
| F17 | major | CLAUDE.md `deferred(<이유>)` 잔존 | **resolved** (CLAUDE.md INBOX 의무 갱신) |
| F18 | major | ADR-007 approval ↔ STATUS 충돌 + HEAD stale + 중복 키 | **resolved** (ADR-007 Approval 채움 + 중복 키 제거 + HEAD 갱신) |
| F19 | minor | approver enum에 claude-reviewer 없음 | **resolved** (HARNESS §4.3 + §7 approver enum 확장) |
| F20 | major | postprocess REVIEW 필수 필드 누락 | **resolved** (_codex_postprocess.py argparse 확장 + 양쪽 wrapper 전달) |
| F21 | major | tomllib silent ignore (python 3.9) | **resolved** (read_config가 python3.11/12/13 탐색 + tomli fallback + 명시적 stderr WARNING) |
| F22 | minor | wrapper 인자 검증 부족 | **resolved** (need_value helper + source mutual exclusion) |
| F23 | major | pre-review-gate 0 checks도 PASS | **resolved** (attempted_count > 0 검증 + --allow-no-checks 옵션 + harness self-smoke 5 checks) |
| F24 | minor | new-project.sh escape | **resolved** (NAME/TYPE regex 검증 + awk로 sed-safe 치환) |
| F25 | minor | phases/02 "A.5 통합 리뷰" 잔존 | **resolved** ("다음 정식 cross-review 또는 periodic audit"로 일반화) |
| F26 | minor | ADR.template front-matter 없음 | **resolved** (standalone ADR용 front-matter 가이드 주석 추가) |

**남은 open: 0개** ✓ (모두 resolved, A.5c spot-check는 §5.4 사용자 확인 필요 시에만)

## INBOX

- **0 unread** ✓
- 처리 완료: `INBOX/processed/codex-feedback-20260525-seed-review.md`, `codex-feedback-20260525-v0.3-review.md`

## Notes

### Codex 토큰·재리뷰
- **Cumulative tokens**: A.0a = 79,748 / A.0f = 131,909 / A.5 = 107,011 / **누적 = 318,668**
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
