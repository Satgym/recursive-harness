# Phase 05 — Integration

> 단위 모듈을 결합하여 시스템 수준에서 동작 검증. Blueprint 의존성 그래프가 실제로 작동함을 확인.

## Entry 입력

- Phase 03/04를 통과한 모듈들 (≥ 2개; 단일 모듈만으론 본 phase 의미 약함)
- Blueprint §4 Dependency graph
- Blueprint §5 Test strategy (integration / e2e 부분)
- Blueprint §6 Observability 약속

## Activities

0. **(v1.1+ Fleet 모드일 때) Subtree merge-collection** — 본 phase 진입 전에 다음 의무:
   - 모든 child branch (HARNESS §14.4 worktree 구조)가 자기 `MERGE-REPORT.md` commit 완료했는지 확인
   - 각 child branch `git fetch` + parent로 merge (sequential — child끼리는 conflict 자체적으로 못 풀음)
   - 각 child의 MERGE-REPORT.md를 회수해서 `.harness/reviews/05-merge-collection-<date>.md`로 통합 (per-child finding + capability candidate + **conflict decision matrix** 묶음)
   - merge conflict 발생 시:
     - 모든 관련 child의 MERGE-REPORT *conflict decision matrix* 섹션 (F77) 수집 → lock conformance · invariant impact · test evidence 비교
     - shared 파일(F4 위반)이면 parent가 단독 결정. `severity ∈ {blocker, major}`이면 §11 사용자 escalation 의무
     - 모듈 boundary 충돌이면 split-decision 자체 재검토 (drift 신호 — Fleet §14.7)
     - 결정 결과는 ADR로 명문화 (`merge-conflict-resolution-<slug>` ADR 신설)
   - 통합 후 cross-cutting integration codex review 1회 별도 호출 (Fleet F7) — *self-test 대체*는 dogfood/POC만; production Fleet은 codex 의무
   - **(v1.2 F103 patch)** [`lock-grep-gate`](../skills/lock-grep-gate.md) skill 호출 의무 — consume allowlist + invariant util 호출 + MERGE-REPORT INV evidence cross-check. 결과는 `.harness/reviews/05-lock-grep-gate-<date>.md`. PASS 필수 (FAIL 시 해당 child re-work)
1. **결합 환경 준비** — DI / config / fixture 로 실 의존성 (또는 mock vs real boundary 정책에 따라).
2. **Integration test 실행** — Blueprint test strategy에 명시된 시나리오.
3. **E2E 시나리오** (해당 시) — 사용자 관점 happy path + 핵심 실패 경로.
4. **Observability 검증** — 약속한 로그 구조 / metric / 디버그 hook이 실제로 산출되는지 확인. 캡쳐 디렉토리 / 콘솔 prefix 동작.
5. **Performance / Resource 점검** (관련 시) — 펌웨어라면 메모리/플래시 예산, 웹이라면 응답 시간, AI 모델이라면 평가셋 score.
6. **Postmortem 트리거 점검** — Phase 03/04 진행 중 §6.3 트리거에 해당하는 사건이 있었는지 회고. 있었다면 `postmortems/<date>-<slug>.md` 작성 + `status: resolved`까지.

## Outputs

- Integration test 결과 (CI 로그 또는 로컬 실행 캡쳐)
- (해당 시) 성능 / 자원 측정 결과
- (해당 시) Postmortem 파일

## Exit 기준

- [ ] Integration test PASS
- [ ] E2E 시나리오 PASS (Blueprint에 명시된 경우)
- [ ] Observability hook 동작 확인 (실 실행 캡쳐로 증거)
- [ ] 성능 / 자원 제약 (Blueprint §2) 위반 없음
- [ ] 발생한 모든 Postmortem이 `status: resolved`
- [ ] HC-8 (외부 mutation) / HC-9 (destructive) 작업이 본 phase에 있었다면 모두 사용자 승인됨
- [ ] **(Fleet 모드)** 모든 child branch merge 완료 + MERGE-REPORT 회수 + cross-cutting integration review 1회 완료 + child가 제출한 capability candidate에 대한 *수용/거부 결정* ADR로 명문화
- [ ] **(Fleet 모드 v1.3 primary)** 모든 child별 `npx eslint --config eslint.config.<child>.mjs ... PASS` (no-restricted-imports violation 0). ESLint 미설치 환경에선 `lock-grep-gate` fallback PASS
- [ ] **(Fleet 모드 v1.2 F103 fallback)** `lock-grep-gate` skill PASS (`.harness/reviews/05-lock-grep-gate-<date>.md` 존재 + verdict=PASS) + MERGE-REPORT INV evidence가 실제 코드와 일치 (mismatch 0)
- [ ] **(Fleet 모드 strategy=b — F101 v1.2)** ambient declaration 파일들이 merge 시점에 *모두 제거됨* (real provider import로 대체 확인). strategy=a이면 모든 stub이 *real impl로 덮어쓰기됨* (throw 본문 grep으로 검증)

## 주도 역할

- **claude-implementer** (테스트 실행 + 결과 정리)
- **codex-reviewer** (선택; 통합 결과에 대한 리뷰는 04 라운드와 분리, 또는 누적)
- **user** (HC-8/9 발생 시 승인)

## 발생 가능한 드리프트 / 위험

- ❌ Integration test가 unit test의 합으로 위장 → 실제 모듈 boundary 미검증
- ❌ Observability를 "코드는 있는데 동작 확인 안 함" → Phase E dogfood에서 무의미한 hook 발견
- ❌ 성능 제약 위반을 "다음 release"로 미룸 (Blueprint와 결정 ADR 없이) → 드리프트
- ❌ Postmortem 트리거를 인지 못함 → 반복 사고 시 누적 위험

## 다음 phase

[06-handoff.md](06-handoff.md) — 세션 / 모듈 / phase 종료 시 핸드오프.
