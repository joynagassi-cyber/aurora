# index — Sommaire cliquable des docs écrans

> **Statut** : index v2 (2026-09-29, lot final — tous les docs existants sur
> disque, 6 transverses + 44 docs écrans) · couvre les **44 docs écrans**
> présents dans `docs/design-system/screens/` (état courant du répertoire, à
> re-synchroniser avec `_inventory.md` après arbitrage du OQ-1 — règle de
> comptage des variantes 44 SSoT vs 54 candidats).
> **Politique** : 1 slug = 1 écran = 1 doc 14-sections (`_inventory.md` §1). Les
> surfaces flottantes (05 §3.5 + `AgentThinkingLoader` ui-libraries §9.3) ne sont
> **pas** des écrans : doc transversal dédié, référencé par chaque écran
> (`_floating-surfaces.md`, **existant**).
> Les OQ globales (registre OQ n°1/13/16/36/39-44/46-48 de `_inventory.md` §3) sont
> consolidées dans **_open-questions.md** (**existant**, 374 OQ consolidées /
> 256 ouvertes). La logique d'interconnexion des pages (qui ouvre qui, contrats
> partagés, machine à états cross-pages) = doc transversal **_flows.md**
> (**existant**).

## Liens de navigation

| Doc transversal | Rôle | Statut |
|---|---|---|
| [_inventory.md](./_inventory.md) | Inventaire écran-par-écran réconcilié (54 slugs × module × SSoT × route × classe offline × statut), politique de comptage figée, registre OQ global (§3), état des lots (§4) | **EXISTANT** |
| [_floating-surfaces.md](./_floating-surfaces.md) | Surfaces flottantes transverses (BottomSheet / Modal / Drawer / Command palette / Toast-Snackbar / FAB, 05 §3.5 l. 752-864 + `AgentThinkingLoader` ui-libraries §9.3 l. 420-487) — stacking normative (contenu 0 < TopBar/BottomNav 10 < sheet/menu/drawer 30 < Modal 40 < Toast 50 < Splash 60) | **EXISTANT** |
| [_open-questions.md](./_open-questions.md) | Consolidation du registre OQ global (`_inventory.md` §3 : OQ n°1/13/16/36/39/40/41/42/43/44/46/47/48) + pointer vers les OQ locales de chaque doc §14 (374 OQ consolidées, 256 ouvertes) | **EXISTANT** |
| [_flows.md](./_flows.md) | **Interconnexion des pages** (taxonomie des transitions T1-T6, matrice écran → surfaces flottantes ouvertes, flux de navigation par module (qui ouvre qui), contrats de données partagés AD-7/AD-9/AD-15/AD-17, machine à états cross-pages, matrice écran × état transversale, sémantique router.tsx ↔ 44 slugs, 8 OQ interconnexion) | **EXISTANT** (lot final, 2026-09-29) |
| [INDEX_REVIEW.md](./INDEX_REVIEW.md) | Review adversarial du lot (top 5 OQ bloquantes, SSoT factices, verdicts par écran) | **EXISTANT** |
| [_report.md](./_report.md) | Rapport de fin du chantier (état 2026-09-29, lot final) | **EXISTANT** |

## Table des écrans (44 docs)

Légende statut (état courant des docs, plus fin que les statuts SSoT de
`_inventory.md` §2) :
- **SPECIFIED** = doc 14-sections écrit ;
- **SPECIFIED (fragment)** = doc partiellement complété (sections manquantes signalées dans le doc) ;
- **SPÉCIFIABLE** = SSoT écran complète existe (05 §4.x / WDS), doc écrit mais OQs ouvertes restantes ;
- **ADDITIF** = slug hors du décompte 44 SSoT (WDS / G-L5 / code) ;
- **CLAIMÉ (GAP)** = claimed dans le 44 SSoT (05 §4 l. 1316) mais SSoT écran manquante / module muet écran-par-écran.

| # | Slug | Nom | Module | Route | SSoT principale | Statut | OQs §14 |
|---|------|-----|--------|-------|-----------------|--------|---------|
| 1 | [agent-chat](./agent-chat.md) | Agent conversation (streaming + tool-call renderers) | Agent | `/agent` | docs/agent/kernel.md §13 + ui-libraries §9.3 | SPECIFIED | 6 |
| 2 | [analytics](./analytics.md) | Analytics (vue du tab Progress) | Productivité | `/progress` (+ `/progress/:id`) | 05 §4.5.2 l. 2410-2478 + WDS 01.2/01.7 | SPECIFIED | 11 |
| 3 | [artifacts-detail](./artifacts-detail.md) | Artefact (détail / preview par format) | Artifacts | `/artifacts/:id` | docs/artifacts/overview.md + WDS 03.5 + ADR §16 (OQ-46) | CLAIMÉ → SPECIFIED | 8 |
| 4 | [bibliotheque-ressources](./bibliotheque-ressources.md) | Bibliothèque de ressources (S-14) | Learning | `/learn` | 05 §4.6.1 l. 2479-2519 + WDS 03.4 | SPECIFIED | 24 |
| 5 | [calendrier-jour](./calendrier-jour.md) | Calendrier (vue jour, Pager) | Productivité | `/calendar` | 05 §4.4.1 l. 1896-2043 + 05 §3.4 `Pager` | SPÉCIFIABLE | 8 |
| 6 | [calendrier-mois](./calendrier-mois.md) | Calendrier (vue mois, Pager) | Productivité | `/calendar` | 05 §4.4.1 + 05 §3.6 `CalendarCell` | SPÉCIFIABLE | 9 |
| 7 | [calendrier-semaine](./calendrier-semaine.md) | Calendrier (vue semaine, Pager) | Productivité | `/calendar` | 05 §4.4.1 + 05 §3.4 `Pager` | SPÉCIFIABLE | 9 |
| 8 | [cours-detail](./cours-detail.md) | Cours (détail) | Learning | `/learn/:id` | 05 §4.6.2 l. 2521-2563 + WDS 03.6 | SPECIFIED | 9 |
| 9 | [cours-liste](./cours-liste.md) | Cours (liste) | Learning | `/learn` | 05 §4.6.2 l. 2521-2563 | SPECIFIED | 6 |
| 10 | [discovery-feed](./discovery-feed.md) | Discovery feed (S-27) | Discovery | `/discovery` | WDS 03.2 + docs/discovery/overview.md + ADR §13.9 (OQ-41) | CLAIMÉ → SPECIFIED | 7 |
| 11 | [discovery-sheet](./discovery-sheet.md) | Fiche de découverte (S-40, détail d'une `DiscoveryItem`) | Discovery | `/discovery/:id` (BottomSheet sur le feed) | WDS 03.3 + ADR §13.8 (OQ-42) | ADDITIF | 14 |
| 12 | [eisenhower](./eisenhower.md) | Matrice d'Eisenhower (quadrants) | Productivité | vue quadrants (sous `/tasks`) | docs/productivity/eisenhower.md (G-L5, NEEDS_DECISION) + ADR §2.3 (OQ-16) | ADDITIF | 21 |
| 13 | [exercises-proof](./exercises-proof.md) | Exercices de preuve | Learning | `/learn/:id` | WDS 01.6 + catalog `learning.import` (OQ-36) | ADDITIF | 8 |
| 14 | [fiches-detail](./fiches-detail.md) | Fiches (détail) | Learning | `/learn/:id` (overlay) | 05 §4.7.1 l. 2564-2639 (7 structures ADR §17) | SPECIFIED | 19 |
| 15 | [fiches-liste](./fiches-liste.md) | Fiches (liste) | Learning | `/learn/:id` (overlay) | 05 §4.7.1 l. 2564-2639 | SPECIFIED | 12 |
| 16 | [goal-feature-detail](./goal-feature-detail.md) | Détail d'une feature d'un objectif | Productivité | `/goals/:id/features/:fid` | code `goals/index.tsx:120` + goal-dashboard-ui (OQ-13) | ADDITIF / SPECIFIED | 10 |
| 17 | [habitudes](./habitudes.md) | Habitudes | Productivité | `/habits` | 05 §4.3.5 l. 1699-1786 + WDS 05.1 (OQ closes) | SPECIFIED | 15 |
| 18 | [home](./home.md) | Home (welcome, AD-14, 7 slots) | Home | `/home` | 05 §4.1.2 l. 1360-1425 + goal-dashboard-ui S1 + 02 §6.2 | SPECIFIED | 20 |
| 19 | [kanban](./kanban.md) | Kanban global (board transverses par statut) | Productivité | `/projects` (vue Kanban) | 05 §4.3.3 l. 1569-1633 + WDS 05.4 | SPÉCIFIABLE | 14 |
| 20 | [knowledge-node](./knowledge-node.md) | Nœud de connaissance (détail d'un `SemanticNode`) | Knowledge | `/knowledge/:nodeId` | docs/knowledge/overview.md §4/§11/§16 (OQ-40) | CLAIMÉ → SPECIFIED | 7 |
| 21 | [knowledge-tree](./knowledge-tree.md) | Arbre sémantique (Knowledge tree, AD-10) | Knowledge | `/knowledge` | docs/knowledge/overview.md §1/§4/§5 (OQ-39) | CLAIMÉ → SPECIFIED | 7 |
| 22 | [mirror-cognitive](./mirror-cognitive.md) | Mirror cognitif | Learning | `/mirror` | 05 §4.9.2 l. 2840-2924 + WDS 01.5 + docs/learning/overview.md §21 | SPECIFIED | 8 |
| 23 | [mode-coach](./mode-coach.md) | Mode coach | Learning | `/coach` | 05 §4.9.1 l. 2760-2839 + WDS 04.4 | SPECIFIED | 8 |
| 24 | [not-found](./not-found.md) | Not found / feature-disabled (fallback wildcard `*`) | Shell | `*` (wildcard) | page matrix S2 + feature-registry S6 + ui-libraries §9.1 l. 387 (OQ-48) | CLAIMÉ → SPECIFIED | 4 |
| 25 | [objectifs-detail](./objectifs-detail.md) | Objectifs (détail, dashboard mission-control, 5 layouts adaptatifs) | Productivité | `/goals/:id` | 05 §4.3.4 l. 1635-1697 + WDS 02.3 + goal-dashboard-ui | SPECIFIED | 32 |
| 26 | [objectifs-liste](./objectifs-liste.md) | Objectifs (liste) | Productivité | `/goals` | 05 §4.3.4 l. 1635-1697 + WDS 02.2 | SPECIFIED | 16 |
| 27 | [onboarding](./onboarding.md) | Onboarding (3 sous-écrans S1/S2/S3) | Onboarding | `/onboarding` (boot, avant `/home`) | 05 §4.1.1 l. 1332-1358 + WDS 04.1 | GAP → SPECIFIED (OQ-1…14, closes 1-3) | 28 |
| 28 | [progress-dashboard](./progress-dashboard.md) | Progress dashboard (today/week/month/trajectory) | Progress | `/progress` (+ `/progress/:id`) | 05 §4.5.2 l. 2410-2477 + ADR §18.6 + docs/progress/overview.md (OQ-43) | CLAIMÉ → SPECIFIED | 8 |
| 29 | [projets-detail](./projets-detail.md) | Projets (détail, 4 vues Gantt/Kanban/Timeline/List + milestones + templates) | Productivité | `/projects/:id` | 05 §4.3.2 l. 1481-1568 + 02 §6.1 | SPÉCIFIABLE (fragment complété 2026-09-28) | 46 |
| 30 | [projets-liste](./projets-liste.md) | Projets (liste) | Productivité | `/projects` | 05 §4.3.1 l. 1430-1479 + 02 §6.1 | SPECIFIED | 10 |
| 31 | [qcm](./qcm.md) | QCM | Learning | `/learn/:id` | 05 §4.8.2 l. 2698-2759 + WDS 01.4 | SPECIFIED | 9 |
| 32 | [retro-actions](./retro-actions.md) | Rétro-actions (journal des décisions, post-rétrospective) | Productivité | (reviews) | WDS 06.3 + 05 §4.5.1 l. 2229-2408 | SPÉCIFIABLE (ADDITIF) | 9 |
| 33 | [revues-jour](./revues-jour.md) | Revues (jour) | Productivité | (reviews) | 05 §4.5.1 l. 2229-2409 + 05 §3.4 `Pager` | SPÉCIFIABLE | 5 |
| 34 | [revues-mois](./revues-mois.md) | Revues (mois) | Productivité | (reviews) | 05 §4.5.1 + WDS 06.2 | SPÉCIFIABLE | 6 |
| 35 | [revues-semaine](./revues-semaine.md) | Revues (semaine) | Productivité | (reviews) | 05 §4.5.1 + WDS 06.1 | SPÉCIFIABLE | 11 |
| 36 | [routines](./routines.md) | Routines | Productivité | `/routines` | 05 §4.3.6 l. 1787-1891 + WDS 05.2 (OQ closes) | SPECIFIED | 20 |
| 37 | [settings](./settings.md) | Settings (sélecteur thème 10+3 + preview) | Settings | `/settings` | design-system/overview §6 + WDS 04.5 (OQ-47) | GAP → SPECIFIED | 4 |
| 38 | [slide-ascent](./slide-ascent.md) | Slide ascent (palette 12 types de slides) | Ascent | `/goals/:id/ascent` | docs/ascent/overview.md S11-S14 + WDS S-41 | ADDITIF / SPECIFIED | 16 |
| 39 | [taches-detail](./taches-detail.md) | Tâches (détail) | Productivité | `/tasks/:id` | WDS 05.5 §1-§11 (OQ closes) + 05 §3/§4.3.3 | ADDITIF / SPECIFIED | 8 |
| 40 | [taches-liste](./taches-liste.md) | Tâches (liste) | Productivité | `/tasks` | WDS 05.3 (OQ closes) + 05 §3.3/§3.4/§3.7 + catalog `productivity.tasks` | ADDITIF / SPECIFIED | 12 |
| 41 | [flashcards](./flashcards.md) | Flashcards (révision FSRS) | Learning | `/learn/:id` (overlay IonModal) | 05 §4.8.1 l.2640-2697 + WDS 01.3 | SPÉCIFIABLE | 8 |
| 42 | [inbox](./inbox.md) | Inbox / Capture (capture universelle + triage, S-23) | Productivité (additif) | `/inbox` (route adjacente, S-23, EXPERIENCE §IA L59) | WDS 04.2 + catalog `productivity.inbox` (`docs/features/master-feature-catalog.md` l.18) | ADDITIF / SPÉCIFIABLE (relecture 3/3, doc créé — il était **ABSENT** du lot ; `_report.md` §2 / `INDEX_REVIEW.md` §4.3 l'inscrivaient « à écrire ») | 11 |
| 43 | [focus-mode](./focus-mode.md) | Focus mode (7 états + blocklist v1.8 DPC, session screen + bilan sheet) | Productivité | `/focus` (tab-adjacent, T3) | 05 §4.4.2 l.2044-2228 + `docs/focus-mode/spec.md` (OQ-17 DPC) | SPÉCIFIABLE (lot final, créé 2026-09-29) | 8 |
| 44 | [timeline-gantt](./timeline-gantt.md) | Timeline Gantt (vue projet, `projets-detail`) | Productivité | `/projects` (vue interne T4, 05 §4.3.2 l.1486-1487 + WDS 02.5) | 05 §4.3.2 l.1486-1487 + WDS 02.5 | SPÉCIFIABLE (lot final, créé 2026-09-29) | 10 |

## Slugs de l'inventaire non encore documentés (à créer pour boucler le 54)

Référencés dans `_inventory.md` §2 mais **sans doc** dans ce répertoire :
`projets-detail-vue-liste` / `-vue-kanban` / `-vue-timeline` / `-vue-gantt`
(compris dans `projets-detail` §2-§5, 05 §4 l.1320-1321 — la scission
vue-slug distinct vs vue-in-`projets-detail` = OQ-1 du registre global,
**non tranchée**), plus les enveloppes `calendrier` / `revues` / `objectifs` /
`onboarding` (#49-53, même question OQ-1).

> **Mis à jour (lot final, 2026-09-29)** : les 4 écrans « à écrire » de la
> relecture 3/3 (`focus-mode`, `flashcards`, `inbox`, `timeline-gantt`) sont
> **tous créés** — ils figurent dans la table 44 docs ci-dessus (lignes 41-44).
> Les 6 docs transverses (`_inventory`, `_floating-surfaces`,
> `_open-questions`, `INDEX_REVIEW`, `_report`, et le nouveau
> **`_flows`** = interconnexion des pages) sont **tous existants** — voir la
> table « Liens de navigation » ci-dessus. Il ne reste que l'arbitrage du
> OQ-1 (règle de comptage 44 SSoT vs 54 candidats) pour figer définitivement
> l'index, qui est une décision de la Design System team, pas un doc manquant.

## Notes de synthèse

- **44 docs écrans** écrits à ce jour (41 docs initiaux + `flashcards` +
  `inbox` + `focus-mode` + `timeline-gantt` = **44**, table 44 docs ci-dessus)
  ; le comptage exact des OQ locales (colonne « OQs §14 ») à re-synchroniser
  avec `_open-questions.md` (registre consolidé, 374 OQ / 256 ouvertes).
- **Conventions OQ locales** : chaque doc §14 numérote ses OQ propres pour éviter
  la collision avec le registre global (`_inventory.md` §3, l. 176-192 :
  OQ-1/13/16/36/39/40/41/42/43/44/46/47/48). OQ-1 (règle de comptage 44→54) est
  la 1ʳᵉ du registre global et **précède** tous les lots de spécification
  (blocant pour l'index + le rapport final — à trancher par la Design System
  team).
- **Interconnexion** : les docs écrans ne se suffisent pas entre eux — le doc
  transversal **`_flows.md`** (lot final) recense qui ouvre qui (matrice
  écran → surfaces flottantes ouvertes), les contrats partagés (AD-7 local-first,
  AD-9 targeted events, AD-15 shared domain types, AD-17 3-layer theming), la
  machine à états cross-pages (S6/§6.1 s'étendant sur plusieurs écrans), et la
  sémantique `router.tsx` (17 routes figées) ↔ 44 slugs (plusieurs vues T4 /
  overlays T2 par route). 8 OQ interconnexion dans `_flows.md` §8 (pointeurs
  vers des OQ déjà existantes, pas de nouvelle OQ isolée).
- **Dérives à arbitrer** (non bloquant pour l'exécution frontend, signalé) :
  `progress-dashboard` et `analytics` partagent la route `/progress`
  (`analytics` = vue du tab 4, `progress-dashboard` = `:/progress/:id` +
  trajectory) — dédupliquer ou renommer (cf. `_flows.md` §8 OQ-08).
- **Docs transverses** : les 6 (`_inventory`, `_floating-surfaces`,
  `_open-questions`, `INDEX_REVIEW`, `_report`, `_flows`) sont **tous
  existants** (lot final, 2026-09-29) — plus aucun doc transversal « à créer ».
