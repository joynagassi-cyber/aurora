# Progress Module — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (waves 2–4). Authority: ADR §18 (18.1–18.8),
`01-backend` §4.4, `03-sync` §4.2, spine AD-6/AD-9 (F-07: Progress = sole producer of
evidence events).

1. **Purpose** — measure *real transformation*, not counters (ADR §18): where am I
   really; what really improved; what stagnates/regresses/is forgotten; why; which
   next action yields the most useful progress.
2. **Responsibilities** — the five fundamental questions (18.1); dimensions: academic
   (discovered→understood→recallable→fragile→mastered→forgotten per chapter/concept/
   formula/method + exercise rates, autonomy), skill transformation scale
   (discovery → understanding → recall → guided application → autonomous application →
   new problems → mastery → expertise, each tied to evidence + level + freshness +
   confidence), real-vs-illusion progress (recognition scores vs recall/transfer),
   time-scale views (7d/30d/semester/year/multi-year, trajectories over percentages),
   goal progress (Goal → Skills → Projects → Tasks → Evidence, milestones actually
   reached), professional progression (documented gaps to target-job requirements,
   remediation paths — never a single artificial global score), forgetting &
   consolidation (FSRS data + recent performance), discipline & execution
   (punctuality, regularity, postponements, planned vs actual duration, interruptions,
   deep work, recovery after failure; **causes of gaps, not just counts**, 18.2).
   Evidence model (18.3: QCM, active recall, standard/new exercise, personal
   explanation, error correction, project, professional application, successful
   repetition; minimum data = skill/goal, observed level, evidence, date, freshness,
   context, confidence). Causal analysis (18.4: strategy, time available, regularity,
   difficulty, load, interruptions, resource quality, recurring errors, prior
   understanding, plan changes — correlation ≠ causation discipline). Conditional
   trajectories (18.5: maintain current pace / more time / strategy change / reduced
   load / unblock — planning aids, **not predictions**). Dashboards (18.6:
   today/week/month/trajectory boards). Agent-engine role (18.7: Progress feeds
   orchestration — gap → revision/exercise/search/new task/plan adaptation;
   stagnation → cause analysis before new recommendation; reproducible success →
   Expert Skill after validation).
3. **Non-responsibilities** — writing Knowledge tables (emits-only, AD-6/F-02:
   `NodeState` updates are Knowledge's, consuming Progress events); creating evidence
   for others (`ProgressEvidenceCreated` is Progress-produced, F-07); learning
   execution (Learning).
4. **User flows** — progress dashboard (today: major progress / main blockage / next
   action; week; month; trajectory), skill-map view (G2 `DataVisualizationRenderer`),
   "why did I stagnate?" causal drill-down, "what next?" action surface.
5. **Architecture** — server-side aggregation jobs (evidence qualification, skill-state
   recompute, trend rolling); device mirrors limited to `skill_states` +
   `progress_snapshots` (03 §4.2 mirror rule — `progress_evidences`, `progress_events`,
   `progress_trends` are server-only).
6. **Domain model** — `ProgressSnapshot`, `ProgressEvidence`, `SkillState` (level,
   freshness, confidence, evidence, history), `ProgressEvent` (significant learning /
   execution / error / success / change events), `ProgressTrend` (period aggregate),
   `Gap`, `TrajectoryScenario` (conditional state+assumptions+actions).
7. **Application services** — dashboard use-cases (read mirrors; scenario view =
   server job on demand).
8. **Ports / interfaces** — consumes 4 events (`TaskCompleted`, `FlashcardReviewed`,
   `GoalUpdated`, `DiscoveryItemCreated`); produces 2 (`ProgressEvidenceCreated`,
   `SkillStateChanged`) — declared consumers only (AD-9 matrix).
9. **Adapters** — aggregation workers (jobs), G2 chart adapters via `packages/ui`.
10. **Data model** — 01 §4.4 (`progress_*` tables + `gaps`; `progress_events` =
    Progress's Event History, server-only, F-10).
11. **API** — job outputs + PowerSync mirrors; no UI→HTTP.
12. **Events** — produces `ProgressEvidenceCreated` (consumers: Knowledge →
    `NodeState`, Agent → context) and `SkillStateChanged` (consumers: Agent → expert
    skills, Discovery → competence profile, Learning → targeted revision).
13. **Jobs** — `skill_recompute` (triggered by `progress_evidences` inserts, 01 §5.2),
    trend rolling, trajectory scenario computation.
14. **Permissions** — none (analytical read-heavy).
15. **Security** — RLS per user; trajectories stay personal (no cross-user analytics
    in V1).
16. **Offline behavior** — dashboards read mirrors offline; new scenarios/aggregates
    wait for connectivity.
17. **Error handling** — stale mirror = `offline`/stale state surfaced (02 §7);
    recompute jobs idempotent.
18. **Recovery** — mirrors resync; aggregation re-runnable (idempotent).
19. **Observability** — recompute SLOs, dashboard render perf (02 §9), evidence
    coverage metrics (progress quality, not just quantity).
20. **Tests** — sole-producer test (F-07, 01 §7(e)), mirror-scope test (03 §7: only
    `skill_states`/`progress_snapshots` mirrored), deterministic recompute tests.
21. **Known limitations** — causal analysis is probabilistic, not deterministic (ADR
    §18.4 discipline); forgetting detection depends on FSRS + recent-performance
    availability; professional benchmarks depend on external reference data.
22. **Dependencies** — Learning (events), Productivity (`GoalUpdated`), Discovery
    (measurement), Agent (consumption), Knowledge (state writer).
23. **Future evolution** — Event Sourcing explicitly excluded from V1 (spine);
    multi-year longitudinal analytics; professional benchmark feeds.
