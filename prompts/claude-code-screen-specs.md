# PROMPT — SCREENS SPEC (spécification exhaustive écran par écran, zéro inférence)

Tu es l'agent design-spec (Claude Code, track design). Mission : produire la
documentation NORMATIVE écran par écran de l'app Aurora — inventaire complet,
aucun écran laissé au déduit — pour que tout changement futur (widget,
micro-animation, modal, formulaire, style de pagination, transition, fluidité)
parte d'un spec FIXE, élément par élément. C'est le socle du chantier UI
premium ; ce prompt est DOCS-ONLY.

## Travail dans : C:\Users\joyda\dyad-apps\aurora-2

## Scope (non destructif, AD-13)
- Extensions seulement : nouveaux fichiers sous `docs/design-system/screens/`
- 1 lot = 1 commit = 1 rollback, préfixe `cc/screens: <module>`
- Aucun code modifié → le gate (pnpm typecheck / lint / test /
  check-boundaries.sh / check-rls.sh / check-view-joins.ts) reste vert par
  construction ; à vérifier avant chaque commit
- Le pass DAPHNE « 50 screenshots / visual regression » (prompts/dyad-design-qa.md)
  CONSOMME ces specs — ne PAS l'exécuter ici (pas de double-travail)

## Comptage des écrans (constaté 2026-09-27, à RECONCILIER en tâche 1)
- SSoT : 05-design-system.md §4 (l.1316) = « 44 écrans », liste exhaustive
  dérivée du doc §2–18 + §13 Discovery + §18 Progress. MAIS la doc ne détaille
  que 4.1.1 → 4.9.2 (~26 slugs) ; progress / knowledge / discovery / agent /
  inbox / artifacts / settings / ascent sont CLAIMÉS dans les 44 sans détail
  écran par écran.
- Écrans ADDITIFS documentés hors 05 §4 : eisenhower (G-L5,
  docs/productivity/eisenhower.md), taches-liste / taches-detail (WDS 05.3 /
  05.5), timeline-gantt (WDS 02.5), retro-actions (WDS 06.3), discovery-sheet
  (WDS 03.3), exercises-proof (WDS 01.6), inbox-capture (WDS 04.2),
  goal-feature-detail (route /goals/:id/features/:fid, code
  apps/mobile/src/pages/goals/index.tsx:120).
- Code : 17 routes primaires (docs/mobile/navigation-and-page-composition.md,
  02 §6.1) matérialisées dans apps/mobile/src/router.tsx.
- Total candidats : ~44–46 slugs (table ci-dessous) ; avec les variantes
  (onboarding ×3, projets 4 vues Gantt/Kanban/Timeline/List, goal dashboard 5
  layouts, Pagers jour/semaine/mois) et les surfaces flottantes (BottomSheet,
  Modal, Drawer, Command palette, Toast, FAB) le périmètre dépasse 50.
- Tâche 1 = inventaire réconcilié + POLITIQUE DE COMPTAGE figée (slugs vs
  variantes vs surfaces) + arbitrage du delta 44 SSoT vs N candidats (OQ n°1).

## Inventaire candidat FIXE (slug · module · source SSoT · statut)

| # | slug | module | route (code) | SSoT | statut |
|---|------|--------|--------------|------|--------|
| 1 | onboarding (3 sous-écrans max) | Onboarding | boot, avant /home | 05 §4.1.1 + WDS 04.1 | détaillé |
| 2 | home (welcome, AD-14, 7 slots) | Home | /home | 05 §4.1.2 + goal-dashboard-ui S1 | détaillé |
| 3 | projets-liste | Productivité | /projects | 05 §4.3.1 | détaillé |
| 4 | projets-detail (4 vues Gantt/Kanban/Timeline/List + milestones + templates) | Productivité | /projects/:id | 05 §4.3.2 | détaillé |
| 5 | kanban | Productivité | /projects (vue) | 05 §4.3.3 + WDS 05.4 | détaillé |
| 6 | timeline-gantt | Productivité | /projects (vue) | WDS 02.5 | additif |
| 7 | objectifs-liste | Productivité | /goals | 05 §4.3.4 + WDS 02.2 | détaillé |
| 8 | objectifs-detail (goal dashboard, 5 layouts adaptatifs) | Productivité | /goals/:id | 05 §4.3.4 + WDS 02.3 + goal-dashboard-ui S4 | détaillé |
| 9 | goal-feature-detail | Productivité | /goals/:id/features/:fid | code (goals/index.tsx:120) + goal-dashboard-ui | additif |
| 10 | taches-liste | Productivité | /tasks | WDS 05.3 + catalog productivity.tasks | additif |
| 11 | taches-detail | Productivité | /tasks/:id | WDS 05.5 | additif |
| 12 | eisenhower (quadrants) | Productivité | vue quadrants | docs/productivity/eisenhower.md (G-L5) | additif |
| 13 | inbox (capture + tri) | Productivité | /inbox | catalog productivity.inbox + WDS 04.2 | additif |
| 14 | habitudes | Productivité | (habits) | 05 §4.3.5 + WDS 05.1 | détaillé |
| 15 | routines | Productivité | (routines) | 05 §4.3.6 + WDS 05.2 | détaillé |
| 16 | calendrier-jour | Productivité | /calendar | 05 §4.4.1 + WDS 04.3 | détaillé |
| 17 | calendrier-semaine | Productivité | /calendar | 05 §4.4.1 | détaillé |
| 18 | calendrier-mois | Productivité | /calendar | 05 §4.4.1 | détaillé |
| 19 | focus-mode (7 états + blocklist + DPC) | Productivité | /focus | 05 §4.4.2 + docs/focus-mode/spec.md | détaillé |
| 20 | revues-jour | Productivité | (reviews) | 05 §4.5.1 | détaillé |
| 21 | revues-semaine | Productivité | (reviews) | 05 §4.5.1 + WDS 06.1 | détaillé |
| 22 | revues-mois | Productivité | (reviews) | 05 §4.5.1 + WDS 06.2 | détaillé |
| 23 | retro-actions (journal des décisions) | Productivité | (reviews) | WDS 06.3 + 05 §4.5.1 | additif |
| 24 | analytics | Productivité | /progress? | 05 §4.5.2 + WDS 01.2/01.7 | détaillé |
| 25 | bibliotheque-ressources | Learning | /learn | 05 §4.6.1 + WDS 03.4 | détaillé |
| 26 | cours-liste | Learning | /learn | 05 §4.6.2 | détaillé |
| 27 | cours-detail | Learning | /learn/:id | 05 §4.6.2 + WDS 03.6 | détaillé |
| 28 | fiches-liste | Learning | /learn/:id (overlay) | 05 §4.7.1 | détaillé |
| 29 | fiches-detail | Learning | /learn/:id (overlay) | 05 §4.7.1 | détaillé |
| 30 | flashcards (FSRS) | Learning | /learn/:id | 05 §4.8.1 + WDS 01.3 | détaillé |
| 31 | qcm | Learning | /learn/:id | 05 §4.8.2 + WDS 01.4 | détaillé |
| 32 | exercises-proof | Learning | /learn/:id | WDS 01.6 + catalog learning.import | additif |
| 33 | mode-coach | Learning | (coach) | 05 §4.9.1 + WDS 04.4 | détaillé |
| 34 | mirror-cognitive | Learning | (mirror) | 05 §4.9.2 + WDS 01.5 + docs/learning/overview.md §21 | détaillé |
| 35 | knowledge-tree (Semantic Tree, AD-10) | Knowledge | /knowledge | docs/knowledge/overview.md | claimé, non détaillé |
| 36 | knowledge-node | Knowledge | /knowledge/:nodeId | docs/knowledge/overview.md | claimé, non détaillé |
| 37 | discovery-feed | Discovery | /discovery | docs/discovery/overview.md + WDS 03.2 | claimé, non détaillé |
| 38 | discovery-sheet | Discovery | (sheet) | WDS 03.3 + ADR §13.8 | additif |
| 39 | progress-dashboard (today/week/month/trajectory) | Progress | /progress (+/:id) | docs/progress/overview.md (18.6) | claimé, non détaillé |
| 40 | agent-chat (streaming + tool-call renderers) | Agent | /agent | docs/agent/kernel.md §13 + dyad-design-qa t.11 | claimé, non détaillé |
| 41 | slide-ascent (12 slides palette) | Ascent | /goals/:id/ascent | docs/ascent/overview.md S11–S14 + WDS S-41 | additif |
| 42 | artifacts-detail (preview par format) | Artifacts | /artifacts/:id | docs/artifacts/overview.md + WDS 03.5 | claimé, non détaillé |
| 43 | settings (sélecteur thème 10+3 + preview) | Settings | /settings | design-system/overview §6 + WDS 04.5 | claimé, non détaillé |
| 44 | not-found / feature-disabled | Shell | * | page matrix S2 + feature-registry S6 | claimé, non détaillé |

Surfaces flottantes à spécifier (transverses, 1 doc dédié + référence par
écran) : BottomSheet, Modal, Drawer, Command palette, Toast, FAB (05 §3.5)
+ AgentThinkingLoader (loader « agent réfléchit », spec ui-libraries §9.3 :
organisme organique = 3 blobs morphants (motion, GPU-only transform+
opacity) autour du PAPILLON MONO STATIQUE au centre (prop `butterfly`),
coloré aux tokens accent (10 thèmes + 3 presets), reduced-motion =
statique. INTERDIT : trois-points linéaires, spinner classique.

## Lis AVANT d'écrire (dans cet ordre)
1. _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/05-design-system.md (§2 tokens, §3 composants, §4 écrans, §5–6 thèmes)
2. docs/design-system/overview.md
3. docs/ui-libraries.md (S1 map libs, S3 interdits, S5 mobile, S6 5 états + killed, S8 décision, S9 logos)
4. docs/architecture/multi-agent-workflow.md (S3 premium UI : S3.4/S3.5)
5. docs/architecture/goal-dashboard-ui.md (AD-14 + 5 layouts + S4 esthétique)
6. docs/mobile/navigation-and-page-composition.md (17 routes + page matrix)
7. docs/features/master-feature-catalog.md (feature → screens → états offline)
8. _bmad-output/wds/C-UX-Scenarios/** (sketches UX par écran, 01–06 + ascent S-41)
9. docs/focus-mode/spec.md (7 états), docs/ascent/overview.md + implementation.md, docs/progress|knowledge|discovery|artifacts|learning/overview.md
10. Code : apps/mobile/src/router.tsx, src/pages/**, src/ux/polish.tsx, src/ux/theme-adapter.tsx ; packages/ui/src (components/ui, themes/, styles/aurora.css)

## Règles absolues (la psychologie du designer)
- Chaque écran s'ouvre par le CONTENU, pas par la mise en page : objectif
  utilisateur (1 ligne), contexte (device / moment / réseau), fréquence
  d'usage, état émotionnel cible, ERREUR LA PLUS PROBABLE de l'utilisateur,
  et ce que l'écran doit RÉSOLRE (Home AD-14 : « Qu'est-ce qui compte
  maintenant ? » ; analogie par écran).
- ZÉRO invention : toute règle écrite cite sa SSoT (doc § ou fichier:ligne).
  Pas de SSoT pour un élément = ligne `OQ-<n>` dans la section « Open
  questions » du document écran. Jamais de spec muette, jamais de
  « à décider » masqué.
- 6 états S6 (ui-libraries §6) sur CHAQUE élément async :
  loading / empty / error / success / offline / killed — pour chaque :
  texte exact, visuel (composant + tokens), CTA.
- États sémantiques d'écran (ui-libraries §6.1) : en-cours (progression
  mesurable ≠ loading), terminé (terminal positif ≠ success toast),
  échec (terminal non retryable ≠ error transitoire), 404/not-found
  (logo coloré au centre) — chaque état applicable documenté, sinon
  « N/A (raison) ».
- Tokens only (AD-17) : aucune valeur color/spacing/typo/ radius brute ;
  10 thèmes + 3 presets = spec du COMPORTEMENT par couche (05 §5.2), jamais
  de valeur par thème ; règle bloquante 05 §5.1 (thème ne touche jamais
  success/warning/danger/info).
- Motion : 150–250 ms, GPU uniquement (transform + opacity), smooth (pas
  bouncy), `prefers-reduced-motion` = static (05 §2.6 règle 2) ; transitions
  de page = spec de apps/mobile/src/ux/polish.tsx (PAGE_TRANSITION 200 ms
  ease-out) ; sur mobile : PAS de `layout` animations.
- Pagination : 1 règle par type de données — AG Grid (virtualisation,
  rowBuffer 10, maxVisibleRows 30, 60 fps Pixel 4a) pour les tables lourdes ;
  shadcn Pagination pour listes légères ; Pager jour/semaine/mois (05 §3.4)
  pour le temps. Une seule règle de pagination par écran, nommée explicitement.
- Transitions de navigation : un détail léger = BottomSheet par-dessus le tab
  courant ; un détail lourd (TopBar + sub-nav) = route push ; JAMAIS de
  changement de tab (02 §6.1) ; retour = contexte préservé (02 §6.3).
- A11y WCAG AA (05 §6.3) : contraste vérifié par thème × style neutre, focus
  visible (ring contrast), tap targets >= 44 px (56 px High Contrast),
  aria-label sur tous les icon buttons, letter-spacing 0.
- Logos S9 (ui-libraries §9, 4 fichiers, owner decision 2026-09-27) :
  version COLOREE sans fond = headers / centres de page / empty states par
  défaut ; version complète = icône d'app externe UNIQUEMENT ; version
  MONOCHROME (grayscale tonale) = cas de la matrice ui-libraries §9.1
  UNIQUEMENT (agent chat new session + thinking, états killed/désactivés,
  presets Nocturne/High Contrast, watermarks, exports docs). Chaque
  occurrence par écran listée avec sa version (colorée / monochrome / pleine).
  Page 404 / not-found = logo AURORA COLORE au CENTRE de page (état « vivant
  » avec CTA primaire = marque active, §9.1/§6.1) — c'est LA page de détail
  qui montre le travail de finition.
- 1 écran = 1 système de composants (ui-libraries S1) : chaque élément =
  composant DS (05 §3) + lib d'implémentation (shadcn/Radix, FullCalendar,
  AG Grid, motion, AntV, KaTeX, Tiptap, dnd-kit, Virtuoso). ion-calendar /
  ion-list data / ion-item forms = INTERDIT (S3) ; tout autre composant
  maison = OQ (à trancher), jamais accepté silencieusement.
- Offline-first : pour chaque écran = classe offline (master-feature-catalog)
  + dégradation AD-1 + ce qui vit sur le miroir local (AD-7/AD-12) et ce qui
  meurt (killed).
- Le document écran doit être ACTIONNABLE par un agent de build (DYAD) :
  si un widget change, le spec dit exactement quel composant, quel token,
  quel état, quelle micro-animation, quelle transition — sans qu'il ait à
  deviner.
- PRÉCISION (work of detail) : le §3 d'un écran couvre 100% de la zone —
  aucun élément « non listé » ; la SSoT est muette sur un élément = OQ
  (jamais de spec implicite). Même exigence pour §4 : chaque état de la
  matrice §6/§6.1 est documenté ou motivé N/A. C'est ce qui rend un
  changement de widget / micro-animation / modal / formulaire / pagination
  / transition PROPAGABLE sans re-décision.

## Modèle de document PAR ÉCRAN (obligatoire, sections 1–14 complètes)

```
# <slug> — <Nom écran>
Status: SPECIFIED | GAP (liste des OQ) · Module · Route · SSoT (refs précises)

## 1. Psychologie designer
Objectif utilisateur · Contexte (device/moment/réseau) · Fréquence ·
État émotionnel cible · Erreur la plus probable · Ce que l'écran RÉSOUT

## 2. Zones (header / content / footer + surfaces flottantes)
Chaque zone : liste des éléments (composant DS + lib + tokens utilisés)

## 3. Éléments / widgets
Table : élément · composant DS (05 §3) · lib (ui-libraries S1) ·
tokens · variante responsive · source SSoT

## 4. États — matrice COMPLÈTE (par élément async + par écran)
Ligne par ligne, chaque : composant (DS+lib) · tokens · texte exact · CTA ·
transition d'entrée/sortie :
- 6 S6 (ui-libraries §6) : loading / empty / error / success / offline /
  killed (G-M2) — sur chaque élément async
- Sémantiques (ui-libraries §6.1) : en-cours · terminé · échec — si
  applicables à l'écran (sinon « N/A (raison) »)
- 404 / not-found : SI l'écran est routé — page entière : logo AURORA
  coloré au CENTRE (§9.1/§6.1), message, CTA "Retour à l'accueil"
- killed sur tout flux serveur (flux mort → skeleton + "Reconnexion...")

## 5. Micro-interactions
Table : élément · action → feedback · durée (150–250 ms) · GPU only ·
comportement reduced-motion · source SSoT

## 6. Modals / BottomSheets / Drawers
Chaque surface : déclencheur, contenu, focus-trap, dismissal, transition

## 7. Formulaires
Chaque champ : lib (shadcn Form + RHF + zod), validation, clavier mobile
(Tiptap/keyboard avoidance), persistance (local-first auto-persist 02 §6.3)

## 8. Pagination
Règle unique nommée (AG Grid / shadcn Pagination / Pager) + params

## 9. Transitions
Entrée/sortie (spec polish.tsx), ouverture des détails, retour natif Android,
préservation du contexte

## 10. Thèmes
Comportement des 3 couches (neutre × 10 expressifs × 3 presets) sur cet
écran ; local adaptation V1 = Focus uniquement (OQ-15) ; règle 05 §5.1

## 11. A11y
Contraste par thème × style, focus, 44/56 px, aria-labels, SR labels

## 12. Offline
Classe offline (catalog), miroir local, dégradation AD-1, killed

## 13. Logos S9
Occurrences (header / empty state / centre) = version SANS fond, COLOREE par
défaut ; version MONOCHROME = cas de la matrice ui-libraries §9.1 (agent chat
new session + thinking, killed, presets Nocturne/High Contrast, watermarks,
exports). Chacune listée explicitement : version + raison (designer
psychology) + SSoT ref.

## 14. Open questions
Chaque OQ : n°, écran, élément, question, options envisagées, décideur
```

## Tâches (1 lot = 1 commit, AD-13)
1. `docs/design-system/screens/_inventory.md` — inventaire réconcilié
   (table slug × module × SSoT × code × classe offline × statut
   SPECIFIED/GAP) + POLITIQUE DE COMPTAGE figée (nombre final d'écrans)
   + OQ n°1 (delta 44 SSoT vs N candidats). Commit `cc/screens: inventory`
2. Lot Onboarding/Home : onboarding (+ 3 sous-écrans), home. 1 commit
3. Lot Productivité : projets-liste, projets-detail, kanban, timeline-gantt,
   objectifs-liste, objectifs-detail, goal-feature-detail, taches-liste,
   taches-detail, eisenhower, inbox, habitudes, routines, calendrier×3,
   focus-mode, revues×3, retro-actions, analytics. 1 commit
4. Lot Learning : bibliotheque, cours×2, fiches×2, flashcards, qcm,
   exercises-proof, mode-coach, mirror-cognitive. 1 commit
5. Lot Knowledge/Discovery/Progress : knowledge-tree, knowledge-node,
   discovery-feed, discovery-sheet, progress-dashboard. 1 commit
   (ce lot a le plus d'écrans « claimés non détaillés » → le plus d'OQ ;
   chaque OQ cite le doc module qui MANQUE la prescription écran)
6. Lot Agent/Ascent/Artifacts/Settings/Shell : agent-chat, slide-ascent,
   artifacts-detail, settings, not-found/feature-disabled + doc transversal
   surfaces flottantes (BottomSheet/Modal/Drawer/Command palette/Toast/FAB
   + AgentThinkingLoader). Le spec agent-chat DOIT inclure : new session =
   marque MONOCHROME statique (empty state neutre, §9.1) ; état « l'agent
   réfléchit » = AgentThinkingLoader (§9.3) en §4 (loading) + §5
   (micro-interaction de sortie 150–250 ms au premier token du streaming ;
   la marque revient colorée dans le header seulement). Le spec
   not-found/feature-disabled DOIT inclure : page 404 = logo AURORA COLORE
   au CENTRE (§9.1/§6.1), message court, CTA primaire "Retour à
   l'accueil" + CTA secondaire "Consulter l'écran parent", aucun crash /
   texte 404 nu. 1 commit
7. `docs/design-system/screens/_open-questions.md` — OQ consolidées
   (chaque OQ : écran, élément, question, options, décideur attendu) +
   `docs/design-system/screens/index.md` (sommaire cliquable des N docs).
   1 commit

## DoD par document écran
- 14 sections complètes (pas de section vide : soit SSoT citée, soit OQ)
- Chaque élément du §3 a sa ligne d'états (§4) et sa micro-interaction (§5)
- Aucun élément sans composant DS/lib (ou OQ explicite)
- 100% de la matrice des états (§4) documentée ou « N/A (raison) » —
  jamais de case vide ; 404 présent si l'écran est routé
- Monochrome : chaque occurrence de logo listée avec sa version exacte
  (colorée / monochrome / pleine) + cas §9.1 invoqué (pas d'usage ad hoc)
- Vérification : le spec de l'écran permet à DYAD de coder l'écran SANS
  lire d'autre doc

## Rapport de fin OBLIGATOIRE
- « Écrans inventoriés : N (politique de comptage : ...) »
- « Écrans SPECIFIED : X/N — liste des GAP + OQ les plus bloquantes (top 5) »
- « OQ ouvertes : N (registre : docs/design-system/screens/_open-questions.md) »
- « Gate vert : OUI/NON (typecheck + lint + test + boundaries) »
- « Commits : liste cc/screens: ... (7) »
- « SSoT manquantes : liste des docs module à compléter (progress /
  knowledge / discovery / agent / settings) pour fermer les OQ du lot 5–6 »
