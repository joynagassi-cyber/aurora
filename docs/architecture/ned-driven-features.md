# Aurora — Need-Driven Feature Architecture (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED`. Additive to the module-based architecture.
Authority: ADR S4 (intentions principales), ADR S12 (principe final: "simple en
surface, puissante en profondeur"), ADR S13 (Discovery), ADR S18 (Progress),
feature-registry.md S7 (product modes), kernel.md S12 (Intent Engine).

## Problem

The current architecture organizes features by **module** (Productivity,
Learning, Knowledge, Discovery, Progress, Artifacts, Agent, Scientific,
Integrations). This is correct for code ownership (AD-2, AD-13).

But the USER does not think in modules. The user thinks in **needs**:
- "Je dois preparer mon examen de geotechnique vendredi"
- "J'ai du mal a tenir mes habitudes de sport"
- "Je veux comprendre le chapitre 3 de thermodynamique"
- "Mes projets professionnels avancent mal"

The application must be structured so that **a clear need activates the
right combination of features**, pre-structured and interconnectable,
without the user having to navigate modules manually. The Agent detects
the need and orchestrates; the UI adapts to the active need.

## Architecture: 3 Layers

```
Layer 3: NEEDS (le "pourquoi" — declarative, user-visible)
  |
  | 1 need activates N features
  v
Layer 2: FEATURES (le "quoi" — module-owned, AD-2)
  |
  | features interconnect via AD-9 events + shared contracts
  v
Layer 1: MODULES (le "qui" — code ownership, AD-13)
```

- **Modules** own the code (AD-2, AD-13). Unchanged.
- **Features** are the user-facing capabilities (feature-registry.md S1).
  Unchanged.
- **Needs** are a NEW layer: named business goals that the user declares
  (explicitly or via Agent inference). A need is a **composition of
  features + a context + a success criterion**.

## Core Needs (V1 — 7 needs)

| Need ID | Name | User phrase | Success criterion |
|---|---|---|---|
| NEED-1 | **Examine Preparation** | "J'ai examen de X le [date], prepare-moi" | All exam topics covered (QCM >= 80%, sheets done, focus sessions planned) |
| NEED-2 | **Daily Productivity** | "Organise ma journee / semaine" | All critical tasks done, no overload, habits maintained |
| NEED-3 | **Concept Mastery** | "Je ne comprends pas X / verifie si j'ai compris" | Mirror analysis: no critical gaps; QCM >= 80% on the topic |
| NEED-4 | **Skill Building** | "Je veux apprendre / maitriser X" | SkillState = "mastered" (Progress); discovery gap closed |
| NEED-5 | **Focus / Discipline** | "Je m'ecarte / je procrastine / bloque-moi" | Focus adherence >= 80%; interruptions down; no blocklist violation |
| NEED-6 | **Project Delivery** | "Mon projet X avance mal / est en retard" | Milestones on track; replan executed; progress evidence positive |
| NEED-7 | **Knowledge Curation** | "Ajoute ca a mes notes / montre-moi l'arbre" | Semantic tree updated; sources traced; concepts linked |

**Rule:** needs are DATA (UserContext, AD-15), not code. Adding a need
= adding a row to `user_needs` table + a feature composition definition.
No new module. No new code path. The Agent's Intent Engine (kernel S12)
classifies the utterance into a need; the need's feature composition
determines which capabilities are active.

## Need -> Feature Composition (the pre-structured mapping)

Each need defines a **feature composition** = the set of features
activated + their interconnection rules + the agent's orchestration
pattern. This is pre-structured (designed, not improvised at runtime).

### NEED-1: Examine Preparation

```
Active features:
  learning.import (course for the exam)
  learning.sheet (revision sheets)
  learning.qcm (20+ QCM per topic)
  learning.flashcards (FSRS for weak items)
  learning.mirror (verify understanding)
  productivity.calendar (study blocks, exam date)
  productivity.focus (2-3h sessions)
  progress.analyze (tracking mastery per topic)
  discovery.gaps (identify weak areas)
  knowledge.tree (prerequisite check: "does she understand the
    prerequisite concepts?")

Interconnection (the workflow, pre-structured):
  1. discovery.gaps -> which topics are weak? (Progress skill_states)
  2. knowledge.tree -> prerequisites for those topics
  3. learning.import -> ensure courses are in KB
  4. learning.sheet -> generate revision sheets per topic
  5. productivity.calendar -> schedule study blocks (time blocking,
     exam date constraint)
  6. productivity.focus -> 2-3h sessions per block, blocklist
  7. learning.qcm + flashcards -> practice within blocks
  8. learning.mirror -> verify after each block
  9. progress.analyze -> is mastery >= 80%? If not, loop 4-8

Agent orchestration (Intent -> Plan):
  "J'ai examen de geotechnique vendredi"
  -> Intent: NEED-1 (exam prep)
  -> Context: exam date, course scope, current skill states
  -> Plan: 7 steps (1-7 above), confirmation at step 5 (calendar
     override) and step 6 (focus start)
  -> Monitor: Progress tracks mastery; Agent re-plans on < 80%

UI adaptation (product mode "Exam period", feature-registry S7):
  - Learning + Progress + Focus + Calendar = FRONT (emphasized)
  - Discovery + Projects + Analytics = MINIMIZED (data intact)
  - Home slots: "Examen: geotechnique vendredi" + "Prochain bloc
    etude: 09:00-11:00" + "Maitrise: 62% (objectif 80%)"
```

### NEED-2: Daily Productivity

```
Active features:
  productivity.inbox (capture + triage)
  productivity.tasks (daily task list)
  productivity.eisenhower (priority quadrant)
  productivity.calendar (time blocking, conflicts)
  productivity.habits (daily routines)
  productivity.focus (short sessions between tasks)
  productivity.reviews (end-of-day review)
  agent.coach (mid-day check-in, if enabled)

Interconnection:
  1. productivity.inbox -> triage -> tasks/events/projects
  2. productivity.eisenhower -> prioritize (agent-assisted)
  3. productivity.calendar -> time block (availability + energy)
  4. productivity.focus -> 25-50 min blocks (Pomodoro)
  5. productivity.habits -> anchor routines (morning/evening)
  6. productivity.reviews -> end-of-day: done / deferred / blocked
  7. agent.coach -> mid-day: "Tu es en retard sur X, veux-tu replanifier?"

Agent orchestration:
  "Organise ma journee"
  -> Intent: NEED-2 (daily productivity)
  -> Plan: inbox triage -> eisenhower -> calendar -> focus plan
  -> Confirm: calendar changes (CONFIRMATION_REQUIRED)
  -> Monitor: coach check-in at 14:00 (if enabled + silence window ok)

UI adaptation (product mode "Core"):
  - Inbox + Tasks + Calendar + Habits = FRONT
  - Focus = accessible (Home slot)
  - Learning/Discovery = available but de-emphasized
```

### NEED-3: Concept Mastery

```
Active features:
  learning.mirror (explain -> detect gaps)
  learning.qcm (targeted quiz on the concept)
  learning.flashcards (weak sub-concepts)
  knowledge.tree (where in the tree? prerequisites? bridges?)
  knowledge.retrieval (source material for the concept)
  scientific.evaluate (if the concept involves a formula)
  progress.evidence (record understanding evidence)

Interconnection:
  1. knowledge.retrieval -> source material (FTS + pgvector)
  2. learning.mirror -> user explains; agent detects gaps/contradictions
  3. knowledge.tree -> show concept in tree; prerequisites?
  4. learning.qcm -> 5-10 targeted questions on the weak sub-concepts
  5. learning.flashcards -> FSRS for the weak items
  6. scientific.evaluate -> verify formula understanding (if applicable)
  7. progress.evidence -> record "understood X" (F-07, Progress sole
     producer)

Agent orchestration:
  "Je ne comprends pas la loi d'Ohm"
  -> Intent: NEED-3 (concept mastery)
  -> Plan: retrieval -> mirror -> tree context -> QCM -> flashcards
  -> Confirm: none (all read/practice, no destructive action)
  -> Result: "Tu maitrises 4/5 sous-concepts; le courant en regime
    permanent est a re-travailler. 3 flashcards generees."

UI adaptation:
  - Current screen: concept detail + tree node expanded
  - Agent panel: mirror explanation + QCM inline
  - Flashcards: accessible from Learning > Flashcards
```

### NEED-4: Skill Building

```
Active features:
  discovery.research (what's the current state of the skill?)
  discovery.gaps (where am I vs where I need to be?)
  learning.import (courses/materials for the skill)
  learning.sheet + qcm + flashcards (practice)
  productivity.projects (skill as a project with milestones)
  productivity.calendar (practice schedule)
  progress.analyze (is the skill improving?)

Interconnection:
  1. discovery.gaps -> current skill level vs target
  2. discovery.research -> best resources (multi-source)
  3. learning.import -> ingest the resources
  4. productivity.projects -> "Skill: X" project with milestones
  5. productivity.calendar -> weekly practice schedule
  6. learning.sheet/qcm/flashcards -> practice within schedule
  7. progress.analyze -> is the skill trending up?

Agent orchestration:
  "Je veux maitriser le machine learning d'ici 6 mois"
  -> Intent: NEED-4 (skill building)
  -> Plan: gap analysis -> research -> project + milestones ->
     calendar -> practice loop
  -> Confirm: project creation + calendar (CONFIRMATION_REQUIRED)
  -> Monitor: monthly progress review; adjust pace if < target

UI adaptation (product mode "Study"):
  - Learning + Progress + Calendar = FRONT
  - Discovery = active (research)
  - Productivity (projects) = active
```

### NEED-5: Focus / Discipline

```
Active features:
  productivity.focus (sessions + blocklist + DPC)
  productivity.habits (routine adherence)
  agent.coach (discipline coaching, ADR S13)
  progress.analyze (discipline evidence, interruptions)

Interconnection:
  1. productivity.focus -> start session (blocklist, timer)
  2. productivity.habits -> "Did you do your morning routine?"
  3. agent.coach -> "Tu as 3 interruptions cette semaine, veux-tu
     bloquer TikTok?"
  4. progress.analyze -> discipline trend (interruptions/week)

Agent orchestration:
  "Je ne peux pas me concentrer"
  -> Intent: NEED-5 (focus/discipline)
  -> Plan: detect distraction pattern (Progress) -> suggest blocklist
     -> start focus session -> coach follow-up
  -> Confirm: blocklist change (CONFIRMATION_REQUIRED)

UI adaptation (product mode "Focus-heavy"):
  - Focus = FRONT (Home slot prominent)
  - Notifications suppressed (focus spec S8)
  - Coach cadence increased (within silence windows)
```

### NEED-6: Project Delivery

```
Active features:
  productivity.projects (Gantt/Kanban, milestones, dependencies)
  productivity.tasks (project tasks)
  productivity.calendar (deadline-driven planning)
  productivity.reviews (weekly project review)
  progress.analyze (on track? delay detection)
  agent.coach (replanning suggestion)
  artifacts.export (deliverables: reports, presentations)

Interconnection:
  1. productivity.projects -> current state (milestones, tasks)
  2. progress.analyze -> delay detection (planned vs actual)
  3. productivity.calendar -> replan remaining work
  4. productivity.reviews -> weekly: what's done / blocked / next
  5. artifacts.export -> deliverable generation (PDF, PPTX)
  6. agent.coach -> "Tu es en retard de 3 jours sur le milestone M2,
     voici un replan"

Agent orchestration:
  "Mon rapport de stage est en retard"
  -> Intent: NEED-6 (project delivery)
  -> Plan: assess delay -> replan tasks -> calendar blocks ->
     focus sessions -> artifact export (report template)
  -> Confirm: replan discards old plan (CONFIRMATION_REQUIRED)

UI adaptation:
  - Projects + Calendar + Reviews = FRONT
  - Artifacts = active (export)
  - Learning/Discovery = minimized
```

### NEED-7: Knowledge Curation

```
Active features:
  knowledge.tree (semantic tree: add/expand/link)
  knowledge.retrieval (search existing)
  learning.import (add new sources)
  artifacts.preview (view source documents)
  discovery.research (find new knowledge)

Interconnection:
  1. knowledge.retrieval -> "do I already have this?"
  2. learning.import -> add new source (camera/OCR/upload)
  3. knowledge.tree -> extract concepts -> create/link nodes
  4. artifacts.preview -> view the source document
  5. discovery.research -> "what's new on this topic?"

Agent orchestration:
  "Ajoute cette info a ma knowledge base"
  -> Intent: NEED-7 (knowledge curation)
  -> Plan: retrieval check -> import -> tree update -> confirm
  -> Result: "Ajoute: 2 concepts, 1 formule, lien avec 'Thermodynamique'"

UI adaptation:
  - Knowledge tree = FRONT
  - Artifacts = active (preview)
  - Discovery = optional (research)
```

## Need Detection (Agent Intent Engine)

The Intent Engine (kernel S12) classifies every utterance into:
- A **need** (NEED-1..7, or composite)
- A **task profile** (complexity, reasoning, tools, vision, ...)
- A **feature composition** (from the need's pre-structured mapping)

Detection rules (data-driven, NOT `if user === Horeb`):

```
UserContext.need (explicit): user selects a need in the UI
  -> feature composition = that need's mapping

Agent inference (implicit):
  utterance + context -> Intent Engine -> NEED-X
  "examen" + date + course -> NEED-1
  "organise" + "journee" -> NEED-2
  "comprends pas" + concept -> NEED-3
  "apprendre" + skill + horizon -> NEED-4
  "concentrer" / "procrastine" / "bloque" -> NEED-5
  "projet" + "retard" / "milestone" -> NEED-6
  "ajoute" + "notes" / "arbre" / "connaissances" -> NEED-7

Composite needs:
  "Prepare mon examen ET tiens mes habitudes"
  -> NEED-1 + NEED-2 (compound plan, single execution)
```

**A need is a DATA object** (AD-15, `packages/domain`):

```ts
interface UserNeed {
  id: string;                   // ULID
  userId: string;
  needType: 'exam_prep' | 'daily_productivity' | 'concept_mastery'
    | 'skill_building' | 'focus_discipline' | 'project_delivery'
    | 'knowledge_curation';
  subject?: string;             // "geotechnique", "machine learning", ...
  targetDate?: string;          // exam date, skill deadline
  successCriteria: string;      // "QCM >= 80%", "skill = mastered", ...
  activeFeatures: string[];     // feature ids (from the composition)
  createdAt: string;
  status: 'active' | 'completed' | 'abandoned';
}
```

The `UserContext` (Identity) references the active need(s); the feature
registry's availability policy (feature-registry.md S2) filters the
surface on the active need's `activeFeatures`.

## Interconnection Rules (per need, NOT per module)

The key insight: features interconnect **through the need's workflow**,
not through module boundaries. The module boundary (AD-2) is a code
ownership rule; the need's workflow is a **user value chain**.

Each need defines:
- **Entry feature:** where the user starts (e.g., NEED-1 starts at
  `discovery.gaps` or `productivity.calendar`)
- **Sequence:** the ordered feature activations (1-7 in NEED-1)
- **Branching:** conditional steps (e.g., "if mastery < 80% -> loop")
- **Confirmation points:** which steps need user confirmation (ADR S5)
- **Exit:** when the need is satisfied (success criterion met)
- **Events emitted:** AD-9 events that connect the features

The Agent's Planner (kernel S12) builds the execution plan FROM THE
NEED'S WORKFLOW, not by improvising feature combinations. The workflow
is pre-structured (designed, tested, documented); the Agent fills in
the parameters (dates, topics, durations) and executes.

## UI Adaptation (per active need)

The feature-registry product modes (S7) are the **default** surface.
An active need **overrides** the mode for the features it activates:

```
Default mode: "Core" (Productivity + Knowledge + Agent)
Active need: NEED-1 (Exam prep, geotechnique, Friday)
  -> Override: Learning + Progress + Focus + Calendar = emphasized
  -> Home slots: "Examen: geotechnique vendredi" + "Maitrise: 62%"
  -> Agent surface: exam-specific suggestions ("Reviser le chapitre 3")
  -> Notifications: exam reminders (OneSignal, server-state-driven)
  -> Focus: blocklist pre-filled (social apps, exam-period)
```

The override is DATA (UserContext.activeNeed), not code. When the need
completes or is abandoned, the surface reverts to the mode default.

## Data model (additive, AD-15)

| Entity | Owner | Table | Notes |
|---|---|---|---|
| `UserNeed` | Identity | `user_needs` | per-user, per-need; status lifecycle |
| `NeedFeatureComposition` | Identity | `need_feature_compositions` | needType -> feature ids + workflow steps (SSoT, defined in domain, seeded per needType) |
| `NeedProgress` | Progress | `need_progress` | per-need tracking: success criterion met? evidence refs |

`UserNeed` is NOT synced to the device (Identity, server-owned; the
device reads via `user_context` mirror which includes `activeNeed`).

## Agent capability (additive to feature-agentability-matrix.md)

| Capability ID | Feature | Status |
|---|---|---|
| `need.detect` | Intent Engine | FULL (server, wave 3) |
| `need.activate` | UserContext write | CONFIRMATION_REQUIRED (activating a need changes the surface) |
| `need.status` | read UserNeed + NeedProgress | FULL |
| `need.complete` | Progress sole-producer | FULL (on success criterion met) |
| `need.abandon` | UserContext write | CONFIRMATION_REQUIRED |

## What this does NOT change

- Module ownership (AD-2, AD-13): unchanged. Modules still own their
  tables, contracts, events.
- Feature registry (feature-registry.md S1): unchanged. Features are
  still declared per module.
- Agent kernel (kernel.md S12): unchanged. The 15 components still
  run the loop. The Intent Engine now classifies into NEED-X (in
  addition to task profile).
- AD-9 events: unchanged. The 9-event vocabulary is closed. Need
  completion emits `ProgressEvidenceCreated` (existing event).
- Code structure: no new packages. `UserNeed` + `NeedFeatureComposition`
  are in `packages/domain` (AD-15). The workflow definitions are
  server-side data (JSON in `user_needs` + seed in domain).

## Tests (wave 3+)

- Need detection: 20 E2E scenarios [e2e-agent-scenarios.md] re-mapped
  to needs (S1 = NEED-2, S2 = NEED-1, S4-5 = NEED-5, S6-7 = NEED-3,
  S10-11 = NEED-4, S17-19 = NEED-6, S15-16 = NEED-7)
- Feature composition: activating NEED-1 -> only NEED-1 features
  visible in UI; other features accessible but de-emphasized
- Workflow execution: NEED-1 loop (gaps -> sheets -> QCM -> mirror ->
  progress) completes; branching on < 80% triggers re-practice
- Need completion: success criterion met -> `ProgressEvidenceCreated`
  -> need status = "completed" -> UI reverts to mode default
- Composite needs: NEED-1 + NEED-2 compound plan executes without
  conflict
- Data integrity: `user_needs` rows are server-only; device mirror
  includes `activeNeed` in `user_context`
