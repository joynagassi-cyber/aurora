---
id: S-41
slug: slide-ascent
name: "Slide-Ascent (/learn/ascent)"
scenario: ascent-distill (17)
surface: S-41 slide-ascent
route: "/learn/ascent"
status: draft (bridge — pont, NON COUVERT par le corps gelé)
created: 2026-09-25
method: Whiteport Design Studio (WDS), mode Suggest, steps 08-15
---

# S-41 — Slide-Ascent (`/learn/ascent`)

**Scenario:** Ascent 17 — proposition **non prescriptive** (entrée dans WDS Phase 4) ; S-41 ne compte pas dans les 40 surfaces du scope-report (S-01…S-40) — voir `ascent-distill.md` §17.1
**S-ID (scope-report):** S-41 `slide-ascent` (S-ID hors scope-report, déclaré dans `00-ux-scenarios.md` §Page Coverage Matrix comme **proposé, Ascent §17** — non compté dans les 40)
**Route:** `/learn/ascent`
**Platform:** Mobile Android — Pixel 4a (OQ-11), thème Nocturne (OQ-16), offline = état premier (AD-7)
**Interaction:** Touch-first
**Visibility:** Authenticated (`UserContext` actif, AD-15)

**Previous Step:** ← [Ascent 17 — entrée dans WDS Phase 4 (ascent-distill.md §17, proposition non prescriptive)](../../ascent/ascent-distill.md)
**Next Step:** → [Final — scenario success : scénario 07 « Horeb's Trajet d'apprentissage recommandé par Ascent 17 » (ascent-distill.md §17.3, option 1 recommandée, NON tranché)]

---

## Page Metadata

| Property | Value |
|----------|-------|
| **Page Number** | S-41 (pas de numéro `NN.M` — surface proposée, hors des 40 du scope-report) |
| **Page Name** | Slide-Ascent — vue progressive disclosure du `LearningPath` |
| **Page Slug** | `slide-ascent` |
| **S-ID** | S-41 `slide-ascent` *(proposé, Ascent §17.1)* |
| **Route** | `/learn/ascent` |
| **Platform** | Mobile Android (Pixel 4a, OQ-11) |
| **Viewport** | 540 × 960 px (Pixel 4a, OQ-11) |
| **Interaction** | Touch-first |
| **Visibility** | Authenticated (`UserContext` actif, AD-15) ; `ascent_paths` lues via PowerSync mirror local (AD-7) |
| **Variants (step 14)** | 2 (Nocturne · Light, 2 min.) |

> **Nature du spec (pont, non-duplication) :** `status: draft (bridge)` — les pointeurs vers le module Ascent (PROPOSED, non gelé) sont : S-41 `slide-ascent` (ascent-distill.md §17.1) · spine AD-7 (offline état premier) · AD-13 (5 états UX canoniques) · AD-14 (garde : CTA fixe, jamais proposition libre) · AD-15 (`UserContext` SSoT) · trigger-map §5 (flywheel moteur agentique) · ADR §18.6 (dashboard Progress) · scope-report §B (S-41 déclaré hors 40 surfaces) · `ascent-distill.md` §7 (12 types de slides + progressive disclosure 4 niveaux + 5 actions Active Reading) · §15 (NON COUVERT déclaré) · §17.2 (mapping réutilisation S-26/S-22/S-19/S-20/S-38/S-13, zéro duplication). Le **corps gelé** (ADR v1.7 / spine AD-1…17) ne couvre **pas** S-41 : Ascent est PROPOSED, pas d'ADR gelé, pas de numéro AD. Tout ce qui n'est pas couvert par le corps gelé est déclaré **NON COUVERT** ci-dessous et une option A/B/C est proposée au standup — aucune implémentation.

---

## 1. Page Purpose (step 10)

**Wording proposé (09/25) :**
> Horeb visualise le **plan de formation sur 4 semaines** produit par Ascent (renderer du `AscentLearningIR` / `LearningPath`) : cours + chapitres + exercices + QCM + fiches + miroir, séquencé **READ → DO → PROVE** (ascent-distill §9, framework pas contrainte). Elle **identifie les 2 sessions de révision manquantes** (phase `review` non couvertes par les preuves `ProgressEvidence` existantes) et le **rythme posé** apparaît à la fin du scénario. Preuves tracees : cours complétés + exercices validés (AD-9, ADR §18) ; plan **mesurable** (4 semaines = `targetDate` du `LearningPath`, ascent-distill §6.1).

La page ne fait qu'une seule chose à chaque ouverture : **montrer le plan d'apprentissage adaptatif (4 semaines, 6 types d'activités) et rendre lisibles les 2 sessions de révision manquantes**.

---

## 2. Entry Points (step 11)

| # | Entrée | Type | Source |
|---|--------|------|--------|
| 1 | **Bloc « progression critique » de Home (S-02, AD-14)** ou **bloc Coach → /agent (S-29) → Slide-Ascent** (ascent-distill §7, garde AD-14 : S-41 = surface dédiée, JAMAIS un 8ᵉ slot sur Home) | **Internal (primary)** | ascent-distill.md §7 (garde AD-14 — Slide-Ascent surface dédiée, route de détail) ; `EXPERIENCE.md` §Information Architecture invariant S6.2 (route ouverte au-dessus du tab courant) |
| 2 | **BottomNav** — pas de tab dédié (le 5ᵉ tab = `/agent` S-29, OQ-4 close option C) ; accès à `/learn/ascent` via une route push au-dessus du tab courant, **pas** via un 6ᵉ tab (OQ-4, convention) | **Internal (secondary)** | OQ-4 close (option C, 09/25) — 5 tabs BottomNav fixes : `Home · Kanban · Calendar · Progress · /agent` ; S-41 = route de détail (invariant S6.2) |
| 3 | **Deep link `/learn/ascent`** (push notification, automatisation Intégrations/Cron → jobs) | **External (secondary)** | scope-report S-31 parcours #17 (5 points d'entrée S-31 : deep link = 5ᵉ) ; feature-registry §4 |
| 4 | **Retour natif** (back depuis une activité déléguée : S-19 flashcards / S-20 qcm / S-26 knowledge) | **Internal (secondary)** | scope-report parcours #5 « Return destination » (invariant S6.2 : la page d'origine revient dans son état sauvegardé — scroll, niveau de disclosure, slide ouverte) |

**Point clé** : S-41 est une **surface dédiée** (route `/learn/ascent`, montée **au-dessus du tab courant** de la BottomNav — invariant S6.2, `EXPERIENCE.md` §Component Patterns : BottomSheet léger / route push lourde). C'est **JAMAIS** un 8ᵉ item/slot de la composition AD-14 de Home (garde AD-14, ascent-distill §7). La vue **Level 3** (chemin complet + timeline) vit **dans** S-41, pas sur Home.

---

## 3. Mental State (step 12)

**Contexte de la page** : Horeb a ouvert la vue Ascent depuis le bloc « progression critique » de Home (01.1) ou via le bloc Coach → `/agent` → Slide-Ascent, 23 h, thème Nocturne, réseau 3G Bénin (AD-7, offline = état premier). Son objectif : **Maîtriser la RDM d'ici l'exam** (4 semaines, `targetDate`). Elle veut **voir le plan** (4 semaines, cours + chapitres + exercices + QCM + fiches + miroir) et **savoir ce qu'elle doit faire maintenant** — sans se noyer dans le chemin complet (ascent-distill §7, progressive disclosure : montrer l'info quand elle devient utile, pas avant).

| Dimension | Contenu |
|---|---|
| **Trigger** (ce qui la pousse) | L'envie de voir un **plan mesurable** (4 semaines) plutôt qu'une liste d'activités disjointes — le moteur Ascent a **ordonné** le chemin (READ → DO → PROVE) selon son `UserContext` (RDM, exam, 4 semaines) et sa `LearnerBaseline` (5 états : unknown/partial/known/fragile/mastered — ascent-distill §6.2) ; la peur qu'un prérequis fragile soit masqué par un score unique (ascent-distill §6.2, règle 5 états) |
| **Hope** | Identifier **les 2 sessions de révision manquantes** (phase `review` non couvertes par les preuves existantes) — le plan doit être **mesurable** (4 semaines = `targetDate`) et les **preuves tracées** (cours complétés = `ProgressEvidenceCreated`, exercices validés = AD-9, ADR §18) |
| **Worry** | Que le plan soit **trop long à lire** (12 types de slides, 4 niveaux de disclosure — risque de noyade, ascent-distill §7) ; que le **rythme posé** (fin du scénario) ne tienne pas compte de la semaine d'exam (Quick depth sur le faible, Deep sur le fort — ascent-distill §8) ; que les adaptations du moteur (réordonner, insérer une remédiation) soient **invisibles** (log `AscentAdaptation`, ascent-distill §6.3 — pourquoi cet ordre ?) |
| **Questions** | « Mon plan de 4 semaines tient-il le coup (preuves tracées : cours + exercices) ? » · « Quelles sont les 2 sessions de révision manquantes ? » · « Quel est le rythme posé, et pourquoi cet ordre (log d'adaptation) ? » |
| **Contrainte UX** | Offline = état premier (AD-7) : le `LearningPath` est lu via le **mirror local PowerSync** (`ascent_paths`, ascent-distill §13) en **lecture seule** ; les adaptations cloud (réordonner/accélérer/remédiation) sont **désactivées avec explicatif** (bandeau offline + actions désactivées, 5 états UX AD-13, ascent-distill §7). V1 = **1 objectif actif à la fois** (ascent-distill §17.4, V1 troncature) : S-41 affiche **un seul** `LearningPath` actif, multi-path = V1.1. |

---

## 4. Desired Outcome (step 13)

### Business Goal
**Un plan d'apprentissage **mesurable** (4 semaines, `targetDate`) et **traceable** (preuves = `ProgressEvidenceCreated`, AD-9, ADR §18) qui alimente le **flywheel du moteur agentique** (trigger-map §5, ADR §18.7)** — le scénario success (scénario 07, « Horeb's Trajet d'apprentissage recommandé par Ascent 17 ») est atteint quand : (a) les 4 semaines du plan sont visibles, (b) les 2 sessions de révision manquantes sont identifiées, (c) le rythme posé (READ → DO → PROVE, ascent-distill §9) est posé **à la fin du scénario**. Source : ascent-distill.md §17.3 (option 1 recommandée, NON tranché) ; trigger-map §5 ; ADR §18.

### User Goal
**Visualiser le plan de 4 semaines (cours + chapitres + exercices + QCM + fiches + miroir) et identifier les 2 sessions de révision manquantes en 1 geste** — le rythme posé (fin du scénario) doit rendre lisible **pourquoi cet ordre** (log d'adaptation, ascent-distill §6.3, provenance AD-11). Source : scenario success (ascent-distill §17.3) ; ascent-distill §7 progressive disclosure (niveau 1 = étape courante + suivante, niveau 3 = vue complète du chemin + timeline).

---

## 5. Variants (step 14)

**`has_variants` = true · `variant_count` = 2 (Nocturne · Light, 2 min.)**

| Variant | Déclencheur | Ce qui change | Source |
|---|---|---|---|
| **Nocturne** (default pour Horeb) | Thème = Nocturne (SPEC OQ-16, 1re classe) | Fond sombre + accent désaturé global (le thème gère la désaturation globalement, OQ-3 01.1 close option B) ; les 12 types de slides (KaTeX, AntV, images — ascent-distill §7) s'affichent en Nocturne par défaut (session nocturne intensive, ADR §23.1, trigger-map §7 signal 6) | `DESIGN.md` §Colors (pack 05 §5) |
| **Light** | Thème = Light | Fond clair, accent normal (pas de désaturation) ; les slides KaTeX/AntV restent lisibles (moteurs lazy par essence, jamais au bundle initial — EXPERIENCE.md §Perf S9, ascent-distill §7) | `DESIGN.md` §Colors |

> Pas de variante Focus : le focus-mode est un **état sans chrome** (scope-report §Focus-mode, pack 05 §4.4.2) — si Horeb est en focus, `/learn/ascent` n'est pas accessible (focus bloque les autres surfaces, focus-mode §7). Les 2 variantes sont des **surcharge du thème** (pas des layouts distincts) : le layout (section 6) est identique, seuls les tokens de couleur changent.

---

## 6. Layout Structure (step 15)

*(PROPOSITION SUGGEST — NON COUVERT par le corps gelé pour la disposition interne de Slide-Ascent ; dérivé de ascent-distill.md §7 (12 types de slides + progressive disclosure 4 niveaux + 5 actions Active Reading) + spine AD-14 (garde : surface dédiée, CTA fixe) + AD-13 (5 états) + AD-7 (offline état premier). Le layout est **proposé**, NON prescriptif — l'arbitrage revient au standup wave-3.)*

**Composition Slide-Ascent — slide courante + barre de disclosure progressive (niveau 1 visible par défaut) + CTA fixe (AD-14, jamais proposition libre) :**

```
+-------------------------------------+
| /learn/ascent (thème Nocturne)     |
|  Titre : « Trajet : Maîtriser la    |
|    RDM d'ici l'exam »              |
|  Sous-titre : 4 semaines · N étapes |
|  [CTA FIXE : Commencer / Reprendre] |  ← CTA AD-14 (jamais proposition libre)
+-------------------------------------+
|  Niveau 1 (toujours) :             |
|  « Etape courante » + « Etape       |
|    suivante » (ascent-distill §7)  |
|  → tap = Niveau 2 (detail de        |
|    l'etape : concept, formule,      |
|    1 exemple, l'activite a faire    |
|    MAINTENANT)                      |
+-------------------------------------+
|  Niveau 3 (a la demande) :         |
|  Vue complete du chemin (4         |
|    semaines, toutes etapes,        |
|    statuts, timeline) + carte      |
|    des prerequis + profondeur +   |
|    « pourquoi cet ordre ? »        |
|    (log AscentAdaptation)          |
+-------------------------------------+
|  12 types de slides (palette,     |
|    pas sequence obligatoire) :    |
|  Concept · Definition · Formula    |
|  (KaTeX, lazy) · Diagram (AntV,   |
|  lazy) · Example · Analogy ·      |
|  Timeline · Comparison ·          |
|  Question · Exercise ·            |
|  Reflection · Recap               |
+-------------------------------------+
|  Actions Active Reading (5,        |
|    couche d'interaction) :        |
|  [Explain] [Note] [Flashcard]     |
|  [Visualize] [Je bloque]          |
+-------------------------------------+
|  Bandeau (offline/error/empty,    |
|    AD-13 — section 7)             |
+-------------------------------------+
|  BottomNav (5 tabs, S-31 shared)  |
|  Home · Kanban · Calendar ·       |
|  Progress · /agent                 |  ← FAB chat masque (BottomNav presente, OQ-4 close)
+-------------------------------------+
```

**Note :**
- Les **12 types de slides** (ascent-distill §7) forment une **palette, pas une séquence obligatoire** : le nombre de slides = nombre de **transitions significatives** du `LearningPath` ; chaque slide = une **vue** sur les données (`AscentLearningIR` = SSoT, pas la UI). Les moteurs **KaTeX** (formules) et **AntV** (diagrammes) sont **lazy par essence, jamais au bundle initial** (EXPERIENCE.md §Perf S9, ascent-distill §7 — budget OQ-11 : JS ≤ 300 Ko gz).
- Les **5 actions Active Reading** (ascent-distill §14) sont la **couche d'interaction** : `Explain` / `Je bloque` → **S-22** `mirror-cognitive` (ascent-distill §17.2 mapping) ; `Flashcard` / `Exercise` → **S-19** / **S-38** via **S-25** `/learn` ; `Note` → local. S-41 **orchestre** ces surfaces existantes, elle **ne les recrée pas** (règle pont, ascent-distill §17.2).
- Le **CTA est fixe** (garde AD-14) : « Commencer / Reprendre » — **jamais une proposition libre de l'agent** dans le chemin court (ascent-distill §17, garde AD-14). Le moteur Ascent **propose** l'ordre (via le `LearningPath`), mais l'UI ne présente que le CTA fixe ; la décision libre de l'agent n'apparaît **qu'en Niveau 4** (panneau contextuel : « pourquoi cet ordre ? », log `AscentAdaptation` — ascent-distill §7).
- La **timeline 4 semaines** (plan mesurable) vit **DANS** Slide-Ascent (vue Niveau 3), **pas sur Home** (garde AD-14, ascent-distill §7).

---

## 7. Page States (AD-13, 5 états canoniques)

| State | When | Appearance | Actions |
|-------|------|------------|---------|
| **Default** | `LearningPath` actif chargé depuis le mirror local PowerSync (`ascent_paths`, AD-7, ascent-distill §13), Niveau 1 visible (étape courante + suivante) | Slide courante + barre disclosure + CTA fixe « Commencer / Reprendre » + 5 actions Active Reading ; BottomNav 5 tabs (S-31) | Tap CTA → démarre/reprend la slide courante ; tap « Niveau 3 » → timeline 4 semaines + log d'adaptation |
| **Loading** | Charge du `LearningPath` (PowerSync mirror local, AD-7) | Skeleton de la slide courante (~300 ms max, AD-13), CTA indisponible | — |
| **Empty** | Aucun `LearningPath` actif (V1 = 1 objectif actif à la fois, ascent-distill §17.4) | État vide **actionnable** : « Aucun trajet actif — définir un objectif » + CTA « Créer un objectif » (CTA fixe AD-14, jamais proposition libre) — jamais un vide mort (EXPERIENCE.md §State Patterns A2) | Tap CTA → `/agent` (S-29) pour formuler l'objectif NL verbatim (ascent-distill §6.1 `goal` NL verbatim) |
| **Error** | Sync hors-ligne + mirror local corrompu | Bandeau « hors-ligne — dernières données locales » (AD-7), slide lue en **read-only** depuis le mirror, adaptations cloud **désactivées avec explicatif** (ascent-distill §7, 5 états UX AD-13) | Tap quand réseau revenu → re-sync ; les adaptations (réordonner/remédiation) restent désactivées tant qu'offline |
| **Offline** (AD-7) | Réseau coupé, `LearningPath` chargé depuis le mirror local | Bandeau fine « hors-ligne » (AD-13, A5), slide lue depuis le mirror, CTA « Commencer / Reprendre » reste **actionnable** (les données sont locales) — les **adaptations cloud** (réordonner, insérer remédiation) sont **désactivées avec explicatif** (jamais masquées — EXPERIENCE.md §State Patterns A5) | Tap CTA → slide courante (lecture seule) ; tap sur les 5 actions → `Explain`/`Note`/`Flashcard`/`Visualize` localement si possible, `Je bloque` → S-22 (kernel analyse, dégradation documentée) |

---

## 8. Open Questions

| # | Question | Context | Status |
|---|----------|---------|--------|
| 1 | **Le CTA fixe « Commencer / Reprendre » ouvre-t-il la slide courante (Niveau 1) ou déclenche-t-il directement l'activité déléguée (QCM S-20 / flashcards S-19 / exercice S-38) ?** Le corps gelé (AD-14, garde CTA fixe) ne tranche pas ; ascent-distill §17.2 mapping réutilisation (S-41 orchestre S-19/S-20/S-38 via S-25) suggère que le CTA ouvre la slide (Niveau 1) et que **l'activité déléguée** est le **2ᵉ geste** (tap sur la slide → `learningCommand`). Une option B (CTA = 1 geste direct vers l'activité) serait plus rapide mais **contredirait** la progressive disclosure (montrer l'info quand elle devient utile, ascent-distill §7). | AD-14 (CTA fixe) ; ascent-distill.md §7 (progressive disclosure) + §17.2 (mapping S-19/S-20/S-38 via S-25) | OQ-1 **Close (option A, 09/25, ratifié par Joy)** — CTA fixe « Commencer / Reprendre » = ouvre la slide courante Niveau 1 ; l'activité déléguée reste le 2ᵉ geste — progressive disclosure (ascent-distill §7). |
| 2 | **La timeline 4 semaines (vue Niveau 3) est-elle un Gantt (type S-33 `timeline-gantt`) ou une liste verticale ordonnée (type `AscentStep[]`) ?** Le corps gelé (AD-13, OQ-11 budgets) ne tranche pas ; OQ-1 du spec 02.5 (close option A, 09/25) : **liste chronologique simple, pas de Gantt interactif** (budget OQ-11 — 300 Ko JS, 30 fps) ; la règle est **réutilisable** : la timeline S-41 doit être **non-interactive** (pas de Gantt) pour tenir le budget OQ-11. | AD-13 (5 états) ; OQ-11 (budgets) ; OQ-1 spec 02.5 close option A (liste chronologique simple, pas de Gantt interactif) ; ascent-distill.md §6.1 (`AscentStep[]`, `depth{}`) | OQ-2 **Close (option A, 09/25, ratifié par Joy)** — timeline 4 semaines = liste verticale ordonnée (non-interactive, budget OQ-11) ; réutilise OQ-1 spec 02.5 close option A (pas de Gantt interactif, Gantt reporté V1.1). |
| 3 | **Porte d'entrée du chat agentique (S-29) sur `/learn/ascent` : 5ᵉ tab BottomNav S-31 + FAB back-up (option C, OQ-4 close 01.1) — se propage à toutes pages Phase 4.** Sur `/learn/ascent`, la BottomNav **est présente** (5 tabs : `Home · Kanban · Calendar · Progress · /agent`) — c'est une route de détail au-dessus du tab courant (invariant S6.2), pas un écran sans BottomNav ; le **FAB chat S-29 est masqué** (le 5ᵉ tab est l'entrée principale, OQ-4 close option C). Si Horeb est en focus-mode, `/learn/ascent` n'est pas accessible (focus bloque les autres surfaces, focus-mode §7) — le FAB réapparaît uniquement dans la variante Focus (01.1, OQ-4 close). NON COUVERT par le corps gelé (cible du 5ᵉ tab non nommée) — ratifié comme proposition WDS (OQ-4 close, 2026-09-25). | OQ-4 close option C (01.1, 09/25) ; `EXPERIENCE.md` §Information Architecture invariant S6.2 (route au-dessus du tab courant) ; focus-mode §7 | OQ-3 **Close (OQ-4, option C, 01.1)** — 5ᵉ tab BottomNav = `/agent` (S-29) + FAB back-up sur écrans sans BottomNav (overlays, focus-mode). Sur `/learn/ascent` (BottomNav présente), le 5ᵉ tab = entrée principale, FAB masqué. Se propage à toutes pages Phase 4. |

---

## 9. Reference Materials

**Strategic Foundation (Ascent, PROPOSED — NON COUVERT par le corps gelé) :**
- [Ascent Distill](../../ascent/ascent-distill.md) — §6 modèle de domaine (`AscentLearningIR`, `AscentStep`, `AscentActivity`, `LearnerBaseline` 5 états, `AscentAdaptation`) · §7 UX Slide-Ascent (12 types de slides + progressive disclosure 4 niveaux + 5 actions Active Reading + budgets NFR + garde AD-14) · §8 profondeur Quick/Standard/Deep · §9 READ → DO → PROVE · §13 persistance (`ascent_paths`, PowerSync mirror local) · §15 NON COUVERT déclaré · §17 entrée WDS Phase 4 (S-41 + mapping réutilisation + scénario 07 + dépendances FeatureRegistry)
- [Product Brief](../../A-Product-Brief/product-brief.md) — §2 persona Horeb, §7 Progress (transformation réelle, preuves tracées)
- [Trigger Map](../../B-Trigger-Map/trigger-map.md) — §5 flywheel moteur agentique ; §7 signaux 6 (session nocturne) / 8 (mesurer la progression réelle) / 15 (rythme posé)

**Related Pages (mapping réutilisation, ascent-distill §17.2 — zéro duplication) :**
- [01.3 — Flashcards (S-19)](../01-horebs-progress-proof/01.3-flashcards-review/) — action Active Reading `Flashcard`
- [01.4 — QCM du domaine (S-20)](../01-horebs-progress-proof/01.4-qcm-evaluation/) — action Active Reading `Exercice`
- [03.6 — Learn cours-detail (S-25/S-16)](../03-horebs-active-discovery/03.6-learn-cours-detail/) — activités déléguées `learningCommand` (cours + chapitres)
- [01.5 — Mirror-cognitive (S-22)](../01-horebs-progress-proof/01.5-mirror-cognitive/) — actions Active Reading `Explain` / `Je bloque` (kernel analyse)
- [01.2 — Analytics /progress (S-13)](../01-horebs-progress-proof/01.2-analytics-progress/) — Niveau 4 « historique de progression de cette compétence »
- [02.5 — Timeline Gantt (S-33)](../02-horebs-gap-closure/02.5-timeline-gantt/) — OQ-1 close option A (liste chronologique simple, pas de Gantt interactif — règle réutilisable S-41 OQ-2)

**Docs Ascent (pont vers le module PROPOSED) :**
- `docs/ascent/overview.md` — SSoT conceptuel (22 sections) [ascent-distill §16 pointeur]
- `docs/ascent/implementation.md` — guide d'implémentation wave 3+ (domain types, module serveur, Slide-Ascent UI, kernel integration, data, tests)
- `prompts/session-4-wave3-agent-integration.md` §SOUS-AGENT 5 SOPHIA — plan de commits « wave3/sophia » + règles serveur / 80-20 (ascent-distill §15, NON COUVERT : SOPHIA ajoutée post-hoc)

**Design System** (à extraire — composants Slide-Ascent : slide courante, barre disclosure 4 niveaux, 12 types de slides (KaTeX/AntV lazy), 5 actions Active Reading, timeline 4 semaines, bandeau offline AD-7, CTA fixe AD-14)

---

## 10. Budgets & Contraintes NFR (Pixel 4a, OQ-11)

| Contrainte | Valeur | Source |
|---|---|---|
| JS initial (gz) | ≤ 300 Ko | OQ-11 |
| TTI | ≤ 1,5 s | OQ-11 |
| FPS | 30 | OQ-11 |
| Thème par défaut | Nocturne (OQ-16, 1re classe) | SPEC |
| Offline | État premier, AD-7 (PowerSync mirror local `ascent_paths`, lecture seule ; adaptations cloud désactivées avec explicatif, AD-13) | ADR AD-7, ascent-distill §13 |
| Moteurs KaTeX / AntV | **Lazy par essence, jamais au bundle initial** (budget OQ-11 : JS ≤ 300 Ko gz) — les 12 types de slides (KaTeX, AntV, images) = cas le plus lourd des moteurs visuels frozen (EXPERIENCE.md §Perf S9, ascent-distill §7) | EXPERIENCE.md §Perf S9, ascent-distill §7 |
| Garde AD-14 | **CTA fixe** « Commencer / Reprendre » — **jamais proposition libre de l'agent dans le chemin court** (le moteur Ascent propose l'ordre via le `LearningPath`, l'UI ne présente que le CTA fixe ; la décision libre n'apparaît qu'en Niveau 4 « pourquoi cet ordre ? » — log `AscentAdaptation`, ascent-distill §7) | ADR AD-14, ascent-distill §7 (garde AD-14 Slide-Ascent) |
| V1 troncature | **1 objectif actif à la fois** (S-41 affiche un seul `LearningPath` actif ; multi-path = V1.1, ascent-distill §17.4) | ascent-distill §17.4, overview §21 (dérogations V1) |
| Dépendances NON COUVERT | FeatureRegistry rattachement Ascent (feature enfant de Learning vs feature `ascent` autonome) + 8 effets de désactivation (Ascent doit **dégrader** le chemin quand Learning off, pas cacher) — **NON COUVERT par le corps gelé** (Ascent PROPOSED, standup wave-3) ; le CTA « Commencer / Reprendre » reste **désactivé avec explicatif** (jamais masqué, AD-13) si une feature dépendante est off | ascent-distill §17.4 ; scope-report §C (8 effets de désactivation C1-C8) |

---

## 11. Checklist (step 15)

- [x] `S-41-slide-ascent/` folder créé
- [x] `S-41-slide-ascent/Sketches/` folder créé
- [x] `S-41-slide-ascent.md` spec créée (ce fichier, pont `status: draft`)
- [x] Design log `00-design-log.md` — Design Loop Status : `ascent-distill | S-41 | Slide-Ascent (/learn/ascent) | specified | 2026-09-25`
- [x] OQ-1 (CTA slide vs activité déléguée — Close option A, 09/25, ratifié par Joy : CTA = slide courante Niveau 1, activité = 2ᵉ geste)
- [x] OQ-2 (timeline 4 semaines : Close option A, 09/25, ratifié par Joy — liste chronologique simple, règle réutilisable OQ-1 spec 02.5 close option A, budget OQ-11)
- [x] OQ-3 (chat S-29 5ᵉ tab + FAB sur `/learn/ascent`) — **Close** (OQ-4 option C, 01.1)
- [ ] Scénario 07 « Horeb's Trajet d'apprentissage » (ascent-distill §17.3 option 1 recommandée) — **NON tranché**, à indexer en Phase 4 si ratifié (pas d'implémentation ici, convention pont)

---

*Created using Whiteport Design Studio (WDS) methodology · Mode Suggest, steps 08-15 (batch, 09/25) · Budgets : Pixel 4a OQ-11 (30 fps, TTI < 1.5 s, JS < 300 Ko gz), thème Nocturne OQ-16, offline AD-7 · Garde AD-14 : CTA fixe « Commencer / Reprendre », jamais proposition libre dans le chemin court · Ascent = PROPOSED, NON COUVERT par le corps gelé — convention pont : NON COUVERT + options A/B/C au standup, pas d'implémentation*
