---
artifact: postmortem
date: <YYYY-MM-DD>
author: claude
trigger: <repeated-drift | escaped-blocker | failed-review-loop | broken-handoff | hc-violation>
status: open   # open | resolved
references:
  - related_adr: <ADR-NNN, optional>
  - related_review: <path, optional>
  - related_commit: <sha, optional>
---

# <YYYY-MM-DD> — <Short slug>: Postmortem

> 트리거: HARNESS §6.3 — 본 사건이 어느 트리거에 해당하는지 front-matter `trigger`에 명시.

## 1. Event

*무엇*이 일어났는가. 사실만, 해석 없이. 시점·관찰자·관찰된 산출물 명확히.

## 2. Impact

영향 — 정량 + 정성:
- 영향 범위: <어느 sub-phase / 모듈 / 산출물>
- 손실: <시간 / 토큰 / 손상된 산출물>
- 사용자에게 미친 영향: <있다면>
- 외부 영향: <있다면 — HC-8 위반 가능성>

## 3. Root cause

근본 원인 분석 (5 Whys 권장):

1. Why? ...
2. Why? ...
3. Why? ...
4. Why? ...
5. Why? ...

→ 근본 원인: ...

## 4. Immediate actions

사고 발견 즉시 취한 조치:
- ...

## 5. Harness change proposal

재발 방지를 위한 *하니스 자체* 변경:
- HARNESS.md 수정 (어느 §, 어떻게)
- 또는 새 ADR (ADR-NNN 신규)
- 또는 체크리스트 보강 (예: codex-reviewer 체크리스트, pre-review-gate 항목)
- 또는 스킬·스크립트 추가

> 본 postmortem은 위 변경이 *실제 적용*되어야 `status: resolved` 가능.

## 6. Verification

어떻게 재발 방지 확인할 것인가:
- 자동화 테스트 / 린트 추가
- 다음 codex review 체크리스트에 항목 추가
- 사용자 review 시점에 명시적 확인

## 7. Follow-up schedule

- 검증 일정: <e.g. 2주 후 재확인 / 다음 Phase 게이트 / A.5 통합 리뷰>
- Owner: claude-implementer (기본)
- Outcome: <검증 후 결과 한 줄로 기록 — `status: resolved`로 닫기 직전>

## 8. Closure

`status: open` → `status: resolved` 전환 조건:
- [ ] §5 하니스 변경안이 commit됨 (해당 commit SHA: ...)
- [ ] §6 검증 방법이 실제로 통과
- [ ] §7 follow-up schedule의 outcome이 채워짐
