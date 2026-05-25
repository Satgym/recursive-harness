# Module Skeleton — _generic

> Blueprint §3 Modules 작성 시 출발점. 도메인 모르면 *작은 책임*으로 시작 후 확장.

## 기본 모듈 후보 (대부분의 프로젝트)

> **의존 컬럼 = "depends-on"** (`A depends-on B`는 *A가 B의 API를 호출*한다는 의미. caller → callee).

| Module | 책임 | depends-on (이 모듈이 호출하는) |
|---|---|---|
| `M-core`     | 도메인 비즈니스 로직 (가장 stable 코어). storage *port/interface*를 소유 | — |
| `M-io`       | 입출력 (HTTP / CLI / file / network) | M-core |
| `M-storage`  | M-core의 storage port *구현* (DB / file / cache) | M-core (port 정의를 import) |
| `M-config`   | 설정·시크릿 로드 (HC-7) | (외부 env / secret manager) |
| `M-observability` | 로그·metric·tracing | M-config |
| `M-tests`    | 테스트 fixture·utility | 위 전부 |

## 의존 방향 원칙

- 외부 인터페이스(M-io) → 코어(M-core). M-io가 M-core를 호출.
- **저장 의존성 역전**: M-core가 *storage port (interface/trait)*를 정의하고, M-storage가 그 port를 *구현*. 런타임 wiring 시 M-storage instance를 M-core에 주입. → 결과적으로 `M-storage depends-on M-core` (port를 import해야 하므로).
- M-config는 모든 모듈에 주입 가능. 의존 그래프에선 잎(leaf).
- M-observability는 cross-cutting: *사용*은 어디서나, *의존*은 M-config만.

```
   M-io ──▶ M-core ◀── M-storage          (M-storage가 port impl을 위해 M-core 참조)
              │
              ▼
   (M-config가 모든 모듈에 주입)
              │
              ▼
   M-observability ──▶ M-config
```

화살표는 *caller → callee* (즉 의존 방향). 사이클 발견 시 사이클 해소 절차 참조.

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
