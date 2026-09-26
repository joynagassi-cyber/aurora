-- =============================================================================
-- Aurora — Migration 0018: keep_alive heartbeat (Free-tier anti-pause)
-- (01 §5.2 + docs reference: "Comment Maintenir un Projet Supabase Actif sur
-- le Plan Gratuit (Guide Complet 2026)" — article inforeole, 16 juillet 2026)
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
-- Pas de RLS (table sans user_id ; le heartbeat s'exécute en tant que
-- superuser du scheduler pg_cron, pas en tant que authenticated user) —
-- la table ne contient JAMAIS de données utilisateur, uniquement un
-- timestamp de ping. Le job s'exécute quotidiennement à 00:00 UTC.
--
-- APPLICATION STATUS (2026-09-26)
--   Appliqué au live Supabase DEV via le Supabase MCP (`execute_sql`,
--   block-by-block) :
--     1. CREATE TABLE keep_alive (collision check : 0 table existante)
--     2. INSERT amorçage (1 ligne, last_ping = 2026-09-26 21:23:55 UTC)
--     3. SELECT cron.schedule('aurora_keep_alive', '0 0 * * *', …)
--        → jobid 7 créé, active=true
--   Vérification post-apply :
--     SELECT j.jobid, j.jobname, j.schedule, j.active, j.command
--     FROM cron.job WHERE jobname = 'aurora_keep_alive'
--     → jobid 7, schedule '0 0 * * *', active=true,
--       command = 'DELETE FROM public.keep_alive; INSERT INTO public.keep_alive
--       DEFAULT VALUES;' (verbatim SSoT)
--   NOTE (correction vs le statut plus ancien du 0014) : le rôle MCP
--   PEUT écrire dans `cron.job` (le `cron.schedule()` a réussi, contrairement
--   à l'INSERT direct `cron.job` du 0014 qui a échoué : le 0014 utilise
--   `INSERT INTO cron.job` = un chemin différent, soumis à un GRANT
--   distinct de la fonction wrapper `cron.schedule()`). Le 0014 reste donc
--   le seul à nécessiter une application dashboard-side manuelle.
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

-- Amorçage (le job overwrite une seule ligne : une contrainte UNIQUE sur
-- une colonne impossible n'existe pas — on s'appuie sur la logique DELETE
-- + INSERT du command body, pas sur une PK)
INSERT INTO keep_alive (last_ping) VALUES (now());

-- 2. Job pg_cron quotidien 00:00 UTC (le `0 0 * * *` du scheduler
--    pg_cron, exécuté en `public` par défaut)
SELECT cron.schedule(
  'aurora_keep_alive',
  '0 0 * * *',
  $cmd$
    DELETE FROM public.keep_alive;
    INSERT INTO public.keep_alive DEFAULT VALUES;
  $cmd$
);

-- Vérification post-apply (exécuter dans le même bloc, ou à la main)
-- SELECT last_ping FROM keep_alive LIMIT 1;
-- SELECT j.jobname, j.schedule, j.active
-- FROM cron.job j WHERE j.jobname = 'aurora_keep_alive';
