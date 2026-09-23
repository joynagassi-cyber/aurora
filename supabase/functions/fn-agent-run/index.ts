// fn-agent-run — 01 §5.1 contract:
//   IN  { intent, contextRefs[], taskProfile }
//   OUT 202 { ok, data: { jobId } }
// The Agent kernel runs SERVER-side (AD-12/F-09); the client only reads UI state.

import { ok, err, ulid } from "../_shared/envelope.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SECRET_KEY = Deno.env.get("SUPABASE_SECRET_KEY") ?? "";

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}) as {
      intent?: string;
      contextRefs?: string[];
      taskProfile?: Record<string, unknown>;
    });

    if (!body.intent) return err("agent/missing_intent", "intent is required", 400);
    if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) {
      console.warn("[fn-agent-run] SUPABASE secrets not configured — cannot enqueue agent job");
      return err("agent/secrets_missing", "Server env not configured", 503);
    }

    // Stub wave-0: the kernel loop + job enqueue (kind=agent_run) lands in wave 1.
    const jobId = ulid();
    console.log(
      `[fn-agent-run] intent=${body.intent} refs=${(body.contextRefs ?? []).length} ` +
      `profile=${body.taskProfile ? "set" : "default"} -> jobId=${jobId}`,
    );

    return ok({ jobId }, 202);
  } catch (e) {
    console.error("[fn-agent-run] error", e);
    return err("agent/run_error", String(e), 500);
  }
});
