-- =============================================================================
-- Aurora Wave 0 — Migration 0008: Agent / Integrations module (01 §4.7)
-- Agent orchestration is SERVER-only (AD-12/F-09). expert_skills is
-- SERVER-ONLY with NO local mirror (AD-3). Integrations tokens live in
-- Supabase secret storage, never in plain columns (AD-3).
-- =============================================================================

CREATE TABLE agent_runs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  intent       text NOT NULL,
  status       text NOT NULL DEFAULT 'running'
               CHECK (status IN ('running','completed','failed','cancelled')),
  steps_json   jsonb NOT NULL DEFAULT '[]'::jsonb,
  budget_snapshot jsonb,
  started_at   timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  trace_id     text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE agent_actions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  run_id        uuid NOT NULL REFERENCES agent_runs (id) ON DELETE CASCADE,
  kind          text NOT NULL,
  target_module text NOT NULL,
  payload       jsonb NOT NULL DEFAULT '{}'::jsonb,
  result_status text,
  trace_id      text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE expert_skills (
  -- SERVER-ONLY, no local mirror (AD-3, 01 §4.7). Agent self-improvement
  -- memory is never synced to device.
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  trigger_     text,
  objective    text,
  procedure    text,
  constraints  jsonb NOT NULL DEFAULT '{}'::jsonb,
  confidence   numeric(5,4),
  source       text,
  status       text NOT NULL DEFAULT 'candidate'
               CHECK (status IN ('candidate','validated','deprecated')),
  valid_at     timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE integrations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  provider        text NOT NULL,
  connection_state jsonb NOT NULL DEFAULT '{}'::jsonb,
  -- token_ref: pointer into Supabase secret storage. The token value is NEVER
  -- stored in this table (AD-3, 01 §4.7).
  token_ref       text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE automations (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text,
  trigger_    jsonb NOT NULL DEFAULT '{}'::jsonb,
  action      jsonb NOT NULL DEFAULT '{}'::jsonb,
  enabled     boolean NOT NULL DEFAULT true,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notification_preferences (
  user_id    uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  channels   jsonb NOT NULL DEFAULT '{}'::jsonb,
  quiet_hours jsonb NOT NULL DEFAULT '{}'::jsonb,  -- coaching silence, ADR §13
  crdt_added jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'agent_runs','agent_actions','expert_skills','integrations','automations','notification_preferences'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY %I_user_isolation ON %I
       USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())', t, t);
    EXECUTE format(
      'CREATE POLICY %I_service_role ON %I FOR SELECT TO service_role
       USING (user_id = auth.uid())', t, t);
    EXECUTE format(
      'CREATE TRIGGER %I_updated BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
  END LOOP;
END $$;
