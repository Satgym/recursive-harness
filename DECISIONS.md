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

## ADR-016 — starpin v0.9 HD namespace + sky planet API

**Date**: 2026-05-27 · **Status**: accepted (user-recommended "추천해줘")

**Scope**: 2 paired carry items from v0.8 — restore HD aliases as `hd` namespace (v0.8 r1 #2) + expose v0.8's loaded planet_positions via `/v1/sky/planets` (closes "data loaded but not exposed" gap).

**References**:
- codex v0.8 r1 #2 (HD as HIP corruption)
- v0.8 STATUS "v0.9 carry" — sky planet integration + hd namespace
- ADR-002 amended (manifest sha `3b217f0e775df…`)
- migration 0032
- codex v0.9 r1 (2 findings: blocker + major) + r2 (1 closed + 1 partial → closed)

**Decision**:

### A. HD namespace restored (codex v0.8 r1 #2)
1. Migration 0032 — `object_aliases.source_catalog` enum adds `'henry-draper'`; idempotent DO blocks
2. `canonical-id.ts` — `'hd'` added to VALID_SOURCES (separate from `'hip'`)
3. `ingest/fetch_aliases.py` — HD restored in SIMBAD_PREFIX_MAP, emits `source_catalog: 'henry-draper'`
4. Verified: 35 HD aliases load alongside 34 HIP — distinct namespaces

### B. /v1/sky/planets endpoint (v0.8 carry)
1. `backend/src/sky/planet-repository.ts` (NEW) — read-only access, `DISTINCT ON (body_id)` latest-per-body + epoch filter
2. `backend/src/routes/sky-planets-route.ts` (NEW) — auth-gated, optional `?epoch_utc=ISO` filter
3. UTC contract round-trippable (r2 #2): canonical `YYYY-MM-DDTHH:MM:SS.sssZ` form, parse-validate via `Date`, year range bound 1900-2100, repo uses `to_char(... AT TIME ZONE 'UTC', ...)` for stable output
4. Verified: 8 planets queryable, response epoch_utc can be fed back as query (round-trip test)

### C. Codex review evidence
- r1: 2 findings (1 blocker server.ts ts-jest narrowing + 1 major epoch_utc UTC semantics)
- r2: 1 closed + 1 partial → patched to closed (round-trip contract + bound)
- 26 test suites / **279 tests + 3 skipped / 0 fail** (+8 new for v0.9)

**Consequences**:

positive:
- Name-based lookup via HD numbers now works (Sirius = HD 48915, queryable)
- Planet positions exposed via stable API contract — UI/native clients can render planets alongside stars
- UTC contract is round-trippable (response value ↔ query input)
- Year-range guard catches Date.parse silent failures (e.g., `0000-01-01`)

negative:
- 117 aliases — bounded scope (36 SIMBAD calls); v0.9+ streaming for full bright sample still carry
- `/v1/sky/planets` is single-epoch in current ingest (8 planets per snapshot); multi-epoch hourly cadence is v0.10 carry
- Year bound 1900-2100 — astronomy queries beyond that window need wider range

후속 (v0.10+):
- Multi-epoch planet ingest (hourly window for 24h or daily)
- `/v1/sky/now` integration with planets (currently stars only)
- Streaming SIMBAD batch for full Gaia bright sample
- Temp-table swap-on-commit
- Native mobile (still requires Xcode + Android Studio)
- Real cloud deploy level 2

**Approval**: user · 2026-05-27 · autonomous (사용자 "추천해줘" delegated)

---

## ADR-015 — starpin v0.8 catalog data quality bundle (sentinel→NULL + aliases + planet_positions)

**Date**: 2026-05-27 · **Status**: accepted (user-directed "진행해줘")

**Scope**: 3 carry items from v0.6 codex r1 (#18) + v0.6 deferred features (object_aliases population, planet_positions table). Closes catalog data quality gaps without expanding stack.

**References**:
- codex v0.6 r1 #18 (sentinel pollution)
- v0.6 STATUS "v0.7 carry-over" — object_aliases + planet_positions
- ADR-002 amended (manifest sha `dc13e2ba71263b…`)
- migrations 0030, 0031
- codex v0.8 r1 (5 findings) + r2 (1 partial closed)

**Decision**:

### A. Sentinel → NULL (codex v0.6 #18)
1. Migration 0030 — ALTER COLUMN mag DROP NOT NULL + CHECK allows NULL + tight predicate backfill (`source_catalog='simbad' AND parallax_mas IS NULL`) with `> 50 rows aborts` HC-9 guard
2. Python ingest writes `mag=None` directly for fallback rows (no sentinel)
3. Repository viewport queries: `ORDER BY mag ASC NULLS LAST`
4. Loader NO LONGER normalizes — passes mag through honestly (r2 #6)

### B. object_aliases population (v0.6 carry)
1. `ingest/fetch_aliases.py` (NEW) — SIMBAD batch query, bounded to 6 fixtures + 30 brightest Gaia rows
2. Per-call rate limit (1.2s) + retry — re-uses common.with_retry
3. Loader extension: aliases.ndjson → object_aliases UPSERT with SAVEPOINT (FK orphan tolerance)
4. Phase-ordered load: objects → aliases → planets (FK dependency)
5. HD dropped from SIMBAD prefix map (r1 #2 — HD ≠ HIP namespace; v0.9 carry: dedicated `hd` source)

### C. planet_positions table (v0.6 carry)
1. Migration 0031 — new table, PRIMARY KEY (body_id, epoch_utc), separate from objects
2. Loader extension: horizons-*.json → planet_positions UPSERT
3. v0.8 ships single-epoch only; multi-epoch in v0.9 hourly cadence

### D. Codex review evidence
- r1: 5 findings (1 blocker + 2 major + 2 minor)
- r2: 4 closed + 1 partial → patched + closed
- 247 unit tests pass (+6 new loader tests)
- End-to-end smoke: 646 objects + 82 aliases (HD-free) + 8 planets

**Consequences**:

positive:
- Real fixture-target lookup via HIP aliases works (Polaris by name → Gaia DR3 source_id)
- mag NULL preserves percentile/avg integrity (no sentinel pollution)
- Planet ephemerides queryable by body_id + epoch
- HC-9 migration guards prevent future lossy backfills

negative:
- 35 alias rows dropped (HD entries) — name-based lookup via HD numbers won't work until v0.9
- SIMBAD batch scope is bounded to 36 calls; full Gaia bright sample alias cross-match deferred to v0.9 (streaming)
- planet_positions ships with 1 epoch — sky service doesn't yet query it (route work in v0.9)

후속 (v0.9+ carry):
- `hd` canonical namespace (object_aliases.source_catalog enum + canonical-id update)
- Streaming SIMBAD batch for full bright sample
- Sky service planet integration (current /v1/sky/viewport returns stars only)
- Temp-table swap-on-commit for snapshot rotation (M2 §6.2)
- Full mag ≤ 12 Gaia ingest

**Approval**: user · 2026-05-27 · autonomous

---

## ADR-014 — starpin v0.7 deploy-ready level 1 (prod-sim, observability scaffold)

**Date**: 2026-05-27 · **Status**: accepted (user-directed 2026-05-27 "완전성 우선")

**Scope**: starpin deploy-ready layer level 1 — local production-shape Docker stack + observability surface (NOT real cloud deploy). Native mobile deferred to v0.8 (Xcode/Android tooling absent → would violate "정직한 분할").

**Context**:
v0.6 ship closed data-ingest-ready layer; starpin had 2 remaining gaps (native mobile + deploy). Native mobile requires Xcode + Android Studio neither of which are installed on host — Claude cannot honestly build/test that code. Deploy-ready is fully verifiable in-Docker and addresses the second-biggest gap.

"Level 1" = production *shape* without cloud: same secrets discipline, same healthcheck contract, same metrics surface as a real prod deploy, but runs locally. Real cloud (v0.8+) brings its own secret manager (Vault/SM) + observability stack (managed Prometheus/Loki) — the *application code* stays unchanged.

**Decision**:

### A. Backend container + prod compose

- `backend/Dockerfile` — multi-stage (node:22-alpine builder + runtime), non-root user, embedded healthcheck via wget
- `docker-compose.prod.yml` — backend service IS in compose (dev runs on host); all secrets via Docker secret file mounts (never env literals); no host port for postgres/redis; structured JSON log driver with rotation; `*_FILE → env` expansion at container entrypoint

### B. Health endpoints

- `GET /healthz` (liveness): constant-time, no DB/disk/network IO. Container restart trigger.
- `GET /readyz` (readiness): DB query + snapshot loaded + objects table populated. 503 with reason if any fails. Traffic router trigger.
- 5 unit tests cover happy path + each failure mode (DB fails / snapshot unloaded / empty objects).

### C. Metrics endpoint

- `GET /metrics` (Prometheus text format) — `backend/src/lib/metrics.ts` is a 100-line zero-dep registry. Cardinality budget ≤ 200 series.
- 4 counters (http_requests / http_errors / oauth_callback / boot) + 1 gauge (uptime).
- HC-7 hygiene: label values are bucketed (route template, status_class, provider), never user id / token / IP literal. Backslash+quote escaping in label rendering.
- 5 unit tests cover render format, label cardinality, escape behavior.

### D. Secret management

- `scripts/init-prod-secrets.sh` — generates 4 prod secrets (pg_password from existing dev script + database_url constructed + internal_service_secret random + snapshot_checksum read from ADR-002). All files chmod 0600, gitignored via `.docker-secrets/.gitignore`. Idempotent.
- `.env.template` — committed reference of all required env vars (no real values). Documents `*_FILE` convention for prod secrets.

### E. Observability scaffold

- `ops/prometheus-rules.yml` — 4 alert rules consuming the metrics surface (backend down, error rate >5%, boot loop, OAuth failure rate).
- `ops/README.md` — what ships in v0.7 vs deferred to v0.8 (no Grafana dashboard yet, no Loki, no tracing — all data-blind speculation without real metric history).

### F. End-to-end smoke

`docker compose -f docker-compose.prod.yml up --build`:
- All services healthy (postgres + redis + backend)
- snapshot loader verified ADR-002 checksum + UPSERTed 646 rows
- /healthz 200, /readyz 200 (all 3 checks pass)
- /metrics serves Prometheus format with live request counters
- Structured JSON logs

### G. NOT in v0.7 scope (carry-over)

- Real cloud deploy (k8s manifest, Terraform, AWS/GCP/Fly config)
- Grafana dashboard (need real metric distribution first)
- Loki / log aggregation
- OpenTelemetry tracing
- DB password rotation (requires Postgres-side ALTER ROLE + downtime)
- Backup/restore strategy
- TLS termination (reverse proxy responsibility — nginx config v0.8)

**Approval**: user · 2026-05-27 · autonomous (사용자 "완전성 우선" delegated)

---

## ADR-013 — Hara v1.8 minimize + hook (rule doc cut + git hook enforcement)

**Date**: 2026-05-27 · **Status**: accepted (user-directed 2026-05-27 "치명적인 문제가 발생하지 않을 점들에 대해서는 최대한 줄이고, 정말 중요한 로직과 치명적인 버그를 막는 구조만 유지 + 훅 활용")

**References**:
- `.harness/reviews/06-20260527-meta-harness-usage-gap-r1.md` (codex meta-review, 205k tokens)
- HARNESS.md v1.7 (559줄) → v1.8 (185줄)
- PATTERNS.md / FLEET.md (신설 — cut content 분리)
- `.githooks/{pre-commit,commit-msg,pre-push,README.md}` (신설)
- `scripts/codex-bundle-review.sh` (신설 — bundle review formal path)

**Context**:
v0.5 + v0.6 dogfood 회고 (codex + self-review)에서 일관된 패턴 surfaced — 하니스 표면적의 ~40%만 실제 사용, 60%는 spec-only / bypassed. 내가 놓친 7건 (codex가 catch한)이 모두 "문서에 있지만 안 읽음" 패턴 (pre-review-gate root, STATUS 내부 모순, Fleet worktree spec drift 등). 추가 구조를 11개 신규 제안한 것이 *정확히 이 악순환의 다음 사이클*임을 사용자가 지적.

**Decision**: Hara v1.8 — 두 축으로 amend.

### A. Minimize (cut HARNESS.md 565→185줄, 66% 감소)

1. **HARNESS.md 재작성** — must-read content만 유지. 구체 cut:
   - §6.3-6.4 Postmortem 상세 → PATTERNS.md
   - §11 Dispute protocol (24줄) → PATTERNS.md (v0.5/v0.6 dogfood에서 0회 invoke)
   - §13.5-13.7 Adaptive 상세 → PATTERNS.md
   - §14 Fleet Mode 본문 160줄 → FLEET.md
   - §5.2 Codex 모델 spec 상세 → PATTERNS.md
2. **PATTERNS.md 신설** (205줄) — reference 자료. 문제 발생 시만 read
3. **FLEET.md 신설** (162줄) — Fleet 작업 시만 read (split / child / merge)
4. **CLAUDE.md 갱신** — read 순서 명확화 (must vs reference 분리)

원본 559줄 → must-read 185줄 → 상시 read 부담 -66%.

### B. Hook enforcement (.githooks/ 신설)

5. **pre-commit**: 
   - RELEASE.md staged → STATUS.md 동시 staged 강제 (v0.6 r2 #21 패턴 자동 차단)
   - capability_candidates 자동 수집 (reviews/merge-reports에서 `capability_candidate: yes` grep → `.harness/capability-candidates.md` append, 자동 staging)
   - 베스트-에포트 typecheck (`npx tsc --noEmit`)
6. **commit-msg**:
   - ship-style 커밋 (`code|harness|note(...vN.N.N)`)에 직전 10개 안에 `wip(` 잔존 시 차단
7. **pre-push**:
   - ship-style 커밋 push 시 직전 20개 안에 `.harness/reviews/*.md` 신규 추가 부재면 차단 (HC-11 자동 enforce)
8. **설치 안내**: `git config core.hooksPath .githooks` (clone 1회). README 별도

### C. 보조 (Wave 1 P0 bug fixes)

9. **`scripts/pre-review-gate.sh`** — root detection을 git toplevel → nearest `.harness/` ancestor + `--root` 옵션 (F127). monorepo case에서 harness self-checks가 잘못 실행되던 버그 해결.
10. **`scripts/_codex_postprocess.py`** — body의 leading `---...---` YAML 블록을 strip하여 outer frontmatter와 중복 방지 (F128). machine-readability 회복.
11. **`scripts/codex-bundle-review.sh`** 신설 — bundle review (실제 dogfood path)를 formal 지원. `codex-exec-review.sh`의 alias이지만 의도 명시.
12. **`scripts/codex-review.sh`** — codex CLI 0.132+ 호환성 fix. `--uncommitted/--commit/--base` + custom prompt 조합 시 early-error + bundle-review 안내 (F129).

### D. 신규 HC (Hard Constraint)

- **HC-11 Codex-Cadence**: ship-style 커밋은 r1+r2 codex 리뷰 통과 의무. pre-push hook이 enforce. 1-round ship 금지 — v0.4/v0.5/v0.6 dogfood data가 모두 r2까지 패치 필요 입증.

**Consequences**:

positive:
- HARNESS.md 강제 read 의무 66% 감소 → 읽힐 확률 ↑
- hook enforce → 에이전트 망각 / 컨텍스트 압박에 무관하게 critical gate 작동
- codex finding이 catch한 7건 중 4건이 hook으로 자동 닫힘 (HC-6/HC-11/capability-collection/WIP-residue)
- bundle review가 공식 path로 promote — codex CLI 0.132 호환성 회복

negative:
- 첫 clone 후 `git config core.hooksPath .githooks` 수동 실행 의무 (one-time)
- hook `--no-verify` bypass 가능 — 사용자 명시 승인 필요 (CLAUDE.md 명시)
- PATTERNS.md/FLEET.md 분리로 문제 발생 시 어디 보는지 학습 필요 (HARNESS.md §11이 가이드)

후속:
- v1.9 carry: phases/ roles/ templates/ skills/ 디렉토리 full audit (현재는 spot trim만)
- v1.9 carry: shared-findings broadcast (FLEET.md §11에 명시)
- v1.9 carry: collect_merge_reports.py + 자동화
- v1.9 carry: review-rerun-prompt template (4회 ad-hoc 작성한 패턴)

**Approval**: user · 2026-05-27 · autonomous (사용자가 P0+P1+P2 전면 채택 선택)

---

## ADR-012 — Hara v1.3 AST-level lock enforcement + Strategy helper scripts 실 구현

**Date**: 2026-05-27 · **Status**: accepted (user-delegated 2026-05-27 — "자체적으로 계속 최선의 진행방향으로 발전")
**References**:
- HARNESS.md §14.8 promote (grep → AST primary, ESLint flat config `no-restricted-imports`)
- HARNESS.md §14.9 strategy a/b/c helper script *실 구현* 명시
- HARNESS.md §14.2 F7 codex 대체 heuristic 4 조건 명문화 (F70-fleet-3)
- skills/lock-eslint-gen.md (신설 v0.1)
- scripts/fleet/gen_stub.py / gen_ambient.py / topo_sort.py / gen_eslint_lock.py (신설)
- templates/SUBTREE-PROMPT.template.md (mid-work escalation 섹션 신설 — F70-fleet-1)
- project-types/_generic/esm-jest-pattern.md (신설 seed — F86)
- 실 validation: starpin-fleet 4 child에 ESLint lock rule 적용 → 의도적 violation 정확히 catch (F102 mechanical evidence)

**Context**: v1.2 ship 후 사용자 지시 "진행해" — v1.3 trigger 후보 중 highest-value 선택. v1.2 codex F102가 "lock-grep-gate는 advisory not mechanical"이라 지적했고, v1.3은 *그 한계를 실 ESLint AST rule로 해결*. 동시에 v1.2 §14.9의 strategy a/b/c가 *명세만 있고 helper script는 명시되지 않은 상태*였음 — v1.3에서 *실제 작동하는 4 Python script* 작성 + retroactive validation.

**Decision**: Hara v1.3 amend.

### A. AST-level lock enforcement (primary, grep fallback)

1. **신규 base skill `lock-eslint-gen.md`** — ESLint v9+ flat config (`eslint.config.<child>.mjs`)을 child별 자동 생성. `no-restricted-imports` rule이 locked-interface allowlist 외 모든 named import를 *AST error*로 차단
2. **신규 helper script `scripts/fleet/gen_eslint_lock.py`** — SPLIT-DECISION-ADR + 각 child의 locked-interface §"Consumed interface"를 파싱하여 flat config 생성. multi-line import + type-only import 구분 + 모든 provider module exports와 cross-check
3. **HARNESS §14.8 promote** — primary는 `lock-eslint-gen` (AST), v1.2의 `lock-grep-gate`는 fallback (ESLint 미설치 / legacy 환경)

### B. Strategy a/b/c helper scripts 실 구현 (F101 closure)

4. **`scripts/fleet/gen_stub.py`** — Strategy (a). locked-interface §Public interface → stub file with `throw new Error('not-implemented')` bodies. Provider child가 완전 덮어쓰기 의무
5. **`scripts/fleet/gen_ambient.py`** — Strategy (b). locked-interface → `.d.ts` ambient declaration. Consumer worktree에 둠. Phase 05 merge 시 *제거 검증* 의무 (v1.2 Phase 05 amend로 이미 명세)
6. **`scripts/fleet/topo_sort.py`** — Strategy (c). SPLIT-DECISION-ADR §"Dependency graph"의 `a -> b` 형식 파싱 → wave별 spawn order 출력. parent가 wave별 순차 dispatch

### C. Small wins

7. **`templates/SUBTREE-PROMPT.template.md` mid-work escalation 섹션 신설** (F70-fleet-1) — child가 작업 중간에 lock/invariant 위반, shared change 필요, 횡단 invariant 신규 발견, HC 위반 risk, inter-lock mismatch 5 카테고리 발견 시 `.harness/subtrees/<self>/escalation.md` 즉시 기록 + paused 의무. 양식 명시
8. **HARNESS §14.2 F7 codex 대체 heuristic 4 조건** (F70-fleet-3) — self-test 갈음 가능은 (i) examples/ or dogfood/ 경로 (ii) LOC < 1500 (iii) HC-7/8/9 없음 (iv) 외부 통신/DB write/auth/결제 부재. 4 모두 충족 시만; SPLIT-DECISION-ADR의 `codex_review_replacement` field에 명시
9. **`project-types/_generic/esm-jest-pattern.md` seed 신설** (F86) — `jest` import / `isolateModulesAsync` / `.js` extension / `tsconfig: { strict: false }` override 함정 / 표준 config 양식. dogfood 신호 3건 (starpin / fleet-mini / starpin-fleet) 통합

### D. Retroactive validation

- `gen_stub.py` + `gen_ambient.py` + `topo_sort.py` + `gen_eslint_lock.py` 모두 **starpin-fleet locked-interfaces에 실 적용 PASS**
- ESLint lock config가 starpin-fleet의 4 child source에 적용: 실 코드는 violation 0 (children이 lock 준수했음을 confirm)
- 의도적 violation (claim에 `createSession` import) → ESLint **정확히 catch**:
  ```
  src/claim/violation.ts
    1:10  error  'createSession' import from '../auth/index.js' is restricted. Lock violation (Fleet F1 / F90)...
  ```
  → F102 mechanical enforcement 실 작동 evidence

**Consequences**:

- positive:
  - lock enforcement가 *진짜 typecheck-level*에 도달 (ESLint AST rule — alias / multi-line import 모두 catch). v1.2의 "automated gap detection"에서 v1.3의 "mechanical enforcement"로 격상
  - Strategy a/b/c가 *실 helper script로 작동* (v1.2의 "명세만"에서 v1.3 "실 실행")
  - dogfood 신호의 v1.4 buffer 비움 (mid-work escalation / codex 대체 heuristic / ESM jest 표준 — 모두 처리)
  - HARNESS body 증가 *최소* (§14.8/9 amend 위주, 새 §X 신설 없음)
- negative:
  - ESLint v9+ 의존 추가 (legacy v8 사용자에겐 grep fallback 의존)
  - re-export barrel / namespace import (`import * as X`)는 ESLint rule으로 *부분* catch — *완전*은 v1.4 custom AST walker 후보
  - helper script들이 Python 3 의존 (Node-only 환경에서는 별도 설치)
- risk:
  - SPLIT-DECISION-ADR template이 v1.3 신규 field (`codex_review_replacement`) 의무화하지 않음 — 본 ADR-012는 *권장*만, 차후 amendment에서 mandatory 전환
  - locked-interface §"Consumed interface"가 정확히 명시 안 됐을 때 ESLint config는 allowlist=∅로 처리 → child 의도와 다를 수 있음. spec 작성 책임은 root coordinator

**Approval gate**:
- 사용자 승인 필수 (하니스 자체 변경 — strict 모드)
- approver: <pending>
- approval scope: §14.8 promote (AST primary) + §14.9 helper scripts 실 구현 명시 + lock-eslint-gen skill + 4 Python helper scripts + SUBTREE-PROMPT mid-work escalation + §14.2 F7 codex 대체 heuristic + esm-jest-pattern seed

---

## ADR-011 — Hara v1.2 Fleet enforcement 강화 (starpin-fleet real-world dogfood trigger)

**Date**: 2026-05-27 · **Status**: accepted
**References**:
- HARNESS.md §14.8 (lock & invariant enforcement) + §14.9 (inter-child consume timing) + §14.10 (scope-bounded gates) 신설
- skills/lock-grep-gate.md (신설 v0.1)
- skills/spawn-subtree-prompts.md (preflight: inter_child_consume_strategy 의무)
- templates/SUBTREE-PROMPT (Pre-review-gate scope-only section 신설; ownership SoT 참조로 일원화)
- templates/MERGE-REPORT (INV evidence 코드 path 인용 의무)
- templates/SPLIT-DECISION-ADR (inter_child_consume_strategy field + root_path/current_depth/resulting_depth/max_depth_allowed field 의무)
- templates/LOCKED-INTERFACE.template.md (신설 — runtime/type-only import 구분 + 행동 spec + defensive validation policy 의무)
- examples/starpin-fleet/ v0.1.0 (real-world dogfood evidence + 11 v1.2 findings)
- F80 patch (ADR-001 split-decision 작성 즉시 발견 → HARNESS §14 F6 amend로 흡수)

**Context**: Hara v1.1 ship 후 사용자 지시 (2026-05-27): "이제 다시 알아서 진행해 ... 백그라운드 세션 부르는 방식으로 테스트 및 하니스 개선". starpin Blueprint 기반 *real-world Fleet dogfood* (starpin-fleet) 진행 — 4 children parallel spawn (Agent run_in_background) + inter-child consume (sky→catalog, claim→auth) + 4 cross-cutting invariants.

결과: Fleet pattern mechanically 작동 (45 tests PASS, lock 4/4, invariant 4/4, boundary 0 violation). **그러나** real-world에서 11 unique v1.2 finding 도출 — 모두 *enforcement gap* (TypeScript typecheck로 막히지 않는 lock 항목들).

**Decision**: Hara v1.2 amend.

### A. HARNESS §14 amendments (3 신규 subsections)

1. **§14.8 Lock & invariant enforcement** (F87/F90/F82 patch)
   - Single-method consume: locked-interface에 *runtime import vs type-only* 구분 의무
   - Invariant-guard import 검증: (a) runtime gate wrapper redesign 또는 (b) `// @invariant-guard: <util>` 표준 marker
   - MERGE-REPORT INV evidence는 *실제 코드 path 인용* 의무 (false evidence는 child re-work)
   - parent의 `lock-grep-gate` skill이 자동 검증

2. **§14.9 Inter-child consume timing** (F81 patch)
   - SPLIT-DECISION-ADR에 `inter_child_consume_strategy: a|b|c` field 의무
   - (a) lock-spec stub: parent가 provider stub 미리 작성
   - (b) type-only ambient: consumer가 ambient declaration 자체 작성
   - (c) topological spawn order: spawn skill이 provider 후 consumer dispatch
   - spawn preflight가 strategy field 검증

3. **§14.10 Scope-bounded pre-review-gate** (F85 patch)
   - spawn-subtree-prompts skill이 SUBTREE-PROMPT 생성 시 *child별 scope-only* typecheck/test 명령 자동 주입
   - Fleet F4 (ownership) 옆에 *gate scope rule* 신설 — child gate = files it owns + shared transitive imports

### B. 신규 base skill

- `skills/lock-grep-gate.md` v0.1 — parent Phase 05 merge-collection에서 자동 호출. consume allowlist + invariant util 호출 + INV evidence cross-check

### C. 신규 base template

- `templates/LOCKED-INTERFACE.template.md` — 그동안 *예제로만 존재*, 정식 template 신설. runtime/type-only import 명시 / 행동 spec / file ownership SoT / defensive validation policy 의무

### D. Template amendments

- `SUBTREE-PROMPT.template.md`: 작업 범위 섹션은 locked-interface §File ownership *참조*만 (F83 SoT). Pre-review-gate scope-only 섹션 신설 (F85). 종료 절차에서 MERGE-REPORT 양식 명시 (F88).
- `MERGE-REPORT.template.md`: 횡단 invariant 섹션에 *실제 코드 path 인용 의무* (F87)
- `SPLIT-DECISION-ADR.template.md`: front-matter에 `root_path/current_depth/resulting_depth/max_depth_allowed/inter_child_consume_strategy` field 의무화 (F74 강화 + F81)

### E. F80 patch (이미 적용 — 본 ADR에서 명시)

- HARNESS §14 F6: `approver: user` / `approver: user-delegated` + `delegation_source` / `dogfood_simulation: true` 3 path
- spawn-subtree-prompts preflight: 3 path 검증 + 추가 게이트 (delegated이면 source 비어있지 않음; simulation이면 path가 examples/)
- SPLIT-DECISION-ADR template: 3 path 양식 명시

### F. Carry-over (v1.2 미해결)

- F70-fleet-1: child mid-work escalation 위치 — v1.3 후보
- F70-fleet-2 / F92: real git worktree dogfood — v1.3 후보
- F70-fleet-3: parent codex review 대체 heuristic 명문화 — v1.3 후보
- F86: ESM jest module isolation 표준 패턴 — project-type seed에 가이드 추가 검토

**Consequences** (F106 v1.2 codex down-tone):

- **positive**:
  - lock enforcement에 **automated gap detection layer 추가** (lock-grep-gate skill — *typecheck 수준 아님*, grep first-line + MERGE-REPORT evidence + codex second-line)
  - inter-child consume timing 명세화 — 3 strategy (stub/ambient/topo) 절차 작성, 단 helper script (`gen_stub.py` 등)는 v1.3 후속
  - scope-bounded gates 명세 — spawn skill이 per-child tsconfig/jest config 생성 의무
  - **real-world dogfood가 gap discovery로서 효과적** (11 unique finding) — *simulation에서 못 본 것을 real에서 본다* evidence. **단 본 dogfood는 same-worktree boundary + self-test로 진행** — *진짜 mechanical enforcement* 검증은 real git worktree + AST rule 적용한 v1.3 후속 dogfood에서

- **negative**:
  - HARNESS body가 v1.1 → v1.2에서 ~80줄 추가 (cleanup pass 후에도). 470 → ~550줄. 사용자 지시 "하니스가 길어지면 claude가 규칙을 안 지킴"과 trade-off — v1.2 amendment는 *enforcement 강화*가 본질이라 줄이기 어려움
  - lock-grep-gate skill은 *grep 기반* — false positive/negative 가능 (간접 호출은 못 잡음). ESLint rule이 더 강할 수 있으나 본 v1.2는 grep으로 충분

- **risk**:
  - LOCKED-INTERFACE template은 *신규 양식* — 기존 fleet-mini/starpin-fleet의 locked-interface는 양식 후속 적용 필요 (또는 v1.2 template 적용 strict-only로 가능)
  - inter_child_consume_strategy = (c) topo-order는 *parallel 이득 일부 포기* — heuristic 가이드 부재 (어떤 case에 어떤 strategy?) → v1.3 후보

**Codex review evidence**:
- review file: `.harness/reviews/harness-amend-20260527-v1.2-fleet-enforcement.md` (tokens 97,740)
- verdict: 1 blocker + 5 major + 1 minor; HC-7/8/9 위반 0
- patches applied:
  - **F100 (blocker)**: `approver: user-delegated`는 examples/ 경로만 허용 (production은 `approver: user` 직접 승인 또는 out-of-band confirmation artifact 의무). v1.3 후보 — Slack/email signature 통합
  - **F101 (major)**: spawn skill에 strategy a/b/c별 *실제 절차* 추가 — (a) stub 자동 생성, (b) ambient declaration 생성 + merge phase 제거 검증, (c) topological order *안내* (강제 dispatch는 Claude Code SDK multi-session 의존 — v1.3 후속). helper script들은 v1.3 후속
  - **F102 (major)**: §14.8 + lock-grep-gate "mechanical" → "automated gap detection" language down-tone. AST/ESLint v1.3 carry-over 명시
  - **F103 (major)**: Phase 05 Activities Step 0 + Exit 기준에 lock-grep-gate PASS 명시
  - **F104 (major)**: spawn skill Step 3.5 신설 — per-child tsconfig.<child>.json + jest.config.<child>.mjs 자동 생성 (yq 의존; fallback은 inline)
  - **F105 (major)**: spawn skill Step 3 — LOCKED-INTERFACE template *인스턴스화* + 6 필수 섹션 모두 채움 의무. 누락 시 die
  - **F106 (minor)**: ADR-011 positive consequences "typecheck 수준에 근접" → "automated gap detection layer" 정직한 down-tone
- 후속 codex 재리뷰: 본 patches에 대해 *별도 round 불필요* (mechanical). real-world enforcement 검증은 v1.3 후속 dogfood

**Approval**:
- approver: user
- approved_at: 2026-05-27
- approval scope: §14.8/9/10 신설 + lock-grep-gate skill + LOCKED-INTERFACE template + SUBTREE-PROMPT/MERGE-REPORT/SPLIT-DECISION-ADR template amend + F80 + F100~F106 patches + starpin-fleet v0.1.0 dogfood evidence + Phase 05 lock-grep-gate gate
- 후속: v1.3 후보 (real git worktree dogfood + AST/ESLint lock rule + helper scripts + out-of-band confirmation + wall-time benefit 측정)

---

## ADR-010 — Hara v1.1 Fleet Mode 도입 (재귀 coordinator 패턴, depth ≤ 2)

**Date**: 2026-05-27 · **Status**: accepted
**References**:
- HARNESS.md §14 (신설)
- skills/estimate-project-scope.md (신설 v0.1)
- skills/spawn-subtree-prompts.md (신설 v0.1)
- templates/SUBTREE-PROMPT.template.md / SUBTREE-STATUS.template.md / SPLIT-DECISION-ADR.template.md / MERGE-REPORT.template.md (신설)
- examples/fleet-mini/ (신설 v0.1 dogfood)

**Context**: v1.0 검증 후 사용자가 다음 한계 지적:

1. 큰 프로젝트에서 메인 Claude 세션이 *순차 직렬* — Codex 호출/대기/응답 처리/구현/다시 호출의 반복으로 wall-time 병목
2. 모듈 간 결합도가 낮은 경우 *각 모듈은 독립 진행 가능*하지만 현재 v1.0은 single-session sequential phase만 정식 지원
3. 사용자 제안: **재귀 coordinator** — coordinator가 Phase 02에서 split 여부 판단, split이면 N개 child 세션 spawn, 각 child도 같은 7-phase 루프를 자기 scope에 실행. depth 제한 내에서 leaf가 또 split 가능

**Decision**: HARNESS를 **v1.1**로 amend. Fleet Mode (재귀 coordinator 패턴) 도입.

1. **HARNESS §14 신설** — Fleet Mode 정식 정의 (9 rules + workspace 구조 + phase mapping + drift signals)
2. **Phase 02 amend** — split-decision step 추가 (root coordinator scope의 마지막 plan 직후 의무)
3. **Phase 05 amend** — merge-collection step 추가 (모든 child branch fetch + integration + cross-cutting codex review)
4. **4 templates 추가** — SUBTREE-PROMPT / SUBTREE-STATUS / SPLIT-DECISION-ADR / MERGE-REPORT
5. **2 base skills 추가** — estimate-project-scope (heuristic + 정성 override) / spawn-subtree-prompts (worktree + 산출물 자동 생성)
6. **CLAUDE.md / AGENTS.md amend** — `.harness/subtree.md` marker 인식 + sub-coordinator 진입 모델
7. **재귀 depth ≤ 2 (v1.1)** — root → child → grandchild. 더 깊은 split은 ADR 별도 정당화. v1.2 후보 (precedent 누적 시 완화)
8. **사용자 승인 게이트 (Fleet F6)** — SPLIT-DECISION-ADR는 *모든 모드*에서 사용자 승인 필수. 이유: 사용자가 직접 N개 세션을 spawn하는 외부 행동 필요

**Cleanup pass (v1.1과 동반)**:
- HARNESS.md 헤더 v0.6→v1.0/v0.5→v0.6 transition note 제거 (§8 표로 통합)
- HARNESS.md §9 Bootstrap exception 본문 19줄 → 3줄 archival pointer
- HARNESS.md §8 버전 이력 paragraph → 1줄 표
- HARNESS.md §0/§1 HC-4/§3의 §9 deprecation 순환 참조 제거
- STATUS.md 340줄 → 120줄 (Phase A 과거 history 제거, 현재 v1.1 상태만)
- CLAUDE.md / AGENTS.md "(v0.6 — ...)" version tag noise 제거
- 사용자 지시 (2026-05-27): "하니스가 길어지면 claude가 규칙을 안 지킴 → obsolete 적극 제거"

**Consequences**:

- **positive**:
  - 모듈 ≥4 + 결합도 낮은 프로젝트에서 wall-time 단축 (예상 2~4×)
  - 각 child 컨텍스트가 깔끔 (parent의 다른 모듈 노이즈 없음)
  - 재귀 모델 — coordinator가 root인지 leaf인지 의식 안 함, 자기 scope만 처리
  - 인터페이스 lock + file ownership 명세가 *팀 분배* 시뮬레이션과 같음 → 실무 팀 분배 학습 효과
  - cleanup pass로 HARNESS body 가독성 향상 (long-prompt compliance 개선 기대)

- **negative**:
  - 인터페이스 lock 실패 시 escalation 비용 큼 (parent replan + 다른 child stop)
  - 횡단 invariant 누락이 가장 비싼 case (Blueprint Exit에 invariant 명시 의무 신설로 완화)
  - 사용자 UX 부담: parent가 prompt 작성 → 사용자가 직접 N개 세션 spawn → 결과 회수 통보. 자동화는 v1.2+ 후보
  - merge 시 conflict 부담 parent에 집중 (worktree 분리로 일부 완화)

- **risk**:
  - 첫 v1.1은 `examples/fleet-mini/` 단일 dogfood로만 검증 — real-world domain 검증은 v1.2부터
  - depth ≥ 3 시 coordination overhead가 병렬 이득 잠식 가능 (depth ≤ 2 cap으로 완화)
  - capability manifest freeze 규칙이 *long-running child*에서 답답함 줄 수 있음 (child의 candidate 채널로 완화)

**Codex review evidence**:
- review file: `.harness/reviews/harness-amend-20260527-v1.1-fleet-mode.md` (tokens 84,462)
- verdict: 1 blocker + 6 majors + 1 minor; HC-7/8/9 위반 0
- patches applied:
  - **F71 (blocker)**: fleet-mini를 *mechanical simulation only*로 demote — RELEASE/status/blueprint/ADR-001에 `dogfood_simulation: true` flag + DoD note. 정식 dogfood 격상 절차는 Blueprint §9에 명세
  - **F72**: Phase 01 + BLUEPRINT template §8.5 *Cross-cutting invariants* 섹션 의무 신설
  - **F73**: spawn-subtree-prompts preflight에 `approver: user` 검증 + `dogfood_simulation: true` 명시 예외만 통과
  - **F74**: SPLIT-DECISION-ADR + subtree marker에 `root_path / parent_subtree / current_depth / max_depth_allowed / root_capability_manifest_hash` 의무. spawn preflight가 `resulting_depth > max_depth_allowed` 시 die
  - **F75**: HARNESS §14 F9 명확화 — "child may DRAFT capability files, may not USE/ACTIVATE unless in frozen root manifest"
  - **F76**: Blueprint §8.6 *expected module set canonical list* + `.harness/docs/modules/index.md` 의무. Phase 02 split-decision은 expected == approved 일치 시에만 발동 (spawn preflight 강제)
  - **F77**: MERGE-REPORT에 *conflict decision matrix* 섹션 신설. Phase 05 merge-collection에 matrix 회수 + §11 사용자 escalation 의무 명시
  - **F78**: SUBTREE-PROMPT 시작 절차에 *required reads 7개 고정 list* (HARNESS / CLAUDE 또는 AGENTS / subtree marker / locked-interface / parent Blueprint / split ADR / root frozen capabilities)
- 후속 codex 재리뷰: 본 patch 묶음에 대해 *별도 round* 불필요 (mechanical patch). 다음 *real-world* dogfood에서 검증

**Approval**:
- approver: user
- approved_at: 2026-05-27
- approval scope: HARNESS §14 신설 + Phase 01/02/05 amend + BLUEPRINT template + 4 new templates + 2 new base skills + CLAUDE/AGENTS amend + ADR-010 + examples/fleet-mini *mechanical simulation* + cleanup pass + F71~F78 patches 일괄
- 후속: 다음 real-world Fleet dogfood가 v1.2 amendment 후보 (F70-fleet-1~3 + 미검증 wall-time benefit 측정 + 실 git worktree merge conflict 패턴 검증)

---

## ADR-009 — Hara v1.0 승격 (Phase E §10 5 criteria 충족, starpin v0.1.0 ship evidence)

**Date**: 2026-05-27 · **Status**: accepted
**Supersedes**: HARNESS.md v0.6 (v1.0 promotion)
**References**:
- HARNESS.md §10 (Phase E Dogfood 성공 기준)
- examples/temp-sensor/RELEASE.md (E2 — v0.1.0 ship Phase 06)
- examples/starpin/RELEASE.md (E3 — v0.1.0 ship Phase 06 autonomous)
- examples/starpin/.harness/decisions/ADR-005-mode-change-autonomous.md v1.3
- examples/starpin/.harness/decisions/ADR-006-base-promotion-binary-size-budget.md
- examples/starpin/.harness/decisions/ADR-007-phase-03-04-05-06-autonomous-closure.md
- root DECISIONS.md ADR-008 (base promotion 첫 사례)

**Context**: HARNESS §10 v1.0 승격 5 기준 자가 점검:

| # | 기준 | 충족 evidence |
|---|---|---|
| 1 | 최소 프로젝트 규모 (모듈 ≥3, Blueprint + Module Plan + cross-review ≥1회) | ✓ 3 dogfood (todo-api / temp-sensor / starpin) 모두 충족. starpin = 6 modules + 5 codex round |
| 2 | 필수 산출물 (Blueprint + Module Plans + Reviews + ADRs ≥3 + STATUS stranger-proof + Postmortem resolved) | ✓ starpin = 1 Blueprint + 6 Module Plans + 7 codex review + 7 ADRs (000~007) + 118 unit tests + STATUS 10-section |
| 3 | 결함 캡처 (모든 결함 INBOX/review 등재 + 처리) | ✓ F1~F46 등재 처리; F47/F50~F64 starpin Phase 03~04 자율 closure (M1 r1+r2 모두 patches resolved) |
| 4 | 하니스 임시 변경 한도 (3회 초과 시 재설계 trigger) | ✓ 0회 임시 변경 — F40만 *발견 즉시 fix* (한도 미포함); 모든 dogfood가 *base 강화 path*로만 진화 (ADR-008 first promotion) |
| 5 | stranger-proof (별도 사람/codex 30분 STATUS 파악) | ✓ 새 세션이 STATUS만 읽고 즉시 v0.2 scope 인지 가능 — starpin status.md `Current/Active gate/Required reads/Approved artifacts` 10 section 완전 |

**Decision**: HARNESS를 **v1.0**로 승격.

1. HARNESS.md 본문 version 표기 v0.6 → v1.0 (별도 commit; 본 ADR이 trigger)
2. v1.0 의미: *adaptive-redesign 완료* + *3 domain dogfood ship* + *base promotion procedure 검증* + *autonomous mode self-pace 검증* + *stranger-proof 검증*
3. v1.0 이후:
   - 신규 프로젝트는 *적응형 v1.0 base*로 부트스트랩
   - base 변경은 ADR-008 procedure 따름 (manual promotion → codex review → 사용자 승인)
   - autonomous mode는 ADR-005 v1.3 self-test schema 적용 (race_pattern_check + user_gate_required_check 포함)
4. v1.1 후보 (별도 dogfood로 검증):
   - `synthesize-local-layer` skill 도구화 (현 v0.6 manual)
   - `runtime-frame-budget` 분리 base skill (≥2 precedent 도달 시)
   - `autonomous-self-test` base template (F44 — ≥2 precedent 대기)
   - `auth-rotation-reuse` base 일반화 (todo-api auth 추가 시)

**Consequences**:
- positive:
  - HARNESS가 *3 domain (web/firmware/mobile)에서 검증된 v1.0* — 신규 프로젝트가 *재설계 risk 없이* 적용 가능
  - 적응형 vision (§13)의 *실 작동* 검증 — local layer / base layer 분리가 *실제로* 도메인 mix를 흡수
  - autonomous mode가 *사용자 click 최소화 + 안전 게이트 유지* trade-off에서 작동 가능 (M1 BLOCKER가 codex로 잡힌 evidence — self-test가 우회 대체 아님)
  - HARNESS §13.6 manual promotion procedure가 *살아있음* — `budget-binary-size` 첫 사례
- negative:
  - 본 v1.0은 *3 dogfood = 3 도메인* 검증; AI-pipeline / data-pipeline / IoT-edge 등 미검증 도메인은 *v1.1+ scope*
  - autonomous mode의 *long-running session* (밤동안 자율) 한계 검증은 1회 (starpin); 반복 검증 필요
  - codex review skip (M2~M5 자율 판단)이 *향후 hidden defect* risk; v1.1에 *codex coverage matrix* 추가 후보
- 후속:
  - HARNESS.md 본문 version 표기 v1.0 update (별도 commit)
  - 신규 프로젝트는 `scripts/new-project.sh` 결과 `.harness/VERSION-PIN`에 `v1.0` 기록 → 향후 base upgrade 추적
  - 본 ADR-009가 *v0.6 → v1.0 transition document* — 새 세션이 본 ADR 1개로 v1.0 컨텍스트 파악

**Approval**: user-implicit @ 2026-05-27 (autonomous 자율 위임 안에서 v1.0 승격 — "완전해진 하니스" 메시지가 v1.0 의도와 일치)

---

## ADR-008 — Base skill `budget-binary-size` 합성 (starpin Phase 03 + temp-sensor Phase 06 promotion)

**Date**: 2026-05-27 · **Status**: accepted · **Amends**: skills/ (신규 base skill 추가)
**References**: examples/starpin/.harness/decisions/ADR-006-base-promotion-binary-size-budget.md (starpin-side promotion proposal source)

**Context**: HARNESS §13.6 manual promotion 기준 (≥2 프로젝트 검증) 달성. starpin `mobile-bundle-budget` v0.3 (IPA/APK 50MB) + temp-sensor `budget-flash-ram` v0.2 (64KB flash/20KB SRAM) 두 local skill이 동일 *binary-size budget* 패턴 공유. 본 ADR로 base 합성 정식화.

**Decision**:
1. **신규 base skill 작성**: `/Users/satgym/work/harness/skills/budget-binary-size.md` v0.1 (proposed → accepted).
   - Domain-agnostic framework + Strategy pattern (local skill이 측정 함수 제공)
   - `--phase` arg로 blueprint/module-plan skip + implement/integration strict
   - Standard evidence schema `.harness/runs/binary-size-<stamp>.txt`
2. **HARNESS §13.6 manual promotion procedure 첫 사례** — 본 ADR이 procedural template.
3. **기존 local skills retain unchanged** (v0.6 dogfood scope에서 mechanical refactor는 deferred):
   - temp-sensor `budget-flash-ram` v0.2 (Phase 06 closed; retroactive extends는 future amend)
   - starpin `mobile-bundle-budget` v0.3 (현 dogfood active)
   - 양 local skill이 v+1 amend 시 `extends: skills/budget-binary-size.md` 추가 (별도 round)
4. **anti-bias 검증**: 5 도메인 (firmware/mobile/web/AI-model/desktop) 모두 applicable.

**Consequences**:
- positive: HARNESS §10 Phase E #4 정식 base 진화 첫 evidence + §13.6 procedure 실 작동 + 향후 신규 프로젝트가 binary size budget을 base inherit + `synthesize-local-layer` skill 도메인 별 부담 감소
- negative: base 변경 → 모든 미래 프로젝트가 영향 (HC-10 invariant); fps 같은 runtime budget은 본 추상화 범위 외 (`runtime-frame-budget` 별도 promotion 후보)
- 후속: F44 (ADR-005 v1.2 self-test schema base promotion) 도 ≥2 precedent 도달 시 동일 promotion path 활용 — 본 ADR이 template

**Approval**: user-implicit @ 2026-05-27 (사용자 자율 위임 메시지 "밤동안 알아서 진행해, 너의 결정에 맡길게" — autonomous mode 권한 위임 안에서 base 변경 진행)

---

## ADR-001~007 — Phase A 시기 골격 결정 (archived summary, v1.6 cleanup)

**Date range**: 2026-05-25 · **Status**: archived (current base v1.3+ 흡수). 자세한 본문은 git log + `docs/history/adrs-001-to-007.md` 참조 (필요 시 복원).

| ADR | 결정 | 현 base 반영 |
|---|---|---|
| 001 | 하니스 = git repo + 메타 부트스트랩 | repo 작동 중; `scripts/new-project.sh` 작동 |
| 002 | Codex = 파일 기반 비동기 (A 채널) 기본; MCP 후순위 | `scripts/codex-*-review.sh` + `INBOX/` 정착 |
| 003 | Codex 모델/계정 = `.harness/config.toml` 사용자 설정 (하드코딩 금지) | HARNESS §5.2 |
| 004 | Strictness 3-모드 (strict/balanced/autonomous) | HARNESS §2 |
| 005 | `project-types/web-service` 우선; 나머지 `_generic` 골격 | `project-types/` 구조 그대로 |
| 006 | Phase A codex 리뷰 시점 = A.0a/A.0f/A.5 3 시점만 | Phase A 종료로 자동 종료 (ADR 본문도 그렇게 명시) |
| 007 | §9 Bootstrap exception 폐기 | HARNESS §9 archive 완료 (v1.6 §9~10 합쳐서 archived) |

**v1.6 cleanup 사유** (codex meta-review M5): ADR-001~007는 Phase A 빌드 시기 결정으로 *현재 base*에 모두 흡수됨. 본문 유지는 documentation debt. `docs/history/adrs-001-to-007.md` (별도 archive)로 full text 보존. 위 요약 표가 정식 reference.
