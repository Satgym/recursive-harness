# Skill: harness-amend

## Purpose

하니스 자체의 결함 / 드리프트 / 진화 필요를 인지했을 때 HARNESS.md / roles / templates / scripts / phases 등을 수정하는 표준 절차. [HARNESS.md §6.2](../HARNESS.md)의 절차를 실행 가능한 단계로.

## When to invoke

- [skills/drift-check.md](drift-check.md)가 드리프트 발견
- 사용자가 하니스 동작에 대한 불만 / 변경 요청
- Codex review가 하니스 자체에 대한 finding (예: F16/F18처럼 자기 모순)
- Postmortem 트리거 (HARNESS §6.3)가 발동되어 *하니스 자체* 변경 필요

## Inputs

- 변경 동기 (드리프트 신호 / finding / 사용자 의견 / postmortem)
- HARNESS.md 현재 버전 + 변경 이력
- 영향 받는 산출물 (roles / templates / scripts / phases / DECISIONS)

## Procedure

1. **변경 동기 명시화**:
   - 무엇이 / 왜 안 맞는지를 1단락으로
   - STATUS *Notes*에 임시 기록 (drift-check가 이미 했다면 그곳)
2. **영향 분석**:
   - HARNESS 어느 §에 영향?
   - 관련 산출물 (roles/templates/scripts/phases) 어느 파일?
   - 진행 중인 작업에 영향? (영향 있으면 일시 정지)
3. **변경안 작성**:
   - **작은 변경** (wording / typo / 누락 필드): patch (Edit)
   - **중간 변경** (새 hard constraint / 새 phase / 양식 변경): HARNESS 본문 수정 + 관련 산출물 동시 갱신
   - **큰 변경** (헌법 구조 변경 / 새 phase 추가): HARNESS 메이저 버전 증가 + 마이그레이션 가이드
4. **ADR 발행** (모든 *중간/큰* 변경):
   - DECISIONS.md에 새 정수 ADR (Context / Decision / Consequences / Approval)
   - 기존 ADR을 뒤집으면 supersedes 명시 + 기존 ADR `Status: superseded by ADR-NNN`
5. **Codex 리뷰** (강력 권장 — 모든 헌법 변경):
   - [skills/request-codex-review.md](request-codex-review.md)로 텍스트 리뷰 의뢰
   - **HC-7/8/9 영향 검토**가 review 의무 (codex-reviewer가 강제 blocker로 표시)
   - 단 §5.4 cost guardrail — 동일 HARNESS 대상 재리뷰 3회 초과 시 사용자 명시 확인
6. **사용자 승인 — 모든 모드에서 필수** (HARNESS §2: "하니스 자체 변경은 모든 모드에서 항상 사용자 승인"):
   - 변경안 + Codex review를 사용자에게 보고
   - 승인 후 적용
7. **버전 업데이트**:
   - 변경 종류에 따라 v0.X → v0.(X+1) (작은) 또는 vX.0 → v(X+1).0 (큰)
   - HARNESS §8 버전 이력에 새 항목 (날짜 / 변경 요약)
   - 본 파일 헤더의 버전 갱신
8. **변경 적용 + commit**:
   - 모든 영향 파일 동시 commit
   - 메시지 양식: `harness(vX.Y): <subject>` (§12.3)
9. **STATUS 갱신**:
   - *Approved artifacts*에 HARNESS 새 버전 (6필드)
   - *Decision summary*에 새 ADR 한 줄 추가
   - *Notes*에 변경 사실 기록
10. **작업 재개** — 원래 일시 정지했던 작업이 있다면 갱신된 헌법 위에서 재개. 시작 시 [skills/resume-session.md](resume-session.md) 효과적.

## Outputs / Side effects

- 갱신된 HARNESS.md (+ 영향 받는 산출물)
- 새 ADR
- (선택) Codex review 파일
- 사용자 승인 기록
- 새 git commit
- STATUS 갱신

## Failure modes

- **사용자 승인 없이 적용** → HARNESS §2 위반. 위반 자체가 다음 amend의 동기 (악순환).
- **ADR 없이 변경** → 미래 세션이 "왜 이렇게 됐는지" 모름. ADR은 모든 중간/큰 변경에 의무.
- **버전 미증가** → STATUS의 `Harness version` 추적이 깨짐. 작은 patch라도 본 파일 헤더는 갱신.
- **반복적 amend (한 phase 내 3회 이상)** → 헌법 구조 자체에 문제. Postmortem 트리거 (§6.3 반복 드리프트).
- **변경이 진행 중 작업과 호환 안 됨** → 마이그레이션 가이드 + 일시 정지된 작업의 재진입 절차 명시.

## Related

- HARNESS §6.2 (드리프트 감지·수정 절차)
- HARNESS §6.3 (Postmortem triggers)
- HARNESS §2 (Strictness — 하니스 자체 변경은 항상 사용자 승인)
- ADR template ([templates/ADR.template.md](../templates/ADR.template.md))
- [skills/drift-check.md](drift-check.md)
- [skills/request-codex-review.md](request-codex-review.md)
