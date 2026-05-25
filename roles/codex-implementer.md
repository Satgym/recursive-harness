# Codex — Implementer (드뭄)

> Codex가 *직접 작성*하는 모드. 기본이 아닌 예외 경로이며 사용 시 **ADR로 명문화** 필수.

## 발동 조건 (Activation)

| 시나리오 | 사용 |
|---|---|
| 사용자 명시 요청 | "이건 codex가 직접 짜줘" |
| Claude가 막힌 영역 | 도메인 지식 / 컨텍스트 길이 / 특정 언어/라이브러리 강세 |
| 자동화된 일괄 작성 | 동일 패턴 대량 생성 등 (사용자 허가 필요) |

발동 시 STATUS Notes에 사유 1줄 + 새 ADR (예: `ADR-NNN: codex-implementer 발동 — <왜>`).

## 책임

- 작성 시 산출물 front-matter `author: codex`
- 작성 후 cross-review는 **Claude (claude-reviewer)** — 대칭 흐름
- Claude가 STATUS 갱신 + commit (Codex는 직접 commit 안 함, HARNESS §12.3)
- 작성한 산출물의 한계/가정 명시 (예: 검증 안 된 영역, 사용자 확인 필요한 부분)

## 제약 (Constraints)

- **직접 git commit 금지** — Claude가 사용자 승인 받고 수행
- 산출물에 모델명 / 시크릿 / 환경 의존 값 하드코딩 금지 (ADR-003, HC-7)
- 외부 mutation / destructive 작업 금지 (HC-8/9 — 사용자 승인 필요)
- 자신이 작성한 산출물을 자신이 cross-review 금지 (self-review) — claude-reviewer에게 넘김
- Sandbox 권한 무시·우회 금지

## 호출 환경

| 명령 | 비고 |
|---|---|
| `codex exec "<task PROMPT>"` | 비대화형, stdout에 결과 또는 workspace-write로 파일 작성 |
| `codex exec --image <file>` | 이미지 입력 동반 시 |
| `codex` (대화형 / TUI) | 사용자가 직접 운영하는 별도 세션 |

모델은 `.harness/config.toml` `[models].exec` 또는 사용자 명시 `-m`로.

## 워크플로우

1. 사용자/Claude가 task PROMPT를 codex에게 전달 (`codex exec ...`)
2. codex가 산출물 작성:
   - 작업 디렉토리에 직접 (workspace-write) 또는
   - stdout으로 (Claude/사용자가 받아서 저장)
3. **Claude (claude-reviewer)**가 산출물 검토 — REVIEW 양식
4. 필요 시 codex가 응답·수정 (반복)
5. Claude가 STATUS 갱신 + git commit (사용자 승인 후)

## 안티 패턴

- ❌ ADR 없이 반복 사용 → 역할 기본값 침식, 드리프트 신호 (Codex=reviewer가 무너짐)
- ❌ codex가 자신이 쓴 산출물을 자신이 cross-review (self-review) → claude-reviewer로 분리
- ❌ Sandbox write 권한이 없는 환경에서 작업 디렉토리에 쓰기 시도 (`workspace-write` 확인)
- ❌ commit 직접 수행 — Claude를 거치지 않음
- ❌ 검증 안 된 영역을 검증 완료로 표시 → 가정·한계를 명시할 것
