-- =============================================================================
-- Aurora Wave 0 — Migration 0007: Artifact module / R2 metadata (01 §4.6)
-- Binaries live ONLY in R2 (AD-16); these tables carry metadata + r2_key.
-- ArtifactGenerated is emitted AFTER confirmed R2 upload (AD-9, F-06).
-- =============================================================================

CREATE TABLE artifacts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  kind          text NOT NULL
                CHECK (kind IN ('pdf','docx','pptx','xlsx','image','audio','video','markdown','latex','other')),
  title         text,
  mime_type     text,
  r2_key        text,   -- AD-16 key convention (docs/cloudflare/r2.md §1 SSoT)
  size_bytes    bigint,
  source_event_id text, -- jobId / provenance (F-06)
  context_task_id uuid,
  context_course_id uuid,
  status        text NOT NULL DEFAULT 'queued'
                CHECK (status IN ('queued','generating','uploaded','failed','expired')),
  crdt_added    jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed  jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE artifact_files (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  artifact_id uuid NOT NULL REFERENCES artifacts (id) ON DELETE CASCADE,
  filename    text NOT NULL,
  mime_type   text,
  r2_key      text,
  size_bytes  bigint,
  sha256      text,
  status      text NOT NULL DEFAULT 'uploaded'
              CHECK (status IN ('uploaded','verified','failed')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['artifacts','artifact_files'] LOOP
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
