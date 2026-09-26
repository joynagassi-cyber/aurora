# Aurora — PowerSync Wave 0 (MINERVA)

Local-first sync layer (AD-7 / 03-sync). Wave 0 delivers the **prerequisites**
for the relay: the mirror mapping, the relay-scoped views, and the config.
Per 03 §8.1, the **relay is operational in wave 1** — this commit ships the
schema/views/config it needs, plus a documented round-trip test.

## Layout

```
powersync/
  cli.yaml         link file (instance cloud : org/project/instance id)
  service.yaml     service config Cloud (replication + client_auth supabase)
  sync-config.yaml Sync Streams (edition 3) — 1 flux = 1 module owner
  schema.json      PowerSync schema (mirror SSoT — S4.2/5.4)
  relay.sql        relay-scoped views + GRANTs (fichier SSoT ; tracker
                   live = supabase/migrations/0015)
  test/roundtrip.md  1-row insert -> PowerSync -> SQLite (03 S7)
```

## Streams par module owner (S4.2/F-03)

10 flux auto_subscribe, per-table, filtrés `user_id = auth.user_id()`,
priorités 1/2/3 (identity / core / bulk, OQ-11 + AD-14) :

`identity` (priority 1) · `productivity` (tasks/subtasks/projects/goals,
priority 2) · `productivity_bulk` (milestones/habits/routines/
focus_sessions/decisions/calendar_events) · `knowledge` (notes/resources/
semantic_*/node_state/source_refs) · `learning` (courses/subjects/skills/
learning_sessions/reviews) · `progress` (skill_states/progress_snapshots/
**gaps** — l'exposition de `gaps` par ce flux est la résolution de la
divergence 0012) · `discovery` (discovery_items) · `artifact` (artifacts) ·
`integrations` (automations) · `ascent_paths` + `user_goals` (wave 3,
HEPHAESTUS/Ascent).

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

## Wave 1 status (2026-09-26)

- **Live Supabase** : publication `powersync FOR ALL TABLES` (0001) ; les 8
  vues `v_*_scope` + GRANTs `service_role` appliquées (`supabase/migrations/
  0015_powersync_relay_views.sql`, relay.sql reste le SSoT) ; table
  `subtasks` créée (0013).
- Les flux `sync-config.yaml` sont **per-table** (pas d'UNION ALL) : le
  relay lit les tables réelles sous RLS ; les vues relay servent de SSoT
  d'audit + lecture inter-module (0012).
- `gaps` (mirror Discovery, `schema.json`) est peuplée par le flux
  **progress** (`gaps WHERE user_id = auth.user_id()`, F-03 single-writer)
  — le flux Discovery n'y touche pas ; `v_progress_public` (0012) reste la
  surface de lecture inter-module pour Discovery.
- **0014 (pg_cron)** : non appliquée au live — `permission denied for
  table cron.job` pour le rôle du MCP ; à exécuter via le dashboard
  Supabase.
- **PowerSync Cloud** : instance `6ab1612e8453e7cf8338ef9a` (= `POWERSYNC_URL`
  du `.env.local`, org Aurora, region eu). `cli.yaml` + `service.yaml`
  écrits ; `client_auth.supabase: true` (JWKS auto-détecté, audience
  `authenticated`, aucun secret en clair — AD-3). `sync-config.yaml` = 10
  flux Sync Streams (edition 3), 1 flux = 1 module owner, `auth.user_id()`,
  priorités 1/2/3.
- `PS_ADMIN_TOKEN` dans `.env.local` = token PowerSync Cloud de l'org
  **Aurora** (celui du projet) → `powersync validate` + `powersync deploy`
  (dev uniquement ; prod off-limits sans approbation).
- **Redeploy 2026-09-26** : 12 flux Sync Streams (edition 3) déployés sur
  l'instance dev `6ab1612e…` (slot `_2_4761`, `initial_replication_done`,
  lag 0) : 8 modules wave 1 (`identity`, `productivity`,
  `productivity_bulk`, `knowledge`, `learning`, `progress`, `discovery`,
  `artifact`, `integrations`) + `user_goals` + `ascent`. Les deux tables
  wave 3 portent `user_id` (0016 `ascent_paths.user_id`, 0017
  `user_goals.user_id`) → filtre `WHERE user_id = auth.user_id()` identique
  aux autres flux ; `gaps` exposée par le flux `progress` (0012, F-03
  single-writer). Le schéma miroir client
  (`packages/data/src/powersync-schema.ts`) expose `ascent_paths`
  (11 colonnes) + `user_goals` (7 colonnes), aligné avec
  `POWERSYNC_SCHEMA.mirrorTables` (drift détecté au typecheck
  `@aurora/data`).
- **Résidu `powersync status`** : warning « Table "public"."X" not found »
  sur les 31 tables streamées, alors que ces tables EXISTENT sur le même
  DB via l'API Supabase (`pg_class` : `public.user_context` oid 141681,
  publication `powersync FOR ALL TABLES`). Anomalie déjà vue post-deploy
  00:00 (v1.7, résolue par refresh du catalog) et revenue durablement
  après le redeploy de 21:18 UTC (vérifié sur les slots `_1_811d` ET
  `_2_4761` : `replication_id: —`, 30/30 warnings). Cause probable : le
  secret `default_password` (définition 0001) ne correspond plus au mot de
  passe courant du DB Supabase. **Action manuelle requise
  (dashboard)** : PowerSync dashboard → instance Development →
  connection « Default » → re-saisir le mot de passe courant (Supabase
  Dashboard → Settings → Database) ; `service.yaml` garde
  `secret_ref: default_password` (le secret est défini côté Cloud —
  `fetch config` confirme). Re-vérifier après : `powersync validate`
  (plus de warnings) puis `powersync deploy sync-config`.

## App-side engine (03 S8.1, `packages/data` + `apps/mobile`)

- `packages/data/src/powersync-client.ts` — `PowerSyncClientEngine`
  (wrappe `PowerSyncDatabase` de `@powersync/capacitor` + le schéma miroir
  gelé `AuroraPowerSyncSchema` + le connecteur Supabase). Le SDK vendor
  reste dans l'adapter (AD-1) ; le shell ne l'importe jamais directement.
- `packages/data/src/supabase-connector.ts` — `SupabaseBackendConnectorImpl`
  (`fetchCredentials` = JWT de la session Supabase signée, `uploadData` =
  upsert/patch/delete sur PostgREST sous RLS ; stratégie d'erreur gelée :
  RLS 42501 / contraintes = permanent → `transaction.complete()` + log
  (la file ne se bloque jamais) ; transitoire → `throw` (retry avec
  backoff PowerSync).
- `packages/data/src/local-store-bridge.ts` — `EngineLocalStoreBridge`
  : le swap 03 S8.1 derrière `LocalStore` ; les repositories
  (`SqliteQueryRepository`) continuent de lire via le contrat référence,
  maintenant adossé au miroir SQLite réel.
- `apps/mobile/src/lib/boot-data.ts` — le point de boot du shell :
  `createAuroraDataProvider` construit client Supabase (clé publishable
  uniquement, AD-3) + moteur + bridge ; `connect()` exige une session
  Supabase active (le `fetchCredentials` du connecteur lit
  `client.auth.getSession()`), `dispose(true)` = `disconnectAndClear()`
  (sortie / changement d'utilisateur, 03 S5.5.6).

> **relay operationnel = wave 1** (03 S8.1). The round-trip test is written and
> runnable now; it is **skipped with reason** while the relay is not
> provisioned, and executed in wave 1.
