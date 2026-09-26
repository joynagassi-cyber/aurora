-- =============================================================================
-- Aurora Wave 3 — Migration 0017: user_goals (Progress-owned GoalProject)
-- (dynamic-goal-engine.md "Data model (additive, AD-15)")
--
-- GoalProject is what the AGENT creates/mutates when decomposing an NL goal.
-- The `user_needs` entity from need-driven-features.md v1 is REPLACED by
-- GoalProject (dynamic, agent-created — NOT a fixed category).
--
-- Ownership (AD-7 / AD-6): Progress owns `user_goals` rows (Progress owns
-- progress data); the Agent (server) CREATES / COMPOSES the content via
-- @aurora/goal-engine (pure composition logic, never writes a module table
-- directly — AD-7 single-writer: the agent emits the command, Progress
-- applies + persists). GoalProgress rows + ProgressEvidence are
-- Progress's F-07 sole-producer territory (the agent only READS them).
--
-- Mirrored locally: YES (goal-dashboard-ui.md S8: "GoalProject + subGoals
-- + progress are in local mirror (PowerSync, 03 S4.2). The dashboard
-- renders offline"). The composition data (features/timeline) travels in
-- the same JSONB column — the whole GoalProject document is one row.
--
-- ADDITIF : ne modifie aucune table existante ; idempotent IF NOT
-- EXISTS. Un scope = un seul module owner (Progress) ; les lectures
-- inter-modules passent par la vue publique v_goal_project_public.

-- ============================================================================
-- Single-writer (AD-7): only Progress writes user_goals. RLS user
-- isolation (0005 pattern) + service_role write for the Progress module
-- (agent commands are applied server-side by Progress, NOT BYPASSRLS).
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_goals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  -- GoalProject document (dynamic-goal-engine.md): objective, successCriteria,
  -- targetDate, horizon, subGoals[], features[], timeline[], progress, status.
  -- The whole composition travels as JSONB (one document per goal row) —
  -- the schema mirrors the frozen AD-15 `GoalProject` type (packages/domain
  -- entities-goal.ts).
  goal        jsonb NOT NULL,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Index by user (all reads are user-scoped).
CREATE INDEX IF NOT EXISTS idx_user_goals_user ON user_goals (user_id);

-- RLS: users read their own rows; appends happen via service_role
-- (Progress module, server-side). Bound by user_id — no BYPASSRLS (01 S2.2).
ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_goals FORCE ROW LEVEL SECURITY;

CREATE POLICY user_goals_user_isolation ON user_goals
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- service_role: the Progress module applies agent goal.* commands
-- (goal.create/status/recompose/pause/complete/abandon/feature.add/remove).
-- JUSTIFICATION: writes are scoped to the user the job runs for (AD-7:
-- service write for user A can never touch user B's rows).
CREATE POLICY user_goals_service_role ON user_goals
  FOR ALL TO service_role USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE TRIGGER user_goals_updated BEFORE UPDATE ON user_goals
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- Cross-module read surface (AD-2): the GoalProject entity is Progress-owned
-- (data) + Agent-owned (creation/composition logic). Other modules READ the
-- composition via the public view — they NEVER write user_goals.
--
-- SECURITY INVOKER (01 §3.4, AD-7/F-03): the view inherits the CALLER's RLS
-- policies, so a service_role reader is still bound by user_id-scoped policy
-- (the view does NOT bypass RLS). Default view = SECURITY DEFINER (bypasses
-- RLS) — must be explicit (01 §2.2 rule 1: FORCE RLS on every business table,
-- the relay goes THROUGH the policies, never BYPASSRLS).
-- =============================================================================
CREATE OR REPLACE VIEW v_goal_project_public WITH (security_invoker = on) AS
SELECT
  id,
  user_id,
  goal,
  -- denormalized for cheap cross-module queries
  goal->>'objective' AS objective,
  goal->>'successCriteria' AS success_criteria,
  goal->>'horizon' AS horizon,
  goal->>'status' AS status,
  (goal->'progress'->>'overallPct')::int AS overall_pct,
  created_at,
  updated_at
FROM user_goals;

-- service_role (relay) may read the public view; RLS bounds the rows.
GRANT SELECT ON v_goal_project_public TO service_role;

-- =============================================================================
-- PowerSync relay-scoped view (goal-dashboard-ui.md S8: "The dashboard
-- renders offline"). Reads THROUGH the RLS policies, never BYPASSRLS.
-- One scope = one module owner (Progress).
-- =============================================================================
CREATE OR REPLACE VIEW v_user_goals_scope WITH (security_invoker = on) AS
SELECT id, user_id, goal, crdt_added, crdt_removed, local_mutation_id,
       created_at, updated_at
FROM user_goals;

GRANT SELECT ON v_user_goals_scope TO service_role;
