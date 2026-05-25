---
artifact: module_plan
version: v0.1
date: <YYYY-MM-DD>
author: claude
status: draft   # draft | approved | superseded | rejected
approval:
  approver: <pending>
  approved_at: <pending>
  mode: <strict | balanced | autonomous>
  scope: <e.g. 인터페이스 + 테스트만, 구현 세부는 코드에서>
module: <module name, e.g. auth>
supersedes: <optional>
references:
  - blueprint: <path to blueprint + §M-N 식별자>
  - related_modules: [<list>]
---

# Module `<name>` — Plan

> Blueprint §M-N의 인터페이스를 *코드 작성 전에* 계약으로 고정. HC-1 (Plan-First) 준수.

## 1. Responsibility

한 문장으로 본 모듈이 *책임지는 것 / 책임지지 않는 것* 명확화.

- **Owns**: ...
- **Does NOT own**: ...

## 2. Public interface

언어/도메인에 맞춰 *정확하게* 표현:

```python
# 또는 OpenAPI YAML / TypeScript / C 헤더 / RPC schema
class AuthService:
    def login(self, credentials: Credentials) -> AuthResult: ...
    def logout(self, session_id: str) -> None: ...
```

### Errors / Edge cases
- `InvalidCredentials` — 사유 / 응답
- `Locked` — 사유 / 응답
- 시간 초과: <정책>

## 3. Internal contracts (precondition / postcondition / invariant)

| 위치 | 종류 | 내용 |
|---|---|---|
| `login()` entry | pre | credentials 객체 valid (타입 검증) |
| `login()` exit | post | AuthResult.session_id is null 또는 valid UUID |
| class invariant | inv | active session 수 ≤ MAX_SESSIONS |

## 4. Dependencies

- **다른 모듈**: <list>
- **외부 서비스**: <API / DB / 캐시 — endpoint, mock 가능 여부>
- **환경/시크릿** (HC-7): <env var name / vault path — 평문 저장 금지>
- **라이브러리**: <name@version, 라이선스 점검 여부>

## 5. Test plan

### Unit
- happy path: <테스트 케이스 N개>
- error path: <Errors 섹션 각 항목>
- boundary: <경계 입력>

### Integration
- 어떤 boundary? (DB / 다른 모듈 / 외부 mock)
- fixture: ...

### Manual / GUI / HIL (해당 시)
- 캡쳐 저장 위치: `<dir>`
- 디버그 콘솔 출력: <약속된 prefix>
- HIL: <시뮬레이터 / 실 장비>

## 6. Implementation notes

- 알고리즘 선택 / 데이터 흐름
- 성능 고려 (병목, 캐싱)
- 보안 고려 (HC-7/8 영향)

## 7. Risks & open questions

| ID | item | mitigation / 결정 필요 사항 |
|---|---|---|
| R1 | <지연 가능성> | <조치> |
| Q1 | <결정 필요> | <누가 결정> |

## 8. Definition of done (이 모듈)

- [ ] Public interface 코드가 plan과 일치 (시그니처 매치)
- [ ] 모든 unit / integration 테스트 통과
- [ ] Codex cross-review 통과 (blocker 0, major 0 또는 명시 deferred)
- [ ] STATUS.md *Approved artifacts*에 등재
- [ ] HC-7/8/9 적용 항목 검증됨
