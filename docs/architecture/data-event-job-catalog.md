# Data / Event / Job Catalog (Deliverable G)

## 1. Server tables (conceptual — no DDL in V1 docs, spine § Deferred; schemas per module, 01 §4)

| Area | Tables (conceptual) | Owner module (AD-2 RLS) | Notes |
|---|---|---|---|
| Productivity (01 §4.1) | `tasks`, `subtasks`, `projects`, `goals`, `milestones`, `habits`, `routines`, `focus_sessions`, `decisions`, `events` (calendar) | Productivity | recurrence materialized (not rules) for PowerSync; calendar `events` ≠ server `events` Event History (03 §4.2) |
| Learning (01 §4.2) | `courses`, `subjects`, `skills`, `learning_sessions`, `reviews`, `flashcards` (+ FSRS state: due/stability/difficulty) | Learning | FSRS algorithm **runs server-side** (job), device mirrors state |
| Knowledge (01 §4.3, AD-6) | `knowledge_documents`, `source_refs`, semantic tree: `semantic_nodes`, `semantic_edges`, `semantic_bridges`, `node_state`, `semantic_tree_version` (+ pgvector embeddings) | **Knowledge only** (sole writer of `NodeState`) | local mirror has NO embedding column (03 §4.2); versioning = Knowledge table, not Event History (AD-6) |
| Progress (01 §4.4, ADR §18.8) | `progress_snapshots`, `progress_evidences`, `skill_states`, `progress_trends`, `progress_events`, `trajectory_scenarios`, `gaps` | Progress | Progress **emits** events, never writes Knowledge tables (AD-2/F-02); `gaps` rows owned by Progress, definitions in `packages/domain` |
| Discovery (01 §4.5) | `discovery_items`, discovery profile/feeds | Discovery | `Gap` definitions ≠ rows (above) |
| Artifact / R2 metadata (01 §4.6) | `artifacts` (metadata + `r2_key`), file records | Artifact | binaries in R2 buckets only; `ArtifactGenerated` after upload (F-06) |
| Agent / Integrations (01 §4.7) | `expert_skills` (**server-only**, no local mirror, AD-3), integrations state, `user_context` (Identity) | Agent / Integrations / Identity | agent memory never synced to device |
| Event History (01 §4.8) | `events` (per producer module) + `progress_events` | producers | analysis/audit only; NOT Event Sourcing (V1 exclusion) |
| Jobs (01 §5.3) | `job_queue` (`jobId`, `kind`, `status pending/running/done/failed`, `attempts`, `due_at`, `user_id`, idempotency key = `kind + hash(logical payload) + user_id`, nullable `source_local_mutation_id` ULID per G-M4 fix, `updated_at`), `job_logs` | Foundation (AD-16) | per-kind timeout + exponential retry; `job_logs` feeds Sentry |
| Model Registry (01 §4.10, AD-16b) | `model_registry` (+ `ai_usage`, `ai_health` structures versioned for quota drift, R1) | `packages/data` + Foundation | auto-retirement of unavailable/paid providers (AD-5); free tiers = capacities, not SLAs |

## 2. Local store (SQLite/PowerSync, 03 §4)

- Local tables mirror AD-15 entities per the frozen 03 §4.2 mapping: `tasks`, `milestones`,
  `projects`, `goals`, `habits`, `routines`, `focus_sessions`, `decisions`, `events` (calendar),
  `notes`, `resources`, `courses`, `subjects`, `skills`, `learning_sessions`, `reviews`,
  `semantic_nodes/edges/bridges`, `node_state`, `source_refs`, `evidence_refs`,
  `progress_*` mirrors (limited: `skill_states`, `progress_snapshots` only), `discovery_items`,
  `artifacts` (metadata + `r2_key`), `automations`, `user_context`.
- **No local table** for: `expert_skills` (server-only), `events` Event History,
  `progress_events`, `progress_trends` (recomputed server-side), `progress_evidences`
  (consumed server-side; `evidence_refs[]` stay in owner entities' CRDT lists).
- Rules: one local table per module owner; no FK/join crosses modules (public views only);
  files never in SQLite (R2 + `r2_key`); canonical timestamps = server `updated_at`;
  list merges = frozen OR-Set CRDT (SSoT `packages/domain`).

## 3. PowerSync views / scopes (AD-7, owner `packages/data`, provisioned wave 0)

Declarative read-only `CREATE VIEW`; engine reads with `service_role` **through** RLS
policies; a scope = single module-owner view; **never** joins another module's internal
tables; server-wins conflict + per-entity timestamp; CRDT for lists that must merge (03 §5.4).

## 4. Events (V1 vocabulary — exactly 9, AD-9)

See [contract-catalog.md §6](./contract-catalog.md). Rules: one producer per event; consumers
declared in the consumer's Contract Pack (AD-13); Learning never creates `ProgressEvidence`
rows directly (F-07); kernel never emits `ArtifactGenerated` (F-06); `JobCompleted` without
`jobId`+`jobKind` is rejected (F-08). Simple transactional ops remain direct commands
(01 §3.3, ADR §26.6).

## 5. Jobs (AD-8, 01 §5)

- Flow: Supabase Cron (pure short trigger functions) → INSERT `job_queue` → Postgres trigger /
  Cron → **`fn-job-dispatcher`** (the only dispatcher; distribue only, never creates jobs) →
  worker (Edge Function or Cloudflare Worker) by `kind` → `reportResult` → `JobCompleted` event.
- Heavy capabilities that MUST be jobs: OCR, transcription, artifact generation, research,
  scientific compute, FSRS ticks, `skill_states` recompute (01 §5.2), kernel `Verify`
  (01 §5.6). Nothing heavy blocks the UI.
- Properties: persisted (Postgres), identifiable (`jobId`), idempotent (idempotency key),
  retryable (bounded exponential backoff, per-kind timeout), observable (`job_logs` + Sentry +
  per-kind SLO, duty owner Foundation AD-16d).
- Kinds vocabulary SSoT = `packages/domain` (AD-15) — e.g. `ocr`, `transcription`,
  `artifact_gen`, `fsrs-tick`, `skill_recompute`, `research`, `agent_run`, `verify`,
  `scientific`.

## 6. Files (R2, AD-16)

Private buckets per environment (names = wave-0 data, OQ-03); presigned URLs only
(`presignGet` TTL 15 min, `presignUpload` TTL 5 min, 01 §5.4); server-side presigning
(`fn-*` Edge Functions) — client never holds R2 keys (AD-3); uploads from device go straight
to R2 via presigned URL (`LocalFileStorageAdapter.upload`, 04 §3.2.2); unsupported formats:
stored + downloadable, no native-preview claim (ADR §16).
