# Ascent — Pedagogical Trajectory Engine (Aurora)

**Status:** `PROPOSED` (not yet a frozen ADR decision). This document is
the prescriptive design for Ascent, the adaptive learning trajectory
engine. It is additive to the existing module architecture. No existing
module is modified; Ascent is a NEW module that sits above Learning,
Knowledge, Progress, and Discovery.

---

## 1. Purpose

Ascent is the **pedagogical trajectory engine** of Aurora. It answers
one question that no other module answers:

> "Given what Horeb already knows, what she is trying to learn, and
>  how she is progressing — in what ORDER, at what PACE, with what
>  DEPTH, should she learn next?"

It is NOT a second Learning engine. It does not generate QCMs,
flashcards, or study sheets. It does not store concepts or formulas.
It does not track evidence. It does not search the web.

It composes a **LearningPath** from the existing modules and adapts
that path as new evidence arrives.

## 2. Scope

### Ascent OWNS (and only these):

- The **trajectory** (order of concepts/skills to learn)
- The **priorities** (what to learn next, and why)
- The **composition** of a training (which modules, in what sequence)
- The **adaptation** (reorder, accelerate, slow down, insert remediation)
- The **prerequisites** (what must be mastered before the next step)
- The **progression decisions** (when to move on, when to revisit)
- The **depth selection** (Quick / Standard / Deep per concept)
- The **READ → DO → PROVE** sequencing (pedagogical framework)

### Ascent does NOT own:

| Concern | Owner | Why |
|---|---|---|
| Concepts, formulas, documents, sources, provenance | **Knowledge** | Content storage and retrieval (AD-6, AD-11) |
| QCMs, flashcards, exercises, FSRS, active recall | **Learning** | Practice and consolidation (01 S4.2) |
| Evidence, mastery states, trends, gaps | **Progress** | Measurement and proof (01 S4.4, F-07) |
| Discoveries, research, changes, emerging topics | **Discovery** | External knowledge acquisition (01 S4.5) |
| Spaced repetition scheduling | **FSRS** (Learning) | Memory decay and review timing (03 S4.2) |
| Representation choice (text, formula, diagram, infographic) | **Explain Engine** (Artifact) | How to SHOW a concept (AD-10 renderers) |
| Interactive presentation of a path | **Slide-Ascent** | UI format, NOT the engine (S8 below) |
| Deterministic computation | **Scientific Engine** | Math/units/verification (ADR S15) |

**Rule: Ascent reads from Knowledge, Learning, Progress, and Discovery
via their public contracts. It NEVER writes to their tables.** It emits
its own decisions (LearningPath, adaptations) as data that the Agent
Kernel consumes and the UI renders.

## 3. Responsibilities (exact)

1. **Build a LearningPath** from a goal + learner baseline + available
   knowledge. The path is a typed IR (AscentLearningIR, S4 below).
2. **Adapt the path** when new ProgressEvidence arrives (mastery
   changed, a prerequisite was missed, a gap was discovered).
3. **Select depth** per concept (Quick / Standard / Deep) based on
   the learner's current state + the goal's requirements.
4. **Sequence READ → DO → PROVE** for each step, with the
   understanding that this is a FRAMEWORK, not a rigid constraint
   (the Agent can reorder if context demands it).
5. **Decide when to move on** (progression criterion met) and when
   to **revisit** (prerequisite weakened, forgetting detected).
6. **Compose the path** from existing Learning/Knowledge/Discovery
   objects — it does not create new content, it ARRANGES existing
   content.

## 4. Non-Responsibilities

- Ascent does NOT generate QCMs, flashcards, or study sheets.
  It tells Learning: "generate a QCM on concept X, depth Standard,
  10 items." Learning does the work.
- Ascent does NOT store concepts or formulas. It references them
  by ID (Knowledge SSoT, AD-6).
- Ascent does NOT compute evidence. It reads Progress
  (SkillState, ProgressEvidence) to make decisions.
- Ascent does NOT search the web. It reads Discovery results.
- Ascent does NOT render anything. It outputs a LearningPath (data).
  The UI (Slide-Ascent) renders it.

## 5. Architecture (position in Aurora)

```
                    USER GOAL ("Master RDM by exam day")
                              |
                              v
                    +------------------+
                    |   ASCENT ENGINE  |   <- NEW module (server, wave 3+)
                    |  (trajectory)   |
                    +--------+---------+
                             |
              reads via public contracts (AD-2):
              +----+----+----+----+
              |    |    |    |    |
              v    v    v    v    v
          Knowledge  Progress  Discovery  Learning  FSRS
          (content, (evidence, (gaps,     (items,   (due
           tree,     mastery,   research)  QCMs,    reviews)
           sources)  gaps)      (items)    sheets)
                             |
                             v
                    +------------------+
                    |  LearningPath    |   <- Ascent's output (data, not UI)
                    |  (AscentLearningIR)
                    +--------+---------+
                             |
              consumed by:
              +----+----+----+
              |    |    |    |
              v    v    v    v
          Agent   Slide-  Goal   Progress
          Kernel  Ascent  Project (evidence
          (plan) (UI)    (track)  triggers
                              |
                              v
                    +------------------+
                    |  PROGRESS        |   <- evidence updates the path
                    |  (feedback loop) |
                    +------------------+
```

**Ascent is a SERVER-SIDE module** (AD-12, same as Agent Kernel).
It does not run on the device. The device receives the LearningPath
via PowerSync (local mirror) and renders it through Slide-Ascent.

## 6. Domain Model (AscentLearningIR + supporting types)

### 6.1 AscentLearningIR (the path itself)

```ts
// packages/domain/ascent.ts (SSoT, AD-15)
// PROPOSED: this type does not yet exist in packages/domain.
// It is additive — no existing type is modified.

interface AscentLearningIR {
  id: string;                        // ULID
  userId: string;
  goal: string;                     // "Master RDM by exam day" (NL, verbatim)
  targetSkill?: string;             // skill_id (Progress) if applicable
  targetDate?: string;             // optional deadline

  // What to learn (ordered)
  steps: AscentStep[];             // the sequence

  // How to learn (per step, adaptive)
  depth: Record<string, DepthLevel>;  // stepId -> Quick/Standard/Deep

  // Starting point
  baseline: LearnerBaseline;

  // Prerequisites (must be mastered before proceeding)
  prerequisites: {
    stepId: string;
    requires: string[];            // stepIds or skill_ids
    status: 'met' | 'pending' | 'remediation_needed';
  }[];

  // Progression criteria
  passageCriteria: {
    stepId: string;
    criterion: string;            // "QCM >= 80%", "all FSRS due items reviewed"
    metric: string;               // which Progress metric to check
    threshold: number;
  }[];

  // Adaptation log (audit trail)
  adaptations: AscentAdaptation[];

  // Status
  status: 'active' | 'paused' | 'completed' | 'abandoned';
  createdAt: string;
  updatedAt: string;
}

interface AscentStep {
  id: string;
  label: string;                   // "Flexion simple — poutre appui simple"
  conceptRefs: string[];          // Knowledge concept_ids (NOT content)
  skillRef?: string;             // Progress skill_id
  sourceRefs: string[];          // SourceRef[] (AD-11 provenance)

  // What to DO (delegated to Learning)
  activities: AscentActivity[];

  // READ → DO → PROVE (framework, not rigid)
  phase: 'read' | 'do' | 'prove' | 'remediation' | 'recap';

  // Depth
  depth: DepthLevel;

  // Status
  status: 'pending' | 'active' | 'done' | 'skipped' | 'remediation';
}

interface AscentActivity {
  id: string;
  type: 'read' | 'practice' | 'quiz' | 'flashcard' | 'mirror'
       | 'exercise' | 'review' | 'remediation' | 'recap';
  // What to delegate to Learning:
  learningCommand?: {
    action: 'generate_qcm' | 'generate_flashcards' | 'create_exercise'
           | 'start_mirror' | 'review_due';
    params: Record<string, unknown>;  // depth, item_count, topic
  };
  // What to read (Knowledge):
  knowledgeRef?: {
    type: 'concept' | 'formula' | 'document' | 'source';
    id: string;
  };
}

type DepthLevel = 'quick' | 'standard' | 'deep';
```

### 6.2 LearnerBaseline (what the user already knows)

```ts
interface LearnerBaseline {
  userId: string;
  // Per-skill state (from Progress SkillState, NOT a re-declaration):
  skillStates: {
    skillId: string;
    status: 'unknown' | 'partial' | 'known' | 'fragile' | 'mastered';
    // Multi-dimensional (NOT a single score):
    dimensions?: {
      understanding?: number;   // 0-1 (can explain it)
      recall?: number;          // 0-1 (can retrieve it)
      application?: number;     // 0-1 (can use it in a problem)
      autonomy?: number;        // 0-1 (without help)
      retention?: number;       // 0-1 (after 1 week)
    };
    lastEvidence: string;       // ProgressEvidence id
    freshness: string;          // ISO date (how recent the evidence is)
  }[];
  // Derived:
  gaps: string[];              // skill_ids where status = 'unknown' | 'partial'
  fragiles: string[];         // skill_ids where status = 'fragile'
  mastered: string[];          // skill_ids where status = 'mastered'
  computedAt: string;
}
```

**Rule: the 5 states (Unknown/Partial/Known/Fragile/Mastered) are
NEVER reduced to a single 0-100 score.** The dimensions
(understanding, recall, application, autonomy, retention) are
optional but preferred. A concept can be "mastered in understanding
but fragile in application" — a single score would hide this.

**Source: Progress (SkillState, 01 S4.4). Ascent READS this, never
writes it.**

### 6.3 AscentAdaptation (the change log)

```ts
interface AscentAdaptation {
  id: string;
  pathId: string;
  trigger: string;             // "ProgressEvidence: RDM.flexion QCM 50% < 80%"
  action: 'reorder' | 'accelerate' | 'slow_down' | 'insert_remediation'
         | 'skip' | 'deepen' | 'shallow' | 'revisit' | 'recompose';
  detail: string;             // "Moved step 'FEM validation' after 'manual
                              //  flexion' because prerequisite not met"
  affectedSteps: string[];   // stepIds changed
  createdAt: string;
  // PROVENANCE:
  evidenceRefs: string[];    // ProgressEvidence ids that triggered this
}
```

## 7. Interfaces / Contracts (Ports)

Ascent consumes these existing ports (AD-2, no new ports needed):

| Port | From | What Ascent reads |
|---|---|---|
| `KnowledgeBase` | Knowledge | concepts, formulas, source_refs (for step content) |
| `ProgressEvidence` (public view) | Progress | skill_states, progress_evidences (for baseline + adaptation) |
| `DiscoveryService` (public view) | Discovery | discovery_items, gaps (for "what's new / what's missing") |
| `ObjectiveManager` (public view) | Productivity | goals, projects (for the target) |
| `FeatureRegistry` | Feature Registry | which features are enabled (if Learning is off, the path degrades) |

Ascent produces:

| Output | Consumer | Format |
|---|---|---|
| `AscentLearningIR` | Agent Kernel (Context Builder) | Data (not an AD-9 event) |
| `AscentAdaptation` | Progress (evidence trigger), Agent (replan) | Data + log |
| `LearningPathCommand` | Learning (generate QCM/flashcards) | Domain command (AD-7, via use-case) |

**Ascent does NOT emit new AD-9 events.** It is a consumer of
existing events + a producer of domain commands. No additive ADR
needed for the event vocabulary.

## 8. Data Flow

```
1. USER states a goal: "Master RDM by Friday"
   -> Agent Kernel (Intent Engine): goal detected
   -> Ascent: build LearningPath
      - READ: LearnerBaseline (Progress skill_states)
      - READ: Knowledge (RDM concepts, formulas, tree)
      - READ: Discovery (any new RDM-related findings)
      - READ: Learning (existing QCMs, flashcards on RDM)
      - BUILD: AscentLearningIR (steps, prerequisites, depth, activities)
      - WRITE: ascent_paths (Ascent's own table, AD-7 single-writer)

2. USER works through the path (Slide-Ascent UI)
   -> Learning executes activities (QCM, flashcards, mirror)
   -> Progress captures evidence (ProgressEvidenceCreated, F-07)
   -> Ascent observes evidence (via public view + event)
   -> If evidence changes a step's status: AscentAdaptation
      - "Step 'Flexion simple' passed (QCM 85% > 80%) -> move to next"
      - "Step 'FEM validation' blocked (prerequisite 'manual flexion'
        not mastered) -> insert remediation"

3. PATH COMPLETION
   -> All steps done -> AscentLearningIR.status = 'completed'
   -> GoalProject (dynamic-goal-engine.md) progress updates
   -> Progress: final SkillState snapshot
   -> Ascent: archive the path (data preserved, not deleted)
```

## 9. Persistence (Ascent's own tables)

| Table | Owner | Sync | Notes |
|---|---|---|---|
| `ascent_paths` | Ascent | Server-only (like expert_skills, AD-3) | The LearningPath data |
| `ascent_steps` | Ascent | Server-only | Individual steps |
| `ascent_adaptations` | Ascent | Server-only (append-only log) | Change history |
| `ascent_baselines` | Ascent | Server-only | Snapshot of LearnerBaseline at path creation |

**Rule: Ascent tables are SERVER-ONLY (like expert_skills, 03 S4.2).**
The device reads the CURRENT path via PowerSync mirror (read-only).
Adaptations are computed server-side (AD-12, same as Agent Kernel).

## 10. READ → DO → PROVE (Pedagogical Framework)

This is a FRAMEWORK, not a rigid constraint.

| Phase | Purpose | Example (RDM flexion) | Ascent decides |
|---|---|---|---|
| **READ** | Understand the concept | Read the definition + 1 formula + 1 diagram | Depth: how much to read |
| **DO** | Practice with guidance | 5 guided exercises (increasing difficulty) | Type: exercise, not QCM |
| **PROVE** | Demonstrate mastery independently | 20-item QCM + 1 open problem | Threshold: >= 80% to pass |

**The Agent (via Ascent) can REORDER if context demands:**
- "Horeb already knows the formula (Progress: mastered) but can't
  apply it to a new problem type" -> skip READ, go to DO
- "Horeb is in exam week, time-constrained" -> Quick depth,
  only PROVE (the QCM is the priority, not the reading)
- "Horeb is stuck on a prerequisite" -> insert remediation
  BEFORE the main step (slow_down + insert_remediation)

**Never force the sequence mechanically.** The sequence is a
DEFAULT, not a RULE. Ascent adapts it.

## 11. Progressive Disclosure (UX Principle)

The user does NOT see the entire path at once. They see:

```
Level 1 (always visible):
  "What to learn next" = current step + next step

Level 2 (on tap / expand):
  Current step details: concept, formula, 1 example,
  the activity to do NOW

Level 3 (on demand):
  Full path overview (all steps, status, timeline)
  Prerequisites map
  Depth level + why this depth was chosen
  Sources (AD-11 provenance)

Level 4 (contextual panel):
  Related concepts (Semantic Tree neighbors)
  Cross-domain bridges (if activated)
  Progress history for this skill
  "Why this order?" (adaptation log)
```

**Rule: show the information when it becomes useful. Not before.**
The user should never be overwhelmed by the full path on first load.

## 12. Slide-Ascent (Presentation Format, NOT the Engine)

Slide-Ascent is the **UI format** for presenting an AscentLearningIR.
It is NOT the engine. The engine produces data; Slide-Ascent renders
it.

```
Ascent (engine) -> AscentLearningIR (data) -> Slide-Ascent (UI)
```

### Slide types (a PALETTE, not a mandatory sequence):

| Type | When used | Content |
|---|---|---|
| **Concept** | Introducing a new idea | Definition + 1 diagram + 1 example |
| **Definition** | Formal statement | Precise definition + conditions + source |
| **Formula** | Mathematical content | KaTeX + variable meanings + units + conditions |
| **Diagram** | Visual explanation | AntV diagram / SVG / image |
| **Example** | Concrete application | Worked problem + step-by-step |
| **Analogy** | Bridging understanding | "Think of it like..." (labeled as analogy, NOT fact) |
| **Timeline** | Historical / sequential | When/why things evolved |
| **Comparison** | Distinguishing concepts | Side-by-side (e.g., BAEL vs Eurocode 2) |
| **Question** | Active recall | Prompt the user to answer before showing |
| **Exercise** | Practice | Guided or open problem |
| **Reflection** | Metacognition | "What did you learn? Where were you stuck?" |
| **Recap** | Consolidation | Summary of the session + next steps |

**Rules:**
- These types are a PALETTE. The path does NOT have to use all 12.
- A 5-concept path might use: Concept, Formula, Example, Question, Recap.
- A deep-dive might use all 12.
- **Never impose 10 slides per course.** The number of slides =
  the number of meaningful transitions in the path.
- Each slide is a VIEW over the AscentLearningIR data. The data
  is the source of truth; the slides are rendering.

## 13. Depth Levels (Quick / Standard / Deep)

Three levels. They modify CONTENT, not ARCHITECTURE.

| Level | What changes | Example (RDM flexion) |
|---|---|---|
| **Quick** | 1 concept + 1 formula + 1 example + 1 QCM (5 items) | "What is M_max? M = PL/4. Here's a 5-question quiz." |
| **Standard** | Concept + formula + 2 examples + 10 QCM + 3 flashcards + 1 exercise | "Full understanding: definition, formula, 2 examples, practice." |
| **Deep** | All of Standard + derivation + 3 examples (increasing complexity) + 20 QCM + 10 flashcards + open problem + mirror + cross-domain bridge | "Mastery: prove the formula, solve 3 hard problems, explain to the mirror, connect to FEM." |

**The depth is selected by Ascent based on:**
- The goal's requirements (exam = Deep for core topics, Quick for minor ones)
- The learner's current state (mastered = skip, fragile = Standard, unknown = Quick first)
- Time available (exam week = Quick for low-priority, Deep for high-priority)
- The concept's importance in the trajectory (prerequisite = Deep, peripheral = Quick)

**The 3 levels use the SAME architecture.** No separate code paths.
The difference is in the AscentLearningIR data (which activities,
how many items, which depth). The rendering is identical.

## 14. Active Reading (Light Interaction Layer)

When the user is reading a concept/formula/document in the path,
they can trigger lightweight interactions WITHOUT leaving the flow:

| Action | What it does | When available |
|---|---|---|
| **Explain** | "Explain this to me in simpler terms" -> Agent generates a simplified explanation (labeled as Aurora explanation, NOT corpus, AD-11) | Always |
| **Note** | Add a personal note to this concept (stored in Productivity `notes`) | Always |
| **Flashcard** | "Turn this into a flashcard" -> Learning creates a flashcard from the selected content | If Learning is enabled |
| **Visualize** | "Show me a diagram" -> Artifact generates an AntV/KaTeX visualization | If the concept has a formula/diagram |
| **"Je bloque"** | "I'm stuck on this" -> Agent diagnoses (Mirror-style) + suggests remediation | Always |

**The "Je bloque" flow:**
```
User: "Je bloque sur la formule M = PL/4"
  -> Ascent: diagnostic (which sub-concept is the blocker?)
  -> Agent: "The issue is likely the shear force diagram.
     Do you want a 5-min visual explanation + 2 practice problems?"
  -> User confirms
  -> Learning: generates 2 targeted exercises (remediation)
  -> Progress: evidence = "remediation on shear diagram"
  -> Ascent: adaptation = "inserted remediation before step 4"
```

**Rule: start with 5 actions. Do NOT add 15 contextual actions
on every element. The 5 above cover 90% of needs.**

## 15. Engineering / Science Rigor (link to Scientific Engine)

Ascent respects the LLM/Engine/Verifier/Knowledge separation
(ADR S15, engineering-intelligence-layer.md):

```
When Ascent includes a "prove" activity on a technical concept:
  1. The user does the QCM (Learning)
  2. The answers are checked by the Scientific Engine (deterministic)
  3. The verification is by invariants (equilibrium, dimensional)
  4. The result is a SolverResult (structured, traceable)
  5. Progress captures the evidence
  6. Ascent adapts the path based on the evidence

Ascent NEVER asks the LLM to "check the answer."
The LLM explains. The Engine computes. The Verifier validates.
```

## 16. External Corpora (GenieCivilPDF, courses, norms)

Ascent treats external content with a source hierarchy:

| Level | Source | Authority | Example |
|---|---|---|---|
| **A** | Normative / official (Eurocode, BAEL, regulations) | Highest (legal) | "Dimension per Eurocode 2 6.2" |
| **B** | Academic / university (identified courses, professors) | Pedagogical | "Cours RDM du Prof. X" |
| **C** | Technical secondary (GenieCivilPDF, textbooks, solved problems) | Reference | "Exercice from GenieCivilPDF" |
| **D** | Non-authoritative (blog, forum, AI-generated) | Exploration only | "YouTube explanation" |

**Rule: Level D NEVER overrides Level A/B/C.**
If a Level C example contradicts a Level A norm, the norm wins.
Ascent flags the conflict: "GenieCivilPDF uses method X (Level C),
but Eurocode 2 requires method Y (Level A). Following Level A."

**Provenance (AD-11) on every Ascent step:**
- Which source (level, document, page/section, date)
- Which course (if the user provided one)
- Which norm (if a normative method is used)
- The Ascent path is traceable to its sources

## 17. Events (only the ones that matter)

Ascent does NOT emit new AD-9 events. It consumes existing ones:

| Event (AD-9) | How Ascent uses it |
|---|---|
| `ProgressEvidenceCreated` | Trigger for adaptation (mastery changed) |
| `SkillStateChanged` | Baseline update (a skill went from fragile to mastered) |
| `DiscoveryItemCreated` | "New gap detected" -> Ascent may insert a new step |
| `GoalUpdated` | Goal changed -> Ascent recomposes the path |
| `TaskCompleted` | Practice activity done -> Ascent checks passage criteria |
| `ArtifactGenerated` | Study sheet ready -> Ascent marks the READ phase complete |

**Ascent produces:** `AscentAdaptation` (its own log, NOT an AD-9 event).
The Agent Kernel reads Ascent's data (Context Builder, 01 S5.6) when
planning the next session.

## 18. Security

- Ascent data is user-scoped (RLS, AD-2)
- Ascent tables are server-only (AD-3, like expert_skills)
- The LearningPath does NOT contain sensitive content
  (it references Knowledge/Learning objects by ID)
- Source hierarchy enforcement: Ascent cannot use Level D to
  override Level A (data policy, 01 S6)

## 19. Testing

| Test | What it verifies |
|---|---|
| Baseline accuracy | LearnerBaseline matches Progress skill_states (no re-declaration) |
| Prerequisite enforcement | Step 3 cannot be "active" if step 2 (prerequisite) is not "done" |
| Adaptation on evidence | QCM 50% on step 2 -> Ascent inserts remediation before step 3 |
| Depth selection | Exam goal + 2 weeks -> Deep for core, Quick for peripheral |
| READ→DO→PROVE flexibility | Skip READ if Progress shows "mastered" (no forced sequence) |
| Slide-Ascent rendering | 12 slide types render correctly, palette (not mandatory sequence) |
| Source hierarchy | Level D source does NOT override Level A (Ascent flags conflict) |
| Progressive disclosure | Level 1 shows only current + next step (not full path) |
| "Je bloque" flow | Stuck -> diagnosis -> remediation -> new evidence -> adaptation |
| Offline | Path readable offline (local mirror); adaptations computed server-side |
| RLS | User A cannot read user B's AscentLearningIR |

## 20. Implementation Notes

- **Wave:** 3+ (after Learning, Progress, Knowledge are live)
- **Owner:** Ascent module (new, packages/ascent)
- **Server-side only** (AD-12, like Agent Kernel)
- **No new AD-9 events** (consumes existing 9, produces AscentAdaptation)
- **No new ports** (consumes existing KnowledgeBase, ProgressEvidence,
  DiscoveryService, ObjectiveManager)
- **No new Edge Function** (Ascent runs inside fn-agent-run or a
  dedicated fn-ascent, wave 3+)
- **Table: 4** (ascent_paths, ascent_steps, ascent_adaptations,
  ascent_baselines) — all server-only
- **80/20 rule:** the minimum viable Ascent = 1 table
  (ascent_paths with steps JSONB) + adaptation log.
  The 4-table split is for query performance, not architecture.
  Start with 1 table if needed.

## 21. Deferred / Future

| Item | Why deferred | When |
|---|---|---|
| Multi-path composition (2 goals simultaneously) | V1 = 1 active goal at a time | V1.1 |
| Ascent learns from outcomes (reinforcement) | Too complex for V1; deterministic adaptation is sufficient | V1.1+ |
| Peer comparison ("you're ahead of 80% of students") | Privacy + data requirements | V2 |
| Ascent on desktop (Phase 2) | Platform-specific, not V1 | Phase 2 |
| Ascent + FSRS co-optimization (Ascent decides WHEN to review, not just WHAT) | FSRS already owns timing; Ascent owns content order | V1.1 |

## 22. What Ascent Does NOT Do (Anti-Complexity Guard)

| Temptation | Why rejected | 80/20 answer |
|---|---|---|
| A second LLM "pedagogical model" | Ascent is DETERMINISTIC (rules + data). The LLM explains, Ascent sequences | No new model. Use the Agent's LLM for explanations, Ascent for ordering |
| 13+ specialized agents | AD-12: ONE kernel. Ascent is a CAPABILITY of the kernel, not a separate agent | 1 capability, not 13 agents |
| Complex scoring algorithm | 5 states + dimensions is enough. No ML model needed | Deterministic rules, not ML |
| WebGL / 3D visualization | Not needed for pedagogical content. AntV + KaTeX + images cover it | AntV + KaTeX |
| Distributed pipeline | Ascent is a single server function. No Kafka, no queue | 1 function, 4 tables |
| Ascent replaces Learning | Learning generates QCMs/flashcards. Ascent decides WHEN and WHAT order | Ascent = conductor, Learning = orchestra |
| Ascent replaces Progress | Progress measures. Ascent decides what to do with the measurement | Ascent reads Progress, never writes it |
| Graphiti / Zep / vector memory | AD-11: provenance via SourceRef + Postgres pgvector. No external memory graph | Postgres + R2 |
| Drift Guardian 24/7 | Not needed. Ascent adapts on evidence events (AD-9), not on a continuous watch | Event-driven, not continuous |
