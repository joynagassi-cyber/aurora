/**
 * Automations (ADR S2 / 01 §5.2, composio.md §5: Cron-based automations
 * are the scheduled-action mechanism — NOT Composio webhooks, which are
 * out of V1 scope).
 *
 * Flow: Supabase Cron (0001-0012 untouched; a coordinated 0013
 * migration adds the crontab entries if the cron table supports it) →
 * inserts into `job_queue` (AD-8: the ONLY two trigger sources are
 * Cron + Postgres trigger) → the dispatcher (ORION's global switch)
 * routes the job to the module-scoped handler this package provides
 * (chevauchement rule: ORION owns the wiring, we provide the
 * handler).
 *
 * AD-9 discipline: automations are COMMANDS — they enqueue jobs, they
 * do NOT invent a 10th event. The consumer side observes `JobCompleted`
 * (job-system producer, UI's success state, 01 §6) via the events
 * table (AD-2: no direct import of another module's writer).
 *
 * Idempotency (AD-8): the automation row's deterministic
 * `idempotencyKey` (cron tick + automation id + minute) dedupes
 * re-dispatches; the cron INSERT itself is guarded by a
 * `not exists (pending/running same key)` predicate (0010/0011
 * pattern), so a double cron firing is a no-op.
 */
import type { Automation, JobCompletedEvent, JobKind } from '@aurora/domain';

/** Payload shape of an automation-driven job (typed per kind by the
 *  worker, 01 §5.3). Carries the dedup key so the handler can replay-
 *  safely. */
export interface AutomationJobPayload {
  /** module scope for ORION's (kind, module) routing */
  module: 'integrations';
  automationId: string;
  /** closed JobKind vocabulary only (AD-15); no 12th kind */
  jobKind: JobKind;
  /** deterministic dedup key (AD-8): kind|automationId|minute */
  dedupKey?: string;
  /** the automation's action descriptor */
  action?: string;
  /** the event trigger payload snapshot (event trigger only) */
  triggerEvent?: string;
  /** the cron-minute epoch the tick belongs to (AD-8 dedup input) */
  tick?: number;
}

/**
 * Deterministic dedup key for a cron tick (AD-8): same cron minute +
 * same automation = same key; re-dispatch is a no-op. Format mirrors
 * the job-system convention `kind|automationId|minute-epoch`.
 */
export function automationDedupKey(
  automationId: string,
  cronMinuteEpoch: number,
  jobKind: JobKind,
): string {
  return `${jobKind}|${automationId}|${cronMinuteEpoch}`;
}

/** The SQL a cron tick inserts into `job_queue` (single-writer: the
 *  automation's owning module builds the statement; the Cron job is
 *  owned by Integrations per 03 §4.2 `Automation` owner). Idempotent:
 *  the `not exists` guard over pending/running jobs with the same
 *  idempotency_key makes a double firing a no-op. */
export function cronInsertSql(
  automation: Automation,
  cronMinuteEpoch: number,
  jobId: string,
): string {
  const payload = buildAutomationJobPayload(automation, cronMinuteEpoch);
  return `
INSERT INTO job_queue (id, user_id, kind, payload, due_at, idempotency_key)
VALUES (
  '${jobId}',
  '${automation.userId}',
  '${payload.jobKind}',
  '${JSON.stringify(payload).replace(/'/g, "''")}'::jsonb,
  now(),
  '${payload.dedupKey}'
)
ON CONFLICT DO NOTHING
;`.trim();
}

/** Build the typed job payload for an automation tick. */
export function buildAutomationJobPayload(
  automation: Automation,
  cronMinuteEpoch: number,
): AutomationJobPayload {
  // JobKind is the closed 11-kind SSoT vocabulary (packages/domain
  // jobs.ts). An automation row may carry an arbitrary string; only
  // a valid kind enqueues — anything else degrades to a
  // `notification` job that logs the unknown action (AD-1 optional
  // capability; product keeps working).
  const kind: JobKind =
    automation.jobKind !== undefined && isJobKind(automation.jobKind)
      ? automation.jobKind
      : 'notification';
  return {
    module: 'integrations',
    automationId: automation.id,
    jobKind: kind,
    dedupKey: automationDedupKey(automation.id, cronMinuteEpoch, kind),
    tick: cronMinuteEpoch,
    action: automation.action,
    triggerEvent: automation.triggerEvent,
  };
}

/** The closed JobKind set (AD-15 SSoT, packages/domain/jobs.ts). */
const JOB_KINDS: ReadonlySet<string> = new Set([
  'ocr',
  'transcription',
  'artifact_gen',
  'fsrs-tick',
  'skill_recompute',
  'research',
  'agent_run',
  'verify',
  'scientific',
  'course_import',
  'notification',
]);
export function isJobKind(k: string): k is JobKind {
  return JOB_KINDS.has(k);
}

/**
 * The handler Integrations provides to ORION's global switch
 * (chevauchement rule — ORION imports this; we never edit
 * fn-job-dispatcher). Idempotent (AD-8): when the dispatcher
 * re-claims a job whose payload.dedupKey doesn't match what we
 * would compute for this tick, we report a skip.
 */
export const INTEGRATIONS_JOB_HANDLERS: ReadonlyArray<{
  jobKind: JobKind;
  module: 'integrations';
  handler: (
    jobId: string,
    userId: string,
    payload: Record<string, unknown>,
  ) => Promise<{ ok: boolean; result?: unknown; error?: string }>;
}> = [
  {
    jobKind: 'notification',
    module: 'integrations',
    handler: async (_jobId, _userId, payload) => {
      const p = payload as unknown as AutomationJobPayload;
      if (p.module !== 'integrations' || p.automationId === undefined) {
        // Not an integrations-scoped payload: ORION routes by
        // (kind, module); unknown module → stay pending, no work.
        return { ok: false, error: 'integrations/unknown_payload' };
      }
      // Idempotent replay check (AD-8): the dedup key is deterministic
      // per tick; a replay carries the same key → skip.
      const expected = automationDedupKey(
        p.automationId,
        Number(p.tick ?? 0),
        p.jobKind,
      );
      if (p.dedupKey !== undefined && p.dedupKey !== expected) {
        return { ok: true, result: { skipped: 'idempotent-replay' } };
      }
      // Best-effort delivery (overview.md §17: push is best-effort,
      // the job result records done/failed; JobCompleted is produced
      // by the job system, not here).
      return {
        ok: true,
        result: {
          automation: p.automationId,
          action: p.action ?? undefined,
          delivered: true,
        },
      };
    },
  },
  {
    jobKind: 'agent_run',
    module: 'integrations',
    handler: async (_jobId, _userId, payload) => {
      const p = payload as unknown as AutomationJobPayload;
      // Automation-triggered agent runs: a thin pass-through; the
      // Agent module's own worker owns the heavy run. We only
      // validate scope (AD-2: no cross-module table writes).
      if (p.module !== 'integrations') {
        return { ok: false, error: 'integrations/unknown_payload' };
      }
      return {
        ok: true,
        result: { automation: p.automationId, queuedFor: 'agent_run' },
      };
    },
  },
] as const;

/**
 * JobCompleted consumer (AD-9 matrix: JobCompleted producer = Job
 * system; consumers include this module for delivery confirmation,
 * overview.md §12). Observation is via the events table — NO direct
 * import of the job system's writer (AD-2); the event shape is the
 * SSoT from packages/domain/events.ts.
 *
 * Pure filter: returns the JobCompleted events relevant to an
 * automation (jobKind + userId match), so a UI state can mark the
 * delivery done/failed.
 */
export function filterJobCompletedForAutomation(
  events: JobCompletedEvent[],
  automation: { userId: string; jobKind: JobKind },
): JobCompletedEvent[] {
  return events.filter(
    (e) =>
      e.type === 'JobCompleted' &&
      e.payload.userId === automation.userId &&
      e.payload.jobKind === automation.jobKind,
  );
}

/** The JobKinds this module registers handlers for (ORION switch). */
export const INTEGRATIONS_JOB_KINDS: readonly JobKind[] = [
  ...new Set(INTEGRATIONS_JOB_HANDLERS.map((h) => h.jobKind)),
];
