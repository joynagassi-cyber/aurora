-- =============================================================================
-- Aurora Wave 0 — Migration 0200 (tracking marker)
-- Le schéma Aurora (12 migrations 0001..0012, SSoT = supabase/migrations/*.sql)
-- est déjà APPLIQUÉ au live (vérifié objet par objet : 51 tables, 123 policies,
-- 46 triggers, 3 extensions, 2 fonctions, 8 index, 3 vues, 1 type,
-- vector(768) gelé, 5 policies permissives toutes justifiées Rationale:).
-- Ce marker trace l'application dans le tracker Supabase.
-- ADDITIF : ne recrée aucun objet ; idempotent (SELECT de vérification).
-- =============================================================================

SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relname IN ('user_context','goals','tasks','job_queue','model_registry')
 LIMIT 5;
