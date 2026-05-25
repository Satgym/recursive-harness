# roles/ — 에이전트 역할 정의

이 디렉토리는 Claude와 Codex의 역할별 책임 / 입력 / 출력 / 제약을 명세한다.
모든 역할은 [HARNESS.md](../HARNESS.md)의 절대 규칙(HC-1~9), §7 STATUS 양식, §11 분쟁 프로토콜을 따른다.

## 4개 역할

| 역할 | 누가 | 발동 시점 | 파일 |
|---|---|---|---|
| **Implementer** (기본) | Claude | 대부분의 작업: 코드/문서 작성, 리뷰 반영, STATUS 갱신 | [claude-implementer.md](claude-implementer.md) |
| **Reviewer** (기본) | Codex | Phase 게이트, cross-review, 텍스트 검토(Blueprint/Plan/ADR) | [codex-reviewer.md](codex-reviewer.md) |
| **Reviewer-Swap** (드물게) | Claude | 사용자 명시 지시 / Codex 산출물 검토 / 분쟁 시 추가 검증 / Codex 호출 불가 환경 | [claude-reviewer.md](claude-reviewer.md) |
| **Implementer-Rare** (드물게) | Codex | 사용자 명시 요청 / Claude가 막힌 영역 / 특정 도메인 codex 강세 | [codex-implementer.md](codex-implementer.md) |

## 발동 규칙 (Activation rules)

1. 한 sub-phase 안에서 같은 에이전트가 *implementer + reviewer 둘 다* 수행하지 않는다.
   - Claude의 자체 점검은 *self-test*이지 cross-review가 아니다. 산출물 front-matter `approval.approver`로 `claude-self-test`라 명시 → 약한 효력 (정식 cross-review를 대체 못 함).
2. **Reviewer-Swap** / **Implementer-Rare**는 사용 시 **ADR로 명문화** (왜 스왑했는지). 반복 스왑 없이 (역할 기본값을 무너뜨림).
3. 분쟁은 HARNESS §11 분쟁 프로토콜을 따른다. disputed `severity ∈ {blocker, major}`는 phase 진행 차단 (§9 임시 게이트 Exit #6 / §3 정식 phase).

## 도구·권한 매트릭스 (요약)

| 권한 | claude-implementer | codex-reviewer | claude-reviewer | codex-implementer |
|---|:---:|:---:|:---:|:---:|
| 코드 / 문서 직접 수정 | ✓ | ✗ (INBOX 새 파일 예외) | ✗ (REVIEW 출력만) | ✓ (사용자 승인 후) |
| 정식 cross-review 출력 | △ (self-test로만) | ✓ | ✓ | ✗ |
| INBOX 새 피드백 작성 | ✓ | ✓ (예외) | ✓ | ✗ |
| STATUS.md 갱신 (필수) | ✓ | ✗ (dispute 사실 기록만 가능) | ✗ | △ (작업 후 Claude가 갱신) |
| git commit | ✓ | ✗ | ✗ | △ (사용자 승인) |
| 사용자 escalation | ✓ | ✓ | ✓ | ✓ |
| HC-8/9 작업 수행 | ✗ (승인 필요) | ✗ | ✗ | ✗ (승인 필요) |

`△` = 조건부 허용. 자세한 내용은 각 역할 파일 참조.

## 역할 간 흐름 (Typical flow)

```
[claude-implementer]
   ├─ 작업 (Blueprint/Plan/Code/Docs)
   ├─ pre-review-gate (lint/test)
   └─ 의뢰 → [codex-reviewer]
                ├─ REVIEW 출력 → INBOX 또는 .harness/reviews/
                └─ 의견 충돌 시 §11
                        └─ 합의 안 되면 사용자 escalation

[codex-implementer]  ← 사용자 명시 요청 시 발동
   └─ 작성 → [claude-reviewer]
                └─ REVIEW 출력 (대칭 흐름)
```

## 다음 단계 (A.2 / A.3와의 연결)

- 각 역할의 출력 양식(REVIEW, ADR, BLUEPRINT, MODULE-PLAN 등)은 **Phase A.2 `templates/`**에서 정식 양식으로 확정.
- 각 역할의 호출은 **Phase A.3 `scripts/`**(특히 `codex-review.sh`, `codex-exec-review.sh`)에서 표준화.
- 각 역할의 phase별 Exit 의무는 **Phase A.4 `phases/`**에서 매핑.
