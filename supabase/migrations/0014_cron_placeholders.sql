-- =============================================================================
-- Aurora Wave 2 (foundation fix) — Migration 0014: pg_cron placeholder entries
-- (01 §5.2, wave0-scout-resolutions issue 4 — "W0 creates cron entries with
-- placeholder intervals". The pg_cron extension itself: 0001.)
--
-- OQ-03: schedule values below are PLACEHOLDERS. Final values are a Joy +
-- Foundation decision; update the SCHEDULE column only (structure identical
-- regardless of interval — the dispatcher reads due_at from job_queue, the
-- cron only enqueues or wakes).
--
-- Jobs are enqueued idempotently (idempotency_key + ON CONFLICT DO NOTHING,
-- 0010 uq_job_queue_idempotency). Kind vocabulary = packages/domain JobKind.
-- =============================================================================

-- 1. fsrs-tick batch — daily 02:00 (placeholder). One job per user per day;
--    the worker reads due flashcards (03 S4.2: FSRS ticks run server-side).
INSERT INTO cron.job (schedule, jobname, command) VALUES (
  '0 2 * * *',
  'aurora_fsrs_tick',
  $cmd$
    INSERT INTO job_queue
      (id, user_id, kind, payload, status, max_attempts, backoff_ms, due_at,
       idempotency_key, source_local_mutation_id)
    SELECT substr(md5('fsrs-tick:' || uc.user_id::text || to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD')), 1, 26),
           uc.user_id, 'fsrs-tick', '{}'::jsonb, 'pending', 3, 30000, now(),
           'fsrs-tick:' || uc.user_id::text || ':' || to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD'),
           NULL
    FROM user_context uc
    ON CONFLICT (idempotency_key) DO NOTHING
  $cmd$
);

-- 2. skill_recompute — daily 03:00 (placeholder). Re-derives skill_states
--    from evidence (Progress sole producer, F-07).
INSERT INTO cron.job (schedule, jobname, command) VALUES (
  '0 3 * * *',
  'aurora_skill_recompute',
  $cmd$
    INSERT INTO job_queue
      (id, user_id, kind, payload, status, max_attempts, backoff_ms, due_at,
       idempotency_key, source_local_mutation_id)
    SELECT substr(md5('skill_recompute:' || uc.user_id::text || to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD')), 1, 26),
           uc.user_id, 'skill_recompute', '{}'::jsonb, 'pending', 3, 30000, now(),
           'skill_recompute:' || uc.user_id::text || ':' || to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD'),
           NULL
    FROM user_context uc
    ON CONFLICT (idempotency_key) DO NOTHING
  $cmd$
);

-- 3. event_dispatch sweep — every 5 min (placeholder). Thin wake signal only
--    (symmetric with trg_job_queue_notify, 0010): the dispatcher itself is
--    the ONLY actor (AD-8); this cron adds NO business logic.
INSERT INTO cron.job (schedule, jobname, command) VALUES (
  '*/5 * * * *',
  'aurora_event_dispatch',
  $cmd$
    SELECT pg_notify('aurora_job_dispatcher', 'cron-sweep')
  $cmd$
);
