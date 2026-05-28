r2 verify of Hara v2.3 HC-13 Visual-Review (ADR-025) — after fps-defer surgical patches.

## r1 (`harness-20260528-v23-hc13-visual.md`)

**Verdict**: block. 4 findings (2 blocker + 2 major):
- #1 blocker: `scripts/ui-visual-review.sh` 가 hook 메시지 + skill 에서 reference 되는데 존재 X (theater 위험)
- #2 blocker: HC-13 hook 검증이 mobile lane 안에만 — web-only + ui-spec.md 시 발동 안 됨
- #3 major: skill failure mode "screenshot 0 = skip" 가 ui-spec 있는 경우 잘못 (fail 해야)
- #4 major: schema 3 곳 inconsistent — canonical 1곳 고정 필요 + hook 도 더 strict

## v0.2 patch (이 round)

1. **#1 close**: `scripts/ui-visual-review.sh` 작성 (210 라인)
   - inputs: --slug --platform --screenshots --ui-spec --claude-review --evidence [--codex-prompt]
   - Claude review front-matter parse + codex-exec-review.sh 호출 + combined blocker check + evidence JSON canonical schema patch
   - exit codes: 0/1/2/3/4 명시
   - chmod +x; bash -n PASS

2. **#2 close**: HC-13 검증을 hook 의 web lane 에도 추가
   - shared `validate_ui_review` helper 추출 (DRY)
   - web lane: web evidence valid + ui-spec.md tracked → validate_ui_review
   - mobile lane: 동일
   - `note()` carveout 그대로 (gitignored sub-project 의 ui-spec.md 는 root 에서 안 보임)

3. **#3 close**: skill v0.2 failure mode 표 분리
   - `ui-spec.md` 없음 = skip (HC-13 N/A)
   - `ui-spec.md` 있음 + screenshot 0 = **FAIL** (runner exit 3, ship 차단)
   - 명시 8 row 으로 확장

4. **#4 close**: canonical schema 1곳 (skill Outputs 표 + 별도 sub-section)
   - `claude_pass`, `codex_pass`, `findings_count`, `blocker_count`, `severity_counts.{blocker,major,minor}`, `claude_review`, `codex_review`
   - hook 의 validate_ui_review 가 *strict*: `bool == True` (Python `is`) + `blocker_count == 0` + review path 존재 (os.path.isfile)
   - hand-written `{claude_pass:true}` 우회 → review path 검증으로 차단

5. **B.2 bonus** (minor): case pattern 정확화 — `.harness/docs/ui-spec.md|*/.harness/docs/ui-spec.md` (false positive `some.harness/...` 차단)

## r2 task

각 closure 가 v0.2 에 정말 들어갔는지 verify:

1. **#1 close**: `scripts/ui-visual-review.sh` exists + executable + bash -n PASS + 5 exit codes 명시
2. **#2 close**: hook 의 web lane 안에 HC-13 block + mobile lane 안에 HC-13 block (둘 다 validate_ui_review 호출)
3. **#3 close**: skill Failure modes 표가 8 row (skip 1 + fail 6 + pass 1) — ui-spec 있음 + screenshot 0 = exit 3
4. **#4 close**: canonical schema sub-section 명시 + hook validator 가 review path 존재 검증 (os.path.isfile)
5. **B.2 bonus**: hook 의 ui_spec detection case pattern 이 `.harness/docs/ui-spec.md|*/.harness/docs/ui-spec.md` 정확 매칭

추가 sanity:
- recursive self-validation: v2.3 자체 push 시 ui-spec.md 미존재 → HC-13 skip → PASS (확인됨 — "Everything up-to-date")
- v2.3 ship-style commit 이 hook 통과할 것인지

verdict: **ship** | **block** | **minor-followup**. 간결.
