---
name: 'Aurora — Trigger Map'
type: trigger-map
status: draft
owner: Joy (via Freya)
created: 2026-09-23
sources:
  - _bmad-output/architecture/architecture-aurora-2026-09-21/adr-extract.md (v1.7 gelé, §1–§26)
  - _bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md
  - _bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md (AD-1…AD-17, read-only)
  - docs/knowledge/discovery-gap-pipeline.md
  - _bmad-output/project-context.md (draft-for-review, generated 2026-09-23)
  - docs/frontend/feature-registry.md (G-M7)
  - docs/agent/feature-agentability-matrix.md (matrice canonique des ids de capacités)
  - docs/features/master-feature-catalog.md (familles de capacités + progress.*)
companion-of: '_bmad-output/wds/_progress/00-design-log.md'
---

# Aurora — Trigger Map (B)

> Pont WDS vers le corpus (non-duplication) : chaque entrée pointe vers sa section
> source. Résolution des conflits : **spine AD-x > ADR v1.7 > SPEC/packs > ce fichier.**
> Les **ids de capacités** sont vérifiés contre la matrice canonique
> `docs/agent/feature-agentability-matrix.md` (une ligne par id) et
> `docs/features/master-feature-catalog.md` (familles `progress.*` / `discovery.*`).
> Quand un id ne se trouve pas dans le corpus, il est déclaré **NON COUVERT**,
> jamais inventé.

## 1. Objectifs business (tiers)

| Tiers | Objectif | Source |
|---|---|---|
| **Primary** | Mesurer la **transformation réelle** de Horeb dans le temps (état, évolution, causes, preuves) — pas un compteur de tâches | ADR §18 |
| **Secondary** | Faire converger vers l'**excellence internationale** : écarts documentés (académique ↔ professionnel ↔ international), preuves de compétence construites progressivement | ADR §13.5 |
| **Tertiary** | **Discovery continue** : découverte active (pas de veille passive) qui élargit capacités, compréhension et vision | ADR §13 (principe intro) + §13.1–13.3 |

## 2. Persona principale — Horeb

Jeune ingénieure en génie civil au Bénin (disciplines : BA / RDM / hydraulique),
usage **mobile intensif en nocturne** (Phase 1 Android-only, ADR §23 ; thème
Nocturne = preset autonome pour sessions nocturnes, OQ-16 — pack 05 §5).
Tous ses paramètres vivent dans `UserContext` (AD-15) : `region`, `disciplines`,
`professional_target`, `budget_constraint` (G-D14, `project-context.md` §5) —
**zéro `if user === Horeb`** dans le code (règle de `discovery-gap-pipeline.md` §5
« no `if user === Horeb` in code » ; qualification bloquante = finding de review,
`docs/epics-stories.md` W6-E1-1 + `project-context.md` §6, mission §21.6).

**Rôle dans le flywheel** : capture → learning → progress → self-improvement →
adaptive planning (sous-cycle §15 ; boucle canonique `discovery-gap-pipeline.md` §3).

### Drivers positifs (TOP 3)

| # | Driver | Source |
|---|---|---|
| 1 | **Focus** : Focus Mode + anti-distraction = session de travail profond | ADR §2.8 |
| 2 | **Discovery utile** : « ce que cette personne doit découvrir maintenant pour réduire ses lacunes et augmenter son niveau professionnel » (principe intro §13, avant §13.1) | ADR §13 |
| 3 | **Self-improvement** : Expert Skills — apprentissages opérationnels vérifiés et réutilisables | ADR §14 (§14.2) |

### Drivers négatifs (TOP 3)

| # | Driver (ce qui dévie) | Source |
|---|---|---|
| 1 | **Illusion de progression** : bon score de reconnaissance masquant une faible capacité de transfert | ADR §18.2 |
| 2 | **Veille passive** : accumulation de liens/notifications sans action | ADR §13, §17 |
| 3 | **Surcharge de widgets** : Home dégradé en tableau de bord de widgets | AD-14 (pack 05 §4.1.2), ADR §12 |

## 3. Personas secondaires / tertiaires

**NON DÉFINIES DANS LE CORPUS.** Le pack 05 S1 et `00-design-log.md` ne ratifient
que la cible primaire Horeb. Toute adaptation se fait par données (`UserContext` +
Feature Registry + product modes), jamais par personas codées.

## 4. Intent → Capability mapping (ADR §4 → §5 orchestration + registry)

L'utilisateur ne choisit jamais un module : Aurora déduit l'intention puis active
les capacités (§4). Orchestration = boucle du kernel `Intent → Context → Plan →
Retrieve → Tools → Verify → Action → Result → Memory` (§5, AD-12 F-09, exécution
serveur). Les capacités exposées par chaque module viennent du
`AgentFeatureDeclaration.capabilities[]` (`feature-registry.md` §9) ; l'Intent
Engine du kernel classe l'intention via TaskProfile typé (**jamais** de mots-clés,
wave 3 checklist `project-context.md` §6). Les commandes partagent **une**
capacité avec 5 points d'entrée (bouton · palette · agent NL · deep link ·
automation) sans logique métier dupliquée (`feature-registry.md` §4).
Chaque id ci-dessous est vérifié contre `feature-agentability-matrix.md`
(matrice canonique) ou `master-feature-catalog.md` (familles) ; un id absent du
corpus serait déclaré **NON COUVERT**, jamais inventé.

| # | Intention (ADR §4) | Exemples de commandes (S4 registry) | Capabilities Aurora (orchestration §5 + registry) |
|---|---|---|---|
| 1 | **Planifier** | « Construire le planning de la semaine » | `calendar.schedule` · `task.create` / `task.update` · `planning.daily` / `planning.replan` (Productivity, composition AD-14) |
| 2 | **Organiser** | « Trier l'inbox » · « Rattacher la ressource au cours » | famille `productivity.inbox` (triage) + `task.update` · famille `productivity.library` (ressources) + `course.search` (Productivity §2.1) |
| 3 | **Exécuter** | « Ouvrir Focus » · « Lancer la tâche la plus urgente » | `focus.start` · `task.update` (lancer/démarre) · `planning.daily` (actions importantes/irréversibles = politique de confirmation §5, pas une capacité) |
| 4 | **Apprendre** | « Créer une fiche sur RDM » · « Expliquer cette notion » | `learning.sheet.generate` · `learning.mirror.analyze` (Mirror, explication/correction) · `course.search` (Learning + AD-11 fidélité corpus) |
| 5 | **Rechercher** | « Lancer une recherche » · « Que dit la source ? » | `discovery.research` (multi-source via `ResearchProvider`) · `knowledge.retrieval` (preuve de source, `SourceRef`) (Discovery) |
| 6 | **Pratiquer** | « Me donner un exercice de validation » | `scientific.evaluate` / `scientific.verify` (Scientific Engine déterministe, unités/dimensions vérifiées) + exercices progressifs de la famille `learning.qcm` / `learning.sheet` (id d'exercice dédié = **NON COUVERT**) |
| 7 | **Progresser** | « Analyser Progress » | `progress.analyze` · `progress.evidence` (module Progress, AD-9 `ProgressEvidenceCreated`, F-07) |
| 8 | **Découvrir** | « Ce que je devrais découvrir maintenant » | `discovery.gaps` · `discovery.horizons` (Gap object durable, `discovery-gap-pipeline.md` §1.2–1.3 ; fiche de découverte = ADR §13.8) |
| 9 | **Réviser** | « Réviser mes flashcards » | `flashcard.generate` (génération) + famille `learning.flashcards` (FSRS, rappel espacé) · `review.run` (révision) (ADR §3) |
| 10 | **Piloter** | « Comment va ma trajectoire ? » | `coach.checkin` · `progress.trajectories` (§13 Coach adaptatif, §18.5/§18.7 trajectoires conditionnelles) |

> **Note d'exhaustivité §18.8** : le modèle de données conceptuel ADR §18.8 liste
> 7 entités — `ProgressSnapshot`, `ProgressEvidence`, `SkillState`, `ProgressEvent`,
> `ProgressTrend`, `Gap`, `TrajectoryScenario`. La table ci-dessus ne cite que
> celles qui apparaissent dans la boucle agentique ; l'exemple est non exhaustif.

## 5. Flywheel Aurora (ADR §15/§18.7/§19 + `discovery-gap-pipeline.md` §3)

Le flywheel est le **sous-cycle §15** (5 étapes autonomes). Le **cycle complet
§19** (11 étapes : Capture → Organize → Plan → Execute → Learn → Discover →
Practice → Progress → Self-Improve → **Adapt** → Review) est le référentiel ;
voir brief §5. Les deux niveaux sont distincts et aucun n'est omis ici.

```
Sous-cycle §15 (étapes autonomes) :
Discovery → Knowledge → Learning → Practice → Progress
    ↑                                                   |
    └──────────── (le prochain gap découle du résultat) ◄──┘

Cycle complet §19 (référentiel, 11 étapes) :
Capture → Organize → Plan → Execute → Learn → Discover → Practice
→ Progress → Self-Improve → Adapt → Review
```

- Les 5 étapes autonomes du sous-cycle §3 de `discovery-gap-pipeline.md` sont
  **DISCOVERY / KNOWLEDGE / LEARNING / PRACTICE / PROGRESS** (l'étape KNOWLEDGE
  insère le gap dans l'arbre ; Self-Improvement est l'issue de PROGRESS, pas une
  6ᵉ étape autonome). L'Agent les exécute comme background jobs persistés (AD-8)
  ; l'utilisateur ne voit que le résultat (branche nouvelle, explication
  visuelle, exercice, progression).
- `Progress` est le **moteur agentique** (ADR §18.7) : un gap déclenche révision,
  exercice, recherche ou tâche ; une stagnation déclenche l'analyse de cause.
- Raccord architecture : événements AD-9 (`DiscoveryItemCreated`,
  `ProgressEvidenceCreated`, `SkillStateChanged`) + ownership AD-6 (Knowledge écrit
  `NodeState`, Progress émet uniquement, F-07).

## 6. Traps — ce qui détourne de l'objectif

| Trap | Règle de défense | Source |
|---|---|---|
| **Veille passive** | Discovery = système de découverte active typée (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY), orientée besoins du profil, jamais un flux de liens | ADR §13, §17 |
| **Illusion de progression** | Modèles de preuve : QCM, rappel actif, exercice nouveau, explication — distinguer reconnaissance vs transfert | ADR §18.2, §18.3 |
| **Surcharge de widgets** | Invariant Home : composition fixe qui répond « Quoi de *important maintenant* ? » (7 items fixes, jamais un dashboard) ; désactivation = la feature disparaît de la surface, les données restent | AD-14 (7 items = pack 05 §4.1.2), ADR §12, `feature-registry.md` §6 |
| **Blocage natif promessable** | Focus Controller Android = restriction/DND/Screen Pinning **uniquement** ; `isBlockingAvailable()` = false → **pas de CTA de blocage dans l'UI** ; DPC (OQ-17) = mode optionnel expérimental (candidat ADR v1.8), jamais promis en V1 nominale | ADR §2.8, pack 04 §4.1, `project-context.md` règle 14 |

## 7. Signaux psychologiques (persona Horeb)

> Méthodologie : chaque signal est ancré dans une citation ≤ 25 mots du corpus.
> Les catégories sans signal explicite sont signalées. Les « Type » (peur / envie /
> anxiété / douleur) sont inférés de la formulation normative du corpus (les normes
> préviennent explicitement des états psychologiques). Le corpus est
> normatif/architectural : ces signaux sont **déduits** des contraintes de design,
> pas observés (aucune étude utilisateur n'existe dans le corpus).

| Signal | Type | Source (fichier §section) | Evidence (citation ≤ 25 mots) |
|---|---|---|---|
| Peur de la trahison de la définition du professeur dans les fiches (reformulation présentée comme définition officielle) | Peur | adr-extract §17 + spine AD-11 | « ne doit pas remplacer silencieusement la formulation attendue » ; « la priorité est la fidélité au corpus » |
| Besoin de conformité académique stricte aux formulations imposées par l'enseignant | Envie | adr-extract §17 | « fidèle au corpus pédagogique fourni » ; « définitions et formulations imposées peuvent être conservées textuellement » |
| Anxiété devant l'intrusivité de l'agent — demande de contrôle total (cadence, silence, désactivation) | Anxiété | adr-extract §13 Coach | « Le coaching ne doit pas devenir intrusif » ; « cadence, horaires de silence et niveau d'intervention contrôlés par l'utilisatrice » |
| Fatigue d'alertes et de notifications — désir d'information contextuelle plutôt que de bruit | Douleur | adr-extract §13 Coach | « Aurora explique le constat, propose une action et suit le résultat au lieu de multiplier les notifications » |
| Peur de la distraction / perte de concentration (Focus Mode, anti-distraction) | Peur | adr-extract §2.8 + pack 04 §4.1 | « Focus Mode / sessions de concentration / blocage ou limitation des applications distrayantes » ; blocage natif Android non promessable (OQ-06/OQ-17) |
| Besoin de concentration en sessions nocturnes (thème Nocturne dédié) | Envie | SPEC.md OQ-16 + pack 05 §5 | « Nocturne est un preset autonome… surfaces plus foncées, accents désaturés… pour les sessions nocturnes » |
| Douleur liée à la perception de faux progrès (illusion de compétence) | Douleur | adr-extract §18.2 | « Détecter les cas où un bon score de reconnaissance masque une faible capacité de rappel ou de transfert » |
| Besoin de preuve de progrès réel (traçabilité des compétences) | Envie | adr-extract §18.3 + discovery-gap §2C | « Toute progression significative doit être reliée à des preuves et à un contexte » ; NodeState → 'mastered' (§2C) |
| Anxiété vis-à-vis de la charge de travail / surcharge (temps réellement disponible) | Anxiété | adr-extract §2.4 + §2.10 | « Détection des conflits et de la surcharge » ; « charge planifiée vs charge réelle » |
| Peur de l'incompréhension d'une notion (mode Mirror, correction d'erreurs) | Peur | adr-extract §3 (Mirror Cognitive Mode) | « L'étudiante explique ce qu'elle a compris et Aurora détecte lacunes, contradictions et erreurs » |
| Besoin de hiérarchie lisible du savoir (rejet du « second brain » en réseau illisible) | Envie | adr-extract §14 Arbre sémantique | « L'interface privilégie l'exploration par niveaux… jamais une toile de centaines de connexions » |
| Douleur liée à l'incertitude sur sa position par rapport au métier réel (écarts non documentés) | Douleur | adr-extract §13.4 + discovery-gap §5 | « Écart entre le programme universitaire suivi et les compétences réellement utilisées dans le métier » ; « cartographie des écarts documentés » |
| Envie d'horizon d'excellence internationale / différenciation professionnelle | Envie | adr-extract §13.5 | « Devenir une ingénieure capable de comprendre son domaine en profondeur, de travailler avec les outils contemporains » |
| Contrainte budgétaire étudiante (exclusion des outils payants dans la découverte) | Peur | discovery-gap §5 + project-context G-D14 | « Tools: free/open-source preferred (EPANET free, OpenSees free, ANSYS student free) » ; `budget_constraint: 'student'` |
| Préoccupation fiabilité réseau / connectivité (Bénin, mobile data, offline) | Anxiété | discovery-gap §5 + adr-extract §23.1 + spine AD-7 | « Internet connectivity: limited fiber, mobile data common, power reliability varies » ; « Offline is a first-class state, not a failure mode » (AD-7) |
| Besoin de performance fluide sur appareil entry-level (sessions intensives, pas de lenteur) | Envie | project-context §3 règle 15 + SPEC OQ-11 | « Budgets = Pixel 4a, ≤ 300 Ko JS gz initial, ≤ 1,5 s TTI, 30 fps » |
| Souci de confidentialité des données personnelles (cours, notes, notes de calcul) | Anxiété | adr-extract §11 + spine AD-3 | « Les documents, cours, notes et informations personnelles… ne doivent pas être envoyés vers un free tier incompatible » ; « Zéro clé sur appareil » (AD-3) |
| Peur de la dégradation silencieuse des capacités gratuites (free tiers non SLA) | Peur | adr-extract §8 + §10 | « Un free tier est traité comme une capacité variable, non comme une SLA » ; « le routeur doit pouvoir les retirer automatiquement… s'ils deviennent indisponibles ou payants » |
| Besoin de traçabilité des réponses IA (confiance dans le fallback multi-provider) | Envie | adr-extract §10 + project-context Wave 3 DoD | « Une réponse de fallback doit rester traçable : provider, modèle, tentative, motif et qualité attendue sont enregistrés » |
| Douleur liée aux reports et à la procrastination (analyse des causes, pas de jugement) | Douleur | adr-extract §2.10 + §18.2 | « Tendances de procrastination » ; « Analyser les causes des écarts plutôt que simplement compter les tâches terminées ou non » |

### Catégories couvertes / absentes (vérification par catégorie)

- **Fidélité académique (§17)** — couverte (signaux 1, 2).
- **Confiance / traçabilité (§15)** — couverte indirectement : §15 (Ingénierie mathématique)
  ne contient pas de signal psychologique explicite ; la confiance/traçabilité est
  portée par §18.2/§18.3 (preuve), §18.5 (trajectoires conditionnelles), AD-11
  (provenance) et v1.7 §10 (traçabilité des fallbacks) — signaux 7, 18.
- **Concentration (§2.8)** — couverte (signaux 5, 6).
- **Cohérence surface/depth (§12)** — **AUCUN signal explicite** dans le corpus ; §12
  est une règle de design produit (« simple en surface et puissante en profondeur »)
  sans formulation psychologique. **Non couvert — ne pas inventer.**
- **Découverte orientée excellence (§13.5)** — couverte (signaux 12, 11, 14).
- **Progression réelle vs illusion (§18.2)** — couverte (signaux 7, 20).
- **Coaching non-intrusif (§13)** — couverte (signaux 3, 4).
- **Offline (§23.1 local-first)** — **AUCUN signal psychologique explicite** dans
  §23.1 ; le signal offline est porté par AD-7 (spine) + discovery-gap §5 (Bénin :
  mobile data, électricité) — couvert indirectement (signal 15), pas dans §23.1.
- **Performance budget (pack 02 §9)** — le pack `dimensions/02-frontend.md` §9 n'est
  pas dans le corpus lu ; les budgets perf sont ancrés via project-context §3 règle
  15 + SPEC OQ-11 (signal 16) — **couverts** par ces pointeurs uniquement.

### Limites

- Le corpus est normatif/architectural : les signaux psychologiques sont déduits des
  contraintes de design (ex. « ne doit pas devenir intrusif » = signal d'anxiété),
  pas observés. Aucune donnée d'étude utilisateur (entrevue, journaling, métriques
  comportementales de Horeb) n'existe dans ce corpus.
- §12 (cohérence surface/depth) et §23.1 (offline) ne contiennent aucun signal
  psychologique explicite ; les signaux proches ont été récupérés dans §2.8, §13/§14,
  AD-7 et discovery-gap §5.
- Le « §9 pack 02 » (`dimensions/02-frontend.md`) n'a pas été lu (hors corpus
  demandé) ; le signal perf est ancré via `project-context.md` §3-15 + SPEC OQ-11,
  seuls porteurs de budgets.

## 8. Pointeurs architecture (raccord, non-duplication)

- Spine autoritaire : `ARCHITECTURE-SPINE.md` — AD-1…AD-16 gelés (statut final
  2026-09-21, SPEC) + **AD-17 porté par le pack 05** (SPEC OQ-14/15/16) ; 17 ADs
  adoptés à ce jour.
- Matrice canonique des ids de capacités : `docs/agent/feature-agentability-matrix.md`
  (une ligne par id, SSoT types en `packages/domain`) — source de vérité des
  capacités de §4.
- Familles `progress.*` / `discovery.*` (ids canoniques hors matrice agent) :
  `docs/features/master-feature-catalog.md` (`progress.evidence`,
  `progress.trajectories`, `discovery.gaps`, `discovery.horizons`, `knowledge.retrieval`,
  `productivity.inbox`, `productivity.library`).
- Boucle complète §19 (11 étapes) et sous-cycle §15 : `adr-extract.md` §15/§19 ;
  `docs/knowledge/discovery-gap-pipeline.md` §3.
