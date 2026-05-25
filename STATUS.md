# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식을 따른다.
> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | A — 골격 구축 |
| Active sub-phase | **A.0g 완료 → A.1 진입 대기** |
| Strictness | strict |
| Harness version | **v0.4** (HARNESS.md, 위 변경 사항 stage됨, commit 대기) |
| Git | initialized, main, HEAD = `0dbba69` (seed commit). v0.4 변경은 staged + untracked |
| Last updated | 2026-05-25T11:25 by Claude |

## Active gate

- **Gate**: A.0g (minor 3종 wording 정리) → **A.1** (`roles/` 작성)
- **Blocked on**: 사용자가 A.0g 결과(v0.4 변경) 검토 + 승인. 승인 시 git commit + A.1 진입
- **Approval needed**: yes — HARNESS v0.4 + INBOX/README.md 패치 + INBOX 정리(processed 이동)

## Required reads (이 세션 시작 시)

1. `HARNESS.md` v0.4
2. `STATUS.md` (이 파일)
3. `DECISIONS.md`
4. `AGENTS.md` / `CLAUDE.md`
5. `INBOX/README.md` (v0.4 패치 — `deferred_reason` 분리, §11 reference)
6. (참고) `INBOX/processed/codex-feedback-20260525-v0.3-review.md` — A.0f 재리뷰 원본
7. (참고) `INBOX/processed/codex-feedback-20260525-seed-review.md` — A.0a 첫 리뷰 원본

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
  scope: INBOX 체크 의무(F5), INBOX 쓰기 예외(F6), canonical enum(F12), HC-7/8/9 강조

- artifact: CLAUDE.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: HC-7/8/9 강조 + enum 참조 (F12)

- artifact: DECISIONS.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: ADR 양식 표준화(F8), ADR-003 본문 ADR-003a 표기 수정(F8)

- artifact: INBOX/README.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:13
  scope: unread 정의(F10), Codex 쓰기 예외(F6 보강)

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
  scope: deferred(<이유>) → deferred + deferred_reason 분리(F14)
```

## Decision summary

- **ADR-001**: git repo 배포 + 메타 부트스트랩 — 실행됨 (seed commit `0dbba69`)
- **ADR-002**: Codex 개입은 파일 기반 비동기(A) 기본, 사용자 codex 세션(C) 보조, MCP(B) 후순위
- **ADR-003**: 모델/계정은 `.harness/config.toml`에서 설정, 코드 하드코딩 금지
- **ADR-004**: Strictness `strict/balanced/autonomous`, 디폴트 strict. Blueprint는 모든 모드 사용자 승인 (v0.2)
- **ADR-005**: 프로젝트 타입 우선순위 — `web-service` 깊이, 나머지 `_generic` 골격만

## Roadmap

### Phase A — 골격 구축
- [x] **A.0** 사용자 5개 결정 + 씨앗 문서 6종
- [x] **A.0a** Codex seed-review 수령
- [x] **A.0b** Blocker + 핵심 major → HARNESS v0.2
- [x] **A.0c** v0.2 사용자 승인
- [x] **A.0d** 작은 finding 5종 패치
- [x] **A.0e** F7 + 추가 제안 5개 → HARNESS v0.3 + git init + seed commit
- [x] **A.0f** Codex 재리뷰 (3 new minor, verdict: yes_with_minor_fixes)
- [x] **A.0g** F13/F14/F15 정리 → HARNESS v0.4 + INBOX/README 패치 + INBOX 정리(processed/)
- [ ] **A.1** ← **다음**: `roles/` — claude-implementer, codex-reviewer, claude-reviewer(swap), codex-implementer(rare)
- [ ] **A.2** `templates/` — BLUEPRINT, MODULE-PLAN, REVIEW, ADR, POSTMORTEM, STATUS 양식 (이 때 §4.3 artifact-specific enum 확정)
- [ ] **A.3** `scripts/` — codex-review.sh(F13의 config base branch 자동 주입 구현), codex-exec-review.sh, pre-review-gate.sh, new-project.sh
- [ ] **A.4** `phases/` — 00-intake ~ 06-handoff (완성 시 §9 자동 폐기 → ADR로 명문화)
- [ ] **A.5** Phase A 전체 cross-review → HARNESS v0.5 정식

### 이후 phases
- **Phase B**: `skills/` 9종
- **Phase C**: `project-types/` (web 우선)
- **Phase D**: 자기보호 메커니즘 정식화
- **Phase E**: Dogfood + v1.0

## Next action

- **사용자**: A.0g 결과(v0.4 + INBOX 정리) 검토. 승인 시 → Claude가 git commit 수행 후 A.1 진입.
- **Claude**: 사용자 승인 후 commit + A.1 (`roles/` 디렉토리 4개 파일 작성).
- **Codex**: 추가 지시 전까지 대기. (A.1은 텍스트 문서라 다음 codex 리뷰는 A.1 종료 시점 또는 A.5 통합 cross-review.)

## Open findings

### A.0a seed review (모두 resolved, processed)
| ID | severity | 상태 |
|---|---|---|
| F1~F12 | (mixed) | all resolved (A.0f confirmed) |
| Proposal 1~7 | — | all resolved (#5, #6 이월분은 A.0g에서 F13/F14로 완전 해결) |

### A.0f v0.3 review (모두 resolved)
| ID | severity | 제목 | 상태 |
|---|---|---|---|
| F13 | minor | §12.2 branch base 자기 모순 | **resolved (A.0g HARNESS §12.2)** |
| F14 | minor | Status enum 불일치 + INBOX deferred 표기 | **resolved (A.0g HARNESS §4.3 + INBOX/README.md)** |
| F15 | minor | §9 ↔ §11 cross-ref | **resolved (A.0g HARNESS §9 Exit 기준 #6)** |

**남은 open: 0개** ✓

## INBOX

- **0 unread** ✓
- 모든 처리 완료된 codex 리뷰는 `INBOX/processed/`에 보존:
  - `codex-feedback-20260525-seed-review.md` (A.0a, 12 findings + 7 proposals)
  - `codex-feedback-20260525-v0.3-review.md` (A.0f, PART A 확인 + PART B 3 minor findings)
- **unread 정의**: `INBOX/codex-feedback-*.md` with front-matter `status: open` (README.md / `processed/` 제외)

## Notes

- **Cumulative Codex tokens** (HARNESS §5.4):
  - A.0a seed-review = 79,748
  - A.0f v0.3-review = 131,909
  - **누적 = 211,657**
- **재리뷰 횟수** (§5.4): HARNESS.md 대상 2회 (A.0a seed, A.0f v0.3). 3회 째 가능하지만, A.0g 변경은 wording 수준이라 별도 재리뷰 없이 A.5 통합 cross-review에서 검증 예정.
- **알려진 한계 (A.3에서 자동화 대상)**: codex의 비대화형 stdout이 INBOX front-matter 양식을 따르지 않고 트레이스 + 결과가 섞임. A.3 작성 시 `scripts/codex-exec-review.sh`가 codex 출력을 받아 표준 INBOX 양식으로 변환(트레이스 제거, front-matter 부착)하는 책임. 그 전까지는 raw 파일을 `processed/`에 보존하고 STATUS에 finding ID + 출처 라인을 명시.
- **A.1 작업 예고**: roles/ 4개 파일은 텍스트 문서이고 v0.4 헌법 위에서 작성. codex 리뷰는 별도로 트리거하지 않고 다음 재리뷰는 A.5 통합 cross-review에서.
