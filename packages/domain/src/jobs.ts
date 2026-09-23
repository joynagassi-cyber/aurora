/**
 * Job system entities (AD-15 SSoT, 01 S5.3).
 * A Job is: persisted (Postgres), identifiable (jobId), idempotent
 * (idempotency key), retryable (bounded exponential backoff, per-kind
 * timeout), observable (job_logs + Sentry + per-kind SLO).
 */

/**
 * The job kind vocabulary — one shared vocabulary in `packages/domain`
 * (AD-15). `workerKind = job_queue.kind` (contract-catalog S7).
 */
export type JobKind =
  | 'ocr'
  | 'transcription'
  | 'artifact_gen'
  | 'fsrs-tick'
  | 'skill_recompute'
  | 'research'
  | 'agent_run'
  | 'verify'
  | 'scientific'
  | 'course_import'
  | 'notification';

export type JobStatus = 'pending' | 'running' | 'done' | 'failed';

export interface JobQueue {
  /** ULID */
  id: string;
  userId: string;
  /** workerKind (01 S5.3) — determines which worker picks it up */
  kind: JobKind;
  status: JobStatus;
  /** attempts made so far */
  attempts: number;
  /** when the job becomes eligible */
  dueAt: string;
  /**
   * idempotency key = kind + hash(logical payload) + user_id
   * (data-event-job-catalog S1). Deduplicates re-dispatches.
   */
  idempotencyKey: string;
  /**
   * G-M4: nullable ULID tying a job back to the local mutation that
   * triggered it (traceability of the upsync origin).
   */
  sourceLocalMutationId?: string;
  /** opaque payload (typed per kind by the worker) */
  payload?: Record<string, unknown>;
  /** when the worker reported its result */
  completedAt?: string;
  updatedAt: string;
}

/** A log line from a job run — feeds Sentry + per-job observability. */
export interface JobLog {
  id: string;
  /** the job this line belongs to */
  jobId: string;
  userId: string;
  level: 'info' | 'warn' | 'error';
  /** free-form / structured message */
  message: string;
  /** structured fields (kind, provider, model, attempt, reason…) */
  fields?: Record<string, unknown>;
  at: string;
}

/** The dispatcher surface (contract-catalog S7). */
export interface DispatcherApi {
  dispatchDue(now: Date, limit?: number): Promise<{ picked: number; skipped: number }>;
  claimJob(
    jobId: string,
    workerKind: JobKind,
  ): Promise<{ ok: boolean; payload?: Record<string, unknown> }>;
  reportResult(jobId: string, result: { status: 'done' | 'failed'; result?: unknown }): Promise<void>;
}
