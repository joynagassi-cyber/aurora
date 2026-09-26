-- =============================================================================
-- Aurora Wave 0 — Migration 0010: Jobs (01 §5.2/§5.3, AD-8, G-M4)
-- job_queue is the single persisted job store. Dispatcher = fn-job-dispatcher
-- (the ONLY dispatcher, triggered exclusively by Supabase Cron + Postgres
-- INSERT trigger — 01 §5.2). Idempotency key + nullable source_local_mutation_id
-- (ULID, G-M4 frozen shape).
-- =============================================================================

CREATE TABLE job_queue (
  id          text PRIMARY KEY,           -- ULID (chronological)
  user_id     uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  kind        text NOT NULL,             -- SSoT vocabulary = packages/domain (AD-15)
  payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending','running','done','failed','cancelled')),
  attempts    int NOT NULL DEFAULT 0,
  max_attempts int NOT NULL DEFAULT 5,   -- 1 for critical agent_verify (01 §5.3)
  backoff_ms  int NOT NULL DEFAULT 30000, -- exponential base 30s, factor 2, cap 15min
  due_at      timestamptz NOT NULL DEFAULT now(),
  -- Idempotency: kind + hash(logical payload) + user_id (01 §5.3). If the job
  -- is triggered by a local mutation, source_local_mutation_id enters the hash
  -- so repeated re-syncs never double-add the same client-originated job.
  idempotency_key text NOT NULL,
  source_local_mutation_id text,          -- G-M4: nullable ULID (03 §5.5.6)
  result      jsonb,
  trace_id    text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  -- Unique on the dedup key so a re-INSERT of the same logical job is a no-op
  CONSTRAINT uq_job_queue_idempotency UNIQUE (idempotency_key)
);

CREATE INDEX idx_job_queue_due ON job_queue (status, due_at, user_id);
CREATE INDEX idx_job_queue_user_kind ON job_queue (user_id, kind, status);

CREATE TABLE job_logs (
  job_id    text NOT NULL REFERENCES job_queue (id) ON DELETE CASCADE,
  ts        timestamptz NOT NULL DEFAULT now(),
  level     text NOT NULL DEFAULT 'info'
            CHECK (level IN ('debug','info','warn','error')),
  message   text,
  data      jsonb,
  trace_id  text
);
CREATE INDEX idx_job_logs_job ON job_logs (job_id, ts);

-- RLS: users may READ their own jobs; only service_role writes the queue
-- (producers / dispatcher / workers all run server-side — AD-8).
ALTER TABLE job_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_queue FORCE ROW LEVEL SECURITY;
ALTER TABLE job_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_logs FORCE ROW LEVEL SECURITY;

CREATE POLICY job_queue_user_read ON job_queue
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- service_role: the ONLY writer path (AD-8: creation = business EFs,
-- dispatch = fn-job-dispatcher; no other trigger source). Bound by user_id.
CREATE POLICY job_queue_service_role ON job_queue
  FOR ALL TO service_role USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY job_logs_user_read ON job_logs
  FOR SELECT TO authenticated
  USING (job_id IN (SELECT id FROM job_queue WHERE user_id = auth.uid()));

CREATE POLICY job_logs_service_role ON job_logs
  FOR INSERT TO service_role
  WITH CHECK (job_id IN (SELECT id FROM job_queue WHERE user_id = auth.uid()));

CREATE TRIGGER job_queue_updated BEFORE UPDATE ON job_queue
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Postgres trigger on INSERT job_queue → wakes the dispatcher (01 §5.2: the
-- dispatcher is the only thing that acts on new jobs; the trigger only
-- signals, never executes work — AD-8).
CREATE OR REPLACE FUNCTION notify_job_dispatcher() RETURNS trigger AS $$
BEGIN
  -- SECURITY DEFINER: this function is run by the inserting role (service_role
  -- or a policy-scoped user insert) and signals the dispatcher. It NEVER
  -- executes job work — only wakes fn-job-dispatcher via a Postgres NOTIFY.
  PERFORM pg_notify('aurora_job_dispatcher', NEW.id);
  RETURN NEW;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_job_queue_notify
  AFTER INSERT ON job_queue
  FOR EACH ROW EXECUTE FUNCTION notify_job_dispatcher();

-- REST API surface : anon / authenticated ne peuvent PAS appeler
-- /rest/v1/rpc/notify_job_dispatcher directement (le lint 0028/0029
-- flag précisément ce chemin, pas la trigger qui est le SEUL chemin
-- d'écriture de la queue). Le trigger est SECURITY DEFINER (il est
-- appelé par le rôle qui insère — service_role ou un insert borné par
-- la policy user_id = auth.uid()) mais l'EXECUTE est restreint au
-- service_role (pas de BYPASSRLS — l'adversaire n'a pas d'autre
-- chemin d'écriture sur job_queue, AD-8 : seul le dispatcher agit).
REVOKE EXECUTE ON FUNCTION notify_job_dispatcher() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION notify_job_dispatcher() TO service_role;
