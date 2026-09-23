# Master Feature Catalog (master mission §4 — every feature, full integration chain)

Status note: design phase — statuses are DESIGN-level (mission §0 vocabulary:
DESIGNED_ONLY = chain fully specified, no code; NEEDS_DECISION = a chain link is
awaiting a decision; PLATFORM_DEPENDENT = capability depends on a platform
condition; PARTIAL = a chain link is not yet specified anywhere). No feature is
"integrated" (mission §0 absolute rule: nothing is declared integrated without a
complete owner→…→tests chain in code). Columns: **ID · owner · purpose/user value ·
sub-features · inputs→outputs · data · backend contract · frontend entry · agent
capability · dependencies · events · jobs · permissions · platform dependency ·
activation/deactivation · states · tests · limitations · status**.
Details = the doc that carries the prescriptive chain (the "full chain" evidence).

## Productivity family (owner: Productivity module; screens 05 §4.3–4.5)

| ID | Chain (abbreviated; full fields per family below) | Doc |
|---|---|---|
| `productivity.inbox` | capture→triage→objects; In `tasks/notes/events` commands; out = organized objects; data: 01 §4.1; entry: /inbox + global capture; agent: `task.create` (full); events: `TaskCompleted` family; no jobs; no perms; offline-capable; activation: core (always on); deactivation: not supported (core); 5 states; tests 02 §11; limitations: none major | eisenhower.md, productivity/overview.md |
| `productivity.tasks` | tasks/subtasks (statuses, estimates vs `actual_minutes`, recurrence materialized, dependencies, postponements history); agent: task.create/update FULL; offline-capable; core | 01 §4.1, 03 §4.2 |
| `productivity.eisenhower` | quadrant view + agent-assisted explainable prioritization (ADR §2.3); `quadrantOf`/`prioritizationSuggestion` domain fns; UI = quadrant screen **additive to 05 inventory (G-L5)**; tests per eisenhower.md §12; activation: feature registry (G-M7); DESIGNED_ONLY + NEEDS_DECISION (screen) | eisenhower.md |
| `productivity.calendar` | agenda/time blocking/conflict+overload detection; agent: calendar.schedule CONFIRMATION_REQUIRED; `POST_NOTIFICATIONS` first-use; offline-capable | 01 §4.1, 05 §4.4 |
| `productivity.projects` | Gantt/Kanban/Timeline/List views + milestones + templates; agent: project.create CONFIRMATION_REQUIRED; offline-capable | 01 §4.1, 05 §4.3 |
| `productivity.goals` | short/mid/long horizons, goal→project→task hierarchy; `GoalUpdated` producer; offline-capable | 01 §4.1 |
| `productivity.habits` | daily/weekly habits + routines (temporal anchors) + adherence analytics; `HabitStreak` heatmap; offline-capable | 01 §4.1, 05 §3.6.12 |
| `productivity.focus` | focus sessions + Pomodoro + blocklist; in-app = FULL; **app blocking = PLATFORM_DEPENDENT (v1.8 DPC, OQ-17)**; calls = NOT_AGENT_ENABLED (experimental, G-P2); bilans SSoT 01 §4.1; offline-capable (device); activation: core timer, block = profile | focus-mode/spec.md |
| `productivity.reviews` | daily/weekly/monthly + decisions journal; agent: review.run CONFIRMATION_REQUIRED; offline-capable | 05 §4.5 |
| `productivity.analytics` | planned vs actual, procrastination trends, overload detection; S jobs (aggregation); offline-capable (mirrors) | 01 §4.1 |
| `productivity.library` | resource library (courses/PDFs/images/links/exercises; R2 + metadata); offline-capable (metadata + cache) | 01 §4.1 |

## Learning family (owner: Learning; 05 §4.6–4.9)

| ID | Chain | Doc |
|---|---|---|
| `learning.import` | capture (camera/audio) → R2 upload → `fn-import-course` + OCR job → KB ingestion → `CourseImported`; camera perm; online-required (ingestion); degradation: manual entry (AD-1) | 01 §5.1, 04 §3.2.3 |
| `learning.sheet` | AI study sheets (7 structures, ADR §17; fidelity: corpus-dominant + separated agent explanation + fidelity check before export); generation job + AI gateway; online-required; agent: qcm/generate FULL | 01 §4.2, ADR §17 |
| `learning.flashcards` | FSRS spaced repetition (algorithm **server**, state mirrored local, 03 §4.2); offline-capable (review) / online (generation + tick job) | 01 §4.2, 03 §4.2 |
| `learning.qcm` | QCM generation + progressive exercises + error analysis (recurring errors); online generation; PARTIAL offline | 01 §4.2 |
| `learning.coach` | in-app coach mode (check-ins ADR §13, cadence user-controlled); OneSignal server + local; PARTIAL (cadence-limited by design) | 05 §4.9, 04 §3.4 |
| `learning.mirror` | **Mirror Cognitive Mode** — designed 2026-09-22 in 01 §4.2 (G-L3 closed): server `mirror-analysis` job, typed detections + AD-11 provenance, F-07 evidence path, screen = 05 additive wave 2 | 01 §4.2, learning/overview.md §21 |
| `learning.skills` | skill tracking (mastered/fragile/missing) — data = Progress-owned `SkillState` (AD-6); Learning *reads*; activation via Progress events | 01 §4.4 |

## Knowledge family (owner: Knowledge; AD-6/AD-10/AD-11)

| ID | Chain | Doc |
|---|---|---|
| `knowledge.tree` | hierarchical semantic tree (roots/branches/nodes; bridges secondary; readability rule ADR §14); renderer = view only (AD-10); versioning `semantic_tree_version` (Knowledge-owned, AD-6); offline-capable (mirror) / online (retrieval, AD-12) | knowledge/overview.md |
| `knowledge.retrieval` | FTS + pgvector + R2 documents (server-only retrieval); `SourceRef` provenance (AD-11); online-required | 01 §4.3 |
| `knowledge.ocr` | scanner → OCR job (optional provider); degradation = manual entry; camera perm | 04 §3.2.3, 01 §5.1 |

## Discovery family (owner: Discovery; ADR §13)

| ID | Chain | Doc |
|---|---|---|
| `discovery.research` | multi-source (You.com/Tavily/Exa via `ResearchProvider`) + FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY separation (13.7); jobs; online-required; `uncertain` degradation (01 §6); agent FULL | discovery/overview.md |
| `discovery.gaps` | gap analysis (curriculum vs professional, 13.5); `Gap` definitions in domain, **rows owned by Progress** (03 §4.2) | 01 §4.5 |
| `discovery.horizons` | living history + 2030/2040/2050 scenarios (trajectories, not certainties, with sources per projection) | ADR §13.6/13.7 |
| `discovery.sheet` | durable discovery objects (13.8 fields) → Learning activities via `DiscoveryItemCreated` | ADR §13.8 |

## Progress family (owner: Progress; ADR §18)

| ID | Chain | Doc |
|---|---|---|
| `progress.dashboards` | today/week/month/trajectory boards (18.6); mirrors (skill_states, progress_snapshots — 03 §4.2); offline-capable; trends = S jobs | progress/overview.md |
| `progress.evidence` | evidence model (18.3) + sole-producer rule (F-07) + `skill_recompute` jobs | 01 §4.4 |
| `progress.cause` | causal analysis (18.4, correlation≠causation discipline) | ADR §18.4 |
| `progress.trajectories` | conditional scenarios (18.5: aids, not predictions) + forgetting detection (FSRS + recency) | ADR §18.5/18.2 |

## Agent family (owner: Agent; wave 3)

| ID | Chain | Doc |
|---|---|---|
| `agent.kernel` | one server kernel, 15 components (kernel.md §12), NL→action (§13), capability discovery (§14); `fn-agent-run` + jobs; `Verify` critical = S job; agent/expert-skills memory server-only (AD-3) | agent/kernel.md |
| `agent.capabilities.*` | registered capabilities (feature-agentability-matrix.md) — each with scopes, confirmation flags, destructive class, offline class | kernel §14 |

## Artifacts / Scientific / Integrations / Identity

| ID | Chain | Doc |
|---|---|---|
| `artifact.preview` | per-format preview (ADR §16; unsupported = no fake preview); presigned 15/5 min TTLs; USER_ONLY | artifacts/overview.md |
| `artifact.export` | sheet/infographic/figure exports (MD/PDF/DOCX/PNG, ADR §17/§25.4) = jobs + R2 + `ArtifactGenerated` post-upload (F-06) | artifacts/overview.md |
| `scientific.*` | evaluate/convert/symbolic/verify (ADR §15; LaTeX = representation; swappable engines = **NEEDS_DECISION** (engine choice, Scientific team)); light ops offline-capable, heavy = jobs | scientific-engine/overview.md |
| `integrations.automation` | Cron → dispatcher → jobs (AD-8); `Automation` owner Integrations (03 §4.2); platform: server | integrations/overview.md |
| `integrations.notifications` | OneSignal (server key, `fn-notifications`) + local split rule (never both for one object, 04 §3.4); `POST_NOTIFICATIONS` first-use | 04 §3.4 |
| `identity.session` | Supabase Auth + `UserContext` (theme v2 enum, silence windows, preferences); RLS root | modules/index.md §2 |
| `designsystem.themes` | neutral style × 10 themes × 3 presets × local adaptation (AD-17 candidate, 05 §5–6); canvas values aligned 2026-09-22 (G-H2 closed); local adaptation V1 = Focus only (OQ-15) | design-system/overview.md |
| `focus.dpc` (v1.8 candidate) | private deployment: device owner + `setPackagesSuspended` (API 29+) + provisioning procedure + boot-receiver restore; OQ-17 = **NEEDS_DECISION/PLATFORM_DEPENDENT** (blocking for freezing Focus); consumer fallback = 04 §4.1 | focus-mode/spec.md §0/§9 |

## Catalog integrity rules (mission §0)

- A feature may be cited in a narrative doc **only** with a row here (owner + chain
  links); otherwise it is `PARTIAL` by construction.
- Activation/deactivation for every feature = **feature registry**
  (docs/frontend/feature-registry.md, G-M7 NEEDS_DECISION) — before ratification,
  activation is "core = always on, optional = provider-absent degradation (AD-1)".
- Statuses above are re-run after wave 1 (DESIGNED_ONLY → IMPLEMENTED flips) and at
  each OQ ratification.
