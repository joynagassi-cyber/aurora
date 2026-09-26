-- =============================================================================
-- tests/rls-penetration.sql — RLS penetration test (wave0-scout-resolutions
-- issue 3: "W0 creates the test, W1 verifies PowerSync respects RLS").
--
-- STATUS: DEV-ONLY runbook. NOT a migration (do NOT put it under
-- supabase/migrations/). Run in the Supabase DEV project SQL editor with
-- role service_role. Requires two real auth users (A and B) and a session
-- allowed to `SET ROLE authenticated` (Supabase template default).
-- Expected result: for EVERY user-scoped table, user A cannot UPDATE a row
-- that belongs to user B. Global registries (model_registry/ai_usage/
-- ai_health) are EXCLUDED on purpose (01 S4.10: server-wide, justified
-- USING(true) — see 0011 Rationale comments).
--
-- Usage:
--   1) Replace USER_A / USER_B below with two real auth.users ids.
--   2) Run the file. RAISE EXCEPTION = penetration = FAIL.
-- =============================================================================

DO $$
DECLARE
  user_a    uuid := '00000000-0000-0000-0000-00000000000a'; -- USER_A
  user_b    uuid := '00000000-0000-0000-0000-00000000000b'; -- USER_B
  t         text;
  sentinel  uuid := gen_random_uuid();
  row_count bigint;
  tables    text[] := ARRAY[
    'user_context',
    'projects','goals','milestones','tasks','subtasks','habits','routines',
    'focus_sessions','decisions','calendar_events',
    'subjects','skills','courses','learning_sessions','flashcards','reviews','course_imports',
    'knowledge_documents','document_chunks','semantic_nodes','semantic_edges','semantic_bridges',
    'node_state','semantic_tree_version','source_refs','notes','resources',
    'progress_snapshots','progress_evidences','skill_states','progress_trends',
    'progress_events','trajectory_scenarios','gaps',
    'discovery_items','discovery_source_profiles','domain_timeline',
    'artifacts','artifact_files',
    'agent_runs','agent_actions','expert_skills','integrations','automations','notification_preferences',
    'events_history','job_queue'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    -- Insert a sentinel row owned by B (service_role — the only role that
    -- may bypass its own RLS to seed the test).
    SET LOCAL ROLE service_role;
    EXECUTE format('INSERT INTO %I (id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', t)
      USING sentinel, user_b;

    -- As user A: try to UPDATE B's row. RLS must make the row invisible.
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claim.sub', user_a::text, false);
    EXECUTE format('UPDATE %I SET updated_at = now() WHERE id = $1', t) USING sentinel;
    GET DIAGNOSTICS row_count = ROW_COUNT;

    IF row_count > 0 THEN
      RAISE EXCEPTION 'RLS PENETRATION in %: user A updated user B''s row', t;
    END IF;

    -- Cleanup (service_role again).
    SET LOCAL ROLE service_role;
    EXECUTE format('DELETE FROM %I WHERE id = $1', t) USING sentinel;
  END LOOP;

  RAISE NOTICE 'RLS penetration: all % user-scoped tables hold.', cardinality(tables);
END $$;

-- NOTE: job_logs has no user_id column — it is bounded through job_queue
-- subqueries in its policies (0010) and cannot take a sentinel row here.
-- Verify it manually: service_role may only insert logs whose job_id
-- belongs to the job's user (check-rls.sh (b) covers the shape statically).
