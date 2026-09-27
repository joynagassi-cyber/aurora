# Prompt généraliste — « keep-alive Supabase Free tier »

> À donner à **n'importe lequel de mes agents Claude** (tous projets, toutes
> stacks) pour prévenir la mise en pause auto d'un projet Supabase Free
> après 7 jours d'inactivité. Fonctionne via le **MCP `supabase`** seul
> (pas de CLI, pas de token DB dans le shell).

---

## Prompt (copier-coller tel quel dans une session Claude)

```
Tu es un agent senior qui a accès au Supabase MCP (`mcp__supabase__execute_sql`,
connecté à mon projet Supabase via mon harnais — je ne gère aucun secret moi-même).

OBJECTIF : rendre notre projet Supabase Free **immunity à la mise en pause
auto après 7 jours d'inactivité** (pause restaurable 90 jours max, sans
sauvegarde auto sur Free — perte de données si on dépasse).

Méthode retenue (cf. article inforeole 16/07/2026 « Maintenir un projet
Supabase actif sur le plan Free ») : **heartbeat pg_cron** — 1 table
`keep_alive` (1 ligne) + 1 job quotidien à 00:00 UTC qui fait
`UPDATE last_ping = now()`. Charge négligeable, 100 % native Postgres,
aucune dépendance tierce, aucun service externe à surveiller.

⚠️ PIÈGE N°2 (au-delà du piège `cron.schedule()` ci-dessous) : si le projet
a une **publication logical replication** active (ex. relay PowerSync
`FOR ALL TABLES`, ou tout autre `PUBLICATION … ALL TABLES`), la table
`keep_alive` est automatiquement publiée. Dans ce cas, un command body
`DELETE + INSERT` **échouera** au 1er run :
`ERROR: cannot delete from table "keep_alive" because it does not have a
replica identity and publishes deletes`. Solution :
1. `ALTER TABLE keep_alive REPLICA IDENTITY FULL;` (obligatoire si
   publication active sur `ALL TABLES`)
2. Utiliser un command body `UPDATE` pur (sans DELETE) :
   `UPDATE public.keep_alive SET last_ping = now();`
   L'`UPDATE` n'a pas la même contrainte de replica identity que le
   `DELETE` — mais le `REPLICA IDENTITY FULL` reste nécessaire pour que
   les `UPDATE` soient correctement publiés aux subscribers.
Vérifier la présence d'une publication ALL TABLES en ÉTAPE 0 (ajouté
ci-dessous) pour décider du command body correct dès le départ.

---

ÉTAPE 0 — ÉTAT DES LIEUX (toujours d'abord, idempotence garantie)

a. Vérifier l'extension pg_cron (indispensable ; si absente sur le Free,
   l'installer : `CREATE EXTENSION IF NOT EXISTS pg_cron;` — le rôle MCP
   le peut dans la plupart des régions, sinon on m'indiquera que tu n'as
   pas le droit et que c'est à faire dans le dashboard SQL Editor).
   → `SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_cron';`

b. Vérifier si `keep_alive` existe déjà (sinon on crée, sinon on skip).
   → `SELECT COUNT(*) FROM information_schema.tables
       WHERE table_name = 'keep_alive' AND table_schema = 'public';`

c. Vérifier si un job anti-pause existe déjà, sous n'importe quel nom
   (par ex. `aurora_keep_alive`, `prevent_project_pause`, `keepalive_*`).
   → `SELECT j.jobid, j.jobname, j.schedule, j.active
      FROM cron.job j
      WHERE j.jobname ILIKE '%keep%' OR j.jobname ILIKE '%pause%'
         OR j.jobname ILIKE '%alive%'
      ORDER BY j.jobid;`
   Si oui → on ne crée RIEN, on vérifie seulement que `active = true`
   et que le dernier `cron.job_run_details.start_time` est < 24 h ;
   on m'indique le statut tel quel et on arrête ici.

d. Vérifier que le projet est sur le Free tier (l'option Pro ne le
   nécessite pas, mais le deployer ne fait aucun mal sur Pro non plus —
   si tu doutes, tu me demandes, tu ne supposes pas).

e. **Vérifier s'il y a une publication logical replication `ALL TABLES`**
   (piège N°2, critique) — car elle rend `DELETE` impossible sur une
   table publiée sans `REPLICA IDENTITY FULL`, et détermine quel
   command body employer (DELETE+INSERT ou UPDATE pur) dès l'ÉTAPE 2 :
   → `SELECT p.pubname, p.puballtables FROM pg_publication p;`
   Si `puballtables = true` pour n'importe quelle publication (ex.
   relay PowerSync `powersync`), l'ÉTAPE 1 doit inclure
   `ALTER TABLE keep_alive REPLICA IDENTITY FULL;` et l'ÉTAPE 2 doit
   employer le command body `UPDATE` (pas DELETE+INSERT). Sinon
   (aucune publication `ALL TABLES`), le DELETE+INSERT de base reste
   valide mais l'UPDATE pur reste aussi le choix le plus robuste —
   préférence par défaut : toujours le UPDATE.

---

ÉTAPE 1 — CRÉER LA TABLE `keep_alive`

```sql
CREATE TABLE IF NOT EXISTS keep_alive (
  last_ping timestamptz NOT NULL DEFAULT now()
);
-- Obligatoire si l'ÉTAPE 0e a détecté une publication `ALL TABLES`
-- (piège N°2) ; sinon recommandée aussi (aucun coût, robustesse future) :
ALTER TABLE keep_alive REPLICA IDENTITY FULL;
```
Règle de non-collision (instance partagée) : vérifier d'abord avec
`information_schema` que le nom n'existe pas chez un autre projet ;
en cas de collision, on change le nom en `kb_keep_alive` ou
`app_keep_alive` (le nom n'est pas normatif — seule la logique compte)
et on m'indique le nom choisi.

---

ÉTAPE 2 — CRÉER LE JOB PGC_RON (le cœur de l'immunité)

⚠️ IMPORTANT — LE PIÈGE : utiliser `SELECT cron.schedule(...)` et NON
`INSERT INTO cron.job (...)`. Le rôle MCP n'a souvent PAS le GRANT
d'écriture directe sur `cron.job`, MAIS il a le droit sur la fonction
wrapper `cron.schedule()` (c'est ce qu'on a vérifié sur Aurora : le
INSERT 0014 a échoué, le 0018 `cron.schedule()` a réussi).

```sql
SELECT cron.schedule(
  'keep_alive_daily',            -- nom du job, modifiable si collision
  '0 0 * * *',                   -- 00:00 UTC quotidien (modifiable)
  $cmd$
    UPDATE public.keep_alive SET last_ping = now();
  $cmd$
);
```
Si le nom du job existe déjà (un autre projet de l'instance partagée a
déjà créé `keep_alive_daily`), ajouter un suffixe par nom de projet
(par ex. `keep_alive_daily_acme`). Le `cron.schedule()` retourne le
jobid — on me l'indique dans le rapport final.

---

ÉTAPE 3 — AMORCAGE + VÉRIFICATION POST-APPLY (obligatoire, non optionnel)

```sql
-- amorçage (garanti 1 ligne, même si le premier 00:00 UTC est encore loin)
INSERT INTO keep_alive (last_ping) VALUES (now())
ON CONFLICT DO NOTHING;

-- vérification 1 : la table est peuplée
SELECT last_ping FROM keep_alive LIMIT 1;

-- vérification 2 : le job est bien actif dans cron.job
SELECT j.jobid, j.jobname, j.schedule, j.active, j.command
FROM cron.job j WHERE j.jobname = 'keep_alive_daily';

-- vérification 3 : la commande du job est bien celle attendue (verbatim)
-- et pas un résidu d'un autre projet (le cas partagé est fréquent)
```
On ne compte PAS le « job créé » si la vérif 2/3 ne confirme pas le
schedule `0 0 * * *` + le command body verbatim.

---

ÉTAPE 4 — FICHIER SSoT GITHUB (le commit de traçabilité)

Créer (ou mettre à jour si un fichier équivalent existe) un
`supabase/keep-alive.sql` dans le repo du projet, avec :
- l'en-tête indiquant la date d'application + jobid live
- le script intégral (table + job + amorçage)
- le bloc « APPLICATION STATUS » avec le résultat de la vérif ÉTAPE 3
- une note sur le mode de réversibilité : `SELECT cron.unschedule(
  'keep_alive_daily'); DROP TABLE keep_alive;` en cas de passage au
  plan Pro ou d'abandon définitif

Puis commit :
`git add supabase/keep-alive.sql && git commit -m "Supabase Free-tier
anti-pause: keep_alive heartbeat (pg_cron 00:00 UTC, jobid <N>)"`

---

RAPPORT DE FIN OBLIGATOIRE (1 seul message, format fixe)

    Projet Supabase : <nom d'org>/<nom de projet>
    Plan : Free / Pro
    Extension pg_cron : v<version>
    Publication ALL TABLES détectée : oui/non (si oui → REPLICA IDENTITY FULL appliqué)
    Table keep_alive : présente (1 ligne, dernier ping = <date UTC>)
    Job <nom> : jobid <N>, schedule <x>, active=<true/false>
    Commande du job (verbatim) : « UPDATE public.keep_alive SET last_ping = now(); »
    Statut final : OUI — le projet est immunisé contre la pause auto
    (NON si une des vérifs ÉTAPE 3 a échoué — indiquer laquelle)
    Réversibilité : cron.unschedule('<nom>') + DROP TABLE keep_alive;
```

---

## Notes d'usage (pour l'humain, pas l'agent)

- **1 projet Supabase = 1 instance DB = 1 heartbeat**. Si tu as 2
  projets Free dans la même org (limite Free = 2), tu lances ce prompt
  une fois **par projet** (le MCP est connecté à une instance précise).
- **C'est idempotent** : si tu relances le prompt sur un projet qui a
  déjà le heartbeat, l'ÉTAPE 0 détecte l'existant et ne recrée rien
  (pas de doublon de job).
- **Le `cron.schedule()` ≠ `INSERT INTO cron.job`** : c'est LE piège
  documenté dans le prompt. Si l'agent te dit « échec GRANT sur
  `cron.job` », c'est qu'il a pris le mauvais chemin ; fais-le revenir
  au `SELECT cron.schedule(...)`.
- **Sur le plan Pro** : le heartbeat reste inoffensif (1 transaction
  de quelques ms/jour) mais inutile (le Pro n'est jamais mis en pause
  pour inactivité) — à ta discrétion.
- **Désinstallation propre** : `SELECT cron.unschedule('<jobname>');`
  puis `DROP TABLE IF EXISTS keep_alive;` (le projet retombe dans le
  comportement Free normal : pause auto après 7 jours d'inactivité).
- **Vérification au réveil (après ta pause de 4 mois)** :
  `SELECT last_ping FROM keep_alive;` → si la date est dans les dernières
  24 h, le heartbeat a tourné sans erreur pendant toute la durée ; si
  c'est bien plus ancien, le projet a été mis en pause quand même
  (peut-être migré/abandonné) et le job a arrêté de s'exécuter à
  l'arrêt de l'instance.
