# project-types/ — 프로젝트 타입별 템플릿

[Phase 00 Intake](../phases/00-intake.md)에서 `scripts/new-project.sh`가 선택된 project-type의 디렉토리 내용을 `.harness/docs/`로 복사한다. 각 type은 *intake checklist + test strategy + module skeleton* 세트를 제공.

## 현재 지원 타입 (ADR-005 우선순위 반영)

| 타입 | 깊이 | 추가 자료 | 사용 시점 |
|---|---|---|---|
| **`web-service/`** | 깊이 | API spec 양식 포함 | REST/GraphQL/RPC 웹 백엔드 (+ 프론트엔드 연결) |
| **`_generic/`** | 골격 | — | 위에 매칭 안 되는 모든 경우의 fallback |

### 향후 타입 (실 필요 발생 시 추가)
- `firmware/` — MCU·플래시 예산·RTOS·HIL
- `ai-model/` — 데이터·평가셋·베이스라인·재현성
- `cli-tool/` — argparse·UX·플랫폼 호환성
- `data-pipeline/` — 스키마·idempotency·재처리

새 타입 추가는 [skills/harness-amend.md](../skills/harness-amend.md) 절차 (메타 부트스트랩).

## 새 타입을 만드는 방법

```bash
mkdir project-types/<new-type>/
# 다음 3개 파일을 _generic/에서 복사 후 도메인 특화:
cp project-types/_generic/intake-checklist.md project-types/<new-type>/
cp project-types/_generic/test-strategy.md     project-types/<new-type>/
cp project-types/_generic/module-skeleton.md   project-types/<new-type>/
```

작성 후 [skills/harness-amend.md](../skills/harness-amend.md)에 따라 ADR 발행 + 사용자 승인.

## 파일 컨벤션

각 타입 디렉토리에 *최소* 3파일:
- `intake-checklist.md` — Phase 00 Intake에서 답해야 할 도메인 질문
- `test-strategy.md` — Blueprint §5/§6 작성에 영감을 주는 테스트·관측 전략 패턴
- `module-skeleton.md` — Blueprint §3 Modules의 시작점이 될 모듈 분할 예시

특화 자료(예: `api-spec-template.md` for web-service)는 디렉토리에 추가.
