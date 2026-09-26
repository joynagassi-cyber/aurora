-- =============================================================================
-- Aurora Wave 1 — PowerSync relay-scoped views (03 S5.5 / S5.4, 01 S3.4, AD-7)
--
-- The PowerSync RELAY reads these views with service_role, THROUGH the RLS
-- policies (01 S2.2/ S3.4, AD-16) — never BYPASSRLS, never a second backend.
-- One scope = one module owner; a scope NEVER joins another module's internal
-- tables (AD-7/F-03). Cross-module reads use the source module's public view
-- (0012). These views are the read surface of the sync engine.
--
-- RELAY OPERATIONAL = WAVE 1 (03 S8.1). Wave 0 ships these views + RLS.
-- =============================================================================

-- Each scope view is bound to a single user via the authenticated token the
-- relay presents per scope; the module's RLS (user_id = auth.uid()) isolates
-- rows. security_invoker=on keeps the caller's policies in force.
--
-- Idempotent: CREATE OR REPLACE VIEW (relaunched at wave 1).
-- Tracking: supabase/migrations/0015_powersync_relay_views.sql (applied live
-- 2026-09-26 via MCP; relay.sql = SSoT, 0015 = additive tracking file).

-- Identity scope (owner Identity) — 1 module, no join
CREATE OR REPLACE VIEW v_identity_scope WITH (security_invoker = on) AS
SELECT * FROM user_context;

-- Productivity scope (owner Productivity).
-- NOTE: heterogeneous UNION-ALL across Productivity's own tables keeps a
-- single-module scope (AD-7/F-03: no cross-module JOIN); the local mirror
-- materializes per-table (tasks, milestones, projects, goals, habits,
-- routines, focus_sessions, decisions, calendar_events) — see schema.json.
CREATE OR REPLACE VIEW v_productivity_scope WITH (security_invoker = on) AS
SELECT id, user_id, 'tasks' AS table_name, subject, description, status,
       priority, importance, due_at, dependencies, evidence_refs,
       crdt_added, crdt_removed, local_mutation_id, created_at, updated_at
FROM tasks
UNION ALL SELECT id, user_id, 'projects', name, description, status,
                 3, 3, end_date, '[]'::jsonb, '[]'::jsonb,
                 crdt_added, crdt_removed, local_mutation_id, created_at, updated_at
           FROM projects
UNION ALL SELECT id, user_id, 'goals', title, description, status,
                 3, 3, target_date, '[]'::jsonb, '[]'::jsonb,
                 crdt_added, crdt_removed, local_mutation_id, created_at, updated_at
           FROM goals
UNION ALL SELECT id, user_id, 'subtasks', title, NULL, status,
                 3, 3, NULL, '[]'::jsonb, '[]'::jsonb,
                 crdt_added, crdt_removed, local_mutation_id, created_at, updated_at
           FROM subtasks;

-- Learning scope (owner Learning)
CREATE OR REPLACE VIEW v_learning_scope WITH (security_invoker = on) AS
SELECT id, user_id, title, description, subject_id, status, progress_pct,
       crdt_added, crdt_removed, local_mutation_id, created_at, updated_at
FROM courses;

-- Knowledge scope (owner Knowledge) — NO embedding column mirrored (03 S4.2)
CREATE OR REPLACE VIEW v_knowledge_scope WITH (security_invoker = on) AS
SELECT id, user_id, kind, label, summary, body, parent_id, domain_path,
       source_ref_ids, crdt_added, crdt_removed, local_mutation_id,
       created_at, updated_at
FROM semantic_nodes;

-- Progress scope (owner Progress) — LIMITED mirror (03 S4.2): skill_states
-- + progress_snapshots ONLY (no evidences/events/trends).
-- NOTE (0012 cross-module): the client PowerSync engine NEVER reads this
-- view — it reads the per-table `sync-config.yaml` streams under RLS
-- (the "LIMITED mirror" contract 03 S4.2 is a view-surface rule, not a
-- stream rule). The discovery mirror table `gaps` is populated by the
-- PROGRESS stream (`gaps WHERE user_id = auth.user_id()`, F-03 single
-- writer), not by this view. `v_progress_public` (0012) is the
-- cross-module read surface for Discovery.
CREATE OR REPLACE VIEW v_progress_scope WITH (security_invoker = on) AS
SELECT user_id, skill_id, level, freshness, confidence, last_evidence_at,
       NULL AS taken_at, NULL AS payload
FROM skill_states
UNION ALL
SELECT user_id, NULL, NULL, NULL, NULL, NULL,
       taken_at, payload
FROM progress_snapshots;

-- Discovery scope (owner Discovery). `gaps` rows are owned by Progress;
-- the mirror reads them through the PROGRESS module's public view
-- (v_progress_public, 0012) — cross-module read via the source public
-- view, never a direct internal JOIN (AD-7/F-03, 01 S3.4).
CREATE OR REPLACE VIEW v_discovery_scope WITH (security_invoker = on) AS
SELECT id, user_id, title, question, why_now, factual_summary, sources, kind,
       status, crdt_added, crdt_removed, local_mutation_id, created_at,
       updated_at
FROM discovery_items;

-- Artifact scope (owner Artifact) — metadata + r2_key ONLY (files in R2)
CREATE OR REPLACE VIEW v_artifact_scope WITH (security_invoker = on) AS
SELECT id, user_id, kind, title, mime_type, r2_key, size_bytes,
       source_event_id, status, crdt_added, crdt_removed, local_mutation_id,
       created_at, updated_at
FROM artifacts;

-- Integrations scope (owner Integrations)
CREATE OR REPLACE VIEW v_integrations_scope WITH (security_invoker = on) AS
SELECT id, user_id, name, trigger_, action, enabled, crdt_added, crdt_removed,
       local_mutation_id, created_at, updated_at
FROM automations;

-- Ascent scope (owner Ascent, wave 3, W3-E2). READ-ONLY mirror surface:
-- Slide-Ascent renders the current path offline. No cross-module JOIN
-- (the path is self-contained JSONB in ascent_paths — check-view-joins
-- stays green).
CREATE VIEW v_ascent_scope WITH (security_invoker = on) AS
SELECT * FROM ascent_paths;

-- GoalProject scope (owner Progress, wave 3, HEPHAESTUS). The Goal Dashboard
-- renders offline (goal-dashboard-ui.md S8): the whole GoalProject document
-- (subGoals + feature placements + timeline + progress) travels in the JSONB
-- `goal` column of `user_goals`. READ-ONLY mirror surface; the agent composes
-- server-side (AD-7), the device only reads the composition + progress.
CREATE OR REPLACE VIEW v_user_goals_scope WITH (security_invoker = on) AS
SELECT id, user_id, goal, crdt_added, crdt_removed, local_mutation_id,
       created_at, updated_at
FROM user_goals;

-- service_role may read every scope view (the relay); RLS still bounds rows.
GRANT SELECT ON v_identity_scope, v_productivity_scope, v_learning_scope,
                 v_knowledge_scope, v_progress_scope, v_discovery_scope,
                 v_artifact_scope, v_integrations_scope, v_ascent_scope,
                 v_user_goals_scope
  TO service_role;
