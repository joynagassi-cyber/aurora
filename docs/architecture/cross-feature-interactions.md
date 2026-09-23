# Cross-Feature Interactions (explicit, normed by AD-2/AD-7/AD-9)

Every interaction below is wired through **exactly one** of the three allowed
channels (events AD-9 · public views/contract reads AD-2 · commands to the owning
module AD-7). "Doc" = prescriptive source. Status = design phase (no code yet).

## 1. The required chains (master mission §9)

| # | Chain | Wiring (normative channel) | Doc |
|---|---|---|---|
| 1 | Learning objective → Goal → Project → Task → Calendar | `GoalUpdated` (Productivity) + command chain within Productivity (`GoalUpdateCommand`, project/task commands, 01 §4.1 relations goal→project→task); Learning *requests* objectives via Agent plans (kernel `Action` = commands to the owner, F-03) | 01 §4.1, 03 §4.2, agent/kernel |
| 2 | Course → Knowledge → Study material → QCM → Flashcards | `CourseImported` (Learning) → Knowledge tree ingestion (declared consumer, AD-9) → sheet/QCM/flashcard generation jobs (01 §5.1, 01 §4.2 FSRS state) | 01 §3.3, §4.2, §5.1 |
| 3 | Learning exercise → Evidence → SkillState → Progress | Learning/Practice produce `FlashcardReviewed` / exercise results; **Progress is the sole producer of `ProgressEvidenceCreated`** (F-07) → recompute `skill_states` (job, 01 §5.2) → `SkillStateChanged` | 01 §4.4, 03 §4.2 |
| 4 | Discovery → Gap → Skill → Learning path | `DiscoveryItemCreated` → Learning (activity creation) + Knowledge (tree links) + Progress (measurement); `Gap` definitions in domain, **rows owned by Progress** (03 §4.2) → Learning path = commands to Learning | 01 §3.3, 03 §4.2 |
| 5 | Discovery → Priority → Project → Tasks → Calendar | `SkillStateChanged` (competence profile, Discovery consumer) + Agent re-plan (kernel consumes gaps) → Productivity commands (project/task/calendar) | 01 §3.3, agent/kernel |
| 6 | Progress → detected delay → replanning | Progress dashboards/stagnation analysis (01 §4.4) → Agent (AUR §13 Coach replan, "recalcul du planning restant sans détruire l'historique", ADR §13) → Productivity commands | ADR §13, 01 §4.4 |
| 7 | Progress → weak concept → Coach → targeted practice | `SkillStateChanged` → Learning (targeted revision, AD-9 declared consumer) + Agent Coach capability | 01 §3.3 |
| 8 | Task → Focus Session → execution → actual time → task update | `FocusSession` (03 §4.2, Productivity owner) with `task_id`; session end = `TaskUpdateCommand` partials (planned/actual minutes, `actual_minutes` 01 §4.1) — one command, single-writer | 03 §4.2, 02 §4 |
| 9 | FocusSessionBilan → ProgressEvidence → discipline → actual vs planned | Bilan (SSoT 01 §4.1 shape) → evidence qualification by Progress jobs (F-07) → `ProgressEvidenceCreated` → Knowledge `NodeState` + Agent context (AD-9) | 01 §4.1/§4.4, 03 §4.2 |
| 10 | Knowledge Source → concept extraction → SemanticNode → relation | `CourseImported`/search results → Knowledge ingestion jobs (01 §4.3, AD-11 provenance: every significant concept points to `source_refs`) → `semantic_nodes/edges` (Knowledge-only writer, AD-6) | 01 §4.3, 03 §4.2 |
| 11 | Artifact ↔ Learning (course → generated revision sheet → Artifact Hub) | sheet export = job kind (`artifact_gen`) → R2 upload → **`ArtifactGenerated` only after R2** (F-06) → Learning consumer (proof) + Knowledge (`SourceRef`) | 01 §3.3, §4.6, §5.4 |

## 2. All other equivalent interactions (exhaustive list)

| Interaction | Channel | Rule / doc |
|---|---|---|
| Productivity ↔ Agent | `TaskCompleted` / `GoalUpdated` → Agent re-plan; Agent `Action` = commands to Productivity (never direct writes) | 01 §3.3, F-03 |
| Agent ↔ everything (context) | Context Builder reads module **public contracts** (projections of AD-15 types — never re-declarations) | AD-12/F-09, AD-15, 01 §5.6 |
| Agent Verify ↔ Scientific Engine | critical tasks → deterministic engine + KB/source check as **server job** | 01 §5.6, ADR v1.7 §14 |
| Agent Memory ↔ Expert Skills | `expert_skills` server-only (no local mirror, AD-3); error/success loops + guardrails | 01 §4.7, 03 §4.2, ADR §14 |
| Discovery ↔ Scientific/Knowledge | scenario checks & formula verification via engine jobs | 01 §4.5, scientific-engine page |
| Artifact ↔ Knowledge | `ArtifactGenerated` → `SourceRef` (Knowledge owns refs) | 01 §3.3/§4.3 |
| Integrations ↔ Productivity | automations (owner Integrations, 03 §4.2) trigger via Cron → dispatcher (AD-8), never via UI; notifications split rule (server-state = OneSignal, local-deadline = Capacitor, never both for one object) | 04 §3.4, 01 §5.2 |
| Identity ↔ all | RLS root (`user_id` on every table, 01 §2.2); `user_context` = preferences incl. theme v2 enum + silence windows (coaching cadence, ADR §13) | 01 §2.1, 03 §4.2 |
| DS/theme ↔ all screens | theme = store/UI token layer only (never business logic); local adaptation V1 = Focus Mode only (OQ-15) | 05 §5/§6, 02 §3.3 |
| Focus ↔ Internet (invariant) | Focus mechanisms never touch the network; sync/AI/KB stay active during a session | focus spec §3 |
| Jobs ↔ UI | `JobCompleted{jobId,jobKind}` → UI success/retry state (mobile filters by `jobKind`, 04 §3.3); heavy features expose `loading/empty/success/error/offline` | 01 §6, 04 §3.3 |

## 3. What is forbidden (review red-lines)

- Cross-module table writes (AD-2) — the *only* write to a module's data is the
  owner's own (direct or via its commands).
- Undeclared event consumers (AD-9/F-04, 01 §7 test b).
- `ProgressEvidence` rows created outside Progress (F-07).
- Kernel/UI direct table mutation (F-03).
- `ArtifactGenerated` emitted before R2 upload confirmation (F-06).
- `JobCompleted` without `jobId`+`jobKind` (F-08).
- Any 10th event (AD-9 frozen vocabulary).
