# DECISIONS — Architecture Decision Records

> 새 ADR은 **위에** 추가. 기존 ADR을 뒤집을 땐 새 ADR을 쓰고 기존을 `Status: superseded by ADR-NNN`으로 변경.
> 파일이 100개 이상으로 늘면 `decisions/ADR-NNNN-*.md`로 분리.
>
> **ADR ID 규칙**: 정수 단조 증가 (`ADR-001`, `ADR-002`, ...). 알파벳 suffix(`ADR-003a`) 금지 — 수정/보완도 항상 새 정수 번호로.
>
> **ADR 양식** (필수 필드):
> - **Date**: YYYY-MM-DD
> - **Status**: `proposed | accepted | superseded | rejected`
> - **Supersedes**: 이 ADR이 대체하는 이전 ADR 번호 (없으면 생략)
> - **Superseded by**: 이 ADR이 나중에 대체된 경우 후속 ADR 번호 (없으면 생략)
> - **Amends**: 이 ADR이 부분 수정·보완하는 ADR 번호 (없으면 생략)
> - **Context**: 결정 배경, 문제 상황
> - **Decision**: 무엇을 결정했는가
> - **Consequences**: 영향, trade-off, 후속 작업
> - **Approval**: `approver` / `approved_at` (사용자 승인 받은 경우)

---

## ADR-006 — Phase A sub-phase별 Codex 리뷰 시점

**Date**: 2026-05-25 · **Status**: accepted · **Amends**: — · **Supersedes**: —

**Context**: HARNESS.md §9 (Bootstrap exception) 임시 게이트 Exit #2는 "Codex review를 받음"이라 명시되어 있다. 엄격 해석하면 모든 sub-phase(A.0b/c/d/e/g, A.1, A.2, A.3, A.4)마다 별도 codex 리뷰가 필요하나, 다수가 wording-level 또는 단일 디렉토리 추가 수준의 *증분 변경*이라 매번 리뷰는 토큰 낭비이고 cost guardrail(§5.4)과도 어긋난다.

**Decision**: Phase A 동안의 codex 리뷰는 다음 3시점에만 받는다.
1. **A.0a — seed review**: v0.1 씨앗 6문서 검토 (이미 완료, 12 findings + 7 proposals)
2. **A.0f — v0.3 re-review**: PART A 이전 finding 닫힘 검증 + PART B 신규 §에 대한 새 finding 탐색 (이미 완료, 3 minor findings)
3. **A.5 — Phase A 통합 cross-review**: roles/ + templates/ + scripts/ + phases/ 전체에 대해 마지막 통합 검증, HARNESS v0.5 정식화

그 외 sub-phase(A.0b/c/d/e/g, A.1, A.2, A.3, A.4)는 별도 codex 리뷰 없이 진행. 단 진행 중 의문/위험이 발견되면 즉시 STATUS *Open findings* 또는 `INBOX/`에 기록 → A.5에서 처리.

**Consequences**:
- 비용 효율: 누적 토큰 ~211K (현재) → A.5 단일 라운드로 추가 ~200K 이내 추정 (저렴).
- A.5에서 누적 finding이 많을 가능성 → 처리 라운드(A.5b/c/d 등) 길어질 수 있음. cost guardrail §5.4의 "재리뷰 3회 초과 시 사용자 확인"이 일찍 발동될 수 있음.
- A.2/A.3/A.4 작업 중 발견되는 *작은 의문*은 INBOX 능동 피드백(C 채널) 또는 STATUS Open findings로 항상 보존되어야 누락 방지.
- A.4 완료 시 §9 자동 폐기 → ADR-006도 자연 종료 (정식 phase Exit 기준이 §9를 대체).

**Approval**: user @ 2026-05-25T11:39, mode=strict

---

## ADR-005 — 프로젝트 타입 우선순위

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스는 다양한 프로젝트 타입(web, firmware, ai-model, cli, data-pipeline 등)을 지원해야 한다. 모두 동시에 깊이 만들면 빌드 부담이 크고 dogfood 검증이 어렵다.

**Decision**: `project-types/web-service/`를 가장 깊이 만든다. 나머지 타입은 `project-types/_generic/` 골격만 제공하고, 실제 필요할 때 dogfood로 빌드한다.

**Consequences**:
- 첫 실사용은 웹 프로젝트가 될 가능성이 높음.
- 다른 타입은 일반 페이즈 절차로만 가능(특화 체크리스트 없음).
- 펌웨어/AI 모델 같은 도메인 특화 검증은 그 시점에 별도 ADR + Phase C 확장으로 다룸.

---

## ADR-004 — Strictness 모드 도입

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스가 자율적으로 얼마나 진행할 수 있어야 하는지는 신뢰 수준에 따라 다르다. 초기엔 모든 plan을 사용자가 검토해야 안전하지만, 검증된 후엔 자동화를 늘리고 싶다.

**Decision**: 세 모드 정의 — `strict` / `balanced` / `autonomous`. 프로젝트별 `.harness/config.toml`에서 선택. 디폴트 `strict`. 하니스 자체 변경은 모든 모드에서 항상 사용자 승인.

**Consequences**:
- 각 phase 문서의 Exit 기준에 "어느 모드에서 사용자 승인 필요한지" 명시 필요.
- 하니스 자체 빌드는 strict 모드로 진행.
- 모드 전환 자체가 ADR 대상 (신뢰가 검증되면 사용자가 명시적으로 balanced로 전환).

---

## ADR-003 — Codex 모델/계정은 사용자 설정

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 사용자마다 접근 가능한 codex/openai 모델이 다르다. 사용자는 현재 codex5.3 + gpt-5.5까지 사용 가능하며 추후 업그레이드 예정.

**Decision**: 모델명은 코드/스크립트에 하드코딩 금지. `.harness/config.toml`의 `[models]` 섹션에서 `review`, `exec` 모델을 각각 지정한다. 미설정 시 `codex` CLI 디폴트 사용.

```toml
# .harness/config.toml 예시 (사용자가 채움)
[models]
review = "gpt-5.5"
exec   = "codex5.3"
```

**Consequences**:
- 정확한 모델 식별자는 사용자가 채워야 함 (예: 위 문자열이 codex CLI가 실제로 받는 모델명과 일치해야 함).
- 모델 업그레이드 시 새 정수 ADR을 발행해서 변경 사항을 `Amends: ADR-003` 으로 기록.
- 스크립트는 `-c model="$(yq '.models.review' .harness/config.toml)"` 같은 식으로 주입.

---

## ADR-002 — Codex 개입은 파일 기반 비동기를 기본으로

**Date**: 2026-05-25 · **Status**: accepted

**Context**: VSCode 환경 + Claude가 주 대화 상대. Codex 개입 방식 후보: (A) 파일 기반 비동기 호출 (B) MCP 즉석 호출 (C) 사용자가 별도 codex 세션 운영.

**Decision**: A를 기본 채널로. B는 후순위(설정 복잡·컨텍스트 비용 큼). C는 `AGENTS.md` + `INBOX/` 컨벤션으로 자연스럽게 지원.

**Consequences**:
- 모든 리뷰가 파일로 남아 재현/감사 가능.
- 즉석 협의 필요 시 사용자가 직접 별도 codex 세션을 띄울 수 있고, codex는 `AGENTS.md`로 자기 역할을 자동 인지.
- MCP는 v1.0 이후 옵션으로 검토.

---

## ADR-001 — 하니스는 git repo로 배포, 메타-부트스트랩

**Date**: 2026-05-25 · **Status**: accepted

**Context**: 하니스 배포 방식 후보: (a) 단일 SoT + 심볼릭링크 (b) 프로젝트마다 복사 (c) git repo로 만들어 clone/submodule.

**Decision**: (c) git repo. 프로젝트는 하니스 repo를 reference. 프로젝트별 적응적 규칙/스킬은 하니스 자체를 사용해 만든다 (메타 부트스트랩).

**Consequences**:
- 하니스 자체에 버전 필요 (`VERSION` 파일, Phase A.3에서 생성).
- 프로젝트는 `.harness/VERSION-PIN`으로 사용한 버전 기록.
- 하니스 업그레이드 시 마이그레이션 가이드 필요 (Phase D 항목).
- 이 디렉토리는 결국 GitHub 레포가 될 후보 — 파일 작성 시 그 점을 의식 (라이선스, README, .gitignore 등은 Phase E에서).
