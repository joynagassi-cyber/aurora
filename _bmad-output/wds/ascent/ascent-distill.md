---
status: draft
type: bridge
project: Aurora
feature: Ascent
created: 2026-09-25
owner: Joy via Freya (WDS Designer)
sources:
  - docs/ascent/overview.md (22 sections, PROPOSED — pas un ADR gelé)
  - docs/ascent/implementation.md (guide wave 3+)
  - prompts/session-4-wave3-agent-integration.md §SOUS-AGENT 5 SOPHIA
---

# Ascent — Distillation pour WDS (Phase 4 prep)

> **Nature du document :** pont vers le module **Ascent** (Pedagogical Trajectory Engine),
> module **PROPOSED** ajouté par Joy le 2026-09-25. Ascent n'appartient pas encore au
> corpus gelé (ADR v1.7 / spine AD-1…17) — il est **additif** et ne modifie aucun module
> existant. Cette distillation ne duplique pas le contenu : elle l'indexe avec pointeurs
> courts et déclare explicitement les éléments **NON COUVERTS** par le corpus gelé.
>
> **Rôle dans WDS :** préparer **Phase 4 (UX Design)** — Ascent introduit une ou des
> surfaces UI nouvelles (Slide-Ascent) qui n'existent pas dans le scope-report S-01…S-40.

---

## 1. Statut & position dans le corpus

- **Statut : PROPOSED** (pas d'ADR gelé, pas de numéro AD). Ascent est une couche
  **nouvelle, additif** au-dessus de Learning / Knowledge / Progress / Discovery.
  [overview §1-2 ; implementation 1er bloc]
- **Module serveur (AD-12), wave 3+** — comme l'Agent Kernel. Ne tourne pas sur le
  device ; le device reçoit le `LearningPath` via PowerSync (mirror local en lecture
  seule) et le rend via **Slide-Ascent**. [overview §5, §20 ; implementation Step 2]
- **Ne modifie aucun module existant.** Ascent lit les contrats publics
  (AD-2) et écrit **uniquement** sa propre table `ascent_paths` (AD-7 single-writer).
  Il n'émet pas d'événement AD-9 nouveau : il **consomme** les 9 existants et produit
  `AscentAdaptation` (son propre log, pas un AD-9). [overview §7, §17, §20 ;
  implementation Step 2 Rules]

## 2. Ce qu'Ascent est (1 question)

> « Vu ce que Horeb sait déjà, ce qu'elle cherche à apprendre et sa progression —
> dans quel **ORDRE**, à quel **RYTHME**, avec quelle **PROFONDEUR** doit-elle
> apprendre la suite ? » [overview §1]

Ascent **compose** un `LearningPath` à partir des modules existants et **l'adapte**
quand de nouvelles preuves arrivent. Il ne génère pas de QCM/flashcards (ça c'est
Learning), ne stocke pas de concepts (ça c'est Knowledge), ne mesure pas les preuves
(ça c'est Progress). **Ascent = le chef d'orchestre ; Learning = l'orchestre.**
[overview §1-4, §22 ; implementation "What NOT to Build"]

## 3. Responsabilités exactes (ce qu'Ascent possède)

Trajectoire (ordre) · Priorités (quoi/ pourquoi) · Composition d'un entraînement
(séquence de modules) · Adaptation (réordonner, accélérer, ralentir, insérer une
remédiation) · Prérequis (quoi maîtriser avant) · Décisions de progression
(quand passer / quand revisiter) · Sélection de profondeur (Quick/Standard/Deep) ·
Séquencing **READ → DO → PROVE** (framework pédagogique, pas une contrainte rigide).
[overview §3, §10]

## 4. Ce qu'Ascent ne fait PAS (gardes anti-complexité)

Pas de 2ᵉ LLM « modèle pédagogique » (deterministe : règles + données ; le LLM
explique, Ascent ordonne) · Pas de 13+ agents spécialisés (AD-12 : un seul kernel,
Ascent est une **capacité** du kernel) · Pas de modèle ML (5 états + dimensions suffit)
· Pas de WebGL/3D (AntV + KaTeX + images) · Pas de pipeline distribué (1 fonction,
4 tables) · Ne remplace ni Learning ni Progress · Pas de Graphiti/Zep (AD-11 :
SourceRef + pgvector) · Pas de Drift Guardian 24/7 (évent-driven, pas surveillance
continue). [overview §22 ; implementation "What NOT to Build (80/20)"]

## 5. Position dans l'architecture (data flow)

```
Objectif utilisateur ("Maîtriser RDM d'ici l'exam")
        │
        ▼
   ASCENT ENGINE (nouveau, serveur, wave 3+)
        │  lit via contrats publics (AD-2) :
        ▼
Knowledge · Progress · Discovery · Learning · FSRS
        │  produit :
        ▼
   LearningPath (AscentLearningIR — des données, pas de la UI)
        │  consommé par :
        ▼
Agent Kernel (plan) · Slide-Ascent (UI) · Goal Project (suivi)
        │
        ▼
   PROGRESS (feedback loop : les preuves ré-adaptent le chemin)
```
[overview §5, §8 ; integration points — implementation]

## 6. Modèle de domaine (AscentLearningIR + types support)

- **`AscentLearningIR`** : id, userId, goal (NL verbatim), targetSkill?, targetDate?,
  `steps[]`, `depth{}`, `baseline`, `prerequisites[]`, `passageCriteria[]`,
  `adaptations[]`, status, createdAt/updatedAt. [overview §6.1]
- **`AscentStep`** : label, conceptRefs (Knowledge), skillRef?, sourceRefs (AD-11),
  `activities[]`, `phase` (read/do/prove/remediation/recap), depth, status. [§6.1]
- **`AscentActivity`** : type (read/practice/quiz/flashcard/mirror/exercise/review/
  remediation/recap) ; **délègue** à Learning via `learningCommand` (generate_qcm,
  create_exercise, start_mirror…) ; référence Knowledge via `knowledgeRef`. [§6.1]
- **`LearnerBaseline`** : par compétence, 5 états (**unknown/partial/known/fragile/
  mastered** — **jamais réduits à un score 0-100 unique** ; dimensions optionnelles :
  compréhension / rappel / application / autonomie / rétention). Lue depuis Progress
  `SkillState` — Ascent ne la ré-déclare pas. [§6.2]
- **`AscentAdaptation`** : trigger, action (reorder/accelerate/slow_down/insert_
  remediation/skip/deepen/shallow/revisit/recompose), detail, affectedSteps,
  `evidenceRefs` (provenance AD-11). [§6.3]

> **Règle clé des 5 états :** un concept peut être « maîtrisé en compréhension mais
> fragile en application » — un score unique masquerait ça. [overview §6.2]

## 7. UX : Slide-Ascent (surface UI nouvelle — pour WDS Phase 4)

**Slide-Ascent = le format de PRÉSENTATION** d'un `AscentLearningIR`. Le moteur
produit des données ; Slide-Ascent les rend. 12 **types de slides (palette, pas
séquence obligatoire)** : Concept · Definition · Formula (KaTeX) · Diagram (AntV) ·
Example · Analogy · Timeline · Comparison · Question · Exercise · Reflection · Recap.
Règles : la palette n'impose pas 10 slides/cours ; nb de slides = nb de transitions
significatives ; chaque slide = une VUE sur les données (données = SSoT).
[overview §12 ; implementation Step 3]

### Progressive Disclosure (principes UX)

| Niveau | Contenu |
|---|---|
| 1 (toujours) | « Quoi apprendre ensuite » = étape courante + suivante |
| 2 (tap) | Détail de l'étape : concept, formule, 1 exemple, l'activité à faire MAINTENANT |
| 3 (à la demande) | Vue complète du chemin (toutes étapes, statuts, timeline), carte des prérequis, profondeur + pourquoi, sources (AD-11) |
| 4 (panneau contextuel) | Concepts voisins (Semantic Tree), ponts inter-domaines, historique de progression, « pourquoi cet ordre ? » (log d'adaptation) |

**Règle : montrer l'info quand elle devient utile, pas avant — jamais noyer l'utilisateur
avec le chemin complet au 1ᵉʳ chargement.** [overview §11]

### Active Reading (5 actions légères, couche d'interaction)

Explain · Note · Flashcard · Visualize · **« Je bloque »** (diagnostic à la manière du
Mirror + remédiation suggérée). **Règle : 5 actions pour démarrer, pas 15 actions
contextuelles partout — les 5 couvrent 90 % des besoins.** [overview §14]

### Badges

Profondeur (Quick/Standard/Deep) + hiérarchie des sources (A/B/C/D). [implementation Step 3]

### Budgets & contraintes de surface mobile (rappel NFR)

Slide-Ascent se rend sur **Pixel 4a (OQ-11)** sous **thème Nocturne (OQ-16,
1re classe)** avec budgets **30 fps / TTI < 1,5 s / JS < 300 Ko gz**
(NFR9 — `implementation-readiness-report-2026-09-22.md`). Les 12 types de
slides (KaTeX, AntV, images) sont le cas le plus lourd des moteurs visuels
frozen : **moteurs KaTeX/AntV lazy par essence, jamais au bundle initial**
(EXPERIENCE.md §Perf S9). Offline (AD-7) : chemin lu via PowerSync mirror
local en lecture seule ; adaptations cloud = **bandeau offline + actions
désactivées avec explicatif** (5 états UX, AD-13).

### Garde AD-14 — Slide-Ascent est une surface dédiée, JAMAIS un slot sur Home

L'invariant **AD-14** (Home = 7 items fixes, jamais un dashboard de
widgets) s'applique à Slide-Ascent : c'est une **surface dédiée** (route de
détail ouverte au-dessus du tab courant — invariant S6.2 ; BottomSheet léger
/ route push lourde, EXPERIENCE.md §Component Patterns), **jamais** un 8ᵉ
slot/widget sur Home S-02. L'entrée depuis Home passe par un des 7 slots
existant (bloc « progression critique », ou le bloc Coach → /agent →
Slide-Ascent). La vue **Level 3** (full path + timeline) vit **DANS**
Slide-Ascent, pas sur Home.

## 8. Lecture des 3 niveaux de profondeur

| Niveau | Ce qui change (contenu, PAS l'architecture) |
|---|---|
| **Quick** | 1 concept + 1 formule + 1 exemple + 1 QCM (5 items) |
| **Standard** | Concept + formule + 2 exemples + 10 QCM + 3 flashcards + 1 exercice |
| **Deep** | Standard + dérivation + 3 exemples (complexité croissante) + 20 QCM + 10 flashcards + problème ouvert + miroir + pont inter-domaine |

Sélection : exigences de l'objectif (exam = Deep sur le cœur, Quick sur le secondaire)
· état du apprenant (mastered = skip, fragile = Standard, unknown = Quick d'abord)
· temps dispo (semaine d'exam = Quick sur le faible, Deep sur le fort) · importance
du concept dans la trajectoire (prérequis = Deep, périphérique = Quick).
**Même architecture pour les 3 niveaux — la différence est dans les données du
`AscentLearningIR`, le rendu est identique.** [overview §13]

## 9. READ → DO → PROVE (framework, PAS contrainte)

READ (comprendre) · DO (pratiquer guidé) · PROVE (démontrer la maîtrise
indépendamment, seuil ≥ 80 %). L'Agent (via Ascent) **peut réordonner** :
skip READ si Progress montre « mastered » ; Quick depth + seulement PROVE si
semaine d'exam bloquée par le temps ; insérer une remédiation AVANT l'étape
principale si prérequis fragile. **Ne jamais forcer la séquence mécaniquement —
le séquencing est une DÉFAUT, pas une RÈGLE.** [overview §10]

## 10. Rigueur scientifique (lien Scientific Engine)

Séparation LLM / Engine / Verifier / Knowledge (ADR §15). Quand Ascent inclut une
activité « prove » technique : l'utilisateur fait le QCM (Learning) → les réponses
sont vérifiées par le **Scientific Engine (déterministe)** → validation par
invariants (équilibre, dimensional) → `SolverResult` structuré + traçable →
Progress capture la preuve → Ascent adapte le chemin. **Ascent ne demande JAMAIS
au LLM de « vérifier la réponse » : le LLM explique, l'Engine calcule, le
Verifier valide.** [overview §15]

## 11. Hiérarchie des sources (corpus externes)

| Niveau | Source | Autorité |
|---|---|---|
| **A** | Normatif/official (Eurocode, BAEL, réglementation) | Plus haute (légale) |
| **B** | Académique/université (cours identifiés) | Pédagogique |
| **C** | Technique secondaire (GenieCivilPDF, livres, problèmes résolus) | Référence |
| **D** | Non-autoritatif (blog, forum, généré IA) | Exploration seulement |

**Règle : le niveau D ne surpasse JAMAIS le niveau A/B/C.** Si un exemple C
contredit une norme A, c'est la norme qui l'emporte — Ascent **signale le
conflit**. Provenance (AD-11) sur chaque étape Ascent. [overview §16]

## 12. Events consommés (pas d'event AD-9 émis)

`ProgressEvidenceCreated` (déclencheur d'adaptation) · `SkillStateChanged` (mise à
jour du baseline) · `DiscoveryItemCreated` (nouveau gap → nouvelle étape ?) ·
`GoalUpdated` (objectif changé → recomposition) · `TaskCompleted` (certaine
activité d'exercice faite → check des critères de passage) · `ArtifactGenerated`
(fiche d'étude prête → phase READ complète). Ascent **produit**
`AscentAdaptation` (son log, pas un AD-9). Le Agent Kernel (Context Builder)
lit les données d'Ascent pour planifier la prochaine session. [overview §17]

## 13. Persistance (tables Ascent)

`ascent_paths` (les données du LearningPath) · `ascent_steps` · `ascent_adaptations`
(log append-only) · `ascent_baselines` (snapshot du baseline à la création).
**Règle : tables SERVER-ONLY (comme expert_skills, AD-3).** Le device lit le chemin
actuel via PowerSync mirror (lecture seule) ; les adaptations sont calculées
côté serveur (AD-12). **Règle 80/20 : le minimum viable Ascent = 1 table
(`ascent_paths` avec les steps en JSONB) + le log d'adaptation ; le split 4
tables est pour la perf de requête, pas l'architecture — démarrer à 1 table si
besoin.** [overview §9, §20 ; implementation "Data"]

## 14. Intégrations (contrats)

**Consomme (pas de nouveaux ports) :** KnowledgeBase · ProgressEvidence (vue
publique) · DiscoveryService (vue publique) · ObjectiveManager (vue publique) ·
FeatureRegistry (si Learning est off, le chemin se dégrade). **Produit :**
`AscentLearningIR` (→ Agent Kernel Context Builder), `AscentAdaptation`
(→ Progress / Agent replan), `LearningPathCommand` (→ Learning, domain command
AD-7 via use-case). [overview §7]

## 15. Dérogations / NON COUVERT (convention pont)

- **Module PROPOSED, pas gelé** — pas de numéro ADR/AD ; les décisions d'arbitrage
  ne sont pas dans l'ADR v1.7 gelé. **NON COUVERT** par le corpus gelé tant que
  Ascent n'a pas été arbitré (standup wave-3) — à déclarer, PAS à inventer.
- **`AscentLearningIR` n'existe PAS encore dans `packages/domain`** (additif,
  §20/§6.1 de l'overview : « PROPOSED: this type does not yet exist »).
- **WDS : Slide-Ascent n'est pas dans le scope-report (S-01…S-40)** — c'est une
  **surface UI nouvelle** à indexer dans WDS Phase 4 (proche du S-22 mirror-cognitive
  et du S-25 `/learn`, mais distincte). **NON COUVERT** par le scope-report actuel.
- **Ascent = capacité du kernel (AD-12), pas un agent séparé** — pas de S-Sophie
  agent dans la matrice agentability ; à rattachement à l'Agent Kernel.
- **V1 = 1 objectif actif à la fois** ; multi-path, apprentissage par renforcement,
  comparaison par les pairs, Ascent desktop, co-optimisation Ascent+FSRS → **V1.1/V2
  (dérogations déclarées, §21 de l'overview).**
- **Pointeur d'intégration ambigu (plan de vagues) : `prompts/session-4-wave3-
  agent-integration.md` §SOUS-AGENT 5 (l.130-185) — SOPHIA ajoutée post-hoc**
  : l'en-tête du prompt annonce « 4 sous-agents en parallèle » et la section
  « Quand les 4 sont finis » ne mentionne pas le 5ᵉ (SOPHIA/Ascent). La
  cohérence interne du plan de vagues est **NON COUVERT** — à trancher au
  standup wave-3, non à résoudre ici.
- **Conflit interne corpus d'implémentation — « 4 tables » vs « 1 table
  JSONB »** : `implementation.md` porte à la fois « 4 tables, server-only »
  (L64 titre + L108 « 1 function, 4 tables ») **et** « 1 table :
  `ascent_paths` (steps en JSONB) » (Step 1 L15-16) ; le prompt SOPHIA
  (L152/L173) tranche **80/20 = 1 table**. L'autorité revient à
  `overview.md` §20 : le split 4 tables est un **choix de performance de
  requête**, l'architecture minimale = **1 table** ; la phrase L108 « 1
  function, 4 tables » est résiduelle, à corriger au standup wave-3.
  **NON COUVERT** — WDS ne duplique pas les deux comptes.

## 17. Entrée dans WDS Phase 4 (recommandation, non prescriptive)

> **Nature :** le mode d'entrée WDS est une **décision WDS Phase 4**, PAS une
> décision du corpus Ascent (PROPOSED, non gelé). Ce que la distillation
> propose ci-dessous doit être tranché/ratifié en Phase 4, non déduit du
> corpus.

### 17.1 — Surface proposée

Nouvelle surface **S-41 `slide-ascent`** — format de présentation dédié du
`LearningPath` (renderer de `AscentLearningIR`), **distincte** de :
- **S-22 mirror-cognitive** (analyse d'une explication de Horeb par le
  kernel), et
- **S-25 `/learn`** (flow cours → chapitres → fiches/QCM/flashcards/miroir).

S-41 n'est ni l'une ni l'autre : c'est la **vue progressive disclosure**
(4 niveaux, §7) qui rend le chemin d'apprentissage adaptatif d'Ascent.

### 17.2 — Mapping de réutilisation (zéro duplication des surfaces existantes)

| Éléments d'Ascent (overview §11-14) | Surface existante réutilisée |
|---|---|
| Drill d'un concept/formule (`conceptRefs`) | **S-26** `/knowledge/:nodeId` (arbre sémantique, provenance AD-11, « study ») |
| Actions Active Reading « Explain » / « Je bloque » | **S-22** `mirror-cognitive` (kernel analyze) |
| Activités déléguées `learningCommand` (`generate_qcm`, flashcards, exercices) | **S-19** `flashcards` · **S-20** `qcm` · **S-38** `exercises` via **S-25** `/learn` |
| Level 4 « historique de progression de cette compétence » | **S-13** `analytics` (dashboard Progress ADR §18.6) |

**S-41 orchestre ces surfaces existantes ; elle ne les recrée pas** — c'est
la règle « pont » appliquée à la réutilisation du scope-report. S-41 est
**NON COUVERT** par le scope-report S-01…S-40 et doit être **indexé en
Phase 4**.

### 17.3 — Scénario associé (à trancher en Phase 4)

Deux options non prescriptives, à ratifier :
1. **Nouveau scénario 07** « Horeb's Trajet d'apprentissage » (P2, chaîne 07)
   qui couvre S-41 de bout en bout (objectif → `LearningPath` → slides →
   Active Reading → adaptation), distinct des 6 scénarios actuels ; OU
2. **Sous-scénario de 01 (Progress Proof) ou 02 (Gap Closure)** — Ascent est
   le moteur adaptatif qui produit la preuve ou réduit l'écart ; on y
   glisse S-41 comme étape du chemin existant sans créer un 7ᵉ scénario.

La préférence est **l'option 1 (scénario 07)** car Ascent a un but propre
(trajet adaptatif) et une surface dédiée (S-41) qui ne s'intègre pas
naturellement dans le chemin linear Q8 d'un scénario existant.

### 17.4 — Dépendances à trancher (NON COUVERT, standup wave-3)

- **Rattachement FeatureRegistry** : Ascent est-il une feature enfant de
  Learning, ou une feature `ascent` autonome ? (le corpus n'est pas gelé)
- **Les 8 effets de désactivation** : deep-link vers une feature désactivée
  = état `feature disabled` (EXPERIENCE.md §Feature Registry) — Ascent doit
  dégrader le chemin (`Learning` off → le chemin se dégrade, §14), pas
  cacher. À spécifier pour S-41 en Phase 4.
- **Troncature V1 = 1 objectif actif** (§21 overview) : S-41 affiche un seul
  `LearningPath` actif à la fois ; multi-path reporté V1.1.

## 16. Pointeurs (anti-recopie)

- `docs/ascent/overview.md` — SSoT conceptuel (22 sections)
- `docs/ascent/implementation.md` — guide d'implémentation wave 3+ (domain types,
  module serveur, Slide-Ascent UI, kernel integration, data, tests)
- `prompts/session-4-wave3-agent-integration.md` §SOUS-AGENT 5 SOPHIA — plan de
  commits « wave3/sophia » + règles serveur / 80-20
- Cross-refs : `docs/architecture/dynamic-goal-engine.md` (GoalProject, Ascent =
  couche au-dessus) · `docs/agent/kernel.md` S12 (Ascent = capacité du kernel) ·
  `docs/progress/overview.md` (SkillState, ProgressEvidence) · `docs/learning/
  overview.md` (QCM, flashcards, mirror) · `docs/knowledge/overview.md` (tree,
  concepts, formules)
