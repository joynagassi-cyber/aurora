# Aurora — Dynamic Goal Engine (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 3+). **Replaces** the
fixed-need model of need-driven-features.md (v1, 7 hardcoded needs).
Authority: ADR S4 (intentions, deduction pas selection manuelle),
ADR S12 ("simple en surface, puissante en profondeur"), ADR S5
(orchestration agentique), kernel.md S12 (Intent + Planner),
feature-registry.md (capability discovery).

## Core Principle

**The user does not pick a category. The user states a goal in natural
language. The agent decomposes the goal, composes the right features,
positions them into a dynamic project, and tracks progress toward the
objective.**

```
User: "Je veux maitriser le machine learning d'ici 6 mois"
  -> Agent decomposes:
       sub-goal 1: "Evaluer ou j'en suis" (feature: progress.analyze)
       sub-goal 2: "Identifier les lacunes" (feature: discovery.gaps)
       sub-goal 3: "Trouver les meilleurs ressources" (feature: discovery.research)
       sub-goal 4: "Creer un plan d'etude" (feature: planning.daily + calendar)
       sub-goal 5: "Pratiquer regulierement" (feature: learning.qcm + flashcards + focus)
       sub-goal 6: "Verifier la maitrise" (feature: learning.mirror + progress)
       sub-goal 7: "Produire un livrable" (feature: artifact.export)
  -> Agent creates a GoalProject (dynamic, not pre-defined):
       "ML Mastery — 6 mois"
       features positioned + sequenced + interlinked
       progress tracked per sub-goal
       adaptive: si sub-goal 5 shows < 70% after 2 months,
       the agent re-composes (more focus sessions, targeted QCM)
```

## What is a Feature (atomic, composable)

A feature is NOT "Discovery" or "Productivity". Those are MODULES
(code ownership, AD-2). A feature is an **atomic capability** that
the agent can compose:

```
Atomic features (examples, NOT exhaustive — the registry grows):
  capture (inbox)
  task_create
  task_complete
  calendar_block
  time_block
  focus_session
  block_apps (DPC)
  habit_checkin
  review_run
  course_search
  course_import
  sheet_generate
  qcm_generate
  flashcard_generate
  mirror_analyze
  progress_analyze
  skill_track
  gap_detect
  research_run
  horizon_scan
  knowledge_add
  tree_expand
  artifact_export
  artifact_preview
  scientific_compute
  notification_schedule
  automation_toggle
  chat_explain
  chat_verify
  chat_coach
```

Each feature has:
- An **input schema** (what it needs to run)
- An **output schema** (what it produces)
- A **read scope** (what it can read)
- A **write scope** (what it can write)
- An **offline class** (offline-capable / online-required / hybrid)
- A **destructive flag** (is it irreversible?)
- A **confirmation flag** (does it need user confirmation?)
- A **module owner** (which module owns it, AD-2)

Features are registered in the **Capability Registry** (kernel S14,
registries.md S3). The agent DISCOVERS them; it does NOT hardcode a
list.

## What is a Goal (dynamic, user-stated)

A goal is a **natural language objective + success criterion + time
horizon**. It is NOT a fixed category. The user can state ANY goal:

```
"Je veux preparer mon examen de geotechnique vendredi"
"Je veux etre plus disciplinee dans mes habitudes de sport"
"Je veux publier un article de recherche sur le beton armé"
"Je veux rester a jour sur les nouvelles normes de genie civil"
"Je veux reduire mon temps de revision de 20%"
"Je veux comprendre la thermodynamique avant la fin du semestre"
"Je veux un portfolio pour ma candidature en master"
```

The agent does NOT classify into a fixed set. It DECOMPOSES:

```
Goal: "Je veux rester a jour sur les nouvelles normes de genie civil"
  -> Agent decomposes:
       sub-goal 1: "Quelles normes ont change recemment?"
         features: research_run + knowledge_add
       sub-goal 2: "Comment m'organiser pour la veille reguliere?"
         features: automation_toggle (cron) + notification_schedule
       sub-goal 3: "Creer une base de connaissances"
         features: knowledge_add + tree_expand + course_search
       sub-goal 4: "Produire un resume trimestriel"
         features: artifact_export + review_run
  -> GoalProject: "Veille normes GC"
       cadence: trimestriel
       features positioned: research (monthly) -> knowledge (continuous)
         -> tree (continuous) -> artifact (quarterly)
       progress: "3 normes nouvelles documentees / 8 detectees"
```

## The GoalProject (dynamic structure, NOT a fixed entity)

A `GoalProject` is what the agent CREATES when it decomposes a goal.
It is NOT a pre-defined entity in the domain. It is a **dynamic
composition of features + a timeline + a progress tracker**:

```ts
// Created by the Agent at runtime, stored in user_goals (Progress-owned)
interface GoalProject {
  id: string;
  userId: string;
  objective: string;              // the NL goal (verbatim)
  successCriteria: string;        // "QCM >= 80%", "8/8 normes documentees", ...
  targetDate?: string;            // optional deadline
  horizon: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'semester' | 'yearly';

  subGoals: SubGoal[];           // the decomposition
  features: FeaturePlacement[];  // which features, where, when
  timeline: TimelineBlock[];    // when each feature runs
  progress: GoalProgress;        // overall % + per-sub-goal %
  status: 'active' | 'paused' | 'completed' | 'abandoned';
  createdAt: string;
  updatedAt: string;
}

interface SubGoal {
  id: string;
  label: string;                 // "Identifier les lacunes ML"
  features: string[];            // feature ids that serve this sub-goal
  sequence: number;              // order (can be parallel)
  successCriteria: string;       // "skill_state >= fragile"
  status: 'pending' | 'active' | 'done' | 'skipped';
}

interface FeaturePlacement {
  featureId: string;            // "qcm_generate", "focus_session", ...
  role: string;                 // "practice", "verification", "scheduling", ...
  frequency: string;            // "daily", "per-block", "weekly", "on-event"
  position: string;             // "before: mirror_analyze", "after: course_import"
  config: Record<string, unknown>; // feature-specific params
}

interface GoalProgress {
  overallPct: number;
  subGoalProgress: Record<string, number>;
  lastUpdated: string;
  evidenceRefs: string[];       // ProgressEvidence ids (F-07)
}
```

**Key: the agent CREATES and MUTATES GoalProjects. The user does not
manually build them.** The user states the goal; the agent does the
rest. If the goal changes, the agent re-composes (re-plans, ADR S13:
"recalcul du planning restant sans detruire l'historique").

## Feature Composition (the agent's core job)

The agent's Planner (kernel S12) does NOT have a hardcoded mapping
"exam -> features 1-7". It uses:

1. **Capability Registry** (what features exist, their inputs/outputs)
2. **Progress data** (where the user is: skill states, evidence)
3. **Knowledge data** (what's in the KB, gaps, tree)
4. **UserContext** (preferences, silence windows, exam period, ...)
5. **The goal's NL description** (the agent's LLM decomposition)

The LLM decomposes the goal into sub-goals; the Planner maps each
sub-goal to features from the registry; the Result Normalizer checks
the composition is valid (inputs match outputs, no circular deps,
offline class compatible with the user's connectivity pattern).

**This is why the agent must have LLM access: the decomposition is
NOT deterministic. "Je veux rester a jour" can mean 3 very different
compositions depending on the user's domain, current state, and
preferences. A fixed mapping cannot handle this.**

## The 5 "shapes" (NOT categories — patterns the agent recognizes)

These are NOT user-facing categories. They are **composition patterns**
the agent recognizes in the goal and uses as templates for the Planner.
The user never sees "Discovery" or "Productivity". They see their goal
and the agent's plan.

| Pattern | Agent recognizes when... | Typical feature composition |
|---|---|---|
| **Preparation** | goal has a deadline + a domain (exam, presentation, report) | gap_detect -> research -> course_import -> sheet -> qcm -> flashcards -> focus -> mirror -> progress |
| **Practice** | goal is ongoing + repetitive (habits, skills, routines) | habit_checkin -> focus_session -> qcm/flashcards -> progress_analyze -> (weekly) review_run |
| **Curation** | goal is about collecting/organizing knowledge | knowledge_add -> tree_expand -> research (optional) -> artifact_export |
| **Delivery** | goal is a project with milestones | project_create -> task_create -> calendar_block -> focus -> artifact_export -> review |
| **Adaptation** | goal is about improving/changing a behavior | progress_analyze -> gap_detect -> (re)plan -> focus -> habit -> coach (bounded) |

The agent can use ONE pattern, COMBINE patterns, or INVENT a new
composition that doesn't fit any pattern (the LLM handles the
novelty). The patterns are HINTS for the Planner, not constraints.

## What the user sees (NOT module names)

```
Home (when a GoalProject is active):
  "ML Mastery — 6 mois"
  ├─ "Où j'en suis : 42% (18/43 concepts maîtrisés)"
  ├─ "Prochain bloc : Aujourd'hui 14h — QCM Thermodynamique (30 min)"
  ├─ "Cette semaine : 3 sessions Focus faites, 2 flashcards à réviser"
  └─ "Suggestion : Tu es fragile en 'Régime permanent' — veux-tu 20 min de QCM ciblées ?"

Agent chat:
  "On a couvert 3 concepts cette semaine. Tu es à 42%.
   Pour atteindre 80% avant l'examen, il me faut 4 sessions de plus.
   Je te propose de glisser 2 blocs de 45 min dans ta semaine. OK ?"
  [Confirmer] [Ajuster] [Reporter]
```

The user NEVER sees "Discovery module" or "Learning module". They see
their goal, their progress, and the agent's suggestions.

## Data model (additive, AD-15)

| Entity | Owner | Notes |
|---|---|---|
| `GoalProject` | Progress (AD-6: Progress owns progress data) | created by Agent, read by all modules via public view |
| `SubGoal` | Progress | nested in GoalProject |
| `FeaturePlacement` | Agent (server) | the composition data; not synced to device (AD-3) |
| `GoalProgress` | Progress | sole-producer rule (F-07): only Progress emits `ProgressEvidenceCreated` for goal progress |
| `user_needs` (replaced) | Identity | **deprecated** — replaced by `GoalProject` (dynamic, agent-created) |

**The `UserNeed` entity from need-driven-features.md v1 is replaced
by `GoalProject`.** A need was a fixed category; a goal is a dynamic
composition. The agent creates the goal; the user states the objective.

## Agent capabilities (additive)

| Capability | What it does |
|---|---|
| `goal.create` | NL objective -> decompose -> create GoalProject (CONFIRMATION_REQUIRED: the user sees the plan before it's active) |
| `goal.status` | read GoalProject + GoalProgress |
| `goal.recompose` | re-plan a GoalProject when progress stalls or context changes (ADR S13: "recalcul sans detruire l'historique") |
| `goal.pause` | pause active features (jobs stop, notifications mute) |
| `goal.complete` | mark completed when success criteria met (Progress sole-producer) |
| `goal.abandon` | mark abandoned (data preserved, features deactivated) |
| `goal.feature.add` | add a feature to the composition ("et ajoute des QCM chaque semaine") |
| `goal.feature.remove` | remove a feature ("plus besoin de focus sur ce but") |

## UI (adaptive, goal-centric)

- **Home** = active GoalProject(s) front and center (AD-14: "Qu'est-ce
  qui compte maintenant?" = the goal's next action)
- **Agent chat** = the goal's progress + suggestions + confirmations
- **Feature screens** = accessible but NOT the primary navigation
  (the goal IS the navigation; features are tools within it)
- **No "Discovery" tab, no "Learning" tab, no "Productivity" tab** in
  the goal-centric view. Those are module-level screens for power users.
  The goal view composes features into a workflow the user follows.

The feature-registry product modes (S7) still work: "Exam period" mode
emphasizes the goal's features. But the PRIMARY surface is the goal,
not the mode.

## What this does NOT change

- Module ownership (AD-2, AD-13): unchanged. Features still belong to
  modules. The GoalProject is a VIEW over features, not a new module.
- Capability Registry (kernel S14): unchanged. The agent discovers
  features from the registry.
- AD-9 events: unchanged. Goal completion emits
  `ProgressEvidenceCreated` (existing event).
- Code structure: no new packages. `GoalProject` types in
  `packages/domain` (AD-15). The GoalProject entity is Progress-owned
  (data) + Agent-owned (creation/composition logic).
- Existing features: all still work standalone (without a goal). The
  goal is an OPTIONAL composition layer. A user can use `focus.start`
  without a GoalProject.

## Tests (wave 3+)

- Goal creation: NL -> GoalProject (sub-goals, features, timeline)
- Goal recomposition: progress stall -> agent re-plans (ADR S13)
- Feature add/remove: "ajoute des QCM" -> FeaturePlacement updated
- Goal completion: success criteria met -> `ProgressEvidenceCreated`
- Goal pause: active features stopped, notifications muted
- Cross-goal: 2 active goals, no feature conflict (2 goals both need
  `focus_session` -> the agent sequences them, not parallel)
- NL diversity: 20 different goal statements -> 20 different
  compositions (NOT 7 fixed templates)
