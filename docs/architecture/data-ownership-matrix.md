# Data Ownership Matrix (master mission S52)

Rule (AD-2, AD-6, AD-7): a module may **write** only its own tables.
Cross-module data access goes through public contracts (01 S2.2: RLS
enforces module boundaries; 03 S5.4: no cross-module joins). The
entity->module->table mapping is frozen in 03 S4.2; this matrix is the
documentation of that mapping + the read access each module has to
other modules' data.

## Convention

- **Own** = the module is the sole writer (AD-7 single-writer).
- **Read** = the module reads another module's data via a public
  contract / view / event (not a direct table join).
- **Write external** = the module emits a command or event that causes
  another module to write (never a direct foreign-table write).
- **Allowed contract** = the typed interface through which cross-module
  access occurs (port, event, public view, or command).

## Module -> Own Tables

| Module | Own Tables (03 S4.2 + 01 S4.x) | SSoT |
|---|---|---|
| Productivity | `tasks`, `subtasks`, `events`, `projects`, `milestones`, `goals`, `habits`, `routines`, `notes`, `resources`, `decisions`, `focus_sessions`, `productivity_snapshots` | 01 S4.1 |
| Learning | `courses`, `subjects`, `learning_items` (QCM / flashcards / exercises), `learning_sessions`, `fsrs_state` (server, 03 S4.2), `skill_definitions` | 01 S4.2 |
| Knowledge | `sources`, `concepts`, `formulas`, `definitions`, `methods`, `semantic_nodes`, `semantic_relations`, `semantic_tree_version`, `node_states` | 01 S4.3 |
| Progress | `progress_evidences`, `progress_snapshots`, `skill_states`, `progress_events` (server-only), `progress_trajectories`, `gaps` (rows; definitions in domain) | 01 S4.4 |
| Discovery | `discovery_items`, `discovery_sources`, `discovery_scenarios` | 01 S4.5 |
| Artifact | `artifacts`, `artifact_files` (R2 key refs) | 01 S4.6 |
| Agent | `expert_skills` (server-only, 03 S4.2), `agent_runs`, `job_queue` + `job_logs` (shared with Foundation) | 01 S4.7 |
| Integrations | `integrations_state`, `automations`, `notification_preferences` | 01 S4.7 |
| Identity | `user_context`, `users` (Supabase Auth), `session_tokens` | 01 S2.1 |
| Foundation | `events` (AD-9 Event History), `model_registry`, `environment_config` | 01 S5.x |

## Cross-Module Read Access (allowed, via contract)

| Reading Module | Reads From | Data | Allowed Contract |
|---|---|---|---|
| Learning | Knowledge | `sources`, `concepts` (course content) | `KnowledgeBase` port (retrieval, 01 S3.2) |
| Learning | Progress | `skill_states` (mirror) | Progress public view + `SkillStateChanged` event (AD-9) |
| Progress | Learning | `learning_items` results (QCM scores, flashcard reviews) | `FlashcardReviewed`, `TaskCompleted` events (AD-9) |
| Progress | Productivity | `focus_sessions` (bilans), `tasks` (completion) | `TaskCompleted` event + `focus_sessions` public view |
| Knowledge | Artifact | `artifacts` (R2 keys for source documents) | `ArtifactGenerated` event + public view |
| Discovery | Progress | `skill_states` (gap targets) | Progress public view + `SkillStateChanged` event |
| Discovery | Knowledge | `sources` (existing knowledge for gap analysis) | `KnowledgeBase` port |
| Agent | all modules | context forms (9, ADR S16) | module public contracts (AD-2) + events (AD-9); **never direct table joins** |
| Artifact | Learning | `learning_items` (sheet content for export) | Learning public view |
| Integrations | all modules | notification preferences, automation triggers | `user_context` (Identity) + module events |

## Cross-Module Write Access (via command / event, NEVER direct)

| Writing Module | Writes To | Mechanism |
|---|---|---|
| Productivity | Progress (evidence) | `TaskCompleted` event -> Progress sole-producer creates `ProgressEvidence` (F-07) |
| Learning | Progress (evidence) | `FlashcardReviewed` event -> Progress sole-producer |
| Learning | Knowledge (ingestion) | `CourseImported` event -> Knowledge ingestion job |
| Artifact | Knowledge (source ref) | `ArtifactGenerated` event -> Knowledge `SourceRef` creation |
| Discovery | Learning (items) | `DiscoveryItemCreated` event -> Learning item creation |
| Agent | all modules | domain commands via owning module's use-case (AD-7: kernel never writes a table directly) |
| Identity | all modules | RLS root: `user_context` drives every module's row-level policy |

## Invariants (enforced by CI, ADR S21.5)

1. No module imports another module's internal table types (AD-2).
2. No module writes a table it does not own (AD-7 single-writer).
3. No cross-module SQL join in any module's repository (03 S5.4 static test).
4. Events are the only cross-module notification mechanism (AD-9; the
   9-event vocabulary is closed -- a new event = additive ADR).
5. `expert_skills` is server-only; no local mirror (AD-3, 03 S4.2).
6. `progress_events` is server-only (03 S4.2 mirror rule: mirrors =
   `skill_states`, `progress_snapshots`; events = no mirror).
