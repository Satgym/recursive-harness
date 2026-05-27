---
artifact: review
date: 2026-05-27
author: codex
status: open
severity: major
target: Hara harness self-review — usage gaps + missing structure (post v0.5 + v0.6 dogfood)
codex_meta:
  codex_version: 0.132.0
  model: gpt-5.5
  provider: openai
  session_id: 019e68ad-f95f-79e1-9d97-fa7cc7691f62
  workdir: /Users/satgym/work/harness
  sandbox_policy: workspace-write [workdir, /tmp, $TMPDIR]
  reasoning_effort: high
  tokens_used: 205546
  base_ref: 
  included_paths: 
  invoked_at: 2026-05-27T09:04
  prompt_source: .harness/prompts/06-meta-harness-usage-gap-r1.md
---

**Scope Note**

This is a Hara harness self-review. I used `examples/starpin/` only as dogfood evidence for v0.5 and v0.6 behavior, not as a product review.

**Q1 — Structures Actually Used**

| Harness component | Used in v0.5? | Used in v0.6? | Frequency / evidence | Role played |
|---|---:|---:|---|---|
| `scripts/codex-exec-review.sh` | Yes | Yes | All four requested reviews have `base_ref:` blank and `prompt_source` set to `.harness/prompts/...`: [v0.5 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:17), [v0.5 r2](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r2.md:19), [v0.6 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v06-ingest-r1.md:17), [v0.6 r2](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v06-ingest-r2.md:19). Token ledger also records these 4 review artifacts: [codex-token-ledger.jsonl](/Users/satgym/work/harness/examples/starpin/.harness/codex-token-ledger.jsonl:1). | Actual review transport for both code-like bundle reviews and verification rounds. |
| `scripts/codex-review.sh` | No evidence | No evidence | Phase 04 says it should be used: [phases/04-cross-review.md](/Users/satgym/work/harness/phases/04-cross-review.md:14). But actual review metadata lacks `base_ref`, which `codex-review.sh` would populate: [scripts/codex-review.sh](/Users/satgym/work/harness/scripts/codex-review.sh:166). | Defined standard, not dogfood path. |
| `scripts/fleet/gen_eslint_lock.py` | Yes | Carry / verification only | v0.5 r1 found a lock gap in it: [review](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:78). v0.5 r2 verified `allowImportNames`: [review](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r2.md:70). Release states F126 shipped and 14 configs passed: [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:157). v0.6 release says those 14 configs still pass: [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:73). | Real mechanical Fleet lock enforcement. |
| `scripts/fleet/topo_sort.py` | Mentioned, no invocation evidence | No | ADR-011 selected `inter_child_consume_strategy: c`: [ADR-011](/Users/satgym/work/harness/examples/starpin/.harness/decisions/ADR-011-v05-web-demo-split.md:16), and describes topological wave intent: [ADR-011](/Users/satgym/work/harness/examples/starpin/.harness/decisions/ADR-011-v05-web-demo-split.md:70). I found no release/review evidence that `topo_sort.py` was run. | Design intent, not actual tool. |
| `scripts/fleet/gen_stub.py`, `gen_ambient.py` | No | No | No references in v0.5/v0.6 release or requested reviews. | Defined for other consume strategies; dead in this dogfood. |
| `scripts/fleet/validate_capabilities.py` | No evidence | No evidence | Capability manifest was read manually; no run evidence in reviews/release. | Needs activation tooling. |
| `templates/REVIEW.template.md` | Yes, partially | Yes, partially | Template requires review front matter and `capability_candidate`: [REVIEW.template.md](/Users/satgym/work/harness/templates/REVIEW.template.md:1), [REVIEW.template.md](/Users/satgym/work/harness/templates/REVIEW.template.md:42). All reviews include those fields, but generated files have duplicated front matter: [v0.5 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:1). | Effective review shape, but postprocess output is not clean. |
| `templates/MERGE-REPORT.template.md` | Yes, loosely | No | v0.5 children wrote merge reports, e.g. [web-shell](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/merge-report.md:1), [web-login](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-login/merge-report.md:1). Template requires per-child codex review and status: [MERGE-REPORT.template.md](/Users/satgym/work/harness/templates/MERGE-REPORT.template.md:123), but v0.5 children explicitly skipped child review: [web-shell](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/merge-report.md:270). | Handoff artifact, but adapted by hand. |
| `templates/SUBTREE-PROMPT.template.md` | Yes, hand-derived | No | v0.5 child prompts exist: [web-shell prompt](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/prompt.md:1). They include required reads and local skills, but lack the template front matter and full phase machinery: [template](/Users/satgym/work/harness/templates/SUBTREE-PROMPT.template.md:1). | Kickoff prompt pattern, not strict instantiation. |
| `templates/LOCKED-INTERFACE.template.md` | Yes, hand-derived | No | v0.5 locked interfaces have machine fields like `public_module_path` and `consumed_stable_modules`: [locked interface](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-login/locked-interface.md:6). | Actual source for lock enforcement. |
| `templates/SPLIT-DECISION-ADR.template.md` | Yes | No | ADR-011 is a split decision with required fields: [ADR-011](/Users/satgym/work/harness/examples/starpin/.harness/decisions/ADR-011-v05-web-demo-split.md:1). | Fleet planning SoT. |
| `templates/SUBTREE-STATUS.template.md` | No | No | v0.5 child reports say subtree status was n/a because same worktree was used: [web-shell merge report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/merge-report.md:272). | Defined but bypassed. |
| `phases/*.md` | Followed conceptually | Followed conceptually | v0.5 has split, merge reports, parent review, release; v0.6 has review and handoff. But prompts cite HARNESS §14, not canonical phase docs. Phase 04 expected `codex-review.sh`: [phases/04-cross-review.md](/Users/satgym/work/harness/phases/04-cross-review.md:14), while actual used exec prompts. | Vocabulary and gates influenced work, but not mechanically enforced. |
| `roles/*.md` | No explicit role invocation | No explicit role invocation | Active local roles exist in manifest: [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:140). Requested v0.5/v0.6 prompts/reviews do not invoke `mobile-platform-reviewer`, `astronomy-data-reviewer`, `codex-reviewer`, etc.; only incidental HTML `role=` hits were found. | Mostly dormant. |
| `INBOX/` / `.harness/inbox/` | No | No | Project inbox has only README: [README](/Users/satgym/work/harness/examples/starpin/.harness/inbox/README.md:1). Status says none: [status.md](/Users/satgym/work/harness/examples/starpin/.harness/status.md:118). | Unused in these rounds. |
| `.harness/skills/` | Yes | Yes, but differently | v0.5 prompts include active skills directly, e.g. [web-shell](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/prompt.md:8), [web-sky](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-sky-canvas/prompt.md:16). v0.6 review explicitly used `external-catalog-rate-limit`: [v0.6 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v06-ingest-r1.md:66). | v0.5: per-child skill application ledger. v0.6: targeted skill evidence, more ad hoc. |
| `.harness/capabilities.md` | Yes | Weak / ad hoc | v0.5 prompts require it: [web-shell prompt](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/prompt.md:13). Manifest Active list has 6 skills + 2 roles: [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:69). v0.6 prompt does not cite manifest, only specific skill behavior. | v0.5 discovery flow mostly followed; v0.6 capability selection was manual. |
| `.harness/decisions/ADR-*` | Yes | Yes | v0.5 uses ADR-011 split: [ADR-011](/Users/satgym/work/harness/examples/starpin/.harness/decisions/ADR-011-v05-web-demo-split.md:26). v0.6 amends ADR-002 checksum and notes: [ADR-002](/Users/satgym/work/harness/examples/starpin/.harness/decisions/ADR-002-catalog-snapshot.md:25). | High-value SoT. |
| `RELEASE.md` | Yes | Yes | v0.5 release captures Fleet, review, F126: [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:115). v0.6 release captures sequential ingest and review closure: [RELEASE.md](/Users/satgym/work/harness/examples/starpin/RELEASE.md:18). | Main dogfood history / evidence index. |

**Q2 — Where The Harness Failed To Support The Work**

1. **The documented code-review wrapper was bypassed.**  
   Phase 04 requires `scripts/codex-review.sh --phase 04 --slug <module> --base main`: [phases/04-cross-review.md](/Users/satgym/work/harness/phases/04-cross-review.md:14). Actual v0.5/v0.6 review files were generated with empty `base_ref` and prompt files, which matches `codex-exec-review.sh`, not `codex-review.sh`: [v0.5 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:17). This is not just cosmetic: `codex-review.sh` would record a base ref: [scripts/codex-review.sh](/Users/satgym/work/harness/scripts/codex-review.sh:166).

2. **`pre-review-gate.sh` is monorepo-hostile.**  
   It sets root via `git rev-parse --show-toplevel`: [pre-review-gate.sh](/Users/satgym/work/harness/scripts/pre-review-gate.sh:10). In `examples/starpin`, the git top-level is the harness repo, so a direct wrapper call risks running harness self checks instead of starpin backend checks. This likely explains why reviews relied on manual prompt-listed gates instead of the wrapper.

3. **Codex postprocess creates duplicate front matter.**  
   `_codex_postprocess.py` prepends front matter unconditionally: [scripts/_codex_postprocess.py](/Users/satgym/work/harness/scripts/_codex_postprocess.py:139). The review body also starts with front matter, producing two YAML blocks: [v0.5 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:1) and [v0.5 r1 body](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:23). This weakens machine readability.

4. **ESLint v9 Fleet lock enforcement was learned only after three siblings hit the same bug.**  
   `web-login` reports same-dir allowlist blocked incorrectly: [merge report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-login/merge-report.md:87). `web-sky-canvas` reports the same: [merge report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-sky-canvas/merge-report.md:44). `web-claim-message` reports the same: [merge report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-claim-message/merge-report.md:103). Codex later caught the named-import hole as F126: [review](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:78). The harness lacked a sibling broadcast channel.

5. **Fleet promised worktrees, but v0.5 used same-worktree execution.**  
   HARNESS says each child gets independent worktree/branch: [HARNESS.md](/Users/satgym/work/harness/HARNESS.md:484). v0.5 reports say child worktree was not used and work happened in-place on `main`: [web-shell](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/merge-report.md:21), [web-login](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-login/merge-report.md:21). The scaffold has no explicit “same-worktree Fleet” mode, so the actual dogfood sat between spec and reality.

6. **Patch candidates were repeated by hand and had no standard parent intake artifact.**  
   `web-shell` produced 4 patch candidates: [merge report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/merge-report.md:83). `web-login` produced 4 more: [merge report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-login/merge-report.md:85). `web-sky-canvas` had parent-required route/lock changes: [merge report](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-sky-canvas/merge-report.md:39). No collector artifact normalized these into a parent action list.

7. **Capability candidates surfaced but did not flow into a register.**  
   v0.5 codex suggested `oauth-client-state-hygiene`, destructive confirmation, PKCE binding, and lock-eslint improvements: [v0.5 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v05-web-demo-r1.md:47). v0.6 suggested `snapshot-boot-gate` and `external-catalog-call-wrapper`: [v0.6 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v06-ingest-r1.md:47), [v0.6 r1](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v06-ingest-r1.md:71). Child reports suggested `csp-header-emit-skill`, `web-a11y-contrast-gate`, and `ui-error-collapse-checklist`: [web-shell](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-shell/merge-report.md:218), [web-claim-message](/Users/satgym/work/harness/examples/starpin/.harness/subtrees/v05/web-claim-message/merge-report.md:182). The manifest promotion list remains older/manual: [capabilities.md](/Users/satgym/work/harness/examples/starpin/.harness/capabilities.md:180).

8. **Status handoff still allowed internal contradiction.**  
   v0.6 r2 correctly found STATUS had not been updated: [review](/Users/satgym/work/harness/examples/starpin/.harness/reviews/04-20260527-v06-ingest-r2.md:91). After update, top status says v0.6 shipped: [status.md](/Users/satgym/work/harness/examples/starpin/.harness/status.md:3), but the older completion table still says `data-ingest-ready ✗ not started`: [status.md](/Users/satgym/work/harness/examples/starpin/.harness/status.md:50). The harness needs a status consistency validator, not just a template.

9. **Review r2 prompts were manually re-derived.**  
   v0.5 r2 manually lists all ten prior findings and closure instructions: [prompt](/Users/satgym/work/harness/examples/starpin/.harness/prompts/04-cross-review-v05-web-demo-r2.md:9). v0.6 r2 repeats the same pattern: [prompt](/Users/satgym/work/harness/examples/starpin/.harness/prompts/04-cross-review-v06-ingest-r2.md:10). This should be a template or script generated from prior review.

**Q3 — Dead / Underused Structures**

| Structure | Classification | Reason |
|---|---|---|
| `scripts/codex-review.sh` | needs-activation-tooling | It is canonical for Phase 04 but actual dogfood used exec prompts. Also blocked by `pre-review-gate.sh` root behavior. |
| `scripts/codex-exec-review.sh` | alive | It is the real review path for v0.5/v0.6. Needs to be acknowledged as “bundle review” path, not just text review. |
| `scripts/pre-review-gate.sh` | alive-but-broken-in-monorepo | Root detection should use nearest `.harness` or an explicit `--root`; current git top-level behavior is unsafe for `examples/starpin`. |
| `scripts/fleet/gen_eslint_lock.py` | alive | It directly improved v0.5 and remained a v0.6 gate. |
| `scripts/fleet/gen_stub.py`, `gen_ambient.py` | truly-unused-in-dogfood; keep incubating | No v0.5/v0.6 use because strategy `c` was selected and even that was manual. |
| `scripts/fleet/topo_sort.py` | needs-activation-tooling | Strategy `c` was selected, but I found no evidence the helper ran. |
| `scripts/fleet/validate_capabilities.py` | needs-activation-tooling | Capability manifest was manually read; no validation evidence. |
| `templates/REVIEW.template.md` | alive | Used in shape, but postprocess double-frontmatter needs cleanup. |
| `templates/MERGE-REPORT.template.md` | alive-but-loose | Child reports used it broadly, but skipped child codex review and subtree status. |
| `templates/SUBTREE-PROMPT.template.md` | alive-but-hand-derived | Actual prompts were compact/manual, lacking template front matter. |
| `templates/SUBTREE-STATUS.template.md` | dead in this dogfood | Same-worktree mode made it n/a. Needs either enforcement or same-worktree exception. |
| `roles/*.md` and local `.harness/roles/*` | needs-activation-tooling | Roles are listed in manifest but not explicitly invoked in v0.5/v0.6 reviews. |
| `INBOX/` workflow | alive-but-dormant | No v0.5/v0.6 produce/process activity. Keep for async feedback, but do not pretend it is part of normal review loop. |
| `project-types/*` | alive for kickoff, dead for maturation rounds | Useful at project start; not consulted in v0.5/v0.6 evolution. |
| `CAPABILITY-MANIFEST` promotion section | needs-activation-tooling | Candidates are now emitted in reviews/merge reports but not collected or promoted. |
| `phases/*.md` | alive as doctrine, weak as gates | Phase concepts were followed; canonical docs were not demonstrably read at transition time. |

**Q4 — New Structures To Close Gaps**

| Name | Type | Trigger | Owner | Cost |
|---|---|---|---|---:|
| `scripts/codex-bundle-review.sh` | script | Any Phase 04 review where review target is a curated file bundle or gitignored project, not a clean branch diff | both | M |
| `templates/REVIEW-RERUN.template.md` + generator | template/script | Any r2+ review with prior findings | Codex generates, Claude invokes | S |
| `scripts/validate_status.py` | script | Phase 06 handoff and before release note | Claude | M |
| `.harness/capability-candidates.md` + `scripts/collect_capability_candidates.py` | doc/script | After every REVIEW and MERGE-REPORT | both | M |
| `scripts/fleet/collect_merge_reports.py` | script | Phase 05 merge-collection | Claude | M |
| `.harness/subtrees/shared-findings.md` | doc/protocol | Any child finds a parent/harness/sibling-affecting bug | Claude child, parent consumes | S |
| `scripts/fleet/run_lock_configs.py` | script | After `gen_eslint_lock.py`, before parent review | Claude | M |
| `templates/PATCH-CANDIDATE.template.md` or `.harness/patch-candidates.yaml` | template | Child needs parent-owned/shared file change | Claude child | S |
| `same-worktree-fleet.md` or `HARNESS §14 same_worktree_mode` | doc/ADR | Examples/dogfood run Fleet without real worktrees | both | M |
| `scripts/phase_gate.py` | script | Phase transition 02→03, 04→05, 05→06 | Claude | L |

**Q5 — Prioritization**

**Next Harness Maturation Round**

1. Fix `pre-review-gate.sh` project-root detection and add `--root`. This removes the biggest reason `codex-review.sh` is unsafe in `examples/starpin`.
2. Add `scripts/codex-bundle-review.sh`. The real workflow is prompt-file bundle review; make it first-class instead of pretending all code review is `codex review --base`.
3. Add `scripts/validate_status.py`. v0.6 proved handoff can remain internally stale even after a review finding.
4. Add `scripts/collect_capability_candidates.py` and `.harness/capability-candidates.md`. The adaptive loop is producing candidates but losing them.
5. Add `scripts/fleet/collect_merge_reports.py`. Parent merge currently re-derives patch candidates, open findings, and candidate lists by reading N reports manually.
6. Patch `_codex_postprocess.py` to strip duplicate body front matter or mark wrapped-body front matter invalid.

**v1.8 Carry**

7. `scripts/fleet/run_lock_configs.py`, including public/lib and same-dir stable-module cases. This turns the v0.5 F126 path into a reusable gate.
8. `templates/REVIEW-RERUN.template.md` generator from prior review IDs.
9. `templates/PATCH-CANDIDATE.template.md` / YAML register.
10. Same-worktree Fleet mode ADR: either prohibit it or define reduced guarantees and required compensating checks.

**Nice-To-Have / Defer**

- Role activation tooling for `astronomy-data-reviewer` and `mobile-platform-reviewer`. Valuable later, but v0.5/v0.6 failures were scripts/status/candidate flow, not missing advisory personas.
- INBOX automation. It was unused here; keep the channel but do not prioritize it over review/merge/status mechanics.
- Project-type seed expansion, e.g. `realtime-astronomy`. Useful after another astronomy project or after starpin v0.7+ repeats the same ingest patterns.
