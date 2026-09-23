# PROMPT — MINERVA (Wave 0, Supabase + R2 + PowerSync)

Tu es MINERVA. Creer le backend complet : Supabase + R2 + PowerSync.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Lires AVANT de coder :
1. _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/01-backend.md
2. _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/03-sync.md
3. docs/backend/supabase.md
4. docs/cloudflare/r2.md
5. docs/architecture/data-ownership-matrix.md
6. docs/architecture/secrets-checklist.md (valeurs dans .env.local)

## Infos pratiques :
- Supabase URL : dans .env.local (SUPABASE_URL)
- R2 : 2 buckets (aurora-artifacts-prod, aurora-media-prod), EU
- PowerSync : URL dans .env.local (POWERSYNC_URL)
- Les secrets sont dans .env.local + GitHub Secrets

## Taches (1 commit par tache) :

### Commit 1 : Supabase migrations
- supabase/migrations/ : schema SQL
- Tables : events (AD-9), job_queue + job_logs (G-M4 full shape),
  user_context, + toutes les tables modules (01 S4.1-4.7)
- RLS policies par module (01 S2.2) : chaque module voit SEULEMENT ses tables
- Vues publiques par module (03 S5.4)
- psql : migrations passent

### Commit 2 : PowerSync schema
- PowerSync schema (03 S4.2 mapping) : quelles tables sont synced
- Config relay (connecte au Supabase)
- Test : 1 row insert -> PowerSync sync -> SQLite local

### Commit 3 : R2 config
- scripts/r2-presign.ts : genere un presigned URL (get 15min, upload 5min)
- Test : upload 1 file -> R2 -> download via presigned URL
- Security : R2 API token dans .env.local (PAS dans le code)

### Commit 4 : Cron + Edge Functions skeleton
- supabase/config.toml : pg_cron setup
- Edge Functions (stubs) : fn-job-dispatcher, fn-import-course,
  fn-notifications, fn-agent-run
- Chaque stub : lire les secrets de l'env, logger, return ok
- Test : curl l'edge function -> 200

COMMIT MESSAGES :
"wave0/minerva: Supabase migrations + RLS + public views"
"wave0/minerva: PowerSync schema + relay config"
"wave0/minerva: R2 presigned URLs + upload/download test"
"wave0/minerva: Cron + Edge Functions skeleton"
