---
name: Aurora
description: "Comportement UX de la suite Aurora (Phase 1 mobile-only Android) — IA, navigation, 5 états, 17 pages, 6 product modes, 8 effets de désactivation, invariant Home AD-14, commande palette. SSoT = pack 02 S3-S7 + docs/mobile/ + docs/frontend/ ; ce EXPERIENCE.md est le pont comportemental pour les agents."
status: draft
sources:
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/02-frontend.md (S3-S7, S9)
  - _bmad-output/architecture/architecture-aurora-2026-09-21/dimensions/04-mobile.md (S3, S4)
  - docs/mobile/navigation-and-page-composition.md
  - docs/mobile/context-preserving-navigation.md
  - docs/frontend/page-contracts.md
  - docs/frontend/feature-registry.md
  - _bmad-output/ux-designs/ux-aurora-2026-09-23/DESIGN.md (visual identity)
updated: 2026-09-23
---

# Aurora — EXPERIENCE.md (pont comportemental, pas une SSoT)

> **Rôle de ce fichier** : réassemblage comportemental (pack 02 + docs/mobile/ +
> docs/frontend/) pour les agents d'implémentation. Ce n'est **pas** une recopie
> — le pack 02 et les docs sont les sources de vérité. Les références aux tokens
> visuels pointent vers `DESIGN.md` (syntaxe `{DESIGN.colors.primary}` / pointeurs
> `pack-05:Sx.x`).
>
> Règle de résolution des conflits : **spine AD-x > ADR v1.7 > pack 02 > ce EXPERIENCE.md.**

## Foundation

- **Form-factor** : mobile-only Android (Phase 1, doc §23.1) ; Phase 2 = adapter
  Electron ajouté, pas réécriture (ADR §23.1/§23.3, pack 04 R8).
- **UI system** : Design System `@aurora/ui` (`packages/ui`) — see `DESIGN.md`
  (Technical Calm, tokens, 9 composants data, 5 contrats AD-10).
- **UI state** : Zustand (store UI) — `pack-02:S3.1` — garde : selection,
  filters, view modes, scroll anchors, focus-mode on/off, command palette open,
  theme (`AuroraTheme` + `themeStyle`). Périmètre strict : UI state
  transitoire/cosmétique, PERSISTÉ via persist middleware. Ne contient
  **jamais** de données métier — seulement des **IDs de sélections/ancres**
  (ex. `selectedTaskId`) pointant vers les données. L'état « important »
  (sélection à re-ouvrir après kill) vit dans le **store local**
  (PowerSync/SQLite), pas dans Zustand/localStorage.
- **Data state** : `@tanstack/react-query` (`pack-02:S3.2`) porte le data state
  (tâches, cours, skills, progressions…) : source de vérité = store local
  (AD-7) ; l'UI lit, jamais ne recalcule. Query = lecture ; mutation =
  commande use-case.
- **Single-writer UI (AD-7 / F-03)** : l'UI écrit une entité locale
  **uniquement** via le repository du module owner ; **jamais de mutation
  directe d'une table SQLite** (violation = blocking finding). Le store UI
  n'émet jamais de mutation de donnée (2ᵉ writer interdit). Mutation « Agent
  complète une tâche » : le kernel (serveur) émet l'événement, le module owner
  applique, PowerSync propage, l'app **reçoit et affiche** — elle n'est jamais
  le 3ᵉ writer.

## Information Architecture

**Routing mobile-first** (`pack-02:S6`) :

- **Stack** : `IonRouter` + `react-router` v6. 5 onglets max (tab bar 44–60 px) :
  `/home` · `/tasks` · `/learn` · `/progress` · `/agent`. Détails (pas dans les
  tabs) : `/tasks/:id`, `/learn/:id`, `/progress/:id`, `/knowledge` +
  `/knowledge/:nodeId`, `/artifacts/:id`, `/inbox`, `/settings`.
- **Invariant de navigation (S6.2)** : les écrans de détail s'ouvrent
  **AU-DESSUS du tab courant** (IonModal/IonSlides), **jamais** par un
  changement de tab — l'utilisateur revient à son contexte. Le back natif
  (gesture Android) fonctionne sur toute route ; une route qui bloque le back
  **sauvegarde d'abord** (le local-first rend le formulaire auto-persisté).
  La Command Palette n'est **pas** une route (overlay,
  `commandPaletteOpen` dans le store — pas de back-stack polluée).
- **Perf (S9)** : Home **pas** lazy (écran signature, immédiat) ; tabs
  secondaires code-split ; moteurs visuels (xyflow/AntV/KaTeX/motion) lazy
  par essence, jamais au bundle initial.

**Les 15 pages** (`docs/mobile/navigation-and-page-composition.md`) :

| Page | Reached from | Purpose | Key states |
|---|---|---|---|
| Home `/home` | app boot, tous les tabs (return) | Invariant AD-14 : 7 slots fixes (agenda, prochaine action, priorité, progression critique, révisions due, Focus, suggestions Coach) | empty propre par slot, jamais skeleton web |
| Inbox `/inbox` | capture CTA partout, /inbox adjacent, OneSignal | Capture universelle + triage vers tasks/learn/settings | draft Tiptap persisté, « inbox cleared » |
| Tasks `/tasks` (+`:id` overlay) | tab, Home, Agent, /inbox, projects, goals | Liste/kanban/gantt + détail overlay (sous-tâches, Eisenhower, focus CTA) | filtre/ordre persisté, scroll restauré |
| Calendar `/calendar` | tab switch dans /tasks, Home agenda | Time-blocking, vues jour/semaine/mois | blocs de temps persistés |
| Projects `/projects` | /tasks, goals, Home | Gantt/Kanban/Timeline/List + détails (jalons, docs) | vues persistées par projet |
| Goals | /projects, Home slot progression | Hiérarchie goal→projet→tâche | snapshot lecture seule |
| Learning `/learn` (+overlays) | tab, Home due-reviews, Agent tutor | Cours → chapitres → fiches/QCM/flashcards/miroir | position de cours persistée, FSRS read-only |
| Flashcards/QCM/Exercices | /learn, Home due-reviews | Séances de révision, résultat → Progress | session résumable, deck vide = CTA générer |
| Knowledge `/knowledge` (+`:nodeId`) | tab-adjacent, Home, Learning | Arbre sémantique, provenance, « study » | branche vide = CTA import, récupération serveur seulement online |
| Discovery (feed) | /agent suggestions, Home coach | Feed de découverte, sheets → « work on this » | « research running » (état job) |
| Progress `/progress` (+`:id`) | tab, Home, bilans de session | Dashboards jour/semaine/mois/trajectoire, skill-map, gaps | « not enough data yet » (honnête) |
| Focus | Home slot 6, /tasks/:id, Agent | Session (timer ring) → bilan sheet | session non démarrée, DPC = OQ-17 |
| Artifacts `/artifacts/:id` | search, cours (exports), /agent | Preview par format → source/download/share | « loading preview / unsupported » (jamais de preview factice) |
| Agent `/agent` | tab, assistant CTA partout, Home coach | Dialogue → confirmations d'actions → écrans cibles | conversation locale, « start with an intent » |
| Settings `/settings` | Home, top bars | Thème + preview, fenêtres de silence, prefs notifs, compte | thème persisté |

> **Note** : le Screen Registry (`pack-05:S4`) détaille **19 surfaces**
> (incluant `onboarding`, `habitudes`, `routines`, `revues-*`, `analytics`,
> `bibliotheque-ressources`, `cours-*`, `fiches-*`, `flashcards`, `qcm`,
> `mode-coach`, `mirror-cognitive`) — voir
> `.working/extract-05-section4-screens.md` pour le tableau écran par écran.
> Le compteur « 17 pages » du plan de vagues = les 15 pages de la matrice
> mobile + l'`onboarding` + le `mode-coach` ; les 19 surfaces du Screen
> Registry ajoutent `habitudes` et `routines` en mode distinct.

**Entry / outgoing / incoming — par groupe** :

- **Tabs primaires** (Home, Tasks, Learn, Progress, Agent) : EP = app boot /
  onglet ; IN = tous les autres tabs (return) ; OUT = cartes/CTA vers routes
  de détail + `/knowledge`, `/inbox`, `/settings` (Home) ; retour = Home
  re-rendu frais depuis le store local (S6.2 : pas de réseau au mount).
- **Routes de détail overlays** (tasks/:id, learn/:id, progress/:id,
  knowledge/:nodeId, artifacts/:id) : OUT = sous-overlay (édition, sous-tâches,
  focus, nœuds plus profonds) ; IN = leur liste parente + Agent + deep links
  (push « task due », « review due » → `:id` exact) ; RET = retour **dans la
  liste** avec scroll + filtres conservés (ui-state persisté).
- **Routes adjacentes** (/inbox, /settings, Discovery feed) : IN = capture CTA
  sur tous les écrans + OneSignal ; OUT = triage/instructions vers les
  features ; PERSIST = drafts locaux ; states notables = « inbox cleared »,
  « research running ».
- **AGT (agent-triggered) généralisé** : Coach ouvre /agent ou /tasks/:id ;
  Planner ouvre les listes de tâches ; Tutor ouvre flashcards ciblées ;
  « capture this » ouvre /inbox ; « show me the generated X » ouvre
  /artifacts/:id.
- **DEEP** : la charge `route` du payload OneSignal (04 §3.2.5) pointe
  toujours sur une route `:id` exacte du feature owner.

## Voice and Tone

- **Microcopy** : confirmation brève (toast/inline), jamais un mur de texte.
- **Honnêteté** : `error` = message lisible (pas de stack), **retry** toujours
  disponible, différencier erreurs réseau/AI vs métier ; « not enough data
  yet » plutôt qu'un graphique vide factice ; « feature off » (marqueur)
  plutôt qu'une donnée disparue.
- **Focus** (pack 04 §4.1) : les surfaces atténuées (AD-17) + focus ring
  renforcé ; toasts différés (jamais pendant un pomodoro) ; les actions
  cloud désactivées **avec explicatif**, pas masquées.
- **Agent** : l'UI affiche la **capacité réelle** (pack 04 §4.2) — jamais le
  blocage qui n'existe pas (OQ-17).

## Component Patterns

- **Comportemental** : voir `DESIGN.md` §Components (9 composants data +
  5 contrats AD-10 + matrice d'états AD-13). Ce EXPERIENCE.md spécifie le
  **comportement**, pas le rendu visuel.
- **État de composant** : « l'état est décidé par l'app (l'écran), le rendu
  par le Design System » (`pack-05:S3.7`) ; un composant qui implémente un
  état de la matrice = 1 test de rendu par état ; un composant marqué « écran
  » = 1 test par écran qui compose l'état (pack 02 §11).
- **Détail léger vs lourd** (pack 05 S4 règle transversale) : le détail
  **léger** s'ouvre par-dessus le tab courant (`BottomSheet`) ; le détail
  **lourd** (sa propre TopBar + sub-nav) = **route push**
  (`/projects/:id?`, `/courses/:id`, …). Le retour = le contexte, jamais un
  changement de tab.

## State Patterns

**5 états UX normatifs** (`pack-02:S7` + `pack-05:S3.7` + G-M2) :

- **Liste exacte** : `loading` / `empty` / `success` / `error` / `offline`
  (+ **`killed`** = sub-état de `loading`, G-M2 wave 0 — reboot/kill
  mid-chain = re-lecture depuis les IDs de l'URL + drafts persistés, pas un
  crash).
  - `loading` : skeleton Design System, ~300 ms max, jamais un blanc plein
    (data locale = loading court).
  - `empty` : vide **actionnable** (CTA), jamais un vide mort.
  - `success` : confirmation brève (toast/inline) ; un `JobCompleted` ne
    surface que si l'app a filtré par `jobId`/`jobKind`.
  - `error` : message lisible (pas de stack), **retry** toujours
    disponible, différencier erreurs réseau/AI vs métier.
  - `offline` : bannière fine, l'app **fonctionne** (AD-7 : offline = état
    premier) ; actions cloud désactivées **avec explicatif**, pas masquées.
- **Règle AD-13** : un écran qui n'implémente pas l'un des 5 états = **DoD
  non-fermé, blocking review** (test unitaire par état par composant).

**États intermédiaires déclarés** : `hover` (déclaré pour Phase 2 Electron,
inopérant sur Android), `pressed`, `focus` (ring 2px `focus-ring`, §6),
`disabled`.

**Focus Mode** (S6 focus-spec v1.8, `pack-05:S4.4.2`) : `scheduled →
starting → prechecking → active (blocking|restricted) → paused → ending →
completed`, plus `active → interrupted → restoring → restored` et `any →
failed (restore-scheduled)` ; en UI le seul `loading` = le **bilan** de fin
(`Skeleton`) ; `empty` n'existe pas (le Focus marche sans tâche) ; `error`
= `Callout danger` sous le timer, le timer **continue**.

## Interaction Primitives

- **BottomSheet** = détail léger par-dessus le tab courant (glissement
  latéral = liste→détail, montée = sheet).
- **Command Palette** (S4) : une capacité, **5 points d'entrée** (bouton UI ·
  palette de commandes · trigger NL agent · deep link · automatisation
  Intégrations/Cron → jobs), zéro logique métier dupliquée — tous résolvent
  la **même** use-case/capacité du capability registry (la palette filtre par
  disponibilité + permissions). Exemples : « Créer une tâche » =
  `task.create`, « Ouvrir Focus » = `focus.start`, « Lancer une recherche »
  = `discovery.research`.
- **Tap targets** 44px+ (Mobile HIG) — see `DESIGN.md` §Layout & Spacing.
- **Back natif** (gesture Android) : toute route sauvegarde d'abord
  (local-first, formulaire auto-persisté).

## Accessibility Floor

- **Contraste** : ratios §6 du pack 05 ; dark = `primary` nuance 300,
  `success/danger/warning` nuance 400 (pas 500).
- **`prefers-reduced-motion` obligatoire** (AD-13 DoD) : `setReducedMotion`
  appelé au boot (pack 02 §5.5) ; tout `slow`/`normal` → `instant` ;
  `focusMode=true` : animations `slow` désactivées, toasts différés,
  transitions page `fast`→`instant`.
- **États UX** : un écran qui n'implémente pas l'un des 5 états canoniques
  = DoD non-fermé (règle AD-13, ci-dessus).
- **Écran tactile** : tap targets 44px+ ; thumb-zone bas d'écran.

## Key Flows

Flows principaux (narrés avec un protagoniste nommé ; source =
`docs/mobile/navigation-and-page-composition.md` + Feature Registry) :

1. **Capture → triage** : « Capture this » (tout écran) → `/inbox` →
   triage vers tasks/learn/settings ; draft Tiptap persisté (le back
   sauvegarde automatiquement).
2. **Agent-triggered navigation** : Coach/Planner/Tutor/Executor → `AGT` →
   /agent ou /tasks/:id ou flashcards ciblées ; deep links OneSignal →
   `:id` exacte du feature owner.
3. **Learning loop** : Home bloc 5 « 12 révisions dues » → flashcards →
   `SkillStateChanged` (AD-9) → résultat = `ProgressEvidence` (F-07) →
   Progress.
4. **Focus session** : Home bloc 6 « Démarrer le Focus » → timer ring →
   bilan (`ChartSpec` G2) → Focus « terminé ».
5. **Return destination** : back natif + « close overlay » → la page
   d'origine revient dans son état sauvegardé (scroll, filtres, branches
   ouvertes).

## Responsive & Platform

- **Mobile-only V1** (doc §23.1) : pas de responsive, marges latérales
  16px fixes. Desktop Phase 2 = adapter Electron (non-promessable en V1) ;
  les composants `packages/ui` = purs React + tokens, aucun import
  Capacitor/Electron — la Phase 2 réutilise le pack sans réécriture.
- **Écrans nommés avec variante desktop** (doc §23.2, figées) : `projets-liste`
  (desktop 2 colonnes), `calendrier-*` (semaine 7×24h), `bibliotheque-ressources`
  (30/70 liste/aperçu, `Sidebar` remplace BottomNav), `habitudes` (heatmap
  12 sem. desktop vs 7 mobile).

## Feature Registry & Product Modes (S4, figées)

**FeatureDescriptor SSoT (S1)** — 9 champs : `id`, `enabled` (ça
marche), `visible` (ça s'affiche), `routes` (préfixes 02 §6.1),
`capabilities` (ids de capacités agent), `dependencies` (validées
transitivement à l'activation), `optional`, `state` (lifecycle :
available/recommended/locked/deprecated), `offlineClass` (offline-capable /
online-required / hybrid). Les trois axes `enabled × visible × state` se
composent ; un feature `deprecated` rend + stocke toujours ses données.

**La chaîne (S2)** : Registry (SSoT `packages/domain` + seed UserContext) →
**Availability Policy** (activation = enabled ∧ dépendances satisfaites ∧
capacité plateforme présente ∧ provider présent si online-required) →
Navigation Registry → Screen Registry (inventaire 05 §4) → Agent Capability
Registry (le kernel **découvre** les capacités, n'en hardcode jamais).
Une feature est activée/désactivée par la politique de disponibilité
uniquement — **zéro `if user === Horeb`** (profil utilisateur + préférences
+ contexte déclaré pilotent tout).

**8 effets de désactivation (S6)** — tous s'appliquent, **aucun ne touche
les données** :

1. **nav** — le Navigation Registry ne rend que les entrées des features
   enabled (les routes restent définies ; le guard = registry).
2. **shortcut** — slots AD-14 + raccourcis de tabs filtrent sur
   `visible ∧ enabled` (l'invariant AD-14 se re-résout sur les slots actifs).
3. **agent** — le Capability Registry dépose les capability ids de F (le
   kernel planifie jamais un feature désactivé).
4. **dashboard** — les dashboards G2 filtrent les séries par features
   enabled ; les données historiques restent rendues (marqueur « feature
   off »).
5. **jobs** — les kinds de `job_queue` de F cessent d'être créés (Cron
   registry-driven) ; les jobs en attente finissent ou sont annulés proprement
   (`JobCompleted{cancelled}`) — pas de work orphelin.
6. **notifications** — catégories OneSignal + familles de schedules locaux
   de F sont désabonnés (état préservé pour réactivation).
7. **data** — tables AD-15 intouchées, mirrors continuent de syncer,
   rapports historiques conservent leurs données.
8. **deep links** — un deep link vers un feature désactivé rend un **état
   dédié « feature disabled »** (variante `error` de 02 §7 + CTA re-enable +
   redirection vers le tab parent), jamais un crash ou 404.

Réactivation = inverse, instantanée, **sans migration** (la désactivation
est une décision de couche vue + scheduling, jamais une opération sur les
données).

**6 product modes (S7)** — un mode = un **profil nommé** sur les registries
(features × préférences × contexte × thème × capacités), **pas 5 apps** ;
déclaré dans `UserContext` (AD-15), appliqué par la politique de
disponibilité :

1. **Core** — Productivity + Knowledge + Agent core ; Learning/Discovery
   disponibles mais dé-emphasés.
2. **Study** — Learning + Progress + Focus + Calendar en avant ;
   Discovery/Projects minimisés (données intègres).
3. **Exam period** — Learning/Progress/Focus/Calendar devant ;
   Discovery/Projects/Analytics minimisés (période **déclarée** dans le
   profil, pas un check utilisateur).
4. **Focus-heavy** — cadence Focus en hausse, suppression de notifs
   élargie (focus spec §8), slots Home re-pondérés (re-résolution AD-14).
5. **Professional** — Goals/Projects/Progress (dimension pro, ADR §18.2)
   devant ; features exam dé-emphasées.
6. **Minimal** — Inbox + Tasks + Calendar seulement ; le reste
   masqué-mais-préservé.
