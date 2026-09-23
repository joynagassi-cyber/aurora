# Frontend Module Ownership Matrix (master mission S53)

Maps each module to its UI surface: screens, routes, components, entry
points, outgoing actions, agent entry points, feature flag, dependencies.
Authority: 02 S4 (6 layers), 02 S6.1 (route map), 05 S4 (screen inventory),
feature-registry.md (G-M7). Status: design phase; routes/screens are
specified, not implemented.

## Convention

- **Screens** = from 05 S4 inventory (the 5 DS screens + module screens).
- **Routes** = 02 S6.1 route map.
- **Components** = AD-10 renderer contracts (05 S3.6 DEF) + module
  components (02 S4, layer 5).
- **Agent entry** = deep links / `NavigationIntent` / `UiStateCommand`
  that the kernel can trigger (kernel S15).
- **Feature flag** = `FeatureDescriptor.id` (feature-registry.md S1).
- **Dependencies** = module-level (02 S4 layer 4: data / domain /
  application / infrastructure), not UI-level.

## Productivity

| Field | Value |
|---|---|
| Screens | Home (AD-14), Inbox, Tasks, Calendar, Projects, Goals, Habits, Reviews, Analytics, Library, Focus (05 S4.3-4.5) |
| Routes | `/home`, `/inbox`, `/tasks`, `/calendar`, `/projects/:id?`, `/goals/:id?`, `/habits`, `/reviews`, `/analytics`, `/library`, `/focus` |
| Components | TaskCard, CalendarView, GanttView, KanbanView, TimelineView, FocusTimer, EisenhowerQuadrant (G-L5, additive) |
| Entry points | Home slots (AD-14), command palette, agent deep link, notification tap |
| Outgoing actions | `task.create/update/delete`, `calendar.schedule`, `project.create`, `goal.create`, `habit.checkin`, `focus.start/end`, `review.run` |
| Agent entry | `task.create`, `calendar.schedule`, `planning.daily/replan`, `focus.start/block`, `habit.checkin`, `review.run` (feature-agentability-matrix.md) |
| Feature flag | `productivity` (core, always enabled); sub-features: `productivity.focus`, `productivity.eisenhower` (G-L5) |
| Dependencies | Data (local-first, AD-7), Domain (AD-15 entities), Platform (FocusController, DpcAdapter) |

## Learning

| Field | Value |
|---|---|
| Screens | Courses, Study Sheets, Flashcards, QCM, Exercises, Coach, Mirror (05 S4.6-4.9) |
| Routes | `/learning`, `/courses/:id`, `/sheets/:id`, `/flashcards/:deckId`, `/qcm/:id`, `/exercises/:id`, `/coach`, `/mirror` |
| Components | CourseCard, SheetViewer (Tiptap + MathRenderer), FlashcardCard (FSRS), QCMItem, MirrorPanel |
| Entry points | Home (learning slot), command palette, agent deep link, `DiscoveryItemCreated` event |
| Outgoing actions | `course.import`, `sheet.generate`, `flashcard.generate`, `qcm.generate`, `learning.session.start`, `mirror.analyze` |
| Agent entry | `course.search`, `qcm.generate`, `flashcard.generate`, `learning.session.start`, `learning.mirror.analyze` |
| Feature flag | `learning` (core); sub: `learning.mirror` (01 S4.2, wave 2) |
| Dependencies | Knowledge (retrieval), Progress (skill states), Agent (AI generation jobs), Artifact (export) |

## Knowledge

| Field | Value |
|---|---|
| Screens | Knowledge Tree, Source Detail, Concept Detail (05 S4.x + tree renderer) |
| Routes | `/knowledge`, `/knowledge/tree/:nodeId?`, `/knowledge/sources/:id`, `/knowledge/concepts/:id` |
| Components | `SemanticTreeRenderer` (AD-10, lazy Dagre), SourceCard, ConceptCard, `MathRenderer` |
| Entry points | command palette, agent deep link, `CourseImported` event |
| Outgoing actions | `knowledge.search` (FTS + pgvector, server), `knowledge.expand` (tree node) |
| Agent entry | `course.search` (PARTIAL offline), tree navigation via `NavigationIntent` |
| Feature flag | `knowledge` (core) |
| Dependencies | Artifact (R2 source documents), Progress (`node_states` via `ProgressEvidenceCreated`) |

## Discovery

| Field | Value |
|---|---|
| Screens | Discovery Feed, Research Results, Gap Analysis, Horizons (05 S4.x) |
| Routes | `/discovery`, `/discovery/research/:id`, `/discovery/gaps`, `/discovery/horizons` |
| Components | DiscoveryCard, SourceBadge (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY), GapCard |
| Entry points | command palette, agent deep link |
| Outgoing actions | `discovery.research`, `discovery.sheet` -> Learning |
| Agent entry | `discovery.research` (FULL, online) |
| Feature flag | `discovery` (optional, AD-1 degradation: `uncertain` marking) |
| Dependencies | ResearchProvider (You.com/Tavily/Exa), Progress (skill states for gaps), Knowledge (existing sources) |

## Progress

| Field | Value |
|---|---|
| Screens | Progress Dashboard (today/week/month/trajectory), Evidence Detail, Skill Detail (05 S4.x) |
| Routes | `/progress`, `/progress/week`, `/progress/month`, `/progress/skills/:id`, `/progress/evidence/:id` |
| Components | `DataVisualizationRenderer` (G2, `ChartSpec`), TrendCard, SkillStateCard, `ChartSpec` focusBilan (G-H1) |
| Entry points | Home (critical progress slot), command palette, agent deep link |
| Outgoing actions | `progress.analyze` (read + S jobs) |
| Agent entry | `progress.analyze` (FULL) |
| Feature flag | `progress` (core) |
| Dependencies | all modules (evidence producers: Learning, Productivity, Discovery, Artifact); sole-producer rule (F-07) |

## Agent (UI surface)

| Field | Value |
|---|---|
| Screens | Agent Chat / `AgentRunState` surface (05 S4.x, 02 S4 F-09) |
| Routes | `/agent` |
| Components | AgentRunStatePanel (streaming), ConfirmationSurface, PlanPreview |
| Entry points | FAB / nav tab, command palette ("ask Aurora"), deep link |
| Outgoing actions | all registered capabilities (kernel S14) |
| Agent entry | N/A (the Agent is the entry point) |
| Feature flag | `agent` (core, wave 3) |
| Dependencies | AI pipeline (AD-4), all module contracts (AD-2), Composio (optional) |

## Artifacts

| Field | Value |
|---|---|
| Screens | Artifact Hub, Artifact Detail / Preview (05 S4.x) |
| Routes | `/artifacts`, `/artifacts/:id` |
| Components | `InfographicRenderer`, `DataVisualizationRenderer`, `AudioWaveformRenderer` (04 S5), ArtifactCard |
| Entry points | command palette, `ArtifactGenerated` event (UI = OQ-05), agent deep link |
| Outgoing actions | `artifact.preview`, `artifact.export`, `artifact.share` |
| Agent entry | `artifact.generate` (FULL, online) |
| Feature flag | `artifacts` (core) |
| Dependencies | R2 (ObjectStorage), Learning (sheet content), Agent (AI generation) |

## Scientific Engine

| Field | Value |
|---|---|
| Screens | inline (formula rendering in Knowledge / Learning sheets; no dedicated screen in V1) |
| Routes | no dedicated route (renderer contract, AD-10 `MathRenderer`) |
| Components | `MathRenderer` (LaTeX + `onError` -> styled raw source) |
| Entry points | inline in any screen that renders a formula |
| Outgoing actions | `scientific.evaluate/convert/verify` (light ops local; heavy = job) |
| Agent entry | `scientific.evaluate/verify` (FULL) |
| Feature flag | `scientific` (core; engine choice = NEEDS_DECISION, Scientific team) |
| Dependencies | Domain (LaTeX representation), Jobs (heavy compute, AD-8) |

## Integrations / Notifications

| Field | Value |
|---|---|
| Screens | Settings > Integrations, Settings > Notifications (05 S4.x) |
| Routes | `/settings/integrations`, `/settings/notifications` |
| Components | IntegrationCard (connection state), NotificationPreferenceToggle |
| Entry points | Settings nav, agent "connect X" prompt |
| Outgoing actions | `integrations.automation.toggle`, `notification.subscribe/silence` |
| Agent entry | `integrations.automation.toggle` (CONFIRMATION_REQUIRED) |
| Feature flag | `integrations` (optional; Composio = AD-1 degradation) |
| Dependencies | Composio (server), OneSignal (server + device split, 04 S3.4) |

## Design System

| Field | Value |
|---|---|
| Screens | all screens (theme is cross-cutting) |
| Routes | N/A (no route; `AuroraThemeProvider` wraps the app) |
| Components | 9 DS data components (05 S3.6 DEF) + 5 AD-10 renderer contracts + `AnimationSlot` (G-M1) |
| Entry points | Settings > Theme, user_context `theme` field |
| Outgoing actions | N/A (rendering only) |
| Agent entry | N/A |
| Feature flag | `designsystem` (core) |
| Dependencies | 05 S5-6 (theme JSON SSoT, 10 themes + 3 presets), G-H2 (canvas values aligned) |
