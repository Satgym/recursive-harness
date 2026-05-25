# STATUS

> 현재 작업의 단일 진실 출처(SoT). HARNESS.md §7 양식을 따른다.
> 모든 세션은 시작 시 이걸 읽고, 종료 시 이걸 갱신한다.
> 본 파일은 front-matter 대신 §Current 표를 메타데이터로 사용.

## Current

| 항목 | 값 |
|---|---|
| Project | <project name> |
| Phase | <e.g. 01-blueprint / 03-implement / 04-cross-review> |
| Active sub-phase | <e.g. M3.implement.handler> |
| Strictness | strict | balanced | autonomous |
| Harness version pin | <e.g. v0.5> |
| Git | <branch>, HEAD = `<sha>` |
| Last updated | <ISO timestamp> by claude | codex | user |

## Active gate

- **Gate**: <current-stage → next-stage>
- **Blocked on**: <누가 / 무엇을>
- **Approval needed**: yes | no | <조건>

## Required reads (이 세션 시작 시)

> 다음 세션 사람/에이전트가 이 파일 + 아래 목록만 읽으면 즉시 이어받을 수 있어야 함 (stranger-proof).

1. HARNESS.md (pinned version)
2. STATUS.md (이 파일)
3. DECISIONS.md
4. (project-specific) BLUEPRINT, 현재 MODULE-PLAN, 최근 REVIEW
5. (있다면) INBOX/codex-feedback-*.md unread

## Approved artifacts

```yaml
- artifact: <relative path>
  version_or_hash: <vX.Y or sha256:...>
  approver: user | codex-review | claude-self-test
  mode: strict | balanced | autonomous
  approved_at: <ISO timestamp>
  scope: <어디까지의 승인>
# (반복)
```

## Decision summary

> 누적 ADR 한 줄 요약 (DECISIONS.md 전체 읽기 전 빠른 파악용).

- **ADR-001**: <한 줄>
- **ADR-002**: <한 줄>
- ...

## Roadmap

### Current phase
- [x] sub-phase 완료
- [ ] **<현재>**
- [ ] 다음

### 다음 phases
- Phase ...

## Next action

- **사용자**: <무엇을>
- **Claude**: <무엇을>
- **Codex**: <무엇을 / 대기 중>

## Open findings

| ID | severity | 제목 | 상태 |
|---|---|---|---|
| F-N | blocker/major/minor/nit/info | ... | open / resolved / deferred / disputed |

미해결 finding은 INBOX 또는 review 출처 명시.

## INBOX

- **<N> unread** — 파일명 또는 비어있으면 명시
- **unread 정의**: `INBOX/codex-feedback-*.md` with front-matter `status: open` (README.md / `processed/` 제외)

## Notes

- **Cumulative Codex tokens** (HARNESS §5.4):
  - <round>: <tokens>
  - ...
  - **누적 = <total>**
- **재리뷰 횟수** (§5.4 — 3회 초과 시 사용자 확인): <count>
- 기타 메모 / 알려진 한계 / 후속 ADR 후보 등
