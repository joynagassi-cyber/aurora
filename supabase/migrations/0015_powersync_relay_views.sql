-- =============================================================================
-- Aurora Wave 1 — Migration 0015: PowerSync relay-scoped views (powersync/relay.sql)
-- (01 §3.4, 03 §5.5, AD-7/F-03)
--
-- Les 8 vues v_*_scope (le « relay-scoped » SSoT = powersync/relay.sql)
-- LIENT le relay PowerSync sur les vues publiques des modules.
-- security_invoker = on : le reader conserve les policies RLS du module
-- owner (user_id = auth.uid()) — jamais de BYPASSRLS (AD-16, AD-7).
-- Un scope = un seul module owner, jamais de cross-module JOIN (F-03) ;
-- les lectures inter-modules passent par la vue publique du module source.
--
-- ADDITIF : ne modifie aucune table existante ; idempotent IF NOT EXISTS.
-- La publication `powersync` (FOR ALL TABLES, 0001 wave 0) couvre
-- automatiquement ces vues + subtasks (0013).
-- =============================================================================

-- Identity scope (owner Identity) — 1 module, pas de JOIN
CREATE OR REPLACE VIEW v_identity_scope WITH (security_invoker = on) AS
SELECT * FROM user_context;

-- Productivity scope (owner Productivity) — UNION ALL des tables propres au
-- module (pas de cross-module JOIN, AD-7/F-03)
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

-- Knowledge scope (owner Knowledge) — PAS de colonne embedding (03 §4.2)
CREATE OR REPLACE VIEW v_knowledge_scope WITH (security_invoker = on) AS
SELECT id, user_id, kind, label, summary, body, parent_id, domain_path,
       source_ref_ids, crdt_added, crdt_removed, local_mutation_id,
       created_at, updated_at
FROM semantic_nodes;

-- Progress scope (owner Progress) — miroir LIMITÉ : skill_states +
-- progress_snapshots UNIQUEMENT (pas d'evidences/events/trends).
-- NOTE (0012, cross-module) : le client PowerSync ne lit JAMAIS cette vue —
-- il lit les flux per-table de `powersync/sync-config.yaml` sous RLS. La
-- table locale miroir `gaps` est peuplée par le flux progress (`gaps WHERE
-- user_id = auth.user_id()`, F-03 single-writer), PAS par cette vue ;
-- `v_progress_public` (0012) est la surface de lecture inter-module.
CREATE OR REPLACE VIEW v_progress_scope WITH (security_invoker = on) AS
SELECT user_id, skill_id, level, freshness, confidence, last_evidence_at,
       NULL AS taken_at, NULL AS payload
FROM skill_states
UNION ALL
SELECT user_id, NULL, NULL, NULL, NULL, NULL,
       taken_at, payload
FROM progress_snapshots;

-- Discovery scope (owner Discovery)
CREATE OR REPLACE VIEW v_discovery_scope WITH (security_invoker = on) AS
SELECT id, user_id, title, question, why_now, factual_summary, sources, kind,
       status, crdt_added, crdt_removed, local_mutation_id, created_at,
       updated_at
FROM discovery_items;

-- Artifact scope (owner Artifact) — métadonnées + r2_key UNIQUEMENT
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

-- service_role (relay) peut lire chaque scope view ; RLS borne les lignes.
GRANT SELECT ON v_identity_scope, v_productivity_scope, v_learning_scope,
                 v_knowledge_scope, v_progress_scope, v_discovery_scope,
                 v_artifact_scope, v_integrations_scope
  TO service_role;
