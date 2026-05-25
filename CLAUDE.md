# CLAUDE.md — Claude 진입점

이 디렉토리는 **Claude+Codex 협업 하니스**를 빌드하는 작업장이다.
하니스 자체도 하니스의 규칙을 따른다 (메타 부트스트랩 / dogfood).

## 세션 시작 시 읽을 순서
1. [HARNESS.md](HARNESS.md) — 헌법, 절대 규칙, 페이즈 정의
2. [STATUS.md](STATUS.md) — 현재 어디까지 됐고 다음 액션은 무엇인지
3. [DECISIONS.md](DECISIONS.md) — 이미 내려진 결정들 (ADR)
4. [INBOX/](INBOX/) — `ls INBOX/`로 codex가 남긴 피드백 확인 (비어있을 수 있음)

위 4개를 안 읽고 작업 시작 금지.

## Claude의 기본 역할
- **구현자(implementer)**. 코드/문서를 직접 작성.
- 단, Codex의 리뷰 결과를 받아 반영하는 책임도 Claude에게 있음.
- Codex에게 리뷰를 의뢰할 때는 표준 스크립트(`scripts/codex-review.sh`, 추후 작성)를 통한다.

## 절대 규칙 (전체는 HARNESS.md 참조)
- Blueprint 승인 전 코드 작성 금지
- Module Plan 승인 전 해당 모듈 코드 작성 금지
- pre-review-gate(lint/typecheck/test) 통과 전 Codex 리뷰 요청 금지
- 하니스 자체 변경은 별도 절차 (HARNESS.md §6 "하니스 수정 절차")
- 모든 작업 종료 시 STATUS.md 갱신 (생략 금지)
- HC-7/HC-8/HC-9 (시크릿 redact / 외부영향 mutation / destructive 작업)은 strictness 모드 무관 항상 사용자 승인 필요
- 머신용 필드값은 canonical 영어 enum 사용: `severity / status / role / phase / strictness` (구체 목록은 AGENTS.md 절대 규칙 참조). 본문/설명은 한국어 OK

## INBOX 처리 의무
- 세션 시작 시 `ls INBOX/` 확인 (unread = `INBOX/codex-feedback-*.md` with `status: open`)
- 새 파일 발견 → STATUS.md "Open findings"에 항목 추가
- 처리 완료 후 파일 front-matter의 `status`를 `resolved` / `disputed` / `deferred` (+ `deferred_reason: <text>`) 중 하나로 변경하고 `INBOX/processed/`로 이동. `deferred(<이유>)` 합성 표기는 금지(canonical enum 위반).

## 메모리 vs 프로젝트 문서
- 사용자 선호도/스타일: `~/.claude/.../memory/` (자동 메모리 시스템)
- 프로젝트 사실/결정/계획/리뷰: 이 디렉토리(하니스 빌드 중)의 파일들
- 둘은 섞지 않는다.
