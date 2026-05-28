---
artifact: review
date: 2026-05-28
author: codex
status: open
severity: <see body>
target: Hara v2.3 HC-13 Visual-Review (ADR-025)
review_round: r1
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e6d11-fa30-7591-9920-eb884fe0b27d
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 78246
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-28T05:32
  prompt_source: .harness/prompts/harness-v23-hc13-visual-r1.md
---

**REVIEW**

Verdict: **block**

1. `severity: blocker`  
   `위치`: [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:270), [skills/ui-visual-review.md](/Users/satgym/work/harness/skills/ui-visual-review.md:71)  
   `근거`: HC-13 fail 메시지가 `bash scripts/ui-visual-review.sh` 실행을 지시하고 skill도 helper script를 전제로 하지만, `scripts/ui-visual-review.sh`가 현재 repo에 없습니다. 첫 in-repo mobile project가 `ui-spec.md`를 추가하면 hook은 막지만 documented recovery path가 dead command입니다. 이건 visual infra의 load-bearing 부분이라 theater에 가깝습니다.  
   `제안`: v2.3에 최소 runner script를 포함하거나, hook 메시지와 skill을 현재 존재하는 `scripts/codex-exec-review.sh` 기반 수동 절차로 정확히 바꾸세요. 가능하면 evidence JSON patch까지 하는 얇은 `scripts/ui-visual-review.sh`를 추가하는 쪽이 맞습니다.

2. `severity: blocker`  
   `위치`: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:33), [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:201), [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:223)  
   `근거`: HC-13 문서는 “UI surface”와 web/mobile 모두를 말하지만 hook 검증은 mobile lane 내부에만 있습니다. web-only project가 `public/` 또는 `frontend/` + `.harness/docs/ui-spec.md`를 가져도 HC-12 web evidence만 통과하면 HC-13은 전혀 실행되지 않습니다. “hook으로 자동 enforce”라는 HARNESS 문구와 실제 enforcement가 불일치합니다.  
   `제안`: 의도가 web+mobile이면 web lane에도 동일한 `ui_review` 검증을 붙이세요. 의도가 v2.3에서는 mobile-only라면 HARNESS/ADR/skill trigger를 “mobile visual review v0.1”로 좁혀야 합니다.

3. `severity: major`  
   `위치`: [skills/ui-visual-review.md](/Users/satgym/work/harness/skills/ui-visual-review.md:100)  
   `근거`: failure mode가 “screenshot 0개 → skill skip + warning (HC-13 미적용)”이라고 되어 있습니다. 하지만 `ui-spec.md`가 있으면 HC-13은 opt-in 발동 상태입니다. 특히 starpin v0.14는 `note()` carveout 때문에 manual gate라서, 이 문구대로면 screenshot 없이 visual review를 N/A 처리할 여지가 생깁니다.  
   `제안`: `ui-spec.md` 없음은 skip, `ui-spec.md` 있음 + screenshot 0개는 fail로 분리하세요. evidence는 `claude_pass:false`, `codex_pass:false`, `blocker_count >= 1` 또는 no evidence로 hook/manual gate가 차단해야 합니다.

4. `severity: major`  
   `위치`: [skills/ui-visual-review.md](/Users/satgym/work/harness/skills/ui-visual-review.md:29), [skills/ui-visual-review.md](/Users/satgym/work/harness/skills/ui-visual-review.md:52), [skills/ui-visual-review.md](/Users/satgym/work/harness/skills/ui-visual-review.md:86), [.githooks/pre-push](/Users/satgym/work/harness/.githooks/pre-push:257)  
   `근거`: schema가 세 군데에서 다릅니다. 본문은 `findings[]`, outputs table은 `finding_files`, sample은 `findings_count/blocker_count/claude_review/codex_review`입니다. hook은 bool 두 개만 봅니다. 최소 구현자는 어떤 필드가 canonical인지 알 수 없고, `{"claude_pass": true, "codex_pass": true}`만 손으로 넣어도 통과합니다.  
   `제안`: canonical schema를 하나로 고정하세요. 권장: `claude_pass`, `codex_pass`, `findings_count`, `blocker_count`, `severity_counts`, `claude_review`, `codex_review`. hook은 최소한 bool exact true + integer counts + `blocker_count == 0` + review path 존재를 검증하는 편이 낫습니다.

**질문별 판단**

- B.2 regex/pattern: 실제 구현은 `grep`이 아니라 bash `case`이며, `.harness/docs/ui-spec.md`, `frontend/.harness/docs/ui-spec.md`, `web/.harness/docs/ui-spec.md` 모두 match합니다. 이 부분 자체는 blocker가 아닙니다. 다만 `some.harness/docs/ui-spec.md` 같은 false positive는 가능해서 더 정확히 하려면 `.harness/docs/ui-spec.md|*/.harness/docs/ui-spec.md`가 낫습니다.
- C.2 schema completeness: 현재는 major gap입니다. severity별 breakdown은 있으면 좋다가 아니라, subjective visual review를 다음 라운드에서 재검증하려면 `severity_counts` 정도는 load-bearing입니다.
- D.2 ui-spec ownership: `skills/ui-visual-review.md`의 INV-VR-3처럼 Blueprint amendment가 맞습니다. starpin v0.14의 `ui-spec.md`는 implementation note가 아니라 design intent SoT입니다.

`bash -n .githooks/pre-push`는 PASS였습니다. 하지만 위 두 blocker 때문에 v2.3은 아직 ship 불가입니다.
