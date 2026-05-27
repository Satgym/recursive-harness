# `_incubating/` — Hara v1.6 codex meta-review (M12) archive

본 디렉토리는 *작성됐으나 production wire가 안 된* 산출물 보관소.
**Active artifacts와 분리** — base에 wiring될 때까지 read-only reference로만.

## 항목

### `esm-jest-pattern.md`
- 출처: v1.3 codex F116 finding으로 신설 (Node 22 ESM + ts-jest 함정 패턴 정리)
- *왜 incubating*: `new-project.sh`가 본 seed를 자동 emit하지 않음. 신규 프로젝트 보일러플레이트에 통합 미연결. 사용자가 *수동 참조*만 가능.
- 활성화 조건: `new-project.sh --seed esm-jest-pattern` 옵션 + project-types 옵션 통합 (v1.7+ 후보)

### `LOCAL-ROLE.template.md`
- 출처: v0.6 §13 Local Adaptive Layer 신설 시 template 4개 중 하나
- *왜 incubating*: starpin local roles 2개 (mobile-platform-reviewer / astronomy-data-reviewer) *advisory 형태*만 사용 — 본 template의 `authority/escalation/handoff` 같은 정식 필드 사용 X. 다른 dogfood에서도 활성화 0건
- 활성화 조건: ≥1 프로젝트에서 본 template *full instantiate* + non-advisory authority 인스턴스 발생 시 base로 promote

## Promotion 경로

`_incubating/` → `templates/` 또는 `project-types/_generic/` (활성 위치):
1. ≥1 dogfood에서 *실 사용* (wiring evidence)
2. codex review에서 활용 검증
3. ADR 발행 (활성화 사유 + base SoT 등재)

## 메타-원칙 (Hara v1.6)

active와 incubating을 분리하는 이유:
- **dead artifact가 working set에 섞이면** Claude가 "이거 봐야 하나?" 헷갈림 → 규칙 준수도 저하
- **incubating은 *의도적 미사용*** — 차후 promote 가능 자료. 단 *현재 working set 아님* 명시
- **base는 lean** — Hara v1.6 cleanup pass의 핵심 원칙
