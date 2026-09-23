# Cloudflare Workers, AI Gateway & Workers AI — exactly who is who

Status: design phase. Authority: 01 §5.2/§5.6, ADR v1.7 §3/§4/§15, spine AD-4/AD-8.
**These four Cloudflare surfaces are distinct — never documented as one blob**
(mission §22):

| Surface | What it is | What it is NOT |
|---|---|---|
| **Aurora backend (Supabase)** | Postgres + Auth + RLS + Edge Functions + Cron (the business system, [../backend/supabase.md](../backend/supabase.md)) | not a Cloudflare Worker |
| **Cloudflare Worker (Aurora's)** | (a) **per-kind job workers** — worker templates consuming `job_queue` (01 §5.2: dispatcher "distribue les jobs vers les Edge Functions/Workers de travail"); (b) the **last-resort fallback Worker** (ADR v1.7 §4): calls Workers AI directly when the main Gateway path is down — **normalizes req/resp + timeouts, ZERO business logic** | not the dispatcher, not the business backend |
| **Cloudflare AI Gateway** | control/observability plane for ALL AI egress (analytics, caching, rate limiting, retries, fallback, Dynamic Routing, Custom Providers — proxies Agnes, ADR v1.7 §3) → see [gateway.md](./gateway.md) | not a worker of Aurora (Aurora's business code never runs there) |
| **Workers AI** | inference pool (second pool + fallback pool, AD-4): GLM-4.7 Flash, Gemma 4 26B A4B, Nemotron 3 Super 120B… → see [providers/workers-ai.md](./providers/workers-ai.md) | not Aurora's code; its free allocation is a **dated photograph** (10 000 Neurons/day, 21 Sept 2026), never a permanent promise |

## Per-worker card (the two Aurora workers)

### (a) Job workers (per kind: `ocr`, `transcription`, `artifact_gen`, `research`,
`scientific`, `agent_run`, `verify`, `mirror-analysis`, …)

- **Purpose**: execute one `job_queue.kind` (payload from `claimJob`, 01 §5.2 `DispatcherApi`).
- **Entrypoint/route**: worker endpoint invoked by the dispatcher (not user-facing); no public route.
- **Authentication**: worker-to-Aurora via server binding (SUPABASE service context); user context travels **inside the job payload** (`user_id` + scopes) — validated against RLS-consistent checks (01 §2.2).
- **Bindings/secrets**: Postgres/`job_queue` access, provider keys via **Cloudflare Secrets Store / Supabase Secrets** (01 §5.6 — never in code, never on device, AD-3); AI egress = **AI Gateway** (b), except the last-resort path.
- **Environments**: dev/staging/prod = the three AD-16a environments (values OQ-03).
- **Timeouts/retries**: per-kind timeout + bounded exponential retry (01 §5.3); dispatcher `claimJob` owns `attempts`.
- **Logging/observability**: `job_logs` (Postgres) + Sentry (01 §5.3/§7); `JobCompleted{jobId,jobKind,status}` event (F-08).
- **Failure**: `reportResult(failed)` → retry until backoff limit → failed state (UI retryable, 01 §6); stuck = per-kind timeout fires (R4 mitigation, 01 §8.2).
- **Deployment**: Foundation-owned CI/CD (AD-16c); one owner of the worker templates (01 §8.1 wave 1: "dispatcher jobs + worker templates").

### (b) Last-resort fallback Worker (ADR v1.7 §4)

- **Purpose**: direct Workers AI call when the Gateway/main path is unavailable.
- **Invariants**: no business logic; request/response normalization + timeouts only; **never used to bypass quotas** (AD-5: a 429 is never rotated around); entry = internal (invoked by the router's fallback strategy, ADR v1.7 §5/§15), exits = Workers AI only.
- **Trace**: still emits `AIResponseEnvelope` (`reason:'last_resort'`, 01 §3.1) — fallback traceability mandatory (AD-5).
