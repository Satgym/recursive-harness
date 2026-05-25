# INBOX — Codex 능동 피드백 채널

이 디렉토리는 **Codex가 비동기로 하니스/프로젝트에 의견을 남기는 채널**이다.

## 누가 무엇을 남기는가

- **Codex가** 이 디렉토리에 진입했을 때(사용자가 띄운 별도 codex 세션) 능동적으로 남기는 피드백
- 하니스 자체에 대한 개선 아이디어, 다음 Claude 세션이 알아야 할 사항, 정식 리뷰 외 코멘트
- 정식 cross-review 결과는 여기가 아니라 `.harness/reviews/`(Phase A.3 이후)에 저장

**Codex 쓰기 권한**: Codex의 "직접 코드/문서 수정 금지" 절대 규칙에는 **INBOX 새 파일 작성 예외**가 적용된다 (AGENTS.md §Codex 역할 참조). 기존 INBOX 파일의 본문은 codex가 임의로 고치지 않는다 — 새 피드백은 새 파일로.

## Unread 정의

`unread = INBOX/codex-feedback-*.md` 중 front-matter `status: open`인 파일.
README.md와 `INBOX/processed/` 하위는 제외.
STATUS.md의 `INBOX` 카운트는 이 정의를 따른다.

## 파일명 규칙

```
codex-feedback-YYYYMMDD-<short-slug>.md
```

예:
- `codex-feedback-20260525-blueprint-gap.md`
- `codex-feedback-20260526-strictness-edge-case.md`

## 양식 (front-matter 필수)

```markdown
---
date: 2026-05-25
author: codex
severity: blocker | major | minor | nit | info
target: <어떤 파일/phase/모듈에 대한 피드백인지>
status: open
---

## Summary
한 단락.

## Detail
관찰 / 근거 / 재현 경로.

## Suggested action
구체적 변경안 (가능하면 패치 형태나 문장 단위 수정안).

## References
- 파일:라인 / ADR 번호 / HARNESS.md 섹션
```

## Claude의 처리 의무

1. 세션 시작 시 `ls INBOX/` 실행 (디렉토리만 비어있는지 확인)
2. 새 피드백 파일 발견 → STATUS.md "Open findings"에 항목 추가, "INBOX" 카운트 갱신
3. 각 피드백 처리:
   - 반영 → 해당 파일 상단의 `status: open` → `status: resolved` 로 변경
   - 보류 → `status: deferred(<이유>)` 변경, STATUS의 Open findings에는 남김
   - 분쟁 → `status: disputed`, ADR로 결론 기록
4. 처리 끝난 파일은 `INBOX/processed/`로 이동 (시간 순으로 쌓임)

## 디렉토리 구조

```
INBOX/
├── README.md           ← 이 파일
├── *.md                ← 미처리 피드백
└── processed/          ← 처리 완료 (자동 생성)
    └── *.md
```
