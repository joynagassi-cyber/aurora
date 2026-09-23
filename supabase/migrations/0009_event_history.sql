-- =============================================================================
-- Aurora Wave 0 — Migration 0009: Event History — global `events` (01 §4.8)
-- Lead decision: exactly ONE `events` table (ULID, payload jsonb, producer
-- field). `progress_events` stays a separate Progress table (0005). The
-- calendar table is `calendar_events` (0002) so it never collides.
-- Retention: 2 years (audit-only, NOT Event Sourcing — AD-6, ADR §26.7).
-- ULID = 26-char string, sortable; generated app-side or via a helper.
-- =============================================================================

CREATE TABLE events (
  id          text PRIMARY KEY,   -- ULID (26 chars, chronological)
  event_type  text NOT NULL,      -- AD-9 vocabulary (9 events, 01 §3.3)
  payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
  producer    text NOT NULL,      -- module that emitted (unique producer, AD-9)
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  -- consumer bookkeeping (01 §4.8 processed_at optional)
  processed_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_events_user_time ON events (user_id, occurred_at);
CREATE INDEX idx_events_type_user ON events (event_type, user_id);

-- RLS: users read their own history; appends happen via service_role
-- (producers run server-side). Bound by user_id — no BYPASSRLS (01 §2.2).
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE events FORCE ROW LEVEL SECURITY;

CREATE POLICY events_user_read ON events
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- service_role: the producer modules + fn-notifications dispatcher append
-- through this policy. JUSTIFICATION: writes are scoped to the user the job
-- runs for (job_queue target_user_id); a service write for user A can never
-- touch user B's rows.
CREATE POLICY events_service_role ON events
  FOR ALL TO service_role USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Retention 2 years (01 §4.8): archival is a Foundation job, not a trigger.
-- Documented here; execution (DELETE older than 2y) belongs to the model/
-- registry wave-1 ops, kept out of the schema to stay audit-legal.
