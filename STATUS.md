# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식을 따른다.
> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.

## Current

| 항목 | 값 |
|---|---|
| Project | 하니스 자체 빌드 (메타 부트스트랩) |
| Phase | A — 골격 구축 |
| Active sub-phase | **A.0d 완료 → A.0e 진입 대기** |
| Strictness | strict |
| Harness version | **v0.2** (HARNESS.md) + 작은 finding 5종 반영 (AGENTS/CLAUDE/DECISIONS/INBOX) |
| Last updated | 2026-05-25T11:03 by Claude |

## Active gate

- **Gate**: A.0d (작은 finding 5종 반영) → A.0e (HARNESS v0.3, F7 분쟁 프로토콜 + 추가 제안 5개) 전환
- **Blocked on**: 사용자가 A.0e 진행 여부 결정. A.0e가 v0.3 큰 개정이라 별도 라운드로 분리됨
- **Approval needed**: yes — A.0d 결과(이번 회차 변경)에 대한 OK + A.0e 진행 또는 다른 경로 지시

## Required reads (이 세션 시작 시)

1. `HARNESS.md` (v0.2)
2. `STATUS.md` (이 파일)
3. `DECISIONS.md` (ADR 양식 갱신됨, ADR-001~005)
4. `AGENTS.md` (A.0d에서 INBOX 체크 + 쓰기 예외 + canonical enum 반영)
5. `CLAUDE.md` (A.0d에서 HC-7/8/9 강조 + enum 참조 추가)
6. `INBOX/README.md` (A.0d에서 unread 정의 명문화 + Codex 쓰기 예외 안내)
7. `INBOX/codex-feedback-20260525-seed-review.md` (status 갱신은 A.0e 종료 시)

## Approved artifacts

```yaml
- artifact: HARNESS.md
  version_or_hash: "v0.2"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:03
  scope: 전체 파일 (HC-7/8/9, Strictness 통일, §7 STATUS 양식, §9 Bootstrap exception, §5 Review determinism)

- artifact: STATUS.md
  version_or_hash: "v0.2-format"
  approver: user
  mode: strict
  approved_at: 2026-05-25T11:03
  scope: 양식 (10섹션 stranger-proof)

- artifact: AGENTS.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: <pending — A.0d 결과 승인 시 채움>
  mode: strict
  approved_at: <pending>
  scope: INBOX 체크 의무(F5), INBOX 쓰기 예외(F6), canonical enum(F12), HC-7/8/9 강조

- artifact: CLAUDE.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: <pending>
  mode: strict
  approved_at: <pending>
  scope: HC-7/8/9 강조 + enum 참조 (F12)

- artifact: DECISIONS.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: <pending>
  mode: strict
  approved_at: <pending>
  scope: ADR 양식 강화 (Supersedes/Superseded by/Amends 필드, Approval 필드, ID 규칙), ADR-003 본문 ADR-003a 표기 수정 (F8)

- artifact: INBOX/README.md
  version_or_hash: "v0.1+A.0d-patch"
  approver: <pending>
  mode: strict
  approved_at: <pending>
  scope: unread 정의 명문화 (F10), Codex 쓰기 예외 명시 (F6 보강)
```

## Decision summary

- **ADR-001**: git repo 배포 + 메타 부트스트랩
- **ADR-002**: Codex 개입은 파일 기반 비동기(A) 기본, 사용자 직접 codex 세션(C) 보조, MCP(B)는 후순위
- **ADR-003**: 모델/계정은 `.harness/config.toml`에서 설정, 코드 하드코딩 금지 (모델 업그레이드 시 후속 정수 ADR로 Amends)
- **ADR-004**: Strictness `strict/balanced/autonomous`, 디폴트 strict. **v0.2**: Blueprint는 모든 모드 사용자 승인
- **ADR-005**: 프로젝트 타입 우선순위 — `web-service` 깊이, 나머지 `_generic` 골격만

## Roadmap

### Phase A — 골격 구축
- [x] **A.0** 사용자 5개 결정 수집 + 씨앗 문서 6종
- [x] **A.0a** Codex seed-review 수령 (12 findings + 7 제안, verdict: not ready)
- [x] **A.0b** Blocker + 핵심 major (F1/F2/F3/F9/F11) 반영 → HARNESS v0.2 + STATUS v0.2
- [x] **A.0c** v0.2 사용자 승인 (2026-05-25T11:03)
- [x] **A.0d** 작은 finding 5종 (F5/F6/F8/F10/F12) → AGENTS/CLAUDE/DECISIONS/INBOX 패치
- [ ] **A.0e** F7 분쟁 프로토콜 + 추가 제안 5개 (postmortem trigger, cost guardrails, dogfood criteria, branch/git policy, artifact front-matter) → HARNESS v0.3
- [ ] **A.0f** Phase A 씨앗 단계 전체 재리뷰 (Codex 호출) → final cleanup
- [ ] **A.1** `roles/` — claude-implementer.md, codex-reviewer.md, claude-reviewer.md(swap), codex-implementer.md(rare)
- [ ] **A.2** `templates/` — BLUEPRINT, MODULE-PLAN, REVIEW, ADR, POSTMORTEM, STATUS 양식
- [ ] **A.3** `scripts/` — codex-review.sh, codex-exec-review.sh, pre-review-gate.sh, new-project.sh
- [ ] **A.4** `phases/` — 00-intake ~ 06-handoff 각 Exit 기준 (완성 시 §9 bootstrap exception 자동 폐기)
- [ ] **A.5** Phase A 전체 Codex 리뷰 → HARNESS v0.4 (정식)

### 이후 phases (요약)
- **Phase B**: `skills/` 9종
- **Phase C**: `project-types/` (web 우선)
- **Phase D**: 자기보호 메커니즘 정식화
- **Phase E**: Dogfood + git 레포 출시

## Next action

- **사용자**: A.0d 변경 확인 → 승인 / 수정 지시. 동시에 A.0e 진행 방식 선택 (옵션은 다음 응답에서 제시 예정).
- **Claude**: 사용자 승인 후 A.0e 진행.
- **Codex**: 추가 지시 전까지 대기. 능동 INBOX 피드백은 환영.

## Open findings

| ID | severity | 제목 | 상태 |
|---|---|---|---|
| F1 | blocker | Bootstrap deadlock | resolved (v0.2 §9) |
| F2 | major | Blueprint 승인 정의 없음 | resolved (v0.2 §7 Approval record) |
| F3 | major | Strictness 표↔워크플로우 모순 | resolved (v0.2 §2) |
| F4 | major | STATUS A.0 상태 모호 | resolved (v0.2 §7 양식 + Active gate 명시) |
| F5 | minor | AGENTS.md INBOX 체크 의무 누락 | **resolved (A.0d AGENTS.md)** |
| F6 | major | Codex INBOX 쓰기 vs "수정 금지" 충돌 | **resolved (A.0d AGENTS.md + INBOX/README.md)** |
| F7 | major | Claude/Codex 분쟁 해결 프로토콜 부재 | open (A.0e — HARNESS v0.3) |
| F8 | minor | ADR-003a 표기 + Supersedes/Amends 필드 누락 | **resolved (A.0d DECISIONS.md)** |
| F9 | major | STATUS handoff stranger-proof 부족 | resolved (v0.2 §7) |
| F10 | minor | INBOX unread 정의 부정확 | **resolved (A.0d INBOX/README.md)** |
| F11 | major | 보안 hard constraint 부재 | resolved (v0.2 HC-7/8/9) |
| F12 | info | 머신용 canonical enum 표준화 | **resolved (A.0d AGENTS.md + CLAUDE.md)** |

**남은 open: 1개 (F7)**

추가 제안 7개:
- #1 Phase A bootstrap policy: 부분 resolved (v0.2 §9)
- #2 Postmortem triggers: open (A.0e)
- #3 Cost guardrails: open (A.0e)
- #4 Dogfood success criteria: open (A.0e — Phase E 정의 강화로)
- #5 Branch/git policy: open (A.0e — git init 시점 포함)
- #6 Artifact front-matter 표준: open (A.0e)
- #7 Review determinism: resolved (v0.2 §5)

**A.0e 작업 범위**: F7 + 추가 제안 #2/#3/#4/#5/#6 = HARNESS v0.3로 통합

## INBOX

- **1 unread** — `INBOX/codex-feedback-20260525-seed-review.md`
  - 11/12 findings resolved, 1 open (F7)
  - 추가 제안 2/7 resolved, 5 open (모두 A.0e 대상)
  - 전체 처리(A.0f 완료) 후 `INBOX/processed/`로 이동 예정
- **unread 정의**: `INBOX/codex-feedback-*.md` with `status: open` (README.md, `processed/` 제외)

## Notes

- A.0d에서 처리된 변경은 모두 작은 파일 패치(편집). HARNESS 자체는 v0.2 유지.
- A.0e는 HARNESS.md를 v0.3로 끌어올리는 큰 개정이라 별도 라운드로 분리. 부담을 균등 배분.
- A.1 진입 전에 ADR-001 실행(git init) 필요 — A.0e 끝나는 시점 또는 A.1 시작 시점에 사용자 승인 받고 수행.
- A.0f에서 codex re-review를 받아 v0.2/v0.3 작업이 처음 12 findings를 제대로 닫았는지 검증.
