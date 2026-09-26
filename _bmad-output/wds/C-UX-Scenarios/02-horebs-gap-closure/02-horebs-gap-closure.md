---
id: 02
slug: 02-horebs-gap-closure
name: Horeb's Gap Closure
priority: 2
pages: [S-02, S-06, S-07, S-04, S-33, S-17, S-18]
chain: 02
design_intent: S
design_status: not-started
status: draft
aliases: {S-14: S-02 (welcome/home), S-21: S-06 (objectifs-liste), S-22: S-07 (objectifs-detail), S-18: S-04 (projets-detail), S-39: S-33 (timeline-gantt), S-25: S-17 (fiches-liste), S-26: S-18 (fiches-detail)}
---

# 02: Horeb's Gap Closure

**Project:** Aurora
**Created:** 2026-09-25
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Comblé d'écart documenté : Horeb repère le décalage entre sa formation universitaire (BA / RDM / hydraulique) et les compétences réellement exigées par son métier de bureau d'études, puis s'arme de la preuve qui le confirme et du plan qui le réduit (objectifs → jalons → plan d'ouverture → fiche de compétence par blocs) (strategic-chains Chaîne 02 Q4 : « Réduire un écart documenté » ; trigger-map §4 Intent #8 « Découvrir » — `discovery.gaps`, `discovery.horizons` ; ADR §13.4 « cartographie des écarts documentés »).

---

## Business Goal (Q2)

**Goal:** BG-SECONDARY — Convergence vers l'**excellence internationale** via écarts documentés (académique ↔ professionnel ↔ international)
**Objective:** Mesurer l'écart entre le programme universitaire suivi et les compétences réellement utilisées dans le métier, puis le réduire par un plan d'ouverture (learning + practice), avec preuves de compétence construites progressivement (trigger-map §1 Secondary, ADR §13.5 ; strategic-chains Chaîne 02 Q1).

---

## User & Situation (Q3)

**Persona:** Horeb (Primary) — jeune ingénieure en génie civil au Bénin, disciplines BA / RDM / hydraulique, usage **mobile intensif en nocturne** ; profil porté par `UserContext` (`region`, `disciplines`, `professional_target`, `budget_constraint`) (trigger-map §2 ; spine AD-15).
**Situation:** Session nocturne sur mobile, à la maison, connexion mobile Béninoise ; Horeb confronte son cursus (BA / RDM / hydraulique) avec les attentes du métier de bureau d'études — un écart qu'elle documente dans son objectif professionnel (fiche `objectifs-detail`, jalons à l'appui) (trigger-map §2 ; brief §2 contexte Bénin, mobile nocturne ; ADR §13.4 ; ADR §23.1 local-first ; spine AD-15).

---

## Driving Forces (Q4)

**Hope:** Ouvrir une voie concrète vers l'excellence internationale, en voyant l'écart documenté se réduire jalon par jalon (trigger-map §7 signal 14, Envie — « horizon d'excellence internationale / différenciation professionnelle », citation ADR §13.5 : « Devenir une ingénieure capable de comprendre son domaine en profondeur »).

**Worry:** Être piégée dans le programme universitaire sans jamais mesurer l'écart réel avec le métier de bureau d'études (trigger-map §7 signal 12, Douleur — « incertitude sur sa position par rapport au métier réel (écarts non documentés) », citations ADR §13.4 + discovery-gap §5 : « Écart entre le programme universitaire suivi et les compétences réellement utilisées dans le métier » ; piège Peur ① « Illusion de progression » trigger-map §6, ADR §18.2).

> CONSTRAINT: One sentence per component.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android — **Pixel 4a** (budgets SPEC OQ-11 : ≤ 300 Ko JS gz initial, ≤ 1,5 s TTI, 30 fps ; project-context §3 règle 15 ; trigger-map §7 signal 16).
**Entry:** L'app est déjà ouverte sur **Home `welcome/home` (S-02)** — composition fixe AD-14, bloc « progression critique » (7ᵉ item) → `objectifs-liste` ; surface d'entrée non assignée à la chaîne 02 mais point de départ réaliste (strategic-chains Chaîne 01 Q5 ; trigger-map §6 Trap « surcharge de widgets » — composition fixe ; spine AD-14).

---

## Best Outcome (Q7)

**User Success (critères mesurables) :**
Écart documenté (cadre universitaire ↔ bureau d'études) réduit, avec 2 cibles chiffrées : (a) **1 jalon pro du bureau d'études validé** — jalon `atteint` sur `objectifs-detail` (S-07), en contraste avec les jalons non atteints du passo 3 ; (b) **1 fiche de compétence `SourceRef` par bloc manquant** — fiche générée par blocs (définitions, formules, méthodes, pièges, relations) et prouvée sur `fiches-detail` (S-18) ; l'écart mesuré sur `objectifs-detail` (S-07) est visualisé sur `timeline-gantt` (S-33) (ADR §13.5 ; ADR §18.2 « causes, pas comptages »).

**Business Success:**
Écarts documentés réduits (académique ↔ pro ↔ international) et preuves de compétence construites progressivement — mesurables par le nombre de `ProgressEvidenceCreated` (AD-9) liés aux fiches `SourceRef` (**≥ 1 `ProgressEvidenceCreated` par fiche `SourceRef` produite cette session**) et par la convergence cadencée vers l'excellence internationale (trigger-map §1 Secondary ; ADR §13.5 ; ADR §18.2).

---

## Shortest Path (Q8)

Chemin le plus court LINEAIRE (pas de branches, pas de « si », pas de « éventuellement ») — 7 pasos, chaque paso cite sa surface par S-ID + nom + pointeur source court.

1. **`welcome/home` (S-02)** — Bloc « progression critique » (7ᵉ item de la composition fixe AD-14) signale l'écart professionnel (cadre ↔ bureau d'études) et pousse vers l'analyse des objectifs [strategic-chains Ch.01 Q5 ; scope-report S-02 ; trigger-map §6 Trap « surcharge de widgets » ; spine AD-14].
2. **`objectifs-liste` (S-06)** — Cards des objectifs court/moyen/long terme ; Horeb repère l'objectif professionnel (bureau d'études) qui porte l'écart [scope-report S-06 ; Screen Registry §A #6 §4.3.4 ; strategic-chains Ch.02 S-06→S-06].
3. **`objectifs-detail` (S-07)** — Hiérarchie (projets qui y contribuent), indicateurs, jalons ; l'écart se lit ici : jalons non atteints vs indicateurs [scope-report S-07 ; Screen Registry §A #7 §4.3.4 ; strategic-chains Ch.02 Q5].
4. **`projets-detail` (S-04)** — Le projet concerné (bureau d'études) avec tout son contexte (objectif, jalons, tâches, documents, notes, historique) ; le plan d'ouverture s'y construit [scope-report S-04 ; Screen Registry §A #4 §4.3.2 ; strategic-chains Ch.02 S-04→S-04].
5. **`timeline-gantt` (S-33)** — Le plan d'ouverture est visualisé sur la timeline (liste de `GanttRow`) ; l'écart se voit en date [scope-report S-33 ; Screen Registry §A #28, référencé §3.6.4 ; strategic-chains Ch.02 S-33→S-33].
6. **`fiches-liste` (S-17)** — Génération de la fiche de compétence pour le jalon manquant (blocs : définitions, formules, méthodes, pièges, relations) [scope-report S-17 ; Screen Registry §A #21 §4.7.1 ; strategic-chains Ch.02 S-17].
7. **`fiches-detail` (S-18)** ✓ — Preuve de compétence vérifiée : blocs `SourceRef` par section ; l'écart documenté est comblé par la preuve — c'est le succès du scénario [scope-report S-18 ; Screen Registry §A #22 §4.7.1 ; strategic-chains Ch.02 S-18 ; ADR §13.5].

*(7 pasos — la surface `welcome/home` (S-02) est le point d'entrée (Q5) et n'appartient pas à l'affectation de la chaîne 02 (strategic-chains Ch.01) ; les 6 pasos restants couvrent les 6 surfaces assignées de la chaîne 02.)*

---

## Trigger Map Connections

**Persona:** Horeb (Primary) — `UserContext` (région Bénin, disciplines BA/RDM/hydraulique, `professional_target`, `budget_constraint`) (trigger-map §2 ; spine AD-15).

**Driving Forces Addressed:**
- ✅ **Want:** Envie ② Discovery utile — « ce que cette personne doit découvrir maintenant pour réduire ses lacunes et augmenter son niveau professionnel » (trigger-map §2 Drivers, ADR §13 principe intro) × signal 14 Envie « horizon d'excellence internationale / différenciation professionnelle » (trigger-map §7, ADR §13.5).
- ❌ **Fear:** Peur ① Illusion de progression (trigger-map §2 Drivers + §6 Traps, ADR §18.2) × signal 12 Douleur « incertitude sur sa position par rapport au métier réel (écarts non documentés) » (trigger-map §7, ADR §13.4 + discovery-gap §5) — ici l'écart est documenté, pas masqué.

**Business Goal:** BG-SECONDARY — Convergence vers l'excellence internationale via écarts documentés, preuves de compétence construites progressivement (trigger-map §1 Secondary ; ADR §13.5 ; strategic-chains Chaîne 02 Q1/Q7).

---

## Scenario Steps

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 02.1 | `02.1-home-critique/` (S-02 `welcome/home`) | Home AD-14 en session nocturne (thème Nocturne, Pixel 4a) : bloc « progression critique » (7ᵉ item) signale l'écart professionnel (cadre ↔ bureau d'études). Inclut entry context (Q3 + Q4 + Q5 + Q6). [strategic-chains Ch.01 Q5 ; trigger-map §6] | Tap sur le bloc « progression critique » → `objectifs-liste` (S-06) |
| 02.2 | `02.2-objectifs-liste/` (S-06 `objectifs-liste`) | Cards court/moyen/long terme ; l'objectif professionnel (bureau d'études) porte l'écart qui sera détecté sur S-07 [scope-report S-06] | Tap sur l'objectif professionnel → `objectifs-detail` (S-07) |
| 02.3 | `02.3-objectifs-detail/` (S-07 `objectifs-detail`) | Hiérarchie (projets qui y contribuent), indicateurs, jalons — l'écart se lit ici : jalons non atteints vs indicateurs [scope-report S-07 ; strategic-chains Ch.02 Q5] | CTA « ouvrir le projet » → `projets-detail` (S-04) |
| 02.4 | `02.4-projets-detail/` (S-04 `projets-detail`) | Contexte complet du projet bureau d'études (objectif, jalons, tâches, documents, notes, historique) ; le plan d'ouverture s'y construit [scope-report S-04 ; Screen Registry §A #4] | CTA « visualiser sur timeline » → `timeline-gantt` (S-33) |
| 02.5 | `02.5-timeline-gantt/` (S-33 `timeline-gantt` → S-17 `fiches-liste` → S-18 `fiches-detail`) | Plan d'ouverture visualisé (liste de `GanttRow`) : l'écart se voit en date ; CTA vers la fiche du jalon manquant [scope-report S-33, référencé §3.6.4] | CTA « générer la fiche » → `fiches-liste` (S-17) puis `fiches-detail` (S-18) ✓ **Final — scenario success** : l'écart documenté est comblé par la preuve `SourceRef` |

**First step** (02.1) includes full entry context (Q3 + Q4 + Q5 + Q6).
**On-step interactions** (that don't leave the step) are documented as storyboard items within each page spec.
