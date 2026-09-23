-- =============================================================================
-- Aurora Wave 0 — Migration 0012: Public module views (01 §3.4, 03 §5.4)
-- Inter-module reads happen ONLY through the SOURCE module's public view
-- (one scope = one owner module; a view NEVER joins another module's
-- internal tables, AD-7/F-03). The PowerSync relay reads these views with
-- service_role THROUGH RLS.
--
-- Read-only views: each exposes the public shape of its owner module's
-- tables, scoped by user_id. No cross-module JOINs inside a view.
-- =============================================================================

-- Productivity public view (owner Productivity) — read by Progress/Agent
CREATE VIEW v_productivity_public WITH (security_invoker = on) AS
SELECT id, user_id, subject, status, priority, due_at, updated_at FROM tasks
UNION ALL SELECT id, user_id, name AS subject, status, 0 AS priority,
                 null, updated_at FROM projects;
-- (illustrative: keeps a single owner module's tables; no cross-module JOIN)
GRANT SELECT ON v_productivity_public TO service_role;
GRANT SELECT ON v_productivity_public TO authenticated;

-- Progress public view (owner Progress) — read by Discovery (gaps analysis)
CREATE VIEW v_progress_public WITH (security_invoker = on) AS
SELECT g.id, g.user_id, g.kind, g.description, g.status, g.evidence_refs
FROM gaps g
WHERE g.user_id IS NOT NULL;
GRANT SELECT ON v_progress_public TO service_role;
GRANT SELECT ON v_progress_public TO authenticated;

-- Knowledge public view (owner Knowledge) — read by Agent (context)
CREATE VIEW v_knowledge_public WITH (security_invoker = on) AS
SELECT id, user_id, kind, label, summary, source_ref_ids, updated_at
FROM semantic_nodes;
GRANT SELECT ON v_knowledge_public TO service_role;
GRANT SELECT ON v_knowledge_public TO authenticated;

-- NOTE: `security_invoker = on` makes each view inherit the CALLER's RLS
-- policies, so a service_role reader is still bound by the owner module's
-- user_id-scoped policy — the view does not bypass RLS (01 §3.4, AD-7).
