<!--
TWO MODES:
  (A) DECISIONS.md inline ADR — front-matter 불필요. 본 파일 아래의 `## ADR-...` 블록을 사용.
  (B) standalone ADR file (.harness/decisions/ADR-NNNN-<slug>.md) — 위 inline 형식 *위에* 다음 YAML front-matter 부착:

---
artifact: adr
version: v1
date: YYYY-MM-DD
author: claude | codex | user
status: proposed | accepted | superseded | rejected
supersedes: ADR-NNN  # optional
amends: ADR-NNN      # optional
approval:
  approver: user | codex-review | claude-reviewer | claude-self-test
  approved_at: YYYY-MM-DDTHH:MM
  mode: strict | balanced | autonomous
references: [<file_or_id>, ...]
---
-->

## ADR-<NNN> — <Title>

**Date**: <YYYY-MM-DD> · **Status**: proposed   <!-- proposed | accepted | superseded | rejected -->
**Supersedes**: <ADR-NNN, optional>
**Superseded by**: <ADR-NNN, optional — 나중에 채워짐>
**Amends**: <ADR-NNN, optional>

**Context**:
배경, 관찰된 문제, 트레이드오프의 출처. *왜* 결정이 필요한지.

**Decision**:
*무엇을* 결정했는가. 명확하게, 측정 가능하게, 단일 문장 또는 짧은 단락.

**Consequences**:
- positive: ...
- negative: ...
- 후속 작업 (필요 시 issue/ticket 링크 또는 작업 항목)

**Approval**: <pending — 승인 시 사용자 명 + ISO timestamp + mode>

<!--
사용 가이드:
- ADR ID는 정수 단조 증가 (ADR-001, ADR-002, ...). 알파벳 suffix(ADR-003a) 금지.
- 결정을 부분 수정하면 새 정수 ADR 발행 후 Amends 명시.
- 결정을 완전 뒤집으면 새 ADR + 기존을 Status: superseded + Superseded by로 표시.
- DECISIONS.md에 추가할 때 최신 ADR이 *위*에 오도록 (시간 역순).
- ADR 갯수가 100개를 초과하면 .harness/decisions/ADR-NNNN-<slug>.md로 분리.
-->
