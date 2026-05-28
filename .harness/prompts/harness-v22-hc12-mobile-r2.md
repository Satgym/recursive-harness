r2 verification of Hara v2.2 HC-12 mobile equivalent extension (ADR-023).

## r1 (`harness-20260528-v22-hc12-mobile.md`)

**Verdict**: minor-followup. 3 findings:
- #1 minor: ADR §C/D wording "starpin v0.13 ship 시점에 hook 이 이미 작동" misleading because starpin uses note() carveout → hook 발동 X. → patched: §C/D explicit "수동 evidence dogfood" + Phase 04/ship checklist 수동 검증 명시.
- #2 minor: detection 패턴 broad — `capacitor.config.*` catches `.backup/.example`, `android/app/build.gradle.*` catches `.old`. → patched: explicit extensions (`json|ts|js` for capacitor, no-suffix or `.kts` for android). Unit test confirms `.backup/.example/.old` → "other" (no match).
- #3 nit: STATUS Required reads still "ADR-020" → patched to "ADR-023".

## r2 task

1. **#1 closure**: `DECISIONS.md` §C/D 의 wording change — starpin = "수동 evidence dogfood" 명시 + Phase 04 r2 / ship gate 가 evidence 수동 확인. hook-enforced 라는 oversell 사라졌는지 확인.

2. **#2 closure**: `.githooks/pre-push:165-167` 의 detection patterns — `.backup/.example/.old` 같은 non-active 파일이 더 이상 mobile surface 로 잡히지 않음을 unit test 로 확인 (위 단위 test 결과 첨부됨). Capacitor config 는 `.json|.ts|.js` 만, Android build.gradle 는 default + `.kts` 만.

3. **#3 closure**: `STATUS.md` Required reads ADR-023.

4. PART A (backward compat, false-positive, iOS mandatory logic, heredoc) 는 r1 에서 이미 PASS 확인. 변경 없으므로 재검증 불필요.

5. **추가 check** — narrower detection 패턴이 starpin v0.13 의 진짜 Capacitor 산출물 (`capacitor.config.ts` + `ios/App/` + `android/app/build.gradle[.kts]`) 을 여전히 catch 하는지 spot-check.

Verdict: **ship** | **block** | **minor-followup**. 간결 출력.
