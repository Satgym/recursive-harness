# CLAUDE.md — Claude 진입점

이 디렉토리는 **Claude+Codex 협업 하니스 (Hara)** 작업장이다. 하니스 자체도 하니스의 규칙을 따른다 (메타 부트스트랩, dogfood).

## 세션 시작 시 읽을 순서

1. [HARNESS.md](HARNESS.md) — 헌법 (185줄, must-read)
2. [STATUS.md](STATUS.md) — 현재 어디까지 됐고 다음 액션
3. [DECISIONS.md](DECISIONS.md) — 최근 ADR
4. `ls INBOX/` (그리고 프로젝트면 `ls .harness/inbox/`) — 처리되지 않은 codex 피드백 (`status: open`인 파일이 있으면 STATUS의 "Open findings"에 추가)
5. (프로젝트 작업 시) `.harness/status.md` + `.harness/capabilities.md` Active 섹션
6. (Fleet child 세션) `.harness/subtree.md`가 있으면 *sub-coordinator*. parent path + locked interface 읽기

**참조 시 (문제 발생 / 패턴 확인)**:
- [PATTERNS.md](PATTERNS.md) — postmortem, dispute, adaptive layer 상세
- [FLEET.md](FLEET.md) — Fleet Mode 상세 (split / lock enforcement / inter-child)

위 1~4 안 읽고 작업 시작 금지.

## Claude의 기본 역할
- 구현자 + coordinator. Phase 02 split 결정 + Phase 05 merge 회수 포함
- Codex 리뷰 결과 반영은 Claude 책임
- Review wrapper: `scripts/codex-bundle-review.sh` (bundle/dogfood path, 가장 자주 사용) / `scripts/codex-review.sh` (clean branch diff) / `scripts/codex-exec-review.sh` (alias for bundle)

## 절대 규칙 (전체는 HARNESS.md §1 — HC-1~HC-11)

- Blueprint 승인 전 코드 X / Module Plan 승인 전 해당 모듈 코드 X
- pre-review-gate 통과 전 codex 리뷰 X
- STATUS.md 갱신 의무 (`.githooks/pre-commit`이 RELEASE-STATUS 동시 staging 강제)
- ship 커밋 전 r1+r2 codex 리뷰 의무 (`.githooks/pre-push`이 enforce)
- HC-7/HC-8/HC-9 strictness 모드 무관 항상 사용자 승인
- 머신용 필드값은 canonical 영어 enum: `severity / status / role / phase / strictness`
- 하니스 자체 변경은 별도 절차 (HARNESS.md §10)

## 하니스 hooks (v1.8+)

clone 직후 1회: `git config core.hooksPath .githooks`

Hooks가 자동 enforce하는 것 (잊어버려도 못 빠져나감):
- pre-commit: RELEASE↔STATUS 동시 staging, capability_candidates 자동 수집
- commit-msg: ship 커밋에 WIP 잔존 차단
- pre-push: ship 커밋에 최근 codex review file 부재 차단

`--no-verify` bypass는 **사용자 명시 승인 필요**. Claude가 단독 사용 X.

## 메모리 vs 프로젝트 문서

- 사용자 선호/스타일: `~/.claude/projects/<...>/memory/` (자동)
- 프로젝트 사실/결정/계획/리뷰: 이 디렉토리의 파일들
- 둘은 섞지 않는다
