// fn-agent-run — 01 §5.1 contract:
//   IN  { intent, contextRefs[], taskProfile }
//   OUT 202 { ok, data: { agentRunId, jobId } }
//
// Wave 3 (ORACLE) — complete the wave-0 stub:
//  - AD-12/F-09: the kernel runs SERVER-side; the device sees ONLY
//    AgentRunState (02 S4) — this function enqueues the `agent_run`
//    job and returns the run id; the kernel loop itself executes in
//    the job dispatcher's agent handler (a shared file, remaining gap).
//  - AD-8: the heavy agent step persists as a job_queue row
//    (kind = 'agent_run', idempotency key = agent:<runId>).
//  - AD-3: zero provider keys on the device — SERVICE_ROLE_KEY
//    stays in the server env (Deno.env), and payload carries NO
//    provider / router / key material.
//  - F-09 SSoT: the `agent_runs` mirror row is created HERE at enqueue
//    (status='running'); the dispatcher's persistRun updates it at the
//    terminal state. `agent_runs.id` is the table's uuid PK; `trace_id`
//    carries the kernel's ULID agentRunId (the device-facing handle —
//    the device polls by trace_id). The job payload carries
//    `agentRunsId` so persistRun patches BY the uuid PK (a trace_id
//    filter would never match the uuid column).
//
// NOTE (cross-boundary): fn-job-dispatcher is the shared global
// JobKind switch (ORION, chevauchement rule). The agent_run handler
// that boots packages/agent's AgentKernel and persists
// AgentRunState chunks to the `agent_runs` table must be registered
// there — that edit is flagged as a remaining gap, not done here
// (single-writer, AD-7).

import { ok, err, ulid } from "../_shared/envelope.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
// Le secret service_role est stocké sous SERVICE_ROLE_KEY (Supabase refuse
// tout nom commençant par SUPABASE_). Les EF lisent SERVICE_ROLE_KEY.
// La valeur peut être une clé legacy JWT ("eyJ...") ou moderne ("sb_secret_...") :
// pour la moderne, ne l'envoyer QUE sur le header apikey (pas Authorization).
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") ?? "";
function restHeaders(): Record<string, string> {
  const h: Record<string, string> = { "Content-Type": "application/json" };
  if (!SERVICE_ROLE_KEY) return h;
  const isLegacyJwt = SERVICE_ROLE_KEY.startsWith("eyJ");
  h.apikey = SERVICE_ROLE_KEY;
  if (isLegacyJwt) h.Authorization = `Bearer ${SERVICE_ROLE_KEY}`;
  return h;
}

interface AgentRunRequest {
  intent?: string;
  contextRefs?: string[];
  taskProfile?: Record<string, unknown>;
  /**
   * LOT 1-bis / Story 1.1-bis — user confirmation decisions now carry the
   * step content hash (`stepHash`, stamped server-side at prompt time,
   * exposed on the `confirmation` event). A decision whose stepHash no
   * longer matches is treated as "no decision" (the kernel re-prompts,
   * never auto-confirms). A client-supplied `resumeFrom.pendingPlan` is
   * rejected with 400 `agent/plan_not_accepted` before the /auth/v1/user
   * validation: the pending plan is ALWAYS re-loaded server-side from
   * `agent_runs` by (agentRunId, user_id).
   */
  decisions?: Array<{ stepId: string; answer: 'confirmed' | 'rejected'; stepHash?: string }>;
  /**
   * LOT 1-bis / Story 1.1-bis — resume surface: the previous pass's run
   * handle. The client sends ONLY `{ agentRunId }` — the pending plan is
   * re-loaded SERVER-SIDE from `agent_runs` BY agentRunId + user_id (the
   * user_id comes from the validated Bearer JWT, never the body). A
   * client-supplied `pendingPlan` is REJECTED with 400
   * `agent/plan_not_accepted` — a forged plan must never bypass the
   * confirmation points.
   */
  resumeFrom?: { agentRunId: string; pendingPlan?: unknown };
}

/**
 * Normalise a raw `decisions` body into the closed
 * `{ stepId: string; answer: 'confirmed' | 'rejected'; stepHash?: string }`
 * shape (LOT 1-bis / Story 1.1-bis: `stepHash` = the step content hash
 * that binds the answer to its exact step). Anything else (non-array,
 * non-object entries, unknown answers, non-string stepHash) is dropped —
 * a malformed decision must NOT become an auto-confirm.
 */
export function normalizeDecisions(
  raw: unknown,
): Array<{ stepId: string; answer: 'confirmed' | 'rejected'; stepHash?: string }> {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter(
      (d): d is { stepId: string; answer: 'confirmed' | 'rejected'; stepHash?: string } =>
        typeof d === "object" &&
        d !== null &&
        typeof (d as { stepId?: unknown }).stepId === "string" &&
        ((d as { answer?: unknown }).answer === "confirmed" ||
          (d as { answer?: unknown }).answer === "rejected") &&
        ((d as { stepHash?: unknown }).stepHash === undefined ||
          typeof (d as { stepHash?: unknown }).stepHash === "string"),
    )
    .map((d) => {
      const stepHash = (d as { stepHash?: unknown }).stepHash;
      return { stepId: d.stepId, answer: d.answer, ...(stepHash ? { stepHash: stepHash as string } : {}) };
    });
}

/**
 * Enqueue the agent_run job (AD-8). Service-role insert into
 * job_queue (the Job-system-owned table). Returns the jobId; a
 * unique-violation on idempotency_key means an identical job is
 * already queued — the dispatcher dedupes it (01 §5.3).
 *
 * Also creates the `agent_runs` row (F-09 SSoT run state — the device
 * polls it, AD-3/AD-12): `id` is the table's uuid PK, `trace_id`
 * carries the kernel's ULID agentRunId (the device-facing run handle).
 * The job payload carries `agentRunsId` so the dispatcher's
 * persistRun patches BY the uuid PK (a trace_id/ULID filter would
 * never match the uuid column).
 */
async function enqueueAgentRun(req: {
  agentRunId: string;
  userId: string;
  body: AgentRunRequest;
}): Promise<{ jobId: string; agentRunsId: string; alreadyQueued: boolean } | null> {
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return null;
  const payload = {
    kind: "agent_run",
    module: "agent",
    agentRunId: req.agentRunId,
    intent: req.body.intent,
    contextRefs: req.body.contextRefs ?? [],
    taskProfile: req.body.taskProfile,
    // LOT 1 / Story 1.1: the device's confirmation answers (closed
    // vocabulary: stepId + confirmed/rejected). No secret material
    // (AD-3) — the kernel handler normalises it once more on its side.
    ...(Array.isArray(req.body.decisions) ? { decisions: req.body.decisions } : {}),
    // LOT 1-bis / Story 1.1-bis: only the run handle is carried — the
    // pending plan is re-loaded server-side (agent_runs, by agentRunId +
    // user_id), never the client's.
    ...(req.body.resumeFrom?.agentRunId ? { resumeFrom: { agentRunId: req.body.resumeFrom.agentRunId } } : {}),
    // LOT 1-bis / Story 1.2-bis: NO user JWT in the payload. The
    // dispatcher's agent_run handler carries the job_queue row's
    // `user_id` (validated here at enqueue via /auth/v1/user, below)
    // explicitly to the kernel run; the invokeTool seam reaches
    // fn-canvas over the internal channel (x-aurora-internal +
    // x-aurora-user-id). No token persists in the DB, no module global.
    // AD-3: no provider / key / router material in the payload.
  };

  // 1. Create the agent_runs mirror row (F-09). return=representation
  //    hands back the generated uuid PK; one row per run — the ULID
  //    agentRunId is unique by construction (the trace_id filter guards
  //    a same-run re-invoke).
  const runsRes = await fetch(
    `${SUPABASE_URL}/rest/v1/agent_runs?select=id&trace_id=eq.${req.agentRunId}&limit=1`,
    {
      method: "POST",
      headers: restHeaders(),
      body: JSON.stringify({
        user_id: req.userId,
        intent: req.body.intent,
        status: "running",
        trace_id: req.agentRunId,
      }),
    },
  );
  if (!runsRes.ok) {
    console.error(
      `[fn-agent-run] agent_runs create failed status=${runsRes.status} ${await runsRes.text().catch(() => "")}`,
    );
    return null;
  }
  const runsRows = (await runsRes.json().catch(() => [])) as Array<{ id: string }>;
  const agentRunsId = runsRows[0]?.id;
  if (!agentRunsId) return null;

  // 2. Enqueue the agent_run job (idempotency = agent:<agentRunId>).
  payload.agentRunsId = agentRunsId;
  const enqueueHeaders = restHeaders();
  enqueueHeaders["Prefer"] = "resolution=merge-duplicates, return=representation";
  const res = await fetch(`${SUPABASE_URL}/rest/v1/job_queue`, {
    method: "POST",
    headers: enqueueHeaders,
    body: JSON.stringify({
      id: req.agentRunId,
      user_id: req.userId,
      kind: "agent_run",
      payload,
      status: "pending",
      // one retry only (01 §5.3: critical agent steps, max_attempts 1
      // reserved for agent_verify; a generic agent_run keeps the default)
      idempotency_key: `agent:${req.agentRunId}`,
      trace_id: req.agentRunId,
    }),
  });
  if (!res.ok) {
    console.error(
      `[fn-agent-run] enqueue failed status=${res.status} ${await res.text().catch(() => "")}`,
    );
    return null;
  }
  const rows = (await res.json().catch(() => [])) as Array<{ id: string }>;
  return { jobId: rows[0]?.id ?? req.agentRunId, agentRunsId, alreadyQueued: false };
}

Deno.serve(async (req) => {
  try {
    const body = (await req.json().catch(() => ({}))) as AgentRunRequest;

    if (!body.intent) return err("agent/missing_intent", "intent is required", 400);
    // LOT 1 / Story 1.1: normalise decisions (closed vocabulary — invalid
    // entries are dropped, never an auto-confirm) before enqueuing.
    body.decisions = normalizeDecisions(body.decisions);
    // LOT 1-bis / Story 1.1-bis: a FORGED resume plan is rejected
    // outright — the pending plan must be re-loaded server-side from
    // `agent_runs` by (agentRunId, user_id), never taken from the body.
    if (body.resumeFrom !== undefined && body.resumeFrom.pendingPlan !== undefined) {
      return err(
        "agent/plan_not_accepted",
        "resumeFrom.pendingPlan is not accepted; the pending plan is re-loaded server-side from agent_runs (LOT 1-bis)",
        400,
      );
    }
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      console.warn("[fn-agent-run] SERVICE_ROLE_KEY not configured — cannot enqueue agent job");
      return err("agent/secrets_missing", "Server env not configured", 503);
    }

    // user id from the auth header (never trust the body for identity).
    const authHeader = req.headers.get("Authorization") ?? "";
    const match = /Bearer\s+(.+)/.exec(authHeader);
    if (!match?.[1]) {
      return err("agent/unauthorized", "Bearer token required", 401);
    }
    const userIdRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: {
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${match[1]}`,
      },
    });
    if (!userIdRes.ok) {
      return err("agent/unauthorized", "invalid or expired user token", 401);
    }
    const user = (await userIdRes.json()) as { id?: string };
    const userId = user.id ?? "";

    const agentRunId = ulid();
    // LOT 1-bis / Story 1.2-bis: the Bearer token validated above is
    // NEVER carried into the job payload — only the userId (validated
    // here by /auth/v1/user) is. The dispatcher's agent_run handler
    // carries that userId EXPLICITLY to the kernel run, and the
    // invokeTool seam reaches fn-canvas over the internal channel
    // (x-aurora-internal + x-aurora-user-id). No token is persisted,
    // no module global, no identity leak across concurrent runs.
    const enq = await enqueueAgentRun({ agentRunId, userId, body });
    if (enq === null) {
      return err("agent/enqueue_failed", "could not persist the agent_run job", 503);
    }

    console.log(
      `[fn-agent-run] user=${userId} intent=${body.intent} refs=${(body.contextRefs ?? []).length} ` +
      `profile=${body.taskProfile ? "set" : "default"} -> agentRunId=${agentRunId} ` +
      `jobId=${enq.jobId} agentRunsId=${enq.agentRunsId}`,
    );

    // 202 + the device-facing run handle (AgentRunState follows via the
    // job result / event stream — the device never polls the kernel).
    // traceId = the agent_runs uuid PK the device polls by (F-09).
    return ok({ agentRunId, jobId: enq.jobId, traceId: enq.agentRunsId }, 202);
  } catch (e) {
    console.error("[fn-agent-run] error", e);
    return err("agent/run_error", String(e), 500);
  }
});
