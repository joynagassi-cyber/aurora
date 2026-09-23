-- =============================================================================
-- Aurora Wave 0 — Migration 0003: Learning module (01 §4.2)
-- FSRS algorithm runs SERVER-side (01 §4.2/§5.1); the device mirrors the state
-- (due/stability/difficulty) read-only via PowerSync.
-- =============================================================================

CREATE TABLE subjects (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text NOT NULL,
  description text,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE skills (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text NOT NULL,
  definition  text,   -- canonical definitions owned by Learning (01 §4.2)
  subject_id  uuid REFERENCES subjects (id) ON DELETE SET NULL,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE courses (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title         text NOT NULL,
  description   text,
  subject_id    uuid REFERENCES subjects (id) ON DELETE SET NULL,
  status        text NOT NULL DEFAULT 'active'
                CHECK (status IN ('active','completed','archived','abandoned')),
  progress_pct  numeric(5,2) NOT NULL DEFAULT 0,
  crdt_added    jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed  jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE learning_sessions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  course_id     uuid REFERENCES courses (id) ON DELETE SET NULL,
  skill_id      uuid REFERENCES skills (id) ON DELETE SET NULL,
  started_at    timestamptz NOT NULL DEFAULT now(),
  ended_at      timestamptz,
  duration_min  int,
  notes         text,
  crdt_added    jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed  jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE flashcards (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  course_id      uuid REFERENCES courses (id) ON DELETE CASCADE,
  front          text NOT NULL,
  back           text,
  -- FSRS per-card state machine (01 §4.2): due/stability/difficulty + reviewed
  due            timestamptz,
  stability      numeric(10,4),
  difficulty     numeric(10,4),
  last_reviewed_at timestamptz,
  crdt_added     jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed   jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE reviews (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  flashcard_id   uuid REFERENCES flashcards (id) ON DELETE CASCADE,
  skill_id       uuid REFERENCES skills (id) ON DELETE SET NULL,
  rating         int NOT NULL CHECK (rating BETWEEN 0 AND 5),
  reviewed_at    timestamptz NOT NULL DEFAULT now(),
  fsrs_state     jsonb NOT NULL DEFAULT '{}'::jsonb, -- {due, stability, difficulty}
  crdt_added     jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed   jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE course_imports (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  course_id   uuid REFERENCES courses (id) ON DELETE CASCADE,
  source      text NOT NULL,       -- e.g. 'manual' | 'r2_document'
  r2_key      text,                -- imported file lives in R2 (AD-16, 01 §5.4)
  status      text NOT NULL DEFAULT 'queued'
              CHECK (status IN ('queued','processing','done','failed')),
  job_id      text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'subjects','skills','courses','learning_sessions','flashcards','reviews','course_imports'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY %I_user_isolation ON %I
       USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())', t, t);
    -- service_role: PowerSync relay / EF read-through (01 §3.4), bound by user_id
    EXECUTE format(
      'CREATE POLICY %I_service_role ON %I FOR SELECT TO service_role
       USING (user_id = auth.uid())', t, t);
    EXECUTE format(
      'CREATE TRIGGER %I_updated BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
  END LOOP;
END $$;
