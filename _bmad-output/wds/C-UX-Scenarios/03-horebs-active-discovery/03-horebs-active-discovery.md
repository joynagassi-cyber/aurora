---
id: 03
slug: 03-horebs-active-discovery
name: Horeb's Active Discovery
priority: 2
pages: [S-02, S-14, S-15, S-16, S-25, S-26, S-27, S-28, S-34, S-35, S-36, S-40]
chain: 03
design_intent: S
design_status: not-started
status: draft (bridge)
flags: [S-40 critique G3 (sheet de découverte absente de tous les registres 15/17/19/44, résolu par la critique scope-report §C — surface documentée, pas UNRECONCILED), S-35/S-34/S-36/S-28 référencées sans section propre (scope-report §B), S-37 progress-dashboard UNRECONCILED hors périmètre de ce scénario]
---

# 03: Horeb's Active Discovery

**Project:** Aurora
**Created:** 2026-09-25
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Horeb s'engage sur un **écart à combler avec le métier réel** : elle part de la suggestion Coach de son Home, parcourt le feed de découvertes typées orientées par son profil (`UserContext` : Bénin, hydraulique, budget étudiant), ouvre la sheet de détail du gap qui rend l'écart lisible en champs typés, puis rattache une ressource concrète de la bibliothèque au cours ciblé et se positionne sur le chapitre correspondant — pour réduire son écart de façon ciblée plutôt que d'accumuler des liens (strategic-chains Chaîne 03 Q4 : « Découverte active typée orientée profil : feed (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY) → sheet de détail (7+ champs typés, ADR §13.8) → work on this (activité d'apprentissage ou projet, §13.9) » ; trigger-map §4 Intent #5 « Rechercher » + Intent #8 « Découvrir »).

---

## Business Goal (Q2)

**Goal:** BG-TERNARY
**Objective:** Découverte active continue (jamais de veille passive) qui élargit capacités, compréhension et vision (trigger-map §1 Tertiary, ADR §13, §13.1–13.3 ; strategic-chains Chaîne 03 Q1).

---

## User & Situation (Q3)

**Persona:** Horeb (Primary) — jeune ingénieure en génie civil au Bénin (disciplines BA / RDM / hydraulique), usage mobile intensif nocturne sur Pixel 4a (budgets SPEC OQ-11 : ≤ 300 Ko JS gz, ≤ 1,5 s TTI, 30 fps — trigger-map §7 signal 16), profil porté par `UserContext` (AD-15 : `region`, `disciplines`, `professional_target`, `budget_constraint: 'student'`).
**Situation:** 23h, après une journée de TP hydraulique, Horeb ouvre Aurora sur son Pixel 4a, connexion 3G Bénin (trigger-map §7 signal 15 : « Internet connectivity: limited fiber, mobile data common, power reliability varies » — AD-7, offline = état premier). Elle ressent un écart flou entre le programme universitaire et les pratiques réelles des bureaux d'études béninois mais ne sait pas quoi apprendre en priorité ; elle veut réduire ce gap de façon ciblée, pas accumuler des liens (trigger-map §7 signal 11 : « Écart entre le programme universitaire suivi et les compétences réellement utilisées dans le métier » — ADR §13.4 + discovery-gap §5).

---

## Driving Forces (Q4)

**Hope:** Découvrir maintenant la compétence qui comblera le plus vite son écart avec le métier réel de bureau d'études au Bénin (trigger-map §7 signal 13 : « Envie d'horizon d'excellence internationale / différenciation professionnelle » — « Devenir une ingénieure capable de comprendre son domaine en profondeur, de travailler avec les outils contemporains », ADR §13.5).

**Worry:** Enchaîner les liens et notifications sans jamais traiter le problème concret qui bloque son entrée professionnelle (trigger-map §7 signal 4 : « Fatigue d'alertes et de notifications — désir d'information contextuelle plutôt que de bruit » — « Aurora explique le constat, propose une action et suit le résultat au lieu de multiplier les notifications », ADR §13 Coach).

> CONSTRAINT: One sentence per component.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android (app Ionic React + Capacitor, ADR §23.1/§24) — appareil de référence **Pixel 4a**, budgets SPEC OQ-11 : ≤ 300 Ko JS gz initial, ≤ 1,5 s TTI, 30 fps (project-context §3 règle 15 + SPEC OQ-11 ; trigger-map §7 signal 16) ; thème Nocturne (SPEC OQ-16).
**Entry:** Horeb ouvre l'app et atterrit sur **Home `welcome/home` (S-02, AD-14)** : le 7ᵉ bloc fixe de la composition « suggestions Coach » (pack 05 §4.1.2, 7 items fixes ordonnés — agenda, prochaine action, priorité, progression critique, révisions dues, accès Focus, suggestions Coach) affiche une découverte typée liée à son `UserContext` (Bénin, hydraulique, budget étudiant, ADR §13) ; elle le tapote et l'app ouvre le feed de découverte `Discovery feed` (S-27) — sans recherche ni navigation additionnelle (strategic-chains Chaîne 03 Q5 : Home → 7ᵉ bloc « suggestions Coach » → feed de découverte ; scope-report S-02 + S-27 + S-35 `decouverte-feed` §4.1.2).

---

## Best Outcome (Q7)

**User Success (preuve tangible mesurable) :**
Horeb localise le chapitre du gap dans le cours (S-16 `cours-detail`) et y accède : une ressource source (`SourceRef`, S-14 `bibliotheque-ressources`) est rattachée au cours et visible dans sa bibliothèque, et la position de cours est persistée sur `/learn` (S-25) — l'engagement d'apprentissage est tracé (pas un lien passif) ; preuve ancrée au trigger-map §7 signal 8 : « Besoin de preuve de progrès réel (traçabilité des compétences) — Toute progression significative doit être reliée à des preuves et à un contexte », ADR §18.3 + discovery-gap §2C.

**Business Success :**
Une découverte active typée (`FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY`, ADR §13.7) est convertie en engagement d'apprentissage mesurable — 1 sheet de découverte traitée (S-40) rattachée à 1 ressource `SourceRef` (S-14) et 1 position de cours persistée (S-25) — alimentant le sous-cycle Discovery → Knowledge → Learning → Practice → Progress (ADR §13.9, discovery-gap-pipeline.md §3 ; trigger-map §5), et le feed reste typé par `UserContext`, jamais un flux passif de liens (strategic-chains Chaîne 03 Q7 ; trigger-map §6 Trap « Veille passive »).

---

## Shortest Path (Q8)

Chemin le plus court LINEAIRE (pas de branches, pas de « si », pas de « peut », pas de « éventuellement ») — 7 pasos, chaque paso cite sa surface (S-ID + nom + pointeur source court).

1. **`welcome/home` (S-02)** — Le 7ᵉ bloc fixe de la composition AD-14, « suggestions Coach » (pack 05 §4.1.2), affiche une suggestion de découverte typée (UserContext Bénin / hydraulique, ADR §13) ; Horeb tapote la suggestion [strategic-chains Ch.03 Q5 ; scope-report S-02, S-35].
2. **`Discovery feed` (S-27)** — Le feed de découverte typée (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY, ADR §13.7) liste les items orientés par `UserContext` (Bénin, hydraulique, budget étudiant) ; Horeb tapote l'item « Normes hydrauliques Bénin vs Eurocode » qui correspond à son écart ressenti (ADR §13.4) [scope-report S-27 ; trigger-map §1 Tertiary].
3. **`Sheet de découverte` (S-40)** — La sheet de détail (7+ champs typés du gap : problème, sources, impact métier, exercices suggérés — ADR §13.8) rend l'écart lisible ; Horeb tapote le CTA « Work on this » qui attache le gap à une activité d'apprentissage (ADR §13.9) [scope-report S-40, critique G3 ; discovery/overview §4].
4. **`bibliotheque-ressources` (S-14)** — La bibliothèque centralise toute la matière (cours, PDF, docs, images, vidéos, liens, notes) rattachée au gap identifié et recherchable localement ; Horeb sélectionne la ressource d'apprentissage [scope-report S-14].
5. **`artefacts-detail` (S-36)** — Horeb ouvre l'artefact de document (cours hydraulique ciblé par la découverte, §4.3.2) ; elle accède à la vue détaillée de l'artefact [scope-report S-36, §B].
6. **`/learn` (S-25)** — Le flow d'apprentissage associé (cours → chapitres → fiches/QCM/flashcards/miroir) s'ouvre avec la position de cours persistée et les recommandations ciblées affichées ; Horeb avance vers le cours [scope-report S-25, Surfaces §1 #7].
7. **`cours-detail` (S-16)** — Horeb lit la structure du cours (chapitres, concepts, formules MathBlock), localise le chapitre correspondant au gap identifié et le tapote pour commencer ✓ — l'engagement d'apprentissage est tracé (preuve, voir Q7) [scope-report S-16 ; trigger-map §7 signal 8].

*(7 pasos — minimum du parcours actif : feed → sheet → bibliothèque → artefact → /learn → cours-detail, dernier passo = succès du scénario. S-26 `arbre-semantique` et S-28 `/artifacts/:id` sont déclarées dans `pages` (frontmatter) car assignées par la chaîne 03, mais non matérialisées par le chemin le plus court 7 pasos — couverture 1:1 via la matrice de `00-ux-scenarios.md` (convention pont : le chemin reste le minimum viable, pas tous les S-IDs assignés à la chaîne).)*

---

## Trigger Map Connections

**Persona:** Horeb (Primary — trigger-map §2)

**Driving Forces Addressed:**
- ✅ **Want:** Envie ② Discovery utile — « ce que cette personne doit découvrir maintenant pour réduire ses lacunes et augmenter son niveau professionnel » (trigger-map §2 Drivers, ADR §13, principe intro) × signal 13 « Envie d'horizon d'excellence internationale / différenciation professionnelle » (trigger-map §7, ADR §13.5) et × signal 11 « Douleur liée à l'incertitude sur sa position par rapport au métier réel (écarts non documentés) » (trigger-map §7, ADR §13.4 + discovery-gap §5).
- ❌ **Fear:** Peur ② Veille passive — « accumulation de liens/notifications sans action » (trigger-map §2 Drivers négatifs + §6 Traps, ADR §13, §17) × signal 4 « Fatigue d'alertes et de notifications — désir d'information contextuelle plutôt que de bruit » (trigger-map §7, ADR §13 Coach).

**Business Goal:** BG-TERNARY — découverte active continue élargissant capacités, compréhension et vision (trigger-map §1 Tertiary, ADR §13, §13.1–13.3 ; strategic-chains Chaîne 03).

---

## Scenario Steps

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 03.1 | `03.1-home-discovery-entry/` (S-02 `welcome/home`) | Accueil Home AD-14 : Horeb est guidée vers la découverte par le 7ᵉ bloc fixe « suggestions Coach » (composition fixe, pack 05 §4.1.2 ; suggestion typée par UserContext Bénin/hydraulique, ADR §13) [strategic-chains Ch.03 Q5]. Inclut entry context (Q3 + Q4 + Q5 + Q6). | Tapote le bloc « suggestions Coach » |
| 03.2 | `03.2-discovery-feed/` (S-27 `Discovery feed`) | Feed de découverte typée (S-27) : Horeb lit les items FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY (ADR §13.7) triés par `UserContext` (Bénin, hydraulique, budget étudiant) [scope-report S-27] | Tapote l'item de découverte « Normes hydrauliques Bénin vs Eurocode » |
| 03.3 | `03.3-discovery-sheet/` (S-40 `Sheet de découverte`) | Sheet de détail (S-40) : Horeb lit les 7+ champs typés du gap (problème, sources, impact métier, exercices suggérés — ADR §13.8) et comprend l'impact professionnel avant de s'engager [scope-report S-40, critique G3] | Tapote le CTA « Work on this » |
| 03.4 | `03.4-bibliotheque-ressources/` (S-14 `bibliotheque-ressources`) | Bibliothèque de ressources (S-14) : Horeb consulte la matière centralisée (cours, PDF, docs, images, vidéos, liens, notes) rattachée au gap identifié et la sélectionne [scope-report S-14] | Sélectionne l'artefact de document ciblé par la découverte |
| 03.5 | `03.5-artefacts-detail/` (S-36 `artefacts-detail`) | Détail de l'artefact (S-36) : Horeb ouvre l'artefact du cours hydraulique (variante de détail, §4.3.2) et accède à la vue détaillée [scope-report S-36, §B] | Tapote « Ouvrir dans /learn » |
| 03.6 | `03.6-learn-cours-detail/` (S-25 `/learn` → S-16 `cours-detail`) | Entrée dans /learn (S-25) + cours-detail (S-16) : position de cours persistée ; Horeb lit la structure (chapitres, concepts, formules MathBlock) et localise le chapitre du gap ; engagement d'apprentissage tracé (SourceRef S-14, position S-25 — signal 8, ADR §18.3) ; fin du scénario ✓ [scope-report S-25, S-16] | Tapote le chapitre cible ✓ |

**First step** (03.1) includes full entry context (Q3 + Q4 + Q5 + Q6).
**On-step interactions** (that don't leave the step) are documented as storyboard items within each page spec.
