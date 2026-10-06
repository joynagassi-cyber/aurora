# WDS Progress — Claude (main loop)

## Context
- Projet : Aurora (monorepo pnpm, Capacitor/Ionic React mobile app, Supabase + PowerSync)
- Travail de session :
  6. **Feature agentique — gaps G1–G12 (agentique-first, 2026-10-06/07)** : cartographie
     complète des features × 6 verbes (nommer/renommer/créer/supprimer/verrouiller/
     programmer) dans `docs/agent/feature-mapping-agent-gaps.md` ; plan d'implémentation
     `docs/plans/2026-10-06-feature-agentique-g1-g12.md`. Exécution Subagent-Driven,
     4 batches commités (chaque = thin emitters AD-7 + capabilities registry + tests TDD) :
     - `ebe1463` — G1–G3 scheduling de veille : `create_automation` (trigger
       schedule/event/condition, jobKind fermé AD-15, inconnu → notification),
       `update_automation` (renommer/reprogrammer/verrouiller), `delete_automation`
       (DESTRUCTIVE, ADR §5). Veille = `Automation` (table `automations`, 0008) ;
       scheduling per-user via le dispatcher (pas de nouvelles `cron.job`).
     - `e014113` — G4/G5/G12 verbes génériques : 6 rename (`goal_rename` →
       progress.goal_rename, `task_rename` → productivity.task_update patch subject,
       `event_rename`, `habit_rename`, `canvas_rename`, `skill_rename`) + 2 delete
       destructive (`task_delete`/`canvas_delete`, ADR §5) + `skill_delete`.
       Invariant pin par test : **pas de `goal.delete`** (AD-15 additif →
       `goal_abandon` uniquement).
     - `6722e37` — G6/G7 : `habit_create` (cadence daily/weekly/custom) +
       `routine_create` (anchors + steps) ; `recurring`/`recurrenceRule` ajoutés aux
       schémas `task_update`/`schedule` (materialized rows, 01 S4.1). G8 = doc NL
       (focus/bilan récurrents via `create_automation` trigger schedule, pas d'outil).
     - `2d413c1` — G9/G10/G11 : pipeline veille `runVeillePipeline` (packages/discovery,
       research → DiscoveryItem + notification job, **flag `uncertain` AD-16b jamais
       supprimé**, vendor OneSignal resté dans l'adapter AD-1) + `canvas_create`/
       `canvas_lock` + `inbox_capture`/`inbox_triage` + `ascent_read` (read-only).
       Tests agent 102→112, discovery 8→13, tous verts.
     Open items wave 3 : wiring du handler `research` du dispatcher → `runVeillePipeline`
     (TODO commenté dans `veille-pipeline.ts`) ; colonnes module-side pour `canvas.lock`
     (décision : `locked boolean` vs `blocks jsonb`) ; `goal_rename` côté module
     (`renameGoal` à ajouter si absent, pattern `updateGoal` patch title).
  4. **Feature canvas (0022)** : page `/canvas/:id` + mode canvas depuis `/agent` — blocs TipTap
     éditables, commentaires sur sélection, indexation verbatim dans le chat, bascule md ⇄ HTML.
     - Migration `supabase/migrations/0022_canvas.sql` (`canvas_sessions` + `canvas_comments`, RLS user)
       appliquée au live Supabase (policies=2, triggers=1 par table) — commit `6b1af35`.
     - Types `@aurora/domain` (`entities-canvas.ts`) + client device-side `canvas-client.ts` (AD-3,
       pattern agent-client) + test contractuel node:test — commit `86a18d1`.
     - Utils `@aurora/ui` : `markdownToHtml` (marked safe-renderer : `<script>`/`<iframe>`/handlers
       inline neutralisés, HTML brut des listes/tables échappé) + `commentAnchors` (offsets [start,end)
       sur le texte plat de la session) — vitest 9/9 — commits `41c5f0c` + fix sécurité `57363b5`.
     - Hook `useCanvasSession` / `useCanvasSave` (save debouncé 1 s + invalidation) + wiring boot
       `main.tsx` + `qk.canvas` — commit `b88e1d0`.
     - Page `apps/mobile/src/pages/canvas/index.tsx` (blocs TipTap StarterKit, menu sélection
       flottant « Indexer dans le chat » → `/agent?intent=` + « Commenter », CTA création
       `/canvas/new`, liste commentaires + suppression, UxStates 6 états) + `styles/canvas.css` —
       commit `04172c2` + fix CTA/save `269aec6`.
     - Chip « Canvas » dans `/agent` (`PenLine` → `/canvas/new`, `state.from` pour le retour) —
       commit `b028e5d`.
     - SSoT contenu = markdown par bloc ; la bascule md/HTML est une vue sur le même SSoT
       (le JSON TipTap est un intermédiaire éphémère, fallback documenté dans la page).
     - **Réorientation 2026-10-06 (demande : « le canvas n'est PAS simplement utilisé par
       l'humain, c'est l'agent qui utilise le canvas »)** : 3 outils kernel AD-7 (thin command,
       le module Canvas applique — pas de write direct, pas de job) : `canvas_read` (lecture
       blocs + commentaires), `canvas_write` (écrit un bloc md, confirmation via planStep.risk),
       `canvas_comment` (crée/répond à un commentaire ancré). Capabilities `canvas.read` /
       `canvas.write` / `canvas.comment` (scopes `canvas:read` / `canvas:write`). L'humain
       conserve l'édition StarterKit dans /canvas ; l'agent écrit par le kernel, l'humain par
       le client device — même table (AD-7 single-writer, mutation appliquée par le module) —
       commit `2d842fa`.
       **Routage serveur canvas.*** (OQ-03) : endpoint `fn-canvas` (module Canvas =
       single-writer AD-7 des tables canvas_* côté serveur, pattern rest + service key de
       fn-skills, identité par JWT jamais par le body) : `read` / `write` (patch blocs
       jsonb, blockId présent = remplacement, absent = ajout) / `comment` (réponse hérite
       l'ancage du parent). `invokeTool` dans `fn-agent-bootstrap.ts` remplacé par un
       routeur détectant les commandes `canvas.*` → `fn-canvas` ; `tools.ts` : `userId?`
       optionnel sur les 3 outils (AD-7 : le kernel injecte l'identité, l'EF ne la lit
       jamais du body) ; `planner.ts` : stepTemplates pour `canvas_read`/`canvas_write`/
       `canvas_comment` — commit `d89c3fe`.
  5. **Fixs collatéraux (typecheck 0 erreur)** : destructuring `[searchParams]` manquante dans
     `agent/index.tsx` (WIP pré-existant) + `data` du success state dans `knowledge/index.tsx`
     (commit `6e8e8cc`).
  1. **OneSignal** : config propre vérifiée via MCP (app « Aurora App » ID 6b3c35c5-e970-4e1a-a853-e616c92894a8) ;
     `fn-notifications` (Edge Function) remplacé du stub wave-0 par un vrai appel REST OneSignal v2
     (`POST /api/notifications`, `include_external_user_ids` = alias Supabase) ; `.env.example` mobile créé ;
     `config.toml` mis à jour. Split-rule 04 §3.4 intact (local = deadlines, remote = OneSignal).
  2. **Emotion design** : `docs/design-system/emotion-design.md` (345 lignes, normative) — registre « intensité
     calme », mapping couleur→émotion (tokens gelés G-H2), motion (timer jamais animé, NodePulse seul
     emphease), son (4 chimes à produire : chime-local / chime-remote / focus-end / goal-hit ; silence sur
     les erreurs), microcopy (voix 2e personne, zéro exclamation), arc émotionnel de session focus,
     10 anti-patterns.
  3. **Gestes du chat `/agent`** : 4 interactions ajoutées dans `apps/mobile/src/pages/agent/index.tsx` :
     - sélection de texte → menu flottant (Copier / Dans le chat / Ouvrir)
     - swipe horizontal du composer (gauche → sheet +, droite → cycle mode agent)
     - pull-down du composer → modale modèle (seuil 64 px, easing luxe)
     - bulles `route` peelables (deep-link 04 §3.2.5, glisser à gauche → navigate)
     - CSS dans `styles/agent.css` ; `/knowledge` accepte `?q=` (banner d'intake dans `data.css`)
  4. **Feature canvas (0022)** : page `/canvas/:id` + mode canvas depuis `/agent` — blocs TipTap
     éditables, commentaires sur sélection, indexation verbatim dans le chat, bascule md ⇄ HTML.
     - Migration `supabase/migrations/0022_canvas.sql` (`canvas_sessions` + `canvas_comments`, RLS user)
       appliquée au live Supabase (policies=2, triggers=1 par table) — commit `6b1af35`.
     - Types `@aurora/domain` (`entities-canvas.ts`) + client device-side `canvas-client.ts` (AD-3,
       pattern agent-client) + test contractuel node:test — commit `86a18d1`.
     - Utils `@aurora/ui` : `markdownToHtml` (marked safe-renderer : `<script>`/`<iframe>`/handlers
       inline neutralisés, HTML brut des listes/tables échappé) + `commentAnchors` (offsets [start,end)
       sur le texte plat de la session) — vitest 9/9 — commits `41c5f0c` + fix sécurité `57363b5`.
     - Hook `useCanvasSession` / `useCanvasSave` (save debouncé 1 s + invalidation) + wiring boot
       `main.tsx` + `qk.canvas` — commit `b88e1d0`.
     - Page `apps/mobile/src/pages/canvas/index.tsx` (blocs TipTap StarterKit, menu sélection
       flottant « Indexer dans le chat » → `/agent?intent=` + « Commenter », CTA création
       `/canvas/new`, liste commentaires + suppression, UxStates 6 états) + `styles/canvas.css` —
       commit `04172c2` + fix CTA/save `269aec6`.
     - Chip « Canvas » dans `/agent` (`PenLine` → `/canvas/new`, `state.from` pour le retour) —
       commit `b028e5d`.
     - SSoT contenu = markdown par bloc ; la bascule md/HTML est une vue sur le même SSoT
       (le JSON TipTap est un intermédiaire éphémère, fallback documenté dans la page).
     - **Réorientation 2026-10-06 (demande : « le canvas n'est PAS simplement utilisé par
       l'humain, c'est l'agent qui utilise le canvas »)** : 3 outils kernel AD-7 (thin command,
       le module Canvas applique — pas de write direct, pas de job) : `canvas_read` (lecture
       blocs + commentaires), `canvas_write` (écrit un bloc md, confirmation via planStep.risk),
       `canvas_comment` (crée/répond à un commentaire ancré). Capabilities `canvas.read` /
       `canvas.write` / `canvas.comment` (scopes `canvas:read` / `canvas:write`). L'humain
       conserve l'édition StarterKit dans /canvas ; l'agent écrit par le kernel, l'humain par
       le client device — même table (AD-7 single-writer, mutation appliquée par le module) —
       commit `2d842fa`.
       **Routage serveur canvas.*** (OQ-03) : endpoint `fn-canvas` (module Canvas =
       single-writer AD-7 des tables canvas_* côté serveur, pattern rest + service key de
       fn-skills, identité par JWT jamais par le body) : `read` / `write` (patch blocs
       jsonb, blockId présent = remplacement, absent = ajout) / `comment` (réponse hérite
       l'ancage du parent). `invokeTool` dans `fn-agent-bootstrap.ts` remplacé par un
       routeur détectant les commandes `canvas.*` → `fn-canvas` ; `tools.ts` : `userId?`
       optionnel sur les 3 outils (AD-7 : le kernel injecte l'identité, l'EF ne la lit
       jamais du body) ; `planner.ts` : stepTemplates pour `canvas_read`/`canvas_write`/
       `canvas_comment` — commit `d89c3fe`.
  5. **Fixs collatéraux (typecheck 0 erreur)** : destructuring `[searchParams]` manquante dans
     `agent/index.tsx` (WIP pré-existant) + `data` du success state dans `knowledge/index.tsx`
     (commit `6e8e8cc`).

## Plan / Next
- [ ] **Canvas wave 2** : extension `@tiptap/markdown` pour une vraie ré-sérialisation
     JSON→markdown idempotente (le fallback actuel garde le dernier markdown connu) ; e2e
     Cypress sur l'app live pour valider le flow canvas → indexation → agent.
- [ ] RLS live positif (user A lit ses propres lignes `canvas_sessions`/`canvas_comments`)
     — en attente de users dans l'instance de dev ; le test négatif (aucun leak) est passé.
- [x] **Review multi-agent du design** (workflow 17 agents, 2026-10-05) → disposition **REVISE**
- [x] Corriger le payload OneSignal REST v2 dans fn-notifications (endpoint /api/v2/{app_id}/notifications, headings, include_external_user_ids)
- [x] Corriger les 2 tokens orphelins agent.css (--aurora-accent-warning → --aurora-warning ; rgba(0,0,0,0.4) → --aurora-scrim, token ajouté + dark override)
- [x] Aligner le registre de voix (vouvoiement chat/agent, tutoiement mirror) — registerCopy() dans agent/index.tsx + règle documentée agent-chat.md §5.1
- [x] Ratifier les 4 gestes /agent dans agent-chat.md §5.1 (G1-G4 + équivalents accessibles + voix) et la ligne RET de navigation-and-page-composition.md (/agent)
- [x] Ajouter les anti-patterns A11/A12 à emotion-design §7 (fond animé sous focus ; notification S8 non muée)
- [x] Corriger le crash S7 (emotion-design §5.4 L272 : restore automatique, CTA « Fermer » uniquement, aligné sur spec focus S7 l.130-133)
- [x] Équivalents accessibles : chevron peelable = button focusable (aria-label), thinking-levels = radiogroup + roving, aria-live sur status/thinking
- [x] **OWNER : SSoT motion (option B recommandée)** — créer packages/ui/src/motion.tsx (PAGE_TRANSITION/REVEAL_TRANSITION/NODE_PULSE/SKELETON_PULSE) + sync des ~44 refs « polish.tsx l.x » (polish.tsx supprimé en ef48cb5 ; hook useReducedMotion autonome dans motion.tsx pour éviter le cycle de modules index.ts → motion.tsx → theme/provider.tsx → index.ts ; erreur TS2307 `motion/react` préexistante au niveau du package, pas introduite par le PR)
- [x] **OWNER : 4 sons d'événement** — déclarer out-of-scope V1 : `kind?: 'background' | 'event'` ajouté dans `apps/mobile/src/lib/focus-sounds.ts` (`FocusSound`) pour distinguer les chimes d'événement des fonds ambiants ; note DESIGNED_NOT_IMPLEMENTED dans `docs/design-system/emotion-design.md` §4.2 (production des WAV 44.1 kHz = vague ultérieure ; silence = cohérent avec §4.4)
- [x] **OWNER : split-rule locale** — déclarer scheduleLocal Capacitor DESIGNED_NOT_IMPLEMENTED : commentaire inline dans `packages/platform/src/local-notification.ts` (scheduleLocal/cancelLocal, 04 §7 anti-double-push test = volontairement absent tant que le bridge n'existe pas) + note dans `docs/mobile/overview.md` §6
- [x] Contrastes WCAG AA : assombrir --aurora-text-muted light (#94A3B8 → #64748B) — `apps/mobile/src/styles/tokens.css` + SSoT `packages/ui/src/themes/neutral.ts` (light) ; réserve accent-on-primary ≥18pt + vérif solara/citrus restant à faire (non bloquant V1)
- [x] Garde reduced-motion sur les 2 scrollTo smooth du chat (agent/index.tsx) — via `useReducedMotion()` de `motion/react` (déjà unifié dans theme-adapter.tsx), behavior : reduced ? 'auto' : 'smooth'
- [x] AgentThinkingLoader SSoT (@aurora/ui) à la place du fallback CSS .agent-thinking-blobs (agent.css : bloc de 45 lignes remplacé par un positionnement minimal ; `AgentThinkingLoader state="thinking" label={...}` dans agent/index.tsx)
- [x] Vérifier DpcAdapter.isBlockingAvailable() : réseau ou local ? (AD-7, focus/index.tsx l.80) — confirmé LOCAL (detection device-owner state, `cfg.isDpcActive()` — `packages/focus/src/service.ts:195`), commentaire explicite ajouté ; la lecture ne touche jamais le réseau, offline = no blocking, fallback restriction (controller.ts L6)
- [x] 19 pages SSoT (/skills + /integrations dans navigation-and-page-composition.md §1 + §2) ; badge « Offline » → « Hors ligne » (ux-states.tsx L99, home/index.tsx L111, knowledge/index.tsx L110)
- [x] `emotion-design.md` §4.1 : remplacer « Lundi doux ×2 » par les ids stables `sundown-loop` / `sundown-loop-2`
- [x] `emotion-design.md` §2.2 : note explicite sur le gel des tokens `habit-*` (05 §2.1.2, G-H2)
- [x] Miroir connaissance (AD-7) pour que /knowledge?q= fasse une vraie recherche — `apps/mobile/src/lib/knowledge-repo.ts` (lecture locale `semantic_nodes`/`semantic_edges`/`node_state` via `LocalStore` + recherche substring locale `title`/`content`, PAS FTS/vector — AD-12/F-09) ; `knowledge/index.tsx` branché dessus (arbre réel via `SemanticTreeRenderer`, banner `?q=` = résultat filtré, jamais un écran vide factice) ; `boot-data.ts` + `query-client.ts` : scope `knowledge` + `store` exposé sur le provider
- [x] Gates : check-rls.sh, check-boundaries.sh — **Tous verts** : G1 (aucun vendor hors des 5 adapters), G2 (aucun secret en clair), G3 (aucun user hardcode), G4 (pas de DOM access dans packages/agent) ; check-rls (a) RLS ENABLE sur chaque table OK, (b) aucune policy permissive injustifiée OK, (c) FORCE ROW LEVEL SECURITY présente OK — 22 migrations scannées
- [x] Vérifier le diff G2 d'exclusion de `scripts/check-boundaries.sh` (restreint à `supabase/migrations/0021_lots/*`) — confirmé : le scan G2 passe (aucun secret en clair) en excluant uniquement le lot 0021 ; les 16 fichiers 0021 qui contiennent des patterns de type `Bearer`/`sk-` (exemples de docs Anthropic/Zoom dans le seed de skills) sont tous dans `0021_lots/*` ou `0021_marketplace_skills.sql`, tous exclus de manière ciblée ; aucun autre fichier SQL ni TS/TSX/JS ne contient de valeur de secret → le verrou reste opérationnel
- [x] **Déployer Aurora sur Render (static site) pour e2e Cypress** — service `aurora` (id `srv-db2fkfflot8c73f18ug0`, slug `aurora-n9qd`), URL **https://aurora-n9qd.onrender.com**, workspace `tea-dau0b4vlot8c7396jnr0`. Build command : `corepack enable; corepack prepare pnpm@10.28.0 --activate; pnpm install --frozen-lockfile --config.minimum-release-age=0; pnpm --filter @aurora/mobile build:web`, publishPath `apps/mobile/dist`, autoDeploy on (branch `main`). 2 fixes sur le repo pour que le build passe : `worker.format='es'` dans `apps/mobile/vite.config.ts` (erreur Rollup IIFE sur le worker PowerSync, commit `80ee3b2`) + `NODE_OPTIONS=--max-old-space-size=4096` comme variable d'env du service (OOM sur `rendering chunks`, commit docs `9755979` + ajout via `update_environment_variables`, non dans la commande de build mais fonctionnel car Render exporte l'env du service sur le process de build). Build #4 (`dep-db2fup2jnfac73cnmm4g`) = **live**, HTTP 200, HTML Aurora correct (`/assets/index-*.js`). Pour Cypress : viser cette URL ; l'app reste utilisable sans `VITE_SUPABASE_URL`/`VITE_SUPABASE_PUBLISHABLE_KEY`/`VITE_POWERSYNC_URL` (fallback AD-7 : miroir local vide, pas d'erreur) — pour un build « réel » il faudra ajouter ces 3 vars via `update_environment_variables` + re-trigger deploy, les valeurs viennent de `.env.local` (AD-3 : ne jamais les committer).

## Corrections apportées au design (review multi-agent, disposition REVISE)
- **fn-notifications** : le payload OneSignal était non conforme au REST v2 réel — première notification cassée silencieusement. Corrigé (endpoint + champs).
- **agent.css** : 2 tokens orphelins = violation AD-17. Corrigé (warning + scrim).
- **Voix** : 3 violations de tutoiement en mode chat/agent (interdit §5.1). Corrigé via registerCopy().
- **Gestes** : 4 gestes documentés dans le code mais absents de la SSoT écran = « ratification fantôme ». Corrigé (agent-chat.md §5.1 + nav RET).
- **S7 crash** : le doc promettait CTA « Reprendre » alors que la spec = restore automatique. Corrigé.
- **A11** : peel = div aria-hidden (inaccessible). Corrigé (button focusable + focus-visible).

## Learned
- Le `create_segment` OneSignal MCP n'accepte que des opérateurs `OR`/`AND` comme `operator`
  (séparateurs d'expressions), pas `exists` — inutilisable pour des segments par existence d'alias.
  Le ciblage Aurora passe par `include_external_user_ids`, pas par segments OneSignal.
- TypeScript strict : `findIndex` peut renvoyer -1 → garder `Math.max(0, …)` ; les éléments d'array
  indexés par modulo peuvent être `| undefined` en noUncheckedIndexedAccess.
- **OneSignal REST v2 (docs.onesignal.com)** : endpoint = `POST /api/v2/{app_id}/notifications`
  (app_id dans l'URL, PAS dans le body) ; champs = `headings` (titre), `content` (corps),
  `include_external_user_ids`, `data` (deep-link). Auth = `Basic {REST_API_KEY}`.
- **Vérifier les claims de synthèse par un adversaire** : dans le review, 3 claims du fix plan
  avaient des prémisses fausses (ex. « replay automatique S7 » inexistant dans la spec ;
  « accent-surface/focus-ring absents » = faux, existent sous d'autres noms). Toujours
  vérifier sur le SSoT avant d'appliquer.
