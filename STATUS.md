# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식을 따른다.
> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | A — 골격 구축 |
| Active sub-phase | **A.3 작업 완료 → A.4 진입 대기** (scripts/ 6파일 + smoke test 통과) |
| Strictness | strict |
| Harness version | v0.4 (approved + committed) |
| Git | main, HEAD = `c83eb45` (A.2 commit). scripts/ 6파일 + tokens fix 패치 untracked |
| Last updated | 2026-05-25T13:25 by Claude |

## Active gate

- **Gate**: A.3 (`scripts/` 6파일 + smoke test 통과) → A.4 (`phases/`)
- **Blocked on**: 사용자가 A.3 결과 검토 + 승인. 승인 시 commit + A.4 진입.
- **Approval needed**: yes — scripts/ 6파일

## Required reads (이 세션 시작 시)

1. `HARNESS.md` v0.4
2. `STATUS.md`
3. `DECISIONS.md`
4. `AGENTS.md` / `CLAUDE.md`
5. `INBOX/README.md`
6. `roles/README.md` + 4개 역할 파일 (A.1 결과)
7. `templates/README.md` + 6개 양식 파일 (A.2 결과)
8. `scripts/README.md` + 4 main + 1 helper (A.3 결과; smoke-tested)
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
```

## Decision summary

- **ADR-001**: git repo 배포 + 메타 부트스트랩 — 실행됨 (seed commit `0dbba69`, A.0g `d138d05`)
- **ADR-002**: Codex 개입은 파일 기반 비동기(A) 기본, 사용자 codex 세션(C) 보조, MCP(B) 후순위
- **ADR-003**: 모델/계정은 `.harness/config.toml`에서 설정, 코드 하드코딩 금지
- **ADR-004**: Strictness `strict/balanced/autonomous`, 디폴트 strict. Blueprint는 모든 모드 사용자 승인 (v0.2)
- **ADR-005**: 프로젝트 타입 우선순위 — `web-service` 깊이, 나머지 `_generic` 골격만
- **ADR-006**: Phase A codex 리뷰는 A.0a / A.0f / A.5 3시점에만 (sub-phase별 별도 리뷰 면제)

## Roadmap

### Phase A — 골격 구축
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
- [x] **A.3** `scripts/` 6파일 (codex-review.sh / codex-exec-review.sh / pre-review-gate.sh / new-project.sh / _codex_postprocess.py / README); smoke-tested
- [ ] **A.4** ← **다음**: `phases/` 00-intake ~ 06-handoff 각 Exit 기준 (완성 시 §9 자동 폐기 → ADR-007로 명문화)
- [ ] **A.4** `phases/` — 00-intake ~ 06-handoff (완성 시 §9 자동 폐기 → ADR로 명문화)
- [ ] **A.5** Phase A 전체 cross-review → HARNESS v0.5 정식

### 이후 phases
- **Phase B**: `skills/` 9종
- **Phase C**: `project-types/` (web 우선)
- **Phase D**: 자기보호 메커니즘 정식화
- **Phase E**: Dogfood + v1.0

## Next action

- **사용자**: A.3 결과(scripts/ 6파일) 검토 + 승인. 승인 시 commit + A.4 진입 지시.
- **Claude**: 승인 후 commit → A.4 (`phases/` 7파일 — 00-intake ~ 06-handoff Exit 기준).
- **Codex**: 대기 (ADR-006에 따라 다음 리뷰는 A.5).

## Open findings

- **0 open** (모두 closed/processed)

## INBOX

- **0 unread** ✓
- 처리 완료: `INBOX/processed/codex-feedback-20260525-seed-review.md`, `codex-feedback-20260525-v0.3-review.md`

## Notes

### Codex 토큰·재리뷰
- **Cumulative tokens**: A.0a = 79,748 / A.0f = 131,909 / **누적 = 211,657**
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
