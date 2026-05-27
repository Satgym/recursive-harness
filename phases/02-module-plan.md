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
11. **(v1.1+) Split-decision step** — *마지막 plan 판정 의무* (F76):
    - Blueprint §8.6 expected module set과 `.harness/docs/modules/index.md`의 캐노니컬 list 비교
    - 둘이 *완전히 일치*하고 모든 plan이 `status: approved`일 때만 본 step 진입 (불일치 또는 미완 시 die — 계속 Phase 02)
    - 진입 후 [skills/estimate-project-scope.md](../skills/estimate-project-scope.md) 호출:
      - **결과 = no-split**: 본인이 Phase 03 진행 (지금까지 패턴)
      - **결과 = split**: SPLIT-DECISION-ADR 작성 (current_depth/max_depth_allowed/root_path field 의무 — Fleet F74) → `approver: user` 승인 (F6, autonomous도 의무; `dogfood_simulation: true`만 예외) → [skills/spawn-subtree-prompts.md](../skills/spawn-subtree-prompts.md) 호출 (preflight가 F73/F74/F76 게이트 enforce) → 각 child worktree + prompt 생성 → 사용자에게 child 세션 spawn 요청. 본인은 child 완료까지 wait
    - Fleet 규칙 전체는 HARNESS §14.

## Outputs

- `.harness/docs/modules/<name>/plan.md` (front-matter `artifact: module_plan`)
- (해당 시) `.harness/reviews/02-module-plan-<date>-<name>.md`
- **(v1.1 split 시)** `.harness/decisions/ADR-NNNN-split-decision-<slug>.md` + `.harness/subtrees/<child>/{prompt.md,locked-interface.md}` 일체

## Exit 기준

- [ ] MODULE-PLAN의 8개 섹션 모두 채워짐 (Implementation notes는 high-level OK)
- [ ] Public interface가 *컴파일 가능 수준*의 명세 (시그니처만이 아니라 타입까지)
- [ ] Errors / Edge cases 적어도 1개 이상 (없으면 plan 자체가 부족)
- [ ] Test plan에 unit + (필요 시) integration 모두 매핑됨
- [ ] **strict 모드**: Codex 리뷰 통과 + 사용자 승인
- [ ] **balanced 모드**: Codex 리뷰 통과 (사용자 승인 갈음)
- [ ] **autonomous 모드**: claude-self-test 완료 (cross-review 대체 불가, 다음 정식 cross-review 또는 periodic audit에서 사후 검증)
- [ ] STATUS Approved artifacts에 module plan 등재
- [ ] **(v1.1+ Fleet 의무)** root coordinator scope의 마지막 plan일 때 split-decision 수행됨 (no-split이든 split이든 *판단을 명시*). split 결정 시 SPLIT-DECISION-ADR + 사용자 승인 + subtree workspace 생성 완료

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
