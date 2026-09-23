-- =============================================================================
-- Aurora Wave 0 — Migration 0001: extensions + Identity (user_context)
-- Refs: 01-backend §2.1/§4.10, AD-6/AD-16, 03-sync §4.2
-- RLS: 01-backend §2.2 (ENABLE + FORCE on service_role; policies bound by user_id)
-- =============================================================================

-- Extensions required by the platform (01 §4.3 vector, §5.2 cron, pgcrypto ULIDs)
CREATE EXTENSION IF NOT EXISTS vector;     -- pgvector: semantic_nodes.embedding, document_chunks.embedding (01 §4.3)
CREATE EXTENSION IF NOT EXISTS pg_cron;    -- job dispatcher triggers (01 §5.2)
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid fallback; ULID helpers

-- -----------------------------------------------------------------------------
-- Identity module (owner Identity, 01 §2.1). user_context = writer-unique table.
-- AD-17 v2 (pack 05 §5): theme carries the AuroraTheme enum (10 expressive + 3
-- presets), NOT the legacy binary. theme_style keeps the legacy binary.
-- packages/domain owns the TS enum SSoT (AD-15); SQL persists the value only.
-- -----------------------------------------------------------------------------
-- ASSUMPTION wave-0: AuroraTheme value set ratified by SPEC OQ-14 (pack 05 §5 v2).
CREATE TYPE aurora_theme AS ENUM (
  -- 10 expressive living themes (pack 05 §5.4, AD-17)
  'aurora', 'lagoon', 'boreal', 'sakura', 'vesper',
  'solara', 'terra', 'verdant', 'citrus', 'cosmos',
  -- 3 technical presets (pack 05 §5.5)
  'slate', 'nocturne', 'high_contrast'
);

CREATE TABLE user_context (
  user_id        uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  -- AD-17 v2: expressive theme (10+3) — NOT the legacy binary
  theme          aurora_theme NOT NULL DEFAULT 'aurora',
  -- Legacy binary light/dark style (theme_style), still consumed by 5 mustFixForV2 locks
  theme_style    text NOT NULL DEFAULT 'light' CHECK (theme_style IN ('light','dark')),
  -- Coaching authorization prefs (ADR §13: cadence, silence, intervention level)
  coaching_prefs jsonb NOT NULL DEFAULT '{}'::jsonb,
  -- CRDT OR-Set lists that must merge across devices (03 §5.3/§5.4):
  -- local_mutation_id ULID + added/removed jsonb; SSoT encoding in packages/domain
  prefs_added    jsonb NOT NULL DEFAULT '{}'::jsonb,
  prefs_removed  jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '', -- ULID (03 §5.5.6)
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

-- canonical server timestamp (03 §4.2 rule 3)
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_user_context_updated BEFORE UPDATE ON user_context
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS (01 §2.2): ENABLE on every business table; FORCE on service_role
ALTER TABLE user_context ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_context FORCE ROW LEVEL SECURITY;

-- Default policy: strict isolation by auth.uid() (01 §2.2 rule 2)
CREATE POLICY user_context_user_isolation ON user_context
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- service_role policy — PowerSync relay / dispatcher / EFs read through RLS
-- (01 §3.4, 03 §5.5). Bound by user_id, justified: the relay mirrors exactly the
-- rows the authenticated user owns; it never bypasses RLS (AD-7/AD-16).
-- JUSTIFICATION: bound by user_id = auth.uid() through the per-user scope.
CREATE POLICY user_context_service_role ON user_context
  FOR SELECT TO service_role
  USING (user_id = auth.uid());
