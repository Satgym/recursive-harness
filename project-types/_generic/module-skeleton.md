# Module Skeleton — _generic

> Blueprint §3 Modules 작성 시 출발점. 도메인 모르면 *작은 책임*으로 시작 후 확장.

## 기본 모듈 후보 (대부분의 프로젝트)

| Module | 책임 | 의존 |
|---|---|---|
| `M-core`     | 도메인 비즈니스 로직 (가장 stable 코어) | — |
| `M-io`       | 입출력 (HTTP / CLI / file / network) | M-core |
| `M-storage`  | 영속화 (DB / file / cache) | M-core |
| `M-config`   | 설정·시크릿 로드 (HC-7) | (외부) |
| `M-observability` | 로그·metric·tracing | M-config |
| `M-tests`    | 테스트 fixture·utility (코드는 아님) | 위 전부 |

## 의존 방향 원칙
- 외부 인터페이스(M-io) → 코어(M-core) → 저장(M-storage). 역방향 금지.
- M-config는 모든 모듈에 주입.
- M-observability는 cross-cutting (사용은 어디서나, 의존은 M-config만).

## 모듈 인터페이스 표현

각 모듈은 [templates/MODULE-PLAN.template.md](../../templates/MODULE-PLAN.template.md) §2 Public interface에 *언어 시그니처*로 표현:
- Python: `class`/`Protocol`/`@dataclass`
- TypeScript: `interface` / `type`
- Rust: `trait` + struct
- Go: interface + struct
- C: 헤더 (`.h`)

## 모듈 경계 판단 휴리스틱

- "이 모듈만 바꿔도 다른 모듈은 그대로인가?" — 그렇다면 경계 적정.
- "데이터 흐름이 한 방향인가?" — 양방향이면 사이클 후보.
- "테스트가 boundary 통과를 검증하는가?" — 아니면 모듈 의미 약함.

## 사이클 해소

순환 의존이 발견되면:
1. 공통 코어 추출 (위로 빼서 양쪽이 의존)
2. 이벤트 / pub-sub로 분리
3. 인터페이스 역전 (DI)

세 방법 모두 실패하면 모듈 정의를 다시 보기 (drift 신호).
