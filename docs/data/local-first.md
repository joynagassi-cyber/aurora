# Local-First Data Layer (PowerSync + SQLite + Supabase)

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 1). Authority: spine AD-7, `03-sync` (whole
pack), `01-backend` §3.4/§5, `04-mobile` §6, ADR §26.2/§26.7.

## 1. The flow (mission §27)

```
UI → local state (SQLite/PowerSync via LocalQueryRepository) → mutation via
LocalCommandRepository (partial DomainCommand → owning module, single-writer AD-7/F-03)
→ upsync queue → Supabase (server of record, RLS) → PowerSync downstream (views)
```
The UI **reads only SQLite** — no network on the render path (AD-7, 02 §9);
network calls exist only inside the sync engine (PowerSync), never in feature code.

## 2. Read / write contracts (03 §3.1, owner `packages/data`)

- `LocalQueryRepository<T>`: `getById`, `list`, `watch` (reactive, local-only) —
  the store never exposes raw tables to the UI.
- `LocalCommandRepository`: `apply(ownerModule, cmd)` with `DomainCommand` **partials**
  (e.g. `TaskUpdateCommand {op:'task.update', id, patch}`); full-entity PUT =
  single-writer violation. Commands frozen per entity in `packages/domain` (AD-15).
- Kernel never writes tables: it emits commands/events; the owning module applies
  (AD-7/F-03/F-09).

## 3. Offline (first-class state, not failure — AD-7)

- Offline = local reads fully functional; mutations queue for upsync; cloud-only
  actions disabled with honest UI (02 §7 `offline` state; 03 §5.9 surface rules).
- `NetworkStatusAdapter` (04 §3.2.6) drives the state; background sync throttling:
  `minSyncIntervalMs` (foreground ~30 s; background ≥ 5 min, no polling) — 04 §6.2
  imposes the constraint, 03 §5.7 defines the parameter (owner `packages/data`);
  `FOREGROUND_SERVICE` (OQ-04) only if continuous background sync is chosen.

## 4. Conflict resolution (03 §5.3, canonical rule)

- Default: **server-wins + per-entity server `updated_at`** (canonical timestamp =
  server; the client never dates its own mutations so the server overwrites an older
  `updated_at` — 03 §4.2 rule 3). Scalar conflicts resolve **silently**.
- Lists that must merge: **frozen OR-Set CRDT** (SSoT `packages/domain`; not
  LWW-Map, 03 §5.3). A `conflict` sync state is reachable **only** on an un-mergeable
  CRDT type-collision (03 §3.2: user alert + lossless merge, the residual case —
  test 03 §7).

## 5. Scopes / views (AD-7, 03 §5.4)

- All PowerSync views owned by `packages/data`, provisioned wave 0; declarative
  read-only; engine reads with `service_role` **through RLS policies** (never
  BYPASSRLS, 01 §2.2/§3.4).
- A scope = single module-owner view; **never** joins another module's internal
  tables; cross-module reads go through the source module's **public view**
  (AD-2/AD-7/F-03).

## 6. Re-sync after long outage (03 §5.5)

Return-to-foreground after long offline = full re-sync path (no crash — 04 §6.1
"retour foreground = re-sync, pas de crash"); stale state surfaced via `SyncStatus`
(03 §3.2 → UI `offline`/stale, 02 §7); re-sync is job-assisted where heavy.

## 7. UI bridge

React Query ↔ `watch` bridge (03 §5.8, owner `packages/data`): queries subscribe to
local watchers; no query hits the network to render.

## 8. Entity → local table mapping (frozen, 03 §4.2)

Single writer per entity table; no cross-module FK/join; files never in SQLite
(R2 + `r2_key`); server-only tables never mirrored (`expert_skills`, `events` Event
History, `progress_events`, `progress_trends`, `progress_evidences` — mirrors limited
to `skill_states` + `progress_snapshots` per the frozen mapping rule). Full table:
[data-event-job-catalog.md §2](../architecture/data-event-job-catalog.md).

## 9. Tests (03 §7 + 04 §7.1)

Single-writer per entity (kernel `Action` writing `tasks` = failure, F-03) · CRDT
merge lossless · server-wins determinism (concurrent updates → newest wins) ·
view-join static test (`JOIN` on non-public table = failure) · re-sync after
outage · app-kill + relaunch = local state intact (04 §7.1).

## 10. Limitations (documented, not hidden)

- Sync engine = PowerSync (single vendor behind the repository abstraction —
  swappable per AD-1 discipline, but V1 frozen).
- No local semantic retrieval (server-only, AD-12/F-09) — the local mirror keeps
  `source_ref_ids[]`, not embeddings (03 §4.2 note).
- `conflict` is the rare residual state, not the common path (03 §3.2).
