# Aurora — Supabase Wave 0 (MINERVA)

Backend foundation: **PostgreSQL schema + RLS + public views**, **pg_cron**, and
**Edge Function stubs**. This is the transactional source of truth (AD-6).

## Layout

```
supabase/
  migrations/   0001..0012 — applied in order (CREATE ... IF NOT guarded where safe)
  functions/    fn-job-dispatcher / fn-import-course / fn-notifications / fn-agent-run (wave-0 stubs)
  config.toml   pg_cron entries (ASSUMPTION wave-0) + EF catalog
  .env.example  VARIABLES ONLY — real values in repo-root .env.local (AD-3)
```

## Migration map (→ doc sections)

| File | Module / area | Ref |
|---|---|---|
| `0001_extensions_identity` | vector + pg_cron + pgcrypto; `user_context` (Identity, AD-17 theme enum) | 01 §2.1/§4.10 |
| `0002_productivity` | `tasks`,`projects`,`goals`,`milestones`,`habits`,`routines`,`focus_sessions`,`decisions`,`calendar_events` | 01 §4.1 |
| `0003_learning` | `courses`,`subjects`,`skills`,`learning_sessions`,`reviews`,`flashcards`(FSRS),`course_imports` | 01 §4.2 |
| `0004_knowledge` | `knowledge_documents`,`document_chunks`(vector+FTS),`semantic_*`,`node_state`,`source_refs`,`notes`,`resources` | 01 §4.3, AD-6 |
| `0005_progress` | `progress_snapshots`,`progress_evidences`,`skill_states`,`progress_trends`,`progress_events`,`trajectory_scenarios`,`gaps` | 01 §4.4 |
| `0006_discovery` | `discovery_items`,`discovery_source_profiles`,`domain_timeline` | 01 §4.5 |
| `0007_artifact` | `artifacts`(metadata+r2_key),`artifact_files` | 01 §4.6 |
| `0008_agent_integrations` | `agent_runs`,`agent_actions`,`expert_skills`(server-only, AD-3),`integrations`,`automations`,`notification_preferences` | 01 §4.7 |
| `0009_event_history` | global `events` (ULID, payload jsonb, `producer`, 2y retention, audit-only) | 01 §4.8 |
| `0010_jobs` | `job_queue`(G-M4 full shape)+`job_logs`+INSERT trigger | 01 §5.2/§5.3, AD-8 |
| `0011_registres` | `model_registry`(AD-5/AD-16b),`ai_usage`,`ai_health` | 01 §4.10 |
| `0012_public_views` | `v_productivity_public`,`v_progress_public`,`v_knowledge_public` | 01 §3.4, 03 §5.4 |

## RLS strategy (01 §2.2, frozen)

- `ENABLE ROW LEVEL SECURITY` + `FORCE ROW LEVEL SECURITY` on **every** business table
  (service_role/dispatcher/PowerSync go through policies, never `BYPASSRLS`/GRANT superuser).
- Default policies are **strictly bound by `auth.uid()`** (per-user isolation).
- `service_role` policies are **explicitly bound by `user_id`** and each carries a
  justification comment (a service policy without a user/job bound = blocking bug).
- Cross-module reads go through the **public view** of the source module
  (`security_invoker = on`, so callers still inherit the owner's RLS — 01 §3.4).
- No `USING (true)` user policy exists, except the global server registries
  (`model_registry`,`ai_health`,`ai_usage` service write) which are explicitly
  justified as server-owned registries with no user dimension.

## Applying migrations

```bash
# Repo root has pnpm-workspace; Supabase CLI 2.x
supabase link --project-ref <AURORA_PROJECT_REF>   # link the Aurora project (see .env.local SUPABASE_URL)
supabase db push                                    # apply 0001..0012 in order
supabase cron enable                                # install pg_cron + job schema
# register the pg_cron entries from supabase/config.toml on the live project
supabase functions deploy fn-job-dispatcher fn-import-course fn-notifications fn-agent-run
```

## Wave-0 vs Wave-1 (relay)

Per 03 §8.1, the **PowerSync relay is operational in wave 1**. Wave 0 delivers the
**prerequisites**: the schema, RLS, public views, and relay-scoped tables. The
`relay` component itself (reads views via service_role under RLS, 03 §5) ships in
wave 1 — documented in commit 2.

## Testing

- **Migrations**: `supabase db push` applies 0001..0012 with no error (state
  recorded in commit 1).
- **R2 presign**: `pnpm exec tsx scripts/r2-presign.ts` (commit 3).
- **Cron/EF curl**: `curl -X POST <SUPABASE_URL>/functions/v1/fn-job-dispatcher -H 'apikey: $SUPABASE_PUBLISHABLE_KEY' -d '{}'` → 200 (commit 4).

## Key conventions (frozen SSoT, referenced not repeated)

- **R2 key convention** = `docs/cloudflare/r2.md §1` (the ONLY source of truth):
  `{env}/{user_id}/{module}/{yyyy}/{mm}/{dd}/{ULID}[_slug].{ext}`. 01 §5.4 is
  obsolete on key naming — do not follow it (documented in commit 3).
- **ULID** ids (26-char, sortable) for `events`/`job_queue`/`source_local_mutation_id`.
- **CRDT OR-Set** columns (`crdt_added`/`crdt_removed` jsonb) on merge lists;
  SSoT encoding in `packages/domain` (TODO wave 1).
