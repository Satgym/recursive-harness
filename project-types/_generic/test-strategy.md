# Test Strategy Skeleton — _generic

> Blueprint §5 / §6의 시작점. 도메인 특화 정보는 project-type별 파일을 참조 (web-service 등).

## 1. Test pyramid

```
            [E2E / Manual / GUI]   ← 가장 적게, 비싸지만 가장 사용자에 가까움
          [Integration]            ← 모듈 boundary 검증
       [Unit]                      ← 가장 많이, 빠름
```

각 층의 비율은 도메인에 따름. 일반 가이드: unit ~70% / integration ~25% / e2e ~5%.

## 2. Unit
- 도구: 언어별 표준 (pytest / jest / cargo test / go test)
- 위치: `tests/<module>/` 또는 `<module>/__tests__/`
- 정책: happy path + error path + boundary, 각 케이스에 하나 이상
- Mock vs real: 외부 의존성은 mock, 내부 로직은 real

## 3. Integration
- 도구: 위와 같거나 testcontainer / 임시 sandbox
- 무엇을: 모듈 ↔ 모듈, 모듈 ↔ DB/외부 mock
- fixture: 시드 데이터·환경

## 4. E2E / Manual / GUI
- E2E: 가능하면 자동 (Playwright / Selenium / cypress / locust)
- Manual: 명확한 step-by-step + 스크린샷 비교 (capture 디렉토리: `.harness/screens/<date>-<scenario>/`)
- GUI 검증: 화면 캡쳐를 *파일로 저장*해 사용자가 직접 확인 가능

## 5. Pre-review-gate 적용
`scripts/pre-review-gate.sh`가 lint + typecheck + unit + (해당 시) integration까지 자동. e2e는 별도 호출 (CI 또는 사용자 명시).

## 6. 디버그 hook (작업 영역 상시 출력)
모든 작업 중인 영역에 다음 중 하나 이상의 상시 가시화:
- 구조화 로그 (key=value 또는 JSON), 약속된 prefix
- 콘솔에 직접 dump (개발 모드 only)
- metric counter / gauge
- breakpoint hooks

## 7. 재현성
- 랜덤 시드 고정
- 환경 캡쳐: `requirements.txt` / `package-lock.json` / `Cargo.lock` commit
- 컨테이너 / nix / asdf 같은 환경 격리 도구 명시
- fixture 데이터는 repo 안에 또는 명시된 hash로
