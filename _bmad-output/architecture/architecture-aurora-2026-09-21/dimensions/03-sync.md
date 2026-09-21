---
name: "Aurora — Dimension Synchronisation (PowerSync + SQLite + Supabase, pack de contrat, vague 0)"
type: dimension-pack
altitude: initiative
companion-of: ARCHITECTURE-SPINE.md (autorité, read-only)
sources:
  - ARCHITECTURE-SPINE.md (AD-1…AD-16, statut final, 2026-09-21)
  - adr-extract.md (ADR v1.7 gelé)
  - reviews/review-adversary.md (trous F-01…F-10 comblés dans le spine)
status: wave-0-draft
created: 2026-09-21
owner: équipe Data (owner de packages/data, AD-13 §21.2)
binds: "packages/data (store SQLite, repositories, scopes serveur), apps/mobile (consommation en lecture), Supabase (vues + RLS + PowerSync triggers)"
consumes: ["01-backend.md (RLS, jobs, événements serveur)", "02-frontend.md (state UI, use-cases, états UX)"]
adRefs: [AD-1, AD-2, AD-3, AD-6, AD-7, AD-8, AD-9, AD-13, AD-15, AD-16, F-01, F-03, F-04, F-07]
---

# 03 — Dimension SYNCHRONISATION (PowerSync + SQLite + Supabase)

> Ce pack est **prescriptif** pour les agents de développement : il référence le spine (AD-x) sans le
> répéter, et l'approfondit là où le spine reste volontairement silencieux (spine § Deferred : RLS,
> mapping AD-15). Les AD-x citées sont contraignantes et read-only. Le contenu est en français ; les
> identifiants de code (noms de packages, interfaces, tables, événements, fonctions) sont en anglais.
> Ce pack définit **la sémantique de synchro** que `02-frontend` consomme (ses sections 3.2, 4, 7, R2, R7)
> et que `01-backend` consomme pour les vues/RLS serveur (sa section 3.4). Les deux packs se référencent
> mutuellement ; aucune décision n'est dupliquée.

---

## 1. Périmètre et objectifs

**Périmètre du pack** : la couche local-first complète — ce qui vit **sur l'appareil** (SQLite,
reconnaissance locale) et le **pont** vers le serveur Supabase (vues PowerSync, triggers, RLS,
règles de conflit) :

- **Store local** (`packages/data` : SQLite) = la source de vérité **pour la UI** (AD-7 : « the UI reads
  local state first and syncs to Supabase »). PostgreSQL reste la source transactionnelle **globale**
  (AD-6) — les deux sont complémentaires, pas concurrents : SQLite est le *cache autoritaire de
  l'écran*, Supabase est le *registre durable*.
- **Réseau de sync** : PowerSync relay (côté serveur, composant Supabase) + vues SQL des scopes (owner
  `packages/data`, AD-7, provisionnées en vague 0) + `sqlite` local + moteur d'écriture local-first
  (mutations appliquées immédiatement en local, remontées au serveur, résolution serveur = autorité).
- **Règles de résolution de conflit** (AD-7) : **server-wins + horodatage serveur par entité**
  (`updated_at` serveur = canon), **CRDT** pour les listes qui doivent merger (recommandation :
  type OR-Set (figé, SSoT `packages/domain`, AD-15) pour les listes de champs optionnels, listes de
  tags, listes de dépendances de tâches (pas LWW-Map : le cas « supprimé/ré-ajouté » convergent
  sans résurrection, §5.3).
- **Single-Writer par entité locale** (AD-7 resserree par F-03) : chaque entité SQLite a **un unique
  module owner qui en est le seul writer** ; le kernel Agent **ne mute jamais directement une table**
  (AD-7, F-03) — il émet la commande/événement, l'owner module applique la mutation (ex. `TaskCompleted`
  → Productivity applique).
- **Interdiction de jointure** (AD-7 + AD-2) : un scope PowerSync **ne joint jamais** les tables
  internes d'un autre module (F-03) — la lecture inter-modules passe par une **vue publique** du module
  source (voir § 3.4 de `01-backend.md`).
- **États d'offline** : offline = **état de première classe**, pas une panne (AD-7) — l'app **fonctionne**
  sans réseau : lecture locale, mutations locales, sync différé ; seules les actions **nécessitant le
  cloud** (jobs IA/recherche, uploads R2 — AD-8, AD-16) sont désactivées avec explicatif (pack
  `02-frontend` § 7, état `offline`).

**Objectifs opérationnels du pack** :
1. Figer le **schema SQLite local** (tables miroir + entités AD-15) et le **contrat de lecture/écriture**
   (UI lit UNIQUEMENT SQLite ; écriture uniquement via le module owner — § 4 ci-dessous).
2. Figer la **mécanique de sync up/down** : ordre, déduplication, re-sync après coupure longue,
   horodatage canonique.
3. Figer la **règle de conflit** (server-wins + per-entity timestamp ; CRDT pour les listes) et son
   **démarche de test** (§ 7).
4. Figer le **split d'ownership** des vues PowerSync (AD-7 : `packages/data` owner, provisionné en
   vague 0) et l'interdiction de jointure inter-modules (AD-2, F-03).
5. Figer l'**intégration Supabase** : RLS (AD-2, `01-backend` § 2.2), triggers PowerSync, service_role
   (AD-16), et le **flux complet offline → re-connect → re-sync** (re-sync, § 5.5).

**Hors périmètre de ce pack** (pointeurs vers les autres packs) :
- Les **vues SQL concrètes** (leurs bodies) et les policies RLS → `01-backend.md` § 3.4 + § 2.2 (ce pack
  en fixe la **règle** (owner, interdiction de jointure, service_role), pas le code SQL).
- L'état UI (Zustand) et les use-cases → `02-frontend.md` § 3–4 (ce pack définit **ce que le store local
  expose** au niveau repository, pas le state UI transitoire).
- Les événements **serveur** (AD-9) et le système de jobs (AD-8) → `01-backend.md` § 3.3 / § 5 ; ce pack
  consomme `JobCompleted` (F-08) pour l'état `success` côté client.
- Le Design System / écrans → dimension design (`05-design-system.md`).

---

## 2. Modules / packages concernés (AD-13, AD-15, AD-16)

| Package / composant | Owner (équipe) | Rôle dans cette dimension |
| --- | --- | --- |
| `packages/data` | **Data team (owner AD-7, vague 0)** | Le **seul** propriétaire du store local (SQLite + PowerSync), des **vues SQL des scopes** (AD-7), des **repositories** (contrat de lecture/écriture, § 4), de la **mécanique de sync** (ordre, déduplication, re-sync, règle de conflit). Uniquement ce module **écrit** dans les stores locaux par module owner (AD-7 single-writer). |
| `packages/domain` (types AD-15) | Data/Feature teams (mapping §21.2) | **SSoT des types** (entités frozen : `Task`, `Goal`, `Milestone`, `Habit`, `Routine`, `Note`, `Resource`, `Course`, `Subject`, `Skill`, `LearningSession`, `Review`, `FocusSession`, `Artifact`, `Automation`, `Decision`, `UserContext` + `ProgressSnapshot/Evidence/SkillState/Trend/Event/TrajectoryScenario`, `SemanticNode/Edge/Bridge/State`, `SourceRef`, `EvidenceRef`, `DiscoveryItem`, `Gap`, `ExpertSkill` — spine AD-15). Le store local **persiste ces types** ; personne ne redéclare une shape (F-01). |
| `apps/mobile` (consommation) | App Shell team (pack `02-frontend`) | Lit **uniquement** les repositories de `packages/data` (AD-7, F-03 : l'UI ne touche **jamais** le SQLite/PowerSync directement, § 4) ; ne **mute jamais** directement une table locale (single-writer, F-03). |
| Supabase (serveur) | Backend team (pack `01-backend` § 2.2) | Hôte des **vues PowerSync** + **RLS** (AD-2, AD-7) + **triggers** (AD-7, PowerSync) + `service_role` (AD-16) ; le **registre durable** (AD-6). |
| PowerSync relay (composant serveur) | Data team (AD-7) + Backend (AD-16, compte) | Composant qui **relais** les mutations local→serveur et pousse les mises à jour serveur→local ; lit les vues via `service_role` (AD-16, AD-7). |

**Règle de dépendance** (AD-1, hexagonal, spine § 4) : `packages/data` **importe** les types de
`packages/domain` (AD-15) et les adapters PowerSync/SQLite ; il **n'importe jamais** un SDK fournisseur
d'un autre module (AD-2) ; le store local est **le seul** point d'accès aux données métier de
`apps/mobile` (AD-7, F-03).

---

## 3. Contrats (interfaces TS publiques + événements prod/consom, AD-9)

### 3.1 Contrats de lecture / écriture (la règle normalement attendue par `02-frontend` § 4)

```ts
// packages/data — contrat de la couche store local (AD-7, F-03)
// L'UI lit UNIQUEMENT via ces repositories ; l'écriture passe par le module owner.

export interface LocalQueryRepository<T extends { id: string }> {
  // LECTURE — uniquement SQLite local ; aucun appel réseau ici (AD-7)
  getById(id: string): Promise<T | undefined>;
  list(filter: LocalFilter<T>): Promise<T[]>;
  watch(filter: LocalFilter<T>, onChange: (rows: T[]) => void): Unsubscribe; // reactive, local-only
}

export interface LocalCommandRepository {
  // ÉCRITURE — route vers le MODULE OWNER de l'entité (AD-7 single-writer, F-03)
  // Le kernel n'appelle jamais directement : il émet une commande/événement (AD-7, F-03, F-09)
  // `cmd` est TOUJOURS un `DomainCommand` (partial intent SSoT en `packages/domain`, AD-15),
  // JAMAIS une entité complète de `packages/domain` (violation du single-writer si un PUT
  // full-entity ; le pack 02 §4 use-cases émet des partials — `completeTask(id)`,
  // `rescheduleTask(id, newDueAt)`). Les commandes par entité sont figées dans `packages/domain`
  // (owner par entité, AD-15) :
  //   TaskUpdateCommand { op:'task.update', id, patch: Partial<Task> }
  //   TaskCreateCommand, TaskDeleteCommand, GoalUpdateCommand, ReviewRatedCommand,
  //   NoteUpdateCommand, FocusSessionStartCommand, … (une union par entité mutable AD-15)
  apply(ownerModule: string, cmd: DomainCommand | DomainCommand[]): Promise<WriteResult>;
}

export type WriteResult =
  | { ok: true; queuedForUpsync: number }        // mutation appliquée localement, en file pour le serveur
  | { ok: false; error: { code: string; message: string } };

// Le store local (SQLite) n'expose JAMAIS de table brute à l'UI (AD-7, F-03) —
// seuls ces contrats (repositories) sont publics.
```

**Règles normatives** :
- **L'UI lit UNIQUEMENT SQLite** (via `LocalQueryRepository`) — aucune lecture réseau synchronisée
  (AD-7 : « the UI reads local state first »). Les appels réseau **n'existent que** dans le fond de la
  sync (powerSync), jamais dans le chemin de rendu de l'UI (pack `02-frontend` § 9).
- **L'écriture passe par le module owner** (via `LocalCommandRepository` + `ownerModule`) : l'UI est
  l'**émetteur de commande** ; le **module owner** (ex. Productivity pour `Task`) est le **writer
  unique** du store local de cette entité (AD-7, F-03). L'app n'est **jamais** un 2ᵉ writer
  (pack `02-frontend` § 4 : « L'app n'est jamais le 3ᵉ writer d'un `Task.status` »).
- **Le kernel Agent** (côté serveur, AD-12/F-09) **ne mute jamais directement une table locale** : il
  émet l'événement/commande (ex. `TaskCompleted`), le module owner (Productivity) **applique** la
  mutation, PowerSync propage à l'appareil, l'UI **reçoit** la nouvelle valeur via le repository
  (pack `02-frontend` § 4, AD-7, F-03, F-09).

### 3.2 Contrats d'états de sync (exposés à l'UI pour les états UX canoniques AD-13)

```ts
// packages/data — état de la couche sync (consommé par apps/mobile pour l'état « offline »,
// pack 02-frontend § 7)
// `conflict` : state ATTEIGNABLE uniquement dans le cas résiduel d'une collision CRDT
// non-mergeable (résiduel, test §7 ; scalar server-wins = silencieuse, JAMAIS surfacée).
// Condition de déclenchement (figée) : deux écritures concurrentes sur une liste CRDT
// produisent un conflit de type (ex. un élément supprimé par un client, ré-ajouté par
// l'autre avec des métadonnées divergentes que le CRDT ne peut pas merger sans perte).
// Dans ce cas : `state = 'conflict'` + alerte utilisateur (contrat §6, pack 02 §7 état
// `error` avec `retryable:false` + explicatif) + la résolution CRDT (merge sans perte, §5.3)
// est re-tentée ; si non résolvable = la file subsiste (pas de perte de mutation locale,
// AD-7/F-03) et l'alerte reste jusqu'à résolution (jamais un écran crashé).
export type SyncState = 'idle' | 'syncing' | 'conflict' | 'degraded';
export interface SyncStatus {
  online: boolean;            // détection réseau (pack 02-frontend § 7, @capacitor/network)
  pendingUpstream: number;    // mutations locales en attente de remontée serveur
  lastSyncAt: Date | null;
  state: SyncState;
}
// L'UI **n'agit jamais** sur SyncStatus — elle **surfe** (lecture seule) pour décider de l'état
// « offline » (pack 02-frontend § 7, R7 : offline = état premier, pas un failure mode, AD-7).
```

### 3.3 Événements produits / consommés par cette dimension (AD-9)

| Événement (AD-9) | Rôle dans cette dimension | Règle (F-xx) |
| --- | --- | --- |
| `JobCompleted` (payload `jobId`+`jobKind`, F-08) | **Consommé** côté client : l'UI (pack `02-frontend` § 4, `JobCompleted` → état `success`) ; `jobKind` filtre le succès (ex. `artifact_gen` vs `research`) — l'UI n'est **jamais** le producer. | AD-9/F-08 : payload `jobId`+`jobKind` obligatoire (F-08) ; producer = Job system (serveur), AD-8. |
| `ArtifactGenerated` (post-upload-R2, F-06) | **Consommé** pour le succès Artifact Hub côté client ; la **vraie** mutation (insertion `artifacts`) est faite par le module owner (Artifact) — pas par l'UI (AD-7/F-03 single-writer). | AD-9/F-06 : émis **par l'Artifact module, après l'upload R2 uniquement** ; le kernel **n'émet pas** (F-06). |
| `TaskCompleted`, `GoalUpdated`, `FlashcardReviewed`, `CourseImported`, `ProgressEvidenceCreated`, `SkillStateChanged`, `DiscoveryItemCreated` | **Propagés** par PowerSync (serveur→local) pour mettre à jour le store local ; **consumés** côté serveur par les declared consumers (AD-9) ; côté client, seule la **nouvelle valeur locale** est lue (les événements ne sont **pas** re-persistés par l'UI, AD-2). | AD-2 (pas de re-persistance croisée), AD-7 (PowerSync propage les valeurs), F-04 (consumers déclarés). |
| (Événements de sync **interne** — pas dans le vocabulaire AD-9) | `SyncStateChanged` (interne, pas un événement métier AD-9 ; il **alimente** `SyncStatus` § 3.2) — **pas** distribué, pas partagé, uniquement un hook de notification **interne** du store local. | Pas un événement AD-9 (pas de multiple consumers asynchrones) ; une **opération transactionnelle directe** (AD-9, doc §6 v1.6 : « modifier le titre d'une tâche n'a pas besoin de devenir un événement distribué »). |

**Règle d'or (AD-9/F-04)** : cette dimension **n'introduit aucun nouvel événement** du vocabulaire
figé ; elle **consomme** `JobCompleted`/`ArtifactGenerated` (F-08/F-06) et **propage** les valeurs
locales. Un module qui **consomme** un événement doit le **déclarer** dans son Contract Pack (AD-13/F-04) ;
`packages/data` consomme les événements **vues/seuls** pour le store local ; l'UI **ne consomme
jamais d'événement** au sens AD-9 (elle lit les valeurs locales + `SyncStatus` § 3.2).

---

## 4. Schémas de données (entités AD-15 + relations, sans DDL)

### 4.1 Principe du store local : **miroir des entités AD-15, pas une 2ᵉ source de vérité**

Le store SQLite local est un **miroir** des entités AD-15 (frozen, `packages/domain`) : chaque entité
a **une** table locale **par module owner** ; les **relations** (FK, join) vivent dans le **même
module owner** (AD-2, F-03 : un scope ne joint **jamais** les tables internes d'un autre module).
Le schéma SQL local **est la persistance** de ces types (AD-15), pas une redéclaration (spine § 4 de
`01-backend`, `03-sync` reprend la règle).

### 4.2 Mapping entité (AD-15) → module owner → table locale (SINGLE-WRITER, AD-7/F-03)

> Table de mapping **frozen** (wave 0, ratifiée avec le mapping entité→package→équipe, spine AD-15
> § Deferred / Open Question). Chaque entité a **un unique owner** qui en est le **seul writer** du
> store local. Le kernel **n'est jamais** un writer (F-03, AD-7).

| Entité (AD-15) | Module owner (writer unique) | Table locale (SQLite) | Notes (relation / AD) |
| --- | --- | --- | --- |
| `Task`, `Milestone` | **Productivity** | `tasks`, `milestones` | hiérarchie goal→project→task (doc §2.6, `01-backend` § 4.1) ; récurrence **matérialisée** (pas de règle) pour PowerSync (AD-7, `01-backend` § 4.1) ; **pas** de `JOIN` de tables d'un autre module (F-03). |
| `Project`, `Goal` | **Productivity** | `projects`, `goals` | `GoalUpdated` (AD-9) : owner = Productivity (writer local + producer serveur) ; l'UI lit le store local, le serveur produit l'événement. |
| `Habit`, `Routine` | **Productivity** | `habits`, `routines` | suivi de régularité (doc §2.7) ; owner Productivity. |
| `FocusSession` | **Productivity** | `focus_sessions` | `FocusController` port (doc §7/§8) ; owner Productivity (writer local). |
| `Decision` | **Productivity** | `decisions` | journal des décisions (doc §2.9). |
| `Event` (calendrier) | **Productivity** | `events` | agenda/calendrier (doc §2.4) ; **distinguer** de la table serveur `events` (Event History, AD-6, `01-backend` § 4.8) — le store local n'a **pas** de table `events` d'Event History (celle-ci est serveur-only, AD-6/F-10). |
| `Note`, `Resource` | **Knowledge** (contenu) | `notes`, `resources` | notes libres/structurées, bibliothèque de ressources (doc §2.1/§2.11) ; les **fichiers** vivent dans R2 (AD-16, `01-backend` § 5.4) ; le store local ne stocke que les métadonnées + `r2_key`. |
| `Course`, `Subject`, `Skill` (définitions) | **Learning** | `courses`, `subjects`, `skills` | `CourseImported` (AD-9) ; owner Learning (writer local des métadonnées). |
| `LearningSession`, `Review` | **Learning** | `learning_sessions`, `reviews` | `FlashcardReviewed` (AD-9, FSRS) ; owner Learning ; **l'algorithme FSRS s'exécute côté serveur** (`01-backend` § 4.2/§ 5.1) ; le store local lit l'état FSRS (`due`, `stability`, `difficulty`). |
| `SemanticNode`, `SemanticEdge`, `SemanticBridge`, `NodeState` | **Knowledge** | `semantic_nodes`, `semantic_edges`, `semantic_bridges`, `node_state` | AD-6 : **la vérité du Semantic Tree est dans la Knowledge Base (serveur)**, le moteur de rendu n'est **jamais** la source de vérité (AD-6, pack `02-frontend` § 5.1) ; `node_state` = **owner Knowledge uniquement** (AD-6/F-02) ; le store local est un **miroir de lecture** (pas de write du contenu du Tree par l'UI). **Note de schéma local (normative)** : `semantic_nodes` local **n'inclut PAS** la colonne `embedding vector` (les embeddings vivent en serveur PostgreSQL/pgvector, `01-backend` § 4.3, AD-12/F-09 : la recherche sémantique est serveur-only, l'appareil ne fait jamais de retrieval local) — le miroir local conserve `source_ref_ids[]` (listes CRDT §5.3) mais **pas** les vecteurs (perte de stockage sans gain de query locale). |
| `SourceRef`, `EvidenceRef` | **Knowledge** / **Progress** | `source_refs`, `evidence_refs` | `SourceRef` (Knowledge, AD-6/§14) ; `EvidenceRef` (Progress, doc §18.8, AD-6 : Progress **émet**, n'écrit **jamais** les tables Knowledge, F-02). |
| `ProgressSnapshot`, `ProgressEvidence`, `SkillState`, `ProgressTrend`, `ProgressEvent`, `TrajectoryScenario` | **Progress** | tables `progress_*` (voir `01-backend` § 4.4) | **owner Progress** (F-07 : **Progress est le seul** producer de `ProgressEvidenceCreated` ; il **émet** les événements, il **n'écrit jamais** les tables Knowledge, AD-2/F-02) ; le store local est un **miroir de lecture** des `Progress*` (l'UI lit, pack `02-frontend` § 5.3). |
| `DiscoveryItem`, `Gap` | **Discovery** / **Progress** | `discovery_items`, `gaps` | `DiscoveryItemCreated` (AD-9) ; **les définitions** de `Gap` sont en `packages/domain` (AD-15) ; le **module owner** des lignes `gaps` = **Progress** (`01-backend` § 4.4 : « les définitions de Gap sont en packages/domain ; le module owner des lignes gaps est Progress ») ; Discovery **lit** via vue publique, **n'écrit pas** (F-04). |
| `Artifact` | **Artifact** | `artifacts` | métadonnées ; les **fichiers** dans R2 (AD-16) ; `ArtifactGenerated` (AD-9/F-06) est émis **après l'upload R2** ; le store local ne stocke que métadonnées + `r2_key` (AD-2, F-03). |
| `Automation` | **Integrations** | `automations` | Supabase Cron → dispatcher (AD-8, `01-backend` § 5.2) ; owner Integrations. |
| `UserContext` | **Identity** | `user_context` | profil/préférences ; owner Identity (writer local + serveur, `01-backend` § 2.1). |
| `ExpertSkill` | **Agent** | `expert_skills` | **côté serveur uniquement** (`01-backend` § 4.7 : « la mémoire de l'agent n'est PAS synchronisée sur l'appareil ») — le store local n'a **pas** de table `expert_skills` (AD-3 : pas de clé/mémoire sensible sur l'appareil). |

**Règles du schéma local (normatives)** :
1. **Une table locale par module owner** ; les **relations (FK, join) ne traversent jamais les modules**
   (F-03, AD-2) : si une vue a besoin d'une donnée d'un autre module, elle passe par la **vue publique**
   du module source (`01-backend` § 3.4), **jamais** par un `JOIN` direct de table interne (AD-7, F-03).
2. **Les fichiers ne vivent pas dans SQLite** (AD-16, R2) : le store local stocke uniquement les
   **métadonnées** + `r2_key` (pas le binaire) — les binaires dans R2 (bucket privé + URLs présignées,
   `01-backend` § 5.4).
3. **Horodatage canonique = serveur** : chaque entité mutable porte `updated_at` **serveur** (canon,
   `01-backend` § 3.4) ; le client ne **date jamais** ses propres mutations de manière à ce que le
   serveur écrase un `updated_at` plus ancien (`01-backend` R6, AD-7 : « server-wins + per-entity
   timestamp ») — la mutation locale a un **horodatage local** (pour le file d'up-sync) mais le **résultat
   autoritatif** est celui du serveur (server-wins, AD-7).
4. **`ExpertSkill`, Event History `events` et les tables `progress_events` (Event History de
   Progress) n'ont pas de table locale** : `expert_skills` est serveur-only
   (`01-backend` § 4.7, AD-3) ; la table serveur `events` (Event History, AD-6) et `progress_events`
   (`01-backend` § 4.4) ne sont **pas** dupliquées dans le store local (F-10 : le versioning du
   Tree = table Knowledge serveur, pas l'Event History locale). **Miroir local des `Progress*`
   (figé, règle de cohérence §3.3 vs §4.2)** : les entités Progress **mirroirées** sur l'appareil
   sont : `skill_states` (niveau/fraîcheur/confiance — l'écran Progress et les dashboards G2 du
   pack 02 §5.3 les lisent), `progress_snapshots` (état à un instant, `TrajectoryScenario` est
   serveur-only car conditionnel et volumineux) — **pas** `progress_evidences` (les preuves sont
   consommées côté serveur ; le mirror `evidence_refs[]` reste dans les listes CRDT des entités
   propriétaires, ex. `tasks.evidence_refs`), **pas** `progress_events` (serveur-only, F-10),
   **pas** `progress_trends` (agréats dérivés, recalculés par le module Progress serveur,
   `01-backend` § 4.4). Le **mapping événement AD-9 → miroir local** est figé :
   `ProgressEvidenceCreated`/`SkillStateChanged`/`GoalUpdated` (serveur-only, AD-9) **propagent
   leurs effets sur les miroirs locaux** (`skill_states`, `goals`) via le downstream PowerSync
   (§5.2) ; l'UI ne lit que le miroir local, jamais l'événement direct (AD-7, F-03).


---

## 5. Décisions d'implémentation

### 5.1 Flux de synchro **upstream** (local → serveur) — ordre et déduplication

1. **Application locale immédiate** : la mutation est appliquée au store local **immédiatement** (l'UI
   voit le résultat sans attendre le réseau — AD-7 : « the UI reads local state first »). Le `updated_at`
   **local** (pour l'ordre du file) est posé ; la valeur est marquée `queuedForUpsync` (contrat
   `WriteResult`, § 3.1).
2. **File d'up-sync par ordre d'horodatage local** : PowerSync **remonte** les mutations en file
   (FIFO par horodatage local) vers le serveur ; chaque mutation porte l'horodatage local (pour
   l'ordre) + l'horodatage serveur (canon, remis par le serveur).
3. **Déduplication par `id` + horodatage** : si une mutation locale a déjà été reconnue côté serveur
   (même `id` + `updated_at` serveur ≥ l'horodatage de la file), elle est **dédupliquée** (pas de
   double application, AD-8 : les jobs/mutations doivent être **idempotentes**).
4. **Remontée batchée** : la remontée est **batchée** (pas une requête réseau par mutation) ; les
   batchs sont **attempts bornés** (retry sur panne transitoire uniquement, AD-5 — pas de bypass de
   quota par rotation ; AD-8 : « persisted, idempotent, retryable, observable »).

### 5.2 Flux de synchro **downstream** (serveur → local) — pûsh des vues

1. **Le serveur est l'autorité** : les vues PowerSync (scopes, § 5.4) **poussent** les mises à jour
   (insertion/modification/suppression) vers le store local ; le moteur PowerSync **applique** localement
   (server-wins, AD-7).
2. **Le store local est mis à jour sans bloquer l'UI** : la sync **n'occupe jamais** un frame UI
   (pack `02-frontend` § 9 : « la sync ne doit jamais bloquer un frame UI ; l'app n'a qu'à lire le
   store »). La propagation est **réactive** (`watch`, § 3.1, `LocalQueryRepository.watch`).
3. **Pas de re-persistance croisée** (AD-2, F-04) : le store local **n'écrit jamais** un événement
   comme le sien ; il reçoit les **valeurs** (entités), pas les événements distribués (les événements
   AD-9 sont **serveur-only** ; l'UI lit les valeurs locales + `SyncStatus` § 3.2).

### 5.3 Résolution de conflit (AD-7, F-03) — règle canonique

- **Réglage par défaut = server-wins + horodatage serveur par entité** (AD-7) : si une mutation locale
  (en attente de remontée) **entre en conflit** avec une valeur serveur récente (même entité,
  `updated_at` serveur plus récente), le **serveur gagne** (le `updated_at` serveur est canon, § 4.2
  règle 3). **Aucune** alerte utilisateur en cas de résolution serveur-wins (le conflit est résolu
  **silencieusement** — `01-backend` § 6 : « le conflit est résolu silencieusement par PowerSync »).
- **Exception CRDT pour les listes qui doivent merger** (AD-7) : pour les **listes** de type
  « ensemble de valeurs optionnelles » (tags, dépendances de tâches, listes de `source_ref_ids`,
  champs multi-valués `dependencies[]`, `evidence_refs[]`), le store local utilise le type CRDT
  **figé : OR-Set (Observed-Remove Set)** — décision normative (plus de double choix) : OR-Set
  (pas LWW-Map, qui ne résout pas proprement le cas « supprimé par un, ré-ajouté par l'autre »
  sans résurrection). **Encodage de valeur (figé, SSoT `packages/domain`, AD-15)** : chaque
  élément de liste = `Record<string, unknown>` avec `{ v: string; ts: serverTimestampMs; c: clientId }`
  (valeur + horodatage serveur + client d'origine) ; le CRDT OR-Set est **sérialisé** dans le
  champ SQLite (JSON colonne) par `packages/data` ; **une seule implémentation** (pas de dualité
  OR-Set/LWW-Map) ; le test de lossless-merge (§7) passe sur cette implémentation unique.
  Les **ajouts et suppressions** convergent par union/diff (merger **sans perte**) au lieu
  d'écraser (le « server-wins » est inapproprié pour les listes — deux clients qui ajoutent des
  éléments distincts doivent **fusionner**, pas écraser).
  Le **test CRDT** (§ 7) vérifie le merger **sans perte** (deux écrits concurrents = union des
  éléments, pas l'écrasement du plus récent).
- **Le single-writer prévient** (AD-7, F-03) : comme chaque entité a **un unique owner writer**,
  les conflits **sont rares** ; la **règle de conflit** est le **filet de sécurité** (une collision
  résiduelle sur les listes = CRDT ; sur les scalaires = server-wins), **pas** le mécanisme principal
  (`01-backend` § 6 : « le single-writer par entité prévient les conflits, la résolution est le filet
  de sécurité »).

### 5.4 Scopes / vues SQL PowerSync (AD-7, F-03) — ownership + interdiction de jointure

- **Owner** : `packages/data` possède **TOUTES** les vues PowerSync (scopes), **provisionnées en
  vague 0** (AD-7, dernière phrase) ; **aucune** autre équipe n'ajoute une vue sans PR (spine §
  Consistency Conventions, `01-backend` § 3.4).
- **Un scope = une vue d'UN seul module owner** : le scope `productivity_sync` porte les vues de
  Productivity (`tasks`, `projects`, `goals`, …) ; le scope `learning_sync` porte les vues de Learning
  (`courses`, `reviews`, `flashcards`, …) — **un module owner ≠ plusieurs scopes** (AD-2, F-03).
- **Interdiction de jointure inter-modules** (AD-7 + AD-2, F-03) : un scope **ne joint jamais** les
  tables **internes** d'un autre module (ex. le scope Productivity **ne joint pas** `flashcards` de
  Learning, ni inversement ; le scope `focus_sessions` ne **joint pas** `tasks` pour compter les tâches
  terminées, F-03). Le besoin de **lecture inter-modules** passe par une **vue publique** du module
  source : le module expose `SELECT` sur ses **types publics** (une vue, pas une table interne) +
  policy `service_role` (`01-backend` § 3.4).
- **RLS** (AD-2, `01-backend` § 2.2) : les vues PowerSync sont lues par le relay via `service_role`,
  **toujours** sous les policies RLS (pas de bypass, `01-backend` § 2.2) ; chaque vue est bornée
  par `user_id` (isolement par utilisateur, AD-2/§2.2).

### 5.5 Intégration Supabase (AD-6, AD-7, AD-16) + re-sync après coupure longue

- **RLS** = le mécanisme d'application d'AD-2 au niveau données (`01-backend` § 2.2, tranchement) :
  les vues PowerSync + le sync engine passent **toujours** par les policies `service_role` (AD-16,
  AD-7). Les valeurs **d'environnement** (noms de buckets, régions, clés) sont les **données de vague 0**
  (spine § Deferred, AD-16a) ; **la structure** (3 environnements dev/staging/prod, owner unique
  `packages/data`/Foundation, AD-16) est **fixée ici**.
- **Triggers PowerSync** : les mutations serveur (post-INSERT/UPDATE/DELETE dans les tables vues)
  déclenchent les **triggers PowerSync** qui **poussent** la mise à jour au relay (downstream, § 5.2) ;
  les mutations locales montent via le relay (upstream, § 5.1). **Pas** de broker (Kafka) en V1
  (AD-8, `01-backend` § 3.3 : les événements passent par la table `events` serveur, pas par le réseau
  de synchro local).
- **Re-sync après coupure longue** (offline prolongé, AD-7 : offline = état premier) :
  1. **Redétection réseau** (`@capacitor/network` injecté par `packages/platform`, pack
     `02-frontend` § 7) → le store local repasse en `online` ( `SyncState` § 3.2, `idle → syncing`).
  2. **Remontée du file complet** (FIFO, § 5.1) : les mutations `queuedForUpsync` (dont l'accumulation
     pendant l'offline) sont remontées **en priorité** (le plus ancien d'abord, horodatage local) ; la
     **déduplication** (§ 5.1.3) évite les doubles ; les **conflits** sont résolus **server-wins**
     (scalars, § 5.3) / **CRDT merge** (listes, § 5.3).
  3. **Pull de l'entité serveur** : après la remontée, le relay **tire** les vues (§ 5.4) pour
     récupérer les mises à jour faites **par d'autres clients / modules** pendant la coupure
     (server-wins sur les scalars, CRDT sur les listes).
  4. **`SyncState` = `idle`** : le file est vide (`pendingUpstream = 0`, § 3.2) ; l'UI **reprend**
     l'état `success` normal (pack `02-frontend` § 7 : l'offline **se termine**, l'app redevient
     « normale »).
  5. **Bornes** : si le file **dépasse** un seuil (config de vague 0, ex. 5000 mutations ou 24 h), la
     remontée est **batchée** (pas une seule requête géante) ; les jobs **heavy** (AD-8) sont
     **re-déclenchés** (persists, idempotent) — les **travaux lourds** ne se font **jamais** pendant
     l'offline (AD-8, `01-backend` § 5.1 : « le travail lourd ne se termine jamais dans une Edge
     Function ») ; ils sont **re-planifiés** (idempotence par `idempotency_key`, `01-backend` § 5.3).
  6. **Clé de déduplication côté client (figée, normative)** : chaque mutation locale porte une
     **`localMutationId`** = ULID (tri chronologique, généré par `packages/data` à l'application
     locale immédiate, §5.1) ; cette clé est la **déduplication upstream** du file PowerSync
     (re-syncs répétés après coupures multiples ne double-remontent PAS les mêmes mutations).
     Côté serveur, la **déduplication des jobs client-originés** (re-planifiés, §5.5.5) utilise
     l'`idempotency_key` de `job_queue` (`01-backend` §5.3 : `job_kind` + hash payload + `user_id`)
     — le format est partagé avec la clé du file client : le serveur déduit la clé depuis le
     `source_local_mutation_id` (ULID, champ de `job_queue`) si le job est ré-emis par un
     re-sync ; le test re-sync (§7) couvre le double re-planification.

### 5.7 Throttling de sync en background (paramètre PowerSync, owner `packages/data`)

Le pack `04-mobile` §6.2 **impose** la contrainte : « la fréquence de sync PowerSync baisse
automatiquement en background, intervalle ≥ 5 min, pas de polling réseau en app background ».
Cette mécanique **est** de l'owner de ce pack (sync = `packages/data`, AD-7) : le paramètre
PowerSync **figé** est :

- **`minSyncIntervalMs`** (option du sync engine PowerSync, configurée par `packages/data`) :
  - **foreground** : valeur de vague 0 (défaut suggéré ~ 30 s) ;
  - **background** : **≥ 5 min** (300 000 ms) — le sync engine passe en mode **throttlé**
    (pas de boucle serrée, pas de polling réseau) ;
  - **retour foreground** : re-sync immédiat (§5.5), jamais une longue attente.
- **Déclenchement** : le passage foreground/background est signalé par `AppLifecycleAdapter`
  (pack 04 §3.2.1, injecté par `packages/platform`) → `packages/data` ajuste `minSyncIntervalMs`
  (le store local reste la source de vérité UI, AD-7 ; la sync n'est jamais bloquante).
- **`FOREGROUND_SERVICE`** : si la sync doit continuer au-delà d'une limite (passage en
  background prolongé), la permission est demandée (pack 04 O4, §6.1) ; le **paramètre
  `minSyncIntervalMs` est le levier du throttling** (ce pack le définit ; le pack 04 l'
  impose comme contrainte, les deux packs sont cohérents).

### 5.8 Bridge React Query (pack 02 §3, `@tanstack/react-query` ↔ `LocalQueryRepository.watch`)

Le pack `02-frontend` déclare `@tanstack/react-query` comme couche de data state (les queries
lisent les repositories PowerSync/SQLite). Le **pont** entre RQ et le `watch` du §3.1
(`LocalQueryRepository.watch`) est **documenté ici** (owner `packages/data`) — le pack 02 ne
ré-invente pas la mécanique :

- **Query keys** : convention `packages/data` (owner, AD-7) — les clés RQ des entités locales
  suivent le schéma `[module, entity, ...filter]` (ex. `['tasks', 'list', filter]`) ; `packages/
  data` fournit les **factories de query** (le repository expose `watch` ; RQ **consomme**
  `watch` via un hook bridge `useLocalQuery` (owner `packages/data`, pas RQ directement)).
- **Invalidation** : les événements de sync (§3.2 `SyncStateChanged` interne, non-AD-9)
  déclenchent `invalidateQueries` de la entité concernée (le bridge écoute `watch` et mappe
  vers RQ) ; **pas** d'invalidate par événement AD-9 (l'UI lit le store local, AD-7/F-03).
- **Pas de duplication de cache** : RQ est **au-dessus** de `watch` (le store local est la
  source de vérité, RQ = cache de lecture/reactive), pas un second store (violation AD-7 si
  RQ cacheait des données métier au lieu de lire le SQLite).

### 5.9 Offline = état de première classe (règles de surface)

- **Offline = état de première classe, pas une panne** (AD-7) : l'app **fonctionne** sans réseau —
  **lecture locale** (tous les écrans lisent le store local), **mutations locales** (file up-sync),
  **seuls** les actions **nécessitant le cloud** (jobs IA/recherche, uploads R2, AD-8/AD-16) sont
  **désactivées avec un explicatif** (pas masquées), pas crashées (pack `02-frontend` § 7, R7).
- **Détection** : `@capacitor/network` (injecté par `packages/platform`) → `onNetworkChange →
  store.uiStore.setOffline(bool)` (pack `02-frontend` § 7) ; le `SyncStatus.online` (§ 3.2) **reflète**
  la détection réseau ; l'UI **ne décide jamais** de l'offline elle-même (le `SyncStatus` est **le**
  contrat, pas le store UI).
- **Pas de cache réseau pour les écrans** (AD-7, F-03) : toute lecture d'écran = **query locale**
  (SQLite), **jamais** de fetch réseau qui synchroniserait l'UI (pack `02-frontend` § 9 : « PowerSync =
  perf local : toute lecture d'écran = query locale (SQLite), pas de fetch réseau (AD-7) »).

---

## 6. États et gestion d'erreurs

| État / erreur (AD-13, états canoniques `loading`/`empty`/`success`/`error`/`offline`) | Règle (AD-xx) | Surface (pack `02-frontend`) |
| --- | --- | --- |
| `offline` (réseau absent **ET** store local dispo) | AD-7 (offline = premier état, pas une panne) ; F-03 (single-writer prévient le conflit) | Bannière fine « Hors-ligne — vos données locales sont disponibles » ; l'app **fonctionne** ; actions cloud **désactivées avec explicatif** (pack § 7, R7). |
| `offline` (réseau absent **ET** store local **absent** — ex. 1ʳe sync non terminée) | AD-7 (offline = premier état) | « Hors-ligne — aucune donnée locale encore » ; l'app **ne crash** pas ; les actions locales restent possibles (file up-sync, AD-7) ; les actions cloud sont désactivées (pack § 7). |
| Erreur de sync (échec de remontée) | AD-5 (retry sur panne **transitoire** ; **pas** de bypass de quota) ; AD-8 (idempotent, observable) | `SyncState = 'degraded'` (§ 3.2) ; **retry** borné (backoff exponentiel, `01-backend` § 5.3) ; **pas** d'écrasement silencieux : la file `pendingUpstream` **subsiste** (la mutation n'est **pas** perdue, AD-7/F-03). |
| Conflit serveur vs local | AD-7 (server-wins + per-entity timestamp) ; F-03 (single-writer prévient) ; CRDT pour les listes (§ 5.3) | **Résolution silencieuse** (`01-backend` § 6) : le **serveur gagne** (scalars) ; les **listes** mergent **sans perte** (CRDT, § 5.3) ; **aucune** alerte utilisateur sauf collision **type** CRDT non-mergeable (cas résiduel, à signaler). |
| Échec de job (heavy) pendant la synchro | AD-8 (jobs persistés/idempotents) ; AD-5 (retry borné) ; F-08 (`JobCompleted` porte `jobId`+`jobKind`) | L'UI **consomme** `JobCompleted` (§ 3.3) : `status: failed` → état `error` avec `jobId` pour le **retry** (`01-backend` § 6 : « le UI peut le re-essayer, l'UI reste honnête ») ; l'UI ne **crash** pas, ne **reproduit pas** un job (idempotence, AD-8). |
| Échec d'authentification (JWT Supabase expiré) | AD-2/AD-16 (RLS, service_role) ; `01-backend` § 6 (Auth) | **Refresh automatique** du JWT ; échec d'Auth → redirection vers l'écran de **login** (l'appareil **ne peut pas** appeler les Edge Functions sans identité — RLS, `01-backend` § 2.2/§ 6) ; l'UI reste **lisible** (store local), les actions serveur sont bloquées. |
| Store local corrompu / migration échouée | AD-7 (store local = source de vérité UI) ; F-03 (single-writer) | **Re-sync depuis le serveur** (rebuild du store local, § 5.5.3 : « pull de l'entité serveur ») ; si le serveur est inatteignable **et** le store corrompu → état `error` (pas `success`), **pas** de crash (AD-7, pack § 7) ; la migration est **idempotente** (AD-8). |

**Règle transversale** : **aucun** état d'erreur ne **crash** l'app (AD-7, pack `02-frontend` R7 :
« l'app ne devient jamais brisée sans réseau ») ; les **actions qui exigent le cloud** sont
**désactivées avec explicatif**, **jamais** masquées, **jamais** source de crash (`01-backend` § 6 :
« dégradation propre »).

---

## 7. Tests obligatoires (AD-13 DoD, par module Sync)

- **Single-writer (AD-7 / F-03)** : test par entité locale — **seule** l'unité propriétaire mute le
  store local de cette entité ; le **kernel** ne mute **JAMAIS** directement une table locale
  (F-03 : le test est un **échec** si l'`Action` du kernel écrit directement dans `tasks` local,
  `01-backend` § 7). **1 test par entité AD-15** (§ 4.2) — le viol de single-writer = **blocking
  review finding** (AD-13, F-03).
- **Server-wins + per-entity timestamp (AD-7)** : test **déterministe** — deux mises à jour
  concurrentes de la **même entité** (môme `id`) = le plus récent **gagne** (le `updated_at` serveur
  est canon) ; test du **ordre** (FIFO par horodatage local, § 5.1.2) ; la **résolution** est
  **silencieuse** (pas d'alerte, § 6) ; test de **déduplication** (§ 5.1.3 : une mutation déjà
  reconnue côté serveur n'est **pas** réappliquée — idempotence, AD-8).
- **CRDT pour les listes (AD-7, § 5.3)** : test de **merger sans perte** — deux clients qui
  **ajoutent** des éléments **distincts** à une liste (tags, `dependencies[]`, `source_ref_ids[]`)
  **fusionnent** (union), **pas** l'écrasement du plus récent ; test de **suppression** (un élément
  supprimé par l'un, ajouté par l'autre = convergence OR-Set, pas de résurrection) ; **1 test par
  type de liste** (CRDT = OR-Set figé, § 5.3 — plus de double choix).
- **Interdiction de jointure inter-modules (AD-7, F-03, AD-2)** : **test statique** — un `JOIN` sur
  une **table non-publique** (interne) d'un **autre module** = **échec** (`01-backend` § 7 : « test
  statique : un JOIN sur une table non-public = échec ») ; les **vues publiques** (types publics +
  policy `service_role`) sont les **seuls** canaux inter-modules (`01-backend` § 3.4). **1 test par
  scope** (§ 5.4) ; le test vérifie que **chaque** scope ne joint **que** les tables de **son** module
  owner.
- **Re-sync après coupure longue (AD-7, § 5.5)** : test du **scénario complet** — (a) offline
  (file up-sync s'accumule), (b) **re-connect** (file remontée **FIFO**, déduplication, conflits
  résolus server-wins / CRDT), (c) **pull** serveur (mises à jour d'autres clients), (d) `SyncState`
  = `idle` (file vide), (e) les **jobs heavy** sont **re-planifiés** (idempotents, AD-8) — test du
  **file entier** (≥ 5000 mutations, § 5.5.5) en batch ; test **d'absence de perte** (aucune
  mutation locale perdue après re-sync, AD-7/F-03).
- **États UX (AD-13, § 6)** : les 5 états canoniques (`loading`/`empty`/`success`/`error`/`offline`)
  sont **testés** (pack `02-frontend` § 7 : « un écran qui n'implémente pas l'un des 5 = DoD non-fermé,
  blocking review ») ; test de **l'offline** (intercept réseau + `SyncStatus.online = false`, § 3.2) :
  l'app **rester** fonctionnelle (lecture locale + mutations locales), les actions cloud sont
  **désactivées avec explicatif** (pas de crash, R7).
- **Type-check & contrats (AD-15, F-01, AD-2)** : `type-check` — les types inter-modules (entités AD-15)
  viennent de `packages/domain` (**pas** redéclarés, F-01) ; **lint** ; build du monolithe (spine §
  Consistency Conventions : `main` buildable) ; **pas** d'import de SDK fournisseur dans le store local
  (AD-1 : le domaine/application n'importe **jamais** un fournisseur directement).

---

## 8. Risques et dépendances

### 8.1 Dépendances (ordre de vague, AD-13, spine § Consistency Conventions / ADR §21.8)

- **Vague 0 (ce pack)** : `packages/data` (owner AD-7, **provisionné en vague 0**), **schéma SQLite
  local** (§ 4), **vues PowerSync** (scopes, owner `packages/data`, § 5.4, `01-backend` § 3.4),
  **RLS** (`01-backend` § 2.2), **contrats de repository** (§ 3.1), **mapping entité→owner→table**
  (AD-15/F-01, § 4.2) ; **clés** CI/CD + compte PowerSync/Supabase (owner Foundation, AD-16c,
  `01-backend` § 8.1).
- **Vague 1 (Fondations)** : Auth Supabase (AD-2/AD-16, `01-backend` § 2.2/§ 6), **provision**
  `packages/data` (owner AD-7), **PowerSync relay** (composant serveur, AD-7/AD-16) ; **implémentation
  R2** (`ObjectStorage`, `01-backend` § 5.4) ; le **sync engine** (relay + triggers + RLS) est
  opérationnel (vague 1) — **préalable** pour toute mutation local-first.
- **Vague 2 (Features)** : les modules (Productivity, Learning, Knowledge, Discovery, Progress,
  Artifact) **consomment** les contrats de **ce pack** (repositories § 3.1, single-writer § 4.2/§ 5.3,
  états § 6) — **jamais** leur propre store / propre bucket / propre registre (AD-16, `01-backend`
  § 8.2 R7 : « un team feature qui ignore l'owner et crée son propre registre/son propre bucket =
  violation expressément AD-16 »).
- **Vague 3 (Agent)** : le **kernel serveur** (F-09) **émet** les commandes/événements (AD-7/F-03) ;
  le store local **propage** les nouvelles valeurs (downstream, § 5.2) ; le kernel **n'est jamais** un
  writer local (F-03, § 4.2/§ 5.3) ; `expert_skills` **n'est pas** synchronisée (AD-3, § 4.2) — le
  kernel **lit** le contexte, **n'écrit pas** le store local.
- **BLOCANT (vague 0)** : le **mapping entité→package→équipe** (AD-15, spine § Deferred / Open
  Question, `01-backend` § 8.1 : « le mapping final entité → package → équipe (AD-15) ») + la
  **ratification pnpm** (spine Open Question #1, `01-backend` § 8.1) **avant** la découpe des
  packs Data / Agent / Design System (spine Open Question).

### 8.2 Risques (avec mitigations)

- **R1 (AD-7/F-03) — un scope joint les tables internes d'un autre module (trou F-03)** : = un
  **écrasement silencieux** au re-sync (le store local perd la **cohérence** entre modules, AD-2).
  **Mitigation** : le **test statique** de jointure (§ 7, « JOIN sur une table non-public = échec »)
  est **blocking** ; le **review** Codex (ADR §21.6) **vérifie** les boundaries (trou listé, F-03) ;
  les **vues publiques** (types publics + policy `service_role`, `01-backend` § 3.4) sont le **seul**
  canal inter-modules.
- **R2 (AD-7/F-03) — single-writer violé (le kernel mute directement, ou l'UI mute un 2ᵉ)** : = un
  **conflit résiduel** au re-sync (le server-wins **écrase** une mutation valide, ou une liste
  **perd** des éléments). **Mitigation** : le **test single-writer** (§ 7, « le kernel ne mute JAMAIS
  une table locale, F-03 ») est **blocking** ; le **store UI** (Zustand) ne contient **jamais** de
  donnée métier (pack `02-frontend` R2 : « le store UI = UI state + IDs, jamais de Task/Goal complets »
  ; test de séparation en CI : le store **n'expose pas** de type `packages/domain`).
- **R3 (AD-7) — la résolution de conflit est **silencieuse** et **écrase** une mutation locale valide
  (server-wins)** : le **scalarm** est **rare** (le single-writer prévient, § 5.3) ; le **risque** est
  sur les **listes** (le server-wins **écrase** un ajout distinct). **Mitigation** : **CRDT pour les
  listes** (§ 5.3, OR-Set figé) ; test de **merger sans perte** (§ 7) ; le **file up-sync** FIFO
  (§ 5.1.2) garantit que les mutations locales **précédent** la résolution serveur ; **aucune** perte
  de mutation locale après re-sync (test § 7, R2).
- **R4 (AD-7/F-03/AD-2) — les entités AD-15 sont **doublées** (un type redéclaré par deux équipes,
  F-01)** : = des stores locaux **incompatibles** (même `Task`, **deux** shapes). **Mitigation** :
  le **test type-check** (§ 7 : « les types inter-modules viennent de `packages/domain`, F-01 ») est
  **blocking** ; le **mapping AD-15** (§ 4.2, ratifié en vague 0, BLOCANT § 8.1) est **la référence** ;
  **jamais** de redéclaration (F-01, AD-15) ; le **review** Codex (ADR §21.6) **vérifie** la
  compatibilité des contrats (trou listé, F-01).
- **R5 (AD-7/AD-16) — le sync **bloque** un frame UI, ou une action locale **échoue** pendant
  l'offline** : l'app **semble** cassée (violation AD-7, pack `02-frontend` R7 : « l'app ne devient
  jamais brisée sans réseau »). **Mitigation** : la **sync** est **toujours** en arrière-plan
  (§ 5.6, pack `02-frontend` § 9 : « la sync ne doit jamais bloquer un frame UI ») ; les **actions
  qui exigent le cloud** sont **désactivées avec explicatif** (pas de crash, § 6) ; le **store local**
  est **toujours** disponible (lecture immédiate, AD-7) ; test de l'offline (pack § 7, R7 + § 7 ici :
  « l'app reste fonctionnelle (lecture locale + mutations locales) »).

### 8.3 Ce qui reste ouvert (pour le team-lead)

- Les **valeurs** de synchro (batch size, seuil du file, SLO de latence, délais de `SyncState`)
  = **données de vague 0** (spine § Deferred, AD-16a : « les valeurs d'environnement sont les données
  de vague 0 ; la structure est fixée ici ») ; la **structure** (batch, FIFO, dédup, server-wins, CRDT)
  est **figée ici**.
- Le **mapping final** entité → package → équipe (AD-15, § 4.2) ; le **CRDT** (figé : OR-Set +
  encodage, § 5.3 — plus de double choix) ; le **PowerSync relay** (composant serveur vs self-hosted,
  AD-16, `01-backend` § 5.1 « PowerSync relay (serveur) »).

---

**Références** : spine (AD-1…AD-16, statut final 2026-09-21 ; AD-7 resserree par F-03) ; ADR v1.7
(gelé, §7 Local-First + §23 plateforme + §21 parallélisation) ; revue adversariale (F-01…F-10,
**intégrées** dans le spine final) ; `01-backend.md` (RLS §2.2, vues §3.4, jobs §5, états §6) ;
`02-frontend.md` (state UI §3, use-cases §4, états §7, perf §9, risques R2/R7). Ce pack
**référence et approfondit** le spine (pas de redondance) ; les **décisions contraignantes**
restent dans le spine (read-only) ; **ce pack** est **prescriptif** (il dit **comment**
implémenter AD-7/AD-6/AD-2/F-01/F-03, les entités AD-15 et l'offline first-class).

*Pack 03/16. Dimensions consommantes : `02-frontend.md` (state UI + use-cases + états UX),
`01-backend.md` (RLS + vues + jobs). Le sync est **la dimension qui relie** les deux : le store
local **est** le point d'accès UI (AD-7), les vues/RLS **sont** le contrat serveur (AD-2/AD-6).*
