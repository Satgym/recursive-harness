# Phase 01 — Blueprint

> 전체 밑그림. **모든 모드에서 사용자 승인이 필수**인 유일한 phase (ADR-004 v0.2). 코드 작성 전 마지막 의도 확인 게이트.

## Entry 입력

- `.harness/docs/intake.md` (00 Intake 산출물)
- `.harness/config.toml`
- **`.harness/capabilities.md`** (v0.6 — Active local capabilities; HARNESS §13.3). Active 비어있으면 그 사실을 명시. Blueprint 작성 시 Active local skills/roles의 체크리스트·도메인 룰을 *반드시 고려*.
- Active 섹션에 명시된 모든 local skill / role 파일 (Working set 포함)
- (선택) 참조 시스템 / 기존 코드베이스

## Activities

1. **BLUEPRINT 인스턴스화** — `cp templates/BLUEPRINT.template.md .harness/docs/blueprint.md` 후 9개 섹션 모두 채움 (Goals/Non-goals / Constraints / Modules / Dependency graph / Test strategy / Observability / Risks / Open questions / 승인 체크).
2. **모듈 경계 결정** — 모듈 ≥ 3개. 각 모듈은 책임 1문장으로 표현 가능. 인터페이스 in/out 식별.
3. **의존성 그래프** — 사이클 금지. 사이클 발견 시 모듈 분할 또는 이벤트화로 해소.
4. **테스트 전략 전역** — Phase 00의 테스트 환경 약속을 구체화. unit / integration / e2e / manual-or-GUI / HIL 별 위치와 도구.
5. **Observability** — 구조화 로그 형식, redaction(HC-7), 디버그 hook 약속.
6. **Risks** — likelihood × impact 매트릭스, 각 risk에 mitigation 명시.
7. **HC-7/8/9 영향 식별** — Blueprint 시점에서 시크릿 / 외부 mutation / destructive 작업이 발생할 모듈 / 시점을 사전 명시.
8. **(v1.1+) Cross-cutting invariants 식별 의무** — split 여부와 무관하게 *모듈 경계를 가로지르는 invariant*를 BLUEPRINT §X에 명시. Fleet Mode 진입 시 child가 이를 *동시에* 지켜야 함. 식별되지 않으면 `none identified`로 명시 (생략 금지). HARNESS §14.2 Fleet F2.
9. **Expected module set 고정** — Blueprint §3 Modules 표에 *모든 예상 모듈 ID*를 한 번에 열거 + `.harness/docs/modules/index.md`에 같은 set을 캐노니컬 list로 기록 (Phase 02 split-decision의 "마지막 plan" 판정 근거). 후속 phase에서 모듈 추가/제거 시 Blueprint amend ADR 필수.
10. **Codex 리뷰 의뢰** — `scripts/codex-exec-review.sh --phase 01-blueprint --slug initial --prompt-file <prompt>`로 codex-reviewer 검토 요청. 결과는 `.harness/reviews/01-blueprint-<date>-initial.md`.
9. **리뷰 finding 처리** — blocker = 0, major resolved/deferred 명시.

## Outputs

- `.harness/docs/blueprint.md` (front-matter `artifact: blueprint`, `status: approved`)
- `.harness/reviews/01-blueprint-*.md` (Codex 리뷰)
- (필요 시) 결정에 대한 ADR

## Exit 기준

- [ ] BLUEPRINT 9개 섹션 모두 채워짐
- [ ] 모듈 ≥ 3 (Phase E dogfood 기준에 부합)
- [ ] 의존성 그래프 사이클 없음
- [ ] 테스트 전략 실행 가능 (도구 / 위치 명시)
- [ ] HC-7/8/9 영향 항목 식별됨
- [ ] **(v1.1+) Cross-cutting invariants 명시** (Fleet F2 — `none identified`로라도 명시; 생략은 양식 위반)
- [ ] **(v1.1+) Expected module set이 Blueprint §3 + `.harness/docs/modules/index.md`에 캐노니컬 기록**
- [ ] Open questions 모두 답 또는 명시적 deferred
- [ ] **Codex 리뷰 받음** (ready_for_next_phase=yes 또는 yes_with_minor_fixes)
- [ ] **사용자 승인** (모든 모드)
- [ ] STATUS Approved artifacts에 blueprint 등재 (Approval record 6필드)

## 주도 역할

- **claude-implementer** (작성·반영)
- **codex-reviewer** (Codex 리뷰)
- **user** (최종 승인 — 모든 모드)

## 발생 가능한 드리프트 / 위험

- ❌ 모듈을 "나중에 쪼개기" 위해 추상화로 미룸 → 의존성 사이클 / 무한 책임
- ❌ HC-7/8/9 영향을 "구현 시 발견" 처리 → 사후 사용자 승인 누락 사고 가능
- ❌ Codex 리뷰 통과 없이 다음 phase 진입 (HC-4 위반)
- ❌ Blueprint 작성 도중 사용자가 새 요구 추가 → intake 부족 신호, 00으로 일시 회귀

## 다음 phase

[02-module-plan.md](02-module-plan.md) — Blueprint의 각 모듈을 하나씩 plan 작성.
