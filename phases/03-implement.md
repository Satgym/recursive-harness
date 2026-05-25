# Phase 03 — Implement

> Module Plan을 따라 코드 / 테스트 / 디버그 hook을 작성.

## Entry 입력

- `.harness/docs/modules/<name>/plan.md` (approved, Phase 02 산출물)
- 의존 모듈의 인터페이스 (이미 구현되어 있다면 실 코드, 아니면 plan만)
- Blueprint의 Test strategy / Observability 약속

## Activities

1. **Public interface 구현** — plan §2의 시그니처와 *정확히* 일치 (타입까지). 불일치 발견 시 plan을 먼저 수정 (드리프트 신호).
2. **Internal contracts 코드화** — assert / invariant check / type guard로 명시. 또는 contract library 사용.
3. **Dependencies wiring** — 외부 의존성 주입 (DI / config). HC-7: 시크릿은 환경변수/vault에서 읽기, 코드/로그에 평문 금지.
4. **Unit tests** — plan §5 test plan의 모든 케이스 (happy + error + boundary).
5. **Integration tests** (필요 시) — fixture, mock vs real boundary.
6. **Observability hook** — Blueprint §6에서 약속한 로그 구조 / metric / 디버그 prefix 또는 화면 캡쳐 저장 hook.
7. **HC-7 redaction 점검** — log statement에 자격증명 노출 가능 영역 검사.
8. **HC-8/9 예방** — 외부 mutation / destructive 작업 코드 경로에 사용자 승인 hook (또는 dry-run flag).

## Outputs

- 모듈 소스 코드 (`src/<module>/...` 또는 프로젝트 컨벤션에 따름)
- 테스트 코드 (`tests/<module>/...` 또는 `__tests__/`)
- (해당 시) 디버그 hook / 캡쳐 디렉토리 / metric exporter

## Exit 기준

- [ ] Public interface 시그니처가 plan과 일치 (`grep / type-check`로 검증 가능)
- [ ] Unit test 모두 PASS (plan §5의 모든 case 매핑)
- [ ] `scripts/pre-review-gate.sh` PASS (lint / typecheck / unit)
- [ ] Observability hook 동작 확인 (수동 실행으로 prefix / 캡쳐 / log 출력 확인)
- [ ] HC-7 redaction 점검 통과 (시크릿 grep 0건)
- [ ] HC-8/9 작업 경로에 보호 hook 존재 (해당 모듈에 있다면)

## 주도 역할

- **claude-implementer** 단독 (사용자 / Codex 개입 없음, 단 Codex MCP 옵션 채널 B를 즉석 컨설팅 용도로 사용 가능)

## 발생 가능한 드리프트 / 위험

- ❌ Interface 시그니처를 silent 변경 (plan 미수정) → Phase 04에서 다른 모듈과 불일치 발견
- ❌ "임시 print()로 디버그" → Blueprint observability 약속 위반, 후속 cleanup 누락
- ❌ pre-review-gate를 우회하고 04로 진입 (HC-4)
- ❌ HC-7 redaction 점검 누락 → 04 cross-review에서 blocker로 강제 발견

## 다음 phase

[04-cross-review.md](04-cross-review.md) — codex review로 변경 검증.
