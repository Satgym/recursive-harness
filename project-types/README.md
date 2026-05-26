# project-types/ — *Seeds*, not Catalog (v0.6)

> **v0.6 재해석** (adaptive-redesign-r1 F65): `project-types/`는 *모든 도메인을 커버하는 catalog*가 아니라 *부트스트랩을 돕는 starter seeds* 모음이다. 매칭이 없으면 `_generic` + [Local Capability Synthesis](../skills/synthesize-local-layer.md)가 정상 경로.

## 현재 seeds

| Type | 깊이 | 추가 자료 | 사용 시점 |
|---|---|---|---|
| `web-service/` | 깊이 (intake / test / module / api-spec) | OpenAPI 명세 양식 | REST / GraphQL / RPC 백엔드 (+ 프론트 연결) |
| `_generic/` | 골격 (intake / test / module) | — | 위에 매칭 안 되는 모든 경우 — 즉 *기본 경로* |

## 새 프로젝트 시작 시 흐름 (v0.6 standard)

```
scripts/new-project.sh <name> <type-or-_generic>
  ↓
Phase 00 Intake
  └─ intake-checklist 채움
  └─ Local Capability Synthesis sub-step  ⭐
       └─ base + seed로 부족한 부분 → local skills/roles draft
       └─ Codex review (HC-10 delta safety)
       └─ 사용자 승인 → capability manifest *Active* 등재
  ↓
Phase 01 Blueprint (base + local layer를 함께 사용)
```

## 새 seed를 base에 추가하려면 (드물게)

새 seed 추가는 *base 변경*이라 `harness-amend` + ADR + Codex review + 사용자 승인. 단:

- **첫 시도는 seed 추가가 아니라 local layer 구성**: 한 프로젝트의 domain gap을 base seed로 즉시 promote하지 않는다. 충분한 사용 사례가 쌓인 후만 (HARNESS §13.6).
- **promotion 기준** (HARNESS §13.6):
  - 서로 다른 ≥ 2 프로젝트에서 활성 사용 OR 1 non-trivial dogfood 검증
  - Codex review 통과
  - 도메인 시크릿 / 고유 정보 없음 (generalizable)

## firmware / ai-model / cli-tool / data-pipeline / ...

이런 카테고리는 **base에 seed로 들어오기 전까지** `_generic` + Local Capability Synthesis로 처리한다. 첫 dogfood가 그 도메인이라면 *그 프로젝트의 local layer*가 출발점.

예시:
- firmware 프로젝트: `_generic` seed + `.harness/skills/budget-flash-ram.md`, `.harness/roles/firmware-safety-reviewer.md`, `.harness/skills/run-hil-smoke.md` 같은 local layer 구성
- AI eval 프로젝트: `_generic` seed + `.harness/skills/track-eval-baseline.md`, `.harness/roles/ml-eval-judge.md` 등

같은 도메인 프로젝트 2+ 누적 시 base seed 승격 후보.

## 파일 컨벤션 (seed 작성 시)

각 seed 디렉토리에 *최소* 3파일:
- `intake-checklist.md` — Phase 00 Intake 도메인 질문 (sed-safe; new-project.sh가 `.harness/docs/intake.md`로 복사)
- `test-strategy.md` — Blueprint §5/§6 작성 영감
- `module-skeleton.md` — Blueprint §3 모듈 분할 출발점

특화 자료(예: web-service의 `api-spec-template.md`)는 추가.

## Anti-patterns (v0.6)

- ❌ "내 도메인은 firmware인데 seed가 없으니 *base에 firmware/ seed를 먼저 추가*해야 한다" — *반대로* 가야 함. 먼저 `_generic`으로 시작, local layer 구성, 충분히 쓰인 후 base 승격.
- ❌ 한 프로젝트만 사용한 local capability를 즉시 base seed로 승격
- ❌ seed에 사용자 또는 도메인 *시크릿* 포함 (HC-7)
