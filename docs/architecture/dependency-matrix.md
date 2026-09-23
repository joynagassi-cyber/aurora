# Dependency Matrix — 4-Module Strategic Core (ADR S21.9)

**Status:** `DESIGNED_NOT_IMPLEMENTED`. Authority: AD-2 (module
boundaries), AD-6 (data layer split), AD-7 (single-writer), AD-9
(targeted events, 9-event vocabulary), 01 S2.2 (RLS ruling),
03 S5.4 (no cross-module joins), data-ownership-matrix.md.

## 1. The Cardinal Rule

**No core module imports another module's code, types, or
database tables directly.** Period.

Interactions happen ONLY through:
1. **Ports** (contract-catalog S2): typed interfaces in
   `packages/domain` that both sides agree on
2. **Events** (AD-9, 9-event vocabulary): producer emits,
   consumer observes (no direct call)
3. **Public views** (01 S2.2, 03 S5.4): read-only, module-scoped
   Postgres views (no cross-module SQL joins)
4. **Agent Kernel** (AD-12, F-09): the kernel reads public
   contracts from ALL modules; it never writes a module table

```
RULE: A imports B only if B is a LOWER layer (domain, data, platform).
     NEVER: A imports B if B is a sibling module.
     Sibling communication = events + ports + public views. ONLY.
```

## 2. The 4-Module Hierarchy (asymmetric, NOT circular)

```
                    DISCOVERY (detects, enriches)
                    |
                    | DiscoveryItemCreated (event)
                    v
              +-----+-----+
              |         |
              v         v
         LEARNING   KNOWLEDGE
         (practice) (tree + retrieval)
              |         |
              | ProgressEvidenceCreated   |
              | SkillStateChanged         |
              v         |
         +---+---+      v
         |      |   PROGRESS (measures, sole producer of evidence)
         v      |
    PRODUCTIVITY<-------
    (plans, executes)
```

**Direction: top-down. Discovery feeds Learning + Knowledge.
Knowledge feeds Progress (via events). Progress feeds Productivity
(via evidence). Productivity feeds Discovery (via task completion
patterns).**

But this is NOT a direct dependency chain. Each arrow is an
EVENT or a PUBLIC VIEW, not an import.

## 3. Who Owns What (SSoT, AD-15, 03 S4.2)

| Module | Owns (writes) | Reads (public view / event) |
|---|---|---|
| **Productivity** | tasks, events, projects, goals, milestones, habits, routines, notes, resources, decisions, focus_sessions | Progress (skill_states, progress_snapshots — public view) |
| **Learning** | courses, subjects, learning_items, learning_sessions, fsrs_state, skill_definitions | Knowledge (sources, concepts — via KnowledgeBase port), Progress (skill_states — public view) |
| **Knowledge** | sources, concepts, formulas, definitions, methods, semantic_nodes, semantic_bridges, semantic_tree_version, node_states | Artifact (R2 keys — via ArtifactGenerated event) |
| **Progress** | progress_evidences, progress_snapshots, skill_states, progress_events (server-only), progress_trajectories, gaps | ALL modules (via AD-9 events: TaskCompleted, FlashcardReviewed, CourseImported, DiscoveryItemCreated, ArtifactGenerated, SkillStateChanged) |
| **Discovery** | discovery_items, discovery_sources, discovery_scenarios | Progress (skill_states — public view), Knowledge (sources — via KnowledgeBase port) |

**Key: Progress is the CONVERGENCE POINT.** All modules emit
evidence; Progress is the sole producer of `ProgressEvidenceCreated`
(F-07). No other module writes `progress_evidences`.

## 4. The 9 Events (AD-9) — the ONLY inter-module signal

| # | Event | Producer | Consumers | What it carries |
|---|---|---|---|---|
| 1 | `TaskCompleted` | Productivity | Progress, Learning, Agent | `{taskId, userId, completedAt, evidenceRefs?}` |
| 2 | `CourseImported` | Learning | Knowledge, Discovery, Progress | `{courseId, userId, source, importedAt}` |
| 3 | `FlashcardReviewed` | Learning (FSRS) | Progress | `{cardId, userId, rating, nextDueAt, fsrsState}` |
| 4 | `ProgressEvidenceCreated` | **Progress ONLY** (F-07) | Knowledge (NodeState), Agent | `{evidenceId, userId, skillId?, goalId?, type, level, confidence, sourceEventId}` |
| 5 | `SkillStateChanged` | **Progress** | Agent, Discovery, Learning | `{skillId, userId, newState, freshness, confidence}` |
| 6 | `GoalUpdated` | Productivity | Progress, Agent | `{goalId, userId, changedAt, fields[]}` |
| 7 | `ArtifactGenerated` | **Artifact, post-R2 only** (F-06) | Knowledge (SourceRef), Learning [+ UI — OQ-05] | `{artifactId, userId, kind, r2Key, sizeBytes, generatedAt, jobId}` |
| 8 | `JobCompleted` | Job system | Artifact, UI | `{jobId, jobKind, userId, status, result?}` |
| 9 | `DiscoveryItemCreated` | Discovery | Learning, Knowledge, Progress, Agent | `{discoveryItemId, userId, topic, sources, createdAt}` |

**Closed vocabulary.** A 10th event = additive ADR (spine Consistency
Conventions). The 9 are normative (01 S3.3 matrix).

## 5. Port Contracts (the ONLY typed interface between siblings)

| Port (packages/domain) | Defined by | Consumed by | What it exposes |
|---|---|---|---|
| `KnowledgeBase` | Knowledge | Learning, Agent, Discovery | `search(query)`, `getConcept(id)`, `retrievalFTS+vector` |
| `ProgressEvidence` (public view) | Progress | Productivity, Learning, Discovery | `getSkillState(skillId)`, `getSnapshot(userId, period)` |
| `ObjectiveManager` (public view) | Productivity | Progress, Agent | `getGoal(id)`, `getProject(id)`, `getTasks(filter)` |
| `ArtifactStore` | Artifact | Knowledge, Learning | `getArtifact(id)`, `presignGet(key, ttl)` |
| `DiscoveryService` (public view) | Discovery | Learning, Agent | `getGap(id)`, `getDiscoveryItems(filter)` |
| `ScientificEngine` | Scientific | Learning, Agent | `evaluate(expr)`, `verify(result)`, `convert(qty)` |
| `JobRunner` | Foundation | ALL (for dispatch) | `dispatch(jobKind, payload)`, `claim(jobId)` |
| `NotificationProvider` | Integrations | Agent, Productivity | `send(notification)`, `scheduleLocal(deadline)` |

**No port exposes a module's internal table schema.** A port is a
BLACK BOX: the consumer knows the input/output types, not the
implementation. Knowledge can swap Postgres for another engine
without changing the `KnowledgeBase` port.

## 6. The "No Big Ball of Mud" Test

For ANY proposed cross-module interaction, ask:

| Question | If YES -> OK | If NO -> REJECT |
|---|---|---|
| Does it go through a Port (typed contract in packages/domain)? | OK | Direct table access = REJECT |
| Is it an AD-9 event (one of the 9)? | OK | New event without additive ADR = REJECT |
| Is it a public view (read-only, module-scoped)? | OK | Cross-module SQL JOIN = REJECT (03 S5.4) |
| Does the Agent Kernel emit a domain command (not write a table)? | OK | Kernel writes a module table = REJECT (AD-7) |
| Is the dependency direction consistent with the hierarchy? | OK | Circular import = REJECT |

**The CI enforces this (wave 0, AD-16c):**
- `import/no-restricted-paths`: module A cannot import module B's
  internal types (only `packages/domain` types)
- `no-restricted-imports`: 5 AD-10 engines only in `packages/ui`
- Grep: vendor names in domain/ui/apps = build failure (AD-1)
- RLS penetration test: user A cannot read user B's rows;
  module A's Edge Function cannot write module B's table
- Static view-join test (03 S5.4): no SQL JOIN across module
  schemas in any repository

## 7. The Agent Kernel's Role in the Dependency Graph

The kernel (AD-12, F-09) is the ONE component that sees ALL
modules. But it sees them through PORTS and EVENTS, not through
internal table access.

```
Agent Kernel (server)
  |
  | reads:
  |   KnowledgeBase port -> Knowledge (retrieval)
  |   ProgressEvidence view -> Progress (skill states)
  |   ObjectiveManager view -> Productivity (goals, tasks)
  |   DiscoveryService view -> Discovery (gaps, items)
  |   ScientificEngine port -> Scientific (verify)
  |   events: ALL 9 (Context Builder, 01 S5.6)
  |
  | writes:
  |   domain commands via owning module's use-case (AD-7)
  |   NEVER direct table writes (single-writer)
  |   NEVER emits ArtifactGenerated (Artifact does, F-06)
  |   NEVER writes NodeState (Knowledge does, AD-6)
  |   NEVER writes progress_evidences (Progress does, F-07)
```

The kernel is a CONSUMER of all ports + a PRODUCER of domain
commands. It orchestrates; it does not own data.

## 8. What a New Module Must Do (product evolution, S70)

When a new module M is added:
1. M defines its Port (in packages/domain, AD-15 SSoT)
2. M defines its events (if any, additive ADR to the 9)
3. M declares its public views (read-only, RLS-scoped)
4. M registers its FeatureModule (feature-registry.md S8)
5. M registers its Agent capabilities (feature-agentability-matrix.md)
6. M does NOT import any existing module's internal code
7. Existing modules do NOT need to change to accommodate M
   (they interact via M's Port + events)

**The monolith stays modular because the boundary is enforced by
CI, not by convention.**

## 9. The 4-Module Interaction Map (concrete examples)

### Example 1: Learning -> Knowledge
```
Learning imports a course (camera -> OCR -> R2)
  -> Learning emits: CourseImported {courseId, source}
  -> Knowledge observes: CourseImported
  -> Knowledge ingests: extracts concepts, formulas, tree nodes
  -> Knowledge updates: semantic_tree_version++
  -> Knowledge emits: nothing (tree update is internal)
  -> Progress (later): QCM on this course -> FlashcardReviewed
  -> Progress emits: ProgressEvidenceCreated
  -> Knowledge observes: ProgressEvidenceCreated
  -> Knowledge updates: NodeState (status: mastered/fragile)
```
**Learning NEVER writes to Knowledge's tables.** The event +
ingestion job is the bridge.

### Example 2: Discovery -> Learning
```
Discovery runs research (job, AD-8)
  -> Discovery finds: "gap in FEM validation"
  -> Discovery emits: DiscoveryItemCreated {topic: 'FEM', sources}
  -> Learning observes: DiscoveryItemCreated
  -> Learning creates: learning_items (QCM, flashcards on FEM)
  -> Learning emits: nothing (items are internal)
  -> Progress (later): FEM QCM passed
  -> Progress emits: ProgressEvidenceCreated {skillId: 'FEM', type: 'understanding'}
  -> Progress updates: SkillState FEM = 'mastered'
  -> Progress emits: SkillStateChanged
  -> Discovery observes: SkillStateChanged
  -> Discovery: "FEM gap closed, move to next gap"
```

### Example 3: Productivity -> Progress -> Agent
```
Productivity: task completed
  -> Productivity emits: TaskCompleted {taskId}
  -> Progress observes: TaskCompleted
  -> Progress creates: ProgressEvidence (discipline)
  -> Progress emits: ProgressEvidenceCreated
  -> Agent observes: ProgressEvidenceCreated
  -> Agent: "Task X done. Next priority: Y."
  -> Agent (via commands): Productivity task.update (reorder)
  -> Agent (via commands): Productivity calendar.schedule (plan Y)
```

**In all 3 examples: no module writes another module's tables.
Events + ports + commands. That's it.**

## 10. Anti-Patterns (CI rejects these)

| Anti-pattern | Why it's wrong | CI test |
|---|---|---|
| Learning imports `semantic_nodes` table directly | Violates AD-2 (module boundary) | RLS penetration + import/no-restricted-paths |
| Progress writes `learning_items` | Violates F-07 (sole producer) | Static analysis: only Progress Edge Function writes progress_evidences |
| Agent kernel calls `KnowledgeBase.search()` in a loop (N+1) | Performance, but also couples kernel to Knowledge internals | 02 S11 perf test (batched retrieval) |
| Productivity emits a 10th event `TaskDeferred` | Violates AD-9 (9-event closed vocabulary) | Event vocabulary lint (only 9 allowed) |
| Discovery SQL JOINs `progress_snapshots` | Violates 03 S5.4 (no cross-module joins) | Static view-join test |
| Two modules both write `expert_skills` | Violates AD-7 (single-writer) | RLS + ownership check (Agent only) |

## 11. Decoupling by Orchestration (the Agent as the bridge)

**The problem:** Horeb fails a BA (reinforced concrete) exercise
in the Learning module. Tomorrow at 14h, a study session should be
scheduled in the Productivity module (calendar + focus block).

**The naive (WRONG) approach:**
```
Learning module code:
  onExerciseFailure() {
    productivity.scheduleStudyBlock(14:00);  // DIRECT CALL
  }
```
This couples Learning to Productivity. If Productivity changes its
API, Learning breaks. If we add a third module, Learning breaks
again. This is the "big ball of mud" anti-pattern.

**The correct approach (3 layers of decoupling):**

```
Layer 1: EVENTS (modules talk to the world, not to each other)
  Learning: exercise failed
    -> Learning emits: ProgressEvidenceCreated
       { type: 'understanding', skillId: 'BA.flexion',
         level: 'fragile', sourceEventId: 'ex_123' }
    (Learning does NOT know or care who consumes this event)

  Progress: observes ProgressEvidenceCreated
    -> Progress updates: SkillState BA.flexion = 'fragile'
    -> Progress emits: SkillStateChanged
       { skillId: 'BA.flexion', newState: 'fragile' }
    (Progress does NOT schedule anything. It measures.)

Layer 2: AGENT KERNEL (the orchestrator, server-side, AD-12)
  Agent: observes SkillStateChanged (Context Builder, 01 S5.6)
    -> Intent: "BA flexion is fragile, user has exam in 5 days"
    -> Context: Productivity (available time tomorrow),
                Learning (what to review),
                Progress (how fragile, which sub-concepts)
    -> Plan:
       Step 1: Productivity command -> calendar.schedule
               (tomorrow 14:00, 90 min, "BA flexion revision")
       Step 2: Productivity command -> focus.start
               (90 min, blocklist: social apps)
       Step 3: Learning command -> qcm.generate
               (20 items on BA flexion, from the failed exercise)
    -> Confirmation: "Demain 14h: 90 min de revision BA flexion
       + 20 QCM. Tu confirmes?"
    -> User confirms
    -> Agent executes the commands (via each module's use-case)

Layer 3: MODULES (each applies its own commands, single-writer)
  Productivity: receives calendar.schedule command
    -> Writes events table (its own table, AD-7 single-writer)
    -> Upsyncs to Supabase
    -> Local mirror updates (PowerSync)
  Learning: receives qcm.generate command
    -> Creates learning_items (its own table, AD-7)
    -> Dispatches artifact_gen job (AD-8)
```

**The key: NO module calls another module.** The Agent reads
events from all modules and emits commands TO all modules. The
modules are decoupled from each other; they are only coupled to
the Agent (through events in, commands out).

## 12. The 4-Module Technical Contract Matrix

| Module | Consumes (Ports / Events / Views) | Produces (Ports / Events / Commands) | Package boundary (AD-2) |
|---|---|---|---|
| **Productivity** | `UserContext` (Identity), `ProgressEvidenceCreated` (event), `SkillStateChanged` (event), `FocusController` port, `NotificationProvider` port | `TaskCompleted` (event), `GoalUpdated` (event), `TaskRepository` / `CalendarProvider` / `FocusController` (ports), domain commands (task.update, calendar.schedule) | `packages/productivity/*` — CANNOT import Learning, Discovery, Progress, Knowledge internal code |
| **Learning** | `UserContext`, `TaskCompleted` (event), `KnowledgeBase` port (retrieval), `SkillStateChanged` (event), `ArtifactGenerated` (event), `ScientificEngine` port | `CourseImported` (event), `FlashcardReviewed` (event), `FSRSController` / `CourseManager` (ports), domain commands (learning_items) | `packages/learning/*` — CANNOT import Productivity, Discovery, Progress internal code |
| **Discovery** | `UserContext`, `SkillStateChanged` (event), `ProgressEvidenceCreated` (event), `KnowledgeBase` port (read-only), `ResearchProvider` port, `ProgressSnapshot` (public view) | `DiscoveryItemCreated` (event), `GapDetector` / `SourceRegistry` (ports), domain commands (discovery_items) | `packages/discovery/*` — CANNOT import Learning, Productivity, Progress internal code |
| **Progress** | `TaskCompleted` (event), `FlashcardReviewed` (event), `CourseImported` (event), `ArtifactGenerated` (event), `DiscoveryItemCreated` (event), `GoalUpdated` (event) | `ProgressEvidenceCreated` (event, SOLE producer F-07), `SkillStateChanged` (event, SOLE producer), `ProgressSnapshot` / `MetricCalculator` (public views) | `packages/progress/*` — CANNOT import any module's internal code; OBSERVES all, WRITES only its own tables |

**Progress is the hub (convergence point).** It observes ALL other
modules' events. But it NEVER initiates a call to another module.
It only emits its own events (ProgressEvidenceCreated,
SkillStateChanged). Other modules observe THOSE events and react.

## 13. The Asymmetry Rules (who can see what)

```
READ direction (public views + events, ALWAYS allowed):
  Progress reads ALL (it's the observer, AD-9 consumer matrix)
  Learning reads Knowledge (via KnowledgeBase port, retrieval)
  Discovery reads Progress (skill_states, public view)
  Agent reads ALL (Context Builder, 01 S5.6, via ports + events)

WRITE direction (single-writer, AD-7, NEVER cross-module):
  Productivity writes ONLY productivity tables
  Learning writes ONLY learning tables
  Knowledge writes ONLY knowledge tables
  Progress writes ONLY progress tables (+ sole-producer evidence)
  Discovery writes ONLY discovery tables
  Agent writes NOTHING directly (commands only, AD-7)

The asymmetry is absolute:
  Learning can READ Knowledge (port).
  Knowledge CANNOT read Learning (no port, no event from Learning
  to Knowledge — CourseImported is consumed by Knowledge, which
  is an event flow, not a read).
```

## 14. What the Agent's Command Bus Looks Like (concrete)

When the Agent decides "schedule BA revision tomorrow 14h":

```
Agent (server, fn-agent-run)
  |
  | emits domain command (NOT a direct function call):
  | {
  |   type: 'calendar.schedule',       // Productivity command
  |   payload: {
  |     userId, date: '2026-09-25',
  |     timeBlock: { start: '14:00', end: '15:30' },
  |     label: 'BA flexion revision',
  |     courseId: 'ba_course_1',
  |     skillRef: 'BA.flexion'
  |   },
  |   source: 'agent',                 // provenance: who triggered this
  |   traceId: 'agent_run_abc123'
  | }
  |
  v
Productivity use-case (server, packages/productivity)
  |
  | validates: is the time slot free? conflicts?
  | writes: events table (Productivity's own table, AD-7)
  | upsyncs: Supabase -> PowerSync -> local mirror
  | emits: nothing (scheduling is not an AD-9 event)
  |
  v
Done. Learning was NEVER called by the Agent for scheduling.
The Agent called Productivity's use-case with a command.
Productivity applied it. Learning's QCM generation is a SEPARATE
command (qcm.generate) that the Agent also emits in the same plan.
```

**The plan is atomic (all-or-nothing confirmation) but the
execution is per-command (each module handles its own command).**
If one command fails, the others still execute (graceful
degradation, AD-1 last paragraph). The user is informed of the
failed step.

## 15. Testing the Decoupling (CI + integration)

- **Import boundary test** (wave 0, AD-16c):
  `packages/learning` MUST NOT import from `packages/productivity`
  or `packages/progress` or `packages/discovery`. CI fails on violation.

- **Event contract test** (01 S7 a-e):
  `ProgressEvidenceCreated` payload schema matches the 9-event
  vocabulary. No extra fields. No missing fields.

- **Single-writer test** (01 S7, AD-7):
  Only Progress Edge Function can INSERT into `progress_evidences`.
  A test that tries to write `progress_evidences` from a Learning
  Edge Function MUST FAIL (RLS + ownership check).

- **No cross-module JOIN test** (03 S5.4):
  Static analysis: no SQL query in any repository JOINs tables from
  two different module schemas.

- **Agent never writes test** (AD-7, 01 S7):
  The kernel's execution path MUST NOT contain a direct
  `INSERT`/`UPDATE`/`DELETE` on any module table. Only
  domain commands (use-case calls) and event observations.

- **Orchestration integration test** (wave 4, E2E):
  "Exercise failed in Learning -> SkillStateChanged -> Agent
  replans Productivity" runs as a full E2E flow (23 composite
  workflows, W1-W23). No module directly calls another.
