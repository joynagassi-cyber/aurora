# Goal Dashboard — UI Specification (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 5 Dyad). Authority:
dynamic-goal-engine.md (data model + composition), 05-design-system.md
(tokens, components, AD-10 renderers, themes v2), 02-frontend.md
(6 layers, 5 UX states, routing), AD-14 (Home invariant), AD-17
(theme system).

**Rule: the Goal Dashboard is NOT a list of features. It is a
visually organized "mission control" adapted to the goal's shape.
The agent composes features; the UI composes the VISUAL LAYOUT.
It must look intentional, aesthetic, and specific to the goal —
NOT like a generic settings page or a raw feature list.**

## 1. GoalProject Card (on Home / Dashboard)

The user sees 1-N GoalProject cards on the Home screen (AD-14:
"Qu'est-ce qui compte maintenant?"). Each card is a **visual summary**
of the active goal.

```
+------------------------------------------+
|  [icon]  ML Mastery — 6 mois            |
|                                          |
|  42%  (progress bar, themed)            |
|  [18] / [43] concepts                    |
|                                          |
|  Prochain: QCM Thermo — 14h (30min)    |
|  Cette semaine: 3/5 sessions focus      |
|                                          |
|  [Suggestion] "Régime permanent: 3 QCM" |
+------------------------------------------+
```

**Design rules (05 DS, AD-17):**
- Card = 8px border radius (05 S3, DS convention: compact, not bloated)
- Progress bar uses the goal's theme accent (AD-17: theme = skin,
  semantic tokens = state; progress = `info` token, accent = theme)
- Icon = per goal-shape (preparation = target, practice = loop,
  curation = tree, delivery = milestone, adaptation = spiral)
- Card height = fixed (no dynamic resize on content change —
  prevents layout shift, 02 S9 perf rule)
- Tap = navigate to Goal Dashboard (02 S6.1: detail over current tab)
- Multiple goals: horizontal scroll (IonList, OQ-09) or grid
  (2-up on landscape, 1-up on portrait)

**States (AD-13 5 + killed):**
- `loading`: skeleton card (shimmer, 05 S3.7)
- `empty`: "Aucun objectif actif" + "Demande à Aurora" CTA
- `success`: goal completed (progress 100%, badge "Terminé ✓")
- `error`: goal data unavailable (offline + no mirror) + retry
- `offline`: last-known progress + "sync pending" badge
- `killed`: app was force-killed; re-hydrate on open (04 S6.1)

## 2. Goal Dashboard (the screen you land on)

When the user taps the GoalProject card, they land on the **Goal
Dashboard** — a full-screen, goal-specific "mission control."

**This is NOT a list of features.** It is a spatial layout where
each feature has a POSITION that encodes its role in the goal:

### Layout principles (the "why" of positioning)

```
Top:     The goal itself (objective, success criteria, horizon,
         overall progress) — the "what" and "how far"

Middle:  The feature workflow (spatially arranged by sequence)
         - Sequential features: left -> right (flow)
         - Parallel features: same row, side by side
         - Branching: fork visual (Y-split)
         - Each feature = a NODE (icon + label + status)
         - Nodes connected by LINES (the workflow)
         - The CURRENT active node is PULSING (animation, AD-10
           AnimationController [G-M1])

Bottom:  Context strip (this week's stats, next focus session,
         coach suggestion, quick actions)
```

### Adaptive layouts per goal shape

The layout is NOT the same for every goal. The agent's composition
pattern (dynamic-goal-engine.md "5 shapes") drives the VISUAL:

**Preparation** (deadline-driven: exam, presentation, report):
```
+------------------------------------------+
|  ML Mastery — vendredi 20 nov            |  <- goal header
|  [==== 42% ====]  18/43 concepts         |  <- progress
+------------------------------------------+
|                                          |
|  [Gaps] --- [Recherche] --- [Import]    |  <- sequence (left->right)
|    |            |            |           |
|    v            v            v           |
|  [Fiches] --- [QCM] --- [Flashcards]    |  <- practice loop
|    |            |                        |
|    v            v                        |
|  [Focus] --- [Mirror] --- [Progress]    |  <- verify
|                                          |
+------------------------------------------+
|  Cette semaine: 3/5 focus | 2 QCM faits |  <- context strip
|  Suggestion: régime permanent (3 QCM)   |
+------------------------------------------+
```

**Practice** (ongoing: habits, skills, routines):
```
+------------------------------------------+
|  Habitudes sport — hebdomadaire         |
|  [==== 78% ====]  13/17 semaines        |
+------------------------------------------+
|                                          |
|        +----[Habit checkin]----+        |
|        |                       |        |
|        v                       v        |
|   [Focus 20min]          [QCM ciblées] |  <- parallel
|        |                       |        |
|        +-------[Progress]-----+        |  <- convergence
|                                          |
+------------------------------------------+
|  Streak: 5 semaines | Prochain: mardi   |
+------------------------------------------+
```

**Curation** (knowledge collection: veille, base de connaissances):
```
+------------------------------------------+
|  Veille normes GC — continue           |
|  [8/8 Q3]  [3/12 Q4 prévu]             |
+------------------------------------------+
|                                          |
|   [Recherche] --+                         |
|                  |                        |
|                  v                        |
|   [Connaissance] --+                      |
|                  |                        |
|                  v                        |
|   [Arbre] -- [Artifact (trimestriel)]    |  <- tree -> export
|                                          |
+------------------------------------------+
|  Dernière recherche: 12 oct (3 normes)   |
+------------------------------------------+
```

**Delivery** (project with milestones):
```
+------------------------------------------+
|  Rapport de stage — livraison 15 déc     |
|  [==== 55% ====]  5/9 sections           |
+------------------------------------------+
|                                          |
|  [M1] --- [M2] --- [M3] --- [M4] --- [M5]  <- milestones
|   done   done   ACTIVE  pending  pending  |
|              |                            |
|              v                            |
|         [Focus] [QCM] [Sheet] [Export]   |  <- active sub-goals
|                                          |
+------------------------------------------+
|  Jalon M3: "Synthèse" — due 28 nov       |
+------------------------------------------+
```

**Adaptation** (behavior change: discipline, anti-procrastination):
```
+------------------------------------------+
|  Discipline — réduction interruptions    |
|  [==== 60% ====]  -40% interruptions     |
+------------------------------------------+
|                                          |
|   [Progress (analyse)]                     |
|        |                                  |
|        v                                  |
|   [Gaps (pourquoi?)] --- [Re-plan]       |
|        |                                  |
|        v                                  |
|   [Focus + Blocklist] --- [Coach]         |  <- intervention
|        |                                  |
|        v                                  |
|   [Progress (vérif)]                      |  <- loop
|                                          |
+------------------------------------------+
|  Interrupt. cette sem: 4 (-2 vs sem.préc)|
+------------------------------------------+
```

## 3. Feature Nodes (the visual units)

Each feature in the dashboard is a **NODE**:

```
+------------------+
|  [icon]  QCM     |   <- icon + feature name (short)
|  12/20 faits     |   <- progress within this feature
|  [pulse]         |   <- if this is the ACTIVE step
+------------------+
```

**Node states:**
- `pending`: gray icon, no pulse
- `active`: accent icon + PULSE animation (AD-10 AnimationController,
  G-M1: `useAuroraAnimation` wrapper; reduced-motion = no pulse,
  static highlight)
- `done`: checkmark overlay, muted color
- `skipped`: strikethrough, tooltip "sauté par l'agent"
- `blocked`: red dot + tooltip (reason: "attend focus session")
- `error`: warning icon + retry CTA

**Node tap behavior:**
- `active` node -> deep link to the feature's screen (02 S6.1 route)
  WITH CONTEXT (context-preserving navigation: goalId + subGoalId
  in query params; the feature screen shows "dans le contexte de
  ML Mastery")
- `done` node -> review view (what was done, evidence refs)
- `pending` node -> "Commencer" CTA (agent confirms: "Tu veux
  commencer les QCM maintenant? 30 min estimées")

**Node position = meaning:**
- Left-to-right = sequence (the workflow order)
- Top-to-bottom = dependency (output of top feeds bottom)
- Side-by-side = parallel (no dependency between them)
- Centered/raised = the CURRENT focus (the node the agent recommends
  next)

## 4. Aesthetics Rules (NOT robotic)

**The Goal Dashboard must look like a carefully designed product
surface, not a generated form.**

| Rule | Detail |
|---|---|
| Spacing | 16px between node rows, 8px within a row (05 S2.1 spacing tokens). NOT uniform 20px everywhere. |
| Hierarchy | Goal header = H2 size; feature nodes = H4; context strip = body. Clear visual weight. |
| Color | Theme accent for active/progress (AD-17: theme = skin). Semantic tokens for state (success/warning/danger = independent of theme, 05 S2.1.3). |
| Lines | Connection lines between nodes = 1px, 40% opacity, rounded joins. NOT thick/dashed/animated (unless AD-10 AnimationController for the active path). |
| Icons | Lucide icons (05 S3, DS convention). 16px in nodes, 20px in header. NOT emoji, NOT custom SVG. |
| Animation | Only the ACTIVE node pulses (AnimationController, G-M1). Transitions = 200ms ease-out. NOT bouncy, NOT exaggerated. Reduced-motion = static highlight. |
| Typography | Inter / system font (05 S2.1). Feature labels = 13px/500. Progress % = 20px/700. Goal title = 16px/600. |
| Cards | Node = 8px radius (DS convention). Goal header = no card (full-width band). Context strip = no card (inline). ONLY the nodes are card-like. |
| Empty space | The dashboard BREATHES. Not every pixel is filled. The active node has 24px padding. The goal header has 16px top/bottom. |
| Theme adaptation | The goal dashboard uses the user's active theme (AD-17). A "Nocturne + Vesper" goal looks like a purple-tinged dark dashboard, NOT a generic gray one. |
| Local adaptation (OQ-15) | During an active Focus session, the goal dashboard's secondary nodes are ATTENUATED (40% opacity) — only the active node + progress bar are at full contrast. |

**What makes it NOT robotic:**
- The layout is ADAPTIVE (different per goal shape, not one grid for all)
- The agent's SUGGESTION appears as a natural language sentence in
  the context strip ("Régime permanent: 3 QCM à faire — veux-tu
  que je te les prépare?"), NOT as a system message
- Progress is VISUAL (bar + percentage + "18/43 concepts"), not a
  raw number
- The goal has a NAME the user gave in NL ("ML Mastery — 6 mois"),
  not "GoalProject_001"
- The icon set is intentional (target, loop, tree, milestone, spiral),
  not generic circles
- The spacing and hierarchy follow the DS tokens (05 S2.1), not
  auto-layout defaults

## 5. Agent -> UI Contract (how the agent's composition becomes a dashboard)

The agent creates the `GoalProject` (data). The UI renders it.
The contract between them:

```
Agent (server) writes GoalProject:
  - subGoals[] (with feature assignments)
  - timeline[] (sequence, parallel, branch)
  - progress (per sub-goal %)

UI (client) renders:
  - Goal header (objective, criteria, horizon, overall %)
  - Feature workflow (nodes + connections, from timeline[])
  - Context strip (stats, next action, coach suggestion)

The agent does NOT control pixel positions. The UI derives the
layout from the goal's shape + timeline structure. The agent's
contribution is the DATA (what features, in what order, with what
progress); the UI's contribution is the LAYOUT (where each node
sits, how lines connect, what the visual hierarchy is).
```

**If the agent adds a feature mid-goal** ("ajoute des QCM chaque
semaine"): the GoalProject is updated; the UI re-renders the
dashboard with the new node in the right position (the layout
algorithm re-computes from the updated timeline[]). No full reload.

## 6. Routing (02 S6.1, additive)

```
/home                    -> Home (GoalProject cards visible)
/goals                   -> Goals list (all GoalProjects, active + completed)
/goals/:id               -> Goal Dashboard (the screen spec'd above)
/goals/:id/features/:fid -> Feature detail (deep link from a node tap,
                             with goal context in query: ?goalId=X&subGoalId=Y)
```

**Context-preserving navigation:** tapping a feature node on the
Goal Dashboard navigates to the feature screen WITH `?goalId=X` in
the query. The feature screen shows a breadcrumb: "ML Mastery >
QCM Thermodynamique". Back = return to the Goal Dashboard (02 S6.2:
details open over the current tab, return to parent).

## 7. Multi-goal handling

- 2+ active goals: each has its own Goal Dashboard (separate routes)
- Home shows all active GoalProject cards (horizontal scroll or 2-up grid)
- If 2 goals conflict (both need `focus_session` at the same time):
  the agent sequences them (not parallel); the dashboard shows
  "Attends: Focus en cours sur 'Veille normes'"
- Completed goals: moved to a "Terminés" section (data preserved,
  AD-15; the card shows "✓ 100% — 12 déc" and is tap-able for review)

## 8. Performance (02 S9)

- Goal Dashboard render: < 100ms (local data, no server call on tap)
- Node layout computation: O(n) where n = number of features
  (typically 4-12; never > 20 in V1)
- Progress bar update: on `ProgressEvidenceCreated` event (AD-9)
  or local timer (focus session) — no polling
- Animation: pulse = CSS transform (GPU-accelerated), not JS
  re-render. 30 fps on Pixel 4a [OQ-11]
- Offline: GoalProject + subGoals + progress are in local mirror
  (PowerSync, 03 S4.2). The dashboard renders offline; "sync
  pending" badge if upsync queue > 0

## 9. What the user does NOT see

- Module names ("Discovery module", "Learning module") — NEVER
- Feature IDs ("qcm_generate") — the user sees "QCM" or
  "20 questions sur la thermo"
- Agent internals (Intent Engine, Context Builder, Tool Resolver)
- GoalProject JSON / timeline[] data structure
- The "5 shapes" (Preparation/Practice/Curation/Delivery/Adaptation)
  — these are internal composition patterns, not user-facing labels

The user sees: their goal, its progress, the next action, and the
agent's suggestions in natural language. The structure is THERE,
but it's invisible — it's the skeleton under the skin.
