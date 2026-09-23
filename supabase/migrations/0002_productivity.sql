-- =============================================================================
-- Aurora Wave 0 — Migration 0002: Productivity module (01 §4.1)
-- Lead decision: calendar table renamed to `calendar_events` to avoid the
-- collision with the Event History `events` table (03 §4.2: "events =
-- calendrier uniquement" in the LOCAL store; server Event History is `events`).
-- Recurrences are MATERIALIZED rows (01 §4.1), never a rule table, to stay
-- PowerSync-compatible (AD-7).
-- =============================================================================

CREATE TABLE projects (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  goal_id     uuid,
  name        text NOT NULL,
  description text,
  status      text NOT NULL DEFAULT 'active' CHECK (status IN ('active','archived','completed')),
  start_date  date,
  end_date    date,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE goals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title       text NOT NULL,
  description text,
  -- horizon: short/mid/long (01 §4.1)
  horizon     text NOT NULL DEFAULT 'mid' CHECK (horizon IN ('short','mid','long')),
  status      text NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','archived')),
  target_date date,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE milestones (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  project_id  uuid REFERENCES projects (id) ON DELETE CASCADE,
  goal_id     uuid REFERENCES goals (id) ON DELETE SET NULL,
  title       text NOT NULL,
  due_date    date,
  status      text NOT NULL DEFAULT 'open' CHECK (status IN ('open','reached','skipped')),
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tasks (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  project_id   uuid REFERENCES projects (id) ON DELETE SET NULL,
  goal_id      uuid REFERENCES goals (id) ON DELETE SET NULL,
  subject      text NOT NULL,
  description  text,
  status       text NOT NULL DEFAULT 'todo'
               CHECK (status IN ('todo','doing','blocked','done','cancelled')),
  priority     int NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 4),
  importance   int NOT NULL DEFAULT 3 CHECK (importance BETWEEN 1 AND 4),
  due_at       timestamptz,
  -- materialized recurrences: each occurrence is a row; parent_recurrence_key
  -- groups them; every occurrence has a stable identity (01 §4.1, AD-7)
  parent_recurrence_key text,
  energy       text CHECK (energy IN ('high','medium','low')),
  work_context text,
  actual_minutes int,
  dependencies jsonb NOT NULL DEFAULT '[]'::jsonb,  -- CRDT OR-Set list (03 §5.3)
  evidence_refs jsonb NOT NULL DEFAULT '[]'::jsonb, -- CRDT OR-Set (03 §5.3)
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE habits (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text NOT NULL,
  frequency   jsonb NOT NULL DEFAULT '{}'::jsonb,  -- temporal anchor spec
  target      text,
  status      text NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused','dropped')),
  streak      int NOT NULL DEFAULT 0,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE routines (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text NOT NULL,
  anchor      jsonb NOT NULL DEFAULT '{}'::jsonb,  -- temporal anchor (01 §4.1)
  steps       jsonb NOT NULL DEFAULT '[]'::jsonb,
  status      text NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused','archived')),
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE focus_sessions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  task_id           uuid REFERENCES tasks (id) ON DELETE SET NULL,
  started_at        timestamptz NOT NULL DEFAULT now(),
  ended_at          timestamptz,
  planned_minutes   int,
  actual_minutes    int,
  status            text NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','paused','ended','abandoned')),
  -- focus-mode policy rows (04 §4.2 FocusController + focus-mode/spec.md §5)
  notification_policy jsonb NOT NULL DEFAULT '{}'::jsonb,
  call_policy         jsonb NOT NULL DEFAULT '{}'::jsonb,
  focus_app_rules     jsonb NOT NULL DEFAULT '{}'::jsonb,
  session_bilan       jsonb NOT NULL DEFAULT '{}'::jsonb, -- FocusSessionBilan (G-H1, wave-1 type in packages/domain)
  crdt_added          jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed        jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id   text NOT NULL DEFAULT '',
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE decisions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title       text NOT NULL,
  context     text,
  outcome     text,
  decided_at  timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Lead decision (03 §4.2): LOCAL calendar entity is `events`; the SERVER table
-- is `calendar_events` to keep it distinct from the Event History `events`
-- (01 §4.8, AD-6/F-10). Renaming documented in the wave-0 commit 1 message.
CREATE TABLE calendar_events (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title        text NOT NULL,
  description  text,
  start_at     timestamptz NOT NULL,
  end_at       timestamptz,
  all_day      boolean NOT NULL DEFAULT false,
  recurrence   jsonb NOT NULL DEFAULT '{}'::jsonb,   -- materialized info only (01 §4.1)
  location     text,
  crdt_added   jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- RLS (01 §2.2): ENABLE + FORCE on service_role; default auth.uid() policies;
-- service_role policies bound by user_id with justification comments.
-- -----------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'projects','goals','milestones','tasks','habits','routines',
    'focus_sessions','decisions','calendar_events'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);

    -- Default: strict user isolation (01 §2.2 rule 2)
    EXECUTE format(
      'CREATE POLICY %I_user_isolation ON %I
       USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())',
      t, t);

    -- service_role: PowerSync relay / fn-job-dispatcher / Edge Functions read
    -- through RLS (01 §3.4, 03 §5.5). Bound by user_id — the relay mirrors
    -- exactly the rows of the requesting user (AD-7 single-writer, AD-16).
    EXECUTE format(
      'CREATE POLICY %I_service_role ON %I FOR SELECT TO service_role
       USING (user_id = auth.uid())', t, t);

    -- updated_at trigger (03 §4.2 rule 3: server timestamp is canonical)
    EXECUTE format(
      'CREATE TRIGGER %I_updated BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
  END LOOP;
END $$;
