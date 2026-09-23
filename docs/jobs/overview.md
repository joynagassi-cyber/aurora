# Async Jobs (AD-8) — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 1 mechanics; wave 2+ kinds). Authority:
spine AD-8, `01-backend` §5.2/§5.3, ADR §26 (serverless targeted + persisted jobs).

## 1. Purpose

Everything heavy is a **persisted, identifiable, idempotent, retryable, observable**
job — no long work blocks the UI (AD-8; mission §24). Heavy capabilities: OCR,
transcription, artifact generation, research, scientific compute, FSRS ticks,
`skill_states` recompute, agent runs/verify (01 §5.2/§5.6).

## 2. The flow (mission §24)

```
Supabase Cron (pure short trigger functions) ─┐
                                               ├→ INSERT job_queue
Postgres trigger (on key tables, e.g. flashcards → fsrs-tick,
                          progress_evidences → skill recompute) ─┘
          ↓
fn-job-dispatcher (the ONLY dispatcher; distributes, never creates jobs)
          ↓  claim (status running, attempts++)
worker Edge Function / Cloudflare Worker (by kind)
          ↓  reportResult
JobCompleted event (jobId + jobKind mandatory, F-08) → job_logs + Sentry
```

## 3. Contract (frozen, 01 §5.2)

`DispatcherApi = { dispatchDue(now, limit?), claimJob(jobId, workerKind),
reportResult(jobId, result) }`; `workerKind = job_queue.kind`; one kind vocabulary in
`packages/domain` (AD-15). Trigger sources are **exclusively** (a) Supabase Cron and
(b) the Postgres trigger on INSERT `job_queue` — any other source = AD-8 violation.

## 4. `job_queue` schema (01 §5.3; full shape to be frozen per G-M4)

`jobId`, `kind`, `status pending/running/done/failed`, `attempts`, `due_at`,
`user_id`, `idempotency_key = kind + hash(logical payload) + user_id` (UNIQUE),
nullable `source_local_mutation_id` (ULID, client-origin dedup, 03 §5.5),
`updated_at`; retry = bounded exponential backoff + **per-kind timeout** (01 §5.3);
`job_logs` = observability (Sentry wiring, 01 §7).

## 5. Status semantics & UI (01 §6)

`pending`/`running` → UI `loading`; `failed` → UI `error` with `jobId` for retry;
the event producer stays the job system (never each module, AD-9); the UI remains
"honest": a failed job is retryable from the surface.

## 6. Rules & tests

- Idempotency per kind (01 §7: re-executed with the same key = no duplicate effect).
- A job stuck in `pending`/`running` without deadline = lost work (risk R4):
  per-kind timeout + SLO alerts; duty owner = Foundation (AD-16d).
- No UI-blocking heavy path: any feature adding one = blocking review finding.
- Durable-execution note: if wave-3 kernel workflows want a library engine, it stays
  behind `DispatcherApi` + the job store (01 §8.3, wave-3 option).

## 7. Kinds inventory (complete, mission §50)

`ocr` · `transcription` · `artifact_gen` (large artifact processing) ·
`export` (MD/PDF/DOCX/PNG sheet/infographic render, ADR §17/§25.4) · `research`
(multi-source) · `agent_run` (kernel loop) · `verify` (critical tasks, 01 §5.6) ·
`scientific` (heavy compute) · `mirror-analysis` (01 §4.2) · `fsrs-tick` ·
`skill_recompute` · `prioritization` (impact analysis, optional) — all: dispatched
by `fn-job-dispatcher` only, persisted in `job_queue`, retried with backoff,
idempotent by key, observable via `job_logs` + Sentry. Long AI multi-step runs =
`agent_run` + step records in Postgres (durable-by-storage; a library engine, if
ever needed, stays behind `DispatcherApi` — 01 §8.3 wave-3 option).
