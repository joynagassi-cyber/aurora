export const meta = {
  name: 'wave0-foundation',
  description: 'Wave 0 foundation : 3 builders (Achilles/Hermes/Minerva) + adversarial verification',
  phases: [
    { title: 'Build', detail: '3 sous-agents en parallele (worktrees isoles)' },
    { title: 'Verify', detail: 'verificateurs adverses par agent' },
    { title: 'Synthesize', detail: 'synthese du rapport final' },
  ],
}

const ROOT = 'C:/Users/joyda/dyad-apps/aurora-2'

const COMMON = `Contexte (valide pour les 3 agents) :
- Repo : ${ROOT} (monorepo pnpm Aurora, Wave 0 = fondation)
- Docs normatives : _bmad-output/architecture/architecture-aurora-2026-09-21/ (ADR v1.7 + Spine AD-1..AD-17) + docs/architecture/ + AI_RULES.md
- Ne PAS recopier les docs, s'y referer (par section, ex. "01 S4.1").
- 1 tache = 1 commit (messages : "wave0/<agent>: ...").
- Les secrets sont dans .env.local (git-ignored) — JAMAIS de valeur de secret en clair dans le code/commits ; process.env / env uniquement.
- pnpm 10.28, node v22.20.0, git 2.55 dispo. pnpm-workspace.yaml existe deja (ne pas casser les blocs allowBuilds / minimumReleaseAge).`

const BUILDERS = [
  {
    key: 'achilles',
    label: 'ACHILLES: workspace + domain types',
    prompt: `${COMMON}

Tu es ACHILLES. Perimetre EXCLUSIF (one-writer, AD-13) : pnpm-workspace.yaml, package.json racine, tsconfig.base.json, eslint.config.js, README.md racine, .github/ISSUE_TEMPLATE/* (a Creer si absent), packages/*/ et apps/* (squelettes : package.json, tsconfig.json, src/index.ts). Tu ne touches PAS a : .github/workflows/, scripts/ (hors eslint), supabase/, docs/, prompts/, .env.local, set-secrets.ps1.

Avant de coder, lis :
1. _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md
2. _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md
3. docs/architecture/contract-catalog.md
4. docs/architecture/data-ownership-matrix.md
5. docs/epics-stories.md (W0-E1 uniquement)
6. AI_RULES.md
7. prompts/achilles.md (ta liste canon de taches)

Taches (4 commits) :
1. "wave0/achilles: pnpm workspace (14 packages)"
   - 14 packages : packages/{domain,data,ui,platform,agent,scientific-engine,integrations,engineering-core,engineering-solvers,engineering-adapters,engineering-registry} + apps/{mobile,server}
   - (Les 4 engineering-* = decomposition interne de scientific-engine, docs/scientific-engine/engineering-intelligence-layer.md — documente ce choix dans le commit message.)
   - Chaque package : package.json (nom @aurora/<x>, deps workspace ; domain = 0 dep) + tsconfig.json (composite, references vers domain) + src/index.ts.
   - Root : package.json (scripts build/test/lint/typecheck) + tsconfig.base.json (strict) + eslint.config.js (flat, eslint 9).
   - pnpm install reussit.
2. "wave0/achilles: domain types (AD-15 SSoT, 40+ entities, 9 events, ports)"
   - packages/domain/src/ : les entities par module (liste exacte dans prompts/achilles.md commit 2), enveloppes (ApiEnvelope/ApiError/AIResponseEnvelope/AppError — contract-catalog §1), 9 evenements (payloads EXACTS de docs/architecture/data-event-job-catalog.md §4), 14 ports (contract-catalog §2), contrats AI pipeline (§3), types registres (§10), UI commands (§11), CRDT OR-Set (spine AD-7).
   - ZERo import vendor/framework dans domain (AD-1). Si un champ n'est pas explicite dans contract-catalog / data-event-job-catalog, type minimal + "// TODO(wave1)".
   - tsc --noEmit reussit.
3. "wave0/achilles: ESLint boundary rules (AD-1, AD-2, AD-10)"
   - import/no-restricted-paths : domain n'importe RIEN ; ui n'importe pas data/platform ; apps/mobile feature-slices ne croisent pas (pattern declared).
   - no-restricted-imports : les 5 moteurs AD-10 (@xyflow/react, @dagrejs/dagre, @antv/infographic, @antv/g2, katex, motion) restreints a packages/ui ; SDK fournisseurs restreints aux adapters (data, platform, integrations, scientific-engine, apps/server).
   - lint passe sur l'arborescence.
4. "wave0/achilles: CI-ready (typecheck + lint)"
   - pnpm install && pnpm typecheck && pnpm lint = exit 0.

Delivrable : les 4 commits sur ta branche de worktree. Le code doit compiler/linter avant chaque commit (pas de "a peaufiner"). Signale les contradictions doc dans le commit message, ne tranches pas seul.

Ta sortie finale doit etre : une liste des commits (hash + message), l'etat de pnpm install/typecheck/lint, et les TODO restants.`,
  },
  {
    key: 'hermes',
    label: 'HERMES: CI + boundary tests',
    prompt: `${COMMON}

Tu es HERMES. Perimetre EXCLUSIF (one-writer, AD-13) : .github/workflows/, scripts/check-*.sh, scripts/spine-*.ts, tests/ (squelettes), docs/ci/. Tu ne touches PAS a : pnpm-workspace.yaml, packages/, apps/, supabase/, docs/architecture/, prompts/, .env.local, set-secrets.ps1. (ACHILLES crele les packages en parallele — tes scripts doivent juste exister, etre corrects syntaxiquement, et fonctionnent des que le workspace existe ; ne PAS creer de fichiers packages/.)

Avant de coder, lis :
1. docs/architecture/multi-agent-workflow.md (S4, S5)
2. docs/architecture/dependency-matrix.md (S6, S15)
3. _bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md (wave 0, gate de boundaries)
4. docs/architecture/secrets-checklist.md
5. AI_RULES.md
6. prompts/hermes.md (ta liste canon de taches)

Taches (4 commits) :
1. "wave0/hermes: CI pipeline (GitHub Actions)"
   - .github/workflows/ci.yml : push = pnpm install + typecheck + lint + 4 boundary greps ; main = + tests + build + spine test. Node 22, pnpm (pnpm/action-setup + cache), concurrency group.
   - Branch protection : documente dans un README (main exige CI green + 1 review, pas de force-push) — ne pas automatiser (reglage GitHub).
2. "wave0/hermes: 4 boundary grep tests"
   - scripts/check-boundaries.sh (sh, executable) :
     G1 : vendor names (Agnes, Groq, Cerebras, OpenRouter, fal.ai, Exa, Tavily, @cloudflare/, supabase-js, powersync...) hors des 5 adapters (packages/data, packages/platform, packages/integrations, packages/scientific-engine, apps/server) = FAIL.
     G2 : secrets (sk-, gsk_, cfut_, Bearer avec valeur, API_KEY= valeur) dans le code = FAIL ; exception sanctionnee = OneSignal appKey dans capacitor.config.ts uniquement ; exclure .env.local (git-ignored), docs/, prompts/, set-secrets.ps1 (noms de vars OK, valeurs NON).
     G3 : "if user === Horeb" (hardcode user) = FAIL.
     G4 : document.querySelector dans packages/agent = FAIL (AD-12/F-09).
   - exit 0 si clean, exit 1 + message de la ligne en echec sinon. Idempotent.
3. "wave0/hermes: spine test + RLS + no cross-join"
   - Test spine : 2 "equipes" (2 fichiers tests) importent le meme type de packages/domain et produisent le meme contrat (type-check croise, pas de re-declaration) — runnable des que packages/domain existe, sinon skip with reason (pas de FAIL bloquant).
   - RLS penetration (01 S7) : scan statique des migrations supabase/migrations/*.sql (crees par MINERVA en parallele) — (a) ENABLE ROW LEVEL SECURITY sur chaque table, (b) AUCUN USING(true)/WITH CHECK(true) sans bornage, (c) FORCE ROW LEVEL SECURITY sur service_role. Static check + marker "TODO(wave1): run against live Supabase".
   - No cross-module JOIN (03 S5.4, dep S15) : scripts/check-view-joins.ts — scanne les vues PowerSync, detecte tout JOIN d'une vue de module A sur une table interne de module B (listes module→tables dans data-ownership-matrix.md + 01 S3.4). exit 1 sur violation. Parametrable.
   - Brancher les 3 dans ci.yml (commit 1) ; si un script ne cible pas encore de fichiers existants, le step doit etre continue-on-error + log explicite, pas un echec du run.
4. "wave0/hermes: CI gate (main buildable)"
   - Job "ci-gate" final sur main : pnpm install + typecheck + lint + build + test + check-boundaries.sh + check-view-joins.ts + spine test = exit 0.
   - docs/ci/gate.md : l'ordre exact + quoi faire si un gate echoue (rollback = git revert, 1 story=1 commit=1 rollback).

Delivrable : les 4 commits. Signale les contradictions doc dans le commit message. Ta sortie finale : liste des commits (hash+message), l'etat de validite YAML/script, et les TODO restants.`,
  },
  {
    key: 'minerva',
    label: 'MINERVA: Supabase + R2 + PowerSync',
    prompt: `${COMMON}

Tu es MINERVA. Perimetre EXCLUSIF (one-writer, AD-13) : supabase/ (migrations, config, functions), scripts/r2-*.ts, powersync/ (schema), et .env.local exemple si requis (pas les vrais secrets). Tu ne touches PAS a : packages/, apps/, pnpm-workspace.yaml, .github/workflows/, docs/, prompts/, set-secrets.ps1, ni les vrais secrets de .env.local.

Avant de coder, lis :
1. _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/01-backend.md
2. _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/03-sync.md
3. docs/backend/supabase.md
4. docs/cloudflare/r2.md
5. docs/architecture/data-ownership-matrix.md
6. .env.local (valeurs Supabase, R2, PowerSync — pour tes scripts de test, JAMAIS en clair dans le code)
7. prompts/minerva.md (ta liste canon de taches)

DECISIONS DEJA TRANCHEES PAR LE LEAD (applique, ne redebates pas) :
- Conventions de cles R2 = docs/cloudflare/r2.md §1 (SSoT) : {env}/{user_id}/{module}/{yyyy}/{mm}/{dd}/{ULID}[_slug].{ext}. Le 01 §5.4 est obsolete sur ce point — ne suis QUE r2.md §1. Documente ce choix dans le commit 3.
- Buckets : 1 bucket prive PAR ENV (aurora-files-{dev,staging,prod} per 01 §5.4) ; AD-16 interdit tout autre bucket. Les valeurs .env.local actuelles (aurora-artifacts-prod, aurora-media-prod) sont le deploy prod existant — utilise-les dans le script de test mais documente que la convention figee est 1 bucket/env (mapping = donnee wave-0, OQ-03).
- RLS (01 §2.2) : ENABLE ROW LEVEL SECURITY sur toutes les tables ; FORCE ROW LEVEL SECURITY sur service_role (dispatcher/PowerSync/EFs passent par les policies, JAMAIS BYPASSRLS/GRANT superuser) ; policies par defaut bornées auth.uid() ; policies service_role bornées par user_id/job_id avec justification commentee ; JAMAIS de USING(true)/WITH CHECK(true) sans bornage ; lectures inter-modules = vues publiques du module source (01 §3.4, 03 §5.4).
- Event History : 1 seule table events (ULID, payload jsonb, champ producer, retention 2 ans, audit-only PAS Event Sourcing). progress_events reste table Progress. La table calendrier Productivity = calendar_events (pour éviter collision avec events Event History — 03 §4.2 "events = calendrier uniquement") ; documente le renommage dans le commit 1.
- notes/resources = module Knowledge (03 §4.2 fige : metadata + r2_key, pas de binaire en SQLite), PAS Productivity (data-ownership-matrix en contradiction — 03 §4.2 gagne pour le schema). Flag ce point dans le commit 1.
- pg_cron : les intervalles ne sont pas figés par les docs (wave-0 data) — mets des valeurs raisonnables commentées "-- ASSUMPTION wave-0: ...", ex. fsrs-tick quotidien, event_dispatch 15 min, skill_states/progress_evidences recompute.
- model_registry + ai_usage + ai_health (01 §4.10) SONT incluses wave-0 (owner packages/data/Foundation) meme si les epics ne les citent pas.

Taches (4 commits) :
1. "wave0/minerva: Supabase migrations + RLS + views"
   - supabase/migrations/ (0001_....sql, 0002_..., croissants) :
     0001 extensions (vector, pg_cron, pgcrypto) + user_context (Identity ; theme enum AuroraTheme v2 + theme_style legacy binary ; pilote le RLS).
     0002 Productivity (01 §4.1) : tasks, projects, goals, milestones, habits, routines, focus_sessions (+ focus_app_rules/notification_policy/call_policy/session_bilan), decisions, calendar_events (recurrences MATERIELISEES pas de regle table).
     0003 Learning (01 §4.2) : courses, subjects, skills, learning_sessions, reviews, flashcards (+ FSRS due/stability/difficulty), course_imports.
     0004 Knowledge (01 §4.3, AD-6) : knowledge_documents, document_chunks (+ embedding vector + FTS/GIN), semantic_nodes, semantic_edges, semantic_bridges, node_state (AUTEUR UNIQUE), semantic_tree_version, source_refs, notes, resources.
     0005 Progress (01 §4.4) : progress_snapshots, progress_evidences (producteur UNIQUE Progress, F-07), skill_states, progress_trends, progress_events, trajectory_scenarios, gaps.
     0006 Discovery (01 §4.5) : discovery_items, discovery_source_profiles, domain_timeline.
     0007 Artifact (01 §4.6) : artifacts (metadata + r2_key), artifact_files.
     0008 Agent/Integrations (01 §4.7) : agent_runs, agent_actions, expert_skills (SERVER-ONLY, pas de miroir AD-3), integrations, automations, notification_preferences.
     0009 Event History events (01 §4.8) : ULID, payload jsonb, producer, user_id, created_at, retention 2 ans.
     0010 Jobs (01 §5.3) : job_queue (jobId ULID, kind, status pending/running/done/failed/cancelled, attempts/max_attempts/backoff_ms, due_at, user_id, idempotency_key UNIQUE = kind+hash(payload)+user_id, source_local_mutation_id ULID nullable G-M4, created_at/updated_at) + job_logs + trigger INSERT job_queue.
     0011 Registres (01 §4.10) : model_registry (statut retired possible AD-5), ai_usage, ai_health.
   - RLS sur chaque table (Enable + policies default auth.uid() + service_role bornées commentées) + vues publiques v_{module}_public (01 §3.4, 03 §5.4 ; un scope = 1 owner module, ne joint JAMAIS une table interne d'un autre module).
   - psql/Supabase CLI (si le project est joignable avec .env.local) : les migrations s'appliquent sans erreur ; sinon assure SQL valide syntaxiquement + documente l'etat (applique / en attente) dans le commit message.
2. "wave0/minerva: PowerSync schema + relay"
   - Schema PowerSync (powersync-schema.json ou vues SQL relay, selon 03 §4.2 + docs/backend/supabase.md) : mapping EXACT des tables miroirs (03 §4.2 / data-event-job-catalog §2) : tasks, milestones, projects, goals, habits, routines, focus_sessions, decisions, calendar_events, notes, resources, courses, subjects, skills, learning_sessions, reviews, semantic_nodes/edges/bridges, node_state, source_refs, skill_states + progress_snapshots UNIQUEMENT (ni progress_evidences ni progress_events ni progress_trends — server-only), discovery_items, gaps, artifacts, automations, user_context. Exclu miroir : expert_skills (server-only AD-3), events (Event History), progress_evidences/events/trends.
   - Colonnes CRDT OR-Set sur les listes qui mergent (03 §5.3/§5.4) : local_mutation_id ULID + added/removed jsonb ("-- TODO(wave1): align sur CRDT SSoT packages/domain").
   - Config relay (Supabase, PS_ADMIN_TOKEN via env, 03 §5) : relay lit les vues via service_role SOUS RLS ; 1 scope = 1 module owner. Si le relay est operationnel wave-1 (03 §8.1), livre a wave 0 le SCHEMA + config + vues (pre-requis) et documente "relay operationnel = wave 1" dans le commit message.
   - Test "1 row insert -> PowerSync -> SQLite" (03 §7 round-trip) : ecris-le ; si relay non joignable, skip-with-reason + documente.
3. "wave0/minerva: R2 presigned + test"
   - scripts/r2-presign.ts : genere presigned URLs (GET TTL 15 min, PUT/upload TTL 5 min — r2.md §2/§5 ; valeurs de .env.local : CF_ACCOUNT_ID, CF_API_TOKEN, R2_BUCKET_*, R2_S3_ENDPOINT). Convention cle = r2.md §1. Validation JWT/scope module AVANT emission (01 §5.4) ; le client ne detient JAMAIS de cle R2 (AD-3). JAMAIS de secret en clair — process.env uniquement.
   - Test upload/download : upload 1 fichier via presigned PUT -> download via presigned GET -> assert contenu. Si bucket R2 joignable avec .env.local, execute ; sinon ecris le test runnable + documente l'etat (skip-with-reason + commande exacte).
4. "wave0/minerva: Cron + Edge Functions stubs"
   - supabase/config.toml : pg_cron setup (extension + entries, intervalles = assumptions commentees §DECISIONS : fsrs-tick quotidien, event_dispatch 15 min, recompute skill_states/progress_evidences).
   - Edge Functions stubs : fn-job-dispatcher, fn-import-course, fn-notifications, fn-agent-run — chacun lit ses secrets de l'env (SUPABASE_SECRET_KEY / SUPABASE_URL / ONESIGNAL_*), loggue, retourne 200 ok (ou ApiEnvelope 01 §3.1 {ok:true,data}/{ok:false,error}). Contrats 01 §5.1 : fn-import-course {courseId,fileRefs[]} -> 202 {jobId} ; fn-agent-run {intent,contextRefs[],taskProfile} -> 202 {ok,data:{jobId}} ; fn-notifications = trigger sur events, OneSignal mobile Phase 1, respecte quiet-hours (ADR §13).
   - Test : curl sur une EF -> 200 (si project joignable) ; sinon documente (skip-with-reason + commande).

Delivrable : les 4 commits + supabase/README.md court (fichiers, comment appliquer migrations, etat relay wave0 vs wave1, commande test R2+cron). Signale les contradictions restantes dans le commit message. Ta sortie finale : liste des commits (hash+message), l'etat d'application des migrations (live / attente), et les TODO restants.`,
  },
]

const VERIFY_RULES = `Tu es un VERIFICATEUR ADVERSE. Ta mission : REFUTER les affirmations du rapport ci-dessous en testant reellement le code. Pour chaque affirmation "done/ok", execute toi-meme la verification (pnpm install, tsc --noEmit, lint, grep, psql/supabase si dispo). Ne fais PAS confiance au rapport.
- Si une verification echoue, l'echec est un finding.
- Si le code n'existe pas encore, c'est un finding (non-delivery).
- Ne modifie AUCUN fichier. Rapporte les findings avec file/line + command + resultat reussi/echou.`

const BUILD_SCHEMA = {
  type: 'object',
  properties: {
    commits: { type: 'array', items: { type: 'string' } },
    ok: { type: 'boolean' },
    notes: { type: 'string' },
  },
  required: ['ok'],
}

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          detail: { type: 'string' },
          evidence: { type: 'string' },
        },
        required: ['title', 'detail', 'evidence'],
      },
    },
    verdict: { type: 'string', description: 'CONFIRMED si les affirmations du rapport tiennent ; REFUTED si au moins un echec bloque' },
    notes: { type: 'string' },
  },
  required: ['findings', 'verdict'],
}

const SUMMARY_SCHEMA = {
  type: 'object',
  properties: {
    overall: { type: 'string', description: 'BUILDABLE / AT RISK / BLOCKED' },
    perAgent: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          agent: { type: 'string' },
          status: { type: 'string' },
          detail: { type: 'string' },
        },
        required: ['agent', 'status'],
      },
    },
    blockers: { type: 'array', items: { type: 'string' } },
    recommendedNext: { type: 'string' },
  },
  required: ['overall', 'perAgent', 'blockers'],
}

phase('Build')
log('Lancement des 3 builders en parallele (worktrees isoles)')

// Les 3 builders en parallele — barrier justifie : Verify a besoin des 3 rapports ensemble pour detecter les conflits de perimetre.
const builds = await parallel(
  BUILDERS.map((b) => () =>
    agent(b.prompt, {
      label: b.label,
      phase: 'Build',
      model: b.key === 'minerva' ? 'opus' : undefined,
      isolation: 'worktree',
      schema: BUILD_SCHEMA,
    }),
  ),
)

const buildResults = builds.filter(Boolean)
log(`Builders termines : ${buildResults.length}/3`)

phase('Verify')
log('Verification adverse par agent')

const verifyTargets = BUILDERS.map((b, i) => {
  const r = builds[i]
  if (!r) return null
  return { agent: b.key, report: r }
})

const verified = await pipeline(
  verifyTargets.filter(Boolean),
  (target) =>
    agent(
      `${VERIFY_RULES}

Rapport a verifier (agent ${target.agent}) :
${JSON.stringify(target.report, null, 2)}

Contexte projet : ${ROOT} (Wave 0, monorepo pnpm, docs dans _bmad-output/ + docs/).
Verifie : (1) les commits existent bien (git log), (2) les taches canon de prompts/${target.agent}.md sont couvertes, (3) les invariants AD-1/AD-13/AD-15 tiennent, (4) le gate "main buildable" est verifiable. Donne un verdict + findings precis.`,
      {
        label: `verify:${target.agent}`,
        phase: 'Verify',
        schema: FINDINGS_SCHEMA,
      },
    ).then((v) => ({ agent: target.agent, verdict: v?.verdict, findings: v?.findings || [], notes: v?.notes || '' })),
)

const confirmed = verified.filter(Boolean)
log(`Verification terminee : ${confirmed.length}/3 agents verifiés`)

phase('Synthesize')

const summary = await agent(
  `Tu es le LEAD de la mission Wave 0 Foundation. A partir des rapports de build + des verdicts de verification ci-dessous, produis le rapport final de session pour le user.

Contexte : ${ROOT} — Wave 0 (3 agents paralleles : achilles/hermes/minerva). L'objectif de fin de session (per prompts/session-1-wave0-foundation.md) : main buildable (tsc + lint + grep + tests), pnpm install passe, repo pret pour la vague 1.

Rapports de build :
${buildResults.map((r, i) => `--- ${BUILDERS[i]?.key || i} ---\n${JSON.stringify(r, null, 2)}`).join('\n')}

Verdicts de verification :
${JSON.stringify(confirmed, null, 2)}

Produce : un resume concis par agent, les findings critiques restants, l'etat global (buildable / a risque / bloqué), et la recommandation de prochaine action. Sois factuel, cite les preuves (commandes executees).`,
  { label: 'synthese', phase: 'Synthesize', schema: SUMMARY_SCHEMA, effort: 'high' },
)

return {
  overall: summary?.overall,
  perAgent: summary?.perAgent,
  blockers: summary?.blockers,
  recommendedNext: summary?.recommendedNext,
  buildCount: buildResults.length,
  verifyCount: confirmed.length,
}
