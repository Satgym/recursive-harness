---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: <see body>
target: <see body>
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e67e0-ae0e-7933-bcaf-1b5daa59b723
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 198437
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T05:20
  prompt_source: .harness/prompts/meta-review-direction-completeness.md
---

**REVIEW**

Assumption: 이 리뷰는 “현재 파일 상태가 Hara/starpin의 SoT”라는 전제입니다. 현재 작업트리에는 내가 만들지 않은 untracked `.harness/prompts/meta-review-direction-completeness.md`가 있어 무시했습니다.

1. `severity: blocker`  
   `위치`: [STATUS.md](/Users/satgym/work/harness/STATUS.md:11), [starpin status.md](/Users/satgym/work/harness/examples/starpin/.harness/status.md:11), [starpin status.md](/Users/satgym/work/harness/examples/starpin/.harness/status.md:287), [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:5)  
   `근거`: root STATUS는 starpin v0.4 shipped라는데, starpin 자체 STATUS는 여전히 v0.1 shipped + “M1 구현 시작”을 next action으로 둡니다. Stranger-proof 목적이 직접 깨졌습니다.  
   `제안`: starpin v0.5/Hara v1.6 전에 `examples/starpin/.harness/status.md`를 v0.4 기준으로 재작성하고, root STATUS와 상호 참조를 맞추세요.

2. `severity: blocker`  
   `위치`: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:492), [starpin v0.4 prompt](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v04/rate-limit/prompt.md:5), [starpin-fleet RELEASE](/Users/satgym/work/harness/examples/starpin-fleet/RELEASE.md:58)  
   `근거`: HARNESS §14는 git worktree 격리를 Fleet의 모델로 정의하지만, 실제 dogfood prompts는 같은 backend 디렉토리를 가리키고 `git worktree list`도 root 1개뿐입니다. 현재 evidence는 OS-level isolation이 아니라 self-discipline입니다.  
   `제안`: “Fleet 검증 완료” 표현을 낮추고, 다음 Hara 라운드는 real git worktree 2-child 이상으로만 통과시키세요.

3. `severity: major`  
   `위치`: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:336), [v03 oauth prompt](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v03/oauth-google-pkce/prompt.md:8), [v04 rate-limit prompt](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v04/rate-limit/prompt.md:8)  
   `근거`: §13.3은 `.harness/capabilities.md`와 Active local skills를 working set에 포함하라고 하지만, v0.3/v0.4 Fleet child prompts는 HARNESS §14 + locked-interface + ADR만 읽습니다. local layer가 Fleet에서 사실상 우회됐습니다.  
   `제안`: SUBTREE-PROMPT 필수 읽기에 frozen capabilities + relevant local skills를 넣고, child merge-report에 “local skill 적용/비적용 사유” 필드를 의무화하세요.

4. `severity: major`  
   `위치`: [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:43), [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:60), [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:70), [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:126)  
   `근거`: manifest가 “PROPOSED”, “v0.7 draft”, “Skills (5 Active)”라고 하면서 실제로는 6개 skill을 `status: approved`로 나열합니다. manifest 자체가 machine-readable SoT로 신뢰하기 어렵습니다.  
   `제안`: manifest schema validator를 만들고, draft/archive/history는 별도 섹션 또는 별도 파일로 분리하세요.

5. `severity: major`  
   `위치`: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:251), [STATUS.md](/Users/satgym/work/harness/STATUS.md:178), [DECISIONS.md](/Users/satgym/work/harness/DECISIONS.md:354)  
   `근거`: size discipline이 다시 무너졌습니다. v1.0 이후에도 역사 섹션, 오래된 ADR 본문, inflight finding이 계속 누적되고 STATUS도 181줄까지 재팽창했습니다.  
   `제안`: 기능 추가 금지 cleanup round를 먼저 두세요. §10은 `docs/history/`로, ADR-001~007은 summary table + archive로, STATUS는 current-only로 줄이는 게 우선입니다.

6. `severity: major`  
   `위치`: [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:47), [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:57), [blueprint.md](/Users/satgym/work/harness/examples/starpin/.harness/docs/blueprint.md:205)  
   `근거`: v0.4는 “production-ready hardening 진입”이라고 하지만 mobile full app, ingest worker, snapshot fetch, real deploy가 미완입니다. 원래 사용자 vision인 “거의 완성된 앱”과는 거리가 큽니다.  
   `제안`: release wording을 “backend hardening”으로 제한하고, starpin completion definition을 `backend-ready / app-alpha / data-ingest-ready / deploy-ready`로 쪼개세요.

7. `severity: major`  
   `위치`: [STATUS.md](/Users/satgym/work/harness/STATUS.md:180), [starpin status.md](/Users/satgym/work/harness/examples/starpin/.harness/status.md:571), [v02 review](/Users/satgym/work/harness/.harness/reviews/04-cross-review-20260527-starpin-v02-fleet.md:16), [v04 review](/Users/satgym/work/harness/.harness/reviews/04-cross-review-20260527-starpin-v04.md:16)  
   `근거`: root는 누적 codex tokens를 600K+라고 적지만 starpin Phase 02만 ~610K, v0.2/v0.3/v0.4 reviews만 약 443K입니다. cost guardrail이 기록 수준에서 이미 불일치합니다.  
   `제안`: review postprocess가 STATUS token ledger를 자동 갱신하게 하고, 프로젝트별/하니스별 비용을 분리하세요.

8. `severity: major`  
   `위치`: [v02 review](/Users/satgym/work/harness/.harness/reviews/04-cross-review-20260527-starpin-v02-fleet.md:30), [v03 review](/Users/satgym/work/harness/.harness/reviews/04-cross-review-20260527-starpin-v03-oauth.md:25), [v04 review](/Users/satgym/work/harness/.harness/reviews/04-cross-review-20260527-starpin-v04.md:37)  
   `근거`: codex는 PKCE, provider error mapping, trustProxy, cube fallback 같은 반복 가능한 패턴을 잡았지만 `oauth-pkce-flow`, `http-error-mapping`, `rate-limit-proxy-policy`, `pg-cube-runtime-policy` 같은 local skill 후보로 전환되지 않았습니다. adaptive learning loop가 review closure에서 끊깁니다.  
   `제안`: 모든 major+ finding closure에 “local/base capability candidate? yes/no + 사유”를 필수 필드로 추가하세요.

9. `severity: major`  
   `위치`: [v14-findings.md](/Users/satgym/work/harness/examples/starpin/.harness/v14-findings.md:57), [v14-findings.md](/Users/satgym/work/harness/examples/starpin/.harness/v14-findings.md:83), [v03 review](/Users/satgym/work/harness/.harness/reviews/04-cross-review-20260527-starpin-v03-oauth.md:45)  
   `근거`: AST lock은 child-vs-child 일부만 막고 stable parent module reach-around와 same-directory sibling import를 못 막습니다. “mechanical enforcement” claim은 아직 과장입니다.  
   `제안`: F122/F123을 Hara v1.6의 선행 blocker로 올리고, public module path + consumed stable modules를 machine-readable front-matter로 강제하세요.

10. `severity: major`  
    `위치`: [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:43), [sky merge-report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v04/sky-3d-native/merge-report.md:5), [sky merge-report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v04/sky-3d-native/merge-report.md:49)  
    `근거`: child가 rate-limited 되어 merge-report를 parent가 대리 작성했습니다. Fleet Mode의 failure recovery가 명세 밖에 있습니다.  
    `제안`: child crash/rate-limit 시 `partial artifacts`, `parent-authored report`, `retry window`, `evidence confidence` 절차를 v1.7이 아니라 다음 Fleet 전 필수로 넣으세요.

11. `severity: minor`  
    `위치`: [local skill wc evidence](/Users/satgym/work/harness/examples/starpin/.harness/skills/claim-exclusivity-contract.md:1), [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:58)  
    `근거`: starpin local skills는 249~428줄 규모인데 Fleet prompts에는 들어가지 않습니다. 길고 강하지만 실제 working set에 안 들어가면 compliance 비용만 큽니다.  
    `제안`: 각 skill을 `rationale.md`와 20~50줄 `checklist.md`/script로 분리하고 child prompt에는 checklist만 넣으세요.

12. `severity: minor`  
    `위치`: [esm-jest-pattern.md](/Users/satgym/work/harness/project-types/_generic/esm-jest-pattern.md:132), [v1.3 review](/Users/satgym/work/harness/.harness/reviews/harness-amend-20260527-v1.3-ast-lock.md:63), [templates README](/Users/satgym/work/harness/templates/README.md:17)  
    `근거`: `esm-jest-pattern`은 seed라고 하지만 bootstrap에 연결되지 않았고, LOCAL-ROLE template은 존재하나 현재 local roles는 advisory 입력으로만 쓰입니다. dead artifact가 늘어나는 방향입니다.  
    `제안`: “active template/seed”와 “incubating artifact”를 분리하고, `new-project.sh`에 연결되지 않은 것은 pending/archive로 이동하세요.

13. `severity: info`  
    `위치`: [starpin-fleet RELEASE](/Users/satgym/work/harness/examples/starpin-fleet/RELEASE.md:54), [fleet-mini RELEASE](/Users/satgym/work/harness/examples/fleet-mini/RELEASE.md:46), [STATUS.md](/Users/satgym/work/harness/STATUS.md:156)  
    `근거`: Fleet의 품질 가치는 증거가 있습니다. wall-time 가치는 아직 없습니다. elapsed/duration, sequential baseline, merge overhead가 기록되지 않았습니다.  
    `제안`: 다음 real-worktree dogfood는 child별 start/end, parent merge 시간, rework 시간, codex wait 시간을 필수 ledger로 남기세요.

**권고 방향**

다음 라운드는 `cleanup + SoT repair`가 먼저입니다. 그 다음 `real git worktree Fleet micro-dogfood`로 §14의 실제 isolation과 wall-time ledger를 검증하세요. starpin v0.5는 그 뒤에 하되, “backend feature 추가”보다 mobile app shell + ingest/snapshot Gate A 중 하나를 선택해야 사용자 vision에 가까워집니다. 현재 상태에서 Hara v1.6 amendment를 계속 append하면 adaptive/Fleet의 핵심 가설보다 문서 부채가 더 빨리 커집니다.
