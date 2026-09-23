# Observability Specification (master mission S58)

Authority: AD-16d (Sentry + PostHog, per-kind SLOs), 01 S5.6 (job logs),
04 S7 (platform tests), kernel S12 (Observability component).
**Rule: no sensitive content (corpus text, document bodies, personal data)
in analytics. Only structured metadata (event types, durations, counts,
provider IDs, job kinds, error codes).**

## 1. Sentry (error tracking)

| Scope | What is captured | What is NOT captured |
|---|---|---|
| Mobile (Capacitor) | uncaught exceptions, Promise rejections, performance marks (FID, LCP) | user-entered text, document contents, AI prompt/response bodies |
| Server (Edge Functions) | uncaught exceptions, job failures (per kind), AI call errors (normalized error code, provider, model, attempt -- NO prompt/response) | provider API keys, R2 object contents |
| Focus (device) | session lifecycle errors (start/end/restore/crash/reboot), DPC `setPackagesSuspended` failures | blocklist package names are OK (not sensitive); session content = N/A |

Configuration: per-environment DSN (dev / staging / prod, AD-16: 3 envs).
Release = git SHA (wave 0+). Source maps uploaded per build (04 S7).

## 2. PostHog (product analytics)

| Event class | Examples | Properties (allowed) |
|---|---|---|
| Feature usage | `task_created`, `focus_started`, `focus_ended`, `qcm_completed`, `sheet_generated` | `feature_id`, `duration_ms`, `success: bool`, `error_code?` |
| Agent | `agent_run_started`, `agent_run_completed`, `agent_confirmation_requested`, `agent_confirmation_answered` | `intent_type`, `steps_total`, `steps_completed`, `fallback_used: bool`, `provider`, `model` (no prompt/response) |
| AI pipeline | `ai_call_completed` (per provider call) | `provider`, `model`, `attempt`, `reason` (primary/fallback/last_resort), `expectedQuality`, `latency_ms`, `tokens_input`, `tokens_output` (or `neurons` for CF) |
| Job | `job_dispatched`, `job_completed`, `job_failed`, `job_retry` | `jobKind`, `duration_ms`, `status`, `retryCount`, `idempotencyKey` (hash, not the key itself) |
| Sync | `sync_pending`, `sync_completed`, `sync_conflict` | `mutations_queued`, `duration_ms`, `conflict_type?` |
| Integration | `composio_tool_executed` (composio.md S8) | `toolId`, `app`, `status`, `latency_ms` (NO payload content) |
| Focus (DPC) | `focus_dpc_precheck`, `focus_dpc_applied`, `focus_dpc_restored`, `focus_dpc_crash_recovery` | `blocklist_size`, `rejected_count`, `restore_within_ms` |

**What is NEVER sent to PostHog:** document bodies, course content, user
notes, AI prompt/response text, R2 object keys (beyond a hashed artifact
ID), Composio tool payloads, personal data beyond `distinct_id` (Supabase
Auth user ID, pseudonymous by default).

## 3. AI usage & provider health (AD-5, 01 S5.6)

Tracked server-side (not in PostHog, to avoid quota-sensitive data):

| Metric | Source | Consumer |
|---|---|---|
| tokens / neurons per call | `AIUsageTracker` (01 S5.6) | `AIBudgetManager` (stop-before-overrun) |
| provider latency (p50/p95/p99) | `AIHealthRegistry` | `AIModelRouter` (avoid degraded provider) |
| provider error rate (429/5xx) | `AIHealthRegistry` | `AIFallbackStrategy` (cooldown trigger) |
| quota consumption vs free-tier limit | `AIUsageTracker` + Model Registry quotas (G-U4) | `AIBudgetManager` alert thresholds |
| model retirement | `AIHealthRegistry` (auto-retirement test, 01 S7) | `AIModelRegistry` status update |

## 4. Job status (AD-8)

- `job_logs` (01 S5.3): per-job-kind status, retry count, latency,
  error code. Queried by the job dashboard (server, Foundation).
- `JobCompleted` event (AD-9): user-facing job results (e.g., "your
  sheet is ready"); consumed by UI (OQ-05) + Knowledge + Learning.
- Sentry: job failure = a structured error report (jobKind, step,
  error code, duration -- no payload).
- PostHog: `job_dispatched` / `job_completed` / `job_failed` (S2 above).

## 5. Integration status

- Composio: per-tool execution latency + success rate (PostHog
  `composio_tool_executed`, S2); connection state changes
  (connected / disconnected / reauth_required) = PostHog
  `integration_state_changed`.
- OneSignal: push delivery status (server-side `JobCompleted`);
  double-push detection (04 S7 test).
- R2: upload/download latency + error rate (Sentry + `job_logs` for
  artifact_gen jobs).
- Supabase: sync status (PostHog `sync_*`), RLS violation attempts
  (server logs, Sentry).

## 6. Focus session errors (v1.8 DPC)

- DPC `setPackagesSuspended` failure: Sentry structured error
  (package name, Android version, error code); PostHog
  `focus_dpc_applied` with `rejected_count`.
- Boot-receiver reconciliation: PostHog `focus_dpc_crash_recovery`
  (session ID, time since crash, restore success).
- Pre-check rejections: PostHog `focus_dpc_precheck` (per-package
  status summary: suspendable / not-suspendable / aurora-protected counts).

## 7. Sync errors (03 S5)

- PowerSync sync failures: Sentry (connection error, duration).
- CRDT conflict: PostHog `sync_conflict` (conflict_type, entity type,
  resolution: user-picked / auto-merge).
- Upsync queue overflow: PostHog `sync_pending` with `mutations_queued`
  count; alert threshold (job / Sentry).

## 8. SLOs (per-kind, AD-16d)

| Kind | SLO | Metric source |
|---|---|---|
| AI call (ROUTINE) | p95 < 3 s | `AIUsageTracker` |
| AI call (CRITICAL) | p95 < 10 s (incl. verification job) | `AIUsageTracker` + `job_logs` |
| Job (artifact_gen) | p95 < 30 s | `job_logs` |
| Job (research) | p95 < 60 s | `job_logs` |
| Sync round-trip | p95 < 5 s (online) | PostHog `sync_completed` |
| Focus DPC apply | p95 < 2 s | PostHog `focus_dpc_applied` |
| Notification delivery | p95 < 10 s (OneSignal) | `JobCompleted` latency |

SLO breaches = Sentry alert + PostHog dashboard flag (no auto-pause in
V1; the Foundation duty owner reviews).

## 9. Log discipline

- Server logs (Edge Functions, workers): structured JSON (level,
  message, requestId, jobId?, error code). No prompt/response bodies.
  Retention: 30 days (dev/staging), 90 days (prod) -- AD-16 3-env rule.
- `job_logs`: per-job structured records (kind, status, duration,
  error code, retry count). Retention: 90 days.
- PostHog events: retained per PostHog plan (default 15 months).
- Sentry: retained per Sentry plan (default 90 days free, configurable).
