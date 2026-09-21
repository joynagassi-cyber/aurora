---
name: "Adversarial Review — Aurora Architecture Spine"
type: review
reviewer: adversary (architecture subagent)
target: ARCHITECTURE-SPINE.md (draft, 2026-09-21)
sources:
  - Aurora_Architecture_Decisions_v1_7_final.docx (v1.7 frozen)
  - .memlog.md
altitude: initiative
created: 2026-09-21
status: findings-open
---

# Revue adversariale du spine Aurora

Méthode demandée par le team-lead : construire mentalement **deux unités du niveau en dessous**
(feature/agent teams travaillant en parallèle) qui **obéissent à la lettre à toutes les ADs du spine**
et produisent quand même des incompatibilités. Chaque paire trouvée est un trou à combler — soit une
nouvelle AD, soit une AD existante resserée. Le reviewer a reléu le doc source v1.7 (sections 7–26)
pour vérifier ce que le spine a sous-protégé ou sous-dit.

Cotations : `spine:AD-x` = ARCHITECTURE-SPINE.md ; `doc §n` = Aurora_Architecture_Decisions_v1_7_final.docx.

## Verdict

Le spine est un excellent socle de non-contradiction (14 ADs cohérentes, conventions solides), mais il est
**silencieux là où deux équipes parallèles se touchent** : il ne dit jamais **qui possède une shape, qui
écrit un état, qui consomme un événement, ni quel package héberge quoi**. Deux feature teams travaillant
en parallèle, fidèles à toutes les ADs du spine, peuvent produire des `Task`, des `SemanticNode`, des
`ProgressEvidence` et des `Job` **mutuellement incompatibles** — exactement les collisions que les ADs
prétendent prévenir. Ce sont des trous de contrat, pas des contradictions d'AD.

## Findings

### AD-x (nouvelle) — F-01 · [Critical] Shapes partagées sans propriétaire de type
**Trou : qui définit `Task`, `Artifact`, `ProgressEvidence`, `SemanticNode`, `SkillState`, `Goal` ?**
Le spine nomme un *vocabulaire* d'entités (Consistency Conventions, § Naming) et le fige comme "frozen
initial domain", mais **n'attribue aucune shape à aucun module/package**. La matrice "Capability →
Architecture Map" dit *où vit la capability*, pas *qui possède le type*. Le package `packages/domain`
existe dans le Structural Seed mais n'est lié à aucune AD — deux équipes peuvent chacune créer son propre
`domain` package avec sa propre `Task`.

**Paire d'unités incompatible (obéissant à la lettre du spine) :**
- *Unité A* = `feat/productivity` (Productivity team). Obéit à AD-2 (module boundary) et AD-13 (Contract
  Pack) : son Contract Pack définit `Task` avec les champs qu'il croit nécessaires (statuts, priorités,
  dépendances, récurrence, temps réel — cf. doc §2.2) et les expose comme `Task` de `packages/domain`.
- *Unité B* = `feat/agent-kernel` (Agent team). Obéit à AD-12 (Context Builder consomme du "Productivity
  Context") et à AD-1/AD-4 : pour que le Context Builder du Kernel lise l'état Productivity, B définit **sa
  propre** lecture de `Task` (shape projetée, `TaskContext`) dans `packages/agent`.
- *Résultat* : A pense qu'il possède `Task` ; B pense qu'il possède sa projection. Personne n'a défini
  **le contrat `Task` partagé**. A publie `Task { id, status, dueAt, ... }` ; B publie
  `TaskContext { id, state, ... }`. Les deux sont conformes à AD-1/AD-2/AD-13 **l'un comme l'autre**, car
  le spine ne dit pas que `Task` doit vivre dans un **package partagé unique** (`packages/domain`) et que
  chaque équipe consomme plutôt qu'elle ne recrée le type. Collision au merge, en vague 2 → 3.

**Correction proposée :** nouvelle AD « **Single Source of Truth des types de domaine** » : chaque entité
frozen (Task, Goal, Milestone, Habit, Routine, Note, Resource, Course, Subject, Skill, LearningSession,
Review, FocusSession, Artifact, Automation, Decision, UserContext, **et** ProgressSnapshot/Evidence/
SkillState/Trend/Event/TrajectoryScenario, SemanticNode/Edge/Bridge/State, SourceRef, EvidenceRef,
DiscoveryItem, Gap, ExpertSkill) possède **un unique propriétaire de package** (table de mapping
entité→package→équipe), hébergé dans `packages/domain`. Toute projection (Context Builder du Kernel,
dashboards Progress) doit être une *vue* déclarée du type partagé, jamais une ré-définition. À resserer
dans AD-2 (boundary) et AD-13 (Contract Pack doit lister les types *consommés*, pas seulement produits).

### F-02 · [Critical] L'entité `SemanticNode` / Semantic Tree a **deux prétendants à la ownership**
**Trou : est-ce que le Semantic Tree est possédé par `Knowledge` ou par `Agent` ?**
- AD-6 (spine) : « The Semantic Tree is the knowledge hierarchy — its truth lives in the **Knowledge
  Base**, never in the rendering engine. » → ownership = **Knowledge**.
- AD-10 (spine) : le `SemanticTreeRenderer` est lié à « **Knowledge UI, Agent, Design System** » (trois
  bind targets).
- doc §25.3 : `SemanticNode` porte un `EvidenceRef` = « preuve de compréhension/application **provenant de
  Progress** ».

**Paire d'unités incompatible :**
- *Unité C* = `feat/knowledge` (Knowledge team). Obéit à AD-6 : il détient la vérité du Semantic Tree et
  définit `SemanticNode { concept, domain, state, ... }` + `SemanticEdge` + `SemanticBridge` + `NodeState`
  (collapsed/expanded/mastered/fragile/forgotten — cf. doc §25.3).
- *Unité D* = `feat/progress` (Progress team). Obéit à doc §18.8 (Modèle de données conceptuel) et à
  doc §25.3 (`EvidenceRef` "provenant de Progress") : il veut **écrire** sur `NodeState` (= maîtrisé/
  fragile/oublié) à chaque `ProgressEvidenceCreated`, car c'est le système de mesure qui alimente
  « branches fragiles/consolidées » (doc §14). D définit sa propre mutation de `NodeState` via
  `packages/data`.
- *Collision* : Knowledge (C) et Progress (D) **mutent le même `NodeState`** du Semantic Tree, dans deux
  packages différents, sans contrat explicite de qui écrit et comment (voir F-03). AD-6 dit "truth in
  Knowledge Base" mais ne dit pas si `NodeState` (un *état*, pas une vérité de contenu) est muté par
  Progress. AD-9 énumère `ProgressEvidenceCreated` et `SkillStateChanged` sans dire que leur consumer
  écrit sur `SemanticNode.state`. Deux équipes, conformes, écrivent le même champ.

**Correction :** clarifier dans AD-6/AD-10 : **Knowledge** possède `SemanticNode` (structure + contenu) ;
**Progress** possède `SkillState` (compétence) et **émet** `ProgressEvidenceCreated`/`SkillStateChanged` ;
une **projection unique du module Knowledge** (owner du `SemanticNode.state`) est le **seul** writer du
`NodeState` à partir de ces événements (pattern : le consumer de l'événement est un projeté Knowledge, pas
Progress qui écrit directement dans la table Knowledge). Interdire à Progress d'écrire dans `packages/
knowledge` (à fixer dans la matrice de packages, voir F-05).

### F-03 · [High] Chemins de mutation d'état local-first sans contrat de writer
**Trou : deux (ou trois) modules mutent le même état SQLite/PowerSync sans règle de writer unique.**
AD-7 dit « PowerSync + SQLite on device ; the UI reads local state first and syncs to Supabase » — c'est
un **modèle de lecture**, pas un **modèle d'écriture**. Le spine est silencieux sur :
- qui est le **writer autorisé** d'une entité locale (Productivity écrit `Task`, mais le Kernel du
  Agent, via « Action », complète-t-il la tâche en écrivant directement dans SQLite, ou via commande
  Productivity ?),
- la **sémantique de résolution de conflit** de PowerSync (LWW ? CRDT ? serveur-gagne-toujours ?),
- le **scope PowerSync** : PowerSync exige des *views SQL* (scopes) côté serveur (Supabase). Qui possède
  ces scopes ? AD-7 ne le dit pas ; ils vivent dans `packages/data` (matrice doc §21.2) mais deux équipes
  (Productivity, Learning) définissent des vues qui **jointent les tables de l'autre** (ex. vue
  `focus_sessions` qui compte les tâches terminées).

**Paire d'unités incompatible :**
- *Unité A* (Productivity, `feat/productivity`) : possède la mutation des tâches et définit le PowerSync
  scope `productivity_sync` qui joint `tasks` et `projects`.
- *Unité E* (Agent, `feat/agent-kernel`) : le loop du Kernel `→ Action →` doit **marquer une tâche
  comme faite** au moment où l'agent exécute une action. E obéit à AD-1/AD-2/AD-12 et écrit une
  mutation `TaskCompleted` **directement** (car « Action ») dans le store local, **pas** via commande
  Productivity.
- *Résultat* : deux chemins de mutation du `Task.status` local (commande Productivity d'un côté, Action du
  Kernel de l'autre). Lors du re-sync, PowerSync arbitre selon la règle de conflit non définie ; un côté
  écrase l'autre. Aucun des deux n'enfreint une AD (le spine n'en a pas une) ; la collision est **latente
  par omission**.

**Correction :** resserer AD-7 avec une sous-règle « **Single Writer par entité locale** » : chaque entité
`packages/data` a un module owner qui est le **seul** à muter ; le Kernel (Action) ne mutate **jamais**
directement une table/entité — il émet un **événement/commande** que le module owner applique (voir F-04,
`TaskCompleted` devrait être consumé par Productivity, pas par le Kernel qui écrit lui-même). Plus :
AD-7 doit fixer (a) la règle de résolution de conflit PowerSync (recommandé : *server-wins + horodatage
*par entité*, ou CRDT pour les listes), (b) qui possède les scopes/views SQL PowerSync (`packages/data`,
wave 0), et (c) l'interdiction pour un scope de jointer les tables internes d'un autre module (cohérent
avec AD-2).

### F-04 · [Critical] Événements « ciblés » mais **consommateur non-nommé** : AD-9 est insuffisante
**Trou : la liste d'événements (AD-9) liste les *producteurs* mais jamais les *consommateurs* — donc
deux modules divergent sur qui réagit à quoi.**
Le test demandé : « `DiscoveryItemCreated` déclenche quoi ? `SkillStateChanged` est consommé par qui ? »
Le spine **ne répond pas**. doc §15 (boucle Discovery→Learning→Practice→Progress→Self-Improvement) et
doc §18.7 (Progress comme moteur agentique) décrivent les découplages réels, mais AD-9 du spine ne les
figure pas :

| Événement (AD-9) | Producer (déductible) | **Consumer attendu (MANQUANT)** | Récupéré depuis doc |
|---|---|---|---|
| `TaskCompleted` | Productivity | **Progress** (evidence), **Learning** (révision), **Agent** (re-plan) | §18.7, §15 |
| `CourseImported` | Learning | **Knowledge** (arbre), **Discovery** (gap), **Progress** | §14, §18 |
| `FlashcardReviewed` | Learning (FSRS) | **Progress** (SkillState/fraîcheur) | §18.2 |
| `ProgressEvidenceCreated` | Progress | **Knowledge** (NodeState), **Agent** (Context) | §25.3 |
| `SkillStateChanged` | **Progress** | **Agent** (Expert Skills), **Discovery** (profil de compétences), **Learning** (révision ciblée) | §14.2, §13.1 |
| `GoalUpdated` | Productivity | **Progress** (trajectoire), **Agent** | §18.5 |
| `ArtifactGenerated` | Artifact | **Knowledge** (SourceRef), **Learning** (preuve) | §16, §17 |
| `JobCompleted` | Job System | **Artifact** (fichier disponible), **UI** (état success) | §8 |
| `DiscoveryItemCreated` | Discovery | **Learning** (crée activité), **Knowledge** (liens arbre), **Progress** (mesure), **Agent** (prochaines recommandations) | §13.8, §13.9, §15 |

- `DiscoveryItemCreated` → doc §13.9 (boucle de découverte) : « Créer éventuellement une activité
  d'apprentissage ou un projet. Mesurer ce qui a été compris, appliqué ou ignoré. Utiliser le résultat
  pour améliorer les prochaines recommandations. » → **au moins 4 consommateurs** (Learning, Knowledge,
  Progress, Agent). Le spine n'en nomme aucun.
- `SkillStateChanged` → doc §14.2/§13.1 : consommé par l'Agent (contexte Expert Skills + profil de
  découverte dynamique = « compétences maîtrisées, fragiles, manquantes »). Le spine n'en nomme aucun.

**Paire d'unités incompatible :**
- *Unité D* (Progress) et *Unité F* (Discovery, `feat/discovery`). D définit `SkillStateChanged` avec un
  payload `{ skillId, newState, freshness, confidence }` (doc §18.3). F, pour son "Profil de découverte
  dynamique" (doc §13.1 « compétences maîtrisées, fragiles et manquantes »), **ne s'abonne pas** à
  `SkillStateChanged` (le spine ne l'y oblige pas) et **recrée** une table locale `discovery_skill_
  snapshot` avec sa propre forme `{ skill, level, ... }`. Deux sources de vérité du niveau de compétence :
  `SkillState` (Progress) et `discovery_skill_snapshot` (Discovery). Conformes aux ADs, incompatibles entre
  elles.

**Correction :** resserer AD-9 pour **chaque** événement figé lister (1) le **producer unique**, (2) la
liste **exhaustive des consumers autorisés**, (3) le **payload minimal** (contrat TS). Ajouter une
convention « **Consommateur déclaré** » dans les Contract Packs (AD-13) : un module qui consomme un
événement doit le déclarer dans son pack ; un module qui ne le déclare pas **n'a pas le droit** de le
consommer (et donc de le re-persister). Recommandation : passer la liste d'événements en **appendix
normatif** du spine avec la matrice producer/consumer/payload ci-dessus.

### F-05 · [High] La « fossée de l'enveloppe opérationnelle » — déploiement, environnements, provider
Le spine **assumed** l'enveloppe Supabase + Cloudflare mais ne la **spécifie** pas, et l'a placée en
Deferred (wave 0). C'est le trou le plus structurel pour l'altitude *initiative*, car le spine prétend
« bind: all » et être la référence pour **toutes** les équipes parallèles. Concret :

1. **Environnements (dev/staging/prod)** : Deferred du spine. Mais AD-5 (Model Registry) et le free-tier
   registry (doc §8, 10+ providers avec quotas différents) exigent des **clés, buckets R2 et registres de
   modèles par environnement**. Deux équipes de features (Productivity et Agent), travaillant en parallèle
   sur `main` buildable, ne savent pas **dans quel environnement** elles déploient leurs Edge Functions /
   Workers / buckets R2, ni qui possède les clés CI/CD (GitHub Actions + Cloudflare + Supabase + OneSignal +
   Sentry + PostHog = **6 fournisseurs d'infra distincts** sans owner). Le spine n'a pas de «
   AD-15 : Enveloppe opérationnelle ».
2. **Strategy infra/provider** : le spine fige *quel* fournisseur (Supabase, CF R2, AI Gateway) mais ne
   fige pas la **politique de compte/quota/ownership** (qui tient le compte CF, qui tient Supabase, qui
   provisionne les environments). AD-4/AD-5 disent « Model Registry peut auto-retirer un provider » — mais
   **qui** possède et administre ce Model Registry ? C'est un état partagé de classe `packages/data` ou
   d'une table Supabase ? Deux équipes peuvent chacune créer son registre de modèles.
3. **Operations** : AD-8 (jobs persistés/observables) et Sentry+PostHog (Stack) ne disent pas **qui est le
   duty owner opérationnel**, qui alerte sur les jobs échoués, ni quel SLO par job.

**Paire d'unités incompatible :**
- *Unité G* (Foundation, `feat/foundation-setup`) : possède le Model Registry et les clés CI/CD.
- *Unité H* (Design System / UI, `feat/design-system`) : a besoin d'un bucket R2 **staging** pour les
  assets (palettes, exports SVG/PNG des infographies, doc §25.4) et d'un environnement de preview. H obéit à
  AD-13 mais **ne sait pas quel environnement/bucket consommer** car l'enveloppe opérationnelle est
  Deferred. G et H créent chacun leurs own buckets R2 (un par équipe), divergents.

**Correction :** ajouter **AD-15 (nouvelle) — Enveloppe opérationnelle figée à l'altitude initiative** :
(a) les 3+1 environnements (dev, staging, prod, [per-provider CI]), (b) l'owner unique du **Model
Registry** (recommandé : `packages/data` + une table Supabase, une seule source), (c) l'owner des clés
CI/CD et des comptes fournisseurs (Foundation), (d) l'owner du Model Registry + qui peut auto-retirer un
provider (gating AD-5 à un owner unique), (e) le duty owner opérationnel et SLO par job (AD-8). Le spine
devrait **ne pas Deferred** l'enveloppe opérationnelle à l'altitude initiative — c'est précisément le
niveau qui doit la figer ; le Deferred peut rester pour les *valeurs* des environnements (quelles régions,
quels noms de buckets) mais **la structure doit exister dans le spine**.

### F-06 · [Medium] Deux owners du même `Artifact` / Artifact Hub (Artifact vs Agent vs UI)
AD-10 lie le `SemanticTreeRenderer`/renderers à « Knowledge UI, **Agent**, Design System ». L'`Artifact`
frozen (doc §16, §15) est produit par (a) **Agent** (génération, « Artifact Hub : fichiers générés par
Aurora, métadonnées sur source/tâche/contexte de génération », doc §16), (b) **Artifact module**
(visualisation), (c) **Design System** (renderer). `ArtifactGenerated` (AD-9) : qui est le producer —
Artifact, ou Agent (qui génère) ? doc §15/§16 : l'agent **génère** l'artefact, le module **le
visualise**. Le spine ne tranche pas qui *émets* `ArtifactGenerated`. Paire : *Unité I* (Artifact
module, émet l'événement après upload R2) vs *Unité E* (Agent, émet l'événement après génération
IA avant upload). Deux `ArtifactGenerated`, deux timestamps, deux métadonnées (l'un avec R2 key,
l'autre sans). Correction : AD-9 fige `ArtifactGenerated` comme émis **par le module Artifact**
post-upload-R2-uniquement ; le Kernel ne produit **que** la demande, pas l'événement.

### F-07 · [Medium] `ProgressEvidence` : owned par Progress ou par Learning ?
doc §18.3 « La donnée de progression doit conserver au minimum : compétence ou objectif concerné,
niveau observé, **preuve**, date, fraîcheur, contexte et confiance. » La *preuve* (QCM, rappel actif,
exercice, projet…) **est produite par Learning** (revue flashcard, exercice, §17) mais **est stockée
et qualifiée par Progress** (`ProgressEvidence` doc §18.8). Paire : *Unité J* (Learning, `feat/
learning`) définit `FlashcardReviewed`/`ReviewCompleted` et veut **émettre** `ProgressEvidenceCreated`
(puisque c'est lui qui a la preuve). *Unité D* (Progress) dit que **lui** émet `ProgressEvidenceCreated`
(puisque c'est son entité). Conformes aux ADs ; incompatible sur l'**emission**. Correction : AD-9
fige : les événements *produits* par Learning/Progress (FlashcardReviewed, ReviewCompleted) ;
`ProgressEvidenceCreated` est émis **par Progress** (qui agrège/qualifie) à partir de ces
événements Learning. Learning ne crée **jamais** de `ProgressEvidence` directement (AD-2 : pas
d'écriture dans la table Progress).

### F-08 · [Low/Medium] `JobCompleted` et l'absence d'`ArtifactGenerated`/`TaskUpdated` — couverture
Le spine écarte « Event Sourcing complet » (AD-6) mais garde `JobCompleted` (AD-9). Incohérence
minime : le job system (AD-8) émet `JobCompleted` pour **tout** job persisté ; mais deux jobs « lourds »
qui finissent au même instant (OCR + transcription du même cours, doc § v1.5 pipeline audio) émettent
deux `JobCompleted` avec un payload qui **ne dit pas quel** job (payload manquant — renvoi F-04).
Deux équipes (Artifact = OCR job, Learning = transcription job) consommeront `JobCompleted` l'une
pour l'autre. Correction : `JobCompleted` doit porter `jobId` + `jobKind` dans le payload (voir F-04).

### F-09 · [Low] `packages/domain` et `packages/agent` : l'AD-12 « One Kernel » vs l'AD-8 « Job
asynchrone » — qui possède le contexte du Kernel côté serveur ?
AD-12 bind « Agent module ». AD-8 bind « all features using OCR, transcription, artifact generation,
search, scientific compute ». Si un **Job asynchrone** (Edge Function) doit appeler l'Agent Kernel
(« vérification KB/source et/ou Scientific Engine », doc §v1.7-5, CRITIQUE tasks), le Kernel tourne-t-il
**sur l'appareil** (Ionic) ou **côté serveur** (Edge Function) ? Le spine ne tranche pas. Paire :
*Unité E* (Agent, `packages/agent`, exécute le Kernel **côté client** mobile) vs *Unité K* (Scientific
engine, `packages/scientific-engine`, doit exécuter une **vérification déterministe** dans un **Job
asynchrone côté serveur** car mobile = offline). Le spine laisse la porte ouverte à un **Kernel côté
client** (mobile, offline-first AD-7) **et** un **Kernel/verify côté serveur** (AD-8 jobs). Deux
implémentations du même « Verify » step. Correction : AD-12/AD-8 figent **où** le Kernel/verify tourne —
recommandation : le **Context Builder / Planning / Router / AI** tournent **côté serveur** (jobs +
gateway, pas de clé sur l'appareil par AD-3) ; seul l'état UI/lecture tourne côté client.

### F-10 · [Low] `Semantic Tree` « evolution temporelle » (doc §14) vs Event Sourcing exclu (AD-6)
doc §14 : « Evolution temporelle : Aurora conserve l'évolution de l'arbre afin de visualiser comment le
savoir s'est approfondi ». AD-6 exclut « full Event Sourcing » mais **conserve** « Event History ».
Ambiguïté : qui écrit l'**historique des versions du Semantic Tree** ? Knowledge (owner du Tree) doit
**re-persister** chaque mutation comme `ProgressEvent`/`SemanticTreeVersion` — mais le spine ne fige pas
cette table de versioning. Paire : *Unité C* (Knowledge) versionne l'arbre dans ses tables internes ;
*Unité L* (Progress, qui a l'`Event History`) versionne le même. Deux historiques. Correction :
figer que le **versioning du Semantic Tree est une table de Knowledge** (owner du Tree, AD-6), **pas**
l'Event History de Progress (celui-ci ne stocke que les événements *progression/audit*, pas les *
versions de contenu*).

## Tableau de synthèse des corrections (nouveaux ADs / resserrements)

| # | Trou | Correction | Statut |
|---|---|---|---|
| F-01 | Shapes partagées sans owner | **Nouvelle AD « Single Source of Truth des types de domaine »** + mapping entité→package→équipe | Nouvel AD |
| F-02 | SemanticNode : Knowledge vs Progress | Resserre AD-6/AD-10 : Knowledge = owner structure+NodeState ; Progress émet seulement | AD resserée |
| F-03 | Mutation local-first multi-writer | Resserre AD-7 : Single Writer par entité + règle de conflit PowerSync + owner des scopes | AD resserée |
| F-04 | Événements sans consumer nommé | Resserre AD-9 : matrice producer/consumer/payload exhaustive + « Consommateur déclaré » dans Contract Pack | AD resserée |
| F-05 | Enveloppe opérationnelle manquante | **Nouvelle AD-15** (env, owner Model Registry, owner CI/CD, duty owner, SLO par job) | Nouvel AD |
| F-06 | ArtifactGenerated double-émis | Resserre AD-9 : `ArtifactGenerated` émis par Artifact post-upload uniquement | AD resserée |
| F-07 | ProgressEvidence émis par qui | Resserre AD-9 : émis par Progress ; Learning n'écrivant pas dans la table Progress | AD resserée |
| F-08 | JobCompleted payload opaque | Resserre AD-9/AD-8 : payload `jobId`+`jobKind` obligatoire | AD resserée |
| F-09 | Kernel client vs serveur | Resserre AD-12/AD-8/AD-3 : Context/Plan/Router/AI côté serveur ; état UI côté client | AD resserée |
| F-10 | Versioning Tree double | Resserre AD-6 : versioning du Tree = table de Knowledge, pas l'Event History de Progress | AD resserée |

## Priorisation pour le team-lead
1. **F-01 + F-04** (nouvelle AD de SSoT des types + matrice events producer/consumer) — sans ces deux,
   **toute** vague de parallélisme produit des collisions ; ce sont les pires trous.
2. **F-03** (Single Writer local-first + règle de conflit PowerSync) — blocant pour toute mutation
   multi-module offline.
3. **F-05** (enveloppe opérationnelle) — l'altitude initiative doit la figer ; ce n'est pas un détail
   Deferred.
4. **F-02, F-06, F-07** — clarifications d'ownership d'entités spécifiques (Knowledge/Progress/Artifact).
5. **F-08, F-09, F-10** — précision de contrat (payload, placement client/serveur, versioning).

## Ce que le spine fait bien (pour l'équité de la revue)
- AD-1/AD-2/AD-13 forment un triangle correct (isolation vendor, boundary module, Contract Packs) —
  c'est la base qui *permet* aux findings de n'être que des **manquements** plutôt que des **contradictions**.
- AD-12 (One Kernel) et AD-4/AD-5 (AI multi-provider, fallback/hygiène de quota) sont bien spécifiées.
- Les conventions de merge/PR/branch et le Deferred honnête (RLS, env) sont sains.
- Le vocabulaire d'entités frozen (Consistency Conventions) existe déjà — il n'a besoin que d'un **owner
  par entité** (F-01) pour devenir opérationnel.

## Signatures
Reviewer : architecture-adversary (subagent), 2026-09-21. Revue exécutée sans accès au code (spine seul).
Aucun fichier du projet légué n'a été modifié ; seule cette revue est produite.
