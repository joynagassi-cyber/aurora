-- =============================================================================
-- Aurora Wave 0 — Migration 0005: Progress module (01 §4.4, ADR §18.8)
-- Progress is the UNIQUE producer of progress_evidences / ProgressEvidenceCreated
-- (F-07); it emits events, it NEVER writes Knowledge tables (AD-2/F-02).
-- Mirrored locally: skill_states + progress_snapshots ONLY (03 §4.2).
-- progress_evidences / progress_events / progress_trends = server-only.
-- =============================================================================

CREATE TABLE progress_snapshots (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  taken_at    timestamptz NOT NULL DEFAULT now(),
  payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE progress_evidences (
  -- SERVER-ONLY (not mirrored locally, 03 §4.2). F-07: Progress is sole writer.
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id),
  skill_id    uuid,
  goal_id     uuid,
  type        text NOT NULL,
  level       text,
  date        timestamptz NOT NULL DEFAULT now(),
  freshness   text,
  context     text,
  confidence  numeric(5,4),
  source_event_id text,   -- provenance (01 §3.3 ProgressEvidenceCreated payload)
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE skill_states (
  -- Mirrored locally (03 §4.2): level/freshness/confidence read by Progress UI
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  skill_id    uuid NOT NULL REFERENCES skills (id) ON DELETE CASCADE,
  level       text NOT NULL DEFAULT 'beginner',
  freshness   text NOT NULL DEFAULT 'stale',
  confidence  numeric(5,4) NOT NULL DEFAULT 0,
  last_evidence_at timestamptz,
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE progress_trends (
  -- SERVER-ONLY: derived aggregates, recomputed by Progress server jobs
  user_id     uuid NOT NULL REFERENCES auth.users (id),
  period      text NOT NULL,
  dimension   text NOT NULL,
  value       numeric,
  computed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, period, dimension)
);

CREATE TABLE progress_events (
  -- Progress-owned Event History (append-only audit/progression, AD-6/F-10).
  -- Distinct from the global `events` table (01 §4.8). NOT mirrored locally.
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  event_type  text NOT NULL,
  payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
  occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE trajectory_scenarios (
  -- SERVER-ONLY (03 §4.2: conditional + voluminous → no local mirror)
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  base_snapshot_id uuid REFERENCES progress_snapshots (id) ON DELETE CASCADE,
  hypotheses  jsonb NOT NULL DEFAULT '[]'::jsonb,
  actions     jsonb NOT NULL DEFAULT '[]'::jsonb,
  expected    jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE gaps (
  -- Rows owned by PROGRESS (01 §4.4); definitions in packages/domain (AD-15).
  -- Discovery READS via public view, never writes (F-04).
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  kind        text NOT NULL
              CHECK (kind IN ('academic','skill','tech','methodology','portfolio','ve','depth')),
  description text,
  evidence_refs jsonb NOT NULL DEFAULT '[]'::jsonb, -- CRDT OR-Set (03 §5.3)
  detected_at timestamptz NOT NULL DEFAULT now(),
  status      text NOT NULL DEFAULT 'open'
              CHECK (status IN ('open','in_progress','closed')),
  crdt_added  jsonb NOT NULL DEFAULT '{}'::jsonb,
  crdt_removed jsonb NOT NULL DEFAULT '{}'::jsonb,
  local_mutation_id text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'progress_snapshots','progress_evidences','skill_states',
    'trajectory_scenarios','gaps'
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

-- progress_trends / progress_events: read-only for the user; server-only views.
ALTER TABLE progress_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_trends FORCE ROW LEVEL SECURITY;
CREATE POLICY progress_trends_user_isolation ON progress_trends
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY progress_trends_service_role ON progress_trends
  FOR SELECT TO service_role USING (user_id = auth.uid());

ALTER TABLE progress_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_events FORCE ROW LEVEL SECURITY;
CREATE POLICY progress_events_user_read ON progress_events
  FOR SELECT TO authenticated USING (user_id = auth.uid());
-- service_role: dispatcher / Job system appends Progress's own event history.
-- Bound by user_id (01 §2.2 rule 2); no BYPASSRLS.
CREATE POLICY progress_events_service_role ON progress_events
  FOR ALL TO service_role USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
