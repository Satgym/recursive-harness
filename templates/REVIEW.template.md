---
artifact: review
date: <YYYY-MM-DD>
author: codex   # codex | claude (스왑 시)
severity: <highest finding present, 또는 info>
target: <리뷰 대상 — file:section / module/<name> / diff base..head>
status: open    # open | resolved | deferred | disputed
review_round: <e.g. A.0a, A.5, M3-cross-review>
prior_review: <옵션 — 이전 리뷰 경로>

codex_meta:     # codex 비대화형 호출 시 자동 채움; claude-reviewer는 생략 가능
  codex_version: <e.g. 0.132.0>
  model: <e.g. gpt-5.5>
  provider: <e.g. openai>
  session_id: <UUID>
  workdir: <absolute path>
  base_ref: <e.g. main, sha>
  included_paths: [<files / globs>]
  sandbox_policy: <e.g. workspace-write>
  reasoning_effort: <medium | high | xhigh>
  invoked_at: <ISO 8601>
  prompt_source: <file path or 'stdin'>
  tokens_used: <int>
---

# <Title> Review

## Summary

한 단락 — 전체 인상, 가장 큰 우려, ready 여부의 직관.

## Findings

> finding ID는 **단조 증가, 라운드 간에도 누적**. (e.g. F1..F12는 A.0a, F13..F15는 A.0f, F16~은 다음.)

### Finding N: <짧은 title>
- **severity**: blocker | major | minor | nit | info
- **target**: <file:section-or-line>
- **detail**: <observation + reasoning>
- **suggested_action**: <patch-level 구체 변경안>
- **references**: <files / ADR ids / 이전 finding ID>
- **capability_candidate** (v1.6 M8 — adaptive loop): yes | no
  - yes 시: 본 finding이 *반복 가능한 pattern*이고 *base or local capability로 흡수 가치*. `candidate_name`, `scope` (어떤 모듈/도메인), `kind` (skill / role / template field) 명시
  - no 시: 1회성 fix — 사유 (e.g. "1회 typo", "module-specific business logic")
  - missing 시: finding closure 무효 (v1.6 의무 — adaptive learning loop 유지)

(필요한 만큼 반복)

## Overall verdict

- **new_blockers**: <count>
- **new_majors**: <count>
- **new_minors**: <count>
- **new_infos**: <count>
- **ready_for_next_phase**: yes | yes_with_minor_fixes | no
- **rationale**: 한 단락 — 위 verdict의 근거

## Assumptions (if any)

리뷰 중 채워야 했던 가정:
- Assumption A1: ...
- Assumption A2: ...

가정이 잘못된 경우 우선 검증 후 finding 재평가.

## Related artifacts read

- 산출물 1 (예: HARNESS.md v0.4)
- 산출물 2
- 이전 리뷰
