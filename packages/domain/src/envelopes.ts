/**
 * Envelopes & shared types (contract-catalog S1, 01 S3.1).
 * SSoT `packages/domain`, owner Foundation.
 */

/** 01 S3.1 — generic API envelope. `ApiError.code` is module-prefixed,
 * e.g. "productivity/task_not_found". */
export type ApiEnvelope<T> = { ok: true; data: T } | { ok: false; error: ApiError };

export type ApiError = {
  code: string;
  message: string;
  details?: Record<string, unknown>;
};

/** ADR v1.7 S9 / 01 S3.1 — normalized AI response envelope.
 * Every fallback is traceable (AD-5): provider, model, attempt, reason,
 * expected quality. `traceId` correlates the server-side run.
 * `T` is the shape of the model's returned data. */
export type AIResponseEnvelope<T = unknown> = {
  provider: string;
  model: string;
  attempt: number;
  reason: 'primary' | 'fallback' | 'last_resort';
  expectedQuality: 'full' | 'degraded';
  fallbackUsed: boolean;
  traceId: string;
  data: T;
};

/** G-M3/C-3: shape was in 02 S10 body; now pinned in `packages/domain`.
 * `AppErrorCode` is module-prefixed ("productivity/task_not_found"). */
export type AppErrorCode = string;

export type AppError = {
  code: AppErrorCode;
  message: string;
  /** present when the error maps to a 5th UX state = offline (03 S3.2) */
  offline?: boolean;
  retryable?: boolean;
  details?: Record<string, unknown>;
};

/** 01 S3.1 / 03 S3.2 — heavy capabilities expose the 5 canonical UX states
 * (AD-13): loading, empty, success, error, offline. */
export type AsyncState<T> =
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: AppError }
  | { status: 'offline' };
