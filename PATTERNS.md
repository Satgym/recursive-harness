# PATTERNS.md — Hara reference patterns

> **Optional read**. HARNESS.md is the must-read; this file is for recipes,
> postmortem templates, and historical context — consult when stuck.

---

## §front-matter — Artifact front-matter standard

Every ADR / REVIEW / Module Plan / MERGE-REPORT starts with a YAML front-matter block. Common shape:

```yaml
---
artifact: adr | review | module_plan | merge_report | locked_interface | split_decision
version: v1 | v2 | ...
date: YYYY-MM-DD
author: claude | codex
status: open | resolved | deferred | disputed
# optional, artifact-specific
severity: blocker | major | minor | nit | info
target: <subject>
approval:
  approver: user
  approved_at: ISO-8601
  mode: strict | balanced | autonomous
references:
  - <file:line or doc§>
---
```

### Artifact-specific status enums

| artifact | allowed status |
|---|---|
| adr | open / accepted / superseded / amended / rejected |
| review (per finding) | open / resolved / deferred / disputed |
| module_plan | draft / accepted / superseded |
| merge_report | open / merged / rolled-back |
| locked_interface | draft / locked / amended |
| split_decision | open / accepted / superseded |

### Required fields per artifact

- **ADR**: `supersedes`, `superseded_by`, `amends`, `approval.approver`, `approval.approved_at`
- **REVIEW**: `codex_meta` (model, reasoning_effort, base_ref|commit|uncommitted, prompt_source, invoked_at, tokens_used). codex wrapper 자동 채움.
- **MERGE-REPORT**: `child_name`, `parent_subtree`, `locked_interface_hash`, `evidence_confidence`, `parent_authored` (if applicable)

---

## §drift — Drift detection + correction

### Signals
- Blueprint와 코드 충돌 (모듈 경계, 타입, invariant)
- STATUS가 24h+ stale + 직전 phase Exit 미달
- Codex finding `severity: blocker | major` 미반영
- 같은 finding 2+ 라운드 재발 (codex 회의 권고)
- ADR 미연결 결정 (의사결정의 evidence chain 끊김)
- HC-7/8/9 위반 1회 = 즉시 Postmortem trigger

### 절차
1. drift 발견 시 작업 멈춤
2. STATUS에 "drift detected: <설명>" 명시
3. 영향도 평가 (rollback / patch / re-Blueprint 중 선택)
4. 필요 시 ADR 발행 (drift 원인 + 결정)
5. codex 리뷰 후 진행

### Postmortem triggers
- HC-7/8/9 위반 1회 → 즉시
- 같은 finding 2+ 라운드 재발 → 다음 phase 전 의무
- Blueprint 우회 후 ship → 다음 ship 전 의무

### Postmortem 양식
`postmortems/YYYY-MM-DD-<slug>.md`:

```markdown
---
date: YYYY-MM-DD
trigger: HC-X | repeated-finding | blueprint-bypass
author: claude | codex | user
---

# Postmortem — <slug>

## Timeline
- <ISO-8601>: 무슨 일이 일어났나

## Root cause
<왜 발생했나>

## Detection
<어떻게 발견했나, 더 빨리 잡으려면>

## Fix
<적용한 패치 + commit SHA>

## Prevention
<harness 변경 후보 — ADR or hook 추가 후보>
```

---

## §adaptive-layer — Project-local skills + roles + capabilities

### Manifest 양식 (`.harness/capabilities.md`)

```markdown
# Capabilities (active set for this project)

## Skills (extension — runtime-enforceable checklists)
| skill | version | active | notes |
|---|---|---|---|
| sky-coords-fixture | v0.3 | yes | M3 fixture 검증 |
| external-catalog-rate-limit | v0.4 | yes | Gaia/SIMBAD ≥1s |

## Roles (advisory — review personas)
| role | active | invoke when |
|---|---|---|
| astronomy-data-reviewer | yes | catalog ingest / sky compute 변경 시 |
```

### Loading semantics
- 세션 시작 시 `.harness/capabilities.md` Active 섹션을 working set에 포함
- 자동 discovery 금지 (`.harness/skills/` 디렉토리 스캔 X). 명시 의무
- HC-10에 따라 local은 base를 약화 못함

### Promotion (local → base)
local skill이 *3+ 프로젝트에서 같은 형태로 활용*되거나 base 하니스의 gap을 메우면 promotion 후보. 절차:
1. base에 동등 skill 작성
2. 모든 활용 프로젝트에서 active set 갱신
3. local 파일 deprecate (참조용 stub만 유지)
4. ADR 발행

### Drift 신호
- `.harness/capabilities.md` Active 섹션과 실제 사용된 skill 불일치
- local skill이 base HC-1~9를 약화하는 시도 (HC-10 위반)
- 같은 skill을 *프로젝트 코드*에 hard-coded (`.harness/skills/`에서 promote 안 함)

---

## §codex-config — Codex CLI 모델 설정

`.harness/config.toml`:

```toml
[models]
review = "gpt-5.5"        # default; can omit (codex default)
exec   = "gpt-5.5"

[reasoning]
review = "high"           # high | medium | low (cost vs quality)
exec   = "medium"
```

wrapper가 위 config을 자동 읽어 `codex review/exec -c model_reasoning_effort=$EFFORT` 형태로 전달. token 한도 등 fine-tune은 codex CLI native config (`~/.codex/config.toml`)로.

### Cost guardrails
- review 1회당 expected tokens 추정 (prompt + file sizes)
- 실제는 `_codex_postprocess.py`가 ledger에 기록
- 누적 burst (e.g., 1주 100만 토큰 초과)는 STATUS에 명시 + 다음 round 축소 권고

---

## §dispute — Finding 분쟁 해결

Codex finding에 Claude가 `disputed`로 응답하는 경우:

1. Claude는 dispute 사유를 review 파일에 *evidence + reasoning* 명시 (file:line + rationale)
2. Codex가 r2에서 dispute 재검토 (4 결과: agreed-original-finding-stands / agreed-resolved / refined-finding / new-evidence-changes-position)
3. dispute 무한 핑퐁 방지: 같은 dispute가 r3까지 가면 사용자 결정 필수

### phase 차단 효과
- `disputed` status인 finding이 *severity: blocker* **또는 major*인 경우: phase 진행 차단
- *minor/nit*인 경우: 진행 가능하나 ADR로 기록 + 다음 phase 시작 시 사용자 확인 의무

---

## §subagent-recovery — Background subagent partial-completion / 529 / socket close

Phase 03 background subagent 가 작업 중 실패하는 4 가지 모드 + 대응:

### Mode 1: API 529 Overloaded (Anthropic API capacity)
- **신호**: subagent completion notification result = `API Error: 529 Overloaded`, `total_tokens=0`, `tool_uses=0`
- **현상**: subagent 가 한 번도 tool call 못 함. 결과물 0.
- **대응**:
  1. 재시도 1회 (transient overload)
  2. 재시도도 fail 시 coordinator 가 직접 작성 (scope trimmed 버전)
  3. *작업 시각* 고려 — Anthropic 의 peak hour (UTC 14-22) 회피 가능 시 새벽으로 미루기
- **precedent**: starpin v0.16 sensor scaffold — 2회 연속 529 → coordinator 직접 6 file 작성 (ADR-028)

### Mode 2: Socket close mid-work (network/runtime drop)
- **신호**: completion notification result = `socket connection was closed unexpectedly`, `total_tokens > 0`, `tool_uses > 0`
- **현상**: subagent 가 partial 결과물 생성. 마지막 deliverable 가 incomplete.
- **대응**:
  1. *어디까지 완료됐는지* 자동 진단:
     - `find <project> -newer <reference-mtime-file>` 로 modified files 목록
     - `npm run build` / `npm test` 로 syntactic / structural integrity check
     - prompt 의 deliverable list 와 actual file list cross-check
  2. *남은 deliverable* 만 coordinator 직접 작성 (full rerun 금지 — duplicate work)
  3. impl review doc 은 coordinator 가 직접 작성 (subagent 가 보통 안 함)
- **precedent**: starpin v0.17 wholesale ship — 19 min / 79 tool_uses 후 socket close. Coordinator 가 TS error fix + CSS 보강 + Maestro flow + impl review 로 마무리 (ADR-029)

### Mode 3: Spec-incomplete (subagent did work but missed key responsibility)
- **신호**: build/test 통과 but visual / functional verification 시 명세 누락 발견
- **흔한 누락 카테고리** (3-ship dogfood 기반):
  - **CSS responsibility**: subagent 가 lib code 만 작성, style.css 누락 → 시각적 검증 0
  - **Test fixture / sample data**: 새 backend route 추가했지만 fixture seed 없어서 e2e 가 empty path 만 검증
  - **Maestro flow yaml**: code 만 작성, 검증 path 누락
- **대응**: coordinator 가 *prompt 강화* (다음 round 부터):
  - "implementation = code + styling + tests + fixture data — 4가지 모두 책임"
  - deliverable list 에 각 카테고리 explicit hard-coded

### Mode 4: Server-side rate limit (Anthropic throttle mid-work) — v2.9 add
- **신호**: completion notification result = `API Error: Server is temporarily
  limiting requests (not your usage limit) · Rate limited` (or similar
  classifier-unavailable + rate-limit combination), `total_tokens=0`,
  `tool_uses>0` (so some work happened before throttle)
- **현상**: Mode 2 (socket close) 와 유사하지만 transient — 단지 작업 throughput
  throttle. partial 결과물 디스크에 commit 됨.
- **대응**:
  1. Mode 2 recovery 와 동일 — diagnose modified files + integrity check
  2. coordinator 가 남은 deliverable 직접 작성 (재시도 시 같은 rate limit 재발생
     위험 + 30% → 70% 정도면 직접이 더 빠름)
  3. impl review 에 "subagent N% partial → coordinator (100-N)% direct"
     명시 (audit trail)
- **precedent**: starpin v0.25 ISS tracking — subagent 가 4 file (iss/* +
  iss-routes.ts) 까지 작성 후 rate-limit. coordinator 가 server wiring +
  highlights extension + frontend + 4 jest test + impl review 마무리 (ADR-047).

### 회복 절차 (recovery)

```bash
# 1. 진단 — subagent 가 손댄 file 목록
find <project>/backend/public <project>/backend/src -name '*.ts' -newer <reference-mtime-file> 2>/dev/null
find <project>/tests -newer <reference-mtime-file> 2>/dev/null

# 2. 구조적 integrity
npm --prefix backend run build 2>&1 | grep error
npm --prefix backend test 2>&1 | tail -5

# 3. 명세 vs 실 파일 diff
cat <subagent-prompt-deliverable-list> | grep -oE '`[^`]+`'  # 약속한 파일 list
ls <expected-files>                                            # 실제 파일 확인

# 4. coordinator 가 남은 deliverable 만 작성 — full rerun 금지
```

### prevention

- Subagent prompt 의 "Deliverables" 섹션이 *모듈 type 별 분리* (code / styling / test / fixture / impl-review). 각 카테고리에서 누락 시 *partial* 상태로 명시.
- High-risk slot (Anthropic API peak hour: UTC 14-22) 회피 — 새벽 동작 권장.
- Subagent 1회 launch 의 scope 가 *너무 클 때* socket close 위험 ↑ — chunking (PATTERNS §scope-chunking) 참조.

---

## §deliverable-categories — Subagent prompt category template (v2.3.2)

4-ship dogfood (starpin v0.14~v0.17) 동안 background subagent 가 *lib code 는 잘 쓰지만 부수 deliverable 을 누락* 하는 패턴이 반복. 발견된 누락 카테고리:

| 카테고리 | 누락 발생 ship | 결과 |
|---|---|---|
| `style.css` 신규 component CSS | v0.17.0 (filter), v0.17.3 (sky-detail-page) | 시각 검증 0 — 코드는 작동, UI 안 보임 |
| `tests/mobile/flows/*.yaml` Maestro flow | v0.16, v0.17.0 | coordinator 가 직접 작성 |
| `impl review` markdown (subagent 의 작업 보고) | 거의 매번 | coordinator 가 후처리 |
| Fixture / seed data | v0.17 backend route 새로 추가 시 | empty path 만 e2e 검증 |
| ARIA labels for Maestro compatibility | v0.17.2 (profile-stars button) | tap 실패 |

### Subagent prompt template — Deliverables 섹션 표준

Subagent 호출 prompt 의 "Deliverables" 섹션은 *반드시* 다음 5 카테고리로 분리해서 explicit list:

```
## Deliverables (BLOCKING — implementation = code + styling + tests + fixture + impl-review)

### 1. Code (NEW + MODIFY .ts files)
- <path>: <description>
- ...

### 2. Styling (`style.css` additions)
For EACH new component class in §1, add positioning + responsive CSS.
Missing CSS = invisible UI even if code works. Examples to mirror: .sky-filter-*,
.sky-detail-page-*, .profile-stars-* (all in style.css). Z-index: modal 1000,
overlay 1010 (above modal), banner 950, FAB 50.

### 3. Tests (`tests/` Maestro yaml or unit ts)
- `tests/mobile/flows/<slug>.yaml`: 8+ takeScreenshot, 12+ steps
- For new backend route: minimal jest test in `backend/tests/`

### 4. Fixture / seed (when adding backend route OR new UI requiring sample data)
- backend/fixtures/<slug>.ndjson or backend/migrations/seed.sql
- Or document explicit "no fixture needed because <reason>"

### 5. impl review (`.harness/reviews/04-<date>-<slug>-impl.md`)
Mandatory short doc summarizing files / decisions / known limitations / HC trigger count.
```

이 template 을 subagent prompt 에 hard-code 하면 누락 위험 ↓. coordinator 가 prompt 작성 시 5 카테고리 모두 채우는 *self-checklist* (hook 강제 아님 — v2.3.2 시점 discipline). 5 카테고리 중 비어 있는 카테고리는 *명시적으로 "N/A — <reason>"* 로 표기.

> v2.4 enforced: subagent prompt 작성 후 `bash scripts/check-subagent-prompt.sh <prompt.md>` 로 5 heading 자가 lint. `--strict` 추가하면 impl-review path 명시 의무. exit 1 = 누락 있음.
>
> v2.4.1: `--mode=auto|impl|review` flag 추가. `auto` (default) = filename heuristic (`*-impl.md` or `*-impl-r<N>.md` → impl mode, else review mode). 30+ legacy review prompts 가 false negative 안 나도록 graceful skip.
>
> **Filename convention** (v2.4.1):
> - 실제 dispatch 되는 implementer prompts: `<phase>-<date>-<slug>-impl.md` 또는 `<phase>-<date>-<slug>-impl-r<N>.md`
> - codex/peer review prompts: 그 외 어떤 이름이든 OK (예: `harness-v24-r1.md`, `04-cross-review-*.md`) → auto detect 가 review mode
>
> **Inline `Agent()` prompts**: lint 가 파일 경로만 받으므로, inline string prompt 도 dispatch 직전 `.harness/prompts/<slug>-impl.md` 로 먼저 persist 후 wrapper 실행. stdin / inline lint + pre-Agent auto-hook 은 v2.4.2+ carry.

### ARIA label imperative for Maestro (v2.4.2 enforced)

Capacitor WKWebView 의 accessibility tree 가 nested `<span>` 내 textContent 를 button name 으로 indexing 안 함. button/input/clickable 요소에 *명시적 aria-label* 추가가 Maestro `tapOn: text:` 매칭의 prerequisite.

**precedent (dogfood)**:
- v0.17.2 profile-stars button (V-CX-TEL-01 part)
- v0.19 friends-modal search input (post-hoc patch + Maestro rerun)

**v2.4.2 enforcement**: `bash scripts/check-subagent-prompt.sh --strict` 가 prompt body 에 `aria-label` 또는 `aria label` 단어 존재 여부 grep. 누락 시 exit 1 — coordinator 가 prompt 작성 시 ARIA imperative 명시 의무.

**recommended prompt snippet** (subagent dispatch 시 copy-paste):

```markdown
## ARIA imperative (PATTERNS §deliverable-categories)

ALL interactive `<input>`, `<button>`, clickable element MUST have explicit
`aria-label` attribute. Capacitor WKWebView accessibility tree 가 nested
`<span>` textContent 를 button name 으로 indexing 안 함 → Maestro tap
실패. Korean label OK (e.g. `aria-label="닉네임으로 검색"`).
```

### precedent
- v0.16 sensor scaffold (subagent 529) — coordinator 가 직접 6 file 작성 fallback
- v0.17.0 wholesale (subagent socket close 80%) — CSS + Maestro flow 누락 → coordinator 보강
- v0.17.3 detail-page (subagent v0.17.0 잔재) — CSS 완전 누락 → 시각 검증 실패 → coordinator race fix + CSS 추가
- v0.20 today-widget (Hara v2.5 carry): subagent 가 `mountTodayWidget(host)` 을
  fetchNews *직전* 에 mount → 후속 `while(host.firstChild) removeChild` 가 widget
  제거 → "오늘의 하늘" 사라짐. coordinator 가 mount 위치 while-loop *뒤* 로 이동.
  → **DOM mutation order imperative** (아래 §dom-mutation-order)

---

## §dom-mutation-order — Subagent DOM mount 순서 imperative (v2.5)

starpin v0.20 dogfood lesson: subagent 가 *컨테이너 cleanup* (`while removeChild`)
와 *child mount* 순서 헷갈리면 mount 한 element 가 다음 step 에 지워짐.

### anti-pattern

```ts
const containerEl = document.createElement('section');
host.appendChild(containerEl);
void mountChildWidget(containerEl);   // ← appends to container

// loading state
const loading = document.createElement('p');
containerEl.appendChild(loading);

const data = await fetchData();
while (containerEl.firstChild) containerEl.removeChild(containerEl.firstChild);
// ↑ removes BOTH loading AND mountChildWidget's output. widget gone.
```

### correct pattern

```ts
const containerEl = document.createElement('section');
host.appendChild(containerEl);

const loading = document.createElement('p');
containerEl.appendChild(loading);

const data = await fetchData();
while (containerEl.firstChild) containerEl.removeChild(containerEl.firstChild);

// Mount AFTER clear — survives the cleanup
void mountChildWidget(containerEl);

// Then render data
containerEl.appendChild(makeHero(data));
```

### subagent prompt imperative

Subagent prompts that touch existing files with `while (host.firstChild) removeChild` cleanup blocks MUST include:

> ⚠️ DOM mutation order: if mounting child widgets into a container that has
> a `while (firstChild) removeChild` clear step (loading → data swap), mount
> child AFTER the clear, not before. Pre-clear mounted children get destroyed.

v2.6 부터 `scripts/check-subagent-prompt.sh --strict` 가 enforce:
prompt 가 `public/lib/` 또는 DOM API (`removeChild` / `firstChild` / `appendChild` /
`innerHTML`) 를 언급하면 imperative 키워드 (`DOM mutation` / `mutation order` /
`dom-mutation-order` / `mount AFTER` / `mount after clear` / `clear before mount` /
`after cleanup`) 중 최소 1개 등장 의무. 누락 시 exit 1.

**Trigger 가 fire 안 하는 case**: prompt 가 frontend lib path *없이* 그리고
DOM API *없이* 작성된 경우 (예: 순수 backend impl, schema migration, ADR draft).
*Fire 가능 한* false-positive case: `backend/public/lib/` 처럼 frontend path 가
들어간 경우 + pure frontend helper 가 mutation 없이 helper 만 export 하는 경우.
두 case 모두 prompt 에 짧은 imperative 한 줄 추가로 통과 → cost ≤ 30s.
v2.6.1 carry — API set 확장 (`replaceChildren` / `insertBefore` / `replaceWith`
/ `textContent = ''` 등) + trigger / imperative regex 정밀화.

---

## §smoke-setup — Mobile smoke test environment hygiene (v2.5)

starpin v0.20 dogfood: iOS sim 에서 textarea 입력 시 Siri 받아쓰기 활성화 prompt 가 나타나면 *다음 Maestro run 까지 prompt 가 system level 로 남아* "starpin" assertion FAIL. workaround: `xcrun simctl shutdown all` (모든 booted sim — multi-sim leak 방지) + 다음 Maestro run 의 boot 단계 가 fresh sim 띄움.

### root causes

1. **iOS system dialogs** (Siri, location, push notification, share sheet) 가 WebView accessibility tree 를 가림 → Maestro 가 underlying 앱 elements 못 찾음
2. **Stale WebView state** — 이전 run 의 hash route / scroll position / focused input
3. **Capacitor session token** — backend restart 시 redis 비어 있으면 client token 401 → app-shell redirect /login.html
4. **Maestro `clearState`** — iOS 에서 app data 폴더 reinstall 수행 (localStorage 포함 reset) 하지만 simulator-level system overlay (Siri dictation, share sheet, notification permission) dismiss 는 *보장 안 함* (Maestro 공식 docs)

### v2.5 mitigation

`<project>/scripts/run-mobile-smoke.sh` (예: starpin 의 `examples/starpin/scripts/run-mobile-smoke.sh`) 가 `SMOKE_FRESH_SIM=1` env var 지원 — 모든 booted iOS sim 을 shutdown 후 boot 재시작:

```bash
# v2.5 — at top of script (before boot detection)
if [[ "${SMOKE_FRESH_SIM:-0}" == "1" && "$PLATFORM" == "ios" ]]; then
  xcrun simctl shutdown all 2>/dev/null || true
  sleep 2
fi
```

호출: `SMOKE_FRESH_SIM=1 bash examples/<proj>/scripts/run-mobile-smoke.sh ios <slug>`


### Maestro flow level (immediate)

iOS Siri / dictation prompt 가 자주 발생하면 flow 시작에 `- clearState` + system alert handler:

```yaml
- launchApp
# Defensive: dismiss any system alert (Siri / push / share)
- runFlow:
    when:
      visible: ".*받아쓰기.*"
    commands:
      - tapOn: "지금 안 함"
```

### precedent

- v0.20 today-search-smoke: Siri 받아쓰기 prompt → "starpin" 안 보임 → sim restart 로 회복

### v2.7 — CAPACITOR_SERVER_URL trap (silent stale-asset failure)

starpin v0.22 dogfood lesson: Capacitor 의 `server.url` 설정 (또는 `CAPACITOR_SERVER_URL` env / `.env.local`) 이 켜져 있으면, iOS WKWebView 가 그 *remote* 에서 HTML/JS 를 로드하지 *local bundle 사용 안 함*. 만약 remote (e.g. ngrok-tunneled dev server) 가 stale code 를 serve 하면 Maestro 는 stale code 를 검증하면서 PASS/FAIL — **silent failure mode**:

- 모든 build / `cap sync` / install / 시뮬 erase 가 정상 보임
- 단 runtime accessibility tree 만 mismatch 노출
- 진단 어려움: starpin v0.22 에서 9 Maestro reruns + 시뮬 erase + uninstall/reinstall 후 root cause 발견

`<project>/scripts/run-mobile-smoke.sh` 가 boot 직후 detect + 큰 warning 출력. 핵심 두 함수:

```bash
# HC-7 redaction (r2 codex blocker fix — robust step-wise vs single regex):
#   1. strip fragment / query
#   2. require scheme://; else opaque marker (no leak)
#   3. authority = chars after :// up to first /
#   4. strip userinfo (user:pass@) from authority
#   5. emit scheme://host (or scheme://<host-redacted> if authority empty)
redact_url_for_log() {
  local url="$1"
  url="${url%%#*}"
  url="${url%%\?*}"
  if [[ ! "$url" =~ ^([a-zA-Z][a-zA-Z0-9+.-]*)://(.*)$ ]]; then
    echo "<non-http-url-redacted>"; return
  fi
  local scheme="${BASH_REMATCH[1]}"
  local rest="${BASH_REMATCH[2]}"
  local authority="${rest%%/*}"
  local host_port="${authority##*@}"
  # r3+r4 codex blockers: strict positive allowlist for host chars only —
  # alphanum + `.-:_[]` (FQDN + port + IPv6 brackets). ANY other char
  # (control/whitespace/backslash/`?`/`&`/`;` etc.) → fully redact.
  if [[ -z "$host_port" || ! "$host_port" =~ ^[]A-Za-z0-9.:_[-]+$ ]]; then
    echo "${scheme}://<host-redacted>"
  else
    echo "${scheme}://${host_port}"
  fi
}

detect_capacitor_server_url() {
  # ${VAR+x} → "x" iff VAR is set (even empty); "" if unset.
  # 이 구분이 없으면 force-local fix `CAPACITOR_SERVER_URL= bash $0 ...` 가
  # 빈 string 으로 fall-through 해서 .env.local 을 다시 읽고 warning 재발생.
  local env_was_set=0; local from_env=""
  if [[ -n "${CAPACITOR_SERVER_URL+x}" ]]; then
    env_was_set=1; from_env="${CAPACITOR_SERVER_URL}"
  fi
  local from_file=""
  if [[ $env_was_set -eq 0 ]]; then
    # v2.9 dotenv extension — check .env.local first (local overrides),
    # then .env, then .env.production. Break on first FILE that defines
    # the key (even with empty value) so we match dotenv's
    # "first set wins, even if set-to-empty" rule. The final warning
    # guard `[[ -n "$effective" ]]` filters empty values.
    local f
    for f in "$ROOT/.env.local" "$ROOT/.env" "$ROOT/.env.production"; do
      [[ -f "$f" ]] || continue
      if grep -qE '^CAPACITOR_SERVER_URL=' "$f" 2>/dev/null; then
        from_file=$(grep -E '^CAPACITOR_SERVER_URL=' "$f" 2>/dev/null \
          | head -1 | sed -E 's/^CAPACITOR_SERVER_URL=//' \
          | sed -E 's/^"(.*)"$/\1/' | sed -E "s/^'(.*)'\$/\1/")
        break
      fi
    done
  fi
  local effective="${from_env:-$from_file}"
  if [[ -n "$effective" ]]; then
    local redacted; redacted=$(redact_url_for_log "$effective")
    echo "[run-mobile-smoke] WARN: CAPACITOR_SERVER_URL set ($redacted)" >&2
    echo "  → iOS WKWebView will load from THIS remote, not local bundle." >&2
    echo "  → Fix (a) restart backend dev server; (b) 'CAPACITOR_SERVER_URL= bash $0 ...'" >&2
  fi
}
detect_capacitor_server_url
```

설계 결정 (v2.7 r1+r2 codex 반영):
- `${VAR+x}` 로 set/unset 구분 — empty 가 force-local intent 인 점 보존 (r1 major)
- Robust step-wise URL redaction with strict positive allowlist — single regex 는 no-scheme / file:// / `@`-in-path / IPv6 / control-char / backslash 등 누락. **15-case self-test PASS** (r2 + r3 + r4 blocker 모두 close)
- 외부 remote freshness probe 안 함 — cross-origin probe / auth header / cache-busting hash 차이로 false alarm + permission classifier 마찰
- v2.9 dotenv extension: `.env.local` → `.env` → `.env.production` 순으로 첫 매치 사용 (dotenv 컨벤션 local-overrides)

단순 warning 으로 future operator (Claude / human) 가 silent failure 를 30 초 안에 인지 가능.

---

## §modal-overlay-race — DOM cleanup vs navigation 분리 (v2.3.2)

v0.17.3 V-CX-TEL-01 root cause 분석에서 발견한 패턴. modal/overlay 의 `close()` 함수가 *DOM cleanup* 과 *route navigation* 둘 다 담당하면, *re-render path* 가 close 호출 시 의도치 않은 navigation 발생.

### 안티 패턴

```ts
function closeModal() {
  if (activeOverlay) activeOverlay.remove();
  window.location.hash = '#default';  // ← navigation
}

function renderModal(model) {
  closeModal();  // ← intent: remove old DOM before re-render
                 //   side-effect: navigation fires hashchange → app-shell renders default
                 //   → new overlay rendered under default route
  const overlay = ...;
  host.appendChild(overlay);
}
```

### 올바른 패턴

```ts
function _removeOverlayDom() {       // DOM-only — caller-internal
  if (activeOverlay) activeOverlay.remove();
}

function closeModal() {              // public — DOM + navigation
  _removeOverlayDom();
  window.location.hash = '#default';
}

function renderModal(model) {
  _removeOverlayDom();               // ✓ no nav side-effect
  const overlay = ...;
  host.appendChild(overlay);
}
```

### 감지

- 증상: modal/overlay 가 render 되었어야 할 시점에 *default route* (newsletter / index) 가 visible
- 디버깅: console log 에서 hashchange 가 *연속 2회* 발생 (intended + side-effect)
- e2e: Maestro screenshot 가 modal 대신 default tab 보여줌

### 적용 대상

- 어떤 component 라도 close handler 가 hash/state navigation 트리거 시 같은 분리 적용
- starpin: sky-detail-page (v0.17.3 fix), news-modal (이미 hash 안 건드림 — OK), profile-stars (이미 분리 — OK)

---

## §scope-chunking — Ship 단위 chunking discipline (v2.3.1)

사용자 directive 2026-05-28: "ship 단위 너무 잘게 쪼개지 말기. base 하니스의 분할 원칙은 *필요할 때만*". feedback memory: [[feedback-ship-chunking]].

### 분할이 필요한 신호 (분할 OK)

- 단일 ship 의 추정 작업량 > 한 세션 context 한계
- cross-module 정합성 충돌 위험 큼 (예: backend schema 변경 + frontend major rework 동시)
- 한 모듈만 자율 진행, 다른 모듈은 사용자 선호 결정 필요

### 분할이 *과한* 신호 (잘게 쪼개진 신호)

- ship 마다 review cycle 의 *cost overhead* > impl cost (예: 1 round 2-3 PNG 검증 + codex 호출 2회)
- 다음 ship 이 현 ship 의 *얇은 후속* (예: scaffold + 진짜 기능 분리)
- *layered dependency* 가 명확한데도 분할 (예: sensor → filter → highlight 가 서로 build on each other)

### 자가 진단 기준 (chunking 적정성)

| 지표 | 잘게 쪼개진 신호 | 적정 |
|---|---|---|
| HC-12 Maestro step | ≤ 5 | 8-15 |
| HC-13 PNG | ≤ 3 | 6-12 |
| 새 lib / module 파일 | 0-2 | 5-10 |
| 새 invariant | 0-2 | 3-5 |
| review round (반복) | 2-3 | 1 |
| 신규 backend route / schema | 0 | 1-2 |

`스카이 진단` — 위 6 지표 중 4+ 가 *잘게 쪼개진 신호* 영역이면 다음 ship 합치는 후보.

### precedent

- v0.13 ~ v0.16 starpin 의 4 ship 분할이 *과한 분할* 로 판명 → v0.17 wholesale ship 으로 회수 (ADR-029).
- chunking memory 적용 후 1 ship 의 PNG/step 가 약 2 배 증가 + review round 가 3 → 1 로 감소.

---

## §history — Version archive (v1.2~v1.7)

| 버전 | 핵심 변경 | ADR / finding |
|---|---|---|
| v1.7 | gen_eslint_lock Layer 3 named-import allowlist | F126 inline |
| v1.6 | meta-review cleanup (12 finding, M3 adaptive learning, M9 machine-readable lock) | ADR-008+ |
| v1.5 | inflight codex patches | F120/F121/F122/F124 |
| v1.3 | AST-level lock (ESLint no-restricted-imports) + Strategy helper scripts | ADR-012 |
| v1.2 | Fleet enforcement amend (lock+invariant grep gate, inter-child timing, scope gates) | ADR-011 |

세션 핸드오프 규약 (read 순서 / 영속화): [STATUS.md "Required reads"](STATUS.md), [CLAUDE.md](CLAUDE.md) 참조.
