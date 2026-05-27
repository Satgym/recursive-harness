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

## §history — Version archive (v1.2~v1.7)

| 버전 | 핵심 변경 | ADR / finding |
|---|---|---|
| v1.7 | gen_eslint_lock Layer 3 named-import allowlist | F126 inline |
| v1.6 | meta-review cleanup (12 finding, M3 adaptive learning, M9 machine-readable lock) | ADR-008+ |
| v1.5 | inflight codex patches | F120/F121/F122/F124 |
| v1.3 | AST-level lock (ESLint no-restricted-imports) + Strategy helper scripts | ADR-012 |
| v1.2 | Fleet enforcement amend (lock+invariant grep gate, inter-child timing, scope gates) | ADR-011 |

세션 핸드오프 규약 (read 순서 / 영속화): [STATUS.md "Required reads"](STATUS.md), [CLAUDE.md](CLAUDE.md) 참조.
