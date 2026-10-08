# Agent IA — checklist fin de bout en bout (owner, 10-07)

> **Objectif :** rendre le chat `/agent` **fonctionnel** (intent → run → statut → résultat).
> L'app (côté device) est prête : erreurs typées, CTA « Se connecter », états honnêtes.
> Il manque **3 prérequis côté Supabase** que seul l'owner peut poser (CLI / console), hors git.

## Prérequis (à exécuter depuis la machine owner, projet lié `opagfyspdbhxthlxvlrk`)

### 1. Déployer les 6 Edge Functions (gap G1)
Les sources sont dans `supabase/functions/` (monorepo) :
```
supabase functions deploy fn-agent-run
supabase functions deploy fn-canvas
supabase functions deploy fn-import-course
supabase functions deploy fn-integrations
supabase functions deploy fn-job-dispatcher
supabase functions deploy fn-skills
```
> `fn-agent-run` est le point d'entrée du chat. Sans lui, le device reçoit une
> erreur `404` → l'app l'affiche « Le service est en cours de démarrage — réessaie ».

### 2. Configurer les secrets AGNES (P0-4)
L'agent route **toujours Agnes en primaire** (AD-5).Configurer dans
Supabase → Project → Edge Functions → Manage Secrets (ou `supabase secrets set`) :
- `AGNES_API_KEY_1`, `AGNES_API_KEY_2` (clé primaire + failover)
- `AGNES_GATEWAY_TOKEN` (Cloudflare AI Gateway, AD-5)
- Optionnels : `GROQ_API_KEY`, `OPENROUTER_API_KEY` (fallbacks)
- Optionnels (recherche) : `EXA_API_KEY`, `TAVILY_API_KEY`, `YOU_API_KEY`

> **Jamais de clé dans l'app / le bundle (AD-3).** Le device ne voit qu'un client
> publishable ; les secrets restent côté server. Un `429` n'est **jamais** contourné
> par rotation de clés (contrat AGNES).

### 3. Cœur du dispatcher (G2, ef-bundling P1-2)
`fn-job-dispatcher` doit exposer les handlers de jobs (le copy vendu
`DISCOVERY_JOB_HANDLERS` est déjà dans `supabase/functions/_shared/`).
Vérifier que le deploy du dispatcher a bien pris ce `_shared`.

## Vérification (smoke test, après 1+2+3)
1. **202 :** `POST` `fn-agent-run` avec une session auth → `202` + `agentRunId`
   (`traceId`). Pas de `404` (EF déployée), pas de `500` (secrets AGNES OK).
2. **`agent_runs` :** la ligne du `traceId` passe `running → completed`
   (ou `failed` avec cause lisible). `job_queue` / `job_logs` vides (job consommé).
3. **Dans l'app :** sur `/agent`, envoyer une intention → le compteur passe
   « En cours… » puis « C'est fait — tes changements ont été appliqués. ».
   Un artefact / une mutation observable (ex. une tâche créée) confirme le
   circuit complet (F-09 : le device ne lit que `agent_runs`).

## Si ça échoue
- `404` sur `fn-agent-run` → l'EF n'est pas déployée (étape 1).
- `500` / « AGNES not configured » → secrets manquants (étape 2).
- `401` → session absente (l'app affiche « Connecte-toi pour lancer l'agent. »
  → se connecter sur `/login` ; le kernel tourne sous le JWT du user, AD-3).
- Run `failed` → lire `job_logs` / le `result` de `agent_runs` (cause côté kernel).

> **Aucun de ces pas ne produit de commit.** Ce sont des actions owner sur le
> projet Supabase ; le code device est déjà en place et rejouable (rollback =
> redeployer l'EF précédente, jamais de contournement côté app).
