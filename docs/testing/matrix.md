# Test Matrix (Deliverable I)

Test-class coverage per module + mandatory scenarios. Status: tests are
**specified** (in packs, AD-13 DoD) but not yet executable (no code, wave 0+).
Tooling (AI_RULES): **Vitest** (unit/domain, no DOM), **Playwright** (E2E web
target), **Capacitor smoke on device** (wave 7 QA, OQ-08: Playwright +
Capacitor driver assumed, Appium fallback).

## 1. Test classes (mission §30, mapped to packs)

| Class | Where specified | Examples |
|---|---|---|
| Unit (domain) | 01 §7 (≥80% on `packages/domain` + event handlers), 02 §11, 03 §7 | `quadrantOf`, `prioritizationSuggestion`, FSRS determinism, CRDT OR-Set merge, `DomainCommand` unions |
| Integration | 01 §7, 03 §7 | PowerSync views (static no-join test), re-sync after outage, bridge RQ↔watch, RLS per-table penetration |
| Contract | 01 §7 (events a–e), 02 §11, 04 §7.2 | AD-9 producer/consumer declaration, F-06/F-07/F-08 rules, adapter interface tests (mocked Capacitor), `JobCompleted` payload |
| E2E | 02 §11 (web), 04 §7.1 (device), wave 4 | "create → complete a task", Home AD-14 scenario, offline scenario (intercepted network), Focus session scenarios (§12 below) |
| Failure | 01 §6/§7, 03 §5.5 | job failure → `error` + retryable `jobId`; provider fallback traceability (AD-5); 429 cooldown; OCR/STT absence degradation (AD-1) |
| Permission | 04 §7.2/§3.4, permission-matrix.md | `POST_NOTIFICATIONS` first-use request (not boot), denial paths (reminders off, app keeps working), `FOREGROUND_SERVICE` OQ-04 path, DND role (if ever added) |
| Offline | 02 §11, 03 §5.9, 04 §7.1 | app usable on local reads, cloud actions disabled, re-sync on return, kill-app relaunch = state intact |
| Recovery | 03 §5.5, 04 §6.1, 01 §5.3 | long-outage re-sync, stuck-job timeout → retry, crash mid-job (idempotent resume), Focus crash recovery (spec §11.12) |
| Mobile platform | 04 §6/§7, 02 §9.1 | lifecycle rules, battery/throttle (≥5 min bg, no polling), perf budgets (≤300 Ko gz, ≤1.5 s TTI, 30 fps tree), 5 UX states on device |

## 2. Focus Mode mandatory scenarios (mission §30 — from focus spec §11)

start session · restricted-app list honored (in-app scope) · "open blocked app"
= documented limitation (restriction ≠ blocking, G-P1) · receive notification
during session (Aurora's suppressed / others' pass by design) · receive phone
call (rings as usual in V1 — G-P2) · Internet remains active (sync/AI/KB usable)
· Aurora remains usable · pause · resume · end · restore state (snapshot diff
empty within Aurora scope) · crash recovery (kill mid-session → `interrupted`
row → restore path) · permission revoked mid-session (documented degradation)
· device reboot (session row recovered, OneSignal reconciled server-side).

## 3. Spine test (consistency convention, every wave merge)

Two teams obeying only their Contract Packs produce **the same** public
contract. Blocking where: a screen misses one of the 5 states · an AD-10 engine
imported outside `packages/ui` · a re-declared domain type · a multi-table write
from one use-case (02 §11 "blocking review" list).

## 4. Recurring (drift-safe) tests

Provider-retirement test (01 §8.2 R1, recurring CI — free tiers drift, OQ-12) ·
per-kind job SLO alert checks (AD-16d) · RLS on every migration · theme-pair
WCAG checks (wave 7, 05 §7.2).

## 5. Systemic test classes (mission §59 — beyond per-feature classes)

| Class | Scenario shape | Where specified / example |
|---|---|---|
| Feature alone | one capability, end-to-end on local data | 02 §11 E2E ("create → complete a task") |
| Feature → Feature | chain integrity (command/event/view hand-off) | W-chains in workflows/composite-workflows.md (each workflow = one systemic test at wave 4) |
| Agent → Feature | NL intent → capability plan → module effects | agent/e2e-agent-scenarios.md (20 scenarios) |
| Feature → Agent | module events/context feeding kernel decisions | `TaskCompleted` → re-plan (W3), `SkillStateChanged` → targeted revision (W7) |
| Frontend → Backend | command/query chains incl. optimistic + upsync | page-contracts.md §1–§3 (per-feature rows) |
| Backend → external provider | gateway + fallback + 429 + data-policy | 01 §7 AI suite; providers pages (failure modes) |
| Offline → online | state convergence on reconnect | 03 §7 re-sync test; 02 §11 offline test |
| Failure → fallback | provider down / job failed / OCR absent | 01 §6/§7; 04 §7.4 degradation tests |
| Disabled feature → graceful | registry-off feature: no route, no capability, data intact, deep link graceful | feature-registry.md §54 checklist test |
