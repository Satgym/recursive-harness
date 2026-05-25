# Intake Checklist — _generic

> Phase 00에서 `cp project-types/_generic/intake-checklist.md .harness/docs/intake.md` 후 채움. 답이 모호하면 *명시적 deferred*로 표시 (`<deferred — 결정 시점/조건>`).

## 1. 무엇을 만드는가 (Identity)
- One-line: ...
- Project type 후보: _generic (현재) → 후에 특화 type으로 옮길 가능성
- 도메인: ...

## 2. 누구를 위한가 (Stakeholders)
- 1차 사용자: ...
- 2차 이해관계자: ...
- 누가 결정권자인가: ...

## 3. 왜 (Motivation)
- 비즈니스 / 연구 / 학습 동기: ...
- 측정 가능한 성공 기준: ...

## 4. 절대 안 되는 것 (Non-goals)
- ...
- ...

## 5. 제약 (Constraints)
- **기술**: 언어 / 런타임 / 호스팅 / 라이브러리 제한
- **비용**: 토큰 / 컴퓨트 / 외부 서비스
- **시간**: 데드라인 / 마일스톤
- **규제·법**: PII / GDPR / 라이선스 / 표준
- **인력**: 누가 어디까지 (현재 1인 + 에이전트)

## 6. 테스트·검증 환경 약속 ⭐ (필수)
> Intake에서 *반드시* 명시. Phase 01 Blueprint §5/§6 작성의 기초.

- **자동 테스트**: unit / integration / e2e — 어떤 도구로 어떻게
- **수동·시각 검증**: 화면 캡쳐 / 콘솔 prefix / 결과물 비교 / 로그 grep
- **재현성**: 시드 / 컨테이너 / fixture / 버전 lock
- **디버그 hook**: 작업 중인 영역에 상시 출력하는 로그 / metric / breakpoint 약속

## 7. 관측·로깅 (Observability)
- 구조화 로그 형식: ...
- redaction 규칙 (HC-7): 어떤 필드가 시크릿·PII인지
- metric / tracing 후보: ...

## 8. 보안·외부 영향 사전 식별 (HC-7/8/9)
- 시크릿 / 자격증명이 발생하는 영역
- 외부 mutation 작업 (push / deploy / API write / message send) 발생 시점
- Destructive 작업 (DB drop / 파일 삭제 / 무효화) 발생 시점

## 9. Open questions (Blueprint 단계로 carry)
- Q1: ...
- Q2: ...

## 10. Strictness 선택
- 모드: `strict | balanced | autonomous` (기본 strict)
- 이유: ...
