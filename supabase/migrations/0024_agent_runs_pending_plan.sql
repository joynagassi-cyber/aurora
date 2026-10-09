-- =============================================================================
-- Aurora — Migration 0024: agent_runs.pending_plan (LOT 1-bis / Story 1.1-bis)
--
-- Server-side resume of a stopped agent run (ADR S5 confirmation points,
-- AD-8 idempotent recovery). When a pass halts at a `awaiting-confirmation`
-- step, the pending plan (steps + their statuses) is persisted HERE, on the
-- run's own `agent_runs` row, so a later re-dispatch re-loads the SAME plan
-- server-side (BY agentRunId + user_id) — the client sends only
-- `{ agentRunId, decisions }` and NEVER a plan (a forged client plan would
-- bypass the confirmation points; LOT 1-bis closes that gap).
--
-- ADDITIVE ONLY (01 §2.1 rule: the Aurora schema is additive on the shared
-- instance): one new nullable jsonb column on the existing Aurora-owned
-- table `agent_runs` (0008). No legacy table is touched. No new policy:
-- 0008 already put ENABLE + FORCE ROW LEVEL SECURITY on agent_runs, plus a
-- `agent_runs_user_isolation` (SELECT/INSERT/UPDATE/DELETE, auth.uid() =
-- user_id) and a `agent_runs_service_role` SELECT policy — both already in
-- place. FORCE RLS covers service_role writes through the dispatcher's
-- `agent_runs` patch (AD-1/AD-7). Nothing new to grant.
-- =============================================================================

ALTER TABLE agent_runs
  ADD COLUMN IF NOT EXISTS pending_plan jsonb;

COMMENT ON COLUMN agent_runs.pending_plan IS
  'LOT 1-bis / Story 1.1-bis: the stopped run''s pending plan (Plan jsonb, '
  'see packages/agent/src/types.ts#Plan). Written by the dispatcher''s '
  'persistRun when the terminal AgentRunState carries '
  'status = awaiting-confirmation; read back server-side on resume BY '
  '(agent_runs.id, user_id) — NEVER sourced from the client (forged-plan '
  'gap closed, ADR S5 / AD-8). NULL = no resume pending (a fresh run).';
