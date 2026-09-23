-- =============================================================================
-- Aurora Wave 0 — Migration 0006: Discovery module (01 §4.5)
-- =============================================================================

CREATE TABLE discovery_items (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title       text NOT NULL,
  question    text,
  why_now     text,
  factual_summary text,
  sources     jsonb NOT NULL DEFAULT '[]'::jsonb,
  kind        text NOT NULL
              CHECK (kind IN ('scientific','professional','innovation','trend','uncertain')),
  status      text NOT NULL DEFAULT 'new'
              CHECK (status IN ('new','investigating','resolved','stale')),
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE discovery_source_profiles (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  source_name text NOT NULL,
  domains     jsonb NOT NULL DEFAULT '[]'::jsonb,
  confidence  numeric(5,4),
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE domain_timeline (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  domain      text NOT NULL,
  event_type  text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['discovery_items','discovery_source_profiles','domain_timeline'] LOOP
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
