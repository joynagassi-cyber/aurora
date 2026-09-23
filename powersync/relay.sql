-- =============================================================================
-- Aurora Wave 0 — PowerSync relay-scoped views (03 S5.5 / S5.4, 01 S3.4, AD-7)
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

-- Identity scope (owner Identity) — 1 module, no join
CREATE VIEW v_identity_scope WITH (security_invoker = on) AS
SELECT * FROM user_context;

-- Productivity scope (owner Productivity).
-- NOTE: heterogeneous UNION-ALL across Productivity's own tables keeps a
-- single-module scope (AD-7/F-03: no cross-module JOIN); the local mirror
-- materializes per-table (tasks, milestones, projects, goals, habits,
-- routines, focus_sessions, decisions, calendar_events) — see schema.json.
CREATE VIEW v_productivity_scope WITH (security_invoker = on) AS
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
           FROM goals;

-- Learning scope (owner Learning)
CREATE VIEW v_learning_scope WITH (security_invoker = on) AS
SELECT id, user_id, title, description, subject_id, status, progress_pct,
       crdt_added, crdt_removed, local_mutation_id, created_at, updated_at
FROM courses;

-- Knowledge scope (owner Knowledge) — NO embedding column mirrored (03 S4.2)
CREATE VIEW v_knowledge_scope WITH (security_invoker = on) AS
SELECT id, user_id, kind, label, summary, body, parent_id, domain_path,
       source_ref_ids, crdt_added, crdt_removed, local_mutation_id,
       created_at, updated_at
FROM semantic_nodes;

-- Progress scope (owner Progress) — LIMITED mirror (03 S4.2): skill_states
-- + progress_snapshots ONLY (no evidences/events/trends).
CREATE VIEW v_progress_scope WITH (security_invoker = on) AS
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
CREATE VIEW v_discovery_scope WITH (security_invoker = on) AS
SELECT id, user_id, title, question, why_now, factual_summary, sources, kind,
       status, crdt_added, crdt_removed, local_mutation_id, created_at,
       updated_at
FROM discovery_items;

-- Artifact scope (owner Artifact) — metadata + r2_key ONLY (files in R2)
CREATE VIEW v_artifact_scope WITH (security_invoker = on) AS
SELECT id, user_id, kind, title, mime_type, r2_key, size_bytes,
       source_event_id, status, crdt_added, crdt_removed, local_mutation_id,
       created_at, updated_at
FROM artifacts;

-- Integrations scope (owner Integrations)
CREATE VIEW v_integrations_scope WITH (security_invoker = on) AS
SELECT id, user_id, name, trigger_, action, enabled, crdt_added, crdt_removed,
       local_mutation_id, created_at, updated_at
FROM automations;

-- service_role may read every scope view (the relay); RLS still bounds rows.
GRANT SELECT ON v_identity_scope, v_productivity_scope, v_learning_scope,
                 v_knowledge_scope, v_progress_scope, v_discovery_scope,
                 v_artifact_scope, v_integrations_scope
  TO service_role;
