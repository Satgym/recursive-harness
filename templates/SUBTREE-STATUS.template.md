---
artifact: subtree_status
version: v0.1
child_name: <kebab-case>
parent_path: <absolute or repo-relative>
locked_interface_hash: <sha256 of locked-interface.md at split>
depth: <1 or 2>
---

# STATUS — `<child_name>` sub-coordinator

> 본 child scope의 SoT. parent의 STATUS.md와는 별도.
> 본 파일이 존재 = 본 세션은 sub-coordinator (HARNESS §14).

## Current

| 항목 | 값 |
|---|---|
| Subtree | `<child_name>` (depth=<n>) |
| Parent | `<parent_path>` |
| Phase | <자기 scope 내 phase — 예: 03-implement> |
| Active sub-phase | <세부> |
| Strictness | <inherited from parent ADR-NNNN split-decision> |
| Branch | feat/<child_name> |
| Last updated | <ISO> by <author> |

## Active gate

- **Gate**: <현재 막힌 게이트>
- **Blocked on**: <무엇 대기 중>
- **Approval needed**: <none / user / codex>

## Locked interface (변경 불가 — parent SPLIT-DECISION-ADR-NNNN 기준)

- spec path: `<parent>/.harness/subtrees/<child_name>/locked-interface.md`
- hash at split: `<sha256>`
- 변경 필요 시: 본인이 escalate.md 작성 → parent에 통보 → parent가 ADR amend

## Approved artifacts (본 scope 내)

```yaml
- artifact: <path>
  version_or_hash: <>
  approver: <user | codex-review | claude-self-test>
  mode: <strict | balanced | autonomous>
  approved_at: <ISO>
  scope: <text>
```

## Decision summary (본 scope 내 ADR)

- (본 child가 자기 scope 내에서 추가로 split했다면 ADR-<sub>-split-decision)
- (기타 child 내부 결정)

## Roadmap (본 scope 내)

- [ ] Phase 02 ModulePlan — own modules ≥1
- [ ] Phase 03 Implement
- [ ] Phase 04 CrossReview (자기 scope codex)
- [ ] Phase 06 Handoff — MERGE-REPORT 작성 + commit

## Next action

- **본 child Claude**: <다음 액션>
- **Parent**: 본 child 완료 통보 대기

## Open findings (본 scope)

- (codex review에서 발견된 finding 누적)

## Notes

- (메모)
