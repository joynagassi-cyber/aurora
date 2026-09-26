/**
 * error-recovery.ts — the 10 error classes E1..E10
 * (docs/agent/error-recovery.md, master mission S64).
 *
 * Each class pins the four recovery questions (kernel S12 convention):
 *   what happened / what was executed / what was not executed /
 *   what can be retried / what needs confirmation.
 *
 * Deterministic data, not prose: the Execution Engine (kernel S12) and the
 * E2E failure paths replay these. "Executed" = durable side effects;
 * "Retryable" = re-runnable under the same AD-8 idempotency key.
 */
import type { ErrorClass, ErrorClassId } from './types.ts';

export const E1: ErrorClass = {
  id: 'E1',
  title: 'Provider error (AI call fails)',
  whatHappened:
    'AIProvider.complete() returned 5xx / timeout / connection refused from one or more providers in the fallback chain.',
  executed:
    'the call attempt(s) up to the last provider tried; AIResponseEnvelope recorded for each attempt (AD-5 traceability)',
  notExecuted: 'the dependent step (e.g., sheet generation, QCM generation, explanation)',
  retryable:
    'transient errors (5xx, timeout) -> bounded retry (3x, exponential backoff) on the same provider; then next fallback provider. 429 -> respect retry-after, never key-rotate (AD-5)',
  needsConfirmation: false,
  recovery:
    'persisted step state in job_queue (AD-8); resume from the failed step; if all providers exhausted, expectedQuality: degraded is surfaced in AgentRunState (no silent acceptance, kernel S12)',
};

export const E2: ErrorClass = {
  id: 'E2',
  title: 'Permission error (insufficient scope / platform permission)',
  whatHappened:
    'a tool call required a permission the user has not granted (POST_NOTIFICATIONS refused, DPC not provisioned, Composio tool requires unconnected OAuth)',
  executed: 'the permission check (read) completed; no write occurred',
  notExecuted: 'the dependent action (notification delivery, package suspension, external tool call)',
  retryable:
    'yes, after the user grants the permission / connects the account; the Agent pauses at this step, shows the required action in AgentRunState, and resumes on success',
  needsConfirmation: true,
  recovery:
    'granting a new permission / connecting a new account = user-initiated (the Agent asks, never auto-grants); on revocation mid-session the kernel detects the state change and degrades to the fallback profile',
};

export const E3: ErrorClass = {
  id: 'E3',
  title: 'Network error (offline / connectivity loss)',
  whatHappened:
    'NetworkStatusAdapter reports offline; server calls (AI, R2, Composio, Supabase upsync) fail with network errors',
  executed:
    'all local operations (SQLite reads/writes, in-app timer, local notifications) completed; offline-capable features continue normally',
  notExecuted: 'all online-required operations (AI generation, R2 upload, external tool calls, server retrieval)',
  retryable:
    'on network restore the upsync queue (03 S5) retries pending local mutations; online-required agent steps queued as "pending network" are rescheduled by the Planner',
  needsConfirmation: false,
  recovery:
    'the plan persisted step state (AD-8) records which steps completed locally vs pending network; on restore the Execution Engine resumes from the first pending step; if the user cancels offline, compensating actions run on the locally completed steps',
};

export const E4: ErrorClass = {
  id: 'E4',
  title: 'Auth expired (Supabase session / OneSignal / Composio)',
  whatHappened:
    'the Supabase JWT expires mid-session, or a Composio connected-account token is reauth_required',
  executed: 'all operations that completed before expiry are durable',
  notExecuted: 'all subsequent server calls fail with 401',
  retryable:
    'yes, after re-auth; the Supabase SDK auto-refreshes the JWT (02 S3.1) — if the refresh fails (account locked / deleted) the UI shows a re-login state; Composio uses its reauth flow (composio.md S4)',
  needsConfirmation: true,
  recovery:
    're-login = user action; the Agent pauses, not a silent failure; on re-auth the upsync queue resumes and in-flight jobs that lost their auth mid-execution are re-dispatched (idempotency key, AD-8)',
};

export const E5: ErrorClass = {
  id: 'E5',
  title: 'Feature disabled (registry state change mid-session)',
  whatHappened:
    'the user (or a mode switch) disables a feature the current plan depends on (e.g., Focus disabled while a focus session is in the plan)',
  executed: 'steps before the disable are complete',
  notExecuted: 'steps that require the disabled feature',
  retryable:
    'yes, if the feature is re-enabled before those steps run; the Planner marks the dependent steps as blocked(feature_disabled)',
  needsConfirmation: true,
  recovery:
    'the plan persists; on re-enable the blocked steps unblock; if the user does not re-enable, the plan is marked incomplete with the reason (no silent drop)',
};

export const E6: ErrorClass = {
  id: 'E6',
  title: 'Tool unavailable (Composio tool / OCR / Transcription absent)',
  whatHappened:
    'an optional capability is not available (provider absent AD-1, Composio app not connected, OCR/STT provider not configured)',
  executed: 'the availability check completed; the degradation path was selected',
  notExecuted: 'the tool-specific step',
  retryable:
    'yes, when the provider/account becomes available; the step is marked degraded in the result',
  needsConfirmation: false,
  recovery:
    'degradation is automatic (AD-1: the product keeps working); the user is informed of the reduced quality/capability and can later manually re-trigger the degraded step (e.g., "re-run OCR on this document")',
};

export const E7: ErrorClass = {
  id: 'E7',
  title: 'Invalid input (user data / AI output does not match schema)',
  whatHappened:
    "a tool call's input or an AI response does not match the declared inputSchema / outputSchema (kernel S14)",
  executed: 'the call was attempted; validation failed before execution (input) or after (output)',
  notExecuted: 'the dependent step',
  retryable:
    'input errors: the Agent asks the user for the missing/corrected parameter (disambiguation, kernel S13); output errors: the step is re-run with a tighter prompt constraint; if the second attempt also fails the step is marked failed and the plan continues with the remaining steps (graceful degradation)',
  needsConfirmation: false,
  recovery:
    'the failed step compensates (e.g., a partially created task is deleted); the Agent handles it within its loop',
};

export const E8: ErrorClass = {
  id: 'E8',
  title: 'Conflicting data (CRDT collision / optimistic update rejected)',
  whatHappened:
    'a local mutation upsyncs to Supabase but the server row has a newer updated_at (03 S5.1: server-wins), or an OR-Set CRDT merge produces a conflict state (03 S5.2)',
  executed: 'the local write (SQLite) completed; the upsync was rejected',
  notExecuted: 'the server-side effect',
  retryable:
    'the upsync queue retries with the latest server state (re-merge); if the conflict is un-mergeable (different terminal states) SyncStatus = conflict and the UI shows a conflict-resolution surface',
  needsConfirmation: true,
  recovery:
    'an un-mergeable conflict is resolved by the user (Confirmation Engine + UI); after resolution the upsync completes and the local state is reconciled with the server state',
};

export const E9: ErrorClass = {
  id: 'E9',
  title: 'Partial execution (multi-step plan, some steps done)',
  whatHappened: 'a 5-step plan completed steps 1-3; step 4 failed (any of E1-E8); step 5 not started',
  executed: 'steps 1-3 (durable: Postgres writes, R2 uploads, system state changes)',
  notExecuted: 'steps 4-5',
  retryable:
    'step 4 is retried (idempotency key per step, AD-8); step 5 is re-evaluated after step 4 succeeds; if step 4 is important/irreversible (ADR S5) re-execution requires confirmation; if step 3 created a side effect that step 4 would invalidate, the compensating action for step 3 runs first (rollback)',
  needsConfirmation: true,
  recovery:
    "the plan persisted state (job_queue + step records) records the exact completion boundary; the Execution Engine resumes from step 4; the user sees a plan summary in AgentRunState: \"3/5 done, step 4 failed: <reason>. Retry step 4?\"",
};

export const E10: ErrorClass = {
  id: 'E10',
  title: 'Destructive action confirmed then fails',
  whatHappened:
    'the user confirmed a destructive action (e.g., delete a project, which cascades to tasks / events / evidence); the deletion began (Postgres transaction) but a constraint violation or foreign-key error aborted the transaction',
  executed: 'the transaction was rolled back (Postgres ACID); no partial deletion persisted',
  notExecuted: 'the entire destructive operation',
  retryable:
    'yes, after the constraint issue is resolved (e.g., the user manually removes the blocking reference first); the Agent reports the specific constraint error',
  needsConfirmation: true,
  recovery:
    're-execution of a destructive action always requires re-confirmation (ADR S5: irreversible = confirm every time; the previous confirmation is voided by the failure); the user can retry after fixing the constraint or abort the plan; non-reversible pre-step compensations are flagged for manual review',
};

/** All 10 error classes (E1..E10). */
export const ERROR_CLASSES: readonly ErrorClass[] = [
  E1, E2, E3, E4, E5, E6, E7, E8, E9, E10,
];

export const ERROR_CLASS_IDS: readonly ErrorClassId[] = ERROR_CLASSES.map((e) => e.id);

export function errorClassById(id: ErrorClassId): ErrorClass | undefined {
  return ERROR_CLASSES.find((e) => e.id === id);
}
