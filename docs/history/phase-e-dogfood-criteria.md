# Phase E — Dogfood 성공 기준 (HARNESS §10, archived 2026-05-27 v1.6 cleanup)

> **Status**: archived. v1.0 승격 시점 (2026-05-27, ADR-009)에 모든 criteria 충족. 
> 본 문서는 *historical reference only*. 현 base는 v1.3+v1.5.

## Original criteria (HARNESS v0.3~v1.0)

Phase E의 Exit / 승격 기준:

- **최소 프로젝트 규모**: 모듈 ≥3개, Blueprint + Module Plan + cross-review ≥1회 완료
- **필수 산출물**: Blueprint, Module Plans (per module), Reviews, ADRs (≥3), STATUS가 끝까지 stranger-proof 유지, 발생한 Postmortem은 모두 `resolved`
- **결함 캡처**: 발견된 모든 결함이 INBOX/review에 등재 + 처리(또는 명시 deferred)
- **하니스 임시 변경 한도**: dogfood 중 하니스 자체에 의도되지 않은 변경 3회 초과 시 → 하니스 재설계 트리거 (drift 신호로 격상)
- **v1.0 승격 기준**: 위 모두 충족 + 별도 사람(또는 별도 codex 세션)이 STATUS만 보고 30분 내 프로젝트 상태를 파악 가능

## 충족 evidence

- 3 domain dogfood ship: todo-api (web Phase 02) / temp-sensor (firmware v0.1.0) / starpin (mobile+realtime v0.1.0+)
- DECISIONS.md ADR-009 (v1.0 promotion 정식 record)
- 본 archive 자체가 *post-ship retrospection*

## v1.0 이후

본 criteria는 *v1.0 승격 게이트* 역할로 완료. 신규 dogfood는 base HARNESS §3 phase Exit 기준만 따름.
