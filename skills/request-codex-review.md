# Skill: request-codex-review

## Purpose

Codex에 정식 리뷰를 의뢰. 코드 변경은 `codex review`, 텍스트(Blueprint / Plan / ADR / 하니스 docs)는 `codex exec`. 결과는 `.harness/reviews/`에 [templates/REVIEW.template.md](../templates/REVIEW.template.md) 양식으로 저장.

## When to invoke

- Phase 04 CrossReview 진입 시 (코드)
- Phase 01 Blueprint / Phase 02 Module Plan / 중요한 ADR 작성 후 (텍스트)
- 분쟁 시 추가 검증이 필요할 때 (`scripts/codex-review.sh --commit <sha>` 형태)

## Inputs

- 리뷰 대상 (commit / branch / 텍스트 파일)
- `.harness/config.toml`의 `[models]`, `[reasoning]`, `[git]`
- PROMPT 파일 (가능하면 — 없으면 wrapper의 기본 PROMPT 사용)

## Procedure

1. **사전 점검**:
   - `$HARNESS_ROOT` 환경변수 설정 (또는 `.harness/config.toml [harness] root`에서 자동 인지)
   - `.harness/config.toml`에 `[models]`이 채워져 있는지 (없으면 codex CLI 디폴트 사용 — 알림)
   - 누적 토큰이 §5.4 cost guardrail에 가까운지 (현 누적은 STATUS Notes)
   - HARNESS 대상 review 횟수가 3 초과면 사용자 명시 확인
2. **코드 리뷰** (코드 변경 시):
   - 작업 branch에서 commit까지 완료 (또는 staged)
   - `scripts/pre-review-gate.sh` PASS 보장 (wrapper가 자동 호출)
   - 호출:
     ```bash
     "$HARNESS_ROOT/scripts/codex-review.sh" \
         --phase 04 --slug "<module-or-scope>" \
         --base main \
         --review-round "<e.g. M3-cr-r1>" \
         --prior-review "<있다면 이전 .md>"
     ```
   - (또는) `--uncommitted` / `--commit <sha>` (mutually exclusive)
3. **텍스트 리뷰** (Blueprint / Plan / ADR / 하니스 docs):
   - PROMPT 파일을 `.harness/prompts/<phase>-<slug>.md`에 준비
   - 호출:
     ```bash
     "$HARNESS_ROOT/scripts/codex-exec-review.sh" \
         --phase 01-blueprint --slug initial \
         --prompt-file .harness/prompts/blueprint-review.md \
         --review-round blueprint-r1 \
         --target ".harness/docs/blueprint.md"
     ```
4. **결과 저장**:
   - wrapper가 `_codex_postprocess.py`로 raw stdout을 REVIEW 양식으로 변환해 `.harness/reviews/<phase>-<date>-<slug>.md`에 저장
   - codex_meta 모든 필드(model / session_id / tokens / base_ref / invoked_at / prompt_source 등) 보존됨 (§5.3)
5. **REVIEW validation** (F30):
   - 다음을 모두 검증 — 실패 시 "리뷰 받음"으로 인정 X:
     - [ ] front-matter 필수 키: `artifact: review`, `date`, `author`, `status`, `codex_meta`
     - [ ] `codex_meta` 필수 sub-key: `model`, `session_id`, `tokens_used`, `invoked_at`, `prompt_source`
     - [ ] severity / status enum이 canonical (blocker|major|minor|nit|info; open|resolved|deferred|disputed)
     - [ ] finding ID monotonicity (이전 라운드 최대 ID + 1부터 시작, 누락·중복 없음)
     - [ ] "tokens used" 또는 토큰 카운트 추출 성공
   - 실패 시 raw 파일 경로를 STATUS *Open findings*에 "invalid review attempt"로 등재 + review 파일 자체는 `status: invalid` (또는 `disputed`)로 표시 후 재호출 또는 사용자 escalation
6. **STATUS 갱신**:
   - *Open findings*에 새 finding을 출처 명시로 등재
   - *Notes*에 토큰 누적 갱신
   - INBOX 카운트 영향 없음 (정식 리뷰는 `.harness/reviews/`, INBOX는 능동 피드백 채널)
7. **다음 단계**: [skills/apply-review.md](apply-review.md)

## Outputs / Side effects

- `.harness/reviews/<phase>-<date>-<slug>.md` (front-matter 전부 채워진 REVIEW)
- STATUS *Open findings* + *Notes* 갱신
- 토큰 소비

## Failure modes

- **pre-review-gate 실패** → wrapper가 exit 3. lint/test 먼저 통과해야. `--no-gate`는 디버깅·우회 한정 (사용 시 STATUS Notes에 사유).
- **`[config] WARNING: no python with tomllib/tomli`** (F21) → `.harness/config.toml`이 무시됨. 즉시 python3.11+ 설치 또는 `pip install tomli`. 그 전엔 codex CLI 디폴트가 사용됨.
- **codex 호출 자체 실패** (네트워크 / 인증 만료) → raw 캡쳐 파일이 비어 있거나 에러 메시지. STATUS Open finding으로 등재 후 사용자에게 escalation.
- **§5.4 cost guardrail 위반** (4회째 재리뷰 등) → 사용자 명시 확인 받기 전까지 호출 금지.

## Related

- [phases/04-cross-review.md](../phases/04-cross-review.md)
- [scripts/codex-review.sh](../scripts/codex-review.sh)
- [scripts/codex-exec-review.sh](../scripts/codex-exec-review.sh)
- [scripts/_codex_postprocess.py](../scripts/_codex_postprocess.py)
- HARNESS §5 (호출 규약), §5.4 (cost guardrail)
- ADR-002 (파일 기반 비동기 채널)
- ADR-003 (모델 설정)
