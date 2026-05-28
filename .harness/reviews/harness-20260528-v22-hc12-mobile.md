---
artifact: review
date: 2026-05-28
author: codex
status: open
severity: <see body>
target: Hara v2.2 HC-12 mobile equivalent extension (ADR-023)
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e6c55-fabd-7cb1-bc47-2515b33c6f21
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 80842
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-28T02:07
  prompt_source: .harness/prompts/harness-v22-hc12-mobile-r1.md
---

## REVIEW

**Verdict: minor-followup**

### Finding 1
- `severity`: minor
- `위치`: `DECISIONS.md:48`, `DECISIONS.md:52`, `DECISIONS.md:63`; `.githooks/pre-push:26`, `.githooks/pre-push:157`
- `근거`: ADR-023은 `note(starpin-v0.13.0)`이 hook을 우회한다고 정확히 적고 있습니다. 따라서 starpin v0.13은 “mobile gate의 첫 hook-enforced dogfood”가 아니라 “수동 evidence + review dogfood”입니다. `DECISIONS.md:63`의 “starpin v0.13 ship 시점에 hook 이 이미 작동 → mobile silent-breakage 차단”은 starpin 자체에는 성립하지 않습니다.
- `제안`: v2.2 ship blocker는 아닙니다. 다만 ADR/STATUS에 carry를 명시하세요: “starpin v0.13은 note carveout 때문에 HC-12 hook enforcement 대상이 아니며, Phase 04/r2/ship checklist에서 `examples/starpin/.harness/runs/mobile-e2e-...platform=ios...json` 존재를 수동 검증한다.” 별도 ADR까지는 과합니다.

### Finding 2
- `severity`: minor
- `위치`: `.githooks/pre-push:165`, `.githooks/pre-push:167`; `DECISIONS.md:32`; `HARNESS.md:33`
- `근거`: 실제 hook은 `capacitor.config.*`와 `android/app/build.gradle.*`를 모두 mobile surface로 봅니다. 그래서 `capacitor.config.backup`, `capacitor.config.example`, `android/app/build.gradle.old` 같은 tracked non-active 파일도 mobile evidence를 요구할 수 있습니다. 특히 ADR은 `android/app/build.gradle[.kts]`라고 설명하지만 hook은 모든 suffix를 허용합니다.
- `제안`: Android는 `android/app/build.gradle|android/app/build.gradle.kts`로 좁히는 편이 맞습니다. Capacitor는 broad match를 의도한다면 ADR에 false-positive trade-off를 한 문장으로 남기고, 아니라면 `.json|.ts|.js`로 제한하세요.

### Finding 3
- `severity`: nit
- `위치`: `STATUS.md:32`
- `근거`: Required reads가 “DECISIONS.md — 최근 ADR (현재 ADR-020)”로 남아 있습니다. 현재 리뷰 대상과 STATUS 상 harness version은 ADR-023입니다.
- `제안`: `현재 ADR-023`으로 갱신하세요.

## Checks

A.1 backward compat: 통과로 봅니다. validator는 `required_platform=""`일 때 platform 검사를 skip합니다. macOS bash 3.2에서 web evidence without `platform`은 pass, iOS required는 pass, Android-as-iOS는 fail로 확인했습니다.

A.2 false-positive for `harness(v2.2.0)`: 현재 HEAD와 diff 모두 `capacitor.config.*`, `ios/App`, `android/app/build.gradle*` 매칭 없음. v2.2 자체 push가 mobile evidence 때문에 막힐 가능성은 보이지 않습니다.

A.4 iOS mandatory: 구현은 intake §6과 일치합니다. Android evidence는 iOS evidence의 대체물이 아닙니다.

A.5 heredoc in function: `bash -n` pass, macOS bash 3.2에서 함수 내 heredoc 실행도 정상 확인했습니다.

PART B.1은 blocker가 아닙니다. 다만 지금 wording 그대로 두면 “hook-enforced dogfood”처럼 읽히는 부분이 documentation theater에 가까워질 수 있어 minor follow-up으로 잡는 게 맞습니다.
