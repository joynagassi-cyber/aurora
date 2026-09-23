-- =============================================================================
-- Aurora Wave 0 — Migration 0004: Knowledge module (01 §4.3, AD-6)
-- Sole writer of node_state (AD-6/F-02). Binaries live in R2 (AD-16);
-- local mirror keeps metadata + r2_key ONLY, never the binary, and the
-- semantic_nodes local mirror has NO embedding column (03 §4.2).
-- Lead decision: `notes` and `resources` belong to the Knowledge module
-- (03 §4.2 frozen mapping: Note/Resource → Knowledge, "metadata + r2_key,
-- no binary in SQLite"). This OVERRIDES data-ownership-matrix if it says
-- Productivity — 03 §4.2 wins for schema. Flagged in commit 1 message.
-- =============================================================================

CREATE TABLE knowledge_documents (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title       text NOT NULL,
  mime_type   text,
  r2_key      text,   -- AD-16: {env}/{user_id}/{module}/{yyyy}/{mm}/{dd}/{ULID}[_slug].{ext}
  size_bytes  bigint,
  sha256      text,
  status      text NOT NULL DEFAULT 'uploaded'
              CHECK (status IN ('queued','uploaded','processing','ready','failed')),
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE document_chunks (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  document_id   uuid NOT NULL REFERENCES knowledge_documents (id) ON DELETE CASCADE,
  chunk_index   int NOT NULL,
  text          text NOT NULL,
  -- 768-dim (decision: bge-base compatible; change provider + re-embed to migrate)
  embedding     vector(768),
  UNIQUE (document_id, chunk_index)
);
-- FTS + GIN indexes (01 §4.3)
CREATE INDEX idx_document_chunks_fts ON document_chunks USING gin (to_tsvector('english', text));
CREATE INDEX idx_document_chunks_embedding ON document_chunks USING hnsw (embedding vector_cosine_ops);

CREATE TABLE semantic_nodes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  kind         text NOT NULL
               CHECK (kind IN ('principle','domain','subject','concept','law','formula','method','example','application','skill')),
  label        text NOT NULL,
  summary      text,
  body         text,
  parent_id    uuid REFERENCES semantic_nodes (id) ON DELETE SET NULL,
  domain_path  text,
  -- 768-dim (decision: bge-base compatible; change provider + re-embed to migrate)
  embedding    vector(768),
  source_ref_ids jsonb NOT NULL DEFAULT '[]'::jsonb, -- CRDT OR-Set (03 §5.3)
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE semantic_edges (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  source_node  uuid NOT NULL REFERENCES semantic_nodes (id) ON DELETE CASCADE,
  target_node  uuid NOT NULL REFERENCES semantic_nodes (id) ON DELETE CASCADE,
  relation     text NOT NULL
               CHECK (relation IN ('depends_on','is_a_case_of','deepens','applies','leads_to')),
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE semantic_bridges (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  source_node  uuid NOT NULL REFERENCES semantic_nodes (id) ON DELETE CASCADE,
  target_node  uuid NOT NULL REFERENCES semantic_nodes (id) ON DELETE CASCADE,
  label        text,          -- inter-domain bridge, explicitly annotated (01 §4.3)
  secondaries  jsonb NOT NULL DEFAULT '[]'::jsonb,
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE node_state (
  -- AUTEUR UNIQUE: Knowledge (AD-6/F-02). No other module writes here.
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  node_id      uuid NOT NULL REFERENCES semantic_nodes (id) ON DELETE CASCADE,
  state        text NOT NULL DEFAULT 'collapsed'
               CHECK (state IN ('collapsed','expanded','selected','focused','mastered','fragile','forgotten')),
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE semantic_tree_version (
  -- Knowledge-owned versioning (AD-6/F-10): Event History NEVER doubles it
  version     int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id     uuid NOT NULL REFERENCES auth.users (id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  diff_json   jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE source_refs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  entity       text,         -- which AD-15 entity the ref points to
  entity_id    uuid,
  source_document_id uuid REFERENCES knowledge_documents (id) ON DELETE SET NULL,
  page         int,
  passage      text,
  kind         text,
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- Lead decision: Knowledge owns notes/resources (03 §4.2). Metadata + r2_key;
-- the binary lives in R2 (AD-16).
CREATE TABLE notes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title        text,
  body         text,
  kind         text NOT NULL DEFAULT 'free' CHECK (kind IN ('free','structured')),
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE resources (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title        text NOT NULL,
  mime_type    text,
  r2_key       text,   -- AD-16 key convention
  size_bytes   bigint,
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'knowledge_documents','document_chunks','semantic_nodes','semantic_edges',
    'semantic_bridges','node_state','source_refs','notes','resources'
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

-- semantic_tree_version has no updated_at; skip trigger
ALTER TABLE semantic_tree_version ENABLE ROW LEVEL SECURITY;
ALTER TABLE semantic_tree_version FORCE ROW LEVEL SECURITY;
CREATE POLICY semantic_tree_version_user_isolation ON semantic_tree_version
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY semantic_tree_version_service_role ON semantic_tree_version
  FOR SELECT TO service_role USING (user_id = auth.uid());
