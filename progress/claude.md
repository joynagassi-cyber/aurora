# WDS Progress — Claude (main loop)

## Context
- Projet : Aurora (monorepo pnpm, Capacitor/Ionic React mobile app, Supabase + PowerSync)
- Travail de session :
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

## Plan / Next
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
