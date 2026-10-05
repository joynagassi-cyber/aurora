-- 0020_expert_skills_extensions.sql
-- Self-Improvement §4 (ADR S14.5, docs/agent/expert-skills-extensions.md §4).
--
-- The 3 extension tables that support the expert-skills feedback loop
-- (triage, contrastive analysis, audit trail). All are Aurora-specific
-- names (no collision check needed — verified absent via pg_class pre-apply).
--
-- expert_skills (0008) is the narrow base form. The spec §4 extension
-- (trigger/goal/steps/provenance/obsolescence/decay_lambda) is intentionally
-- NOT applied as an ALTER here:
--   - `expert_skills.procedure` (text) ≈ `steps` (jsonb, richer but same
--     semantics) — a widening to jsonb would break the existing bootstrap
--     reader (fn-agent-bootstrap loadExpertSkills expects text).
--   - `expert_skills.trigger_`/`objective` ≈ `trigger`/`goal` (renamed).
--   - `provenance`/`obsolescence`/`decay_lambda` are new richer fields that
--     the 4 deterministic expert skills (expert-skills.ts) do NOT yet use.
--   - Adding these is a follow-up once the triage/contrastive/audit
--     tables below are consumed by the Self-Improvement loop.
--   The 3 NEW tables below are the minimal schema required to START the
--   feedback loop without touching the existing expert_skills contract.
--
-- RLS: all 3 tables are user_id-isolated (AD-2, Identity root), same
-- pattern as expert_skills (0008). FORCE ROW LEVEL SECURITY on each,
-- service_role = SELECT only (the EF fn-agent-bootstrap / fn-skills is the
-- single server-side writer, matching 0008's expert_skills_service_role
-- policy shape). No USING(true) without a Rationale comment anywhere in
-- this file (check-rls.sh gate requirement).
--
-- NOT in PowerSync sync scope (03 S4.2: expert_skills = server-only, AD-3).
-- These tables inherit that: server-side reads only, no local mirror.

-- ─── skill_hypotheses (triage, spec §2.3) ─────────────────────────────
-- A hypothesis = "if we change X about skill Y, confidence should rise".
-- status: hypothesis → testing → validated / rejected / expired.
CREATE TABLE skill_hypotheses (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  -- null if the hypothesis targets a NEW skill not yet in expert_skills.
  skill_id        uuid REFERENCES expert_skills (id) ON DELETE CASCADE,
  trigger_        text NOT NULL,
  proposed_action text NOT NULL,
  confidence      numeric(5,4) NOT NULL DEFAULT 0.2,
  status          text NOT NULL DEFAULT 'hypothesis'
                 CHECK (status IN ('hypothesis','testing','validated','rejected','expired')),
  -- { start, end, requiredEvidence[] }
  evidence_window jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at      timestamptz NOT NULL DEFAULT now(),
  resolved_at     timestamptz
);

-- ─── contrastive_pairs (spec §2.1) ────────────────────────────────────
-- One pair = a success ProgressEvidence + a failure ProgressEvidence,
-- the divergent variables that explain the difference, and the
-- confidence delta the pair produces on the referenced skill.
CREATE TABLE contrastive_pairs (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  skill_id          uuid NOT NULL REFERENCES expert_skills (id) ON DELETE CASCADE,
  -- progress_evidences.id (Progress, 01 S4.4, sole producer F-07).
  success_evidence_id uuid NOT NULL REFERENCES progress_evidences (id) ON DELETE CASCADE,
  failure_evidence_id uuid NOT NULL REFERENCES progress_evidences (id) ON DELETE CASCADE,
  -- e.g. ["start_time", "energy_level", "interruptions"]
  divergent_vars    text[] NOT NULL DEFAULT '{}',
  conclusion        text NOT NULL,
  confidence_delta  numeric(5,4) NOT NULL DEFAULT 0,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- ─── skill_validation_log (audit trail, ADR S14.5) ──────────────────
-- Every confidence transition on an expert_skill is recorded here.
CREATE TABLE skill_validation_log (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  skill_id   uuid NOT NULL REFERENCES expert_skills (id) ON DELETE CASCADE,
  -- 'created' | 'revalidated' | 'decayed' | 'archived' | 'user_corrected'
  -- | 'contradiction_detected' | 'hypothesis_promoted' | 'hypothesis_rejected'
  event      text NOT NULL,
  -- { confidence_before, confidence_after, reason }
  detail     jsonb,
  evidence_refs uuid[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ─── RLS + triggers + indexes (check-rls.sh compliant) ──────────────
DO $aurora020$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['skill_hypotheses','contrastive_pairs','skill_validation_log'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY %I_user_isolation ON %I
       USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())', t, t);
    -- Rationale: service_role gets SELECT-only access (the EF is the single
    -- server-side reader/writer for the Self-Improvement loop; the user's
    -- own rows stay fully isolated by _user_isolation above). Same shape as
    -- expert_skills_service_role in 0008 — no permissive USING(true) here.
    EXECUTE format(
      'CREATE POLICY %I_service_role ON %I FOR SELECT TO service_role
       USING (user_id = auth.uid())', t, t);
    EXECUTE format(
      'CREATE TRIGGER %I_updated BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
  END LOOP;
END
$aurora020$;

CREATE INDEX idx_skill_hypotheses_user_status ON skill_hypotheses (user_id, status);
CREATE INDEX idx_contrastive_pairs_skill ON contrastive_pairs (skill_id);
CREATE INDEX idx_skill_validation_log_skill ON skill_validation_log (skill_id, created_at DESC);
