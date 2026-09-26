---
# WDS Design Log — Aurora
project: Aurora
owner: Joy (via Freya)
created: 2026-09-23
---

## Progress

### 2026-09-25 — Phase 3: UX Scenarios Complete

**Agent:** Freya (WDS Designer) — scénario outlines ; workflow Ultracode (juges adversariaux)
**Scenarios:** 6 scénarios couvrant 33/40 surfaces (matrice `C-UX-Scenarios/00-ux-scenarios.md` : 31 assignées aux scénarios + S-29/S-31 shared + S-37 UNRECONCILED)
**Quality:** Good (5 Excellent + 1 Good, 0 Needs Work — minima step-07 atteints partout, workflow `wds3-quality-review` run `wf_c47d97af-cef`)

**Artifacts Created:**
- `_progress/scope-report.md` — Analyse de périmètre step-02 (typologie Dynamic App → Storyboard + Screen Flow, 40 surfaces S-01…S-40, 22 parcours nommés, 5 discrepancies UNRECONCILED, Mode Suggest)
- `_progress/strategic-chains.md` — Contexte stratégique step-03 (6 chaînes P1/P2/P3 + bloc shared, matrice de couverture)
- `C-UX-Scenarios/00-ux-scenarios.md` — Index des scénarios + Scenario Summary + Page Coverage Matrix
- `C-UX-Scenarios/01-horebs-progress-proof/01-horebs-progress-proof.md` — Horeb's Progress Proof (P1)
- `C-UX-Scenarios/02-horebs-gap-closure/02-horebs-gap-closure.md` — Horeb's Gap Closure (P2)
- `C-UX-Scenarios/03-horebs-active-discovery/03-horebs-active-discovery.md` — Horeb's Active Discovery (P2)
- `C-UX-Scenarios/04-horebs-foundation-setup/04-horebs-foundation-setup.md` — Horeb's Foundation Setup (P2)
- `C-UX-Scenarios/05-horebs-habit-loop/05-horebs-habit-loop.md` — Horeb's Habit Loop (P3)
- `C-UX-Scenarios/06-horebs-retrospective/06-horebs-retrospective.md` — Horeb's Retrospective (P3)

**Summary:** 6 scénarios Horeb (persona primaire P1) dérivés des 6 chaînes stratégiques (1:1, aucune chaîne orpheline), en respectant les invariants de spine (AD-14 composition Home fixe, AD-9 9 événements fermés, AD-7 offline-first, AD-15 UserContext SSoT). Décisions clés : format mixte Storyboard (workflows cœur) + Screen Flow (onboarding/capture→triage) ; scénario 02 corrigé hors workflow (off-by-one S-IDs + cibles chiffrées Q7 par step-07 G-A) ; S-39 Eisenhower laissée `[NEEDS_DECISION wave-2]` et S-37 UNRECONCILED déclarée, pas inventée (convention pont : NON COUVERT plutôt que fabrication).

**Next:** Phase 4 — UX Design

## Key Decisions

| Date | Décision | Phase | Par qui |
|------|----------|-------|---------|
| 2026-09-23 | Distillation WDS Phase 1/2 depuis le corpus spec-first (pas de ré-audit) ; artefacts WDS = ponts, `status: draft` | Phase 1-2: Brief + Trigger Map | Freya + Joy |
| 2026-09-25 | Plan 6 scénarios (1:1 avec les 6 chaînes P1/P2/P3, persona Horeb P1) approuvé ; S-39 NEEDS_DECISION | Phase 3: Scenarios (step-04) | Freya + Joy |
| 2026-09-25 | Mode Suggest (< 20 surfaces cœur par scénario) + typologie Dynamic App (Storyboard + Screen Flow) | Phase 3: Scenarios (step-02) | Freya |
| 2026-09-25 | Corrections hors workflow post step-05/07 : off-by-one S-IDs scénario 02 + cibles chiffrées Q7 (G-A) + note S-26/S-28 (G-C) + nom scénario 05 « Horeb's Habit Loop » | Phase 3: Scenarios (steps 05/07) | Freya |
| 2026-09-25 | **App agentique (décision Joy)** : depuis n'importe quelle page de l'app on doit pouvoir ouvrir l'interface chat agentique (S-29 `/agent`). **Option C ratifiée** : double entrée = 5ᵉ tab de la BottomNav (S-31) → `/agent` (entrée principale sur les écrans à BottomNav) + FAB chat global (back-up sur les écrans sans BottomNav : overlays de détail, focus-mode). Les 5 points d'entrée S-31 déjà déclarés (bouton UI · palette · trigger NL · deep link · automatisation) + le parcours AGT (scope-report #2) restent intacts ; le 5ᵉ tab = 3ᵉ point d'entrée, le FAB = 4ᵉ (bouton UI). NON COUVERT par le corps gelé (cible du 5ᵉ tab non nommée) — ratifié comme proposition WDS (OQ-4 close, 2026-09-25). Se propage à toutes les pages Phase 4 (composant partagé BottomNav S-31 + FAB global). | Phase 4: UX Design (step 08, page 01.1) | Joy |
| 2026-09-25 | **Ratification batch tranches 01 (scénario 01)** : toutes les OQ du scénario 01 closes (option A partout, sauf 01.1 OQ-3 = B et OQ-4 = C). OQ-1 01.1 (A : badge = sous-élément du bloc « progression critique », AD-14 7 items fixes) · OQ-3 01.1 (B : pas de désaturation spécifique Nocturne au niveau du bloc) · OQ-4 (C : double entrée S-29, voir ci-dessus) · 01.2 (A : 5 questions fixes + A : CTA « Réviser » toujours visible + A : contract de preuve interne) · 01.3 (A : 4 niveaux FSRS + A : timer affiché par défaut) · 01.4 (A : QCM à la volée + A : signal 7 non-cachable) · 01.5 (A : vocal par défaut + A : analyse en une fois) · 01.6 (A : exercice à la volée + A : sous-étapes adaptatives 3-7) · 01.7 (A : CTA « Terminer » + A : 4 critères Q7 dans les 5 questions). Le flag S-38 UNRECONCILED (01.6 OQ-4) reste au standup wave-0. | Phase 4: UX Design (batch tranches 01, scénario 01) | Joy |

## Journal des runs workflow / Backlog

- **Current**: **Phase 4 (UX Design) — EN COURS (09/25)**. Batch 09/25 : **scénarios 03/04/05/06 + S-41 spécifiés** (21 pages, workflow `wds4-ux-design-batch` run `wf_b69cc27b-9c3` + fix 05.3 run `wf_7ec76d8c-e6f`). **21/21 fiches de page en place** (03.1–03.6 · 04.1–04.5 · 05.1–05.6 · 06.1–06.3 · S-41). **Batch tranches 01 ratifié (09/25, Joy)** : scénario 01 (7 pages 01.1–01.7) = OQ closes (01.1 A/B/C · 01.2 A/A/A · 01.3 A/A · 01.4 A/A · 01.5 A/A · 01.6 A/A · 01.7 A/A) — seul le flag S-38 UNRECONCILED (01.6) reste au standup wave-0. **Phase 4 = terminée en spec : 28/28** (scénarios 01 = 7 pages, 02 = 5, 03 = 6, 04 = 5, 05 = 6, 06 = 3 + S-41). Juge 05.3 : verdict FAIL mineur (3 remarques : étiquette AD-13 → pack 02 §7, CTA EmptyState déclaré Button ghost, signal 8 = ligne 8 du §7 non indexé) — **les 2 corrections textuelles ont été appliquées** ; le signal 8 reste une convention de famille. **~40 OQ closes** (scénarios 03–06 + S-41, ratifiées par Joy 09/25, détail ci-dessous) + **~13 OQ scénario 01 closes 09/25 (batch tranches 01)** → standup Phase 4 : reste S-38 UNRECONCILED (01.6, wave-0) + S-39 NEEDS_DECISION wave-2. **Mode = [S] Suggest.**

**Décisions Joy ratifiées (09/25) :**
- OQ-4 (chat S-29) : option **C** (5ᵉ tab BottomNav + FAB back-up sur écrans sans BottomNav) — NON COUVERT par le corps gelé, ratifié comme proposition WDS.
- OQ-1 (01.1) : option **A** (le badge « 12 révisions dues » est un sous-élément du bloc « progression critique », composition AD-14 reste 7 items fixes).
- OQ-3 (01.1) : option **B** (pas de désaturation spécifique au Nocturne au niveau du bloc, le thème gère la désaturation globalement).
- **Batch Phase 4 (scénarios 03–06 + S-41) : ratification Joy du 09/25 de toutes les OQ ouvertes** — option A ratifiée partout sauf : 04.1 OQ-3 (option B : redirect /inbox), 05.3 OQ-3 (option B : tri par priorité). Le flag S-39 NEEDS_DECISION wave-2 (05.6) reste au standup (flag de scénario, pas une OQ de la spec). Détail page par page : 03.1 (A : CTA fixe AD-14) · 03.2 (A : tri UserContext + A : badge visuel) · 03.3 (A : direct S-14 + A : BottomSheet) · 03.4 (A : direct S-36 + A : route push lourde /library) · 03.5 (A : direct /learn + A : BottomSheet) · 03.6 (A : engagement direct + A : mirror AD-7) · 04.1 (A : pré-rempli par inférence + A : écran 3 thème + B : redirect /inbox) · 04.2 (A : triage direct /learn + A : mirror AD-7) · 04.3 (A : kernel dédié AD-12/F-09 + A : 7 badges mirror AD-7) · 04.4 (A : texte statique + A : switch binaire + A : preset réutilisé onboarding) · 04.5 (A : aperçu statique + A : compte minimal + A : notifications par type) · 05.1 (A : tolérance jour courant + A : 7 semaines heatmap, contradiction sources a standup) · 05.2 (A : 1 colonne + A : check inline + A : pas de CTA global) · 05.3 (A : 1 colonne + A : « Ouvrir le Kanban » + B : tri par priorité) · 05.4 (A : tap-then-menu + A : 5 colonnes visibles) · 05.5 (A : 3 zones + A : checkboxes plates) · 05.6 (A : grille 2×2 + A : tap+menu ; S-39 NEEDS_DECISION wave-2 reste au standup) · 06.1 (A : heatmap 7×7 + A : CTA vers 06.2) · 06.2 (A : heatmap 4×7 + A : CTA vers 06.3 S-13) · 06.3 (A : 3 sections + A : CTA vers S-05 calendrier, ADR 19) · S-41 (A : slide Niveau 1 + A : liste verticale 4 semaines).

**OQ closes scénario 01 (09/25, ratifiées par Joy — batch tranches 01) :**
- 01.1 : OQ-1 (agrégation badge / 2 items) + OQ-3 (accent désaturé Nocturne) + OQ-4 (porte d'entrée chat S-29) **closes 09/25 (option A + option B + option C)**
- 01.2 : OQ-1 (5 questions fixes vs adaptatives) + OQ-2 (CTA « Réviser » conditionnel) + OQ-3 (contract de preuve affiché) **closes 09/25 (option A + option A + option A)**
- 01.3 : OQ-1 (niveaux FSRS 4 vs 3) + OQ-2 (timer optionnel) **closes 09/25 (option A : 4 niveaux + option A : timer affiché par défaut)**
- 01.4 : OQ-1 (génération à la volée vs pré-générée) + OQ-2 (distinction reconnaissance/transfert affichée par défaut) **closes 09/25 (option A + option A)**
- 01.5 : OQ-1 (vocal vs texte par défaut) + OQ-2 (streaming vs en une fois) **closes 09/25 (option A : vocal par défaut + option A : en une fois)**
- 01.6 : OQ-1 (génération à la volée vs pré-générée) + OQ-2 (nombre de sous-étapes) **closes 09/25 (option A + option A)** ; OQ-4 = S-38 UNRECONCILED reste au standup wave-0 (flag de surface, pas une OQ de la spec)
- 01.7 : OQ-1 (CTA « Terminer » vs retour automatique) + OQ-2 (4 critères Q7 dans les 5 questions ou section dédiée) **closes 09/25 (option A + option A)** ; OQ-4 close 01.1 (option C) inchangée

- **OQ scénario 01 (01.1–01.7) closes 09/25 (batch tranches 01, option X ratifiée par Joy)** : 01.1 (OQ-1 A + OQ-3 B + OQ-4 C) · 01.2 (A + A + A) · 01.3 (A : 4 niveaux + A : timer affiché par défaut) · 01.4 (A + A) · 01.5 (A : vocal par défaut + A : en une fois) · 01.6 (A + A ; OQ-4 = S-38 UNRECONCILED reste au standup wave-0) · 01.7 (A + A)
**OQ ouvertes (portées au standup Phase 4) :**
- 02.2 : OQ-1 (tri Cards par priorité) + OQ-2 (badge « En retard » fixe) **closes 09/25 (option B + option A, recommandations Freya validées par Joy)**
- 02.3 : OQ-1 (jalons mis en avant) + OQ-2 (CTA « Ouvrir le projet » unique) **closes 09/25 (option A + option A)**
- 02.4 : OQ-1 (groupement tâches par dépendance) + OQ-2 (CTA « Visualiser sur timeline » unique) **closes 09/25 (option B + option A)**
- 02.5 : OQ-1 (liste chronologique simple, pas de Gantt interactif — budget OQ-11) + OQ-2 (CTA « Générer la fiche » unique) **closes 09/25 (option A + option A)**
- 03.2 : OQ-1 (tri par UserContext vs date) + OQ-2 (badge typo visuel vs textuel) **closes 09/25 (option A : tri par UserContext + option A : badge visuel)**
- 03.1 : OQ-2 (CTA bloc suggestions Coach : fixe vs contextuel mode D1–D6) **closes 09/25 (option A : CTA fixe, AD-14)**
- 03.3 : OQ-1 (CTA « Work on this » → S-14 direct vs sélecteur d'engagement) + OQ-2 (sheet = BottomSheet vs route push lourde /discovery/:id) **closes 09/25 (option A : direct S-14 + option A : BottomSheet, 2 min de lecture)**
- 03.4 : OQ-1 (CTA « Ouvrir l'artefact » → S-36 direct vs sélecteur d'engagement) + OQ-2 (bibliothèque = route push lourde /library vs BottomSheet) **closes 09/25 (option A : direct S-36 + option A : route push lourde /library, matière centralisée)**
- 03.5 : OQ-1 (CTA « Ouvrir dans /learn » → S-25 direct vs sélecteur de point d'entrée) + OQ-2 (vue détail = route push /library/:id vs BottomSheet) **closes 09/25 (option A : direct /learn + option A : BottomSheet, 2 min de lecture)**
- 03.6 : OQ-1 (CTA « Commencer le chapitre » engagement direct vs sélecteur de type) + OQ-2 (marqueur ★ : calcul UserContext AD-15 au display vs mirror local AD-7 à la sync) **closes 09/25 (option A : engagement direct + option A : mirror AD-7 recalculé à la sync)**
- 04.1 : OQ-1 (professional_target : 4ᵉ écran vs pré-rempli par inférence) + OQ-2 (thème sur écran 3 vs dans /settings) + OQ-3 (CTA « C'est parti » → /inbox S-23 vs /home S-02) **closes 09/25 (option A : pré-rempli par inférence, 3 écrans stricts + option A : écran 3 = thème seul + option B : redirect /inbox, next step 04.2)**
- 04.2 : OQ-1 (triage /inbox → /learn direct vs sélecteur de type de ressource) + OQ-2 (rattachement SourceRef : mirror local AD-7 vs UserContext AD-15 direct) **closes 09/25 (option A : triage direct /learn + option A : rattachement mirror AD-7 recalculé à la sync)**
- 04.3 : OQ-1 (CTA « Replanifier » : kernel dédié AD-12/F-09 vs chat S-29 vs kernel+escalade) + OQ-2 (7 types d'événements : mirror AD-7 recalculé à la sync vs UserContext direct) **closes 09/25 (option A : kernel dédié AD-12/F-09 + option A : 7 badges mirror AD-7)**
- 04.4 : OQ-1 (bloc preuve appliquée : texte statique vs mini-calendrier inline) + OQ-2 (désactivation coaching : switch binaire vs menu de durée) + OQ-3 (preset silence S-21 réutilisé de l'onboarding 04.1 vs indépendant) **closes 09/25 (option A : texte statique + option A : switch binaire + option A : preset réutilisé onboarding, AD-15 SSoT)**
- 04.5 : OQ-1 (preview thème : aperçu statique vs re-render live) + OQ-2 (section compte : minimale vs élargie) + OQ-3 (préférences notifications : par type vs switch global) **closes 09/25 (option A : aperçu statique + option A : compte minimal + option A : notifications par type, pack 04 §3.2.5)**
- 05.1 : OQ-1 (check-in hors créneau : tolérance jour courant vs fenêtre 23h + badge en retard) + OQ-2 (heatmap mobile 7 semaines (scope-report) vs 5 semaines (pack 05 §4.3.5)) **closes 09/25 (option A : tolérance jour courant, brique = 1 tap/jour + option A : 7 semaines heatmap, contradiction sources a standup)**
- 05.2 : OQ-1 (layout RoutineStep mobile : 1 colonne vs 2 colonnes) + OQ-2 (tap RoutineStep : check inline vs BottomSheet d'analyse) + OQ-3 (CTA final « Routine complète » : bouton global vs complétion visuelle ProgressBar 100 %) **closes 09/25 (option A : 1 colonne + option A : check inline + option A : pas de CTA global, complétion visuelle)**
- 05.3 : OQ-1 (layout liste plate S-32 : 1 colonne vs cards 2 colonnes) + OQ-2 (libellé CTA fixe : « Ouvrir le Kanban » vs « Changer le statut ») + OQ-3 (tri par défaut : date vs priorité vs statut) **closes 09/25 (option A : 1 colonne + option A : CTA « Ouvrir le Kanban » + option B : tri par priorité)**
- 05.4 : OQ-1 (drag mobile : tap-then-menu vs drag-and-drop direct) + OQ-2 (5 colonnes toutes visibles vs terminé/annulé repliées) **closes 09/25 (option A : tap-then-menu + option A : 5 colonnes visibles)**
- 05.5 : OQ-1 (layout overlay : 3 zones vs 2 zones) + OQ-2 (sous-tâches : liste plate checkboxes vs Task nested 5 statuts) **closes 09/25 (option A : 3 zones + option A : checkboxes plates)**
- 05.6 : OQ-1 (matrice mobile : grille 2×2 vs 4 quadrants empilés) + OQ-2 (placement : tap-then-menu vs drag-and-drop) **closes 09/25 (option A : grille 2×2 + option A : tap + menu)** — le flag S-39 NEEDS_DECISION wave-2 reste au standup (flag de scénario, pas une OQ de la spec)
- 06.1 : OQ-1 (preuve de régularité : heatmap 7×7 vs compteur 6/7) + OQ-2 (CTA fixe : « Dérouler la semaine » → 06.2 vs S-12 revues-semaine) **closes 09/25 (option A : heatmap 7×7 + option A : CTA vers 06.2, chaîne S-33)**
- 06.2 : OQ-1 (preuve 4 semaines : heatmap 4×7 vs compteur 4/4) + OQ-2 (CTA fixe : « Voir les actions correctives » → 06.3 S-13 vs S-12) **closes 09/25 (option A : heatmap 4×7 + option A : CTA vers 06.3 S-13)**
- 06.3 : OQ-1 (clôture rétrospective : 3 sections distinctes vs intégrée section 2) + OQ-2 (CTA fixe : « Planifier la semaine » → S-05 calendrier vs S-12 vs retour Home) **closes 09/25 (option A : 3 sections + option A : CTA vers S-05 calendrier, boucle ADR §19)**
- S-41 : OQ-1 (CTA fixe « Commencer/Reprendre » : ouvre la slide Niveau 1 vs déclenche directement l'activité déléguée) + OQ-2 (timeline 4 semaines Niveau 3 : Gantt vs liste verticale ordonnée) **closes 09/25 (option A : ouvre la slide Niveau 1, progressive disclosure + option A : liste verticale 4 semaines)**

**Rappel standup (non tranchés depuis 09/25)** : scénario 01 = **batch tranches 01 ratifié (09/25, Joy)** — OQ closes (01.1 A/B/C · 01.2 A/A/A · 01.3 A/A · 01.4 A/A · 01.5 A/A · 01.6 A/A) ; il ne reste que le flag S-38 UNRECONCILED (01.6, standup wave-0) + dépendances wave-2/3 (S-39 NEEDS_DECISION, S-37 UNRECONCILED, rattachement FeatureRegistry Ascent).


**Component Extraction Check (2nd+ page)** : composants partagés identifiés — BottomNav (S-31, 5 tabs : Home/Kanban/Calendar/Progress//agent), FAB chat (S-29), badges progression (flashcards/qcm/exercises), CTA fixe (AD-14, toutes les surfaces de preuve), 5 états AD-13 (Default/Loading/Empty/Error/Offline). À extraire dans le design system (D-Design-System/00-design-system.md — pas encore créé, étape 2 du Component Extraction).
- **Backlog**: 6 scénarios Suggest + S-41 slide-ascent (Ascent) ; 58 page-folders à initialiser (01:7, 02:5, 03:6, 04:5, 05:6, 06:4, + S-41) ; dépendances tranchées au standup wave-2/3 (S-39, S-37, rattachement FeatureRegistry Ascent).

- 2026-09-25 — Workflow Ultracode `wds4-ux-design-batch` (run `wf_b69cc27b-9c3`, batch 09/25) : 21 fiches de page Phase 4 (scénarios 03/04/05/06 + S-41) spécifiées via pipeline spec→juge adversarial (41 agents, ~2.63M tokens) ; 1 échec pipeline (05.3) corrigé par `wds4-fix-05.3` (run `wf_7ec76d8c-e6f`). Intégrité vérifiée sur disque (222–250 lignes/fiche, 11 sections, OQ-11 budgets, AD-14 CTA fixe, OQ-4 option C propagée). **Phase 4 = 21/21 fiches en place.**


| Scenario | Step | Page | Status | Date |
|----------|------|------|--------|------|
| 01-horebs-progress-proof | 01.1 | Home — Progression Critique | specified (OQ closes 09/25, batch tranches 01) | 2026-09-25 |
| 01-horebs-progress-proof | 01.2 | Analytics /progress (état pré) | specified (OQ closes 09/25, batch tranches 01) | 2026-09-25 |
| 01-horebs-progress-proof | 01.3 | Flashcards (session FSRS) | specified (OQ closes 09/25, batch tranches 01) | 2026-09-25 |
| 01-horebs-progress-proof | 01.4 | QCM du domaine (S-20) | specified (OQ closes 09/25, batch tranches 01) | 2026-09-25 |
| 01-horebs-progress-proof | 01.5 | Mirror-cognitive (S-22) | specified (OQ closes 09/25, batch tranches 01) | 2026-09-25 |
| 01-horebs-progress-proof | 01.6 | Exercises progressifs (S-38, UNRECONCILED flag wave-0) | specified (OQ closes 09/25, batch tranches 01) | 2026-09-25 |
| 01-horebs-progress-proof | 01.7 | Analytics /progress (état post) | specified (OQ closes 09/25, batch tranches 01) | 2026-09-25 |
| 02-horebs-gap-closure | 02.1 | Home — Progression Critique (entrée scénario 02) | specified | 2026-09-25 |
| 02-horebs-gap-closure | 02.2 | Objectifs-liste (S-06) | specified | 2026-09-25 |
| 02-horebs-gap-closure | 02.3 | Objectifs-detail (S-07) | specified | 2026-09-25 |
| 02-horebs-gap-closure | 02.4 | Projets-detail (S-04) | specified | 2026-09-25 |
| 02-horebs-gap-closure | 02.5 | Timeline Gantt (S-33) | specified | 2026-09-25 |
| 03-horebs-active-discovery | 03.1 | Home — Discovery Entry (entrée scénario 03) | specified | 2026-09-25 |
| 03-horebs-active-discovery | 03.2 | Discovery feed (S-27) | specified | 2026-09-25 |
| 03-horebs-active-discovery | 03.3 | Discovery sheet (S-40, critique G3 scope-report §C) | specified | 2026-09-25 |
| 03-horebs-active-discovery | 03.4 | Bibliothèque de ressources (S-14) | specified | 2026-09-25 |
| 03-horebs-active-discovery | 03.5 | Artefacts-detail (S-36) | specified | 2026-09-25 |
| 03-horebs-active-discovery | 03.6 | Learn & cours-detail (S-25 + S-16) | specified | 2026-09-25 |
| 04-horebs-foundation-setup | 04.1 | Onboarding — Profil UserContext (3 écrans, S-01) | specified | 2026-09-25 |
| 04-horebs-foundation-setup | 04.2 | Inbox — Capture (S-23) | specified | 2026-09-25 |
| 04-horebs-foundation-setup | 04.3 | Calendrier — Jour & Semaine (S-10 + S-11, 1 écran 3 modes Pager) | specified | 2026-09-25 |
| 04-horebs-foundation-setup | 04.4 | Mode-coach (S-21) | specified | 2026-09-25 |
| 04-horebs-foundation-setup | 04.5 | Settings — Préférences (S-30) | specified | 2026-09-25 |
| 05-horebs-habit-loop | 05.1 | Habitudes (S-08, heatmap HabitStreak 7 semaines) | specified | 2026-09-25 |
| 05-horebs-habit-loop | 05.2 | Routines — Séquence ordonnée (S-09) | specified | 2026-09-25 |
| 05-horebs-habit-loop | 05.3 | Tâches-liste (S-32, liste plate récapitulative, CTA fixe « Ouvrir le Kanban ») | specified | 2026-09-25 |
| 05-horebs-habit-loop | 05.4 | Kanban global (S-05, 5 colonnes statuts) | specified | 2026-09-25 |
| 05-horebs-habit-loop | 05.5 | Tâches-detail — Overlay (S-24) | specified | 2026-09-25 |
| 05-horebs-habit-loop | 05.6 | Eisenhower — Matrice 4 quadrants (S-39, NEEDS_DECISION wave-2) | specified | 2026-09-25 |
| 06-horebs-retrospective | 06.1 | Rétrospective — Semaine (S-33) | specified | 2026-09-25 |
| 06-horebs-retrospective | 06.2 | Rétrospective — Mois (S-33) | specified | 2026-09-25 |
| 06-horebs-retrospective | 06.3 | Rétrospective — Actions correctives (S-13) | specified | 2026-09-25 |
| ascent (Ascent §17, non compté dans les 40 surfaces) | S-41 | Slide-ascent — Pedagogical Trajectory Engine (S-41) | specified | 2026-09-25 |

## Artefacts

- 2026-09-23 — `A-Product-Brief/product-brief.md` (71 lignes, `status: draft`, 8 sections, pointeurs vers ADR v1.7 / spine AD-1…17 / matrice agentability / discovery-gap §5)
- 2026-09-23 — `B-Trigger-Map/trigger-map.md` (~224 lignes, `status: draft`, 8 sections : 3 tiers business + persona Horeb + mapping intent→capability §4 (10 intentions) + flywheel §15/§19 + 4 traps + 20 signaux psychologiques)
- 2026-09-25 — `ascent/ascent-distill.md` (344 lignes, `status: draft`, 17 sections — pont vers la feature **Ascent** (Pedagogical Trajectory Engine, module PROPOSED, wave 3+) ; pointeurs vers `docs/ascent/overview.md` + `implementation.md` + `prompts/session-4-wave3-agent-integration.md` §SOUS-AGENT 5 SOPHIA ; 2 NON COUVERT déclarées (SOPHIA ajoutée post-hoc au plan de vagues + conflit interne corpus « 1 vs 4 tables ») ; section 17 « Entrée dans WDS Phase 4 » = proposition non prescriptive (surface S-41 `slide-ascent` + mapping réutilisation S-26/S-22/S-19-20-38/S-13 + scénario 07 « Horeb's Trajet d'apprentissage » + dépendances FeatureRegistry) ; budgets NFR (OQ-11/OQ-16/NFR9) + garde AD-14 ajoutés au §7)

## Décisions

- 2026-09-23 — Option A retenue par Joy : distiller les artefacts WDS Phase 1/2 depuis le corpus spec-first existant (pas de ré-audit complet). Les sources SSoT restent `adr-extract.md` + `SPEC.md` + `ARCHITECTURE-SPINE.md` ; les artefacts WDS sont des **ponts** (non-duplication), marqués `status: draft`.
- 2026-09-23 — Persona principale = **Horeb** (la « jeune ingénieure, génie civil, Bénin ») — c'est la cible primaire du pack 05 S1 + `discovery-gap-pipeline.md` (BEN context + Benin construction standards). Pas de secondaire/tertiaire défini officiellement dans le corpus ; à proposer si besoin.
- 2026-09-23 — Workflow Ultracode `wds-phases-1-2-distill` (run `wf_5178a933-862`) : 3 extractors + 3 juges adversariaux + 2 finalizers = 8 agents, ~602k tokens. Résultat : 0 erreur, les deux artefacts WDS Phase 1/2 sont vérifiés par Read direct.
- 2026-09-23 — Workflow Ultracode `wds3-strategic-chains` (run `wf_cab16040-87c`) : 1 builder + 3 juges adversariaux + 1 finalizer = 5 agents, ~337k tokens. Résultat : 6 chaînes (P1: 01-progress-proof · P2: 02-gap-closure, 03-active-discovery, 04-onboarding-foundations · P3: 05-habit-loop, 06-analytics-review) ; couverture 40/40 (37 assignées, 1 UNRECONCILED S-37, 2 shared S-29/S-31, 4 variantes desktop shared) ; verdicts J2/J3 FAIL corrigés par affectation directe (mécanisme proxy « via » retiré).
- 2026-09-25 — Workflow Ultracode `wds3-outline-scenarios` (run `wf_d2c52c85-893`) : 6 drafters + 6 juges adversariaux + 6 finalizers = 18 agents, ~1.37M tokens. Résultat : 6 fichiers de scénario dans `C-UX-Scenarios/{NN-slug}/{NN-slug}.md` (tous `status: draft`). Corrections manuelles post-workflow : off-by-one S-IDs du scénario 02 (S-14→S-02, S-21→S-06, S-22→S-07, S-18→S-04, S-39→S-33, S-25→S-17, S-26→S-18 + possessif « Horeb's Gap Closure »).
- 2026-09-25 — Workflow Ultracode `wds3-quality-review` (run `wf_c47d97af-cef`, step 07) : 6 juges adversariaux (1/scénario, 4 dimensions de la checklist WDS) + 1 synthétiseur = 7 agents, ~423k tokens. Résultat : 5 scénarios **Excellent** (01, 03, 04, 05, 06 : C 7/7 · Q 7/7 · M 7/7 · P 4/4) + 1 **Good** (02 : C 7/7 · Q 6/7 · M 7/7 · P 3/4) ; **minima step-07 atteints partout** (6/7, 5/7, 7/7, 2/4 — 0 Needs Work). Corrections appliquées : **G-A** (02, Q7 : 2 cibles chiffrées User Success « 1 jalon pro validé sur S-07 + 1 fiche SourceRef par bloc manquant sur S-18 » + Business Success « ≥ 1 ProgressEvidenceCreated (AD-9) par fiche SourceRef produite cette session ») ; **G-C** (03, note post-Q8 : S-26/S-28 déclarées dans `pages`, non matérialisées par le chemin 7 pasos — convention pont, couverture 1:1 via `00-ux-scenarios.md`). En note non bloquants : G-B (02, nom feature-first « Gap Closure » — optionnel, Practices 4.1) ; G-D (03, typographie « pasos ») ; G-E (05, S-39 Eisenhower `[NEEDS_DECISION wave-2]` — flag corpus accepté, trancher en wave-2). Nom du scénario 05 corrigé « Habit Loop » → « Horeb's Habit Loop » (pratiques 4.1, pré-requis du workflow).
