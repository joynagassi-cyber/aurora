# Supabase Backend (Auth · PostgreSQL · RLS · Edge Functions · Jobs)

Status: design phase. Authority: 01 §2/§5/§7, 03 §3.4/§5, 01 §8.1 (wave 1: Auth +
data provisioning), AD-16. Supabase = the backend of record (spine Stack).

## 1. Auth

Supabase Auth (01 §6, §8.1 wave 1): JWT auto-refresh; expired/failed → login screen;
**the device cannot call Edge Functions without identity** (01 §6). `user_id` + FK
`auth.users` on every table (01 §4 header) = the tenant-isolation root; Identity
module = `profiles` + `UserContext` (01 §2.1).

## 2. PostgreSQL & RLS (AD-2 enforcement at the data layer — 01 §2.2 ruling)

- Per-module schemas, all tables `ENABLE ROW LEVEL SECURITY`; user policies =
  `auth.uid() = user_id` (never `USING (true)` — 01 §8.2 R2: that is a disaster,
  reviewed systematically by Codex).
- `service_role` reads PowerSync views **through RLS policies, never BYPASSRLS**
  (01 §3.4); penetration test on **every** table, blocking for policy migrations
  (01 §7).
- Triggers: INSERT on `job_queue` (dispatcher, 01 §5.2) + key-table triggers
  (`flashcards` → `fsrs-tick`, `progress_evidences` → `skill_states` recompute,
  01 §5.2). The two authorized trigger sources of jobs (AD-8).

## 3. Per-module data surface (tables / views / functions / policies / indexes / relations)

Conceptual catalog = [data-event-job-catalog.md](../architecture/data-event-job-catalog.md)
(no DDL in V1 docs — spine § Deferred; the Data team cuts the DDL in wave 1, owner
`packages/data`, AD-7/AD-16b). Module→table map: 01 §4.1–4.10 (Productivity,
Learning, Knowledge + pgvector, Progress, Discovery, Artifact/R2 metadata, Agent/
Integrations + `expert_skills`, Event History, jobs `job_queue`/`job_logs`, Model
Registry `model_registry` + `ai_usage`/`ai_health`). PowerSync views (read-only,
declarative, single-module-owner scopes, no cross-module joins, 03 §5.4) are the
**only** server surface the device consumes.

## 4. Edge Functions (catalog, 01 §5.1)

`fn-job-dispatcher` (the only dispatcher — distributes, never creates jobs, 01
§5.2; `DispatcherApi` contract frozen) · `fn-import-course` (OCR path) ·
`fn-notifications` (OneSignal server-side — the only place the server key lives, 04
§3.2.5) · `fn-agent-run` (kernel entry, F-09) · per-kind worker functions ·
presigning functions for R2 (`presignGet` TTL 15 min / `presignUpload` TTL 5 min,
01 §5.4). Every function returns `ApiEnvelope<T>` (01 §3.1).

## 5. Transactions, repositories, security boundaries

- **Transactions**: module writes are single-writer (AD-7); cross-module writes are
  forbidden (AD-2) → no multi-module transactions by design; a module's transaction
  scope = its own tables (+ its `events` insert for AD-9 events).
- **Repositories**: `packages/data` owns all repositories + views + Model Registry
  (01 §2.3); UI reads via `LocalQueryRepository`, writes via `LocalCommandRepository`
  (03 §3.1) — the app never sees Supabase directly on the render path.
- **Security boundaries**: per-user RLS (above) · service_role confined to views ·
  secrets in Supabase Secrets / Cloudflare Secrets Store (never in code, never on
  device — AD-3, 01 §5.6) · CI greps (SPEC wave-0 gate).
- **Jobs** live in Postgres (`job_queue`/`job_logs`, 01 §5.3) — durable by storage;
  executors (Edge Functions/Workers) are stateless (AD-8).
- **Events**: `events` tables per module + Postgres trigger → job / incremental
  reads (01 §3.3, no broker V1).

## 6. Failure & observability

Job failures → `job_logs` + Sentry + `JobCompleted{status:'failed'}` (UI retryable
with `jobId`, 01 §6); per-kind SLOs + alerts; **Foundation = duty owner** until a
module owns measurable traffic (AD-16d, 01 §7 observability tests). Auth failures →
login redirect (01 §6). Stale sync → re-sync path (03 §5.5).

## 7. Database functions (PL/pgSQL) — scope decision

V1 uses **triggers + Postgres Cron only** as server-side extension points (01 §5.2:
the two authorized trigger sources of jobs). PL/pgSQL database functions: **not used
in the V1 design** (no stored business logic — business rules live in
`packages/domain` and Edge Functions/jobs, per the modular-monolith decision); if the
Data team needs one at wave 1 (e.g. a normalization helper), it is an additive
decision recorded in the Data Contract Pack, reviewable and removable.
