You are reviewing **Hara v2.2 — HC-12 mobile equivalent extension (ADR-023)**. Harness self-change; HC-11 r1+r2 required.

## Context

starpin v0.13 (Capacitor wrap) intake amendment §4d 의 결정 — Hara v2.2 = v0.13 ship *전* prerequisite. v0.5~v0.9 silent-breakage 패턴 (web login flow가 5 ship 동안 깨진 채 통과) 이 mobile에서 반복되지 않게 hook 인프라 먼저 깐다.

Memory: `feedback_harness_minimalism` 적용 — load-bearing addition 만 추가, documentation 부풀림 금지. v2.0 trim discipline 유지.

## Changes under review

Single uncommitted diff:

- `.githooks/pre-push`: HC-12 블록 dual-lane 으로 확장.
  - `has_ui_surface` (단일 변수) → `has_web_surface` + `has_mobile_surface` 분리 (양립 가능)
  - mobile detection 패턴 3개: `capacitor.config.*`, `ios/App/*`, `android/app/build.gradle[.kts]`
  - 공유 validator `validate_e2e_evidence($file, $required_platform)` — web 호출 시 `""`, mobile 호출 시 `"ios"`. JSON parse + status/exit_code/test_count/ran_at TTL 검증 동일. 중복 ~60 라인 제거 (DRY).
  - 두 lane 각각 독립 evidence 검색 + 독립 fail 메시지
  - web evidence: 기존 `e2e-*.json` 그대로
  - mobile evidence: `mobile-e2e-<date>-<platform>-<slug>.json` — `platform: ios` 의무 (intake §6: iOS mandatory, Android best-effort)
  - 두 surface 다 detected 면 둘 다 통과 필수. note() carveout 은 그대로 (블록 진입 전 ship_subjects empty면 exit 0).

- `HARNESS.md`:
  - Preamble v2.1 → v2.2
  - HC-12 row 갱신: 5개 detection 패턴 (web 2 + mobile 3) inline 명시. evidence 파일명 web/mobile 분리. cross-link: ADR-017 (web) + ADR-023 (mobile).
  - §11 version history: v2.2 row 추가

- `DECISIONS.md`: ADR-023 추가 (~60 line)

- `STATUS.md`: Active gate + Recent ships 업데이트 (mobile expansion 진행 상황 명시)

## YOUR REVIEW

### PART A — Hook 정확성

A.1 **Backward compat** — v2.1 의 `harness(v2.0.0)` + `harness(v2.1.0)` push 가 v2.2 hook 으로도 통과 해야 함. validator helper 가 web evidence (no `platform` field) 도 정상 인식하는가? `required_platform=""` 일 때 platform check 가 skip 되는지 확인.

A.2 **Mobile surface false-positive** — `harness(v2.2.0)` 자체 push 시 mobile surface 가 detected 면 mobile evidence 가 없어 차단됨. v2.2 commit 에 mobile config/source file 이 추가되는가? (현 변경은 .githooks + HARNESS + DECISIONS + STATUS + 그리고 .harness/prompts + reviews. 모두 mobile pattern 매칭 X 확인.)

A.3 **Mobile detection 패턴 정밀도**:
- `capacitor.config.*` — `capacitor.config.json`, `capacitor.config.ts`, `capacitor.config.js` 모두 매칭? edge: `capacitor.config.backup` 같은 비-active 파일도 매칭. 문제 가능성?
- `ios/App|ios/App/*|*/ios/App|*/ios/App/*` — `ios/App` 디렉토리는 Capacitor `npx cap add ios` 가 생성하는 표준 이름. 진짜 native iOS 프로젝트 (`ios/Starpin.xcodeproj` 같은 분리 path) 는 detect 안 됨. v0.14+ native escalation 시 추가 패턴 필요할 수 있음 — 지금 carry 로 OK 한가?
- `android/app/build.gradle[.kts]` — Capacitor 와 일반 Android 둘 다 표준. 정확.

A.4 **iOS mandatory / Android best-effort logic** — `validate_e2e_evidence "$f" "ios"` 가 platform=android 파일은 reject. 즉 mobile surface 가 있고 android-only evidence 만 있으면 fail. 이게 intake §6 결정과 일치하는가? Android evidence 가 *추가* 로 받아들여지긴 하지만 *대체* 는 안 됨.

A.5 **Validator helper 의 subshell 분리** — `python3 - "$f" "$required_platform" <<'PYEOF' ... PYEOF` 가 함수 안에서 호출됨. heredoc 의 함수-내 사용이 모든 환경에서 정상 작동 (특히 macOS bash 3.2 + zsh)?

### PART B — note() carveout 일관성

B.1 starpin v0.13 ship 시점에 사용자가 `note(starpin-v0.13.0)` form 으로 commit. ship_subjects 가 empty (note 는 ship_pattern 매칭 X) → HC-12 블록 전 exit 0 → mobile evidence 검증 안 됨.

이게 의도된 carveout 인가? ADR-023 §C 가 "starpin 같은 gitignored sub-project 는 여전히 hook 우회" 명시했지만, *그러면 starpin v0.13 의 mobile evidence 가 hook-enforced 안 되는데도 ADR-023 §D 의 "starpin 은 sentinel role" 이 정합한가?* — starpin 이 mobile gate 의 첫 dogfood 인데 hook 이 안 잡는다면 evidence 가 진짜로 생성되는지 *수동* 확인이 유일 길. note() 의 의미가 약화되는 위험.

B.2 대안: ship_pattern 에 mobile-specific exception 추가 (e.g. `note(starpin-mobile-v...)`만 hook 검증) — 너무 ad-hoc?

B.3 또는: `code(...starpin-mobile-v0.13.0)` form 으로 starpin v0.13 만 ship 하면 hook 자동 catch. 그러나 examples/ 가 gitignored 라 `code()` 는 의미 없음 (변경 파일 0개).

이 carveout 문제는 v2.2 자체로 풀 수 있는 게 아니라 *별도 carry* 일 가능성. ADR-023 가 명시했는지 확인 + 추가 후속 ADR 필요한지 surface.

### PART C — HARNESS HC-12 row + ADR-023 정확성

C.1 HC-12 row inline 5 패턴이 정확한지. 미래 새 mobile framework (Flutter / React Native) carry 가 자연스러운지 (또는 row 가 너무 framework-specific 한가).

C.2 ADR-023 fact-density — self-congratulation 아니고 실제 변경 추적 가능한지. 60 line 이 v2.0 trim discipline 위배 아닌지.

C.3 STATUS Active gate 의 mobile expansion 8-단계 list — 정상적 SoT 갱신인가 vs 너무 verbose 인가?

### PART D — Ship 가능성

verdict: **ship** | **block** | **minor-followup**.

특히 PART B.1 (note carveout 의 mobile evidence enforcement 누락) 가 blocker 여부 평가 필요.

## OUTPUT

표준 REVIEW format. harness-minimalism 적용 — 진짜 enforce 못하는 documentation theater 발견하면 flag. cosmetic만 있으면 minor-followup.
