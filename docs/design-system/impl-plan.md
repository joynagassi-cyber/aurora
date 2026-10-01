# Aurora — Plan d'implémentation UI premium (SSoT-driven, zéro inférence)

> **Boussole (AD-15/AD-17) :** tout le frontend part des **44 specs d'écrans**
> (`docs/design-system/screens/`) + les SSoT citées. **ZÉRO INFÉRENCE** : chaque
> widget/animation/modal/formulaire/transition est cité `fichier:§` ou
> `fichier:ligne`, sinon = **OQ ouverte déclarée**. Ne rien inventer.
>
> **Ce document est le livrable B2** (commit `cc/plan:`) — il **consume** les
> 44 specs + les 6 transverses + les SSoT modules, et **fige** l'exécution par
> lots (`dyad/impl:`). **Aucun code ici** (AD-13 : le plan = `.md`).
>
> Prérequis de build (Phase A, `dyad/beta:`) : `apps/mobile` exécutable
> (Vite + `main.tsx`), Ascent local-mirror branché, OneSignal fail-fast,
> perf measures (voir §9 Gates). Le plan B **consomme** ce build.

---

## §0 · Arbitrages (tranches B1) — décisions + impact SSoT + porteur de ratification

Chaque tranchage est une **décision, pas une correction** (règle owner). Le
plan enregistre la **recommandation + raisonnement + SSoT impactée** ; le statut
`DECIDÉ` n'est acquis qu'après **ratification owner**. SSoT SSoT-citées :
`_report.md` §2/§6, `INDEX_REVIEW.md` §1/§3, `_inventory.md` §1/§3,
`_flows.md` §8, `_floating-surfaces.md` §10.

| # | Arbitrage | Recommandation (rationale) | SSoT impactée (update si (a/c)) | Décideur | Statut |
|---|---|---|---|---|---|
| **OQ-1** | 44 SSoT (`05 §4 l.1316`) vs 54 candidats (`_inventory.md §1`) | **(b) N = 54** slugs specifiables. Rationale : `_inventory.md §1` conclut déjà « N = 54 » (44 SSoT + 10 variantes − 7 doublons) ; les 54 slugs sont portés par **44 docs** (les variantes partagent le doc de leur paire). Exécution = 44 docs, comptage = 54. | `05 §4 l.1316` « 44 » → « 54 » (re-sync) si (b) ratifié | DS team (owner `05 §4`) | **RATIFIÉ 2026-09-30** — N=54 (exécution 44 docs, comptage 54) |
| **OQ-16** | Eisenhower `NEEDS_DECISION` (`G-L5`, `_inventory #16`) | **Ratifier `eisenhower` au catalog** (vue quadrants sous `/tasks`, offline-capable) — sinon route/404/CTA non implémentables. Si P2 → sortir du lot tasks (non bloquant pour les autres). | `docs/productivity/eisenhower.md` (G-L5) | owner | **RATIFIÉ 2026-09-30** — eisenhower = vue T4 sous /tasks (G-L5 fermée) |
| **OQ-48** | 404 par écran vs 404 global + libellé FR (`_report §2`, `not-found.md OQ-01…04`) | **404 GLOBAL unique** = la route `*` (`router.tsx l.100-102`) + l'état `feature-disabled` (`feature-registry S6`). Les 5+ écrans qui « codent leur 404 » **réutilisent** ce pattern, ne l'inventent pas (AD-15 1 pattern = 1 owner). Libellé FR = `feature-registry S6`. | `feature-registry S6` (libellé exact) + `not-found.md` | owner + DS | **RATIFIÉ 2026-09-30** — 404 global unique + libellé FR = feature-registry S6 |
| **OQ-47** | settings : CTA sync blocking vs optimistic + 4 champs G-D14 éditables (`_report §2`) | **Optimistic** (le sync est un job AD-8 async, la UI ne bloque jamais le render, AD-7) + les 4 champs G-D14 = **editables** dans `/settings` (PERSIST propre, `_flows §3.5`). | `docs/design-system/overview.md §6` + WDS 04.5 §8 | owner | **RATIFIÉ 2026-09-30** — optimistic + 4 champs G-D14 éditables |
| **OQ-6** | taille `AgentThinkingLoader` : 64-96px (`ui-libraries §9.3 l.454`) vs 48px (`l.483-486`) | **48px** (la valeur owner 2026-09-28, `l.483-486` = la plus récente, elle **override** `l.454` ; ligne de mots + chip = taille du texte du chat). Ferme OQ-3 `agent-chat` + OQ-6. Le composant est déjà implémenté (`packages/ui/…/AgentThinkingLoader.tsx`) → ratifier **une** valeur. | `ui-libraries §9.3 l.454` (64-96) → réaligner sur 48px (SSoT update) | DS team | **RATIFIÉ 2026-09-30** — 48px (1 valeur, SSoT à réaligner) |
| **Logos §13 (OQ-7)** | 404 = COLORED (3 docs) vs MONOCHROME (1 doc ; `05 §9.1 l.387` vs matrice `l.378-388`) | **404/feature-disabled global = COLORED au CENTRE** (règle `05 §9.1 l.387`, majoritaire, 3 docs) ; le MONOCHROME de la matrice `l.378-388` = les watermarks 8 % (empty-states), **pas** le 404. 1 version normative. | `05 §9.1` (matrice `l.378-388` vs `l.387` — dédoubler la ligne 404) | DS team (owner S9) | **RATIFIÉ 2026-09-30** — 404/feature-disabled COLORED au centre |
| **Routes (OQ-12/OQ-01/OQ-08)** | WDS-draft vs `router.tsx` frozen (`_flows §7`, `bibliotheque-ressources OQ-12`, `/progress` OQ-08) | **`router.tsx` = figé (frozen), WDS = draft.** (a) `bibliotheque-ressources` reste **sous `/learn`** (tab T1, pas de `/library` séparé — 1 sous-vue, `_flows §7`); (b) `/progress` : `analytics` = vue du **tab** (read-only), `progress-dashboard` = **`/progress/:id`** (trajectory) — dédupliquer par rôle, pas par slug; (c) les vues internes (eisenhower/kanban/gantt) = **T4** (ui-state), jamais de route distincte. | `router.tsx` (frozen, SSoT de nav) ; WDS 03.4/04.5 résiduel ratifié | owner + App Shell (Winston) | **NON — owner ratifie** |
| **8 docs modules** | compléter pour fermer les 256 OQ (`_report §6`) | **Les 8 docs modules sont la porte d'entrée de la majorité des OQ par-lot.** § exacts (ci-dessous). Dyad définit les §, les équipes modules écrivent. | 8 files (table ci-dessous) | équipes modules (PAIGE) | **NON — owner + équipes** |

**Les 8 docs modules (§ à ajouter — SSoT écran-par-écran, `_report.md §6`) :**

| Doc module | § à ajouter (à définir) | OQs fermées |
|---|---|---|
| `docs/progress/overview.md` | § écran dashboard (5 `ListItem` dépliables, `SegmentedControl` 4 options, desktop 2 panneaux, offline miroir `progress_snapshots`) | OQ-43 + OQ-08 `progress-dashboard` |
| `docs/knowledge/overview.md` | § tree (canvas React Flow, gestes pan/zoom, 404 par nœud) + § nœud (lazy deeper branches) | OQ-39/40 + OQ-01…07 (tree/nœud) |
| `docs/discovery/overview.md` | § feed (dégradation `uncertain`, `01 §6`) + § sheet (BottomSheet, focus-trap) | OQ-41/42 + OQ-01…07 / OQ-01…14 |
| `docs/agent/kernel.md §13` (+ `ui-actions`) | § rendu écran (chat, streaming, renderers tool-calls, 404 par run, offline = history local AD-7) + re-sync `AgentThinkingLoader.tsx` | OQ-44 + OQ-01…06 `agent-chat` + OQ-6 |
| `docs/artifacts/overview.md` | § écran (preview par format image/video/pdf/audio, états par format, presigned TTL 15/5, cache préviews) | OQ-46 + OQ-01…08 `artifacts-detail` |
| `docs/design-system/overview.md §6` | CTA sync (OQ-50 `settings`) + éditabilité 4 champs G-D14 (OQ-48 résiduel) | OQ-47 (residue) |
| `feature-registry S6` | libellé FR exact du 404/feature-disabled + CTA secondaire exact | OQ-48 + OQ-01…04 `not-found` (ferme 5 écrans) |
| WDS 04.5 §8 (corps gelé) | ratifier le résiduel settings | idem ligne `design-system §6` |

> **Règle (05 §3.5 + ui-libraries S1)** : en cas de contradiction SSoT (OQ-5/6
> ci-dessus), **l'owner arbitre** ; le SSoT DS (`05`) = le comportement, la SSoT
> ui-libraries = la lib. **Ne jamais dériver silencieusement** (R4) — chaque
> tranchage **update** la SSoT concernée (ex. `05 §4`, `05 §9.1`, `ui-libraries §9.3`).

---

## §1 · Architecture globale

**Routes ↔ slugs (post-OQ-1 = N 54, 44 docs).** `router.tsx` = **17 routes
figées** (T1 tabs × 5, T2 details-over-tab, T3 tab-adjacent, T4 vue interne,
T6 fallback `*` — `_flows §1/§7`). Le mapping complet route → doc(s) écran est
dans `_flows §7` (ex. `/tasks` porte `taches-liste` + `eisenhower` (T4) ;
`/calendar` porte les 3 pagers (T4) ; `/learn/:id` porte 5 docs par overlays
T2 ; `/progress` = dérive OQ-08).

**5 familles Tab (T1, `_flows §3.1`) :**
- **Tab `/home`** (AD-14, 7 slots) — `home.md`.
- **Tab `/tasks`** (+ `/tasks/:id` T2, + eisenhower T4) — tâches/quadrants/focus-CTA.
- **Tab `/learn`** (+ `/learn/:id` T2) — cours/fiches/QCM/flashcards/mirror/bibliothèque.
- **Tab `/progress`** (+ `/progress/:id` T2) — dashboards/skill-map (OQ-08).
- **Tab `/agent`** (AgentRunState F-09) — chat + 4 doc-tools (§4).

**Surfaces flottantes (6 + loader, `_floating-surfaces.md` §1-§7, pas des écrans) :**
`BottomSheet` · `Modal` · `Drawer` (latéral) · `Command palette` ·
`Toast/Snackbar` · `FAB` + `AgentThinkingLoader` (non-floatable, §9.3).
**Stacking figé** (`05 §3.5 l.754-759`, `_floating-surfaces §0`) :
`contenu 0 < TopBar/BottomNav 10 < sheet/menu/drawer 30 < Modal 40 < Toast 50
< Splash 60` — un écran **n'en définit jamais** (AD-13, le DS est seul owner).

**Sémantique router (transverse, `_flows §7`)** : T1-T3 = changements de route
(le router sait) ; T4 = in-page (ui-state, le router **ne sait pas**) ;
T5 = trigger global → T2/T3 ; T6 = fin de route. **Details open OVER le tab
courant** (`router.tsx l.65-71`, `02 §6.1`), le retour révèle le tab dessous.

**Contrats cross-pages (4 couches, `_flows §4`) :**
- **AD-7** local-first : l'UI lit le local d'abord, **no network on mount**
  pour `/home` (`02 §6.2`) ; single-writer (`_flows §3.5` : **1 page = 1
  PERSIST propriétaire**, les autres lisent).
- **AD-9** targeted events (bus, V1 = 10 événements, `_flows §4.2`) : 1
  producteur + N consommateurs **déclarés** (pas « tout le monde écoute tout »).
- **AD-15** shared types : 1 owner par type, consume not re-declare
  (`AscentLearningIR` = `packages/domain/ascent.ts` ; `Task`/`GoalProject` =
  `@aurora/domain`).
- **AD-17** 3-layer theming (`_flows §4.4`, §5) : couche 1 = sémantiques
  figées (`success/warning/danger/info`, **un thème ne les redéfinit jamais**),
  couche 2 = 10 thèmes + 3 presets, couche 3 = `FOCUS_OVERRIDES`
  (`node.secondary-opacity`/`node.active-contrast` **uniquement**,
  `theme-adapter.tsx`).

**Machine à états cross-pages (`_flows §5`)** : **1 job = 1 état logique**
partagé entre toutes les pages qui l'affichent (le miroir local AD-7 le rend
possible) ; états globaux (`_flows §5.2`) : `killed` (Skeleton + « Reconnexion »)
· `Focus actif` (`FOCUS_OVERRIDES`) · `Feature masquée` → `NotFoundPage` ·
`Offline` (miroir + désactivation du **seul** flux serveur de l'écran).

**« Une seule écriture » par lien (AD-7, `_flows §3.5`)** : chaque page a
**exactement 1 PERSIST** (col. PERSIST de `navigation-and-page-composition §2`)
— l'unique endroit où elle **écrit** du state persistant ; les autres pages
lisent, n'écrivent jamais.

---

## §2 · Plan par lots (exécution) — 1 lot = 1 groupe module = 1 commit (`dyad/impl:`)

Ordre par famille module guidé par `_flows §3`. **Réutiliser d'abord** les
**47 composants `@aurora/ui`** (`packages/ui/src/components/ui/`, vérifié
2026-09-29 : 30 base shadcn/Radix + data `AgGridTable`/`DataTable`/
`CalendarView`/`GanttRow`/`KeyValueList`/`StatTile`/`Timeline` +
`AgentThinkingLoader` + `premium` [Aceternity/Magic UI] + 5 renderers AD-10
dans `packages/ui/src/renderers/`) — **rien d'inventé** (tout revient à
`ui-libraries.md` + les 44 specs). Engines AD-10 **figés** (voir §6).

**Template 14-sections par doc écran** (le lot consomme le `<slug>.md`) :
- **§3 widgets · §5 micro-interactions · §6 modals · §7 formulaires ·
  §8 pagination · §9 transitions** = **à coder** (le « quoi implémenter »).
- **§11-§13** = a11y / offline / logos = **critères de vérification** (ne
  pas confondre avec §9 « transitions »). **§14** = les OQ du lot.

Chaque lot livre, par écran : le composant (`@aurora/ui` réutilisé), les
micro-motions spec (§5), les modals (§6), les formulaires (§7), la
pagination (§8), les transitions (§9), les **6 états UX**
(`loading/empty/success/error/offline/killed`, `ui-libraries §6` + `_flows §6`),
+ les tests. Preuve `fichier:ligne` + gate vert par lot.

| Lot | Module / famille | Slugs (`_flows §3` + `_inventory §2`) | Cœur `@aurora/ui` + engine AD-10 | OQ clôturées par lot |
|---|---|---|---|---|
| **L1** | Home + Onboarding + Settings + Not-found | `home`, `onboarding`×3, `settings`, `not-found` | `StatTile`, `KeyValueList`, `CalendarView`, `premium` (GoalProject cards) · FullCalendar · Tiptap | OQ-47, OQ-48 (404), OQ-01…04 `not-found`, OQ-16 `onboarding` Nocturne |
| **L2** | Productivité (tâches / focus / calendrier / inbox) | `taches-liste`, `taches-detail`, `eisenhower`, `focus-mode`, `calendrier`×3, `inbox` | `AgGridTable`/`DataTable`, `CalendarView`, `GanttRow`, `Timeline` · FullCalendar · `@dnd-kit` (kanban) · Tiptap (inbox) | OQ-16 (eisenhower), OQ-35 `calendrier-mois`, OQ-13 `kanban`, OQ-08 `inbox` |
| **L3** | Projets + Goals + Ascent | `projets-liste`, `projets-detail`(4 vues), `kanban`, `timeline-gantt`, `objectifs-liste`, `objectifs-detail`, `goal-feature-detail`, `slide-ascent` | `GanttRow`, `Timeline`, `AgGridTable` · **React Flow/Dagre** (semantic tree, `SemanticTreeRenderer`) · **Framer Motion** (cards) | OQ-08 (`/progress` dérive), OQ-12/48 (routes proj.) |
| **L4** | Learning | `cours-liste`, `cours-detail`, `fiches`×2, `flashcards`, `qcm`, `exercises-proof`, `mirror-cognitive`, `mode-coach`, `bibliotheque-ressources` | `react-virtuoso` (>100 items) · **KaTeX** (`MathRenderer`) · Tiptap · `@dnd-kit` (fiches) | OQ-36 `exercises-proof`, OQ-12 `bibliotheque`, OQ-04 `cours-liste` |
| **L5** | Knowledge + Discovery | `knowledge-tree`, `knowledge-node`, `discovery-feed`, `discovery-sheet` | **React Flow/Dagre** (`SemanticTreeRenderer`) + **AntV G2** (`DataVisualizationRenderer`) · `BottomSheet` (sheet) | OQ-39/40 (knowledge), OQ-41/42 (discovery) |
| **L6** | Agent + Artifacts + doc-tools | `agent-chat`, `artifacts-detail` (+ 4 flux doc-tools, §4) | `AgentThinkingLoader` (§9.3) · **AntV Infographic** (`InfographicRenderer`) · `Premium` micro-motion | OQ-6 (loader 48px), OQ-3, OQ-44, OQ-46, OQ-01…08 `artifacts` |
| **L7** | Progress + Reviews + Retro | `analytics`, `progress-dashboard`, `revues`×3, `retro-actions` | **AntV G2** (`DataVisualizationRenderer`) · `Timeline` · `SegmentedControl` · Tiptap | OQ-43, OQ-08 `/progress` |
| **L8** | Surfaces flottantes + Transverses + pass thème/a11y | `_floating-surfaces`, `_flows` (transverse) + matrice 13×2 (§5) | 6 surfaces (`BottomSheet/Modal/Drawer/Command/Toast/FAB`) + loader | OQ-1…6 `_floating-surfaces`, OQ-7 (logos 404) |

> **Règle de lot** : 1 lot = 1 commit `dyad/impl: <slug(s)>` = 1 rollback
> (AD-13). Les lots L2/L4/L5 réutilisent les engines AD-10 déjà posés par
> L3 (pas de double-implémentation). `slide-ascent` (L3) **consomme** le
> wiring Phase A (A2 : `ascent` local-mirror branché dans le provider).

---

## §3 · Transverses (non par-lot, figées UNE fois)

**404 / feature-disabled (post-OQ-48, logo post-arbitrage OQ-7)** : le
fallback `*` (`router.tsx l.100-102`) rend `NotFoundPage` (état entier,
**pas** un écran blanc) : logo AURORA **COLORED au CENTRE** (`05 §9.1 l.387`,
récup. `c4adf43`/`56aa2e1`) + message court + CTA primaire « Retour à
l'accueil » + CTA secondaire « Consulter l'écran parent » (libellé FR =
`feature-registry S6`). 1 pattern réutilisé par 5+ écrans (kanban,
projets-detail, eisenhower, home, not-found) — jamais ré-inventé (AD-15).

**6 surfaces flottantes** : `BottomSheet`/`Modal`/`Drawer`/`Command`/
`Toast-Snackbar`/`FAB` (`_floating-surfaces §1-§6`, SSoT `05 §3.5`). Chaque
surface : états par contenu (loading/empty/error/offline), focus-trap
(Matice §9), dismissal (back Android / drag / backdrop), transition
(`§8` table). Le **stacking z-index est figé §0** — un écran ne l'importe que.

**Règles `AgentThinkingLoader` (`_floating-surfaces §7`, `ui-libraries §9.3/§9.3.1`)** :
job agent = **thinking loader** (organisme 3 blobs, **pas** trois-points) ;
indeterminate = ring (`ProgressRing` §3.3) **ou** thinking loader selon l'OQ
récurrente `loading` (`_flows §6`). Non-interactif (`§9.3 l.462`),
`role="status"` + `aria-live="polite"`, mots rotatifs `aria-hidden`,
`exiting` = collapse+fade 200 ms, **reduced-motion = instantané + frozen**.

**États globaux (`_flows §5.2`)** : `killed` (Skeleton + « Reconnexion… »
sur tout flux serveur, local reste lisible AD-7) · `Focus actif`
(`FOCUS_OVERRIDES`, `theme-adapter.tsx`) · `Feature masquée` → `NotFoundPage` ·
`Offline` (miroir + désactiver le **seul** flux serveur de l'écran, col. PERM).

**Taxonomie des transitions (6 mécanismes, `_flows §1`) + matrice écran →
surfaces flottantes ouvertes (`_flows §2`) — transverses, non par-lot :**

| Méca | Quand | SSoT |
|---|---|---|
| T1 tab switch | navigation principale (retour tab = **fresh render local**, AD-7) | `router.tsx l.57-63` · `Shell` |
| T2 push détails over tab | ouvrir `/…/:id` par-dessus le tab courant | `router.tsx l.65-71` · IonModal/IonSlides |
| T3 route tab-adjacent | `/inbox`, `/settings` (vraie page, back) | `router.tsx l.73-75` |
| T4 vue interne | pager jour/sem/mois, switch list/kanban/gantt (in-page, ui-state persistant) | `05 §3.4 Pager` · `navigation §2 col. PERSIST` |
| T5 command palette | global search (5 entry points) | `ui-libraries S1 l.28` |
| T6 redirect/fallback | deep link feature masquée → `NotFoundPage` | `router.tsx l.100-102` |

**Contraintes globales (2, `_flows §1`)** : PAGE_TRANSITION = 200 ms
`ease-out` GPU-only (transform+opacity, `ux/polish.tsx` `PAGE_TRANSITION`),
reduced-motion = statique ; z-index par le stacking figé (§0).

**Dérives non-bloquantes déclarées (R3, `_flows §8`)** : `/progress` partagé
par `analytics` + `progress-dashboard` (OQ-08, dédoublé par rôle, pas par
slug) ; `bibliotheque-ressources` route (OQ-12, reste sous `/learn`).

---

## §4 · Flux doc-tools (4 outils agent, `docs/agent/document-tools.md` S1-S5)

Câblés dans **`agent-chat`** (L6) — 4 **triggers NL distincts** (le LLM voit
le *where/when* dans `packages/agent/src/tools.ts` + matrix S1) :

| NL trigger (utilisateur) | Outil (`payload.docTool`) | Direction | Sortie |
|---|---|---|---|
| « générer un doc (Word/PDF/…) » | `docs.generate` (Pandoc) | TEXT → DOC | .docx/.pdf/.pptx/.html/.epub (job `artifact_gen`) |
| « remplir / corriger ce .docx » | `docs.refine` (python-docx) | DOC → DOC (chirurgie) | .docx (révision `supersedes`) |
| « lis ce Word » | `docs.inspect` (mammoth) | DOC → TEXT | .docx → HTML/Markdown (quick, read-only) |
| « extrais ce PDF/PPT/Excel » | `docs.parse` (Docling) | DOC → TEXT (complexe) | .pdf/.pptx/.xlsx → Markdown/JSON |

**Règles dur** (`document-tools.md` S1, « never-mix ») : un **générateur ne
parse jamais**, un **lecteur ne génère jamais** ; `docs.inspect` = .docx-only
(autres → `docs.parse`) ; layout pixel-precis → `docs.refine` (pas Pandoc) ;
photo/scan brute → job `ocr` (pas Docling). Les 4 = **jobs `artifact_gen`
server-side (AD-8)**, discriminateur `payload.docTool`, **états dans
`AgentRunState` (F-09)** — le loader = `AgentThinkingLoader` (§9.3, 48px OQ-6).
**Retry F-08** : événement `JobCompleted` + `jobId` + `jobKind`.

**Surfaces consommatrices :**
- **`artifacts-detail`** (L6) : sorties .docx/.pdf/.pptx/.epub + parsées
  md/json ; **preview par format** + export, révision `supersedes`,
  `ArtifactGenerated` **post-upload R2 (F-06)** ; **formats non-supportés =
  gardés + téléchargeables, jamais de claim de preview** (ADR §16).
- **`knowledge-node`/`knowledge-tree` + `bibliotheque-ressources`** (L4/L5) :
  représentations parsées = **SourceRef provenance AD-11** (`SourceRefInline`).

**Dégradations SSoT S5 (`document-tools.md` S5) — l'UI affiche
`expectedQuality:'degraded'` (AD-5) dans `agent-chat` + `artifacts-detail` :**

| Outil dégrade vers | Dégradation |
|---|---|
| `docs.generate` | Markdown brut (pas de .docx) |
| `docs.refine` | `docs.inspect` + flag « non-edité » |
| `docs.inspect` | Pandoc (brut) |
| `docs.parse` | Pandoc dégradé / scans bruts → job `ocr` |

**Bus AD-9 (`_flows §4.2`, câbler les 4 flux dans la machine à états §5)** :
`ArtifactGenerated` (producer = job, consumers = `/artifacts` +
bibliothèque) ; `JobCompleted` (kernel AD-8, consumer = la page qui a
déclenché + `/agent` historique). **Le LLM orchestre, le solver calcule,
le verifier valide** (engineering) — les `docs.*` suivent le même pattern
(job `artifact_gen`, sortie = nouvelle line `artifacts` immuable, F-06).

---

## §5 · Vérification thème + a11y (par lot, **SANS EXCEPTION**)

**Contrat thème (A7, AD-17, `05 §5.1`/`§2.1.3`) :**
- Matrice **13 combos × 2 styles neutres** (10 expressifs + 3 presets
  [Nocturne/High Contrast/Slate] × {light, dark}).
- **Blanc-par-défaut (LIGHT)** ; DARK **seulement** si l'utilisatrice le
  choisit (`ui-state.theme`, jamais de switch silencieux au foreground,
  `theme-adapter.tsx`). **ACCENT ONLY** (zéro couleur hors tokens,
  `--aurora-accent-*` ; les sémantiques `success/warning/danger/info` ne
  bougent **jamais**).
- **Aperçus HTML par lot** dans `docs/design-system/previews/` (pattern
  `agent-thinking-loader.html`) — **jamais de mockups non approuvés**
  (G-L2 REJECTED 09/27) ; owner ratifie par aperçu.

**Critères d'acceptation a11y (règle owner, portés ici) — vérifiés sur
CHAQUE aperçu avant ratification :**
- **WCAG AA** (contrastes 4.5:1 texte, 3:1 UI non-texte, `ui-libraries §9.3 l.487` DAPHNE blocking < 3:1).
- **Focus visible** (focus-trap par surface, `_floating-surfaces §9`).
- **Touch targets ≥ 44 px** (`05 §6.3` ; le FAB `mini` 40px = OQ-5 → 44px).
- **`aria-label`** sur les icon buttons ; loader `role="status"` +
  `aria-live="polite"` + mots `aria-hidden` (§9.3 l.457-462).
- **`prefers-reduced-motion` respecté** (tout → `instant` 0 ms, `05 §2.6
  règle 2`, `polish.tsx` `useReducedMotion`).

---

## §6 · Perf budgets (mesurés, pas déclarés)

| Budget | Valeur | SSoT (zéro-inférence) | Mesure |
|---|---|---|---|
| JS | **≤ 300 Ko gz** | `AI_RULES §Testing` + `apps/mobile/src/perf/budgets.ts` (`PERF_BUDGETS.jsGzBytes`) | `perf/measure.ts` → **`viteBundleGzBytes()`** (A5 : `dist/assets/*.js` gz réel), repli proxy `.d.ts` |
| TTI | **≤ 1.5 s** (Pixel 4a) | `02 §9.1` + Sentry SLO | `perf/budgets.ts` `checkTti` + capture device owner (OQ-08) |
| tree | **30 fps** (1000 nœuds) | `02 §9.1` + `packages/ui/scripts/semantic-tree-30fps.mts` | device (harnais `SemanticTreeRenderer`, AD-10 lazy + incremental Dagre) |
| animations | **GPU 150-250 ms + reduced-motion** | `ui-libraries S5 l.169` + `05 §2.6` (fast 150 / normal 250 / slow 400) | `prefers-reduced-motion` = `instant` (`polish.tsx`) |

Lazy engines AD-10 (`ui-libraries` + `05 §3.6`) : les 5 engines se chargent
**seulement** quand leur écran s'ouvre (`React.lazy`), Home les exclut ;
l'état de perf par design = micro-interactions **réduites** (`02 §9.3`).

---

## §7 · Stratégie OQ (256 + 13 + 8)

**3 classes :**
- **Bloquantes** (tranchées **avant** exécution = §0 B1, owner ratifie) :
  OQ-1 (N final), OQ-16, OQ-48, OQ-47, OQ-6, OQ-7 (logos 404), routes
  (OQ-12/OQ-01/OQ-08), + les 8 docs modules (porte des OQ par-lot).
- **Par-lot** (clôturées **pendant** le lot, SSoT mise à jour) : les 256 du
  registre `_open-questions.md` (374 consolidées, 118 clôturées) — chaque lot
  §2 ferme les OQ de ses slugs (`§14` de chaque doc), met à jour la SSoT.
- **Différées** (déclarées + owner OK, non-bloquantes) : les dérives §3
  (OQ-08 `/progress`), les résiduels WDS gelés (04.5 §8).

**Périmètre complet** = les **256** du registre **PLUS** les **13 OQ
globales** (`_inventory §3` : OQ-1/13/16/36/39/40/41/42/43/44/46/47/48 —
fermées via les 8 docs modules §0) **PLUS** les **8 OQ interconnexion**
(`_flows §8`, pointeurs vers des OQ existantes, **pas** de nouvelle OQ
isolée). Registre = `_open-questions.md` (regen par `_gen_oq.py` si commité,
sinon maintenu à la main — **choix owner**, B0-8).

---

## §8 · Non-objets / décisions ≠ corrections

- **Code modules (AD-7/AD-13)** : ce plan **consomme** les packages (data,
  agent, productivity, learning, knowledge, discovery, artifacts, progress) —
  il ne les **réécrit** pas.
- **DPC focus (OQ-17, out V1 device)** : `focus-mode` code l'état device + le
  restriction-only fallback ; le « app blocking » natif (DPC/Device-Owner) =
  **hors V1** (déclaré, non implémenté).
- **Backend / Supabase / secrets** : hors périmètre UI (AD-3, owner).
- **DAPHNE QA (`prompts/dyad-design-qa.md`)** = **Phase C, APRÈS ratification**
  de ce plan — **ne pas l'exécuter ici** (pas de double-travail, G-L2).
- **Mockups** : interdits non approuvés — ratification par **aperçus HTML**
  uniquement (§5).

---

## §9 · Gates d'exécution

1. **Une phase à la fois** (R5) : `Phase A` (build) → **ratification owner
   B1 (§0)** → `B2` (ce plan) → **owner ratifie le plan + previews §5** →
   `B3` (lots `dyad/impl:`). **Pas d'exécution de lots avant ratification
   B1 + B2.**
2. **Gate pnpm vert avant CHAQUE commit** : `pnpm -r typecheck/lint/test` +
   `scripts/check-boundaries.sh` + `check-rls.sh` + `check-view-joins.ts`
   (+ `tests/spine`) — miroir `.github/workflows/ci.yml` (`docs/ci/gate.md`).
3. **Push par commit** (1 story = 1 commit = 1 rollback, AD-13).
4. **Rapport evidence-based à chaque porte** : tout claim `fichier:ligne` ;
   « non vérifié » si non cité. Prérequis **Phase A** (build `dyad/beta:`)
   ratifié par l'owner avant le premier lot.

**Ce que l'owner fournit/ratifie** (checklist §9) : OQ-1/16/47/48/6, logos
404 (OQ-7), routes (OQ-12/OQ-08), 8 docs modules, `_gen_oq.py`
commit-vs-ignore (B0-8), `.env.local` + mécanisme `.env` OneSignal (A3) +
device (`npx cap add/sync`), captures device (perf §6).
