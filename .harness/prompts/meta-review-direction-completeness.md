# Codex Meta-Review — Hara 하니스 방향성 + 완전성 빡센 검토

## 본 review의 성격

본 review는 *일반 코드 cross-review가 아님*. **하니스 자체의 vision vs reality** + *프로젝트 목적 대비 실제 진행 정합성* + *적응형 하니스 design의 evidence*를 빡세게 검토.

Claude (root coordinator)가 자체 분석 후 의심 지점들을 표면화 — codex는 *cold reader 입장에서 독립 검증* + 추가 발견.

## Hara 프로젝트 원래 목적

1. **Claude+Codex 협업 하니스** — Claude가 구현자 / Codex가 리뷰어. 명확한 역할 분리 + 게이트 기반 워크플로우
2. **메타 부트스트랩** — 하니스 자체도 하니스 규칙으로 빌드 (self-application)
3. **Stranger-proof** — 새 세션이 STATUS.md만 읽고 30분 내 이어받기 가능
4. **적응형 vision (v0.6+)** — base layer (HARNESS+phases+templates+skills) + local layer (`.harness/skills` per-project). *local layer가 프로젝트 진행과 함께 자체 진화*가 핵심 가설
5. **Fleet Mode (v1.1+)** — 재귀 coordinator. 큰 프로젝트는 multi-session parallel
6. **3 dogfood (Phase E)** — todo-api / temp-sensor / starpin — 실제 프로젝트로 검증

## 현재 상태 snapshot

### Harness body 누적 (사용자 원칙 "하니스가 길어지면 Claude가 규칙 안 지킴")

| 파일 | 줄수 | 비고 |
|---|---|---|
| HARNESS.md | 565 | v0.6=400 → v1.0=470 → v1.1=520 → v1.2=570 → v1.3=600 → v1.5=565 (cleanup 시도) |
| STATUS.md | 181 | (v1.0 cleanup으로 340→120 압축; v1.5에서 재팽창) |
| DECISIONS.md | 476 | 12 ADRs 누적 (cleanup 안 함) |
| CLAUDE.md / AGENTS.md | 41 / 54 | (cleanup 후 안정) |
| **templates + scripts + skills (base)** | 2200+ | 4 helper scripts + 14 templates + 12 base skills |
| **starpin local layer** | 2200+ | 6 local skills (avg 350줄) + capabilities (198줄) |
| → **세션 시작 시 default read** | ~3500+줄 | (project context 진입 시) |

### Fleet activity (오늘 세션)

- 9 children spawned across 4 rounds (v0.2~v0.4)
- 4 codex full reviews (~600K cumulative tokens 추정)
- 20+ codex findings closed (B/M/m)
- v0.4 backend 227 tests pass

### 적응형 layer activity

- **starpin local skills**: 6개. v0.6 시기 초기 생성 후 **오늘 v0.2~v0.4 Fleet 9 children 진행 중 변경 0건**
- **starpin capabilities.md**: 변경 0건 (frozen at split — v1.1 F3 design intent)
- **base skill promotion**: ADR-008 (`budget-binary-size`) 1건뿐 (v1.0 시기 promotion; 이후 0건)

### Hara 자체 (오늘)

- v1.0 → v1.5+inflight (5+ amendments)
- Open carry-over: F123 (v1.6), F124+ (v1.7 child-recovery)
- 첫 *real-world Fleet dogfood* = starpin-fleet (simulation; 본 v0.2~v0.4도 *same worktree*; **real git worktree 분리 한 번도 검증 안 됨**)

### starpin 완성도

- backend: v0.1 (M1~M5 core) → v0.2 (neighbors/admin2fa/oauth-google/docker) → v0.3 (OAuth 3 providers production) → v0.4 (sky 3d native / rate-limit / PKCE integration test)
- 미완: mobile (iOS/Android) / ingest worker (Python) / snapshot fetch / real prod deploy
- v0.4 RELEASE은 "production-ready hardening" 표현 — *실제 prod deploy + real users* 검증 0

## 내 자체 의심 지점 (codex가 독립 검증해주길)

### A. 적응형 vision의 실제 작동 의심

가설: starpin이 4 round 진행 중 *자체 local skill 진화 0건*은 적응형 vision의 실패 신호 아닌가?
- (a) skill이 잘 설계되어 *재진화 불필요*하다 (good)
- (b) Fleet Mode가 local layer를 *우회* — children이 직접 코드 짜면 local skill enforcement 없음 (bad — skills가 *enforce 안 됨*)
- (c) skill evolution을 위한 trigger mechanism 부재 — *자동 진화 의도였는데 수동도 안 함* (bad)

증거 확인 부탁:
- starpin local skills 6개가 v0.2~v0.4 Fleet 진행 중 *실제로 enforce되었나?* (codex review에서 leverage됐나?)
- v0.3에서 OAuth 3 providers 신설했는데 `oauth-pkce-flow` 같은 신규 local skill *왜 안 생겼나?* (codex가 PKCE 관련 6 finding 발견했는데도)
- v0.4에서 `rate-limit-key-hashing` / `pg-cube-fallback-pattern` 같은 cross-cutting skill *왜 안 생겼나?*

### B. Fleet Mode가 진짜 가치 있나

가설: Fleet Mode는 *같은 worktree에서 Agent tool parallel*만 사용. real git worktree 분리 *한 번도 검증 안 됨*. *진짜 wall-time benefit* 측정 안 됨.

증거 확인 부탁:
- 9 children spawned across 4 rounds — *parallel 이득* 실제 측정값 있나? (또는 모두 sequential과 동일?)
- Same-worktree ownership boundary가 *진짜 isolation 같나*? 아니면 OS-level 차단 없는 self-discipline?
- ESLint AST lock 7개 config 생성 — 실제 *violation 차단* evidence (v0.3 ~ v0.4에서 child가 잘못된 import 시도 → ESLint catch 사례 있었나)?
- 같은 작업을 *Fleet 안 쓰고 single session*으로 했으면 시간/품질 차이?

### C. 하니스 size discipline

사용자 원칙: "obsolete 적극 제거, 단순 append 금지" (2026-05-27 v1.1 시작 시점)

가설: v1.1 cleanup 후 v1.2~v1.5에서 *지속 팽창*. 5 inflight findings 모두 *amendment* (제거 0건).

증거 확인 부탁:
- v1.5 시점에서 *지금 제거 가능한 obsolete* 있나?
  - HARNESS.md §9 (already removed in v1.0 cleanup)
  - HARNESS.md §10 Phase E Exit (v1.0 ship 후 *historical*)
  - templates/ 미사용? (LOCAL-ROLE template — starpin local roles는 advisory reviewer 2개뿐; 본 template 의무?)
  - DECISIONS.md ADR-001~007 (Phase A 시기 — *현재 의미 있나*?)
- starpin local skills 6개 평균 350줄 — *진짜 필요한* 분량? (예: claim-exclusivity-contract 338줄)
- HARNESS §14 (Fleet, 100+ 줄) — 본 dogfood 패턴에서 *모든 child가 이걸 다 읽는가*? subset만 필요한가?

### D. codex review의 hit rate / 가치

가설: codex reviews는 *real bugs 발견* (PKCE, race conditions, TOTP replay)도 했지만 *과잉 findings*도 다수.

증거 확인 부탁:
- 누적 codex token spend ~600K — 가치 대비 비용 적정?
- "Fleet F7 dogfood 한정 self-test 허용" — *얼마나 자주* self-test로 대체했나? *self-test가 catch 못한* bug가 별도 codex round에서 발견됐나?
- v0.2 finding F70-F75, v0.3 finding F100~F106, v0.4 F110~F117 / F70~F78 / etc — *finding ID 중복 patterns 있나*?

### E. starpin "완성" 정의

가설: 사용자 vision = "거의 완성된 starpin 앱". 현재는 *backend service core + 3 OAuth + admin TOTP + docker infra*. mobile/ingest/real deploy 0.

증거 확인 부탁:
- v0.4 RELEASE "production-ready hardening" 표현 *정당*한가? (real deploy/real users 없음)
- "거의 완성" 도달 시기 estimate? mobile이 가장 큰 gap이라면 *Fleet으로 가능한가* (iOS Swift/Android Kotlin native build 환경 없는데)?
- backend만 "production-ready"라 *반쪽 완성* 아닌가? 사용자 vision과 정합?

### F. Hidden gaps (codex 발견 부탁)

다음 영역에서 *내가 놓친* 결함을 빡세게 찾아줘:
- HARNESS.md §14 Fleet rules가 *서로 모순*하는 부분 (예: F3 manifest freeze vs F9 child capability draft)
- ADR-001~012 누적 — *서로 superseded되어야 하는데 안 된* 항목
- starpin local skills *서로 overlap* (예: external-catalog-rate-limit vs lib/rate-limit.ts new)
- `examples/fleet-mini/` + `examples/starpin-fleet/` 가 *유지보수되지 않는 dead code* 가능성
- `project-types/_generic/esm-jest-pattern.md` seed가 *어디서도 사용 안 됨* — dead artifact?
- v1.1 신설 `templates/LOCAL-ROLE.template.md` v0.6 시기 — 본 template 사용 사례 있나?

## 요청

위 의심 지점들 + codex가 cold reader 입장에서 추가로 발견하는 *모든 게* 점검 대상. 특히:

1. **Hara가 자기 vision대로 동작하나** (메타 부트스트랩 + 적응형 + Fleet)
2. **starpin이 사용자 vision대로 진행 중인가** ("완성" 정의 정합성)
3. **Hidden technical debt** (codex가 한 발 떨어져 보고 발견)
4. **Cleanup target** (제거 가능 obsolete) — 사용자 원칙 직접 영향
5. **다음 라운드 권장 방향** (codex 권고 — Hara v1.6 vs starpin v0.5 vs cleanup round vs ...)

REVIEW 양식 — severity (blocker/major/minor/info) + 위치 + 근거 + 제안.

본 review는 *방향성 검토*이므로 minor도 valuable. *blocker 없어도 깊은 정성 review* 권장.
