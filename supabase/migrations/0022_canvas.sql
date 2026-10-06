-- =============================================================================
-- Aurora — Migration 0022: Canvas module (block editor + commentaires)
-- canvas_sessions: un canvas = la surface d'édition d'une session d'artefact
-- (artifact_id nullable — un canvas peut exister sans artefact généré).
-- blocks jsonb: [{ id, kind: 'md', content: markdown }] (SSoT contenu).
-- canvas_comments: ancre de sélection (anchor_start/anchor_end dans le texte
-- plat de la session = blocks.map(b=>b.content).join('\n\n')) + body.
-- Pattern RLS 0007/0008: ENABLE + FORCE, user_isolation + service_role.
-- =============================================================================

CREATE TABLE canvas_sessions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title         text NOT NULL DEFAULT '',
  blocks        jsonb NOT NULL DEFAULT '[]'::jsonb,
  artifact_id   uuid REFERENCES artifacts (id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX canvas_sessions_user_idx ON canvas_sessions (user_id);

CREATE TABLE canvas_comments (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  session_id     uuid NOT NULL REFERENCES canvas_sessions (id) ON DELETE CASCADE,
  anchor_start   int NOT NULL,
  anchor_end     int NOT NULL,
  body           text NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX canvas_comments_session_idx ON canvas_comments (session_id);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['canvas_sessions','canvas_comments'] LOOP
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

GRANT SELECT, INSERT, UPDATE, DELETE ON canvas_sessions, canvas_comments TO authenticated;
