# Skill: apply-review

## Purpose

Codex review 결과를 finding별로 처리: `resolved` / `disputed` / `deferred` (+ `deferred_reason`). disputed는 §11 분쟁 프로토콜 적용. 완료까지 STATUS Open findings에 명시.

## When to invoke

- `.harness/reviews/<phase>-*.md`가 새로 생성된 직후
- 또는 사용자가 명시적으로 "review 결과 처리해줘" 지시

## Inputs

- 리뷰 파일 (front-matter `status: open`, finding 목록)
- 관련 산출물 (Blueprint / Module Plan / 코드)
- HARNESS §11 (분쟁 프로토콜) + phases/04 Exit 기준

## Procedure

1. **finding 인벤토리**:
   - 리뷰 파일의 모든 finding (예: F16, F17, …)을 ID·severity·target 기준으로 정리
   - STATUS *Open findings* 표에 *출처 명시*로 추가 (출처: `.harness/reviews/<file>.md`)
2. **순서 결정** — severity 내림차순:
   - blocker → 즉시 처리 (resolved 또는 사용자 명시 deferred)
   - major → 처리 또는 사용자 명시 deferred + reason
   - minor / nit / info → 처리 또는 carry-over (Phase 진행 가능)
3. **각 finding별 처리**:
   - **resolved**: 코드 / 문서 수정 → 변경을 별도 commit (HARNESS §12.3 메시지 양식). commit body에 `Refs: <review-file> finding F<N>`.
   - **disputed**: 양쪽 근거를 review 파일 또는 별도 메모에 정리 → [HARNESS §11](../HARNESS.md) follow → 결론 ADR. `severity ∈ {blocker, major}` 시 phase 진행 차단.
   - **deferred**: `status: deferred` + `deferred_reason: <text>` (분리 필드, `deferred(<reason>)` 합성 금지). STATUS Open findings에 carry-over.
4. **재리뷰 필요 여부**:
   - 변경이 의미 있을 때만
   - §5.4 cost guardrail — 동일 산출물 3회 초과 시 사용자 확인
   - 재리뷰 PROMPT에는 *처리 응답* 동봉 (codex가 닫힘을 검증)
5. **Phase 04 Exit 점검** (phases/04-cross-review.md):
   - blocker = 0 (resolved 또는 사용자 명시 deferred)
   - disputed blocker/major = 0 (사용자 결정 받음)
   - HC-7/8/9 위반 finding 모두 처리
   - 위 만족 시 *Active gate*를 다음 phase로
6. **STATUS 갱신**:
   - 처리된 finding의 상태를 표에 반영 (resolved / deferred + reason / disputed)
   - 모두 closed 시 review 파일 자체의 `status`를 `resolved` (또는 partial이면 그대로 open)
   - INBOX의 능동 피드백이라면 `INBOX/processed/`로 이동

## Outputs / Side effects

- 코드 / 문서 변경 commit
- (해당 시) 새 ADR (분쟁 결론, deferred 정당화)
- STATUS *Open findings* 갱신
- (조건부) 재리뷰 호출 [skills/request-codex-review.md](request-codex-review.md)

## Failure modes

- **finding을 *암묵적*으로 무시** → HC-6 위반 (작업 미완 + escaped blocker 위험). 모든 finding에 명시적 응답.
- **disputed → owner 일방 종결** → §11 위반. 결론은 ADR로, 2회 핑퐁 시 사용자 escalation.
- **`deferred(<이유>)` 합성 표기** → canonical 위반 (F14/F17 regression). 분리 필드 필수.
- **재리뷰 폭주 (3회 초과)** → 산출물 또는 plan 근본 문제 신호. 작업 중단 + HARNESS §6.2 드리프트 절차.

## Related

- [phases/04-cross-review.md](../phases/04-cross-review.md)
- [skills/request-codex-review.md](request-codex-review.md)
- HARNESS §11 (분쟁 프로토콜)
- HARNESS §6.3 (Postmortem triggers — escaped blocker / failed review loop)
- F14 / F17 (deferred 표기 사례)
