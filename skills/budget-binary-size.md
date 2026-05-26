---
artifact: base_skill
version: v0.1
date: 2026-05-27
author: claude
status: proposed
references:
  - promotion_proposal: examples/starpin/.harness/decisions/ADR-006-base-promotion-binary-size-budget.md
  - precedent_1: examples/temp-sensor/.harness/skills/budget-flash-ram.md v0.2 (firmware — flash + sram)
  - precedent_2: examples/starpin/.harness/skills/mobile-bundle-budget.md v0.3 (mobile — IPA + APK)
  - harness: HARNESS.md §13.6 (manual promotion v0.6)
---

# Base Skill: `budget-binary-size`

> Build artifact의 *byte-level size budget*을 Blueprint·Module Plan·Implement 단계에 결정적 강제.
> Domain-agnostic framework — *측정 함수*는 local skill이 구현 (Strategy pattern).

## Purpose

다양한 도메인이 *build artifact size budget*을 갖는다:
- firmware: flash + sram (linker output `.elf`)
- mobile native: IPA + APK download size (App Store / Play Store policy)
- web frontend: JS/CSS bundle size
- AI/ML: model weights (.pt / .onnx) deployment size
- desktop / CLI tool: executable binary size

이 모든 패턴은 *artifact path glob + budget bytes + phase-gated strictness*로 추상화 가능.
본 base skill은 *framework + 절차 양식*만 제공; 측정 함수 (도구별 다름)는 local skill 책임.

## When to invoke

- **Phase 01 Blueprint §2 Constraints**: 모듈/플랫폼별 *예상* budget 표 의무
- **Phase 02 Module Plan §6 Implementation notes**: 모듈별 budget 명시
- **Phase 03 Implement 종료**: *측정 함수* 호출 (artifact path + budget) → fail/pass
- **Phase 05 Integration** (선택): runtime metric (fps 등 — 별도 local skill에서 처리 권장)

## Required local provisions

본 base skill을 *extends* 하는 local skill은 다음을 제공해야 한다:

```yaml
local_provisions:
  artifact_paths: <list of glob patterns>           # 예: ['build/*.elf'] (firmware) / ['build/*.ipa', 'app/build/outputs/apk/*.apk'] (mobile)
  budget_bytes: <int>                                # 또는 per-artifact dict
  phase_strictness:
    blueprint: skip                                  # 의무 — Phase 01엔 measurement skip
    module-plan: skip                                # 의무 — Phase 02엔 measurement skip
    implement: strict                                # 의무 — Phase 03엔 strict
    integration: strict|skip                         # 선택 — runtime metric은 별도 처리
  measure_artifact: <function name>                  # shell 또는 별도 도구 호출
                                                     #   firmware: size build/*.elf | awk '...'
                                                     #   mobile: stat -f %z build/*.ipa
                                                     #   web: gzip -c dist/*.js | wc -c
```

## Standard procedure

```bash
#!/usr/bin/env bash
# Usage: budget-binary-size.sh --phase <id>
#   --phase blueprint|module-plan → skip
#   --phase implement|integration → strict (artifact 측정 의무)

PHASE="${TS_PHASE:-implement}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

case "$PHASE" in
  blueprint|module-plan)
    echo "[budget-binary-size] phase=$PHASE — skip"
    exit 0
    ;;
  implement|integration)
    # local skill 또는 wrapper가 artifact_paths + budget_bytes + measure_artifact 제공
    # 1. artifact glob 매치
    # 2. measure_artifact() 호출 (local 제공)
    # 3. compare to budget:
    #    - artifact missing 또는 0 byte → exit 2 (artifact missing fail)
    #    - actual > budget → exit 1 (budget exceeded fail)
    #    - actual ≤ budget → echo PASS + exit 0
    # (구현 위임 — local skill의 measure 함수 호출)
    ;;
  *)
    echo "[budget-binary-size] unknown phase: $PHASE" >&2
    exit 2
    ;;
esac
```

## Standard evidence schema

매 run마다 `.harness/runs/binary-size-<stamp>.txt`에 다음 보존:

```yaml
binary_size_evidence:
  evidence_file: .harness/runs/binary-size-<stamp>.txt
  measured_at: <ISO>
  artifacts:
    - path: <glob match>
      bytes: <int>
      budget_bytes: <int>
      pass: true | false
  overall_pass: true | false
```

## HC self-check (base — 모든 도메인 적용)

- HC-1~9 약화 0건 (artifact 측정만; mutation 없음)
- HC-10 (base — base이므로 not applicable; local extends 시 적용)
- HC-7: artifact path 자체는 secret 아님 (build output path는 일반 정보)
- HC-8: build artifact 측정은 *read-only*; deploy 등 외부 영향 없음
- HC-9: `size` / `unzip -l` / `stat -f %z` / `du -k` 모두 read-only

## Promotion provenance

본 base skill은 starpin (mobile) + temp-sensor (firmware) *2 dogfood*에서 검증된
패턴의 abstraction. HARNESS §13.6 manual promotion procedure 첫 사례.

자세한 promotion rationale + ≥2 precedent evidence는 starpin ADR-006 참조:
`examples/starpin/.harness/decisions/ADR-006-base-promotion-binary-size-budget.md`

## Related local skills (Strategy implementations)

- `examples/temp-sensor/.harness/skills/budget-flash-ram.md` v0.2:
  - artifact_paths: `build/*.elf`
  - measure_artifact: `size -A | awk` (firmware segment 분석)
  - budget: 64KB flash / 20KB SRAM (STM32F103)
- `examples/starpin/.harness/skills/mobile-bundle-budget.md` v0.3:
  - artifact_paths: `build/Build/Products/Release-iphoneos/*.ipa`, `app/build/outputs/apk/release/*.apk`
  - measure_artifact: `stat -f %z`
  - budget: 50 MB each
  - 추가: fps runtime budget (별도 step — base 추상화 외부; v0.2 후보로 `runtime-frame-budget` 분리)

## Future promotion candidates (≥2 precedent 도달 시)

- web frontend bundle: any todo-api or 신규 web project에 frontend가 추가되면
- Docker image size: 다수 backend service의 deployment artifact
- AI model weights: AI-pipeline project 등장 시
