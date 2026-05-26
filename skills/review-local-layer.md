# Skill: review-local-layer

## Purpose

Project-local skills / roles / manifest 후보를 Codex로 cross-review. **HC-10 delta safety check**가 핵심 — base 약화·우회 여부 검증. 전체 base 재검토 X, *추가분*만 본다.

## When to invoke

- [skills/synthesize-local-layer.md](synthesize-local-layer.md) 절차의 step 6 (draft 작성 후)
- 또는 기존 local capability에 *중대한* 변경이 생긴 경우 (지속적 manifest 갱신)

## Inputs

- 검토 대상 drafts (`.harness/skills/<id>.md` / `.harness/roles/<id>.md`)
- 갱신된 `.harness/capabilities.md` (Draft / pending 섹션)
- base 참고: HARNESS.md (특히 HC-1~10, §4.3, §7, §11, §13)
- 관련 base skills/roles/templates (extends 또는 인접)

## Procedure

1. **PROMPT 작성** — `.harness/prompts/00.5-capability-<round>.md`:
   - 검토 대상 drafts 경로 명시
   - HC-10 delta safety check 4가지 강제 (아래 §체크리스트)
   - finding ID는 단조 (직전 라운드에서 이어서)
   - 출력 양식: templates/REVIEW.template.md

2. **Codex 호출**:
   ```bash
   "$HARNESS_ROOT/scripts/codex-exec-review.sh" \
       --phase 00.5-capability \
       --slug "synthesis-r<N>" \
       --prompt-file .harness/prompts/00.5-capability-<round>.md \
       --review-round "capability-r<N>" \
       --target ".harness/skills/<...> + .harness/roles/<...>" \
       --prior-review "<prior 00.5 review or N/A>"
   ```

3. **HC-10 delta safety check (Codex가 강제로 점검)**:
   - [ ] 본 capability가 HC-1~9 중 어느 항목을 *약화·재정의*하는가? — 그렇다면 강제 blocker
   - [ ] base phase Exit 기준의 항목을 *제거*하는가? — blocker
   - [ ] base role 권한 매트릭스를 *완화* (예: codex-reviewer에 commit 권한 부여) 하는가? — blocker
   - [ ] `approver` enum을 확장 (user/codex-review/claude-reviewer/claude-self-test 외) 하는가? — blocker
   - [ ] **non-user approval로 `status: approved` 또는 manifest *Active* 진입 시도가 있는가?** (예: codex-review만으로 Active로 promote) — **강제 blocker** (HARNESS §13.5 + 템플릿 INVARIANT). codex-review/claude-reviewer/claude-self-test는 evidence만 제공.
   - [ ] 사용자 승인 게이트를 우회·자동화 하는가? — blocker
   - [ ] HC-7/8/9 도메인 risk를 명확히 식별·redact/gate 했는가? — minor/major 따라 다름
   - [ ] activation trigger가 *언제* 발동되는지 명확한가?
   - [ ] failure modes 명시?
   - [ ] base skill/role과 *중복*되지 않는가? (있다면 base 사용 권장 / 또는 base 승격 후보)

4. **finding 처리** ([skills/apply-review.md](apply-review.md))

5. **재리뷰** (필요 시)

6. **승인 — 사용자**:
   - blocker = 0, major resolved
   - HC-10 check 모두 통과
   - 사용자가 capability manifest의 *Active* 등재를 승인

7. **manifest 갱신**: draft → Active. STATUS *Approved artifacts*에 manifest 등재.

## Outputs / Side effects

- `.harness/reviews/00.5-capability-<date>-<round>.md`
- finding별 처리 (resolved / disputed / deferred)
- 승인된 capability들의 manifest *Active* 등재

## Failure modes

- **HC-10 위반 발견**: 강제 blocker. 재draft 또는 폐기.
- **base 중복**: minor — base 사용 권장. 또는 base 승격 후보 (§13.6).
- **재리뷰 폭주**: synthesis 의도와 도메인 인지 부족 신호. 사용자 협의 단계로 되돌아감.

## Anti-patterns

- ❌ HC-10 delta check를 *형식적*으로 통과시키기 (Codex가 깊이 검증 안 함)
- ❌ 한 라운드에 너무 많은 draft를 묶어 검토 — finding 폭발
- ❌ `approval`이 codex-review만으로 자동 처리 — *사용자 승인* 필수 (HARNESS §13.5)

## Related

- [HARNESS.md §13](../HARNESS.md), 특히 §13.2 HC-10 의미
- [skills/synthesize-local-layer.md](synthesize-local-layer.md)
- [skills/apply-review.md](apply-review.md)
- [skills/request-codex-review.md](request-codex-review.md)
- [scripts/codex-exec-review.sh](../scripts/codex-exec-review.sh)
