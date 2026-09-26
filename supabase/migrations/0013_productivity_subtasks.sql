-- =============================================================================
-- Aurora Wave 2 (foundation fix) — Migration 0013: Productivity `subtasks`
-- (01 §4.1, data-ownership-matrix line Productivity, AD-7 owner = Productivity)
--
-- Closes a real defect: packages/productivity/src/tasks.ts already upserts
-- into the `subtasks` table (toggleSubTask, table union), but the table was
-- never created and never mirrored. Recurrences stay materialized rows
-- (01 S4.1); subtasks are plain rows (PowerSync-compatible, AD-7).
-- =============================================================================

CREATE TABLE subtasks (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  task_id     uuid NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
  title       text NOT NULL,
  status      text NOT NULL DEFAULT 'todo' CHECK (status IN ('todo','done')),
  done_at     timestamptz,
  -- CRDT OR-Set trio + local mutation traceability (0002 pattern, 03 S5.3/5.5)
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_subtasks_user_task ON subtasks (user_id, task_id);

-- RLS: same pattern as 0002/0008 (ENABLE + FORCE + user isolation + bounded
-- service_role read; relay reads THROUGH RLS, never BYPASSRLS — 01 S2.2).
ALTER TABLE subtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE subtasks FORCE ROW LEVEL SECURITY;

CREATE POLICY subtasks_user_isolation ON subtasks
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY subtasks_service_role ON subtasks
  FOR SELECT TO service_role USING (user_id = auth.uid());

CREATE TRIGGER subtasks_updated BEFORE UPDATE ON subtasks
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
