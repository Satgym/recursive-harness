# Phase 04 — Cross-Review

> Codex가 변경된 코드/문서를 독립 검증. 핑퐁 없이 *명시적*으로 모든 finding을 닫는다.

## Entry 입력

- Phase 03의 코드 + 테스트 (commit 또는 staged)
- pre-review-gate PASS 상태
- 관련 Module Plan + Blueprint
- (있다면) 이전 리뷰 (`.harness/reviews/` 또는 `INBOX/processed/`)

## Activities

1. **Codex 호출** — `scripts/codex-review.sh --phase 04 --slug <module> --base main` (또는 `--commit <sha>` / `--uncommitted`).
2. **REVIEW 결과 저장** — `.harness/reviews/04-<date>-<slug>.md`. front-matter `codex_meta`로 model / session_id / tokens 등 §5.3 review determinism.
3. **finding 처리** — 각 finding에 대해:
   - `resolved` → 코드/문서 수정 + commit
   - `deferred` → `deferred_reason` 명시. STATUS Open findings에 carry-over
   - `disputed` → §11 분쟁 프로토콜 follow
4. **재리뷰** (필요 시) — 변경이 의미 있을 때만. §5.4 cost guardrail에 따라 동일 산출물 3회 초과 시 사용자 확인.
5. **분쟁 처리** — disputed `severity ∈ {blocker, major}` → 즉시 사용자 escalation. 무한 핑퐁 방지 (§11).
6. **STATUS / Approved artifacts 갱신** — review 파일 경로, codex_meta의 tokens 누적.

## Outputs

- `.harness/reviews/04-<phase>-<date>-<slug>.md`
- finding별 응답 commit 메시지 (refs: `04-...md` finding N)
- (해당 시) 새 ADR / Postmortem

## Exit 기준

- [ ] Codex 리뷰 받음 (REVIEW 양식, codex_meta 채워짐)
- [ ] **blocker = 0** (resolved 또는 사용자 명시 deferred)
- [ ] major: resolved 또는 사용자 명시 deferred + `deferred_reason`
- [ ] disputed `severity ∈ {blocker, major}` = 0 (모두 사용자 결정)
- [ ] minor / nit / info 처리 의도 명시 (carry-over도 OK)
- [ ] STATUS Approved artifacts에 review 등재
- [ ] §5.4 cost guardrail 준수 (재리뷰 ≤ 3회)
- [ ] HC-7/8/9 위반 finding (강제 blocker) 모두 처리

## 주도 역할

- **codex-reviewer** (리뷰 출력)
- **claude-implementer** (finding 반영)
- **user** (disputed 결정 시 escalation 수신)

## 발생 가능한 드리프트 / 위험

- ❌ blocker를 "주석 추가"로 silent 해결 → escaped blocker 위험, Postmortem 트리거 후보
- ❌ disputed → claude-implementer가 일방적 종결 (owner 결론 ADR 없이) → §11 위반
- ❌ 재리뷰 횟수 폭주 → 모듈 plan / blueprint에 근본 문제, drift 또는 plan 갱신 필요
- ❌ codex가 잡지 못한 영역에 결함 잠복 → A.5 통합 또는 Phase E dogfood에서 발견. Postmortem.

## 다음 phase

[05-integration.md](05-integration.md) — 모듈 결합 + 통합 검증.
