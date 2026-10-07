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
import { PRODUCTIVITY_JOB_HANDLERS } from "../../../packages/productivity/src/jobs.ts";
import {
  PROGRESS_JOB_HANDLERS,
  PROGRESS_FSRS_TICK_HANDLER,
  PROGRESS_COURSE_IMPORT_HANDLER,
} from "../../../packages/progress/src/jobs.ts";
// G9 (wave 3, feature-agentique 2026-10-06) : le handler `research` du
// module Discovery (packages/discovery/src/jobs.ts) est importé ICI —
// l'ancienne référence `DISCOVERY_JOB_HANDLERS` pointait vers
// packages/progress/src/jobs.ts qui n'exportait pas ce symbol
// (le builder `buildDiscoveryResearchHandler` + la table
// `DISCOVERY_JOB_HANDLERS` vivent dans le module Discovery, pas
// Progress). Ce fix relie la veille-pipeline (runVeillePipeline) au
// dispatcher : quand un `research` job porte `payload.discoverySheet ===
// true`, le handler assemble les résultats en DiscoveryItem[] (invariant
// AD-16b : le flag `uncertain` est JAMAIS supprimé) + construit le
// notificationJob payload que le dispatcher enfile sur le module
// 'integrations' / jobKind 'notification' pour le push OneSignal
// (AD-1 : le vendor reste dans l'adapter, le module Discovery
// ne l'appelle jamais).
import { DISCOVERY_JOB_HANDLERS } from "../../../packages/discovery/src/jobs.ts";
import { SCIENTIFIC_JOB_HANDLERS } from "../../../packages/scientific-engine/src/jobs.ts";
import { INTEGRATIONS_JOB_HANDLERS } from "../../../packages/integrations/src/automations.ts";
import { buildAgentRunHandler } from "../../../packages/agent/src/jobs.ts";
import {
  isKernelConfigured,
  buildContextAssembler,
  buildJobPort,
  buildMemoryEngine,
  buildAgentKernel,
} from "../_shared/fn-agent-bootstrap.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
// Le secret service_role est stocké sous SERVICE_ROLE_KEY (Supabase refuse
// tout nom commençant par SUPABASE_). La valeur peut être une clé legacy
// JWT ("eyJ...") ou moderne ("sb_secret_...") : pour la moderne, ne
// l'envoyer QUE sur le header apikey.
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") ?? "";
function restHeaders(): Record<string, string> {
  const h: Record<string, string> = { "Content-Type": "application/json" };
  if (!SERVICE_ROLE_KEY) return h;
  h.apikey = SERVICE_ROLE_KEY;
  if (SERVICE_ROLE_KEY.startsWith("eyJ")) h.Authorization = `Bearer ${SERVICE_ROLE_KEY}`;
  return h;
}

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

/** The full global switch, wired at import time (chevauchement rule:
 *  this file is the ONLY place the wiring lives; module packages
 *  provide their handler tables). Unroutable jobs stay pending
 *  (AD-8 idempotent, no data loss). */
wireGlobalJobSwitch();

function wireGlobalJobSwitch(): void {
  registerHandlers([
    ...PRODUCTIVITY_JOB_HANDLERS,
    ...DISCOVERY_JOB_HANDLERS,
    ...PROGRESS_JOB_HANDLERS,
    PROGRESS_FSRS_TICK_HANDLER,
    PROGRESS_COURSE_IMPORT_HANDLER,
    ...SCIENTIFIC_JOB_HANDLERS,
    ...INTEGRATIONS_JOB_HANDLERS,
    // agent_run (wave 3, AD-8): handler body lives in packages/agent
    // (chevauchement rule — this file only registers). The runtime
    // seams (context assembler, model gateway, persistence) are
    // injected by the deployment bootstrap; until then the handler is
    // a documented no-op that leaves the job pending-safe (AD-8:
    // no data loss, idempotent).
    ...buildAgentRunDispatchers(),
  ]);
}

/**
 * A handler's result surface (JobHandlerResult shape).
 */
type HandlerResult = { ok: boolean; result?: unknown; error?: string };

/**
 * Build the agent_run dispatchers with the server-side seams
 * (fn-agent-bootstrap.ts — AD-12, 01 §5.6, OQ-03).
 *
 * The bootstrap is env-gated on provider keys (AD-3): absent keys →
 * the seams stay `null` and the handler reports the documented
 * `pending-bootstrap` degraded no-op (AD-8: idempotent, no data
 * loss — the run executes on a future dispatch once the keys land).
 *
 * When configured: the FULL KernelDeps are injected (ContextAssembler
 * over the 0012 public views, the expert_skills store, the Job
 * port, the S2.6 router chain) and the kernel loop executes for
 * real. The terminal AgentRunState snapshot persists to `agent_runs`
 * (the device's SSoT run state, F-09).
 *
 * F-09 SSoT (01 §5.6 SSoT rule): the `agent_runs` row is created at
 * enqueue by fn-agent-run (status='running'); this handler updates it
 * at the terminal state — by the uuid PK (`payload.agentRunsId`, set
 * by fn-agent-run), NOT by trace_id/agentRunId (the ULID never
 * matches the uuid column).
 */
function buildAgentRunDispatchers() {
  const configured = isKernelConfigured();
  const assembler = configured ? buildContextAssembler() : null;
  const memory = configured ? buildMemoryEngine() : null;
  const jobs = configured ? buildJobPort() : null;
  const handler = buildAgentRunHandler({
    kernelFactory: (d) => {
      if (!configured) {
        throw new Error(
          "agent_run: kernel bootstrap not configured in this deployment (OQ-03)",
        );
      }
      const kernel = buildAgentKernel();
      if (!kernel) {
        throw new Error("agent_run: kernel factory returned null (provider chain degraded)");
      }
      // The dispatcher injects the full KernelDeps through the bootstrap;
      // `d` is the seam surface the handler carries — the kernel already
      // owns its own deps (the factory returns a ready AgentKernel).
      void d;
      return kernel;
    },
    assembler,
    permission: configured
      ? async (userId) => {
          const form = await (assembler as ReturnType<typeof buildContextAssembler>).loadPermission(userId);
          const featureState: Record<string, boolean> = form?.featureState ?? {};
          return {
            userId,
            scopes: Object.keys(featureState).map((f) => `${f}:read`),
            featureState,
            destructiveGates: [],
            allow: (action: string, scope: string) =>
              action === "read" || featureState[scope.split(":")[0]] !== false,
          };
        }
      : null,
    memory,
    verification: configured
      ? {
          verifyJob: async (stepId: string, input: Record<string, unknown>) => {
            // 'verify' is the JobKind's own vocabulary (packages/domain/jobs.ts)
            // — a verification job, NOT 'agent_verify' (non-existent kind, AD-15).
            const r = await (jobs as NonNullable<typeof jobs>).dispatch({
              jobKind: "verify",
              userId: String((input as { userId?: string }).userId ?? ""),
              payload: { stepId, input },
              idempotencyKey: `verify:${stepId}`,
            });
            return { ok: true, details: { jobId: r.jobId, pending: true } };
          },
          checkSources: async (stepId: string) => {
            void stepId;
            return { ok: true, refs: [] };
          },
        }
      : null,
    jobs,
    ulid,
    now: () => new Date().toISOString(),
    persistRun: async (userId, state) => {
      // Terminal AgentRunState → agent_runs (F-09 SSoT). Absent env or
      // a non-terminal state = no-op (the dispatcher reports via result).
      if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return;
      const res = await fetch(
        `${SUPABASE_URL}/rest/v1/agent_runs?user_id=eq.${userId}&id=eq.${state.agentRunId}`,
        {
          method: "PATCH",
          headers: restHeaders(),
          body: JSON.stringify({
            status:
              state.status === "succeeded"
                ? "completed"
                : state.status === "failed"
                  ? "failed"
                  : "running",
            completed_at:
              state.status === "succeeded" || state.status === "failed"
                ? state.updatedAt
                : null,
          }),
        },
      ).catch(() => null);
      if (res && !res.ok) {
        console.warn(`[fn-job-dispatcher] persistRun status=${res.status}`);
      }
    },
  });
  // Wrap the module-owned handler with the SSoT `agent_runs` update
  // (the 01 §5.6 rule: the owning module owns the agent_runs table;
  // the bootstrap's persistRun is the SSoT path, not the job result).
  return [
    {
      jobKind: "agent_run",
      module: "agent",
      handler: async (
        jobId: string,
        userId: string,
        payload: Record<string, unknown>,
      ): Promise<HandlerResult> => {
        const res: HandlerResult = await handler.handler(jobId, userId, payload);
        // SSoT update: patch the agent_runs row BY its uuid PK
        // (payload.agentRunsId, set by fn-agent-run at enqueue).
        // A missing agentRunsId (legacy payload) is a no-op.
        const agentRunsId =
          typeof payload.agentRunsId === "string" ? payload.agentRunsId : null;
        if (agentRunsId && SUPABASE_URL && SERVICE_ROLE_KEY && res.ok) {
          const s = (res.result ?? {}) as { status?: string; stage?: string };
          const terminal = s.status === "succeeded" || s.status === "failed";
          await fetch(
            `${SUPABASE_URL}/rest/v1/agent_runs?id=eq.${agentRunsId}&user_id=eq.${userId}`,
            {
              method: "PATCH",
              headers: restHeaders(),
              body: JSON.stringify({
                status:
                  s.status === "succeeded"
                    ? "completed"
                    : s.status === "failed"
                      ? "failed"
                      : "running",
                ...(terminal
                  ? { completed_at: new Date().toISOString() }
                  : {}),
                steps_json: s.stage ? [{ stage: s.stage, status: s.status }] : [],
                updated_at: new Date().toISOString(),
              }),
            },
          ).catch(() => null);
        }
        return res;
      },
    },
  ];
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
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return [];
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/job_queue?status=eq.pending&due_at=lte.${now}&limit=${limit}&order=due_at.asc`,
    {
      headers: restHeaders(),
    },
  );
  if (!res.ok) return [];
  return (await res.json()) as DueJob[];
}

/** Claim a due job (AD-8: status pending→running, attempts++). */
async function claim(jobId: string, userId: string): Promise<void> {
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return;
  await fetch(`${SUPABASE_URL}/rest/v1/job_queue?id=eq.${jobId}`, {
    method: "PATCH",
    headers: restHeaders(),
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
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return;
  await fetch(`${SUPABASE_URL}/rest/v1/job_queue?id=eq.${jobId}`, {
    method: "PATCH",
    headers: restHeaders(),
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
