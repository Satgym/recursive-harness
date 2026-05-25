# Phase 02 — Module Plan

> 한 모듈의 *코드 작성 전*에 인터페이스·계약·테스트를 먼저 고정. HC-1 (Plan-First, Code-Late).

## Entry 입력

- `.harness/docs/blueprint.md` (approved, Phase 01 산출물)
- Blueprint §3 Modules의 해당 모듈 섹션 (예: M2)
- (선택) 의존하는 다른 모듈의 module plan (이미 완성된 경우)

## Activities

1. **MODULE-PLAN 인스턴스화** — `cp templates/MODULE-PLAN.template.md .harness/docs/modules/<name>/plan.md`.
2. **Responsibility** — Owns / Does NOT own 한 문장씩.
3. **Public interface** — 언어/도메인에 맞춰 시그니처 *정확하게* 작성 (Python class / OpenAPI / TS / C 헤더 / RPC schema). Errors / Edge cases 함께 정의.
4. **Internal contracts** — precondition / postcondition / invariant 표.
5. **Dependencies** — 다른 모듈 / 외부 서비스 / 환경(HC-7 시크릿) / 라이브러리(라이선스 점검).
6. **Test plan** — unit (happy + error + boundary) / integration (어떤 boundary, fixture) / manual·GUI·HIL (캡쳐 위치, 디버그 prefix).
7. **Implementation notes** — 알고리즘 선택, 성능 / 보안 고려.
8. **Risks & open questions** — 모듈 단위 위험과 결정 필요 항목.
9. **Definition of done** — 템플릿 §8 체크리스트.
10. **Codex 리뷰** — strict 모드에선 의뢰 (`codex-exec-review.sh --phase 02-module-plan --slug <module>`). balanced 모드에선 의뢰 (사용자 승인 갈음). autonomous 모드에선 self-test로 갈음 가능.

## Outputs

- `.harness/docs/modules/<name>/plan.md` (front-matter `artifact: module_plan`)
- (해당 시) `.harness/reviews/02-module-plan-<date>-<name>.md`

## Exit 기준

- [ ] MODULE-PLAN의 8개 섹션 모두 채워짐 (Implementation notes는 high-level OK)
- [ ] Public interface가 *컴파일 가능 수준*의 명세 (시그니처만이 아니라 타입까지)
- [ ] Errors / Edge cases 적어도 1개 이상 (없으면 plan 자체가 부족)
- [ ] Test plan에 unit + (필요 시) integration 모두 매핑됨
- [ ] **strict 모드**: Codex 리뷰 통과 + 사용자 승인
- [ ] **balanced 모드**: Codex 리뷰 통과 (사용자 승인 갈음)
- [ ] **autonomous 모드**: claude-self-test 완료 (cross-review 대체 불가, 다음 정식 cross-review 또는 periodic audit에서 사후 검증)
- [ ] STATUS Approved artifacts에 module plan 등재

## 주도 역할

- **claude-implementer** (작성)
- **codex-reviewer** (strict/balanced에서 의무, autonomous에선 선택)
- **user** (strict에서만 모듈마다 승인)

## 발생 가능한 드리프트 / 위험

- ❌ Interface를 "구현 중 결정" 처리 → HC-1 위반, Phase 03에서 시그니처 변경 → 다른 모듈에 파급
- ❌ Test plan을 "나중에 작성" → 03에서 lint pass / pre-review-gate 통과 못함
- ❌ Errors / Edge cases 1개도 없음 → 명세 부족 신호
- ❌ Blueprint와 모듈 인터페이스가 불일치 → 즉시 §6.2 드리프트 절차

## 다음 phase

[03-implement.md](03-implement.md) — plan을 따라 코드/테스트 작성.
