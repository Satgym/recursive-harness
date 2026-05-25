# scripts/ — 자동화 스크립트

| 스크립트 | 용도 | 호출 시점 |
|---|---|---|
| [codex-review.sh](codex-review.sh) | `codex review --base <branch>` cross-review wrapper | Phase 04 (CrossReview), 모듈 commit 후 |
| [codex-exec-review.sh](codex-exec-review.sh) | `codex exec - < prompt` 텍스트 검토 wrapper | Phase 01/02/ADR/하니스 docs 검토 |
| [pre-review-gate.sh](pre-review-gate.sh) | lint / typecheck / unit test 게이트 | codex-review.sh 안에서 자동 호출 (HC-1 / cost guardrail §5.4) |
| [new-project.sh](new-project.sh) | 하니스로 관리되는 새 프로젝트 부트스트랩 | 새 프로젝트 시작 시 1회 |
| [_codex_postprocess.py](_codex_postprocess.py) | codex raw stdout → canonical REVIEW (front-matter 부착, 트레이스 제거) | 위 두 wrapper가 내부 호출 |

## 공통 동작

- `.harness/config.toml`의 `[models]` / `[reasoning]` / `[git]` 섹션을 디폴트로 사용 (없으면 codex CLI 디폴트).
- 결과는 `.harness/reviews/<phase>-<date>-<slug>.md`에 [templates/REVIEW.template.md](../templates/REVIEW.template.md) 양식으로 저장.
- 모든 스크립트는 `git rev-parse --show-toplevel`을 기준으로 동작 (repo 루트에서 실행 가정).

## 의존성

- bash 4+ (macOS 기본 `/bin/bash`는 3.2이지만 `/usr/bin/env bash`가 brew의 4+를 잡으면 OK)
- python 3.11+ (`tomllib` 표준 라이브러리)
- codex CLI 0.132+ (`codex review` / `codex exec` 지원)
- (선택) jq, ripgrep — 일부 디버깅 편의

## 사용 예

```bash
# 텍스트 검토: Blueprint 또는 ADR
scripts/codex-exec-review.sh --phase 01-blueprint --slug initial \
    --prompt-file .harness/prompts/blueprint-review.md

# 코드 cross-review
scripts/codex-review.sh --phase 04 --slug module-auth --base main

# 새 프로젝트 부트스트랩
scripts/new-project.sh "my-web-app" web-service
```

## 안전장치 (HC-7/8/9)

- HC-7: 스크립트가 시크릿/자격증명을 stdout/log에 출력하지 않도록 — `.harness/config.toml`에 시크릿 *키 이름만* 두고 실제 값은 환경변수/secret manager
- HC-8: 스크립트가 외부 mutation(push/deploy) 실행 금지. 본 디렉토리 스크립트는 모두 *읽기 + 로컬 쓰기*만
- HC-9: `new-project.sh`는 기존 `.harness/` 발견 시 abort (덮어쓰기 금지)
