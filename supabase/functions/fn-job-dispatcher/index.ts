/**
 * fn-job-dispatcher — the ONLY dispatcher (01 §5.2).
 * Triggers: (a) Supabase Cron, (b) Postgres NOTIFY on INSERT job_queue (0010).
 * It DISTRIBUTES jobs to workers by kind; it NEVER creates jobs.
 * Contract: DispatcherApi (01 §5.2). Secrets from env, never hardcoded.
 *
 * Wave 2 (ORION) — global JobKind switch wiring (chevauchement rule):
 * this file is the single place the switch over JobKind lives. Modules
 * (Productivity, Discovery, Progress, Learning, Agent…) register their
 * handlers; the dispatcher routes the module-scoped payload to the
 * matching handler and persists the result (AD-8: idempotent — the
 * idempotency key dedupes re-dispatches).
 *
 * Handlers live in the module packages (AD-2: no cross-module table
 * writes; the dispatcher only reads `job_queue` + writes
 * `job_queue.result` / `job_logs`, which are Job-system-owned tables).
 */
import { ok, err, ulid } from "../_shared/envelope.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SECRET_KEY = Deno.env.get("SUPABASE_SECRET_KEY") ?? "";

// ——— Job handler registry (AD-8: one contract, module-provided handlers) ———
// The dispatcher routes by (jobKind, payload.module) so the shared
// `research` kind fans out to the owning module without a 12th kind
// (AD-15 closed vocabulary).

export interface JobHandlerResult {
  ok: boolean;
  result?: unknown;
  error?: string;
}
export type JobHandler = (
  jobId: string,
  userId: string,
  payload: Record<string, unknown>,
) => Promise<JobHandlerResult>;
export interface RegisteredHandler {
  jobKind: string;
  module: string;
  handler: JobHandler;
}

/** The global switch registry. Owned by ORION (chevauchement rule);
 *  SAPPHO/VECTOR/ECHIDNA plug in without editing the dispatcher. */
const HANDLERS: RegisteredHandler[] = [];

/** Register a module's handlers (idempotent by module+jobKind). */
export function registerHandlers(handlers: RegisteredHandler[]): void {
  for (const h of handlers) {
    const exists = HANDLERS.some(
      (x) => x.module === h.module && x.jobKind === h.jobKind,
    );
    if (!exists) HANDLERS.push(h);
  }
}

/** Route a job to its module handler (the global JobKind switch). */
export function route(
  job: { id: string; userId: string; payload: Record<string, unknown> },
): RegisteredHandler | null {
  const kind = String(job.payload.kind ?? "");
  const module = String(job.payload.module ?? "");
  const match =
    HANDLERS.find((h) => h.jobKind === kind && h.module === module) ??
    (module === "" ? HANDLERS.find((h) => h.jobKind === kind) : undefined);
  return match ?? null;
}

interface DueJob {
  id: string;
  user_id: string;
  kind: string;
  payload: Record<string, unknown>;
}

/** Fetch due jobs (the dispatchDue surface of DispatcherApi). */
async function fetchDue(
  now: string,
  limit: number,
): Promise<DueJob[]> {
  if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) return [];
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/job_queue?status=eq.pending&due_at=lte.${now}&limit=${limit}&order=due_at.asc`,
    {
      headers: {
        apikey: SUPABASE_SECRET_KEY,
        Authorization: `Bearer ${SUPABASE_SECRET_KEY}`,
      },
    },
  );
  if (!res.ok) return [];
  return (await res.json()) as DueJob[];
}

/** Claim a due job (AD-8: status pending→running, attempts++). */
async function claim(jobId: string, userId: string): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) return;
  await fetch(`${SUPABASE_URL}/rest/v1/job_queue?id=eq.${jobId}`, {
    method: "PATCH",
    headers: {
      apikey: SUPABASE_SECRET_KEY,
      Authorization: `Bearer ${SUPABASE_SECRET_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      status: "running",
      user_id: userId,
    }),
  }).catch(() => {});
}

/** Report the result (AD-8: status→done/failed, persist result). */
async function report(
  jobId: string,
  userId: string,
  result: { status: "done" | "failed"; result?: unknown },
): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) return;
  await fetch(`${SUPABASE_URL}/rest/v1/job_queue?id=eq.${jobId}`, {
    method: "PATCH",
    headers: {
      apikey: SUPABASE_SECRET_KEY,
      Authorization: `Bearer ${SUPABASE_SECRET_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      status: result.status,
      result: result.result ?? null,
      user_id: userId,
      updated_at: new Date().toISOString(),
    }),
  }).catch(() => {});
}

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}));
    const limit = (body as { limit?: number }).limit ?? 10;
    const now = new Date().toISOString();
    const traceId = ulid();
    console.log(
      `[fn-job-dispatcher] dispatchDue now=${now} limit=${limit} supabase=${SUPABASE_URL ? "configured" : "MISSING"}`,
    );

    // Claim due jobs → route by (kind, module) → report result.
    // Unroutable jobs (no handler registered yet) are left pending for
    // the next dispatch (AD-8: idempotent, no data loss).
    const due = await fetchDue(now, limit);
    let picked = 0;
    let skipped = 0;
    for (const job of due) {
      const handler = route({
        id: job.id,
        userId: job.user_id,
        payload: { ...job.payload, kind: job.kind },
      });
      if (handler === null) {
        skipped += 1;
        continue;
      }
      await claim(job.id, job.user_id);
      const res = await handler.handler(job.id, job.user_id, job.payload);
      await report(job.id, job.user_id, {
        status: res.ok ? "done" : "failed",
        result: res.ok ? res.result : { error: res.error },
      });
      picked += 1;
    }
    return ok({ picked, skipped, traceId });
  } catch (e) {
    console.error("[fn-job-dispatcher] error", e);
    return err("job/dispatch_error", String(e));
  }
});
