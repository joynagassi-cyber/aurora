# Claude Code + Dyad — Session Prompts (2026-09-22)

## SESSION 1: Wave 0 — Foundation (4 sub-agents, autonomous)

### Prompt for Claude Code Session 1

```
Tu es un agent de developpement autonome. Tu travailles sur le
projet Aurora (modular monolith, local-first, pnpm monorepo) dans
C:\Users\joyda\dyad-apps\aurora-2.

LIS d'abord (dans cet ordre, avant TOUT code) :
1. _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md (ADR v1.7)
2. _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md (AD-1..AD-16)
3. _bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md (vagues + OQ)
4. docs/epics-stories.md (W0-E1..E5, les 13 stories de la vague 0)
5. docs/architecture/contract-catalog.md (contrats TypeScript)
6. docs/architecture/dependency-matrix.md (qui lit/ecrit quoi)
7. docs/architecture/multi-agent-workflow.md (regles de parallelisation)
8. AI_RULES.md (regles IA)

REGLES ABSOLUES :
- AD-1: aucun import de vendor dans packages/domain, packages/ui, apps/mobile/src
- AD-15: TOUTES les entites dans packages/domain (SSoT)
- AD-13: one-writer-per-file (tu n'ecris que TON module)
- AD-2: aucun cross-module table access
- AD-3: zero cles dans le bundle
- Le code doit compiler (tsc --noEmit) et passer les tests avant commit
- Chaque story = 1 commit = 1 rollback possible
- Ne jamais inventer un contrat : si un type n'est pas dans contract-catalog.md,
  il est manquant (marquer G-XX dans le commit message)

TON TRAVAIL (3 sous-agents paralleles) :

=== Sous-agent A : Monorepo + Domain Types (W0-E1) ===
1. Creer le pnpm workspace : 12 packages
   packages/domain, packages/data, packages/ui, packages/platform,
   packages/agent, packages/scientific-engine, packages/integrations,
   packages/engineering-core, packages/engineering-solvers,
   packages/engineering-adapters, packages/engineering-registry,
   apps/mobile, apps/server
   (voir docs/architecture/multi-agent-workflow.md S4 pour la liste)
2. Dans packages/domain : toutes les entites AD-15 (Task, Event, Project,
   Goal, Milestone, Habit, Routine, Note, Resource, Course, Subject, Skill,
   LearningSession, Review, FocusSession, Artifact, Automation, Decision,
   UserContext, Progress*, Semantic*, SourceRef, EvidenceRef, DiscoveryItem,
   Gap, ExpertSkill, GoalProject, SubGoal, FeaturePlacement, GoalProgress)
3. Enveloppes : ApiEnvelope, AIResponseEnvelope, AppError
4. Les 9 evenements (payloads exacts, data-event-job-catalog.md)
5. FeatureDescriptor, AgentCapability, NavigationIntent, UiStateCommand
6. ProblemIR, Quantity, Unit, PhysicalDimension (engineering-core)
7. Les 5 ports principaux (ObjectStorage, AIProvider, KnowledgeBase,
   JobRunner, NotificationProvider)
8. tsc --noEmit passe sur tout
9. ESLint import/no-restricted-paths (domain n'importe rien)
COMMIT : "wave0: monorepo + domain types (AD-15 SSoT)"

=== Sous-agent B : CI/CD + Tests (W0-E1-3/4) ===
1. GitHub Actions workflow : build + lint + type-check + grep
2. Grep 1 : noms de vendor (Agnes, Groq, OpenRouter, fal.ai)
   hors packages/adapters = build failure
3. Grep 2 : secrets (API keys, tokens) dans le bundle = build failure
   (exception : OneSignal appKey dans capacitor.config.ts)
4. Test du spine : 2 equipes (2 branches) produisent le meme contrat
   (import du type, appel de la methode, verification du retour)
5. RLS penetration test (01 S7) : user A ne lit pas user B
6. tsc --noEmit sur tout le workspace
COMMIT : "wave0: CI pipeline + boundary tests + spine test"

=== Sous-agent C : Supabase + R2 + PowerSync (W0-E3) ===
1. 3 Supabase projects (dev/staging/prod) - structure, pas les valeurs (OQ-03)
2. RLS policies par module (01 S2.2)
3. Tables : events (AD-9), job_queue + job_logs (01 S5.3, G-M4),
   user_context (Identity), + toutes les tables modules (01 S4.1-4.7)
4. Vues publiques par module (03 S5.4 : pas de cross-join)
5. PowerSync relay : miroirs locaux (03 S4.2 mapping)
6. R2 : 3 buckets (dev/staging/prod), presigned URL config (15/5 min)
7. Cron : Supabase pg_cron -> job dispatch (01 S5.2)
COMMIT : "wave0: Supabase + R2 + PowerSync + RLS"

QUAND T'ES PRET : commit sur main. Codex fait la revue au push.
```

---

## SESSION 2: Wave 1 — UI + Data (4 sub-agents, autonomous)

### Prompt for Claude Code Session 2

```
Tu es un agent de developpement autonome. Le projet Aurora est dans
C:\Users\joyda\dyad-apps\aurora-2. La vague 0 est terminee
(packages/domain, CI, Supabase, R2, PowerSync existent).

LIS d'abord :
1. docs/architecture/contract-catalog.md (S4 local data, S5 platform, S8 UI)
2. docs/frontend/feature-registry.md (G-M7, activation/deactivation)
3. docs/architecture/event-reconciliation-and-router.md (S1 battery-aware)
4. _bmad-output/.../dimensions/03-sync.md (repos, CRDT, sync)
5. _bmad-output/.../dimensions/02-frontend.md (6 layers, routing, 5 states)
6. docs/epics-stories.md (W1-E1..E3, les 5 stories de la vague 1)
7. docs/architecture/multi-agent-workflow.md (regles + premium UI S3)

REGLES :
- AD-7: UI lit UNIQUEMENT SQLite (LocalQueryRepository), ecrit via
  LocalCommandRepository -> module owner. JAMAIS de reseau sur le
  chemin de rendu.
- AD-10: 5 moteurs figes dans packages/ui UNIQUEMENT
- AD-13: 5 etats UX normatifs (loading, error, empty, success, offline)
  + killed (G-M2)
- Premium UI (multi-agent-workflow S3) : FullCalendar, Radix UI,
  AG Grid, Framer Motion. PAS de ion-calendar, PAS de ion-list
  pour les data tables.
- Battery : WorkManager en background (pas de service continu, 04 S3.6)
- minSyncIntervalMs (03 S5.7) : 5s foreground, 20s background

TON TRAVAIL (3 sous-agents paralleles) :

=== Sous-agent A : packages/ui (W1-E1-1) ===
1. packages/ui/src/themes/ : 10 themes JSON + 3 presets (Slate,
   Nocturne, High Contrast). Canvas : Light #FFFFFF, Dark #121212
   (G-H2 resolved). G-M5: ChartSpec shape publiee ici.
2. 9 composants data (05 S3.6 DEF) :
   - SemanticTreeRenderer (React Flow + Dagre, lazy, incremental, 30fps)
   - InfographicRenderer (AntV Infographic, hybrid SVG + <image>)
   - DataVisualizationRenderer (AntV G2, ChartSpec)
   - MathRenderer (KaTeX, onError -> styled raw source, never crash)
   - AnimationController (RevealKey, reduced-motion, G-M1: AnimationSlot)
   - + 4 data components (DS)
3. Resolvers : resolveToken (theme + semantic tokens)
4. <AuroraThemeProvider> (05 S5.8)
5. FullCalendar integration (calendar premium, NOT ion-calendar)
6. Radix UI integration (forms, dialogs, tooltips, command palette)
7. AG Grid Community (data tables, virtualized, 60fps)
8. Framer Motion (page transitions, node pulse, reveal-on-scroll)
9. tsc --noEmit + 30fps test (1000-node tree on Pixel 4a spec)
COMMIT : "wave1: packages/ui (DS + premium components + themes)"

=== Sous-agent B : packages/data (W1-E2-1/2) ===
1. LocalQueryRepository / LocalCommandRepository (03 S3.1)
2. PowerSync schema (03 S4.2 mapping : toutes les tables mirrors)
3. SQLite local (Capacitor)
4. Sync states : SyncStatus (pending, syncing, idle, conflict)
5. Conflict rule : server-wins + updated_at (03 S5.1)
6. OR-Set CRDT pour les listes (03 S5.3, SSoT packages/domain)
7. Upsync queue (offline -> online, idempotent)
8. React Query bridge (03 S5.8) : RQ <-> LocalQueryRepository.watch
9. Local notifications (Capacitor, 04 S3.4) : scheduleLocal, cancelLocal,
   reduceForFocus
10. T1 tests : single-writer, CRDT merge, server-wins deterministic,
    view-join static (03 S7)
COMMIT : "wave1: packages/data (local-first + PowerSync + CRDT)"

=== Sous-agent C : apps/mobile shell (W0-E4-2 + W1-E1-2) ===
1. Ionic React + Capacitor shell
2. Zustand (ui-state ONLY, jamais de donnees metier, AD-7)
3. React Query (data reads from local repos only)
4. Routing (02 S6.1) : 17 pages, context-preserving
5. 5 UX states + killed (G-M2) : loading, error, empty, success, offline, killed
6. Home screen (AD-14) : 7 slots fixes ("Qu'est-ce qui compte maintenant?")
7. Feature Registry (G-M7) : FeatureDescriptor, activation, deactivation
8. Premium components : FullCalendar (calendar), Radix (forms/dialogs),
   AG Grid (data tables), Framer Motion (transitions)
9. OneSignal (server key, fn-notifications) + local (Capacitor)
   split rule (04 S3.4, never both for same object)
10. OQ-09/10/11 : IonList virtuel (fallback react-virtuoso > 100 items),
    @aurora/ui, Pixel 4a reference
COMMIT : "wave1: apps/mobile shell (Ionic + Capacitor + premium UI)"
```

---

## SESSION 3: Wave 2 — Features (4 sub-agents, autonomous)

### Prompt for Claude Code Session 3

```
Tu es un agent de developpement autonome. Les vagues 0-1 sont
terminees (monorepo, DS, data, mobile shell). Tu codes les features
de la vague 2.

LIS d'abord :
1. docs/features/master-feature-catalog.md (40 features, chaines)
2. docs/architecture/dependency-matrix.md (S1-15, qui lit/ecrit quoi)
3. docs/architecture/data-ownership-matrix.md (tables par module)
4. docs/productivity/overview.md + eisenhower.md
5. docs/learning/overview.md
6. docs/knowledge/discovery-gap-pipeline.md (gap analysis + tree)
7. docs/progress/overview.md
8. docs/scientific-engine/engineering-intelligence-layer.md
9. docs/epics-stories.md (W2-E1..E6, les 14 stories de la vague 2)
10. _bmad-output/.../dimensions/01-backend.md (S4 schemas, S5 jobs)

REGLES :
- AD-7: single-writer (ton module ecrit SEULEMENT ses tables)
- AD-9: les 9 evenements uniquement (pas de 10e)
- AD-8: travail lourd = job persiste (job_queue, idempotent)
- AD-2: pas de cross-module table access (public views + ports)
- Engineering Intelligence Layer (docs/scientific-engine/) :
  le LLM n'interprete PAS, le solveur calcule, le verifier valide
- Progress = seul producer de ProgressEvidenceCreated (F-07)

TON TRAVAIL (3 sous-agents paralleles) :

=== Sous-agent A : Productivity (W2-E1-1..6) ===
1. Inbox + Tasks (CRUD, statuts, subtasks, recurrence, dependencies)
   Eisenhower quadrant (G-L5 : 4 quadrants, agent-assisted)
2. Calendar + Time Blocking (FullCalendar, pas ion-calendar)
   Conflict detection, overload detection
3. Projects + Goals (Gantt/Kanban/Timeline/List views, milestones)
   Goal -> Project -> Task hierarchy
4. Habits + Routines (HabitStreak heatmap, adherence analytics)
5. Focus Mode (in-app timer + Pomodoro + blocklist)
   FocusSessionBilan SSoT (G-H1, 01 S4.1)
   DPC adapter stub (v1.8, W0-E4-3 provisione mais pas encore E2E)
6. Reviews + Analytics (daily/weekly/monthly, planned vs actual,
   procrastination trends)
7. Events : TaskCompleted, GoalUpdated (AD-9, producer = Productivity)
8. Jobs : focus_timer (local, pas serveur), analytics aggregation (S job)
COMMIT : "wave2: Productivity module (inbox, tasks, calendar, focus, reviews)"

=== Sous-agent B : Learning + Knowledge (W2-E2-1..5, W2-E3-1..2) ===
1. Course import (camera -> R2 -> fn-import-course + OCR job)
   CourseImported event (producer = Learning)
2. Study sheets (AI generation, 7 structures, ADR S17 fidelity)
   Fidelity check (corpus-dominant + separated agent explanation)
   Export MD/PDF/DOCX/PNG (artifact_gen job + R2 + ArtifactGenerated)
3. Flashcards (FSRS server-side, state mirrored local)
   FlashcardReviewed event (producer = Learning)
4. QCM + exercises (AI generation, progressive, error analysis)
5. Mirror Cognitive Mode (01 S4.2, G-L3) :
   Server mirror-analysis job, typed detections + AD-11 provenance,
   F-07 evidence path. Screen = additive 05 inventory (wave 2)
6. Semantic tree (Postgres + pgvector, lazy Dagre renderer)
   NodeState (Knowledge-owned, AD-6), semantic_tree_version
   Invariance : meme formule = meme noeud (source_refs enrichit)
   Phased layering : bridges secondaires, masques par defaut
7. Retrieval (FTS + pgvector + R2, server-only, AD-12)
   SourceRef provenance (AD-11)
COMMIT : "wave2: Learning + Knowledge (courses, sheets, QCM, mirror, tree)"

=== Sous-agent C : Discovery + Progress + Scientific (W2-E4..E6) ===
1. Discovery (multi-source, FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY)
   ResearchProvider (Exa/Tavily/You.com, optional, AD-1 degradation)
   Gap analysis (Progress skill_states + Knowledge sources)
   DiscoveryItemCreated event (producer = Discovery)
   Benin filtering (UserContext.region, data-driven, pas hardcoded)
2. Progress (evidence model, sole-producer F-07)
   ProgressEvidenceCreated + SkillStateChanged (producer = Progress)
   Dashboards (G2, ChartSpec), trajectories, causal analysis (S18.4)
   skill_recompute jobs (S jobs, AD-8)
3. Scientific Engine (deterministic, swappable, ADR S15)
   Engineering Intelligence Layer (docs/scientific-engine/) :
   - ProblemIR + Quantity + Unit (engineering-core)
   - 5-stage validation
   - Method Registry (5 seed methods)
   - Solver Registry (5 seed solvers : math, rdm.beam, rdm.truss,
     metre.quantity, math.symbolic)
   - Verification Registry (5 seed rules : equilibrium, dimensional,
     boundary, cross-solver, convergence)
   - Code Registry (Eurocode 2, BAEL - basic)
   - SymPy adapter (Beam 2D/3D, matrices)
   Agent tool : scientific.evaluate / scientific.verify
   Light ops local, heavy = jobs (AD-8)
COMMIT : "wave2: Discovery + Progress + Scientific Engine (Engineering Layer)"
```

---

## SESSION 4: Wave 3+ — Agent + Goal + Self-Improvement

### Prompt for Claude Code Session 4

```
Tu es un agent de developpement autonome. Les vagues 0-2 sont
terminees (modules, features, scientific engine). Tu codes l'Agent
Kernel, le Goal Engine et le Self-Improvement.

LIS d'abord :
1. docs/agent/kernel.md (15 sections, 15 composants)
2. docs/agent/feature-agentability-matrix.md (capabilities)
3. docs/agent/e2e-agent-scenarios.md (20 scenarios)
4. docs/agent/error-recovery.md (10 error classes)
5. docs/agent/expert-skills-extensions.md (4 extensions + SQLite schema)
6. docs/architecture/dynamic-goal-engine.md (GoalProject, 5 shapes)
7. docs/architecture/goal-dashboard-ui.md (cartes + dashboard adaptatif)
8. docs/ai/vercel-ai-sdk-integration.md (streamText, maxSteps, tools)
9. docs/ai/providers/agnes.md + agnes-image.md
10. docs/architecture/event-reconciliation-and-router.md (TaskProfile,
    5 niveaux, Agnes = TOUJOURS PRIMARY)
11. docs/scientific-engine/engineering-intelligence-layer.md
    (6 registres, 5 familles, 4 couches RAG)
12. docs/epics-stories.md (W3-E1, W4-E1, W5-E1)

REGLES :
- AD-12: UN kernel, serveur, device = AgentRunState UNIQUEMENT
- AD-3: zero cles provider sur le device
- AD-5: fallback N contourne JAMAIS un quota (429 = respect)
- Agnes = PRIMARY TOUJOURS (event-reconciliation S2.6)
- Vercel AI SDK = dans packages/agent UNIQUEMENT (AD-1)
- GoalProject = dynamique (pas 7 besoins fixes)
- Expert Skills = server-only (AD-3, 03 S4.2)

TON TRAVAIL (3 sous-agents paralleles) :

=== Sous-agent A : Agent Kernel (W3-E1-1..5) ===
1. Intent Engine : typed TaskProfile (pas de prompt keywords)
   Classification : ROUTINE / AGENT / VISION / CRITICAL / FALLBACK
   Agnes = primary TOUJOURS (retour apres fallback)
2. Context Builder : 9 context forms (ADR S16), server-side
3. Planner : capability plan + confirmation points (ADR S5)
4. Capability Registry : decouverte depuis Contract Packs (AD-13)
   Pas de hardcoding (kernel S14)
5. Tool Registry + Tool Resolver : availability checks
6. Execution Engine : Vercel AI SDK streamText({ maxSteps, tools })
   Tools : planDay, schedule, startFocus, blockApps, research,
   qcm_generate, mirror_analyze, scientific_verify, goal_create,
   discovery_research, artifact_export
7. Verification Engine : KB check + ScientificEngine (job, AD-8)
   Second LLM "judge" SEULEMENT si justifie (ADR v1.7 S14)
8. Result Normalizer : AIResponseEnvelope (provider, model, attempt,
   reason, expectedQuality, fallbackUsed, traceId)
9. Memory : expert_skills (server-only, AD-3)
   4 extensions (expert-skills-extensions.md) :
   - Contrastive pairs (2 min)
   - Confidence decay (deterministic formula)
   - Hypotheses (14-day window, fail-fast)
   - Cognitive-Drift Firewall (3 cycles min)
10. Agent UI : AgentRunState (streaming, 02 S4)
    AgentActionEnvelope + NavigationIntent + UiStateCommand
    (kernel S15, command bus, PAS de React direct)
COMMIT : "wave3: Agent Kernel (15 composants + Vercel AI SDK)"

=== Sous-agent B : Goal Engine + Dashboard (W3+ wave 4-5) ===
1. GoalProject (dynamic, agent-created, PAS 7 besoins fixes)
   SubGoal + FeaturePlacement + Timeline + GoalProgress
   (dynamic-goal-engine.md, 5 shapes = hints pas contraintes)
2. Goal Dashboard UI (goal-dashboard-ui.md)
   - Carte sur Home (AD-14)
   - 5 layouts adaptatifs (Preparation, Practice, Curation, Delivery,
     Adaptation)
   - Feature nodes (position = signification)
   - Esthetique (tokens DS, pulse actif, suggestion en langue naturelle)
3. Agent capabilities : goal.create, goal.status, goal.recompose,
   goal.pause, goal.complete, goal.abandon, goal.feature.add/remove
4. Integration : GoalProject -> feature-registry (modes adaptatifs)
   -> Agent Planner (composition dynamique)
   -> Progress (GoalProgress, sole producer F-07)
COMMIT : "wave3-5: Goal Engine + Dashboard UI"

=== Sous-agent C : Integration + Self-Improvement + E2E (W4-E1, W5-E1) ===
1. 23 composite workflows (docs/workflows/composite-workflows.md)
   Each : Trigger -> Actors -> Modules -> Capabilities -> Data ->
   Events -> Jobs -> UI -> Agent -> Permissions -> Failure -> Recovery
2. Agent multi-module orchestration (e2e-agent-scenarios.md, 20)
   Compound plans (2+ features en une utterance)
   Confirmation points (ADR S5)
   Rollback on partial failure (error-recovery.md)
3. Event wiring (AD-9) : 9 events flow correctly
   Postgres trigger -> job, incremental reads
4. Self-Improvement loop (ADR S14 + expert-skills-extensions.md)
   Progress detects gap -> Self-Improvement triages -> Discovery runs
   -> Expert Skill revised -> Next session uses updated skill
   4 extensions : contrastive, decay, hypothesis, firewall
5. UI polish (W5-E1) :
   - Framer Motion (page transitions, node pulse)
   - FullCalendar (Focus sessions, time blocking)
   - AG Grid (Progress dashboards, QCM results)
   - Theme adaptation (OQ-15, Focus only in V1)
   - Command palette (feature-registry S4)
6. 20 E2E agent scenarios (device, OQ-08 Playwright assumption)
COMMIT : "wave4-5: Integration + Self-Improvement + E2E + UI polish"
```

---

## DYAD — Prompt pour le Design Mobile Premium

### Prompt pour Dyad

```
Tu es le designer et developpeur fullstack de l'interface mobile
Aurora (Ionic React + Capacitor + Android). Tu travailles dans
C:\Users\joyda\dyad-apps\aurora-2.

TON OBJECTIF : une interface mobile PREMIUM, coherente, soignee.
Pas un raccordement de composants. Pas le look "vieux Ionic".
Pas un calendrier en anglais de 2015. Un design system vivant,
expressif, avec 10 themes + 3 presets, qui s'adapte au contexte
de l'utilisatrice (examen, focus, minimal).

LIS d'abord (dans cet ordre) :
1. _bmad-output/.../dimensions/05-design-system.md (tokens S2,
   composants S3, screens S4, themes v2 S5-6)
2. docs/design-system/overview.md (synthese + incoherences verifiees)
3. docs/architecture/goal-dashboard-ui.md (cartes + 5 layouts +
   esthetique + rules)
4. docs/architecture/multi-agent-workflow.md S3 (premium UI stack)
5. docs/mobile/navigation-and-page-composition.md (17 pages,
   entry/exit, context, states)
6. docs/mobile/context-preserving-navigation.md (route params,
   entity IDs, return destination)
7. docs/frontend/feature-registry.md S7 (6 product modes)
8. docs/focus-mode/spec.md S6 (7 states du focus)
9. docs/scientific-engine/engineering-intelligence-layer.md
   (visualizations : AntV, KaTeX, diagrams)
10. docs/artifacts/infographic-multi-resource.md (hybrid SVG +
    images, AntV Infographic)

REGLES ABSOLUES (design) :
- PAS de ion-calendar (vieux, anglais, corporate) -> FullCalendar v6+
- PAS de ion-list pour les data tables -> AG Grid Community
- PAS de ion-item pour les forms -> Radix UI (headless, premium)
- PAS de SVG decoratif / orbes / bokeh -> images reelles (Agnes Image)
- Border radius : 8px MAX (DS convention)
- 10 themes vivants (Aurora default, Lagoon, Boreal, Sakura, Vesper,
  Solara, Terra, Verdant, Citrus, Cosmos) + 3 presets (Slate,
  Nocturne, High Contrast). Canvas : Light #FFFFFF, Dark #121212
- Style neutre x theme expressif x adaptation locale (AD-17, 3 niveaux)
- Tokens semantiques (success/warning/danger/info) independants du theme
- Letter-spacing : 0 (pas de tracking negatif)
- Typography : Inter, 13px/500 labels, 16px/600 titres, 20px/700 progress
- Icons : Lucide UNIQUEMENT (pas d'emoji, pas de SVG custom)
- Animation : Framer Motion (GPU, smooth, NOT bouncy,
  prefers-reduced-motion = static, 200ms ease-out)
- Pas de carte dans une carte. Pas de section pleine largeur en carte.
- Texte qui tient dans son conteneur sur mobile ET desktop
- Pas de gradient hero, pas de typographie hero-scale

TON TRAVAIL (3 phases) :

=== Phase 1 : Design System (packages/ui) ===
1. packages/ui/src/themes/ : 10 JSON + 3 presets
   (G-H2 verified, canvas values correct)
2. 9 composants data (05 S3.6 DEF) :
   - SemanticTreeRenderer (React Flow + Dagre, lazy, incremental)
   - InfographicRenderer (AntV Infographic, hybrid SVG + <image>)
   - DataVisualizationRenderer (AntV G2, ChartSpec [G-M5])
   - MathRenderer (KaTeX, onError -> styled raw source)
   - AnimationController (Framer Motion, G-M1: AnimationSlot)
   - + 4 DS data components
3. resolveToken + <AuroraThemeProvider>
4. 49 theme x screen mockups (G-L2, 05 S5.7)
5. Component states (05 S3.7) : loading, error, empty, success,
   offline + killed (G-M2) sur chaque component

=== Phase 2 : Ecrans (apps/mobile) ===
1. Home (AD-14) : 7 slots fixes + GoalProject cards (dynamic-goal-engine)
   "Qu'est-ce qui compte maintenant?"
   GoalProject card : icone + titre + progress bar + prochain action
   + suggestion agent (langue naturelle, PAS system message)
2. Goal Dashboard (5 layouts adaptatifs, goal-dashboard-ui.md)
   - Preparation : flow left->right
   - Practice : boucle
   - Curation : arbre
   - Delivery : milestones
   - Adaptation : spirale
   - Feature nodes : position = signification
   - Esthetique : spacing 16/8, hierarchie visuelle, theme accent
3. Calendar (FullCalendar v6+, PAS ion-calendar)
   - Views : jour, semaine, mois, agenda
   - Time blocking : blocs colores par type (etude, focus, projet)
   - Conflict detection : visuel (double frame rouge)
   - Focus sessions : blocs "focus" avec blocklist icon
   - Touch-optimized (44px min tap targets)
4. 17 pages (navigation-and-page-composition.md)
   Chaque page : entry, outgoing, incoming, context, actions,
   deep links, agent-triggered, return, persistent, empty, permission
5. Focus screen (05 S4.4 + focus spec S6)
   - Timer + Pomodoro (system clock, AD-7)
   - Blocklist UI (per-package status : suspendable / not / aurora-protected)
   - DPC detection (isBlockingAvailable = detection, PAS constant)
   - 7 states (scheduled, starting, prechecking, active, paused,
     ending, completed / interrupted, restoring, failed)
   - Local theme adaptation (OQ-15, V1 = Focus only)
6. Semantic Tree screen (React Flow + Dagre)
   - Lazy level-1, incremental expand
   - Node colors : mastered (green), fragile (yellow), unknown (gray)
   - Bridges : hidden par defaut, cross-domain view (toggle)
   - 1000 nodes at 30fps (02 S11 perf test)
7. Progress dashboard (AG Grid + G2)
   - Today/week/month/trajectory boards
   - Skill states (heatmap)
   - Evidence detail (per-type: QCM, exercise, flashcard, focus,
     mirror, project)
   - ChartSpec (G-M5, 05 S3.6)
8. Agent chat (AgentRunState, streaming)
   - useChat (Vercel AI SDK, streaming tokens)
   - Tool call rendering (intercept -> AD-10 renderers)
   - Confirmation surface (blocking, ADR S5)
   - Plan preview (before execution)
   - "Suggestion" en langue naturelle (PAS "system message")
9. QCM / Flashcards / Mirror screens (05 S4.6-4.9)
   - QCM : progressive, error analysis, recurring errors
   - Flashcards : FSRS spaced repetition, review UI
   - Mirror : explanation + detection + QCM derivation
10. Artifacts screen (R2 + preview)
   - Per-format preview (PDF, DOCX, PPTX, XLSX, images, audio)
   - Infographic multi-resource (AntV + images)
   - Unsupported = no fake preview (ADR S16)

=== Phase 3 : Polish + QA ===
1. Theme switching (10 themes + 3 presets, instant, GPU)
2. Product modes (6 modes, feature-registry S7)
   - Core, Study, Exam, Focus-heavy, Professional, Minimal
   - Mode = profile over registries (PAS 6 apps differentes)
3. Framer Motion : page transitions (200ms ease-out), node pulse
   (active only), reveal-on-scroll (reduced-motion = static)
4. 30fps on Pixel 4a (OQ-11) : tree, AG Grid, FullCalendar,
   Framer Motion all at 30fps min
5. TTI < 1.5s, JS < 300Ko gz (02 S9 perf budget)
6. Visual QA : screenshots par theme (10) x screen critical (5)
   = 50 screenshots (G-L2 partial, 49 remaining = wave-0 DS)
7. A11y : contrast ratios (WCAG AA), touch targets >= 44px,
   screen reader labels
```

---

## CODEX — Mon role (revue a chaque commit/push)

Je n'interviens PAS pendant le codage. Je intervienne a :
- Chaque commit de Claude Code (revue dans les 5 min)
- Chaque push sur main (revue deep, 15-30 min)
- Fin de sprint (revue etat atteint, 1h)

CHECKLIST CODEX (chaque commit) :
[ ] AD-1 : pas de vendor dans domain/ui/apps
[ ] AD-2 : pas de cross-module table
[ ] AD-3 : pas de secret dans le diff
[ ] AD-7 : single-writer (ce commit ecrit seulement ses tables)
[ ] AD-8 : lourd = job (pas inline)
[ ] AD-9 : 9 events uniquement
[ ] AD-12 : agent ne write pas les tables
[ ] AD-15 : types de packages/domain (pas de re-declaration)
[ ] AD-17 : tokens theme (pas de couleur hardcodee)
[ ] 03 S5.4 : pas de cross-join SQL
[ ] Premium UI : pas de ion-calendar, pas de ion-list data table
[ ] Battery : pas de service continu (WorkManager)
[ ] Offline : feature fonctionne offline (local mirror)
[ ] Test : le test correspondant existe et passe

SI VIOLATION : reject le commit avec le message exact :
"REJECT: AD-X violation, fichier:ligne, explication, correction"
```
