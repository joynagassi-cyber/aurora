# Aurora — Epics & Stories (Planification Implementation)

**Status:** `DESIGNED_NOT_IMPLEMENTED`. Derived from: ADR v1.7 (adr-extract.md),
ARCHITECTURE-SPINE.md (AD-1..AD-16), SPEC.md (wave plan, OQ-01..OQ-17),
packs 01-05, docs/ (87 files, this session). One Epic per wave; Stories are
the individual deliverables within each wave. Each story has: ID, title,
description, acceptance criteria (DoD), module owner, dependencies, size
(S/M/L/XL), and wave gate.

**Patch 09/26 (implementation-readiness gaps):** W0-E2-1 split (theme JSON/provider vs 49 mockups [G-L2] → W0-E2-2) ; W2-E1-1 split (Inbox+Tasks vs Eisenhower → W2-E1-2) ; W2-E1-5 split (in-app timer vs v1.8 DPC → W2-E1-6/7) ; + FR11 W2-E1-8 Resource Library, FR23 W2-E1-9 Automations ; W2-E2-5 dé-couplé de W3 (wave-2 part, NL trigger → W3-E1-6) ; + FR16 W3-E1-7 Coach Mode ; + Epic W3-E2 Ascent (engine + Slide-Ascent feature registry, rattachement G-M7 + S-41).

Convention: story IDs = `W{wave}-{epic}-{n}` (e.g. `W0-E1-1`).
Epic IDs = `W{wave}-E{epic}`.

---

## Wave 0 — Contracts, Tokens, Types, Schemas, CI

**Gate:** OQ-01 + OQ-02 ratified; G-M7 (Feature Registry) ratified;
AI_RULES.md accepted; all 5 packs frontmatter verified; 9-event
vocabulary confirmed; 5 UX states confirmed.

### Epic W0-E1: Monorepo Scaffolding & Domain Types

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W0-E1-1 | pnpm monorepo layout | Create pnpm workspace with packages/domain, packages/data, packages/ui, packages/platform, packages/agent, packages/scientific-engine, packages/integrations, apps/mobile, apps/server | `pnpm install` succeeds; all packages have package.json + tsconfig; OQ-01 ratified | Foundation | — | M |
| W0-E1-2 | packages/domain SSoT types | Define all AD-15 entity types (Task, Event, Project, Goal, Milestone, Habit, Routine, Note, Resource, Course, Subject, Skill, LearningSession, Review, FocusSession, Artifact, Automation, Decision, UserContext, Progress*, Semantic*, SourceRef, EvidenceRef, DiscoveryItem, Gap, ExpertSkill) + envelopes (ApiEnvelope, AIResponseEnvelope, AppError [G-M3]) + commands + events (9) + FeatureDescriptor + AgentCapability + NavigationIntent | All types compile; zero vendor imports; AppError in domain [G-M3]; OQ-02 team column filled | Foundation | W0-E1-1 | L |
| W0-E1-3 | ESLint boundary rules | `import/no-restricted-paths` for all packages; `no-restricted-imports` for AD-10 engines in packages/ui; grep CI for vendor names + secrets in bundle | CI passes on clean tree; vendor name in domain/ui/apps = build failure | Foundation | W0-E1-1 | M |
| W0-E1-4 | CI pipeline (basic) | TypeScript compile + ESLint + grep checks + pnpm install on push to main | Pipeline runs on push; exit code 0 on clean tree | Foundation | W0-E1-1, W0-E1-3 | M |

### Epic W0-E2: Design System Foundations

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W0-E2-1 | Theme JSON SSoT (themes + provider) | Create `packages/ui/src/themes/` with 10 living themes + 3 presets (Slate, Nocturne, High Contrast) as JSON files; `resolveToken` TS function; `<AuroraThemeProvider>` component | G-H2 resolved (canvas values #F8FAFC / #0A0E1A); G-M5 ChartSpec shape published in 05 S3.6; provider compiles + theme switching works | DS team | W0-E1-1 | L |
| W0-E2-2 | 49 theme x screen mockups [G-L2] — CLOSED | **REJECTED 2026-09-27 (owner Joy, time/token cost)**: mockups not produced. Design follows 05 S5.7 mechanism + Lagoon×Focus example + theme tokens + docs/ui-libraries.md (S9 brand assets). No agent may start mockup production without owner re-approval | N/A (story closed, no DoD) | DS team | W0-E2-1 | XL — CLOSED |
| W0-E2-3 | DS data components (9) | Build the 9 DS data components (05 S3.6 DEF): SemanticTreeRenderer, InfographicRenderer, DataVisualizationRenderer, MathRenderer, AnimationController [G-M1: add AnimationSlot] + 4 data components | Components compile; engine imports only in packages/ui; G-M1 AnimationController wrapper added | DS team | W0-E2-1 | L |
| W0-E2-4 | Screen inventory (05 S4) | Complete the screen inventory for all modules (05 S4.1-4.9); include Mirror screen [G-L3] and Eisenhower quadrant [G-L5] as additive items | Inventory covers all module screens; AD-14 Home invariant verified | DS team | W0-E2-1 | M |

### Epic W0-E3: Backend Schemas & RLS

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W0-E3-1 | Supabase project setup (3 envs) | Create dev/staging/prod Supabase projects; RLS policies per module; `user_context` root table; `events` table (AD-9 Event History); `job_queue` + `job_logs` [G-M4 full shape] | RLS penetration test passes; no cross-module table access; OQ-03 values provided | Foundation + Data | W0-E1-1 | L |
| W0-E3-2 | Module schemas (01 S4) | Create all module tables + views + indexes (Productivity 01 S4.1, Learning 01 S4.2, Knowledge 01 S4.3, Progress 01 S4.4, Discovery 01 S4.5, Artifact 01 S4.6, Agent 01 S4.7, Identity 01 S2.1) per data-ownership-matrix.md | All tables match AD-15 types; RLS policies enforce module ownership; Progress sole-producer rule [F-07] verified | Data | W0-E3-1 | XL |
| W0-E3-3 | PowerSync relay + views | Configure PowerSync relay for all local-mirrored tables (03 S4.2 mapping); create public views for cross-module reads; no cross-module joins [03 S5.4] | PowerSync sync test passes; static view-join test passes [03 S7] | Data | W0-E3-2 | L |
| W0-E3-4 | R2 buckets + presign config | Create R2 buckets per env (AD-16a); configure presigned URL generation (15 min get / 5 min upload TTLs); ownership validation logic | Presigned URLs work; no R2 secrets in mobile bundle [AD-3]; cloudflare/r2.md spec followed | Foundation | W0-E3-1 | M |

### Epic W0-E4: Platform & Mobile Shell

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W0-E4-1 | Capacitor whitelist (04 S3.1) | Implement all adapters in `packages/platform`: AppLifecycleAdapter, LocalFileStorageAdapter, DocumentScanner, AudioArtifactProvider, RemoteNotificationAdapter (OneSignal), LocalNotificationAdapter, NetworkStatusAdapter | All adapters behind interfaces [AD-1]; OneSignal appKey in capacitor.config.ts only [AD-3]; no custom plugin outside whitelist without Foundation PR [AD-16c] | Foundation | W0-E1-1 | L |
| W0-E4-2 | Mobile shell (apps/mobile) | Ionic React + Capacitor shell; Zustand store (ui-state only, never domain entities [AD-7]); React Query bridge (03 S5.8); routing (02 S6.1); 5 UX states [AD-13] + killed [G-M2]; Home screen [AD-14] | Shell builds; navigation works; Home invariant [AD-14] renders; Zustand never holds domain data; OQ-09/10/11 assumptions verified | App Shell | W0-E1-1, W0-E2-1 | XL |
| W0-E4-3 | OQ-17 DPC provisioning (v1.8) | Factory reset target phone; install Aurora APK; `adb shell dpm set-device-owner com.aurora/.AuroraDeviceAdminReceiver`; verify `isDpcActive() = true`; run `precheckBlocklist` suspendability matrix | DPC active; suspendability matrix recorded per package; API level verified (>= 29); if fails = consumer fallback [04 S4.1] | Foundation + Productivity | W0-E4-1 | M |

### Epic W0-E5: AI Pipeline Scaffolding

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W0-E5-1 | AI pipeline contracts (9) | Implement all 9 AI contracts in `packages/domain`: AIProvider, AIModelRegistry, AIModelRouter, AIModelPolicy, AIFallbackStrategy, AIHealthRegistry, AIUsageTracker, AIBudgetManager, AIRequestGuard | Contracts compile; no concrete model names in domain code [AD-1, ADR v1.7 S1]; typed TaskProfile only | Foundation | W0-E1-2 | L |
| W0-E5-2 | Model Registry seed | Populate `model_registry` table with Agnes + Cloudflare Workers AI models (wave 1 minimum, ADR v1.7 S16); free-tier quotas = dated photograph (2026-09-21 snapshot) [G-U4]; auto-retirement test | At least 2 providers registered; quota drift CI test passes | Foundation | W0-E5-1 | M |
| W0-E5-3 | Cloudflare AI Gateway config | Configure CF AI Gateway: provider routing, model routing, fallback, retries, timeouts, rate limiting, budgets, provider health, logging, cache | Gateway routes to at least 2 providers; error normalization verified; ai/gateway.md spec followed | Foundation | W0-E5-1 | M |

---

## Wave 1 — Foundations (UI, Data, Auth)

**Gate:** W0 complete; main buildable; G1 frontmatter ratified (AD-10 signatures + Zustand).

### Epic W1-E1: UI Foundation

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W1-E1-1 | packages/ui component library | Complete DS component library (05 S3.6): 9 data components + 5 renderer contracts + theme system; G-M1 AnimationController wrapper; G-M5 ChartSpec | All components render in dev environment; theme switching works (10 themes + 3 presets); perf: 1000-node tree at 30 fps [02 S11] | DS team | W0-E2-1 (W0-E2-2 descoped 09/27 — not a blocker; story delivered) | XL |
| W1-E1-2 | Feature Registry implementation | Implement `FeatureRegistry` (feature-registry.md S1): FeatureDescriptor SSoT, registry chain (S2), deactivation effects (S6), product modes (S7) | Feature toggle works end-to-end: disable a feature -> navigation hidden, agent capability removed, data preserved, deep link shows "disabled" state | App Shell + Foundation | W0-E1-2, W1-E1-1 | L |

### Epic W1-E2: Data Foundation

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W1-E2-1 | Local-first sync (03 S3-S5) | PowerSync + SQLite local repositories; `LocalQueryRepository` / `LocalCommandRepository`; server-wins conflict rule; OR-Set CRDT for lists; upsync queue; React Query bridge (03 S5.8) | Offline read works; local write -> upsync on reconnect; CRDT merge test passes; single-writer test [AD-7] passes | Data | W0-E3-3, W1-E1-2 | XL |
| W1-E2-2 | Supabase Auth + RLS | Supabase Auth (email + OAuth); RLS policies active on all tables; `user_context` per-user isolation | Auth flow works; RLS penetration test [01 S7] passes; cross-user access blocked | Foundation | W0-E3-1 | M |
| W1-E2-3 | Job system (AD-8) | `job_queue` + `job_logs` schema; `DispatcherApi` (dispatchDue, claimJob, reportResult); Supabase Cron triggers; Postgres trigger on INSERT `job_queue`; per-kind workers | Job dispatch works end-to-end; idempotency test passes [01 S7]; OQ-04 `FOREGROUND_SERVICE` resolved | Foundation | W0-E3-1 | L |

### Epic W1-E3: Notification Foundation

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W1-E3-1 | OneSignal + local notifications | OneSignal server client (`fn-notifications`); Capacitor local notifications (`LocalNotificationAdapter`); split rule (server-state = OneSignal, local-deadline = local; never both for same object) | Push delivery works; local notifications work offline; anti-double-push test [04 S7] passes; `POST_NOTIFICATIONS` first-use (not at boot) | Integrations | W0-E4-1, W1-E2-3 | M |

---

## Wave 2 — Features (Productivity, Learning, Knowledge, Discovery, Progress, Scientific/Artifacts)

**Gate:** W1 complete; G2 mapping AD-15 frozen (02 G2); all module screens in 05 S4 inventory.

### Epic W2-E1: Productivity

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W2-E1-1 | Inbox + Task CRUD | Inbox capture/triage; Task CRUD (statuses, subtasks, estimates, actual_minutes, recurrence, dependencies, postponements) | Task create -> complete -> `TaskCompleted` event emitted; local mirror works | Productivity | W1-E2-1 | L |
| W2-E1-2 | Eisenhower quadrant [G-L5] | Quadrant view (4-quadrant grid, `docs/productivity/eisenhower.md` §4); task placement; triage filter | Quadrant renders; task moves between quadrants; theme tokens only | Productivity | W2-E1-1 | M |
| W2-E1-3 | Calendar + Time Blocking | Calendar view; time blocking; conflict detection; overload detection; `calendar.schedule` capability | Time block creation works; conflict detected; offline-capable [local mirror] | Productivity | W2-E1-1 | L |
| W2-E1-4 | Projects + Goals | Gantt/Kanban/Timeline/List views; milestones; templates; goal -> project -> task hierarchy; `GoalUpdated` event | Project CRUD works; goal hierarchy renders; `GoalUpdated` emitted on change | Productivity | W2-E1-1 | L |
| W2-E1-5 | Habits + Routines | Daily/weekly habits; routines (temporal anchors); adherence analytics; `HabitStreak` heatmap | Habit check-in works; streak heatmap renders; offline-capable | Productivity | W2-E1-1 | M |
| W2-E1-6 | Focus Mode (in-app: timer + Pomodoro) | Focus session timer; Pomodoro; `FocusController` (in-app); `FocusSessionBilan` SSoT [G-H1] | Timer works offline; bilan shape matches 01 S4.1 | Productivity | W2-E1-1 | L |
| W2-E1-7 | Focus Mode v1.8 DPC (blocklist + crash/reboot) | `FocusControllerDpc` [v1.8]; blocklist UI; `setPackagesSuspended` + restore; crash/reboot recovery [spec S7] | DPC: suspend applied + restored; 13 mandatory test scenarios [spec S13] | Productivity + Platform | W2-E1-6, W0-E4-3 | L |
| W2-E1-8 | Resource Library (FR11) | `resources` / `notes` / `documents` tables [01 S4.1]; feature catalog `productivity.library`; item types (cours/PDF/documents/images/vidéos/liens/exercices/rapports/notes); rattachement matière/compétence/projet/objectif/session; search; agent context retrieval; R2 storage [ADR S2.11] | Library CRUD works; R2 upload via presigned URL; item linked to domain entity; `ArtifactGenerated` post-upload | Productivity | W2-E1-1, W0-E3-4 | L |
| W2-E1-9 | Automations (FR23) | `Automation` entity; Supabase Cron triggers -> Aurora dispatcher -> persisted jobs [AD-8]; user-facing toggle; `integrations.automation.toggle` capability | Automation create + toggle works; cron job fires and upserts; idempotency test passes [01 S7] | Productivity + Integrations | W1-E2-3 | M |
| W2-E1-10 | Reviews + Analytics | Daily/weekly/monthly reviews; decisions journal; planned vs actual; procrastination trends; overload detection | Review flows work; analytics S jobs (aggregation) complete; offline-capable [mirrors] | Productivity | W2-E1-1 | M |

### Epic W2-E2: Learning

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W2-E2-1 | Course import (camera + OCR) | Camera capture -> R2 upload -> `fn-import-course` + OCR job -> KB ingestion -> `CourseImported` event | Camera capture works; R2 upload via presigned URL; OCR job completes; `CourseImported` emitted; degradation = manual entry [AD-1] | Learning + Platform | W1-E2-3, W0-E4-1 | L |
| W2-E2-2 | Study sheets (AI + fidelity) | 7 structures [ADR S17]; AI generation via gateway; fidelity check (corpus-dominant + separated agent explanation); export MD/PDF/DOCX/PNG | Sheet generation works; fidelity check passes; export = Artifact job + R2 + `ArtifactGenerated` post-upload [F-06] | Learning | W2-E2-1, W1-E2-3 | XL |
| W2-E2-3 | Flashcards (FSRS) | FSRS spaced repetition; algorithm **server** [03 S4.2]; state mirrored local; `FlashcardReviewed` event | Flashcard review works offline [local mirror]; FSRS tick job completes; `FlashcardReviewed` emitted | Learning | W1-E2-3 | M |
| W2-E2-4 | QCM + exercises | QCM generation (AI + fidelity); progressive exercises; error analysis (recurring errors) | QCM generation works online; error analysis identifies recurring patterns; PARTIAL offline [local items] | Learning | W2-E2-2 | L |
| W2-E2-5 | Mirror Cognitive Mode (wave-2 part) | Server `mirror-analysis` job [01 S4.2, G-L3]; typed detections + AD-11 provenance; F-07 evidence path; optional flashcard/QCM derivation; coach-screen UI family [05 S4.8/4.9] | Mirror analysis completes as server job; detections carry source refs; evidence -> `ProgressEvidenceCreated`; screen renders | Learning | W2-E2-4 | L |

### Epic W2-E3: Knowledge

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W2-E3-1 | Semantic tree (Postgres + pgvector) | Hierarchical tree (roots/branches/nodes/bridges); `SemanticTreeRenderer` [AD-10, lazy Dagre]; versioning `semantic_tree_version` [AD-6]; offline-capable [mirror] | Tree renders (1000 nodes, 30 fps); node expansion works; versioning tracks changes; offline browse via local mirror | Knowledge | W1-E1-1, W1-E2-1 | XL |
| W2-E3-2 | Retrieval (FTS + pgvector + R2) | Server-only retrieval [AD-12]; `SourceRef` provenance [AD-11]; FTS + vector search over course corpus | Retrieval returns relevant content with source refs; online-required; `KnowledgeBase` port tested | Knowledge | W2-E3-1 | L |

### Epic W2-E4: Discovery

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W2-E4-1 | Research (multi-source) | `ResearchProvider` (You.com/Tavily/Exa); FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY separation [S13.7]; `uncertain` degradation [01 S6]; research job (heavy, AD-8) | Research completes as job; results typed by category; provider absent = `uncertain` marking [AD-1]; `DiscoveryItemCreated` emitted | Discovery | W1-E2-3 | L |
| W2-E4-2 | Gap analysis + horizons | Gap definitions (domain SSoT, rows owned by Progress [03 S4.2]); living history + 2030/2040/2050 scenarios [S13.6/13.7]; discovery sheets [S13.8] | Gap analysis produces ranked list; horizons render with source refs; discovery sheet -> Learning items via `DiscoveryItemCreated` | Discovery + Progress | W2-E4-1 | M |

### Epic W2-E5: Progress

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W2-E5-1 | Evidence model + sole-producer | `ProgressEvidence` model [S18.3]; F-07: Progress = sole producer of `ProgressEvidenceCreated`; `skill_recompute` jobs; mirrors [03 S4.2] | All 6 evidence types (QCM, Exercise, Flashcard, Focus, Mirror, Project) produce evidence via Progress; sole-producer test [01 S7] passes | Progress | W2-E1-6, W2-E2-3, W2-E2-4 | L |
| W2-E5-2 | Dashboards + trajectories | Today/week/month/trajectory boards [S18.6]; G2 charts (`ChartSpec` [G-M5]); conditional scenarios [S18.5]; forgetting detection (FSRS + recency) | Dashboard renders all time windows; trajectory scenarios show as aids (not predictions); forgetting curve visible | Progress | W2-E5-1, W1-E1-1 | L |

### Epic W2-E6: Scientific Engine + Artifacts

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W2-E6-1 | Scientific engine (deterministic) | `ScientificEngine` port; evaluate/convert/symbolic/verify; LaTeX representation; swappable engines [engine choice = NEEDS_DECISION]; light ops local, heavy = jobs [AD-8] | Deterministic calc verified (units/dimensions); heavy jobs complete; `MathRenderer` renders LaTeX; engine choice documented | Scientific | W1-E2-3 | L |
| W2-E6-2 | Artifact Hub + R2 | Universal file visualization (PDF/DOCX/PPTX/XLSX/images/audio/MD/LaTeX [ADR S16]); presigned URLs; `ArtifactGenerated` post-R2 [F-06]; preview per format (unsupported = no fake preview) | Artifact upload + preview works; `ArtifactGenerated` emitted after R2 upload only; OQ-05 UI consumer verified | Artifact | W0-E3-4 | L |

---

## Wave 3 — Agent Kernel (server-side)

**Gate:** W2 complete; all module contracts + events + jobs in place.

### Epic W3-E1: Kernel Implementation

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W3-E1-1 | Intent Engine + Context Builder | Typed TaskProfile (never prompt keywords [ADR v1.7 S6]); 9 context forms [ADR S16] assembled from module public contracts [AD-2]; server-side [01 S5.6] | Intent classification works on fixtures; context assembly covers all 9 forms; no module internal table access [AD-2] | Agent | W2 | XL |
| W3-E1-2 | Planner + Capability/Tool Registries | Plan = data (re-runnable); Capability Registry from Contract Pack declarations [kernel S14]; Tool Registry per capability; Tool Resolver with availability checks (provider, feature, platform) | Plan generation works; capabilities discovered from registry (not hardcoded); disabled feature removes capabilities [feature-registry S2] | Agent | W3-E1-1 | XL |
| W3-E1-3 | Execution + Verification + Result | Execution Engine (step-by-step, heavy = jobs [AD-8]); Verification Engine (KB check + ScientificEngine for critical, as server job); Result Normalizer (`AIResponseEnvelope` [AD-5]) | Multi-step plan executes; verification marks `expectedQuality:'degraded'` on failure; every model call has envelope trace | Agent | W3-E1-2 | XL |
| W3-E1-4 | Memory (Expert Skills) | `expert_skills` table [03 S4.2, server-only AD-3]; error loop + success loop [ADR S14.3/14.4]; guardrails [ADR S14.5] (no one-shot hypothesis, provenance, user correction, contradiction detection, periodic review) | Skill creation + validation works; guardrail tests pass (contradiction, obsolescence); no skill synced to device [AD-3] | Agent | W3-E1-3 | L |
| W3-E1-5 | Agent UI surface (AgentRunState) | Device consumes only `AgentRunState` [02 S4, F-09]; streaming panel; confirmation surface; plan preview; `AgentActionEnvelope` command bus [kernel S15] | AgentRunState streams to UI; confirmation blocks until user answers; agent never touches React components [mission S77] | Agent + App Shell | W3-E1-3 | L |
| W3-E1-6 | Mirror as Agent Tutor capability | Agent can trigger `mirror-analysis` via NL (Intent #6 « Vérifier sa compréhension »); result lands in AgentRunState + `ProgressEvidenceCreated` | NL trigger -> mirror job dispatched; evidence surfaces in dashboard Progress; confirmation point respected | Agent | W3-E1-3, W2-E2-5 | M |
| W3-E1-7 | Coach Mode (FR16) | Complete coach flow [ADR S13]: contextual check-ins (start/before block/after session/end), change detection, dynamic replanification, learning adaptation, discipline coaching, concise action-oriented dialogues, longitudinal memory; cadence/silence parameters user-controlled (preset S-21 [04.1 écran 2, 04.4]); OneSignal + local notifications; non-intrusive | Check-in fires at anchor points; silence windows respected; user cadence params persisted in `user_context`; no notification spam (anti-trap 6) | Agent + Productivity | W3-E1-3 | L |

### Epic W3-E2: Ascent — Pedagogical Trajectory Engine

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W3-E2-1 | Ascent engine core | `AscentLearningIR` / `AscentStep` / `AscentActivity` / `LearnerBaseline` / `AscentAdaptation` types in `packages/domain` [AD-15]; server-only module (AD-12, like Agent Kernel); `ascent_paths` / `ascent_steps` / `ascent_adaptations` / `ascent_baselines` tables (server-only, 03 S4.2, like expert_skills); build path from goal + learner baseline (Progress skill_states) + Knowledge; sequence READ → DO → PROVE; adapt on new ProgressEvidence (reorder / remediation / depth) | Path builds on fixtures; adaptation log append-only; no writes to module internal tables [AD-2]; path mirrors read-only via PowerSync | Ascent | W3-E1-3, W2 | L |
| W3-E2-2 | Ascent agent capability + Slide-Ascent surface | Ascent registered as feature `ascent` in the Feature Registry [G-M7] (consumer of `FeatureRegistry` port, docs/ascent/overview.md S7); agent NL trigger -> Ascent path (Intent « Apprendre X »); Slide-Ascent progressive disclosure S-41 (`_bmad-output/wds/C-UX-Scenarios/ascent/S-41-slide-ascent/S-41-slide-ascent.md`, OQ closes 09/25 : CTA « Commencer/Reprendre » ouvre slide Niveau 1 + timeline 4 semaines = liste verticale ordonnée en Niveau 3) ; 12 types de slides (palette, pas une séquence imposée — ascent §12) ; path rendered server-side, device read-only | NL trigger -> Ascent job dispatched; S-41 slide renders Niveau 1 par défaut (étape courante + suivante) ; 4 niveaux de disclosure (Niveau 4 = log AscentAdaptation « pourquoi cet ordre ? », ascent §7) ; feature deactivation = degradation (AD-1), data preserved | Ascent + App Shell | W3-E2-1 | L |

---

## Wave 4 — Integration (cross-module flows)

**Gate:** W3 complete; agent can orchestrate multi-module plans.

### Epic W4-E1: Cross-Module Workflows

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W4-E1-1 | 23 composite workflows (W1-W23) | Implement all workflows from `workflows/composite-workflows.md`: Study Session, Exam Prep, Daily/Weekly Planning, Concept Coaching, Mirror Mode, Discovery->Learning, Course->Revision/Flashcards/QCM/Exercise, Exercise->Progress, Goal->Project->Task, Task->Focus, Focus->Progress, Progress->Replanning, Research->Artifact, Audio->Transcription->Knowledge, OCR->Knowledge, Knowledge->SemanticTree, etc. | Each workflow: Trigger -> Actors -> Modules -> Capabilities -> Data -> Events -> Jobs -> UI -> Agent -> Permissions -> Failure -> Recovery documented + tested | All teams | W3 | XL |
| W4-E1-2 | Agent multi-module orchestration | Agent can compose 2+ features in one NL utterance (e2e-agent-scenarios S1, S2, S5, S13, S19, S20); confirmation points enforced; rollback on partial failure | 20 E2E scenarios [docs/agent/e2e-agent-scenarios.md] pass; compound plans work; partial execution recoverable [error-recovery S9] | Agent | W4-E1-1 | L |
| W4-E1-3 | Event wiring (AD-9) | All 9 events flow correctly between modules; Postgres trigger -> job; incremental `since_event_id` reads; no broker [01 S3.3] | Event contract tests [01 S7 a-e] pass; `TaskCompleted` triggers Progress + Learning + Agent; `DiscoveryItemCreated` triggers Learning + Knowledge + Progress + Agent | All teams | W4-E1-1 | M |

---

## Wave 5 — Dyad (UI/UX Refinement)

**Gate:** W4 complete; all workflows functional.

### Epic W5-E1: UI/UX Polish

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W5-E1-1 | Theme adaptation (local, OQ-15) | Focus Mode local theme adaptation (V1 scope); `LocalThemeOverride` port [AD-17]; extension to Lecture/Scientific = V1.1 | Focus screen uses attenuated surfaces + reinforced focus ring; other screens unchanged; port declared for V1.1 | DS + App Shell | W1-E1-1 | M |
| W5-E1-2 | Navigation polish + adaptive modes | Navigation registry filtering on feature availability; product modes [feature-registry S7]; command palette [feature-registry S4]; context-preserving navigation [mobile docs] | All 6 product modes render correctly; command palette lists available capabilities; context preserved on page transitions | App Shell + DS | W4-E1-1 | L |
| W5-E1-3 | Performance pass | 30 fps on Pixel 4a [OQ-11]; TTI < 1.5 s; JS < 300 Ko gz; Semantic Tree lazy/memo/incremental Dagre | Performance budget met on reference device; Sentry performance marks verify | All teams | W5-E1-2 | M |

---

## Wave 6 — Codex (Deep Review)

**Gate:** W5 complete; all features + workflows functional.

### Epic W6-E1: Deep Review

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W6-E1-1 | Global architecture review | Codex deep review of all modules, contracts, events, jobs, data flows; verify AD-1..AD-16 invariants; verify no cross-module table access; verify no vendor leaks; verify agent never touches React; verify no `if user===Horeb` | Review report produced; all findings categorized (Critical/High/Medium/Low); no Critical findings remain | All teams | W5 | L |
| W6-E1-2 | Test coverage audit | Verify all mandatory tests exist: unit, integration, contract, E2E, failure, permission, offline, recovery, mobile platform; Focus Mode 13 scenarios [spec S13]; 20 agent E2E scenarios; 23 composite workflows | Test matrix [docs/testing/matrix.md] 100% covered; any gap = new story | QA | W6-E1-1 | M |

---

## Wave 7 — Release Candidate (E2E Android, CI/CD)

**Gate:** W6 complete; no Critical/High findings.

### Epic W7-E1: E2E + Release

| ID | Story | Description | Acceptance Criteria | Owner | Deps | Size |
|---|---|---|---|---|---|---|
| W7-E1-1 | E2E on real device (OQ-08) | Playwright + Capacitor driver on real Android device [OQ-08 assumption]; all 20 agent scenarios + 23 workflows + Focus DPC scenarios [spec S13] | All scenarios pass on real device; Playwright supports Android 14 (if not, Appium fallback [OQ-08]) | QA | W6 | L |
| W7-E1-2 | CI/CD pipeline | Full CI/CD: build, test, deploy (Supabase, CF Workers, R2); release process; OQ-03 env values in production | Pipeline passes on main; deploy to staging + prod works; release notes generated | Foundation | W7-E1-1 | M |
| W7-E1-3 | Focus DPC E2E (v1.8) | Full DPC provisioning + Focus session E2E on target device: provisioning -> precheck -> start -> block -> end -> restore -> crash -> reboot -> factory reset -> re-provision | All 8 DPC test scenarios [spec S13] pass; suspendability matrix re-verified on target Android version | Foundation + QA + Productivity | W7-E1-1 | M |

---

## Cross-Wave Invariants (apply to ALL stories)

- AD-1: no vendor code in domain/UI/apps (CI grep test)
- AD-2: no cross-module table writes (RLS + static test)
- AD-3: no keys on device (anti-leak test)
- AD-7: single-writer per entity (kernel never writes)
- AD-8: all heavy work = persisted jobs (idempotency)
- AD-9: 9-event vocabulary closed (new event = additive ADR)
- AD-12: one kernel, server-side (device = UI surface only)
- AD-15: all types in packages/domain (no re-declaration)
- AD-17: theme system (neutral style x expressive theme x local adaptation)
- No `if user === Horeb` anywhere (review finding if detected)
- Agent never manipulates React components (command bus only)
- No free-tier promise without snapshot date + verification date
