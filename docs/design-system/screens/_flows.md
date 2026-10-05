# Aurora — Interconnexion des pages (doc transversal n°6)

> **Statut** : doc transversal n°7 (avec `_inventory`, `_floating-surfaces`,
> `_open-questions`, `INDEX_REVIEW`, `_report`) · créé le 2026-09-29 ·
> **Rôle** : la logique qui relie les 44 docs écrans — qui ouvre qui, ce qui
> est partagé entre pages, et ce qui doit rester cohérent d'un écran à l'autre.
>
> **Sources SSoT (zéro invention)** :
> - `docs/mobile/navigation-and-page-composition.md` §2 (page matrix) + §3 (context-preserving)
> - `apps/mobile/src/router.tsx` (17 routes figées + tabs + details-over-tab + tab-adjacent + fallback `*`)
> - `ARCHITECTURE-SPINE.md` — AD-7 (Local-first sync), AD-9 (Targeted events),
>   AD-13 (Contract Packs), AD-14 (Home invariant), AD-15 (Shared domain types),
>   AD-17 (3-layer theming)
> - `_bmad-output/.../05-design-system.md` §3.5 l.754-759 (règles de stacking
>   des surfaces flottantes)
>
> Chaque règle cite sa SSoT ; si la SSoT est muette → OQ dans §8.

---

## 1. Taxonomie des transitions

**Toutes les transitions de page partagent 2 contraintes globales** :

| Contrainte | SSoT | Détail |
|---|---|---|
| **Durée + courbe** : 200ms, `ease-out`, GPU-only (transform/opacity) | `apps/mobile/src/ux/motion.tsx @aurora/ui` `PAGE_TRANSITION` | Toutes les entrées/sorties de page (push, overlay, tab-switch) ; `prefers-reduced-motion` = statique (in)stantané. |
| **Stacking z-index des surfaces flottantes** | 05 §3.5 l.754-759 | contenu 0 < TopBar/BottomNav 10 < sheet/menu/drawer 30 < Modal 40 < Toast 50 < Splash 60 — un écran ne définit jamais son propre z-index ; il consomme ces valeurs. |
| **Details open OVER the current tab** (jamais de switch de tab pour ouvrir un détail) | `navigation-and-page-composition.md` §1 l.10-15 · `router.tsx` l.65-71 | Les overlays (`/tasks/:id`, `/learn/:id`, `/progress/:id`, `/knowledge`, `/knowledge/:nodeId`, `/artifacts/:id`) s'ouvrent **par-dessus** le tab actif ; le retour ferme l'overlay et **révèle le tab en dessous** (ion-back ou native back, 02 §6.3). |
| **Back** : le retour natif (geste Android) fonctionne sur **chaque** route ; une route qui bloque le back **sauve d'abord** | 02 §6.3 · `navigation-and-page-composition.md` §1 l.13-15 | Le local-first (AD-7) rend le form state auto-persisté ; le back n'a jamais de modale « perdues modifications ? » — l'état est déjà persisté. |
| **404 / feature-disabled** : le fallback `*` du router n'est **pas** un crash — c'est l'état « feature disabled » (feature-registry S6) | `router.tsx` l.100-102 · `not-found.md` §14 OQ-48 | Un deep link vers une feature masquée (AD-13 visibility, `navigation-and-page-composition.md` §4) rend `NotFoundPage` — jamais un écran blanc. |

### Les 6 mécanismes de transition (tableau)

| # | Mécanisme | Quand | Composant | SSoT |
|---|---|---|---|---|
| T1 | **Tab switch** (1 des 5 tabs primaires) | navigation principale, retour « Home = fresh render from local store » (AD-7, pas de network on mount) | `Shell` + tab bar 44-60px | 02 §6.1 · `router.tsx` l.57-63 · `navigation-and-page-composition.md` §1 |
| T2 | **Push détails over tab** (IonModal/IonSlides) | ouvrir `/tasks/:id`, `/learn/:id`, `/progress/:id`, `/knowledge`, `/knowledge/:nodeId`, `/artifacts/:id` **par-dessus** le tab courant | IonModal / IonSlides (overlay, le tab reste sous-jacent) | `router.tsx` l.65-71 · 02 §6.1 |
| T3 | **Route tab-adjacent** (pas un overlay, une vraie page) | `/inbox`, `/settings` — routes à côté des tabs, pas au-dessus d'un tab | page normale avec back | `router.tsx` l.73-75 |
| T4 | **Vue interne** (pager jour/semaine/mois, switch de vues list/kanban/gantt/timeline) | au sein d'**un même slug** (pas une nouvelle route) | component state + ui-state store (persistant, 02 §3.2) | 05 §3.4 `Pager` · `navigation-and-page-composition.md` §2 col. PERSIST |
| T5 | **Command palette** (search global, 5 entry points) | recherche globale, ouverture depuis UI/palette/agent/deep link/automation | shadcn Command (ui-libraries S1) | ui-libraries S1 l.28 · `bibliotheque-ressources.md` §14 OQ-01 (la recherche **locale** AD-7 ≠ la palette **globale**) |
| T6 | **Redirect / fallback** | deep link vers feature masquée ou inconnue → `NotFoundPage` | `*` route | `router.tsx` l.100-102 · `not-found.md` |

> **Note** : T1-T3 = changements de **route** (le router sait) ; T4 = changement
> **in-page** (le router ne sait pas, c'est du state ui-state) ; T5 = un
> **trigger global** qui aboutit à T2 ou T3 ; T6 = **fin de route**.

---

## 2. Matrice écran → surfaces flottantes ouvertes

Chaque doc écran a un §6 (Modals/Sheets) qui liste les surfaces flottantes
qu'il **ouvre** (et jamais qui il les **ferme** — une surface est ouverte par
un seul écran, et fermée par elle-même / par le back). Ce § est l'extraction
transversale de tous les §6.

| Écran (slug) | Surfaces flottantes ouvertes (depuis son §6) | SSoT §6 de l'écran |
|---|---|---|
| `calendrier-jour` / `calendrier-mois` / `calendrier-semaine` | BottomSheet de détail (événement pur) + BottomSheet de création (`DateField` pré-rempli) | §6 de chaque doc |
| `taches-detail` | Modal / BottomSheet de sous-tâches + callout de replanification | §6 `taches-detail.md` |
| `cours-detail` | Overlay → fiche / QCM / flashcards (T2, pas une floating surface distincte) | §6 `cours-detail.md` |
| `fiches-liste` / `fiches-detail` | BottomSheet de navigation fiches | §6 |
| `flashcards` | IonModal (overlay du `/learn/:id`) | §6 + `router.tsx` l.97-98 |
| `discovery-sheet` | **Est** une BottomSheet (pas un écran — cf. `_floating-surfaces.md`) | `discovery-sheet.md` §6 |
| `kanban` / `projets-detail` | Modal de création projet + BottomSheet de milestone | §6 |
| `agent-chat` | **Aucune** — le run se lit inline (streaming), pas en modal | §6 `agent-chat.md` (A-07) |
| `home` | **Aucune** — les 7 slots AD-14 sont des cartes navigables (T2), pas des modales | §6 `home.md` |
| `settings` | Modal de confirmation (destructive ops AD-12) + preview de thème | §6 `settings.md` |
| `focus-mode` | BottomSheet de bilan (`focusBilan` ChartSpec, 05 §3.6.9) | §6 `focus-mode.md` |
| `inbox` | BottomSheet de capture (média optionnel) + triage → T2 vers `/tasks/:id` | §6 `inbox.md` |
| `artifacts-detail` | Modal de partage (export par format, ADR §16) | §6 `artifacts-detail.md` |

> **Règle de non-superposition** (05 §3.5 l.754-759, `_floating-surfaces.md` §2) :
> une surface flottante ouverte par un écran **toujours** respecte le stacking
> ci-dessus §1 ; si 2 écrans prétendent ouvrir **la même** surface, c'est une
> OQ (voir §8 OQ-02).

---

## 3. Flux de navigation par module (qui ouvre qui)

Décomposé par **famille de routes** du `router.tsx` (T1 = tab, T2 = overlay,
T3 = tab-adjacent, T4 = vue interne). Chaque ligne cite l'entry point
(`navigation-and-page-composition.md` §2 col. EP/OUT/IN/AGT) :

### 3.1 Famille Tab (T1) — les 5 entrées principales

| Tab (route) | Ouvre (OUT, `navigation-and-page-composition.md` §2) | Ouvert par (IN) |
|---|---|---|
| `/home` (AD-14, 7 slots) | `/tasks`, `/learn`, `/progress`, `/agent`, `/knowledge`, `/inbox`, `/settings` (via cards/CTA des 7 slots) | boot de l'app ; retour de n'importe quel tab = **fresh render from local store** (pas de re-fetch, AD-7) |
| `/tasks` (+`/tasks/:id` T2) | overlay détail (édition, sous-tâches, vue eisenhower, CTA focus → `/focus`) | Home (next-action), `/agent` (suggestions), `/inbox` (triage), `/projects/:id`, `/goals/:id` |
| `/learn` (+`/learn/:id` T2 : course→chapter→sheet/QCM/flashcards/mirror) | résultat → `/progress` (vue skill) ; erreur → analyse | Home (due-reviews), `/agent` (tutor), `/knowledge` (node → « study »), discovery sheets (« work on this ») |
| `/progress` (+`/progress/:id` T2 : dashboards today/week/month/trajectory, skill-map, gaps) | — (read-only, miroirs `skill_states`/`progress_snapshots`, 03 §4.2) | Home (critical-progress), flashcards (résultat), focus bilan |
| `/agent` (AgentRunState F-09) | actions confirmation → `/tasks`, `/learn`, `/focus`… | Home (coach slot), **toutes** les features (assistant CTA), deep links |

### 3.2 Famille Goals (T3, routes `/goals/*`)

| Route | Ouvre | Ouvert par | SSoT |
|---|---|---|---|
| `/goals` | goal detail → milestones/projects (hierarchie goal→project→task, 01 §4.1) | `/projects`, Home (critical-progress slot) | `navigation-and-page-composition.md` §2 · `router.tsx` l.78 |
| `/goals/:id` | project/tasks liés | `/goals` | `router.tsx` l.79 · 05 §4.3.4 |
| `/goals/:id/features/:fid` | — (feuille de l'arbre) | `/goals/:id` | `router.tsx` l.80 |
| `/goals/:id/ascent` (wave 3) | — (chemin pédagogique du goal actif, miroir local) | `/goals/:id` | `router.tsx` l.85 (wave 3, W3-E2) |

### 3.3 Famille Knowledge + Discovery (T2/T3)

| Route | Ouvre | Ouvert par | Note |
|---|---|---|---|
| `/knowledge` + `/knowledge/:nodeId` | node detail (lazy deeper branches, 02 §9.2) → « study » → `/learn` | Home, `/learn` (tree link), discovery (tree links), `/artifacts` (source refs) | retrieval serveur **seulement online** (AD-12) — `router.tsx` l.69-70 |
| `/discovery` (feed) | sheet detail → « work on this » → `/learn` ou `/tasks` | `/agent` (suggestions), Home (coach slot) | le feed = « research running » job state (01 §6 loading) — `router.tsx` l.95 |

### 3.4 Famille Productivité (Focus / Calendar / Projects / Routines / Habitudes)

| Route | Ouvre | Ouvert par | Note |
|---|---|---|---|
| `/focus` | session screen (timer ring) → bilan sheet (`focusBilan` ChartSpec) | Home slot 6 (AD-14 immediate Focus), `/tasks/:id` (CTA), `/agent` | task link + blocklist v1.8 DPC (OQ-17) — `router.tsx` l.88 |
| `/calendar` | time-block editor, event detail | Home (agenda), `/tasks`, goals (exam dates), Agent (replan) | `POST_NOTIFICATIONS` à l'usage — `router.tsx` l.89 |
| `/projects` | Gantt/Kanban/Timeline/List views + project detail (milestones, docs, notes) | `/tasks`, goals, Home | view modes (Kanban/Timeline/Gantt) **persistés par projet** — `router.tsx` l.92 |
| `/inbox` | triage → `/tasks/:id`, `/learn/:id`, `/settings` | capture buttons **partout**, quick-capture de n'importe quel écran, OneSignal reminders | draft persistence local (Tiptap) — `router.tsx` l.74 |
| `/settings` | thème selector + preview, silence windows, notification prefs, account | Home, any top bar | thème = persisted (store persist middleware) — `router.tsx` l.75 |

### 3.5 Règle « une seule écriture » par lien (AD-7, col. PERSIST)

- **Chaque page a exactement 1 PERSIST propriétaire** (col. PERSIST de
  `navigation-and-page-composition.md` §2) — c'est l'unique endroit où cette
  page **écrit** du state persistant (ui-state ou local store). Les autres pages
  **lisent** ce state, ne l'écrivent jamais (discipline single-writer, AD-7).
- **Exemples** : `/tasks` possède « list order/filter/virtualization state
  (ui-state, cosmetic persist, 02 §3.2) » ; `/goals/:id` possède « progress
  snapshot read » ; `/learn/:id` possède « FSRS state read-only local ; study
  position persisted » — une page ne modifie **pas** le FSRS state de
  `/learn` (read-only), elle lit le local store.

---

## 4. Contrats de données partagés entre pages

Les pages ne se parlent **pas** directement (pas de `postMessage` entre
composants) — elles échangent via **3 couches** de contrats SSoT :

### 4.1 AD-7 — Local-first (le socle de toutes les lectures)

- L'UI **lit toujours le local d'abord** (PowerSync + SQLite mirror) ; le serveur
  n'est jamais sur le chemin de lecture d'une page (02 §6.2 : « no network on
  mount » pour `/home`, col. PERM de `navigation-and-page-composition.md` §2).
- **Single-writer discipline** : 1 page = 1 PERSIST (cf. §3.5) ; une page qui
  « écrit » un état partagé = elle écrit son propre PERSIST, jamais celui
  d'une autre page.
- L'**Agent Kernel n'émet que des événements** (AD-9) — il ne modifie **jamais**
  directement les tables de domain (la page qui consomme le résultat d'un job
  lit le miroir local après l'événement, pas le retour du kernel).

### 4.2 AD-9 — Targeted events (le « bus » entre pages, V1 = 10 événements)

Vocabulaire V1 figé (ARCHITECTURE-SPINE AD-9) :

| Événement | Émetteur (producer) | Consommateurs déclarés (pages qui **réagissent**) |
|---|---|---|
| `TaskCompleted` | `/tasks/:id` (ou Agent) | `/progress` (re-render dashboard), Home (next-action refresh) |
| `CourseImported` | import course (job AD-12) | `/learn` (nouveau cours dans la liste) |
| `FlashcardReviewed` | `/learn/:id` (overlay flashcards) | `/progress` (skill-map), F-06 refresh liste |
| `ProgressEvidenceCreated` | jobs de preuve (ex. `/exercises-proof`) | `/progress` (re-render événementiel, **pas** CTA manuel — garde AD-14) |
| `SkillStateChanged` | `/learn` (résultat QCM/flashcards) | `/progress` (skill view), goals (gap analysis) |
| `GoalUpdated` | `/goals/:id` (édition) | `/projects` (hierarchy goal→project), Home (critical-progress slot) |
| `ArtifactGenerated` | job agent (F-06, post-upload R2) | `/artifacts` (aperçu), bibliothèque de ressources |
| `JobCompleted` | kernel AD-8 (tous jobs) | la page qui a déclenché le job (résultat streaming) + `/agent` (historique) |
| `DiscoveryItemCreated` | research jobs (01 §6) | `/discovery` (feed), `/learn` / `/tasks` (« work on this ») |
| `InboxCaptured` (implicite, S-23) | `/inbox` | `/tasks/:id`, `/learn/:id` (triage) |

**Règle d'or AD-9** : 1 producteur + N consommateurs **déclarés** (pas de
« tout le monde écoute tout »). Si une page réagit à un événement qu'elle
n'a **pas** déclaré comme consommateur, c'est une OQ (§8 OQ-03).

### 4.3 AD-15 — Shared domain types (le SSoT des types, 1 owner)

- Les types de domaine partagés (Task, Goal, SkillState, Artifact, DiscoveryItem…)
  ont **1 seul owner** (AD-15 : Shared domain types, single owner, consume not
  re-declare). Une page **importe** le type, ne le **déclare jamais** à nouveau
  localement.
- Concrètement pour ce chantier specs : quand `taches-detail.md` et
  `objectifs-detail.md` parlent tous les deux de « une tâche » ou « un
  objectif », ils doivent pointer le **même** type du module domain
  (pas 2 variantes locales du même concept). Si un doc écran invente son
  propre type local = OQ (§8 OQ-04).

### 4.4 AD-17 — 3-layer theming (ce que chaque page peut/ne peut pas toucher)

- **Couche 1 (neutral style)** : possède les tokens sémantiques
  `success`/`warning`/`danger`/`info` — **un thème ne les redéfinit jamais**
  (règle bloquante 05 §5.1).
- **Couche 2 (thèmes, 10 + 3 presets)** : possède `accent.*` (primary/secondary/
  punctual) + `chartPalette` (3-4 couleurs par thème, `packages/ui/src/themes/*.json`).
- **Couche 3 (Focus override)** : `FOCUS_OVERRIDES` = `node.secondary-opacity` /
  `node.active-contrast` **uniquement** — pas les CTA, pas les tokens
  sémantiques (cf. OQ récurrente §14 de nombreux écrans : « atténuation CTA
  in Focus Mode » = NON COUVERT, cf. `_open-questions.md`).
- **Conséquence inter-page** : une page qui change de thème (via `/settings`)
  ne change **jamais** la couleur d'un `success`/`warning`/`danger`/`info`
  rendu par une autre page — ces 4 tokens sont figés (AD-17, 05 §5.1).

---

## 5. Machine à états cross-pages (S6 / §6.1 s'étendant sur plusieurs écrans)

Les 6 états S6 (`ui-libraries.md` §6) et les états sémantiques §6.1
(en-cours/terminé/échec) ne sont **pas** confinés à 1 écran : un même **job**
ou **run** peut traverser plusieurs écrans avant de finir.

### 5.1 Un job / run traverse N écrans (AD-8 stateless executors, AD-7 local)

```
[Page A déclenche le job] 
   → Page A : état « en-cours » (streaming / skeleton, §6.1 SSoT §6)
   → l'utilisateur navigue vers [Page B] (retour tab, autre CTA) 
       → Page B : lit le MÊME job depuis le miroir local (AD-7) — pas un 2ᵉ job
   → job fini (event AD-9 `JobCompleted` / `ArtifactGenerated` / `DiscoveryItemCreated`)
       → Page A (si encore monté) OU Page B (si A est démonté) : état « terminé »
       → si l'événement arrive pendant killed = attendre la reconnexion (OQ, cf. `_open-questions.md` OQ-08 `analytics.md`)
```

**Règle** : un job = **1 état logique** partagé entre toutes les pages qui
l'affichent (pas 1 état par page). C'est le miroir local (AD-7) qui rend cela
possible — la page B ne « sait pas » que le job a été déclenché depuis la page A ;
elle lit simplement le local store. Si le spec écran dit « cet écran possède
son propre état de ce job » = OQ (violation AD-7, §8 OQ-05).

### 5.2 Les états « globaux » qui concernent TOUTES les pages

| État | Porteur | Effet sur n'importe quelle page | SSoT |
|---|---|---|---|
| **killed** (app re-lancée cold) | device OS | `Skeleton` + bannière fine « Reconnexion… » sur **tout** flux serveur ; le local reste lisible (AD-7) | 05 §3.7 l.1290-1296 · §4d de chaque doc |
| **Focus actif** (blocklist v1.8) | `/focus` (AD-14 slot 6) | atténuation `FOCUS_OVERRIDES` (`node.secondary-opacity`/`node.active-contrast`, AD-17 couche 3) — **pas** sur les CTA (OQ ouverte, cf. §14 récurrent) | 05 §4.4.2 · `theme-adapter.tsx` `FOCUS_OVERRIDES` |
| **Feature masquée** (AD-13 visibility) | `feature-registry` | le deep link vers cette feature → `NotFoundPage` (T6, §1) — « feature disabled », jamais un écran blanc | `router.tsx` l.100-102 · `not-found.md` |
| **Offline** (miroir local seulement) | AD-7 | chaque page = lecture miroir + désactivation du **seul** flux serveur qu'elle porte (variable par page, col. EMPTY/PERM de `navigation-and-page-composition.md` §2) | §12 de chaque doc écran |

---

## 6. Matrice écran × état (44 docs × 6 états S6 — vue transversale)

Chaque doc écran a sa matrice §4 (6 états S6 + §6.1 + 404 + killed, **aucune
case vide**, N/A justifié par AD-7). Ce § est l'extraction : pour chaque état,
le **pattern transversal** que partagent les 44 écrans (et ce qui varie).

| État | Pattern transversal (partagé par 44 écrans) | Ce qui varie par écran (cf. §4 de chaque doc) |
|---|---|---|
| **loading** | `Skeleton` du contenu (05 §3.7 l.1286) ; si c'est un job agent = `AgentThinkingLoader` (§9.3) vs ring indéterminé (`ProgressRing` §3.3) — le choix est **l'OQ récurrent** OQ-04 `cours-liste.md` / OQ-02 `agent-chat.md` | quel composant (ring vs thinking loader) + quel bloc est en skeleton |
| **empty** | `EmptyState` : icône **domaine** 48px (pas un logo) + CTA unique (AD-14 : 1 CTA d'action max) | le libellé du CTA (souvent OQ, cf. OQ-09 `timeline-gantt.md`, OQ-13 `bibliotheque-ressources.md`) + si watermark S9 (low-opacity 8 %, monochrome) s'applique à **cet** écran vide (matrice §9.1 l.385 — cf. OQ-05 `bibliotheque-ressources.md`) |
| **échec** (sémantique §6.1) | `Callout` (`danger`) + CTA exact (règle §6.1 l.193 « exact text / component / token / CTA, never blank ») | le texte du CTA + si un CTA existe du tout (OQ-35 `calendrier-mois.md` = le mois « signale » sans CTA propre, le CTA vit dans le jour) |
| **terminé** (sémantique §6.1) | `Callout` (`success`) ou état « clean » (pas de callout si c'est le default) | l'heure de transition terminée→clean (souvent OQ, cf. OQ récurrente « durée de la bannière success ») |
| **offline** | lecture miroir local (AD-7) + désactivation du **seul** flux serveur de l'écran (col. PERM §2) + `Badge` `warning` « à resync » si stale | quel flux serveur est désactivé (ex. scan de documents linked `calendrier-mois.md` §12) |
| **killed** | `Skeleton` + « Reconnexion… » sur tout flux serveur (05 §3.7 l.1290-1296) ; le local reste lisible | l'élément de §3 qui porte ce flux serveur (variable par écran — cf. OQ-36 `calendrier-mois.md` : « quelle ligne de §4a porte le killed ») |
| **404 / feature-disabled** (si routé) | `NotFoundPage` (fallback `*`, `router.tsx` l.100-102) : logo AURORA **coloré au CENTRE** §9.1/§6.1 + message court + CTA primaire « Retour à l'accueil » + CTA secondaire « Consulter l'écran parent » | **OQ transversale connue** : COLORED vs MONOCHROME du logo sur le 404 (404 = COLORED selon SSoT §9.1 l.387 vs MONOCHROME selon la matrice §9.1 l.378-388 — 3 docs COLORED, 1 MONOCHROME, cf. `INDEX_REVIEW.md` §1 / `_report.md` §2 top-5) |

> **Règle d'audit** : si un écran dit « N/A » pour un état, la justification
> **doit** citer AD-7 (le miroir local rend l'état inutile) — un N/A sans
> justification = OQ (cf. matrice §4 de `timeline-gantt.md` que j'ai complétée).

---

## 7. Sémantique router.tsx ↔ 46 slugs docs

`router.tsx` = **17 routes figées** ; les docs écrans = **44 slugs**
(les variantes comptent 1 slug = 1 écran, cf. `_inventory.md` §1) ;
l'inventaire réconcilié = **54** (OQ-1 du registre global, non encore arbitré).

**Le mapping route → doc(s) écran** :

| Route (`router.tsx`) | Doc(s) écran(s) qui la portent | Note |
|---|---|---|
| `/` (index) + `/home` | `home.md` | 2 routes → 1 doc (index = redirect home, ou rendu identique) |
| `/tasks` | `taches-liste.md` + `eisenhower.md` (vue quadrants, sous `/tasks`, G-L5) | **2 docs pour 1 route** — l'eisenhower est une vue interne (T4), pas une route distincte (`docs/productivity/eisenhower.md` G-L5, NEEDS_DECISION) |
| `/tasks/:id` | `taches-detail.md` | T2 (overlay over tab) |
| `/calendar` | `calendrier-jour.md` + `calendrier-mois.md` + `calendrier-semaine.md` | **3 docs pour 1 route** — 3 vues internes (T4, `Pager` 05 §3.4) |
| `/projects` | `projets-liste.md` + `kanban.md` + `timeline-gantt.md` (+ `projets-detail.md` en overlay) | **3+1 docs pour 1 route** — kanban/timeline-gantt = vues persistées par projet (col. PERSIST §2), `projets-detail.md` = T2 overlay **sous** `/projects` |
| `/goals` | `objectifs-liste.md` | T3 |
| `/goals/:id` | `objectifs-detail.md` | T3 |
| `/goals/:id/features/:fid` | `goal-feature-detail.md` | T3 |
| `/goals/:id/ascent` | `slide-ascent.md` | wave 3, W3-E2 (`router.tsx` l.85) |
| `/learn` | `cours-liste.md` + `bibliotheque-ressources.md` + `flashcards.md` (partial) | **OQ route** : `bibliotheque-ressources.md` §14 OQ-12 = le SSoT écran 05 §4.6.1 cite le slug **sans** route ; WDS 03.4 dit `/library` (non dans le router) ; `router.tsx` = `/learn` (tab). **Non tranché** (WDS draft vs router frozen). |
| `/learn/:id` | `cours-detail.md` + `fiches-liste.md` + `fiches-detail.md` + `qcm.md` + `flashcards.md` (partial) | **5 docs pour 1 route** — les fiches/QCM/flashcards = overlays du cours (`router.tsx` l.97-98 : « already registered under details above, no second registration ») |
| `/knowledge` | `knowledge-tree.md` | T3 |
| `/knowledge/:nodeId` | `knowledge-node.md` | T3, lazy deeper branches |
| `/discovery` | `discovery-feed.md` + `discovery-sheet.md` | `discovery-sheet.md` = BottomSheet **sur** le feed (T2-ish, cf. `_floating-surfaces.md`), pas une route distincte |
| `/progress` | `analytics.md` + `progress-dashboard.md` | **OQ route connue** : 2 docs partagent `/progress` (cf. `index.md` § « Notes de synthèse », dérive à arbitrer) — `analytics` = vue du tab 4, `progress-dashboard` = `:/progress/:id` + trajectory. **Dédupliquer ou renommer** dans le lot final. |
| `/progress/:id` | `progress-dashboard.md` (trajectory) | T2 |
| `/focus` | `focus-mode.md` | T3 ; blocklist v1.8 DPC = OQ-17 |
| `/artifacts/:id` | `artifacts-detail.md` | T2 |
| `/agent` | `agent-chat.md` | T1 (tab 5) |
| `/inbox` | `inbox.md` | T3 (tab-adjacent) |
| `/settings` | `settings.md` | T3 (tab-adjacent) |
| `*` (fallback) | `not-found.md` | T6 (feature disabled, jamais crash) |

**Comptage vérifié** : 17 routes figées → 44 docs écrans (certaines routes
portent 2-5 docs via les vues internes T4 et les overlays T2 ; certaines docs
ne correspondent à **aucune** route distincte — `eisenhower`, `kanban`,
`timeline-gantt`, `discovery-sheet` = vue/overlay **de** une route existante).
L'arbitrage OQ-1 (44 SSoT vs 54 candidats, `_report.md` §1) doit trancher si
certaines de ces vues internes comptent comme des slugs distincts (N final).

---

## 8. Open Questions (ce doc transversal, §8)

| n° | élément | question | options envisagées | décideur attendu |
|---|---|---|---|---|
| OQ-01 | §3 / §7 : la route de `bibliotheque-ressources` (`/library` vs `/learn`) | reprise d'OQ-12 de `bibliotheque-ressources.md` §14 — le WDS 03.4 (draft) dit `/library`, le `router.tsx` (frozen) dit `/learn` (tab) ; **pas de SSoT qui tranche** la route exacte de la bibliothèque en tant qu'écran distinct de l'overlay cours | (a) `/learn` (frozen, la bibliothèque = 1 sous-vue du tab Learning) (b) `/library` (WDS, à ajouter au router) (c) `/learn/bibliotheque` (sous-route dédiée) | owner WDS 03.4 / Frontend (ratifier la route exacte, cf. `bibliotheque-ressources.md` §14 OQ-12) |
| OQ-02 | §2 : 2 écrans qui prétendent ouvrir la **même** surface flottante | si `projets-detail.md` et `kanban.md` (ou `taches-detail.md` et `eisenhower.md`) déclarent tous les deux un « Modal de création » distinct — même composant, 2 déclencheurs = OK (un composant, N déclencheurs) ou 1 seul écran propriétaire ? | (a) le composant a 1 owner, les déclencheurs sont N (pattern courant, pas d'OQ) (b) si les 2 écrans **inventent chacun** leur propre composant de création = 2 composants distincts (violation AD-15, à arbitrer) | DS owner (AD-15, 1 composant = 1 owner) |
| OQ-03 | §4.2 : une page qui **réagit** à un événement AD-9 sans l'avoir déclaré consommateur | le vocabulaire V1 (10 événements) est figé ; si `objectifs-detail.md` dit « réagit à `TaskCompleted` » sans que AD-9 le déclare comme consommateur de cet événement = violation AD-9 (pas de « tout le monde écoute tout ») | (a) ajouter la page au registre de consommateurs AD-9 (nécessite le module à compléter, cf. `_report.md` §6) (b) la page ne réagit **pas** (elle lit le miroir local au mount, AD-7, sans besoin d'écoute) — c'est souvent le bon pattern (AD-7 : pas besoin d'événement pour lire le local) | kernel owner (AD-9) + feature owner concerné |
| OQ-04 | §4.3 : 1 écran qui **déclare** localement un type qui devrait être le type partagé AD-15 | si `kanban.md` et `projets-detail.md` (2 vues de `/projects`) déclarent chacune sa propre version d'un `ProjectStatus` = violation AD-15 (1 seul owner, consume not re-declare) | (a) les 2 écrans **importent** le type du module domain (pattern AD-15, à faire) (b) si c'est inévitable (vue locale simplifiée), la déclarer comme OQ + le noter §14 de chaque écran (c'est le cas de ce OQ) | AD-15 owner (Shared domain types) |
| OQ-05 | §5.1 : « 1 job = 1 état logique partagé » vs les specs écran actuelles | si `artifacts-detail.md` dit « cet écran gère son propre loading de preview » ET `agent-chat.md` dit « le run est en streaming ici » pour le **même** job de génération d'artefact = contradiction (2 états locaux pour 1 job distant) | (a) l'état du job vit **uniquement** dans le miroir local (AD-7/AD-8) — les 2 écrans lisent le **même** état, aucun n'en est propriétaire (pattern correct, à imposer) (b) chaque écran a son propre état local (anti-pattern, à rejeter sauf SSoT qui l'exige) | AD-7/AD-8 owner (Local-first sync + Targeted events) |
| OQ-06 | §5.2 : l'atténuation Focus override sur les CTA (pas les `node.*` seulement) | les 10 écrans qui hébergent un CTA pendant un Focus actif (cf. OQ récurrente §14 : `agent-chat.md`, `cours-liste.md`, `artifacts-detail.md`, `bibliotheque-ressources.md`, …) disent « l'écran **consomme** l'override » mais **pas** de SSoT pour l'atténuation des CTA (override = `node.secondary-opacity`/`node.active-contrast` **uniquement**, pas les CTA) | (a) le CTA est **grisé** (opacité token dédié, à créer) (b) le CTA est **bloqué** (« Reprenez après le focus ») (c) l'engagement est **reporté** dans la file du focus — **aucune** ratifiée (WDS 03.5 §5, NON COUVERT, cf. `INDEX_REVIEW.md` §3) | owner WDS 03.5 / token owner (`aurora.css`) |
| OQ-07 | §6 : le 404 « COLORED vs MONOCHROME » logo (transversal, non résolu depuis le lot 1) | 3 docs écrans disent « logo AURORA **coloré** au CENTRE » (SSoT §9.1 l.387), 1 doc dit « **MONOCHROME** » (matrice §9.1 l.378-388) — chaque écran qui code son 404 doit savoir quelle version est normative avant l'exécution frontend | (a) COLORED au CENTRE (rule l.387, majoritaire, 3 docs) (b) MONOCHROME (matrice l.378-388, cas de la matrice uniquement) (c) 2 versions coexistent (404 global = COLORED, 404 par écran = MONOCHROME) — à arbitrer **une fois** pour fermer l'OQ sur 5+ écrans (kanban, projets-detail, eisenhower, home, not-found) | owner S9 (logos) + DS team |
| OQ-08 | §7 : `/progress` partagé par `analytics.md` et `progress-dashboard.md` | reprise de la dérive signalée `index.md` § « Notes de synthèse » — les 2 docs portent la **même** route ; soit 1 seul doc la porte (le 2ᵉ devient une vue T4 du 1ᵉʳ), soit la route est dédupliquée (ex. `/progress` = analytics, `/progress/:id` = progress-dashboard trajectory uniquement) | (a) dédupliquer : 1 seul doc pour `/progress` (l'autre = sous-vue T4) (b) séparer les routes (analytics = tab, progress-dashboard = uniquement `:/progress/:id`) (c) renommer 1 des 2 slugs pour éviter la collision | Progress owner (docs/progress/overview.md, cf. `_report.md` §6) + Frontend (router.tsx) |

---

*Fin du doc transversal n°6 (interconnexion). Les 8 OQ ci-dessus sont des
pointeurs vers des OQ déjà existantes dans les docs écrans (§14) ou le
registre global (`_inventory.md` §3) — ce doc ne crée **pas** de nouvelle OQ
isolate, il les regroupe sous l'angle « interconnexion » pour l'exécution
frontend.*
