---
name: 'A-Product-Brief/product-brief'
type: product-brief
status: draft
sources:
  - _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md
  - docs/knowledge/discovery-gap-pipeline.md
  - _bmad-output/project-context.md (status : draft-for-review, généré 2026-09-23 — sans numéro de version)
  - docs/agent/feature-agentability-matrix.md
  - docs/features/master-feature-catalog.md
  - docs/epics-stories.md
---

# Product Brief — Aurora (WDS A-Product-Brief)

## 1. Vision produit

Aurora est un espace de travail personnel intelligent réunissant productivité, apprentissage, projets, recherche, pratique, suivi de progression et assistant agentique ; ses fonctionnalités sont les capacités d'Aurora, et l'intention et le contexte de l'utilisatrice déterminent lesquelles l'agent active et orchestre (adr-extract §1). Le principe directeur : « simple en surface, puissante en profondeur » — on commence avec une tâche ou un calendrier, puis on exploite projets, apprentissage, recherche et agent ; le système cohérent des données, des capacités et de l'agent prime sur l'empilement de fonctionnalités visibles (adr-extract §12, §17).

## 2. Cible & contexte

Persona principale : **Horeb**, étudiante en **génie civil** (BA, RDM, hydraulique) au **Bénin**, en vue d'un métier de **bureau d'études** (`discovery-gap-pipeline.md` §5 « Benin context » : région Bénin, disciplines, budget étudiant, outils gratuits/open-source préférés ; §1.1 pipeline pour les disciplines) ; le profil est porté par `UserContext` — G-D14 `project-context.md` §5 : `region`, `disciplines`, `professional_target`, `budget_constraint` sont des **données de `UserContext`**, jamais du hardcoding (AD-15 = SSoT des types de domaine). Usage : **mobile intensif** — réseau mobile fréquent, connectivité limitée, budget étudiant (`discovery-gap-pipeline.md` §5) ; les **sessions de concentration nocturnes** font partie du contexte d'usage (pack 05 §5, thème Nocturne = preset autonome, SPEC OQ-16) ; donc offline-first (spine AD-7, adr-extract §23.1), budgets perf sur **Pixel 4a** (SPEC OQ-11 : ≤300 Ko JS gz, ≤1,5 s TTI, 30 fps).

## 3. Scope V1 mobile-only

- Cible : **app Android (Ionic React + Capacitor)** ; aucune livraison desktop/Electron, aucun temps agent sur le desktop en Phase 1 (adr-extract §23.1/§24, SPEC « Scope V1 »).
- Cœur **platform-agnostic** ; la Phase 2 (Electron, Yjs, STT local whisper.cpp, microservices, Event Sourcing) = ajouter des adapters, pas réécrire (adr-extract §23.4/§23.5, SPEC « Phase 2 »).
- Offline = état premier, lecture locale, écritures local-first via module owner (spine AD-7) ; Focus = restriction/DND/Screen Pinning uniquement (pack 04 §4.1, SPEC OQ-06/OQ-17).
- **NON COUVERT PAR LE CORPUS** : KPIs produits quantitatifs (taux d'activation, rétention), personas secondaires et segmentation marché.

## 4. Intentions principales

Les 10 intentions (adr-extract §4) : **Planifier, Organiser, Exécuter, Apprendre, Rechercher, Pratiquer, Progresser, Découvrir, Réviser, Piloter**. L'utilisateur ne doit pas choisir manuellement un module : Aurora déduit l'intention puis active les capacités nécessaires ; le schéma agentique complet est `Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory` (spine AD-12).

Quand le brief ou la trigger map cite des capability ids (ex. `calendar.schedule`, `planning.replan`, `course.search`, `learning.mirror.analyze`), la matrice canonique de vérification est **`docs/agent/feature-agentability-matrix.md`** (une ligne par capability id, statuts FULL/PARTIAL/CONFIRMATION_REQUIRED/…) ; pour les familles `progress.evidence` et `progress.trajectories`, le référentiel est **`docs/features/master-feature-catalog.md`** (lignes progress.evidence / progress.trajectories, modèles ADR §18.3/18.5).

## 5. Boucle opérationnelle

Avec Progress, Aurora forme une boucle complète (adr-extract §19) : **Capture → Organize → Plan → Execute → Learn → Discover → Practice → Progress → Self-Improve → Adapt → Review**. Principe : comprendre non seulement ce qui a été fait, mais **ce que l'utilisateur est désormais capable de faire**, pourquoi, et quelle action suivante transforme la situation (adr-extract §19, §20). Le sous-cycle autonome de 5 étapes (DISCOVERY → KNOWLEDGE → LEARNING → PRACTICE → PROGRESS, exécuté en jobs de fond, AD-8) est décrit dans `discovery-gap-pipeline.md` §3 ; il s'inscrit dans le cycle complet §19 (11 étapes) : le brief cite les deux niveaux, le §19 restant le référentiel.

## 6. Capacités stratégiques

- **Discovery** (adr-extract §13) : découverte active et multi-source (13.2), profil dynamique (13.1), analyse d'écarts documentée (13.4), fiche de découverte durable (13.8 = structure de fiche), boucle de découverte (13.9) ; l'objet **Gap durable est Progress-owned** — canon `discovery-gap-pipeline.md` §1.2–1.3 (pas 13.8, qui est la structure de la fiche) ; filtrage **data-driven** par `UserContext` (Bénin, budget étudiant), jamais par jugement LLM (`discovery-gap-pipeline.md` §5) ; capacité canonique : `discovery.research` (matrice agentability).
- **Progress** (adr-extract §18) : mesure de la transformation réelle — état, évolution, causes, preuves — et non un compteur de tâches ; modèle de données §18.8 (exemples non exhaustifs : `ProgressSnapshot`, `ProgressEvidence`, `SkillState`, `Gap`, `TrajectoryScenario` — le canon liste aussi `ProgressEvent` et `ProgressTrend`), moteur agentique §18.7 ; familles canoniques `progress.evidence` / `progress.trajectories` = `docs/features/master-feature-catalog.md`.
- **Self-Improvement** (adr-extract §14) : erreurs utiles et réussies vérifiées deviennent des **Expert Skills** (procédures réutilisables, confiance, provenance, révisables), avec garde-fous §14.5 ; boucle unique Discovery→Learning→Practice→Progress→Self-Improvement (adr-extract §15 ; `discovery-gap-pipeline.md` §3).
- **Aurora Coach** (adr-extract §13) : coaching contextuel proactif (check-ins, détection de changements, replanification dynamique — `planning.replan`), cadence et silence contrôlés par l'utilisatrice — jamais intrusif (capacité `coach.checkin` matrice agentability).

## 7. Contraintes & interdits produit

- **Accueil (spine AD-14)** : l'accueil répond à « Qu'est-ce qui compte maintenant ? » avec une **composition fixe** (7 éléments fixes, canon pack 05 §4.1.2) : agenda du jour, prochaine action importante, priorité, progression critique, révisions dues, accès Focus, suggestions Coach ; **jamais** un dashboard de widgets (adr-extract §11, §12).
- **Principe final (adr-extract §12)** : simple en surface, puissant en profondeur ; ne pas empiler de fonctionnalités visibles — un système cohérent où données, capacités et agent se renforcent.
- **Focus (adr-extract §2.8)** : le blocage natif des apps tierces doit être validé techniquement avant toute promesse ; sur Android V1, `isBlockingAvailable()` = false → **pas de CTA de blocage dans l'UI** (le détail « blocage natif non promessable » vient du pack 04 §4.1 et de SPEC OQ-06/OQ-17, pas de §2.8 lui-même) ; DPC = candidat ADR v1.8, mode dégradé sans DPC (SPEC OQ-17).
- **Zéro `if user === Horeb`** : tout le contexte (région Bénin, disciplines, budget) est porté par `UserContext` (G-D14, `project-context.md` §5 ; AD-15 SSoT) ; `discovery-gap-pipeline.md` §5 énonce la règle « no `if user === Horeb` in code » ; un branchement par identifiant utilisateur est un **finding de review bloquant** (`docs/epics-stories.md` W6-E1-1 : « No `if user===Horeb` anywhere (review finding if detected) » ; `project-context.md` §6 wave 6 ; rôle de Codex en adr-extract §21.6) ; ADR §21.6 décrit le rôle de reviewer de Codex, la qualification « bloquant » vient d'epics-stories et de wave 6.
- **Local-first** : l'UI lit uniquement le local ; le kernel n'écrit jamais d'entité (spine AD-7, `project-context.md` §3 règle 1).
- **Zéro clé sur l'appareil** : tous les appels IA passent par le serveur (spine AD-3, `project-context.md` §3 règle 2).
- **Fidélité corpus** : les définitions du corpus enseignant restent textuellement dominantes ; l'explication de l'agent est séparée et labelisée (spine AD-11, adr-extract §17).
- **Événements fermés** : vocabulaire de 9 événements normatifs (spine AD-9) ; un 10ᵉ = ADR additif (`project-context.md` §3 règle 6).

## 8. Références architecture (pointeurs, pas de recopie)

- Spine autoritaire (read-only) : `_bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md` — **AD-1…AD-16 gelés (statut final 2026-09-21)** ; **AD-17 [ADOPTED] (multi-theme skin) porté par le pack 05** (SPEC OQ-14/15/16 ; spine AD-17 [ADOPTED]) — le SPEC dit « 16 ADs gelés », l'AD-17 ayant été ajouté au spine par ratification du pack 05.
- ADR v1.7 gelé : `_bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md` (§1–§26).
- Contrat prescriptif : `_bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md` (Open Questions OQ-01…OQ-17, plan des vagues 0–7).
- Gap pipeline Discovery/Arbre sémantique : `docs/knowledge/discovery-gap-pipeline.md` (§1–§7).
- **Matrice canonique des capability ids** : `docs/agent/feature-agentability-matrix.md` (une ligne par capability, statuts, fallbacks, confirmations) — référent pour tout capability id cité dans le brief et la trigger map.
- **Familles progress.evidence / progress.trajectories** : `docs/features/master-feature-catalog.md`.
- **Exigence « no `if user===Horeb` » + gates wave 6** : `docs/epics-stories.md` W6-E1-1.
- Règles agents & gates wave 0–6 : `_bmad-output/project-context.md` (§3–§6 ; frontmatter : *draft-for-review, généré 2026-09-23* — sans numéro de version).
