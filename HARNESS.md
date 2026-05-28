# HARNESS.md — Hara 헌법 (v2.4.1)

> Claude+Codex 협업의 **절대 규칙**과 **워크플로우 정의**.
> 변경은 §10 절차. 버전 이력은 §11.
>
> **운영 원칙**:
> - **Minimize + hook** (v1.8): 본 문서는 매 세션 강제 read 대상만. 상황별 참조는 [PATTERNS.md](PATTERNS.md) / [FLEET.md](FLEET.md).
> - **Hook-enforced**: 치명적 규칙은 [.githooks/](.githooks/)가 자동 enforce. 본 문서는 *왜*만 설명, hook이 *강제*.
> - **Trim over append** (v2.0): 새 HC/섹션 추가 전 "실제 잘 안 지켜져서 규칙이 필요한가, 아니면 documentation theater인가" 자가 검증. 사용자 지시 (2026-05-27): "안지켜짐 → 규칙 추가 → 길어져서 안 읽힘" 루프 금지. 세션 개성은 전체 흐름만 지키면 수용.

---

## 0. 메타-원칙

하니스는 자기 자신도 하니스 규칙으로 빌드한다 (메타 부트스트랩, dogfood).
모든 phase 진행은 [phases/](phases/)의 Exit 기준을 따른다.

## 1. 절대 규칙 (Hard Constraints)

| # | 규칙 | 의미 |
|---|---|---|
| HC-1 | **Plan-First, Code-Late** | Blueprint 승인 전 코드 X. Module Plan 승인 전 해당 모듈 코드 X |
| HC-2 | **File-Persistent** | 모든 결정·계획·리뷰는 파일로 영속화. 대화 기억에 의존 금지 |
| HC-3 | **Drift-Aware** | phase 경계와 세션 시작 시 "지금 Blueprint와 일치하나?" 자가점검 |
| HC-4 | **Gate-Bound** | phase 간 이동은 [phases/<phase>.md](phases/)의 Exit 기준 만족 필수 |
| HC-5 | **Role-Default** | Claude=구현자, Codex=리뷰어. 역할 스왑은 명시적 결정 + ADR |
| HC-6 | **Status-Updated** | 모든 작업 종료 시 STATUS.md 갱신. **pre-commit hook이 enforce** (RELEASE.md/HARNESS-scaffold 변경 시 루트 STATUS.md 동시 staging). **Scope**: 루트 STATUS.md만 hook enforce. project-local `.harness/status.md` (gitignored sub-project)는 *프로젝트 자체의 책임* — root에서 enforce 불가, 프로젝트 working set에 포함되면 같은 갱신 의무가 그 프로젝트의 hook 또는 사용자 검토로 적용 |
| HC-7 | **Secrets-Redacted** | 시크릿/자격증명/PII는 모든 산출물·로그·리뷰에서 즉시 redact. 어떤 모드에서도 평문 저장 금지 |
| HC-8 | **External-Effects-Gated** | 외부 영향 mutation(deploy, 외부 API write, message send, push to remote)은 **모든 모드에서 사용자 승인** |
| HC-9 | **Destructive-Confirmed** | Destructive 작업(rm/drop/truncate/force-push/branch -D/reset --hard 등)은 **모든 모드에서 사용자 승인** |
| HC-10 | **Local-Extends-Only** | Project-local layer(`.harness/skills/`, `.harness/roles/`, `.harness/capabilities.md`)는 base HC-1~9를 약화·재정의·우회할 수 없다. extension·specialization만 허용. **base phase Exit 기준의 결정 권한은 항상 base에 있음** (local skill이 phase Exit을 자체 판단으로 통과시킬 수 없다) |
| HC-11 | **Codex-Cadence** | 모든 ship-style 커밋(`code|harness|note(...vN.N.N)`)은 r1+r2 codex 리뷰 통과 필수. **pre-push hook이 enforce** (직전 20 커밋 내 review file 부재 시 push 차단) |
| HC-12 | **User-Flow-Verified** | UI surface (tracked `public/` / `frontend/` / `capacitor.config.{json,ts,js}` / `ios/App/` / `android/app/build.gradle{,.kts}`) 프로젝트는 ship 전 첫 사용자 흐름 happy-path 자동 검증 필수. 증거: web → `.harness/runs/e2e-<date>-<slug>.json`; mobile → `.harness/runs/mobile-e2e-<date>-<platform>-<slug>.json` (`platform: ios` 의무, `android` best-effort). 공통 필드 = `status: pass`, `exit_code: 0`, `test_count ≥ 1`, `ran_at` ≤ 24h. **pre-push hook이 enforce** (web/mobile 각각 독립 lane). Scope: first-flow composition만. 트리거 + 상세: ADR-017 (web) + ADR-023 (mobile). |
| HC-13 | **Visual-Review** | HC-12 가 검증한 UI surface 에 *design intent doc* (`<proj>/.harness/docs/ui-spec.md`) 가 존재하는 프로젝트는 ship 전 **visual UX review** 추가 필수. Claude (coordinator, multi-modal) + Codex 가 Maestro `takeScreenshot` 산출물을 *독립* review (r1/r2 pattern) → evidence `ui_review.{claude_pass, codex_pass}` 둘 다 true. 의도: 내부 contract (HC-12) 와 *사용자가 보는 화면* (HC-13) 의 분리. ui-spec.md 미존재 시 opt-in skip (`HC-13 N/A`). base skill: [skills/ui-visual-review.md](skills/ui-visual-review.md). 상세: ADR-025. |

HC-7/HC-8/HC-9는 strictness 모드 무관 항상 적용. HC-6/HC-11/HC-12/HC-13은 hook으로 자동 enforce — 잊어버려도 못 빠져나감. HC-13 은 `ui-spec.md` 존재 시에만 발동 (opt-in).

**Chunking discipline** (v2.3.1 — 사용자 directive 2026-05-28): ship 단위는 *검증 가능한 수준의 적당히 많은 코드* 묶음. 잘게 쪼개기 reflexive 금지. 분할은 *필요할 때만* (depth / cross-module 정합성 / 한 세션 context 한계). 진단 기준 — HC-12 step ≤5 + HC-13 PNG ≤3 = *과한 분할* 신호 (다음 ship 합치는 후보). 4-ship dogfood (starpin v0.13~v0.16) 의 *과한 분할* 인정 → v0.17 wholesale 회수. 상세: [PATTERNS.md §scope-chunking](PATTERNS.md), memory [[feedback-ship-chunking]].

## 2. Strictness 모드

프로젝트의 `.harness/config.toml`에서 선택. **Blueprint 승인은 항상 사용자 필수**, 하니스 자체 변경도 항상 사용자 승인.

| 모드 | 사용자 승인 항목 (HC-7/8/9/11 외) |
|---|---|
| **strict** | Intake, Blueprint, **모든** Module Plan, 모든 ADR, 하니스 자체 변경 |
| **balanced** | Intake, Blueprint, 새 ADR, 하니스 자체 변경. Module Plan은 Codex 리뷰로 갈음 |
| **autonomous** | Blueprint, 하니스 자체 변경 |

하니스 자체 빌드 = **strict**. 모드 변경 자체가 ADR 대상.

## 3. 페이즈 (Workflow)

```
[00 Intake] → [01 Blueprint] → [02 ModulePlan] → [03 Implement]
   → [04 CrossReview r1] → [05 Integration] → [06 Handoff]
```

- 각 phase Exit 기준은 [phases/](phases/) 디렉토리 (00-intake.md ~ 06-handoff.md)
- HC-11에 따라 **CrossReview는 r1+r2 의무** (r1 후 패치 → r2 verify). 1-round ship 금지
- 다중 세션 병렬 Fleet 모드는 [FLEET.md](FLEET.md)

## 4. 산출물 표준 위치

### 4.1 하니스 자체 빌드 (이 레포)

| 산출물 | 위치 |
|---|---|
| 현황 | `STATUS.md` |
| 결정 로그 | `DECISIONS.md` |
| 리뷰 결과 | `.harness/reviews/<phase>-<date>-<slug>.md` |
| Capability 후보 (auto) | `.harness/capability-candidates.md` (pre-commit hook이 자동 갱신) |
| 토큰 ledger (auto) | `.harness/codex-token-ledger.jsonl` |

### 4.2 프로젝트 산출물 (`.harness/`)

| 산출물 | 위치 |
|---|---|
| 설정 | `.harness/config.toml` |
| Intake / Blueprint / Module Plan | `.harness/docs/{intake,blueprint,modules/<name>/plan}.md` |
| 리뷰 | `.harness/reviews/<phase>-<date>-<slug>.md` |
| ADR | `.harness/decisions/ADR-NNNN-<slug>.md` |
| 현황 | `.harness/status.md` |
| Project-local skills/roles | `.harness/skills/*.md` (§7) / `.harness/roles/*.md` |
| Capability manifest | `.harness/capabilities.md` |
| Postmortem | `.harness/postmortems/YYYY-MM-DD-<slug>.md` |
| Fleet artifacts | `.harness/subtrees/<child>/{prompt,locked-interface,merge-report}.md` |

### 4.3 Front-matter 표준

모든 ADR / REVIEW / Module Plan / MERGE-REPORT는 YAML front-matter 필수.
공통 필드 + artifact-specific 필드: [PATTERNS.md §front-matter](PATTERNS.md) 참조.
canonical enum 사용 의무: `severity (blocker|major|minor|nit|info)`, `status (open|resolved|deferred|disputed)`.

## 5. Codex 호출 규약

### 5.1 채널

| 도구 | 용도 |
|---|---|
| `scripts/codex-review.sh` | clean branch diff 리뷰 (PR-sized commit range). 커스텀 프롬프트 불가 (codex CLI 0.132+ 제약 — early-error로 안내) |
| `scripts/codex-bundle-review.sh` | **bundle 리뷰 (실제 dogfood path)**. 파일 묶음 + 커스텀 프롬프트. 코드/텍스트 무관 |
| `scripts/codex-exec-review.sh` | bundle 리뷰의 underlying impl (alias) |

3개 wrapper 모두 `.harness/reviews/`에 canonical metadata + token ledger 자동 기록.

### 5.2 Review determinism

각 review 파일 front-matter는 invocation reproducibility를 위한 metadata 보존: `model`, `reasoning_effort`, `base_ref|commit|uncommitted`, `prompt_source`, `invoked_at`. wrapper가 자동 채움. 본 metadata가 r2 verify에서 r1과 같은 모델/effort 재현 보장.

### 5.3 Cost guardrails

- 한 review 당 expected token 추정 + actual 대비 ledger 기록
- 누적은 `.harness/codex-token-ledger.jsonl` (JSONL, `wc -l` + `jq` 합산)
- 예산 초과 시 STATUS에 명시 + 다음 round 축소

## 6. 드리프트 감지·수정

세부 신호 + 절차 + postmortem 양식: [PATTERNS.md §drift](PATTERNS.md).
Postmortem trigger: (a) HC-7/8/9 위반, (b) 같은 finding 2회 이상 재발, (c) Blueprint 우회.

> v2.0까지 본 섹션에 *"3-질문 자가점검"* 체크리스트가 있었으나 v1.8~v2.0 dogfood (10+ ship)에서 한 번도 명시 invoke 안 됨 — 전형적 documentation theater. v2.1에 삭제. 드리프트 catch는 hook (HC-6/HC-11/HC-12) + codex review에 위임.

## 7. Project-local Adaptive Layer

`.harness/skills/` `.harness/roles/` `.harness/capabilities.md`로 base 하니스를 **확장**한다 (수정 X, HC-10).

- 활성 capability는 `.harness/capabilities.md`의 *Active* 섹션에 명시
- 세션 시작 시 working set에 포함 (자동 discovery 금지 — 명시 의무)
- 신규 local skill 후보는 codex review의 `capability_candidate: yes` finding으로 surfaced → pre-commit hook이 `.harness/capability-candidates.md`에 자동 수집 → 사용자가 promote/close 결정
- 상세 (manifest 양식, promotion 절차, drift 신호): [PATTERNS.md §adaptive-layer](PATTERNS.md)

## 8. STATUS.md 양식 (stranger-proof)

```
## Current
| 항목 | 값 |
| Project | <name> |
| Phase | <currently active phase + sub-phase> |
| Strictness | strict|balanced|autonomous |
| Last updated | <UTC ISO-8601> by <agent> |

## Active gate
- 무엇이 다음 사용자 액션을 막고 있나
- 어떤 codex 리뷰가 진행 중인가
- 미해결 finding 수

## Cumulative
- 누적 ship version + 직전 release link
- 누적 codex token (ledger 기반)
```

stranger (다음 세션 / 다른 사람)가 STATUS.md만 보고 "지금 무엇이 진행 중이고 다음 액션이 뭔지" 알 수 있어야 함.

## 9. Git policy

대부분의 git rule은 `.githooks/`가 자동 enforce (HC-6, HC-11). 사람-에이전트 모두 따른다.

- Branch: `main` + 필요 시 `feat/<slug>`. Fleet 시 child별 `feat/<child>`
- Commit subject: `<type>(<scope>): <subject>` (`type ∈ {code, harness, note, fix, refactor, doc, wip}`)
- Ship-style: `code|harness|note(<scope>-vN.N.N)`. Hook이 WIP 잔존/STATUS 미갱신 차단
- Destructive (force-push, reset --hard, branch -D): HC-9 — 항상 사용자 승인
- `.githooks/` 설치: `git config core.hooksPath .githooks` (clone 1회)

## 10. 하니스 수정 절차

본 파일과 `phases/` `templates/` `roles/` `skills/` `scripts/`의 변경은 *프로젝트 코드 변경과 분리*된 절차:

1. 변경 사유 명시 (어떤 dogfood data가 트리거?)
2. 사용자 승인 (strictness 무관)
3. ADR 작성 (`DECISIONS.md` 또는 `decisions/ADR-NNNN-*.md`)
4. 변경 적용 + STATUS.md 갱신
5. codex r1+r2 리뷰 (HC-11)

## 11. 버전 이력

| 버전 | 변경 | ADR |
|---|---|---|
| v2.4.1 | `--mode=auto|impl|review` flag 추가 — filename suffix (`-impl.md` / `-impl-r<N>.md`) 기반 graceful skip 으로 review/legacy prompt 가 false negative 안 나도록. bare `--mode` 무한루프 + docstring drift 닫음 | ADR-035 |
| v2.4 | `scripts/check-subagent-prompt.sh` lint — v2.3.2 의 5-카테고리 deliverables template 을 *enforceable gate* 로 격상. `--strict` mode 가 impl-review path 의무. starpin v0.18 의 30x speedup 결과 → 의무화 합리 | ADR-034 |
| v2.3.2 | 4-ship dogfood carry 추가 — PATTERNS §deliverable-categories (subagent 5-카테고리 책임 template: code/style/test/fixture/impl-review) + §modal-overlay-race (DOM cleanup vs navigation 분리 패턴) + ARIA imperative for Maestro WKWebView | ADR-032 |
| v2.3.1 | HC-13 dogfood carry 정리 — codex narrative-only output parser robustness + ui-codex round suffix + skill ui-visual-review v0.3 (sim orientation matrix + chunking self-diagnostic + symmetric-pair check) + PATTERNS §subagent-recovery + §scope-chunking + chunking discipline 헌법 추가 | ADR-030 |
| v2.3 | HC-13 Visual-Review 신설 — `ui-spec.md` design intent + Maestro takeScreenshot + Claude(coordinator multi-modal) + Codex visual independent review. base skill `ui-visual-review`. ship gate 의 functional + visual 분리 | ADR-025 |
| v2.2 | HC-12 mobile equivalent extension — surface 감지에 `capacitor.config.*` / `ios/App/` / `android/app/build.gradle` 추가, mobile evidence lane `mobile-e2e-*.json` (`platform: ios` 의무, `android` best-effort), validator helper 공유 | ADR-023 |
| v2.1 | enforcement gap 메우기 — pre-push slug-matching 완화 (scope/version 독립 + r1 default-round 인정), pre-review-gate monorepo subdir 인식 (F42 close), HC-6 carveout 명시 (root vs project-local), §6 3-질문 documentation theater 삭제 | ADR-022 |
| v2.0 | trim discipline — STATUS/HARNESS bloat 제거, HC-12 row 압축, 운영 원칙 명시 | ADR-020 |
| v1.9 | HC-12 User-Flow-Verified (Playwright E2E smoke + pre-push enforce) | ADR-017 |
| v1.8 | minimize + hook (565→200줄, .githooks/ enforce HC-6/HC-11) | ADR-013 |
| v1.1 | Fleet Mode (다중 세션 병렬, depth ≤ 2) | ADR-010 |
| v1.0 | constitution + 6-phase loop + HC-1~9 | initial |

v1.2~v1.7 inflight patch 이력 + archived sections: [PATTERNS.md §history](PATTERNS.md).
