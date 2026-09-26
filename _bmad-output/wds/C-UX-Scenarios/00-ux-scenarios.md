# UX Scenarios : Aurora

> Scenario outlines connecting Trigger Map personas to concrete user journeys

**Created:** 2026-09-25
**Author:** Joy via Freya (WDS Designer)
**Method:** Whiteport Design Studio (WDS)

---

## Scenario Summary

| ID | Scenario | Persona | Pages | Priority | Status |
|----|----------|---------|-------|----------|--------|
| 01 | Horeb's Progress Proof | Horeb | 6 | ⭐ P1 | ✅ Outlined |
| 02 | Horeb's Gap Closure | Horeb | 7 | P2 | ✅ Outlined |
| 03 | Horeb's Active Discovery | Horeb | 12 | P2 | ✅ Outlined |
| 04 | Horeb's Foundation Setup | Horeb | 6 | P2 | ✅ Outlined |
| 05 | Horeb's Habit Loop | Horeb | 6 | P3 | ✅ Outlined |
| 06 | Horeb's Retrospective | Horeb | 2 | P3 | ✅ Outlined |

---

## Scenarios

### [01: Horeb's Progress Proof](01-horebs-progress-proof/01-horebs-progress-proof.md)
**Persona:** Horeb — Self-improvement vérifié × peur d'illusion de progression
**Pages:** S-02, S-13, S-19, S-20, S-22, S-38
**User Value:** Preuve vérifiée de transformation réelle (QCM, rappel actif, exercice, explication) reliée à un contexte et une compétence
**Business Value:** Transformation réelle traçable dans le temps (état, évolution, causes, preuves)

---

### [02: Horeb's Gap Closure](02-horebs-gap-closure/02-horebs-gap-closure.md)
**Persona:** Horeb — Discovery utile : réduire un écart documenté
**Pages:** S-02, S-06, S-07, S-04, S-33, S-17, S-18
**User Value:** Écart documenté comblé (compétence professionnelle alignée sur standard international), preuve de compétence
**Business Value:** Convergence vers excellence internationale — écarts documentés (académique ↔ professionnel ↔ international)

---

### [03: Horeb's Active Discovery](03-horebs-active-discovery/03-horebs-active-discovery.md)
**Persona:** Horeb — Découverte active typée orientée profil × peur de veille passive
**Pages:** S-02, S-14, S-15, S-16, S-25, S-26, S-27, S-28, S-34, S-35, S-36, S-40
**User Value:** Découverte typée orientée profil (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY), pas de flux de liens passifs
**Business Value:** Découverte active continue (pas de veille passive), différenciation produit

---

### [04: Horeb's Foundation Setup](04-horebs-foundation-setup/04-horebs-foundation-setup.md)
**Persona:** Horeb — Configuration du profil UserContext + préférences (thème nocturne, silence, notifications)
**Pages:** S-01, S-10, S-11, S-21, S-23, S-30
**User Value:** Profil personnalisé (pas de hardcoding), environnement conforme (thème Nocturne, fenêtres de silence)
**Business Value:** Activation du profil UserContext → capacité à mesurer la transformation réelle (BG-PRIMARY)

---

### [05: Horeb's Habit Loop](05-horebs-habit-loop/05-horebs-habit-loop.md)
**Persona:** Horeb — Régularité des pratiques (heatmap d'adhérence, check-in)
**Pages:** S-05, S-08, S-09, S-24, S-32, S-39
**User Value:** Régularité mesurée (HabitStreak), routines ordonnées pas un to-do chaotique
**Business Value:** Fidélisation par la régularité → transformation réelle continue (BG-PRIMARY)

---

### [06: Horeb's Retrospective](06-horebs-retrospective/06-horebs-retrospective.md)
**Persona:** Horeb — Rétrospective guidée, analyse des causes pas du simple comptage
**Pages:** S-12, S-13
**User Value:** Causes comprises, adaptation de la trajectoire (Self-Improve → Adapt)
**Business Value:** Rétrospective structurée → transformation réelle + adaptation (ADR §19)

---

## Page Coverage Matrix

| Page | Scenario | Purpose in Flow |
|------|----------|----------------|
| S-01 `onboarding` | 04 | Choix de profil (étudiante/matière/horaire silence/thème), sans tour de fonctions |
| S-02 `welcome/home` | 01, 03, 04 | Point d'entrée (bloc « progression critique », « suggestions Coach », bloc habitudes/routines) |
| S-03 `projets-liste` | 02 | Lister les projets avec jalons, progression, tâches |
| S-04 `projets-detail` | 02 | Contexte complet d'un projet (objectif, jalons, tâches, documents) |
| S-05 `kanban` | 05 | Board global par statut, drag local |
| S-06 `objectifs-liste` | 02 | Objectifs court/moyen/long terme en Cards |
| S-07 `objectifs-detail` | 02 | Hiérarchie (projets → indicateurs → jalons) |
| S-08 `habitudes` | 05 | Suivi d'habitudes, heatmap d'adhérence `HabitStreak` |
| S-09 `routines` | 05 | Routines ordonnées (matin/soir/étude) |
| S-10 `calendrier-jour` | 04 | Planification de la session de ce soir |
| S-11 `calendrier-semaine/mois` | 04 | Planification hebdomadaire/mensuelle (composant `Pager`) |
| S-12 `revues-{jour,semaine,mois}` | 06 | Rétrospective guidée (formulaire structure `pending`/`completed`) |
| S-13 `analytics` | 01, 06 | Dashboard Progress ADR §18.6 (5 questions structurées) |
| S-14 `bibliotheque-ressources` | 03 | Matériau centralisé (cours, PDF, docs, images) |
| S-15 `cours-liste` | 03 | Lister les cours rattachés |
| S-16 `cours-detail` | 03 | Structure d'un cours (chapitres, concepts, formules) |
| S-17 `fiches-liste` | 02 | Générer les fiches de révision |
| S-18 `fiches-detail` | 02 | Fiche par blocs (définitions, formules, méthodes, pièges) |
| S-19 `flashcards` | 01 | Session de révision espacée FSRS |
| S-20 `qcm` | 01 | QCM généré par agent serveur |
| S-21 `mode-coach` | 04 | Réglages du coaching (cadence, silence, désactivation) |
| S-22 `mirror-cognitive` | 01 | L'étudiante explique, le kernel analyse |
| S-23 `/inbox` | 04 | Capture universelle et triage |
| S-24 `/tasks/:id` | 05 | Overlay de détail : sous-tâches, matrice Eisenhower |
| S-25 `/learn` | 03 | Flow d'apprentissage (cours → chapitres → fiches/QCM/flashcards/miroir) |
| S-26 `/knowledge` | 03 | Arbre sémantique, provenance, « study » |
| S-27 `Discovery (feed)` | 03 | Feed de découverte typée |
| S-28 `/artifacts/:id` | 03 | Preview par format → source/download/share |
| S-32 `taches-liste/detail` | 05 | Liste plate des tâches |
| S-33 `timeline-gantt` | 02 | Visualisation du plan d'ouverture |
| S-34 `arbre-semantique` | 03 | Exploration par niveaux, provenance |
| S-35 `decouverte-feed` | 03 | Feed de découverte (référencé §4.1.2) |
| S-36 `artefacts-detail` | 03 | Variante de détail d'un artefact |
| S-38 `exercises` | 01 | Exercice progressif vérifié par le Scientific Engine |
| S-39 `Eisenhower` | 05 | Matrice 4 quadrants [NEEDS_DECISION wave-2] |
| S-40 `Sheet de découverte` | 03 | Detail d'un item du feed (7+ champs typés) |
| S-41 `slide-ascent` *(proposé, Ascent §17)* | 07 *(proposé)* | `LearningPath` (AscentLearningIR) rendu par Slide-Ascent : 12 types de slides + progressive disclosure 4 niveaux + 5 actions Active Reading (module Ascent PROPOSED, non gelé) |

**Coverage:** 33/40 surfaces assignées (S-29, S-31 = shared ; S-37 = UNRECONCILED) + **S-41 slide-ascent proposé** (distillation Ascent §17, à indexer en Phase 4 — non compté dans les 40 surfaces du scope-report)

---

## Next Phase

These scenario outlines feed into **Phase 4: UX Design** where each page gets:
- Detailed page specifications
- Wireframe sketches
- Component definitions
- Interaction details

---

_Generated with Whiteport Design Studio framework_
