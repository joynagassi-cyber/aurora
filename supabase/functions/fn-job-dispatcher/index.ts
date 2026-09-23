// fn-job-dispatcher — the ONLY dispatcher (01 §5.2).
// Triggers: (a) Supabase Cron, (b) Postgres NOTIFY on INSERT job_queue (0010).
// It DISTRIBUTES jobs to workers by kind; it NEVER creates jobs.
// Contract: DispatcherApi (01 §5.2). Secrets from env, never hardcoded.

import { ok, err, ulid } from "../_shared/envelope.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SECRET_KEY = Deno.env.get("SUPABASE_SECRET_KEY") ?? "";

Deno.serve(async (req) => {
  try {
    // Stub wave-0: read the due jobs, log, return 200 ok.
    // The real dispatch (worker invocation per kind) lands in wave 1.
    const body = await req.json().catch(() => ({}));
    const limit = (body as { limit?: number }).limit ?? 10;

    const now = new Date().toISOString();
    console.log(`[fn-job-dispatcher] dispatchDue now=${now} limit=${limit} supabase=${SUPABASE_URL ? "configured" : "MISSING"}`);

    // Stub: no live dispatch yet. Return the contract shape so callers wire correctly.
    return ok({ picked: 0, skipped: 0, traceId: ulid() });
  } catch (e) {
    console.error("[fn-job-dispatcher] error", e);
    return err("job/dispatch_error", String(e));
  }
});
