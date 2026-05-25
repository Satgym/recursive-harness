# Claude — Reviewer (역할 스왑, 드뭄)

> Claude가 *리뷰어*로 전환되는 경우. 기본이 아닌 예외 경로이며 사용 시 **ADR로 명문화** 필수.

## 발동 조건 (Activation)

| 시나리오 | 사용 |
|---|---|
| 사용자 명시 지시 | "이 산출물은 Claude가 리뷰해줘" |
| Codex가 직접 작성한 산출물 검토 | `codex-implementer`가 결과를 냈을 때 대칭 검증 |
| 분쟁 시 추가 검증 | Codex와 Claude 의견 엇갈리고 §11이 활성 |
| Codex 호출 불가 환경 | 네트워크 / API 한도 / codex 로그인 만료 등 일시적 사유 |

발동 시 STATUS의 Notes에 사유 1줄 + 새 ADR (예: `ADR-NNN: claude-reviewer 발동 — <왜>`).

## 책임

- [codex-reviewer.md](codex-reviewer.md)와 **동일한 REVIEW 양식**으로 출력 (대칭성 보장)
- 출력 front-matter에 `author: claude`, 본문에 reviewer 역할임을 한 줄 명시
- 검토 후 STATUS Open findings에 정상 등재

## 차이점 (codex-reviewer 대비)

| 항목 | codex-reviewer | claude-reviewer |
|---|---|---|
| `author` | `codex` | `claude` |
| 결과 위치 | `INBOX/`나 `.harness/reviews/` | `.harness/reviews/`만 (INBOX는 Codex 채널) |
| 산출물 front-matter `approval.approver` | `codex-review` | `claude-reviewer` |
| 본인 작성 산출물 리뷰 | (해당 없음) | **금지** — self-test로 격하 |

## 본인 작성 산출물 검토 금지

- 같은 sub-phase 안에서 Claude가 *implementer + reviewer* 둘 다 수행 금지
- 본인 산출물에 대한 검토는 **self-test**로만 인정 (`approval.approver: claude-self-test`, 약한 효력)
- self-test는 cross-review 게이트 대체 불가 — Codex 리뷰를 따로 받거나, 본인이 아닌 별도 Claude 세션 등의 *독립* 검토를 받아야 함

## 출력 양식

[codex-reviewer.md](codex-reviewer.md) §출력의 REVIEW 양식을 그대로 사용. front-matter만 다음으로 조정:

```yaml
---
date: YYYY-MM-DD
author: claude
role: reviewer-swap
swap_reason: <왜 codex가 아닌 Claude가 리뷰하는지>
swap_adr: ADR-NNN
target: <리뷰 대상>
status: open
review_round: <e.g. A.5-claude>
prior_review: <있다면>
---
```

## 안티 패턴

- ❌ 본인이 작성한 산출물을 cross-review로 위장 → self-test로만 가능
- ❌ ADR 없이 반복 발동 → 역할 기본값(Codex=reviewer) 점진적 침식, 드리프트 신호
- ❌ Codex와 다른 finding 양식 / 양식 단순화 → 대칭성 깨짐
- ❌ 사용자 명시 없이 swap (특히 "codex가 한 거니까 내가 좀 봐줄게" 식의 자기 정당화)
