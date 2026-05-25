# Skill: plan-module

## Purpose

[phases/02-module-plan.md](../phases/02-module-plan.md)의 모듈별 plan(`.harness/docs/modules/<name>/plan.md`)을 작성하여 *코드 작성 전*에 인터페이스·계약·테스트를 고정 (HC-1).

## When to invoke

- Blueprint approved + STATUS *Active gate*가 "02 ModulePlan (M<n>)" 가리킴
- 다음 모듈로 진행 (예: M1 implement 완료 후 M2 plan)

## Inputs

- `.harness/docs/blueprint.md` (approved)
- Blueprint §3 Modules의 해당 모듈 섹션
- (해당 시) 의존 모듈의 plan 또는 실제 인터페이스
- `.harness/config.toml`의 strictness 모드

## Procedure

1. **인스턴스화**:
   ```bash
   mkdir -p .harness/docs/modules/<name>
   cp "$HARNESS_ROOT/templates/MODULE-PLAN.template.md" .harness/docs/modules/<name>/plan.md
   ```
2. **8 섹션 채움** (MODULE-PLAN.template.md §1-8):
   - §1 Responsibility (Owns / Does NOT own 명확히)
   - §2 Public interface (시그니처·타입 *컴파일 가능 수준*)
   - §3 Errors / Edge cases (적어도 1개 이상)
   - §4 Internal contracts (precondition / postcondition / invariant 표)
   - §5 Dependencies (모듈 / 외부 / 환경(HC-7) / 라이브러리)
   - §6 Test plan (unit happy+error+boundary / integration / manual·GUI·HIL)
   - §7 Implementation notes (high-level OK)
   - §8 Definition of done 체크리스트
3. **Codex 리뷰**:
   - **strict / balanced 모드**: 필수
     ```bash
     scripts/codex-exec-review.sh --phase 02-module-plan --slug "<name>" \
         --prompt-file .harness/prompts/module-review.md \
         --review-round "M<n>-plan-r1" --target ".harness/docs/modules/<name>/plan.md"
     ```
   - **autonomous 모드**: claude-self-test만 (cross-review 대체 불가, 정식 cross-review는 다음 라운드)
4. **finding 처리** ([apply-review](apply-review.md) skill)
5. **사용자 승인**:
   - **strict 모드**: 모듈마다 사용자 승인
   - **balanced 모드**: Codex 리뷰 통과로 갈음
   - **autonomous 모드**: skip
6. **STATUS 갱신**:
   - *Approved artifacts*에 module plan 등재 (해당 모드 approval record)
   - *Active gate*가 "03 Implement (M<n>)" 가리킴

## Outputs / Side effects

- `.harness/docs/modules/<name>/plan.md` (`status: approved` 또는 `draft`+claude-self-test)
- (strict/balanced) `.harness/reviews/02-module-plan-*.md`

## Failure modes

- **§2 Public interface가 type까지 명시 안 됨** → 03 Implement에서 시그니처 추론으로 떠밀림, drift 위험.
- **§3 Errors 0개** → 명세 부족 신호. 정상 종료 경로만 있는 모듈은 거의 없음.
- **Blueprint 의존성 그래프와 모듈 인터페이스가 불일치** → 즉시 HARNESS §6.2 드리프트 절차 + Blueprint 갱신 후 재진입.

## Related

- [phases/02-module-plan.md](../phases/02-module-plan.md)
- [templates/MODULE-PLAN.template.md](../templates/MODULE-PLAN.template.md)
- [skills/apply-review.md](apply-review.md)
