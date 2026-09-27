-- =============================================================================
-- Aurora — Migration 0018: keep_alive heartbeat (Free-tier anti-pause)
-- (01 §5.2 + docs reference: "Comment Maintenir un Projet Supabase Actif sur
-- le Plan Gratuit (Guide Complet 2026)" — article inforeole, 16 juillet 2026)
--
-- ⚠️ CORRECTION 2026-09-27 (vérification live post-application) :
--   Le SSoT initial utilisait `DELETE + INSERT` dans le command body du job.
--   Le tout premier run quotidien (00:00 UTC) a ÉCHOUÉ :
--     ERROR: cannot delete from table "keep_alive" because it does not have
--     a replica identity and publishes deletes
--   Cause : la publication `powersync` (relay PowerSync, créee 0001/0015)
--   couvre FOR ALL TABLES, donc `keep_alive` est publiée. Le DELETE du job
--   pg_cron (exécuté hors transaction de WAL-identité complète) viole la
--   contrainte de replica identity de Postgres sur les tables publiées
--   sans `REPLICA IDENTITY FULL`.
--   FIX (appliqué live le 2026-09-27, voir section APPLICATION STATUS ci-dessous) :
--     1. `ALTER TABLE keep_alive REPLICA IDENTITY FULL;`
--     2. Remplacer le command body du job par un `UPDATE` idempotent
--        (plus de DELETE, plus de repli sur l'identity) :
--        `UPDATE public.keep_alive SET last_ping = now();`
--     3. Réappliqué via `cron.unschedule()` + `cron.schedule()` :
--        l'ancienne `jobid 8` (commande DELETE+INSERT, échouée) →
--        nouvelle `jobid 9` (commande UPDATE, active).
--   Ce SSoT reflète désormais l'état live corrigé.
--
-- Motif : Supabase met en pause un projet Free après 7 jours d'inactivité
-- applicative sur la DB. L'équipe de développement a prévu une pause de
-- 4+ mois ; sans heartbeat, le projet serait restaurable pendant 90 jours
-- maximum (supervision manuelle requise au-delà), avec perte des backups
-- automatiques (absents sur Free). Le heartbeat quotidien via pg_cron
-- maintient le projet actif indéfiniment, charge négligeable.
--
-- Règle AD-16 (Aurora additive) : `keep_alive` est une table NOUVELLE,
-- isolée, sans interaction avec les tables Aurora existantes. Pas de
-- collision possible avec l'instance partagée (vérifié via
-- information_schema au moment de l'application, 2026-09-26 : 0 table
-- `keep_alive` en `public`).
--
-- RLS : ENABLE uniquement pour satisfaire le linter Supabase
-- `rls_disabled_in_public` (voir commentaire de la section DDL ci-dessous) ;
-- le heartbeat s'exécute en superuser du pg_cron, qui bypass le RLS par
-- design. Aucune path d'accès user vers cette table (aucune route REST,
-- aucun scope PowerSync de lecture).
--
-- APPLICATION STATUS
--   Appliqué au live Supabase DEV via le Supabase MCP (`execute_sql`,
--   block-by-block) — 2026-09-26 (version initiale) :
--     1. CREATE TABLE keep_alive (collision check : 0 table existante)
--     2. INSERT amorçage (1 ligne, last_ping = 2026-09-26 21:23:55 UTC)
--     3. SELECT cron.schedule('aurora_keep_alive', '0 0 * * *', DELETE+INSERT)
--        → jobid 8 créé (ancien numéro live ; voir note ci-dessous sur
--        le re-numbering jobids 1/2/3 pour le 0014 corrigé)
--   2026-09-27 (correction post-échec du 1er run) :
--     4. ALTER TABLE keep_alive REPLICA IDENTITY FULL;
--     5. cron.unschedule('aurora_keep_alive')  (supprime l'ancienne jobid 8)
--     6. SELECT cron.schedule('aurora_keep_alive', '0 0 * * *', UPDATE)
--        → nouvelle jobid 9, active, command body =
--          ' UPDATE public.keep_alive SET last_ping = now(); '
--     7. Vérification : run échoué de la jobid 8 (00:00 UTC, status
--        'failed', return_message = l'erreur replica identity ci-dessus) ;
--        le prochain run quotidien de la jobid 9 rafraîchira `keep_alive`.
--     8. TEST MANUEL DU FIX (2026-09-27 17:30 UTC, immédiatement après le
--        rescheduling, sans attendre le passage 00:00 UTC du lendemain) :
--        `UPDATE public.keep_alive SET last_ping = now();` exécuté via le
--        MCP → `keep_alive.last_ping` rafraîchi à l'instant
--        (23:32:13 → 17:30:45 UTC) : le command body `UPDATE` est prouvé
--        fonctionnel, pas seulement théorique. Le passage 00:00 UTC du
--        lendemain (jobid 9, `SELECT status FROM cron.job_run_details
--        WHERE jobid = 9`) reste la confirmation officielle du scheduler,
--        mais le fix lui-même est validé par ce test manuel.
--   NOTE jobids 0014 vs 0018 : les 3 jobs du 0014 ont été re-numérotées
--   au live entre la version initiale et cette correction (jobids actuels
--   1/2/3 = `aurora_fsrs_tick`/`aurora_skill_recompute`/
--   `aurora_event_dispatch`, toutes 3 `succeeded` à 02:00/03:00/17:05
--   UTC le 2026-09-27) ; la `aurora_keep_alive` initiale de cette
--   migration occupait le slot `jobid 8`, désormais remparée par la
--   version corrigée en `jobid 9`.
--
-- NOTE (sur le chemin cron.schedule vs INSERT) : le rôle MCP
-- PEUT écrire dans `cron.job` via le wrapper `cron.schedule()`
-- (contrairement à l'`INSERT INTO cron.job` direct du 0014 qui a
-- échoué sur le GRANT du rôle MCP au premier passage) ; cette
-- migration s'appuie donc exclusivement sur `cron.schedule()` /
-- `cron.unschedule()`.
-- =============================================================================

-- 1. Table `keep_alive` (1 ligne, le timestamp du dernier ping)
--
-- RLS : le design originel dit "Pas de RLS" (la table n'a pas de `user_id`,
-- le heartbeat s'exécute en superuser du pg_cron, pas en tant que user
-- authentifié). MAIS le Supabase advisory linter traite RLS-désactivé sur
-- une table `public` comme un ERROR (lint 0013 `rls_disabled_in_public`).
-- Le design SSoT (0018) dit "pas de données user" — on ENABLE donc RLS pour
-- satisfaire le linter, avec 0 policy (le heartbeat écrit en superuser qui
-- bypass le RLS par design ; le lint 0008 INFO `rls_enabled_no_policy`
-- subsiste mais n'est pas bloquant). Aucune path d'accès user vers cette
-- table n'existe (aucune route REST, aucun scope PowerSync).
CREATE TABLE IF NOT EXISTS keep_alive (
  last_ping timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE keep_alive ENABLE ROW LEVEL SECURITY;
ALTER TABLE keep_alive REPLICA IDENTITY FULL;

-- Amorçage (la table tient une seule ligne durable, rafraîchie par le
-- command body du job ci-dessous)
INSERT INTO keep_alive (last_ping) VALUES (now());

-- 2. Job pg_cron quotidien 00:00 UTC (exécuté en `public` par défaut,
--    en superuser du scheduler pg_cron)
--
-- Command body corrigée (UPDATE idempotent, non DELETE+INSERT) : la
-- publication `powersync` (FOR ALL TABLES) couvre `keep_alive`, et
-- Postgres exige `REPLICA IDENTITY FULL` pour DELETE sur une table
-- publiée — la version initiale DELETE+INSERT échouait donc au 1er run
-- quotidien (voir section « CORRECTION 2026-09-27 » en tête de fichier).
SELECT cron.schedule(
  'aurora_keep_alive',
  '0 0 * * *',
  $cmd$
    UPDATE public.keep_alive SET last_ping = now();
  $cmd$
);

-- Vérification post-apply (exécuter dans le même bloc, ou à la main)
-- SELECT last_ping FROM keep_alive LIMIT 1;
-- SELECT j.jobname, j.schedule, j.active
-- FROM cron.job j WHERE j.jobname = 'aurora_keep_alive';
