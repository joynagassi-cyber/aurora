# Eisenhower Matrix — Technical Specification

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 2, Productivity slice). Authority: ADR §2.3
(Priorisation: "Matrice d'Eisenhower", "Priorité manuelle", "Priorisation assistée selon
échéance, impact, effort, dépendances, importance, urgence et temps disponible",
"Détection des tâches critiques ou bloquantes", "Réévaluation quand le contexte change",
"Explication par l'agent de ses recommandations"), `01-backend` §4.1 (`tasks` schema),
`05-design-system` §4.1 (Home "Priorité principale", AD-14) and §4.3–4.5 (list
sort/filter by priority, weekly "Révision des priorités").

**Coverage note (G-DOC-05):** the Eisenhower matrix exists only in ADR §2.3 — no pack
section designs it and the 05 screen inventory has no quadrant screen (05 §4.3–4.5
reference priority only as sort/filter). This page is the prescriptive design; ratify the
quadrant view addition with the Productivity + Design System teams before the wave-2
feature cut (additive per Consistency Conventions).

## 1. Purpose

A prioritization lens over tasks: separate *urgent* (time pressure) from *important*
(contribution to goals), so the user — and the agent's recommendations — act on the right
thing next. The matrix complements, never replaces, the task lifecycle
(`todo/doing/blocked/done/cancelled`, 01 §4.1).

## 2. Responsibilities

- Quadrant classification of tasks (computed, not stored — §3).
- Manual priority (`Task.priority`, AD-15) as the user's override.
- Agent-assisted prioritization: recommendation inputs = due date, impact (goal
  link), effort (estimate vs `actual_minutes`), dependencies (blocking), importance,
  urgency, available time (calendar/time-blocking) (ADR §2.3) — the agent **explains
  its recommendation** (which signals it used; ADR §2.3 "Explication par l'agent de
  ses recommandations").
- Detection of critical/blocking tasks: a task whose `dependencies[]` are `blocked`,
  overdue criticals, and cascades on linked goals/milestones (01 §4.1 relations
  goal → project → task).
- Re-evaluation on context change: new due date, dependency completed/blocked,
  estimate overrun, changed available time → the agent proposes a re-prioritization;
  the user confirms (ADR §5: confirmation for important actions; never silent
  re-prioritization).
- Surfaces: Home "Priorité principale" (AD-14 fixed composition, 05 §4.1 — the Q1
  surface), project list sort/filter (05 §4.3), weekly review "Révision des
  priorités" (05 §4.5), and the **quadrant view** (G-DOC-05, new screen proposal).

## 3. Non-responsibilities

- Not a task status (lifecycle stays `todo/doing/blocked/done/cancelled`).
- Not a second source of truth: quadrants are **computed** from AD-15 fields; the
  only stored priority data are `Task.priority` (manual) + `Task.importance` +
  `Task.due_at` + `Task.dependencies[]` (01 §4.1). No `urgency` column exists in
  the schema — urgency is **derived** (§6).
- Not scheduling: time-blocking/calendar owns *when*; the matrix owns *what first*.

## 4. User flows (mission §29: entry → intent → states)

```
Entry: project screen "Matrix" tab (proposed G-DOC-05) OR Home "Priorité principale"
Intent: "what should I do first?" / "what matters but isn't burning?"
  → UI state: loading (local skeleton, AD-7) → success (4-quadrant grid, 44px
    items, theme tokens only — 05 §5.1 theme/semantic rule: quadrant accents come
    from the active theme, success/warning/danger tokens stay semantic)
  → empty: no tasks in quadrant → CTA "capture" / "plan" (never a dead quadrant)
  → error: store fault (rare) + retry
  → offline: fully functional (local mirror, AD-7); agent-assisted
    recommendations degrade to local rule-based suggestions (no server needed for
    the quadrant computation itself)
  → permission denied: none (feature needs no native permission)
  → recovery: after crash/kill, quadrant re-derives from the local store (04 §6.1)
```

Agent-assisted loop (wave 3): `context change (due/dependency/estimate/available
time) → Agent proposes re-prioritization + rationale (signals listed) → user
confirms/rejects → TaskUpdateCommand(s) (single-writer partials, 02 §4) →
Home/quadrant update`.

## 5. Architecture

- **Domain (SSoT `packages/domain`, Productivity owner)**: a pure function
  `quadrantOf(task: TaskRow, now: Date): Quadrant` (declared view over AD-15 types,
  AD-15 projection rule — never a new entity) + a rule-based recommendation
  function `prioritizationSuggestion(tasks, calendar, goals): Suggestion[]`
  (deterministic, unit-testable, no DOM — Vitest per AI_RULES). Quadrant type:
  `q1_do | q2_plan | q3_minimize | q4_defer`.
- **Feature slice** (`apps/mobile/src/features/productivity`): matrix view reads
  `LocalQueryRepository` only (AD-7); re-prioritization applies via
  `LocalCommandRepository.apply('productivity', TaskUpdateCommand)` — one partial
  command per task (single-writer, AD-7/F-03; no multi-table write).
- **Agent (wave 3)**: impact analysis ("if this slips, which goals?") = a
  persisted job (AD-8) or kernel call (`fn-agent-run`); the agent never writes
  priority directly — it proposes, the owning module applies (kernel Action step,
  AD-7/F-03).

## 6. Domain / data model (01 §4.1 fields, mapped)

| Eisenhower input | Source | Notes |
|---|---|---|
| Importance | `Task.importance` (explicit) — fallback: linked goal horizon/criticality (01 §4.1 `goals`) | user-declared or inferred from goal link (inference flagged as agent suggestion, not stored silently) |
| Urgency | **derived** from `Task.due_at` vs now: overdue / due-today / due-48h → urgent band; plus `Task.status = 'blocked'` as a urgency flag | no stored `urgency` column (documented: keep the schema lean, recompute is cheap; if the team wants persistence, additive AD-15 field, wave-2 decision) |
| Effort | estimate vs `actual_minutes` (overrun ratio) | ADR §2.3 "effort" |
| Dependencies | `Task.dependencies[]` + `status = 'blocked'` of the dependency (blocking detection) | ADR §2.3 "dépendances", "tâches critiques ou bloquantes" |
| Impact | goal link (`goal_id`) + milestone proximity | ADR §2.3 "impact" |
| Available time | calendar/agenda + time blocks (Productivity data) | ADR §2.3 "temps disponible" |

Quadrants (single-user suite — "delegate" reinterpreted):

| | Important | Not important |
|---|---|---|
| **Urgent** | **Q1 DO** — do now (Home "Priorité principale" = top Q1 item, AD-14) | **Q3 MINIMIZE** — time-box / batch / hand off outside Aurora (e.g. via Integrations) / accept as noise |
| **Not urgent** | **Q2 PLAN** — schedule explicitly (time blocking); the "critical progress" of Home is Q2 health | **Q4 DEFER** — clear out, revisit at next review; candidate for cancellation |

## 7. Application services / ports / adapters

- Use-case `prioritizeUseCase` (02 §4 layer): reads tasks+calendar+goals locally →
  `quadrantOf` per task → view model; agent-suggestion merge (when available).
- Ports: `TaskUseCase` (existing), `LocalQueryRepository`, `LocalCommandRepository`;
  agent side: kernel Capability (Tutor/Planner) behind `AgentRunState` (F-09).
- Adapters: repositories (`packages/data`); G2 optional sparkline of Q2-health over
  time (05 §4.5 analytics, `DataVisualizationRenderer`).

## 8. API / events / jobs

- No UI→HTTP (local-first). No dedicated AD-9 event: quadrant changes ride
  `TaskCompleted` / `GoalUpdated` consumers (Agent re-plan, AD-9 matrix) — creating
  a new event would violate AD-9 (9-event discipline, 01 §3.3).
- Jobs: optional `prioritization` kind for heavy impact analysis (AD-8); the
  in-app matrix itself needs no job.

## 9. Permissions / security

- None beyond app scope (no native role). RLS standard (01 §2.2); suggestions are
  advisory and user-confirmed (ADR §5) — no destructive auto-action.

## 10. Offline / errors / recovery

- Offline: matrix fully functional (local mirror); agent suggestions unavailable
  → rule-based local suggestions (documented degradation, AD-1 last paragraph).
- Errors: store fault = `error` state + retry (02 §7); suggestion failure = matrix
  remains (suggestion is additive UI, not critical path).
- Recovery: quadrant re-derived on relaunch; confirmed re-prioritizations are
  already persisted (single-writer writes).

## 11. Observability

- Q1-overdue count, Q2 share of scheduled time, suggestion acceptance/rejection
  rate (PostHog; SLO: quadrant render < 100 ms on reference device, 02 §9.1
  budgets).

## 12. Tests

- Domain unit (Vitest, no DOM): `quadrantOf` determinism (due bands, blocked flag,
  importance fallback), `prioritizationSuggestion` signal coverage (each ADR §2.3
  input changes the output predictably).
- Single-writer: re-prioritization = one `TaskUpdateCommand` partial per task (02
  §11 use-case test).
- UI: 5 states × quadrant view (02 §7); 44px targets + theme-token-only colors
  (05 §2/§5.1); offline (intercept network, matrix still renders from local).
- E2E wave 4: "context change (dependency completes) → agent proposes move → user
  confirms → Home priority updates" scenario.
- Agent: explanation contract — every accepted suggestion lists its signals
  (ADR §2.3 "Explication par l'agent").

## 13. Known limitations

- Derived urgency assumes `due_at` is kept honest (user behavior); the weekly review
  (05 §4.5 "Révision des priorités") is the correction loop.
- Single user: "delegate" (classic Q3 move) is approximated by minimize/batch/
  external hand-off (Integrations) — no multi-user delegation in V1.
- Agent quality depends on data completeness (estimates, goal links): the matrix
  degrades gracefully to a manual-priority grid when signals are missing.

## 14. Dependencies / future evolution

- Depends on: `Task`/`Goal`/`Project` (AD-15), calendar/time-blocking data, Agent
  (wave 3 suggestions). Future: Q2-health trends in reviews; habit linkage
  (recurring Q2 items → routine candidates, ADR §2.7 "déttection d'habitudes
  perturbatrices").
