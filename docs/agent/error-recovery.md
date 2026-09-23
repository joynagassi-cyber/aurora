# Error & Recovery Specification (master mission S64)

10 error classes, each with: what happened / what was executed / what was
not executed / what can be retried / what needs confirmation.
Authority: kernel S12 (Error Recovery component), AD-5 (retry vs fallback),
AD-8 (job idempotency), 01 S6 (AI data-policy guard), 04 S7 (platform errors).

## Convention

- "Executed" = the step completed and its side effects are durable
  (persisted to Postgres / R2 / system state).
- "Not executed" = the step was not started or was rolled back.
- "Retryable" = the step can be re-run with the same idempotency key
  (AD-8) without duplicate side effects.
- "Needs confirmation" = the step is important/irreversible (ADR S5) or
  destructive (Permission Engine classification, kernel S12).

---

## E1. Provider error (AI call fails)

- **What happened:** `AIProvider.complete()` returned 5xx / timeout /
  connection refused from one or more providers in the fallback chain.
- **Executed:** the call attempt(s) up to the last provider tried;
  `AIResponseEnvelope` recorded for each attempt (AD-5 traceability).
- **Not executed:** the dependent step (e.g., sheet generation, QCM
  generation, explanation).
- **Retryable:** transient errors (5xx, timeout) -> bounded retry (3x,
  exponential backoff) on the same provider; then next fallback provider.
  429 -> respect `retry-after`, never key-rotate (AD-5).
- **Needs confirmation:** no (the fallback is automatic within the same
  task profile). If all providers exhausted: `expectedQuality: 'degraded'`,
  user informed via `AgentRunState`; no silent acceptance (kernel S12).
- **Recovery:** persisted step state in `job_queue` (AD-8); resume from
  the failed step. If the job was interrupted mid-AI-call, the step is
  re-dispatched (idempotency key prevents duplicate side effects).

## E2. Permission error (insufficient scope / platform permission)

- **What happened:** a tool call required a permission the user has not
  granted (e.g., `POST_NOTIFICATIONS` refused, DPC not provisioned,
  Composio tool requires OAuth not connected).
- **Executed:** the permission check (read) completed; no write occurred.
- **Not executed:** the dependent action (e.g., notification delivery,
  package suspension, external tool call).
- **Retryable:** yes, after the user grants the permission / connects the
  account. The Agent pauses at this step, shows the required action in
  `AgentRunState`, and resumes on success.
- **Needs confirmation:** granting a new permission / connecting a new
  account = user-initiated (the Agent asks, never auto-grants).
- **Recovery:** on permission revoked mid-session (e.g., user revokes
  DPC): the kernel detects the state change on the next step; the session
  degrades to the fallback profile (focus: DPC -> restriction mode).

## E3. Network error (offline / connectivity loss)

- **What happened:** `NetworkStatusAdapter` reports offline; server calls
  (AI, R2, Composio, Supabase upsync) fail with network errors.
- **Executed:** all local operations (SQLite reads/writes, in-app timer,
  local notifications) completed; the offline-capable features continue
  normally.
- **Not executed:** all online-required operations (AI generation,
  R2 upload, external tool calls, server retrieval).
- **Retryable:** on network restore, the upsync queue (03 S5) retries
  pending local mutations. Online-required agent steps are queued as
  "pending network" in the plan; the Planner reschedules them when
  connectivity returns.
- **Needs confirmation:** no (automatic retry). If the user cancels the
  plan while offline, the compensating actions run on the steps that
  completed locally.
- **Recovery:** the plan's persisted step state (AD-8) records which steps
  completed locally vs. which are pending network. On restore, the
  Execution Engine resumes from the first pending step.

## E4. Auth expired (Supabase session / OneSignal / Composio)

- **What happened:** the Supabase JWT expires mid-session; or a Composio
  connected-account token is `reauth_required`.
- **Executed:** all operations that completed before expiry are durable.
- **Not executed:** all subsequent server calls fail with 401.
- **Retryable:** yes, after re-auth. The Supabase SDK auto-refreshes the
  JWT (02 S3.1); if the refresh fails (user account locked / deleted),
  the UI shows a "re-login" state (02 S7 `error` variant). Composio:
  reauth flow (composio.md S4).
- **Needs confirmation:** re-login = user action; the Agent pauses, not
  a silent failure.
- **Recovery:** on re-auth, the upsync queue resumes; pending agent steps
  retry. In-flight jobs (AD-8) that lost their Supabase auth mid-execution
  are re-dispatched (idempotency key).

## E5. Feature disabled (registry state change mid-session)

- **What happened:** the user (or a mode switch) disables a feature that
  the current plan depends on (e.g., "Focus" disabled while a focus
  session is in the plan).
- **Executed:** steps before the disable are complete.
- **Not executed:** steps that require the disabled feature.
- **Retryable:** yes, if the feature is re-enabled before those steps run.
  The Planner marks the dependent steps as `blocked(feature_disabled)`.
- **Needs confirmation:** re-enabling the feature = user action.
- **Recovery:** the plan persists; on re-enable, the blocked steps
  unblock. If the user does not re-enable, the plan is marked
  `incomplete` with the reason; no silent drop.

## E6. Tool unavailable (Composio tool / OCR / Transcription absent)

- **What happened:** an optional capability is not available (provider
  absent, AD-1 last paragraph; Composio app not connected; OCR/STT
  provider not configured).
- **Executed:** the availability check completed; the degradation path
  was selected.
- **Not executed:** the tool-specific step.
- **Retryable:** yes, when the provider/account becomes available. The
  step is marked `degraded` in the result.
- **Needs confirmation:** no (degradation is automatic, AD-1: the product
  keeps working). The user is informed of the reduced quality / capability.
- **Recovery:** if the provider is later enabled, the user can manually
  trigger the degraded step (e.g., "re-run OCR on this document").

## E7. Invalid input (user data / AI output does not match schema)

- **What happened:** a tool call's input or an AI response does not match
  the declared `inputSchema` / `outputSchema` (kernel S14).
- **Executed:** the call was attempted; the validation failed before
  execution (input) or after (output).
- **Not executed:** the dependent step.
- **Retryable:** input errors: the Agent asks the user for the missing /
  corrected parameter (disambiguation, kernel S13). Output errors: the
  step is re-run with a tighter prompt constraint; if the second attempt
  also fails, the step is marked `failed` and the plan continues with the
  remaining steps (graceful degradation).
- **Needs confirmation:** no (the Agent handles it within its loop).
- **Recovery:** the failed step's compensating action runs (e.g., a
  partially created task is deleted).

## E8. Conflicting data (CRDT collision / optimistic update rejected)

- **What happened:** a local mutation upsyncs to Supabase but the server
  row has a newer `updated_at` (03 S5.1: server-wins) or an OR-Set CRDT
  merge produces a conflict state (03 S5.2).
- **Executed:** the local write (SQLite) completed; the upsync was
  rejected.
- **Not executed:** the server-side effect.
- **Retryable:** the upsync queue retries with the latest server state
  (re-merge). If the conflict is un-mergeable (03 S5.2: different
  terminal states), the `SyncStatus` = `conflict`; the UI shows a
  conflict-resolution surface (user picks a side).
- **Needs confirmation:** un-mergeable conflict = user resolves
  (Confirmation Engine + UI).
- **Recovery:** after resolution, the upsync completes; the local state
  is reconciled with the server state.

## E9. Partial execution (multi-step plan, some steps done)

- **What happened:** a 5-step plan completed steps 1-3; step 4 failed
  (any of E1-E8); step 5 not started.
- **Executed:** steps 1-3 (durable: Postgres writes, R2 uploads,
  system state changes).
- **Not executed:** steps 4-5.
- **Retryable:** step 4 is retried (idempotency key per step, AD-8).
  Step 5 is re-evaluated after step 4 succeeds.
- **Needs confirmation:** if step 4 is important/irreversible (ADR S5),
  re-execution requires confirmation. If step 3 created a side effect
  that step 4 would invalidate, the compensating action for step 3 runs
  first (rollback).
- **Recovery:** the plan's persisted state (job_queue + step records)
  records the exact completion boundary; the Execution Engine resumes
  from step 4. The user sees a plan summary in `AgentRunState`:
  "3/5 done, step 4 failed: <reason>. Retry step 4?"

## E10. Destructive action confirmed then fails

- **What happened:** the user confirmed a destructive action (e.g.,
  delete a project, which cascades to tasks / events / evidence); the
  deletion began (Postgres transaction) but a constraint violation or
  a foreign-key error aborted the transaction.
- **Executed:** the transaction was rolled back (Postgres ACID); no
  partial deletion persisted.
- **Not executed:** the entire destructive operation.
- **Retryable:** yes, after the constraint issue is resolved (e.g., the
  user manually removes the blocking reference first). The Agent reports
  the specific constraint error.
- **Needs confirmation:** re-execution of a destructive action always
  requires re-confirmation (ADR S5: irreversible = confirm every time;
  the previous confirmation is voided by the failure).
- **Recovery:** the user can retry the deletion after fixing the
  constraint, or abort the plan. The plan's step state records the
  failure; the compensating action for any pre-steps that were
  non-reversible (rare) is flagged for manual review.
