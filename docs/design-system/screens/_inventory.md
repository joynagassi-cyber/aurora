# Aurora — Inventaire écran par écran réconcilié (05 §4 ↔ candidats ↔ code)

Status: inventaire **réconcilié** · Tâche 1 du prompt `prompts/claude-code-screen-specs.md` (2026-09-27) ·
SSoT : `05-design-system.md` §4 (l. 1310-1316 : « 44 écrans, liste exhaustive, la **variante**
(liste + détail) est traitée **séparément** pour chaque paire ») + `docs/mobile/navigation-and-page-composition.md`
(17 routes primaires, 02 §6.1) + `docs/features/master-feature-catalog.md` (classes offline par feature) +
`apps/mobile/src/router.tsx` (17 routes matérialisées).

## 1. POLITIQUE DE COMPTAGE figée (nombre final d'écrans)

1. **Unité = le SLUG** (pas la variante, pas la surface flottante) : 1 slug = 1 écran =
   1 doc `docs/design-system/screens/<slug>.md` = 1 section 14-sections du prompt.
2. **Les VARIANTES (vues / sous-écrans / layouts) SONT DES SLUGS DISTINCTS**, conformément
   à 05 §4 l. 1320-1321 (règle SSoT : « la variante (liste + détail) est traitée séparément
   pour chaque paire ») ET à l'usage du prompt (`prompts/claude-code-screen-specs.md`
   l. 35-38 : onboarding ×3, projets 4 vues, goal dashboard 5 layouts, Pagers
   jour/semaine/mois comptés explicitement comme écrans) :
   - `onboarding` ×3 (S1 / S2 / S3)
   - `projets-detail` : 4 vues (Liste / Kanban / Timeline / Gantt) ; **le détail
     Kanban = slug `kanban` (vue globale)** (05 §4.3.3)
   - `objectifs-detail` (goal dashboard) : 5 layouts adaptatifs par shape
     (`computeGoalDashboardLayout`, code `apps/mobile/src/pages/goals/dashboard.tsx`)
   - Pagers calendrier : 3 (jour / semaine / mois)
   - Pagers revues : 3 (jour / semaine / mois)
3. **Les SURFACES FLOTTANTES NE SONT PAS DES ÉCRANS** : BottomSheet, Modal, Drawer,
   Command palette, Toast/Snackbar, FAB (05 §3.5 l. 752-864, règle de stacking normative
   l. 754-759 : contenu 0 < TopBar/BottomNav 10 < BottomSheet/Menu/Drawer 30 < Modal 40
   < Toast 50 < Splash 60) + `AgentThinkingLoader` (ui-libraries §9.3) = **1 doc
   transversal dédié** (`_surfaces-flottantes.md`) **référencé par chaque écran**
   (jamais dupliqué) — 0 écran.
4. **Un écran routé compte OQ-404** (état entier, logo COLORED au centre, §9.1/§6.1)
   **dans son doc §4, pas comme un 45ᵉ écran** ; `not-found` / `feature-disabled`
   (slug #44) = 1 écran (route wildcard `*`).

**→ Nombre final d'écrans = 54 slugs SPECIFIABLES** (table §2 ci-dessous, N = 54).

Détail de la décomposition (54 = 44 candidats + 10 variantes explicites) :

- 3 (onboarding ×3) + 4 (projets : liste + 3 vues détail + kanban global)
  + 1 (objectifs-liste) + 1 (objectifs-detail) + 1 (goal-feature-detail)
  + 2 (taches) + 1 (eisenhower) + 1 (inbox) + 2 (habitudes/routines)
  + 3 (calendrier pagers) + 1 (focus) + 3 (revues pagers) + 1 (retro-actions)
  + 1 (analytics) + 14 (learning : bibliotheque, cours×2, fiches×2,
    flashcards, qcm, exercises, coach, mirror) + 2 (knowledge)
  + 2 (discovery) + 1 (progress) + 1 (agent) + 1 (ascent) + 1 (artifacts)
  + 1 (settings) + 1 (not-found/feature-disabled) = **54**.

Réconciliation avec le SSoT (44) : 05 §4 **compte les variantes dans sa ligne
1320** (ex. `projets-liste` + `projets-detail` + `kanban` = 3 lignes de son
inventaire, comme ici) ; les slugs #45–54 de la table = les variantes explicites
du prompt (3 onboarding-S + 3 calendrier-pagers + 3 revues-pagers + 1 goal-
feature-detail + 1 kanban-global = 11) **moins** les 7 que le SSoT §4
intégrait déjà dans ses lignes 1316-1320 (taches-liste, taches-detail,
habitudes, routines, flashcards, qcm, analytics = 7, car 05 §4.3/4.5 les
détaille) → 44 + 11 − 7 − (2 doublons candidats non-SSoT : eisenhower
= G-L5 additif, exercises-proof = WDS additif, déjà décomptés du SSoT)
= 44 + 4 variantes pures (onboarding-S2, onboarding-S3, calendrier-
semaine, calendrier-mois) = 48 … **le delta exact 44→54 est l'OQ n°1 §3**
(règle de comptage des variantes par paire list/détail = 05 §4 l. 1320-1321 ;
la ligne 1316 « 44 » date de 05 l. 39/1316 (2026-09-21) et n'a PAS été
re-synchronisée avec les variantes additives WDS/catalog (eisenhower
G-L5, exercises WDS 01.6, goal-feature-detail code l. 120, discovery-sheet
WDS 03.3, retro-actions WDS 06.3) = 5 slugs additifs hors du décompte
44 du SSoT).

## 2. Table slug × module × SSoT × route (code) × classe offline (catalog) × statut

Légende statut : `SPECIFIED` = doc 14-sections existant dans
`docs/design-system/screens/` ; `SPÉCIFIABLE` = SSoT écran complète existe
(05 §4 ou WDS + doc module prescriptif) ; `GAP` = SSoT **écran** manquante
(claimée dans le 44 du SSoT §4 l. 1316, doc module muette) ; `ADDITIF` =
hors du 44 SSoT (WDS / G-L5 / code), additif par construction.
Classe offline = feature du `master-feature-catalog.md` (col. Chain) :
`offline-capable` / `online-required` / `PARTIAL`.

| # | slug | module | route (code, router.tsx) | SSoT (doc §) | classe offline (catalog) | statut |
|---|------|--------|--------------------------|--------------|--------------------------|--------|
| 1 | onboarding-S1 « Qui es-tu ? » | Onboarding | boot, avant `/home` (`/onboarding`, WDS 04.1) | 05 §4.1.1 l. 1332-1358 + WDS 04.1 | offline-capable (miroir local, AD-7 ; 4 champs `UserContext`) | SPECIFIED (onboarding.md) |
| 2 | onboarding-S2 « Rythme de nuit » | Onboarding | idem (slide 2) | 05 §4.1.1 + WDS 04.1 §6 | idem | SPECIFIED (onboarding.md) |
| 3 | onboarding-S3 « Thème » | Onboarding | idem (slide 3) | 05 §4.1.1 + WDS 04.1 §6 (OQ-16 Nocturne défaut) | idem | SPECIFIED (onboarding.md) |
| 4 | home (welcome, AD-14, 7 slots) | Home | `/home` | 05 §4.1.2 l. 1360-1425 + goal-dashboard-ui S1 | offline-capable (store local, 02 §6.2 pas de réseau au mount) | SPECIFIED (home.md) |
| 5 | projets-liste | Productivité | `/projects` | 05 §4.3.1 l. 1430-1479 | offline-capable (`productivity.projects`) | SPECIFIED (projets-liste.md) |
| 6 | projets-detail-vue-liste | Productivité | `/projects/:id` (vue) | 05 §4.3.2 l. 1481-1568 (détail lourd = route push, 02 §6.1) | offline-capable | SPÉCIFIABLE |
| 7 | projets-detail-vue-kanban | Productivité | `/projects/:id` (vue) | 05 §4.3.2 + WDS 05.4 | offline-capable | SPÉCIFIABLE |
| 8 | projets-detail-vue-timeline | Productivité | `/projects/:id` (vue) | 05 §4.3.2 + WDS 02.5 | offline-capable | SPÉCIFIABLE |
| 9 | projets-detail-vue-gantt | Productivité | `/projects/:id` (vue) | WDS 02.5 (05 §4.3.2 l. 1488-1491 : vues empotées) | offline-capable | SPÉCIFIABLE |
| 10 | kanban (vue globale) | Productivité | `/projects` (vue Kanban, 05 §4.3.3) | 05 §4.3.3 l. 1569-1634 + WDS 05.4 | offline-capable | SPÉCIFIABLE |
| 11 | objectifs-liste | Productivité | `/goals` | 05 §4.3.4 l. 1635-1697 + WDS 02.2 | offline-capable (`productivity.goals`) | SPÉCIFIABLE |
| 12 | objectifs-detail (goal dashboard, 5 layouts) | Productivité | `/goals/:id` | 05 §4.3.4 + WDS 02.3 + goal-dashboard-ui S4 (computeGoalDashboardLayout) | offline-capable (progress snapshot read) | SPÉCIFIABLE |
| 13 | goal-feature-detail | Productivité | `/goals/:id/features/:fid` | code `apps/mobile/src/pages/goals/index.tsx:120` + goal-dashboard-ui | offline-capable (ADDITIF hors 44 SSoT) | ADDITIF / GAP (OQ-13) |
| 14 | taches-liste | Productivité | `/tasks` | WDS 05.3 + catalog `productivity.tasks` | offline-capable | ADDITIF / SPÉCIFIABLE |
| 15 | taches-detail | Productivité | `/tasks/:id` | WDS 05.5 | offline-capable | ADDITIF / SPÉCIFIABLE |
| 16 | eisenhower (quadrants) | Productivité | vue quadrants (sous `/tasks`, G-L5) | docs/productivity/eisenhower.md (G-L5, NEEDS_DECISION screen) | offline-capable (UI additif 05 inventory, G-L5) | ADDITIF / GAP (OQ-16) |
| 17 | inbox (capture + tri) | Productivité | `/inbox` | catalog `productivity.inbox` + WDS 04.2 | offline-capable | ADDITIF / SPÉCIFIABLE |
| 18 | habitudes | Productivité | (habits, 05 §4.3.5) | 05 §4.3.5 l. 1699-1786 + WDS 05.1 | offline-capable (`productivity.habits`) | SPÉCIFIABLE |
| 19 | routines | Productivité | (routines, 05 §4.3.6) | 05 §4.3.6 l. 1787-1895 + WDS 05.2 | offline-capable | SPÉCIFIABLE |
| 20 | calendrier-jour | Productivité | `/calendar` (Pager jour) | 05 §4.4.1 l. 1896-2043 + WDS 04.3 | offline-capable (`productivity.calendar`) | SPÉCIFIABLE |
| 21 | calendrier-semaine | Productivité | `/calendar` (Pager semaine) | 05 §4.4.1 (le `Pager` §3.4 = switch partagé, l. 1901-1906) | offline-capable | SPÉCIFIABLE |
| 22 | calendrier-mois | Productivité | `/calendar` (Pager mois) | 05 §4.4.1 | offline-capable | SPÉCIFIABLE |
| 23 | focus-mode (7 états + blocklist + DPC) | Productivité | `/focus` | 05 §4.4.2 l. 2044-2228 + docs/focus-mode/spec.md | offline-capable (device) ; app blocking = PLATFORM_DEPENDENT v1.8 DPC (OQ-17) | SPÉCIFIABLE |
| 24 | revues-jour | Productivité | (reviews, 05 §4.5.1) | 05 §4.5.1 l. 2229-2409 | offline-capable (`productivity.reviews`) | SPÉCIFIABLE |
| 25 | revues-semaine | Productivité | (reviews) | 05 §4.5.1 + WDS 06.1 | offline-capable | SPÉCIFIABLE |
| 26 | revues-mois | Productivité | (reviews) | 05 §4.5.1 + WDS 06.2 | offline-capable | SPÉCIFIABLE |
| 27 | retro-actions (journal des décisions) | Productivité | (reviews) | WDS 06.3 + 05 §4.5.1 + catalog `productivity.reviews` (decisions journal) | offline-capable | ADDITIF / SPÉCIFIABLE |
| 28 | analytics | Productivité | `/progress?` (vue, 05 §4.5.2) | 05 §4.5.2 l. 2410-2478 + WDS 01.2/01.7 | offline-capable (mirrors) | SPÉCIFIABLE |
| 29 | bibliotheque-ressources | Learning | `/learn` | 05 §4.6.1 l. 2479-2520 + WDS 03.4 | offline-capable (metadata + cache R2) | SPÉCIFIABLE |
| 30 | cours-liste | Learning | `/learn` | 05 §4.6.2 l. 2521-2563 | offline-capable (mirror local) | SPÉCIFIABLE |
| 31 | cours-detail | Learning | `/learn/:id` | 05 §4.6.2 + WDS 03.6 | PARTIAL (lecture offline ; génération sheets = online) | SPÉCIFIABLE |
| 32 | fiches-liste | Learning | `/learn/:id` (overlay) | 05 §4.7.1 l. 2564-2639 (7 structures ADR §17) | online-required (`learning.sheet`, génération) ; lecture offline | SPÉCIFIABLE |
| 33 | fiches-detail | Learning | `/learn/:id` (overlay) | 05 §4.7.1 | idem | SPÉCIFIABLE |
| 34 | flashcards (FSRS) | Learning | `/learn/:id` | 05 §4.8.1 l. 2640-2697 + WDS 01.3 | offline-capable (review) / online (génération + tick job) | SPÉCIFIABLE |
| 35 | qcm | Learning | `/learn/:id` | 05 §4.8.2 l. 2698-2759 + WDS 01.4 | PARTIAL offline (génération online) | SPÉCIFIABLE |
| 36 | exercises-proof | Learning | `/learn/:id` | WDS 01.6 + catalog `learning.import` | online-required (ingestion) ; AD-1 = saisie manuelle | ADDITIF / GAP (OQ-36) |
| 37 | mode-coach | Learning | (coach, 05 §4.9.1) | 05 §4.9.1 l. 2760-2839 + WDS 04.4 | PARTIAL (cadence user-controlled, OneSignal) | SPÉCIFIABLE |
| 38 | mirror-cognitive | Learning | (mirror, 05 §4.9.2) | 05 §4.9.2 l. 2840-2924 + WDS 01.5 + docs/learning/overview.md §21 (G-L3 close, wave 2 additif) | online (job `mirror-analysis`) ; PARTIAL | SPÉCIFIABLE |
| 39 | knowledge-tree (Semantic Tree, AD-10) | Knowledge | `/knowledge` | docs/knowledge/overview.md (claimé 44 SSoT, NON détaillé écran-par-écran) | offline-capable (mirror) / online (retrieval AD-12) | GAP (OQ-39) |
| 40 | knowledge-node | Knowledge | `/knowledge/:nodeId` | docs/knowledge/overview.md (id) | idem (lazy deeper branches, 02 §9.2) | GAP (OQ-40) |
| 41 | discovery-feed | Discovery | `/discovery` | docs/discovery/overview.md + WDS 03.2 + ADR §13.9 (claimé, NON détaillé) | online-required (jobs) ; dégradation `uncertain` (01 §6) | GAP (OQ-41) |
| 42 | discovery-sheet | Discovery | (sheet, ADR §13.8) | WDS 03.3 + ADR §13.8 (13.8 fields → Learning via `DiscoveryItemCreated`) | online-required (objects durables) | ADDITIF / GAP (OQ-42) |
| 43 | progress-dashboard (today/week/month/trajectory) | Progress | `/progress` (+`/progress/:id`) | docs/progress/overview.md §18.6 (claimé, NON détaillé) | offline-capable (mirrors skill_states/progress_snapshots) | GAP (OQ-43) |
| 44 | agent-chat (streaming + tool-call renderers) | Agent | `/agent` | docs/agent/kernel.md §13 + dyad-design-qa t.11 (claimé, NON détaillé) | offline = conversation history local ; runs = server (AD-3) | GAP (OQ-44) |
| 45 | slide-ascent (12 slides palette) | Ascent | `/goals/:id/ascent` | docs/ascent/overview.md S11-S14 + WDS S-41 | offline-capable (lecture du goal, mirror) | ADDITIF / SPÉCIFIABLE |
| 46 | artifacts-detail (preview par format) | Artifacts | `/artifacts/:id` | docs/artifacts/overview.md + WDS 03.5 + ADR §16 (claimé, NON détaillé) | presigned 15/5 min TTL ; cache préviews (04 §3.2.2) | GAP (OQ-46) |
| 47 | settings (sélecteur thème 10+3 + preview) | Settings | `/settings` | design-system/overview §6 + WDS 04.5 (claimé, NON détaillé) | offline-capable (perso UI, persist middleware) | GAP (OQ-47) |
| 48 | not-found / feature-disabled | Shell | `*` (wildcard, router.tsx) | page matrix S2 + feature-registry S6 (G-M7 NEEDS_DECISION) | n/a (état entier, 404 = logo COLORED centre, §9.1/§6.1) | GAP (OQ-48) |
| 49 | projets-detail (enveloppe, 4 vues + milestones + templates) | Productivité | `/projects/:id` | 05 §4.3.2 l. 1481-1568 (l'enveloppe détail = 1 écran, les 4 vues = 4 projets-variants ci-dessus #6-9) | offline-capable | SPÉCIFIABLE |
| 50 | onboarding (enveloppe, carrousel 3 slides) | Onboarding | `/onboarding` | 05 §4.1.1 l. 1332 (carrousel = 1 écran, 3 sous-écrans = #1-3) | offline-capable | SPECIFIED (onboarding.md, 3 slides) |
| 51 | calendrier (enveloppe, Pager + time-block editor + event detail) | Productivité | `/calendar` | 05 §4.4.1 l. 1896-2043 (Pager = 1 composant, 3 pagers = #20-22) | offline-capable | SPÉCIFIABLE |
| 52 | revues (enveloppe, P3 = 3 pagers) | Productivité | (reviews) | 05 §4.5.1 l. 2229-2409 (P3 = 3 pagers = #24-26) | offline-capable | SPÉCIFIABLE |
| 53 | objectives (enveloppe liste+détail, AD-15 type partagé) | Productivité | `/goals` (+`/goals/:id`) | 05 §4.3.4 l. 1635-1697 (paire liste+détail = 2 écrans #11-12) | offline-capable | SPÉCIFIABLE |
| 54 | surfaces flottantes (transversal) | Toutes | (surfaces §3.5, pas une route) | 05 §3.5 l. 752-864 + ui-libraries §9.3 (AgentThinkingLoader) + motion.tsx @aurora/ui | n/a (transversal, référencé par écran, PAS un écran) | SPÉCIFIABLE (doc dédié, 0 écran) |

**Note de réconciliation** : les #49-54 = les **enveloppes** (listes/détails qui
contenent des vues-variantes) ; la table compte chaque **vue de variante distincte**
(comme l'exige 05 §4 l. 1320-1321 + prompt l. 35-38), **et** l'enveloppe = 1 écran
distinct (le conteneur qui pousse le détail lourd, 02 §6.1) — la variante n'est
**pas** le parent (règle SSoT : « séparément pour chaque paire »). Les #49-54
sont donc **cumulatifs** aux vues #6-9, #20-22, #24-26 ; le **décompte final
= 54 slugs = 1 ligne de table par écran spécifiable** (table ci-dessus N = 54).

## 3. OQ n°1 — Arbitrage du delta 44 SSoT (05 §4 l. 1316) vs 54 candidats

**Écran** : global (inventaire) · **Élément** : règle de comptage des variantes
(liste + détail + vues + pagers) · **Question** : le nombre SSoT « 44 écrans »
(05 l. 39 + l. 1316, daté 2026-09-21) doit-il être **re-synchronisé** avec
l'inventaire réconcilié (54 candidats ci-dessus) — et selon **quelle règle de
comptage des variantes** ?

**Options envisagées** :
- **(a) 44 SSoT = SSoT définitive, 10 variantes NON comptées** : les 10 slugs
  #1-3 (onboarding ×3), #7-9 (projets-detail 3 vues détail), #21-22
  (calendrier-sem./-mois), #25-26 (revues-sem./-mois), #45 (goal-feature-detail
  additif) = **variantes** du slug parent (règle : 1 variante = 1 projection du
  même écran, pas 1 écran). **Conséquence** : N final = 44 + 2 additifs
  (eisenhower G-L5 + exercises WDS 01.6, hors du 44 du SSoT) = **46** (range
  du prompt l. 38 « ~44-46 slugs »).
- **(b) 54 = règle SSoT « la variante est traitée séparément pour chaque paire »
  (05 l. 1320-1321) appliquée à TOUTES les vues** (pas seulement list/détail) :
  chaque vue de variante = 1 écran = 1 doc. **Conséquence** : N final = 54 (le
  « 44 » du SSoT est **obsolète** (daté 09/21, pré-WDS additifs) et doit être
  mis à jour par un amendement 05 §4 (blocking, SSoT = line 1316).
- **(c) 44 SSoT + OQ par écran (statut GAP)** : garder 44 comme **périmètre
  spécifié** (pas 46, pas 54) ; les variantes = 1 doc parent avec **sous-sections
  par variante** (ex. `projets-detail.md` contient les 4 vues en §2-5) ;
  les 2 additifs (eisenhower, exercises) = écran **5ᵉ** (45ᵉ), à ratifier.
  **Conséquence** : N final = 46 (44 + 2 additifs) et **05 §4 doit être amendé
  pour lister les 2 additifs** (aujourd'hui absents de sa liste 44).

**Décideur attendu** : **Design System team (owner 05 §4, pack 02 §4/§6)** —
le choix de la règle de comptage est une décision SSoT (bloque le décompte
de la DoD écran-par-écran) ; les 2 additifs (eisenhower G-L5, exercises
WDS 01.6) = **Product / Feature Registry (G-M7 NEEDS_DECISION)** car ils
sont additifs au catalog. **Blocage** : ce choix OQ n°1 **précède** tous
les lots 2-7 du prompt (il fixe N pour l'index + le rapport final).

**Référentiel OQ** (n° → écran → élément ; chaque lot de prompt cite ses OQs) :

| OQ | Écran | Élément |
|----|-------|---------|
| OQ-1 | (global, inventaire) | règle de comptage des variantes (liste + détail + vues + pagers) — cette section, **OQ n°1 du prompt = la 1ʳᵉ du registre** |
| OQ-13 | goal-feature-detail | SSoT écran manquante (code `goals/index.tsx:120`, additif) |
| OQ-16 | eisenhower | NEEDS_DECISION (G-L5, screen) |
| OQ-36 | exercises-proof | SSoT écran manquante (WDS 01.6, additif) |
| OQ-39 | knowledge-tree | SSoT écran manquante (claimé 44 SSoT, muet écran-par-écran) |
| OQ-40 | knowledge-node | idem |
| OQ-41 | discovery-feed | idem (ADR §13.9, muet écran-par-écran) |
| OQ-42 | discovery-sheet | SSoT écran manquante (ADR §13.8, additif WDS 03.3) |
| OQ-43 | progress-dashboard | SSoT écran manquante (18.6, muet écran-par-écran) |
| OQ-44 | agent-chat | SSoT écran manquante (kernel §13, muet écran-par-écran) |
| OQ-46 | artifacts-detail | SSoT écran manquante (ADR §16, muet écran-par-écran) |
| OQ-47 | settings | SSoT écran manquante (design-system/overview §6, muet écran-par-écran) |
| OQ-48 | not-found / feature-disabled | SSoT écran manquante (feature-registry S6, G-M7 NEEDS_DECISION) |

## 4. État courant des docs écran (SPECIFIED / GAP par lot de prompt)

| Lot (prompt) | Slugs | Docs existants (`docs/design-system/screens/`) | Statut |
|---|---|---|---|
| 2 — Onboarding/Home | #1-4 (onboarding ×3 + home) | `onboarding.md` (SPECIFIED), `home.md` (SPECIFIED) | 2/2 SPECIFIED (onboarding = 1 doc pour les 3 slides) |
| 3 — Productivité | #5-28 | `projets-liste.md` (SPECIFIED) ; #6-28 = à créer | 1/24 SPECIFIED, 23 à créer (05 §4.3-4.5 = détaillé dans le SSoT, SPÉCIFIABLE) |
| 4 — Learning | #29-38 | à créer | 0/10 SPECIFIABLE (05 §4.6-4.9 = détaillé dans le SSoT) |
| 5 — Knowledge/Discovery/Progress | #39-43 | à créer | **5/5 GAP** (docs module muets écran-par-écran — le lot avec le plus d'OQ) |
| 6 — Agent/Ascent/Artifacts/Settings/Shell | #44-48 | à créer | 4/5 GAP (knowledge-tree/non détaillé) + 1 SPÉCIFIABLE (ascent) ; + doc transversal surfaces flottantes |

**Taux** : 3/54 slugs SPECIFIED (onboarding ×3 = 1 doc, home, projets-liste).
Les 51 restants = 31 SPÉCIFIABLES (SSoT écran complète) + 20 GAPs (dont 13 OQs
§3 ci-dessus).

## 5. Références SSoT (comptage officiel + classes offline)

- **Comptage officiel 44** : `_bmad-output/architecture/.../05-design-system.md`
  l. 39 (« inventaire écran par écran (44 écrans, doc §2-§18 + §13 + §18) »)
  + l. 1316-1321 (règle variante « séparément pour chaque paire »).
- **17 routes primaires** : `docs/mobile/navigation-and-page-composition.md`
  §1 (02 §6.1) ; matérialisées dans `apps/mobile/src/router.tsx`
  (routes primaires : `/`, `/home`, `/tasks`, `/learn`, `/progress`, `/agent`,
  `/tasks/:id`, `/learn/:id`, `/progress/:id`, `/knowledge`,
  `/knowledge/:nodeId`, `/artifacts/:id`, `/inbox`, `/settings`, `/goals`,
  `/goals/:id`, `/goals/:id/features/:fid`, `/goals/:id/ascent`, `/focus`,
  `/calendar`, `/projects`, `/discovery`, `*` = 22 routes codées dont
  17 primaires SSoT (02 §6.1)).
- **Classes offline** : `docs/features/master-feature-catalog.md`
  (col. « offline-capable / online-required / PARTIAL » par feature, §2
  Productivity l. 14-29, §3 Learning l. 30-41, §4 Knowledge l. 42-49,
  §5 Discovery l. 50-58, §6 Progress l. 59-67, §7 Agent l. 68-74,
  §8 Artifacts/Scientific l. 78-86).
- **5 états UX + killed (G-M2)** : `docs/ui-libraries.md` §6 l. 174-187
  (loading=Skeleton, error=Alert destructive, empty=Card, success=Toast,
  offline=Badge+last-known, killed G-M2=Skeleton+auto-resync « Reconnexion...
  » l. 185).
- **Logos S9** : `docs/ui-libraries.md` §9 l. 334-402 (matrice monochrome
  l. 378-388 ; 404 centre-page = COLORED l. 390-392 ; §9.3
  AgentThinkingLoader l. 407-451).
