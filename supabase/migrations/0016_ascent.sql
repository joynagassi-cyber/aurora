-- =============================================================================
-- Aurora Wave 3 — Migration 0016: Ascent module (docs/ascent/overview.md,
-- implementation.md "SQL Migration + Sync Surface", 80/20 rule S20).
--
-- Ascent = pedagogical trajectory engine. SERVER-ONLY writes (AD-12, same
-- placement as the Agent Kernel); the device reads the CURRENT path through
-- a read-only PowerSync mirror (03 S4.2 — deliberately NOT like expert_skills,
-- which is never mirrored: Slide-Ascent must render offline, mobile-first).
--
-- 80/20 (overview S20): ONE table. `ascent_paths` carries the whole IR as
-- JSONB columns (steps, depth, baseline snapshot, adaptations log) — the
-- 4-table split (ascent_steps / ascent_adaptations / ascent_baselines) is a
-- deferred query-perf decision, not an architecture change.
--
-- APPLIED live 2026-09-26 via Supabase MCP (block-by-block): table +
-- trigger + ENABLE/FORCE RLS + policies + v_ascent_scope view + GRANT
-- service_role all verified present post-apply.

-- ============================================================================
--
-- Single-writer (AD-7): only Ascent writes ascent_paths. RLS user isolation
-- (0008 pattern); relay reads THROUGH the policies, never BYPASSRLS (AD-16).
-- =============================================================================

CREATE TABLE ascent_paths (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  -- "Master RDM by exam day" (NL goal, verbatim)
  goal        text NOT NULL,
  -- Progress skill_id the goal binds to (optional)
  target_skill uuid,
  target_date date,
  -- AscentStep[] (the ordered trajectory + READ→DO→PROVE phases)
  steps       jsonb NOT NULL DEFAULT '[]'::jsonb,
  -- { stepId: 'quick'|'standard'|'deep' }
  depth       jsonb NOT NULL DEFAULT '{}'::jsonb,
  -- LearnerBaseline snapshot at path creation (S6.2)
  baseline    jsonb NOT NULL DEFAULT '{}'::jsonb,
  status      text NOT NULL DEFAULT 'active'
               CHECK (status IN ('active','paused','completed','abandoned')),
  -- AscentAdaptation[] (append-only audit trail, S6.3)
  adaptations jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER ascent_paths_updated BEFORE UPDATE ON ascent_paths
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS: user isolation (AD-2). ENABLE + FORCE so even service_role is bound
-- by the policies (01 S2.2 rule 1 — the relay goes THROUGH, never BYPASSRLS).
ALTER TABLE ascent_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE ascent_paths FORCE ROW LEVEL SECURITY;

-- user_id isolation (0008 pattern). Ascent is server-only: writes come from
-- the authenticated/service_role paths both bound by user_id; the read-only
-- device mirror reads THROUGH this policy via v_ascent_scope (relay.sql).
CREATE POLICY ascent_paths_user_isolation ON ascent_paths
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY ascent_paths_service_role ON ascent_paths
  FOR SELECT TO service_role
  USING (user_id = auth.uid());

-- NO un-justified USING(true) anywhere in this migration (check-rls (b)).
