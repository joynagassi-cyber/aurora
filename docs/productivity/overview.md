# Productivity Module — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 2). Authority: ADR §2, spine AD-7/AD-8/AD-14,
`01-backend` §4.1, `03-sync` §4.2 (frozen single-writer mapping), `05-design-system` §4.3–4.5.

1. **Purpose** — the user's operative system: capture, organize, plan, execute, track,
   review, improve (the Capture→…→Improve loop, ADR §2). Answers "what matters now?" on
   Home (AD-14 invariant, 05 §4.1).
2. **Responsibilities** — Inbox & quick capture; tasks/subtasks (statuses, priorities,
   Eisenhower, estimates vs actual time, dependencies, recurrence materialized,
   postponements history); projects (Gantt/Kanban/Timeline/List/Calendar views,
   milestones, reusable templates); goals (short/medium/long, goal→project→task
   hierarchy); habits & routines (regularity + adherence analytics); calendar/agenda/
   time-blocking (conflict & overload detection, agent-assisted replanning); reviews
   (daily/weekly/monthly, decision journal); personal analytics (planned vs actual
   load, procrastination trends, overload detection); resource library metadata; **Focus
   sessions** (see [focus-mode/spec.md](../focus-mode/spec.md)).
3. **Non-responsibilities** — learning content (Learning), knowledge structure
   (Knowledge), capability measurement (Progress — Productivity emits `TaskCompleted` /
   `GoalUpdated`; Progress aggregates), agent memory (Agent). Never writes another
   module's tables (AD-2).
4. **User flows** — capture anywhere (Inbox → triage → object); plan day (agenda +
   time blocking from actual available time); prioritize (**Eisenhower matrix — see
   [eisenhower.md](./eisenhower.md)**: quadrant view + agent-assisted, explainable
   re-prioritization, ADR §2.3); execute (focus session + task execution + Pomodoro
   timer); review (daily/weekly/monthly bilan + next actions, incl. weekly
   "Révision des priorités"). Entry points per screen: 05 §4.3–4.5
   (project/goal/habit screens, calendar & focus, reviews & analytics).
5. **Architecture** — vertical slice in `apps/mobile/src/features/productivity` (6 layers,
   02 §4); use-cases emit partial `DomainCommand`s (e.g. `completeTask(id)`) →
   `LocalCommandRepository.apply('productivity', …)` (single-writer, AD-7/F-03); reads =
   `LocalQueryRepository` only (SQLite first, AD-7).
6. **Domain model** — `Task, Event (calendar), Project, Goal, Milestone, Habit, Routine,
   Note, Resource, Decision, FocusSession, UserContext` (AD-15 SSoT `packages/domain`;
   local tables 03 §4.2: `tasks, events, projects, goals, milestones, habits, routines,
   decisions, focus_sessions, user_context`; recurrence materialized for sync).
7. **Application services** — use-cases per screen family (02 §4: `TaskUseCase`
   `completeTask/rescheduleTask/toggleTaskSubTask` …; one command per mutation,
   no multi-table write from one use-case, AD-7).
8. **Ports / interfaces** — domain commands (SSoT `packages/domain`); `FocusController`
   port for focus sessions; consumes `GoalUpdated`/`TaskCompleted` producers (01 §3.3).
9. **Adapters** — `packages/data` repositories (PowerSync/SQLite), platform adapters for
   local notifications (due reminders, 04 §3.2.5), G2 bilan rendering via `packages/ui`.
10. **Data model** — server: 01 §4.1 (per-module schema, RLS by `user_id`); local: 03
    §4.2 mirror (no cross-module joins).
11. **API** — no direct HTTP from the UI (local-first); server Edge Functions are
    consumed via jobs/events, not from screens (02 §9: render path is network-free).
12. **Events** — produces `TaskCompleted` (consumers: Progress, Learning, Agent) and
    `GoalUpdated` (Progress, Agent) — declared in the Productivity Contract Pack (AD-13).
13. **Jobs** — daily/weekly review preparation, analytics aggregation = persisted jobs
    (AD-8, kinds per `job_queue` vocabulary, `packages/domain`).
14. **Permissions** — none beyond app scope (no native roles for Productivity proper;
    Focus needs `POST_NOTIFICATIONS` optional — see permission-matrix).
15. **Security** — RLS per user (01 §2.2); no secrets; decision journal = user data,
    synced server-wins.
16. **Offline behavior** — fully functional locally (tasks, calendar, focus timer,
    habits); mutations queued for upsync; `offline` = first-class state (AD-7, 02 §7).
17. **Error handling** — `ApiEnvelope`/`AppError` (module-prefixed codes, 01 §3.1); 5
    UX states per screen (02 §7); multi-table write = blocking finding.
18. **Recovery** — local store is the mirror; re-sync after long outage (03 §5.5);
    crash recovery = relaunch reads local (04 §6.1).
19. **Observability** — Sentry (perf SLOs, 02 §9.4) + PostHog (feature usage); review
    screens report planned-vs-actual (01 §6).
20. **Tests** — use-case command tests (single command per mutation, 02 §11), RLS
    penetration (01 §7), E2E "create → complete task" (02 §11), Focus scenarios
    (focus spec §11).
21. **Known limitations** — Focus blocking = platform limitation (NOT POSSIBLE on
    consumer Android, G-P1); time blocking quality depends on user-entered available
    time; Eisenhower assistance = agent recommendation, never silent re-prioritization.
22. **Dependencies** — `packages/domain` (types+commands), `packages/data` (repos),
    `packages/ui` (components/G2), platform adapters; events per AD-9.
23. **Future evolution** — Phase 2 desktop reuses slices; automation (AD-15 `Automation`
    = Integrations-owned) may trigger Productivity changes via jobs.
