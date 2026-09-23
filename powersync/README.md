# Aurora — PowerSync Wave 0 (MINERVA)

Local-first sync layer (AD-7 / 03-sync). Wave 0 delivers the **prerequisites**
for the relay: the mirror mapping, the relay-scoped views, and the config.
Per 03 §8.1, the **relay is operational in wave 1** — this commit ships the
schema/views/config it needs, plus a documented round-trip test.

## Layout

```
powersync/
  schema.json      PowerSync schema (scopes / sync tables) — JSON consumed by
                   the PowerSync engine (03 S4.2 mirror mapping, data-event-job
                   catalog S2, contract-catalog S6)
  relay.sql        Server-side: the relay reads module public views via
                   service_role UNDER RLS (01 S3.4, 03 S5.5) — one scope =
                   one module owner, never a cross-module internal JOIN
  test/roundtrip.md  1-row insert -> PowerSync -> SQLite (03 S7) — written,
                   runnable once the relay is up (wave 1); documented here
```

## Mirror mapping (EXACT, 03 S4.2 / data-event-job-catalog S2)

Synced (mirrored to the local SQLite store):

- **Productivity**: `tasks`, `milestones`, `projects`, `goals`, `habits`,
  `routines`, `focus_sessions`, `decisions`, `calendar_events`
- **Knowledge**: `notes`, `resources`, `semantic_nodes`/`semantic_edges`/
  `semantic_bridges`, `node_state`, `source_refs` (NO `embedding` column —
  03 S4.2; retrieval is server-only, AD-12/F-09)
- **Learning**: `courses`, `subjects`, `skills`, `learning_sessions`,
  `reviews`
- **Progress** (LIMITED mirror, 03 S4.2): `skill_states` +
  `progress_snapshots` **ONLY**
- **Discovery**: `discovery_items`, `gaps`
- **Artifact**: `artifacts` (metadata + r2_key only — files never in SQLite,
  AD-16)
- **Integrations**: `automations`
- **Identity**: `user_context`

Excluded from mirror (server-only):

- `expert_skills` (AD-3, 01 S4.7 — agent memory never synced to device)
- `events` (Event History, 01 S4.8 — audit-only, F-10)
- `progress_evidences` (consumed server-side, 03 S4.2; `evidence_refs[]`
  stay in owner entities' CRDT lists)
- `progress_events` (server-only, F-10)
- `progress_trends` (recomputed server-side, 01 S4.4)
- `model_registry` / `ai_usage` / `ai_health` (Foundation registries, server)

## CRDT OR-Set lists (03 S5.3 / S5.4)

Columns that must **merge** (tags, `dependencies[]`, `evidence_refs[]`,
`source_ref_ids[]`, focus-policy sets) are carried as `local_mutation_id`
(ULID) + `added`/`removed` jsonb columns, frozen OR-Set. `-- TODO(wave1):
align sur CRDT SSoT packages/domain` (encoding shape is the single SSoT in
`packages/domain`, AD-15/F-01).

## Conflict rule (frozen, AD-7)

server-wins + per-entity `updated_at` (server canonical, 03 S4.2 rule 3);
CRDT OR-Set for merge lists (03 S5.3). No new event vocabulary is introduced
(AD-9, F-04).

## Config (relay)

- The PowerSync **relay** connects to Supabase PostgreSQL and reads the module
  public views with `service_role` THROUGH the RLS policies (01 S3.4, 03 S5.5)
  — never `BYPASSRLS`, never a second backend (ADR S2 v1.6).
- `PS_ADMIN_TOKEN` is read from env (`.env.local`), never hardcoded (AD-3).
- One scope = one module owner; a scope **never** joins another module's
  internal tables (AD-7/F-03) — cross-module reads use the source module's
  public view.

## Wave 0 vs Wave 1 (relay operational)

| | Wave 0 (this commit) | Wave 1 |
|---|---|---|
| Mirror mapping | ✅ schema.json | — |
| Relay-scoped views + RLS | ✅ relay.sql | — |
| Relay reads views via service_role under RLS | schema+config ready | **relay operational** |
| 1-row insert → PowerSync → SQLite round-trip | ✅ test written (03 S7) | executed once relay up |

> **relay operationnel = wave 1** (03 S8.1). The round-trip test is written and
> runnable now; it is **skipped with reason** while the relay is not
> provisioned, and executed in wave 1.
