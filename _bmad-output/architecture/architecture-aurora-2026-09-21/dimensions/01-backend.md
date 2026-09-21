---
name: "Aurora — Dimension Backend (pack de contrat, vague 0)"
type: dimension-pack
altitude: initiative
companion-of: ARCHITECTURE-SPINE.md (autorité, read-only)
sources:
  - ARCHITECTURE-SPINE.md (AD-1…AD-16, statut final, 2026-09-21)
  - adr-extract.md (ADR v1.7 gelé)
  - reviews/review-adversary.md (trous F-01…F-10 comblés dans le spine)
status: wave-0-draft
created: 2026-09-21
owner: équipe Backend + Data (Foundation)
binds: "packages/domain, packages/data, Supabase (PostgreSQL/Auth/Edge Functions), Cloudflare R2"
---

# 01 — Dimension BACKEND

> Ce pack est **prescriptif** pour les agents de développement : il référence le spine (AD-x) sans le répéter, et l'approfondit là où le spine reste volontairement silencieux (spine § Deferred : RLS, valeurs d'environnement, mapping AD-15). Tout identifiant de code est en anglais, le contenu en français. Les AD-x citées sont contraignantes.

---

## 1. Périmètre et objectifs

**Périmètre serveur d'Aurora** (mobile-only Phase 1, AD spine § Stack) :

- **Supabase** = le seul backend métier : PostgreSQL (source transactionnelle, AD-6), Auth, Edge Functions, Cron. Cloudflare n'est jamais un second backend métier (ADR §2 v1.6 « Supabase reste le backend transactionnel ; Cloudflare n'est pas un second backend métier ») — R2, AI Gateway et Workers AI y vivent en tant que *fournisseurs* derrière des ports (AD-1, AD-16c).
- **Cloudflare R2** = stockage de fichiers (bucket privé + URLs présignées, AD-16) : documents de connaissance, artefacts générés, assets d'export (SVG/PNG des infographies).
- **Modules métier** hébergés côté serveur dans le monolithe (une unité déployable, spine § Design Paradigm) : Identity, Productivity, Learning, Knowledge, Discovery, Progress, Agent, Scientific, Artifact, Integrations.
- **Système de jobs persistés** (AD-8) : Supabase Cron → dispatcher Aurora → jobs persistés → Edge Functions/Workers.
- **Couches IA côté serveur** (AD-3, AD-4, AD-5, AD-12F-09) : Context Builder, Task Classifier, AI Router, AI Policy/Budget, Model Registry, gateway/adapter — le client ne voit que le contrat normalisé `AIProvider`.
- **Event History** (AD-6) : conservation des événements V1 pour progression/audit, sans Event Sourcing.

**Objectifs opérationnels du pack** :
1. Trancher la Open Question du spine : **RLS comme mécanisme d'application AD-2 au niveau données** (tranchement en § 2.2 ci-dessous).
2. Figer l'architecture des jobs (tables, dispatcher, retry/backoff, idempotence, observabilité) — le spine dit « quoi » (AD-8), ce pack dit « comment ».
3. Définir les contrats d'entrée/sortie des Edge Functions (enveloppes normalisées, AD-16 § Consistency Conventions).
4. Trancher le split serveur d'AI (AD-4/AD-5) : qui héberge quoi, où vivent registres et clés.
5. Donner à la vague 0 les données manquantes : schémas de données (niveaux entités/relations, pas de DDL), strategy RLS complète, plan R2 (buckets/naming/présignation).

**Hors périmètre de ce pack** (renvoyés à d'autres dimensions) : PowerSync scopes côté client/lectures (AD-7 — mais leurs *vues SQL côté serveur* font partie de `packages/data`, voir § 3.4), design system, écrans, Electron Phase 2, microservices (exclus V1, spine § Deferred).

## 2. Modules / packages concernés (AD-13, AD-15, AD-16)

### 2.1 Mapping module → périmètre serveur

Le découpage package exact est en [ASSUMPTION] du spine (à ratifier en vague 0 avant la coupe des packs). Ce pack en reprend la graine structurelle et précise le périmètre **serveur** de chaque module métier :

| Module | Périmètre serveur (tables + Edge Functions + jobs qu'il possède) |
| --- | --- |
| **Identity** | Profil utilisateur (`profiles`, préférences, `UserContext`, autorisations de coaching — cadence, silencieux, niveau d'intervention ADR §13), liaison Supabase Auth ↔ profil. **Writer unique de `user_context`** (règle AD-15, mapping `03-sync` § 4.2 : entité `UserContext` → module owner Identity, table locale `user_context`). |
| **Productivity** | `tasks`, `projects`, `goals`, `milestones`, `habits`, `routines`, `focus_sessions`, `decisions`, agenda/time-blocking, récurrences, dépendances. Producers d'événements : `TaskCompleted`, `GoalUpdated` (AD-9). |
| **Learning** | `courses`, `subjects`, `skills`(définitions), `learning_sessions`, `reviews`, flashcards + paramètres FSRS par carte (state machine `due`/`stability`/`difficulty` — l'algorithme FSRS s'exécute côté serveur, pas sur l'appareil), import de cours. Producer : `CourseImported`, `FlashcardReviewed` (AD-9). |
| **Knowledge** | `semantic_nodes`, `semantic_edges`, `semantic_bridges`, `node_state`, `semantic_tree_version` (table de Knowledge, AD-6/F-10), `documents` (métadonnées ; les fichiers vivent dans R2), index FTS + pgvector (chunks + embeddings), `source_refs`. **Seul writer de `NodeState`** (AD-6). |
| **Discovery** | `discovery_items`, `gaps`, profil de découverte dynamique (ADR §13.1), analyse d'écarts, historiques de veille. Déclare ses consommateurs d'événements (AD-9/AD-13). |
| **Progress** | `progress_snapshots`, `progress_evidences`, `skill_states`, `progress_events` (Event History propriétaire), `progress_trends`, `trajectory_scenarios`, `gaps`. **Seul producer de `ProgressEvidenceCreated` et `SkillStateChanged`** (AD-9, F-07) ; n'écrit JAMAIS les tables Knowledge (AD-2). |
| **Agent** | Orchestration **côté serveur uniquement** (AD-12/F-09) : exécutions du kernel (`agent_runs`, étapes du loop), Context Builder, Task Classifier, plans, actions, vérifications. Émet uniquement des commandes/événements vers les modules owners ; ne mute jamais leurs tables (AD-2, AD-7 single-writer). |
| **Scientific** | Exécution de calculs déterministes/scientifiques en **job persisté** (AD-8) ; moteur interchangeable derrière le port `ScientificEngine` (AD-1). |
| **Artifact** | `artifacts` (métadonnées) + **upload R2** ; **producer d'`ArtifactGenerated` uniquement post-upload-R2** (AD-9, F-06). Contrats `ObjectStorage`/`ArtifactProvider` implémentés ici côté serveur. |
| **Integrations** | `integrations`, `connection_states` ; adapter Composio derrière `IntegrationProvider` (AD-1). NotificationProvider = OneSignal (mobile Phase 1). |
| **Foundation (owner infra, AD-16)** | `jobs`, `job_logs`, `model_registry`, `ai_usage`/`ai_health` (§ 4.10), tables d'observabilité (§ 4.3) ; provision des vues PowerSync (AD-7) hébergées par `packages/data` ; propriétaire des comptes fournisseurs et clés CI/CD. |

### 2.2 Tranchement RLS — Open Question du spine, tranchée ici

**Décision : RLS EST le mécanisme d'application d'AD-2 au niveau données.** Justification : l'ADR dit « contracts » au niveau module ; au niveau données, le seul mécanisme natif disponible dans l'enveloppe Supabase est le Row Level Security. RLS ne remplace PAS les contrats (AD-2) : un module ne lit les types publics d'un autre module (AD-2, partie lisibilité) qu'en ayant une RLS policy explicite l'y autorisant.

Règles figées :

1. **Bascule globale** : `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` sur TOUTES les tables métier ; `FORCE ROW LEVEL SERVICE ROLE` sur le rôle `service_role` — la clé service (job dispatcher, Edge Functions, sync engine PowerSync) passe toujours par les policies.
2. **Isolement par utilisateur** : chaque table expose `user_id uuid`; policies par défaut = accès strictement aux lignes de `auth.uid()`. Supabase Auth est l'identité canonique (OAuth Google + e-mail/mot de passe pour V1 ; SSO hors V1). **Accès service_role** : les policies du rôle `service_role` (dispatcher de jobs, sync engine PowerSync, Edge Functions de service) sont autorisées **par paramètre SQL de la policy** (ex. `FOR service_role USING (user_id = auth.uid() OR user_id IN (SELECT target_user_id FROM job_queue WHERE ...))` selon le contexte) — **jamais par `GRANT` ad hoc, jamais par `BYPASSRLS`, jamais par paramètre JSON non auditée** ; le paramètre SQL porte **obligatoirement** un identifiant bornant (`user_id` et/ou `job_id`) ; chaque policy service_role porte une justification commentée dans la migration (test RLS § 2.2.5 : une policy service_role sans bornes par `user_id`/`job_id` = **bug bloquant**).
3. **Module boundaries en données** : les policies de LECTURE inter-modules sont créées **par module owner** dans ses propres migrations (un module ne modifie jamais les policies de tables d'un autre module — cohérent AD-2/AD-13). Un scope PowerSync n'joint JAMAIS les tables internes d'un autre module (AD-7) ; ce que le scope expose est donc borné par les politiques RLS du scope.
4. **Aucune policy permissive par défaut** : pas de policy `USING (true)` hors tables publiques explicites (aucune pour V1). Toute nouvelle table sans policy = bug bloquant (le Codex review § 21.6 du doc ADR l'a prévu : « problems of security, RLS, secrets, permissions »).
5. **Tests RLS obligatoires** : une suite de tests de pénétration RLS (utilisateur A ne voit pas les lignes d' utilisateur B, sur chaque table ; service_role via policy, pas via `BYPASSRLS`) fait partie de la DoD Data (AD-13 § 7 ci-dessous).

### 2.3 Ownership des packages (rappel AD-13/AD-15, graine § Structural Seed du spine)

- `packages/domain` : **SSoT unique des types de domaine frozen** (AD-15, F-01) — entités + enums + contrats d'événements (payloads TS). Tout le monde **consomme** ce package ; personne ne redéclare. Les vues/projections (Context Builder, dashboards) sont des *vues déclarées* des types partagés (AD-15).
- `packages/data` : repositories, schéma/PowerSync, migrations, `model_registry` (owner AD-16b), vues PowerSync côté serveur (owner AD-7, provisionnée en vague 0).
- Backend (monolithe) : les modules ci-dessus (§ 2.1) vivent dans le même déploiement ; **une unité déployable** (spine § Design Paradigm). Vague 0 ratifie l'arbre exact du pnpm (spine Open Question #1).
- Interdictions (AD-1, AD-2, AD-13) : aucune import de SDK fournisseur (ni `@supabase/supabase-js`, ni SDK R2/AI) dans le code du domaine/application ; aucun module n'écrit les tables d'un autre ; toute dépendance additionnelle exige justification + revue (spine § Consistency Conventions, Forbidden).

## 3. Contrats (interfaces TS publiques + événements)

### 3.1 Enveloppes normalisées de réponse (Consistency Conventions du spine)

Toute Edge Function et toute réponse de fournisseur externe (AI, R2, Composio…) retourne un **envelope normalisé** — le domaine ne voit jamais une erreur brute de fournisseur (AD-1) :

```ts
// packages/domain — SSoT (AD-15)
type ApiEnvelope<T> =
  | { ok: true; data: T }
  | { ok: false; error: ApiError };

type ApiError = {
  code: string;            // machine-readable, prefixé par module : "productivity/task_not_found"
  message: string;         // lisible, sans données sensibles
  details?: Record<string, unknown>;
};

// Envelope de réponse AI (consistency convention « provider, model, attempt, reason, expected quality »)
type AIResponseEnvelope = {
  provider: string;
  model: string;
  attempt: number;
  reason: 'primary' | 'fallback' | 'last_resort';
  expectedQuality: 'full' | 'degraded';
  fallbackUsed: boolean;
  traceId: string;
};

// AppError (SSoT `packages/domain`, AD-15 — le type consommé par l'UI, pack 02 §10 ; la SSoT de
// `AppError`/`AppErrorCode` vit dans `packages/domain`, owner Foundation, jamais ré-déclaré ici)
```

### 3.2 Contrats des ports côté serveur (AD-1 ; les implementations vivent dans le monolithe, les contrats dans `packages/domain`)

```ts
// Storage — implémentation R2 (Artifact module, AD-16 owner Foundation)
interface ObjectStorage {
  put(key: string, body: Uint8Array | string, type: string): Promise<ObjectMeta>;
  get(key: string): Promise<Uint8Array>;
  delete(key: string): Promise<void>;
  presignGet(key: string, ttlSec: number): Promise<PresignedUrl>;
  presignUpload(key: string, ttlSec: number, sizeBytes: number): Promise<PresignedUrl>;
}

// AIProvider — normalisé (AD-3 : le client ne voit que ce contrat)
interface AIProvider {
  complete(req: AIRequest): Promise<AIResponseEnvelope>;
  stream(req: AIRequest, sink: ChunkSink): Promise<AIResponseEnvelope>;
}
```

Les autres contrats internes (ADR §8 : `ResearchProvider`, `IntegrationProvider`, `ArtifactProvider`, `ScientificEngine`, `NotificationProvider`, `KnowledgeBase`, `JobRunner`, `FocusController`, `DocumentScanner`, `OCRProvider`, `TranscriptionProvider`, …) sont définis par leurs modules owners respectifs ; ce pack impose seulement la **règle** (AD-1) : aucun code métier n'importe un fournisseur directement, et les capacités optionnelles dégradent proprement quand leur provider est absent (spine § AD-1, last paragraph).

### 3.3 Événements — matrice normative (AD-9, figée par F-04)

Vocabulaire V1 (9 événements, spine AD-9). Chaque événement a **un seul producer** et un **ensemble déclaré de consumers** (AD-9) ; un module consomme uniquement s'il déclare le consommateur dans son Contract Pack (AD-13/F-04). Payloads TS en `packages/domain` (AD-15) :

| Événement | Producer (unique) | Consumers autorisés (déclarés) | Contrat minimal du payload |
| --- | --- | --- | --- |
| `TaskCompleted` | Productivity | Progress, Learning, Agent | `{ taskId, userId, completedAt, evidenceRefs?: string[] }` |
| `CourseImported` | Learning | Knowledge, Discovery, Progress | `{ courseId, userId, source, importedAt }` |
| `FlashcardReviewed` | Learning (FSRS) | Progress | `{ cardId, userId, rating, nextDueAt, fsrsState }` |
| `ProgressEvidenceCreated` | **Progress uniquement** | Knowledge (`NodeState`), Agent (contexte) | `{ evidenceId, userId, skillId?, goalId?, type, level, confidence, sourceEventId }` |
| `SkillStateChanged` | **Progress** | Agent, Discovery, Learning | `{ skillId, userId, newState, freshness, confidence }` |
| `GoalUpdated` | Productivity | Progress, Agent | `{ goalId, userId, changedAt, fields: string[] }` |
| `ArtifactGenerated` | **Artifact (après upload R2 uniquement, F-06)** | Knowledge (`SourceRef`), Learning (preuve) | `{ artifactId, userId, kind, r2Key, sizeBytes, generatedAt, jobId }` |
| `JobCompleted` | Job system | Artifact, UI | `{ jobId, jobKind, userId, status, result? }` — **`jobId`+`jobKind` obligatoires (F-08)** |
| `DiscoveryItemCreated` | Discovery | Learning, Knowledge, Progress, Agent | `{ discoveryItemId, userId, topic, sources, createdAt }` |

Règles supplémentaires (spine AD-9) : Learning ne crée JAMAIS directement de ligne `ProgressEvidence` (F-07) ; le kernel n'émet JAMAIS `ArtifactGenerated` (il demande la génération, F-06) ; le payload `JobCompleted` opaque sans `jobId`/`jobKind` (F-08). **Transport V1** : événement = insertion dans la table `events` du module producer (Event History, AD-6) ; les consumers déclarés l'observent (trigger Postgres → job ou requête incrémentale `since_event_id` en job périodique, § 4.4). Pas de broker (Kafka, etc.) en V1.

### 3.4 Vues PowerSync côté serveur (AD-7, owner `packages/data`)

- Toutes les vues PowerSync sont **déclaratives** : `CREATE VIEW` / `SELECT` read-only ; le sync engine PowerSync (composant Supabase) lit avec `service_role` — donc **via les policies RLS du service_role**, pas en contournant.
- Un scope = une vue unique d'un module owner ; un scope **n'joint jamais** les tables internes d'un autre module (AD-7) ; les besoins de lecture inter-modules passent par une **vue publique du module source** (le module expose `SELECT` sur ses types publics + policy `service_role`).
- Conflit : server-wins + timestamp serveur par entité (AD-7) ; listes nécessitant merge = CRDT ; chaque entité porte `updated_at` serveur comme horodatage canonique.
- `packages/data` possède TOUTES les vues, provisionnées en vague 0 (AD-7 last sentence) ; aucun autre team n'ajoute de vue sans PR (spine § Consistency Conventions).

## 4. Schémas de données (entités + relations, sans DDL — spine § Deferred)

Nommage SQL snake_case ; tous les ids = `uuid` (pgcrypto/gen_random_uuid) ; tables métier dans schema public ; `user_id uuid` + FK sur `auth.users` sur toute table ; audit minimal `created_at`, `updated_at` sur toute table mutable ; toutes les tables en `ALTER ... ENABLE ROW LEVEL SECURITY` (AD-2.2). Les shapes canoniques restent en TS dans `packages/domain` (AD-15) ; SQL est la persistance de ces types, pas une redéclaration.

### 4.1 Productivity
- `tasks` (id, user_id, project_id?, goal_id?, subject, description?, status, priority, importance, due_at?, recurrence_rule?, dependencies[], energy, work_context, actual_minutes, …) — statuts : `todo, doing, blocked, done, cancelled`.
- `projects`, `milestones` (FK project), `goals` (FK user; horizon: short/mid/long), `habits`, `routines` (temporal anchors), `focus_sessions`, `decisions`.
- Relations : goal → project → task (hiérarchie doc §2.6) ; task → project/skill/subject (multi-attachements par table de jonction) ; `focus_sessions.task_id` optionnel.
- Unicité : récurrence dérivée = lignes matérialisées (pas de règle récurrente) pour rester compatible PowerSync (AD-7) ; chaque occurrence a une identité stable.

### 4.2 Learning
- `courses`, `subjects`, `skills` (définitions canoniques, owner Learning), `learning_sessions`, `reviews`, `flashcards` (+ colonnes d'état FSRS par carte : `stability`, `difficulty`, `due`, `last_reviewed_at`), `course_imports`.
- `flashcards.course_id`; `learning_sessions.course_id?/skill_id?`; relation subject ↔ skill par table de jonction.
- L'algorithme FSRS s'exécute côté serveur (job ou transaction) ; l'appareil lit l'état via PowerSync (AD-7 single-writer : seule Learning mute l'état FSRS).

### 4.3 Knowledge (AD-6, §25 du doc ADR)
- `semantic_nodes` (id, user_id, kind [principle|domain|subject|concept|law|formula|method|example|application|skill], label, summary?, body?, parent_id?, domain_path, embedding vector, source_ref_ids[]), `semantic_edges` (source_node, target_node, relation [depends_on|is_a_case_of|deepens|applies|leads_to]), `semantic_bridges` (inter-domaines, explicitly annotated, secondaries), `node_state` (node_id, state [collapsed|expanded|selected|focused|mastered|fragile|forgotten] — **owner Knowledge uniquement, AD-6**), `semantic_tree_version` (version, created_at, diff_json — **table de Knowledge, AD-6/F-10** ; la Event History de Progress ne la double JAMAIS).
- `documents` (id, user_id, title, mime_type, r2_key, size_bytes, sha256, status) ; `document_chunks` (document_id, chunk_index, text, embedding) + index FTS (pg_trgm/GIN) + pgvector ; `source_refs` (entity, entity_id, source document_id?, page?, passage?, kind).
- Provenance obligatoire (spine §14 AD-11 : traceability) : chaque concept porteur pointe vers `source_refs`.

### 4.4 Progress (ADR §18.8 — modèle de données conceptuel)
- `progress_snapshots` (user_id, taken_at, payload), `progress_evidences` (user_id, skill_id?/goal_id?, type, level, date, freshness, context, confidence) — **owner Progress (F-07)** ; `skill_states` (user_id, skill_id, level, freshness, confidence, last_evidence_at), `progress_events` (**Event History** : appends-only, audit/progression, AD-6), `progress_trends` (user_id, period, dimension, value), `trajectory_scenarios` (user_id, base_snapshot_id, hypotheses[], actions[], expected).
- `gaps` (user_id, kind [academic|skill|tech|methodology|portfolio|ve|depth], description, evidence_refs[], detected_at, status) — partagé Progress/Discovery : les **définitions** de Gap sont en `packages/domain` (AD-15) ; le module owner des lignes `gaps` est **Progress** (cartographie §13.4 du doc, consommé par Discovery pour l'analyse d'écart — Discovery **lit** via vue publique, n'écrit pas).

### 4.5 Discovery
- `discovery_items` (user_id, title, question, why_now, factual_summary, sources[], kind [scientific|professional|innovation|trend|uncertain], status), `discovery_source_profiles`, `domain_timeline` (historique vivant, doc §13.6).
- Profil de découverte dynamique (§13.1) = **vue déclarée** des types partagés (skills de Progress, goals de Productivity, cours de Learning) — JAMAIS de recopie des niveaux de compétence (collision F-04, tranchée par AD-15).

### 4.6 Artifact / R2 metadata
- `artifacts` (user_id, kind [pdf|docx|pptx|xlsx|image|audio|video|markdown|latex|other], title, mime_type, r2_key, size_bytes, source_event_id? (jobId/provenance), context (task_id?, course_id?), status [queued|generating|uploaded|failed|expired]).
- Uniquité : `ArtifactGenerated` (AD-9) émis **après** upload R2 confirmé (F-06) — c'est le signal pour Knowledge (`SourceRef`) et Learning (preuve).

### 4.7 Agent / Intégrations
- `agent_runs` (user_id, intent, status, steps_json [étapes du loop], started_at, completed_at, budget_snapshot), `agent_actions` (run_id, kind, target_module, payload, result_status, trace_id) ; le kernel **émet** commandes (Action), le module owner **applique** (AD-7 single-writer, AD-12/F-09).
- `expert_skills` (owner Agent, self-improvement ADR §14 : déclencheur, objectif, procédure, contraintes, confiance, source, statut [candidate|validated|deprecated], valid_at) — **côté serveur uniquement** (mémoire de l'agent n'est PAS synchronisée sur l'appareil).
- `integrations` (user_id, provider, connection_state, token_ref — les tokens Composio vivent dans le secret storage Supabase, JAMAIS en clair dans les tables ; AD-3).

### 4.8 Event History (AD-6)
- Table `events` : append-only, consommée par les declared consumers (AD-9). Champs : `id` (ULID chronologique), `event_type`, `payload jsonb`, `user_id`, `producer` (module), `occurred_at`, `processed_at` (par consumer, optionnel via `event_consumptions`). Rétention : **2 ans** (progression multi-années, ADR §18.2 — au-delà = archive).
- AD-6 exclut l'Event Sourcing complet : `events` est une **mémoire d'audit/progression**, PAS la source de vérité des entités (PostgreSQL reste source transactionnelle, AD-6).

### 4.9 Système de jobs (AD-8) — détail en § 5

### 4.10 Enregistre de modèles (AD-5, AD-16b, owner `packages/data`)
- `model_registry` (provider, model, capabilities [reasoning|tool_calling|vision|audio|long_ctx], status [active|cooldown|retired], quota, data_policy, cost_class, version, evaluated_at) — **owner unique = Foundation/`packages/data` (AD-16b)** ; c'est l'UNIQUE entité qui peut **retirer automatiquement** un provider (AD-5).
- `ai_usage` (provider, model, env, user_id?, tokens, latency_ms, cost, free_tier_remaining) — alimente `AIBudgetManager` et l'observabilité des free tiers (AD-5 : free tiers = capacités, pas SLA).
- `ai_health` (provider, model, status [active|degraded|cooldown|retired], error_rate, last_error_at, last_429_at, cooldown_until, ok) — alimente `AIFallbackStrategy` (ADR §10.6) ; **règle d'alimentation figée** : c'est l'`AIUsageTracker` (pack 01 § 5.6, owner `packages/data`/Foundation) qui écrit `ai_health` à chaque réponse de provider (fenêtre glissante, agrégation périodique par `provider`/`model`), jamais un module feature ; `AIFallbackStrategy` **lit** uniquement (AD-5 : la décision de fallback/cooldown est dérivée de cet état, pas recalculée localement par les équipes).

## 5. Décisions d'implémentation

### 5.1 Edge Functions — catalogue et contrat d'entrée/sortie

Chaque Edge Function = contrat HTTP JSON avec l'envelope normalisé (§ 3.1) ; authentification par Supabase Auth (JWT) ou par API key de service interne (jamais les deux publics). Tout travail lourd (OCR, transcription, génération d'artefact, recherche, calcul scientifique, planification agentique) **ne se termine JAMAIS dans une Edge Function** (AD-8) : la Edge Function **crée un job** et retourne `202 + jobId`.

| Fonction | Entrée | Sortie | Notes |
| --- | --- | --- | --- |
| `fn-agent-run` | `{ intent, contextRefs[], taskProfile }` | `202 { ok, data: { jobId } }` | Le kernel tourne **côté serveur** (AD-12/F-09) ; le client ne fait que lire l'état UI. |
| `fn-generate-artifact` | `{ kind, sourceRefIds[], spec }` | `202 { jobId }` → `ArtifactGenerated` (AD-9) après R2 upload (F-06). |
| `fn-import-course` | `{ courseId, fileRefs[] }` | `202 { jobId }` → `CourseImported`. OCR + chunking + embedding en jobs (AD-8). |
| `fn-research` | `{ query, sources[], maxDepth }` | `202 { jobId }` → `DiscoveryItemCreated`. Via `ResearchProvider` (You.com, Tavily, Exa) — job persisté, jamais en request/response. |
| `fn-science-compute` | `{ expression, units, taskSpec }` | `202 { jobId }`. Moteur interchangeable derrière `ScientificEngine` (AD-1, AD-10). |
| `fn-fsrs-tick` | (cron déclencheur) | recalcule les `due` d'ensemble (batch quotidien). |
| `fn-powersync-sync` | (composant PowerSync) | lit les vues § 3.4 avec service_role + policies. |
| `fn-notifications` | (trigger `events`) | OneSignal (mobile Phase 1) ; respect des silencieux de coaching (ADR §13). |

### 5.2 Cron → Dispatcher (AD-8, figé du doc §21 et §7 v1.6)

- **Supabase Cron** (fonctions de déclenchement pures, court) → insère une ligne dans la table `job_queue` (ci-dessous) → **Aurora Job Dispatcher** = la fonction Edge Function `fn-job-dispatcher` (contrat figé ci-dessous ; déclenchée par Supabase Cron et par trigger Postgres sur `job_queue`) → distribue les jobs vers les Edge Functions/Workers de travail. Les déclencheurs du dispatcher sont **exclusivement** (a) Supabase Cron et (b) le trigger Postgres sur INSERT `job_queue` — toute autre source de déclenchement = violation AD-8.
- **Contrat du dispatcher (figé, une seule implémentation possible)** : le dispatcher est **une** fonction Edge Function `fn-job-dispatcher` — **pas** un second système de déclenchement : les déclencheurs autorisés sont **exclusivement** (a) Supabase Cron (insertion dans `job_queue`) et (b) un trigger Postgres sur INSERT dans `job_queue`. Le dispatcher **ne crée pas** de job (création = les Edge Functions métier, § 5.1) ; il **distribue uniquement** : pour chaque ligne `job_queue.pending` (tri par `due_at`, `user_id`), il envoie le payload vers le worker correspondant au `kind` (Edge Function de travail ou Cloudflare Worker) et met à jour `status`/`attempts`/`updated_at`. API interne du dispatcher (contrat partagé, owner Foundation) :

  ```ts
  // Contrat du dispatcher (fn-job-dispatcher, owner Foundation)
  type DispatcherApi = {
    dispatchDue(now: Date, limit?: number): Promise<{ picked: number; skipped: number }>; // appelé par Cron / trigger
    claimJob(jobId: string, workerKind: string): Promise<{ ok: boolean; payload?: JobPayload }>; // worker : prend possession (status 'running')
    reportResult(jobId: string, result: { status: 'done' | 'failed'; result?: unknown }): Promise<void>; // worker → worker emit JobCompleted (F-08)
  };
  // Règle de mapping `kind` ↔ `workerKind` : `workerKind = job_queue.kind` (les payloads `JobCompleted`/
  // `ArtifactGenerated` portent `jobKind` = la même valeur de `job_queue.kind`, F-08 ; un seul
  // vocabulaire de kinds, défini dans `packages/domain` (AD-15) — pas de seconde nomenclature).
  ```
- **Pas d'auto-appel du cron qui exécute du travail** : le cron déclenche uniquement le dispatcher ; le travail n'existe que comme job persisté (AD-8, « persisted, idempotent, retryable, observable »).
- Jobs déclenchés par événements (triggers Postgres sur tables clés, e.g. `flashcards` → `fsrs-tick`, `progress_evidences` → recompute `skill_states`) passent par le même `job_queue`.

### 5.3 Schéma jobs (table `job_queue` + `job_logs`)

```ts
// job_queue (owner : Foundation, AD-16)
{
  id: string;              // ULID (tri chronologique)
  user_id: string;
  kind: string;            // "ocr" | "transcription" | "artifact_gen" | "research" | "science" | "fsrs_tick" | "agent_verify" | …
  payload: Json;
  status: "pending" | "running" | "done" | "failed" | "cancelled";
  attempts: number;
  max_attempts: number;
  backoff_ms: number;
  due_at: Date;
  idempotency_key: string; // UNIQUE (job_kind + hash du payload logique + user_id) ; si le job est
                           // déclenché par une mutation locale (re-sync, pack 03 §5.5), le champ
                           // `source_local_mutation_id` (ULID, pack 03) entre dans le hash : un
                           // re-sync répété ne double-ajoute JAMAIS le même job client-originé.
  result?: Json;
  created_at: Date; updated_at: Date;
}

// job_logs
{ job_id, ts, level, message, data?, trace_id }
```

- **Idempotence** : clé d'idempotence = `(job_kind, hash du payload logique + user_id)` — un ré-essai du même job ne **ré-exécute pas** le travail ; la worker vérifie d'abord si un `done` avec la même clé existe (ou si l'effet est déjà atomiquement persisté). Les `jobId`/`jobKind` apparaissent dans le payload de `JobCompleted` (F-08) et dans `ArtifactGenerated` (`jobId`). **Mapping des noms** : `jobKind` (dans les payloads d'événements) = `job_queue.kind` (champs) — **une seule nomenclature** de kinds, figée dans `packages/domain` (AD-15) ; les deux ne sont pas deux dictionnaires indépendants.
- **Retry/backoff** : backoff exponentiel (base 30 s, facteur 2, plafond 15 min, jitter) ; **retry uniquement sur pannes transitoires** ; **fallback** (changement de provider) sur indisponibilité/incompatibilité/limite atteinte — règle AD-5 figée ; **un `429` n'est JAMAIS contourné par rotation de clés ou de comptes** (AD-5) ; `max_attempts` par kind (par défaut 5 ; 1 pour les `agent_verify` critiques — un échec passe en `failed` + alerte, pas en retry illimité).
- **Timeouts** : chaque job a un budget d'exécution maximal (par kind) ; dépassement = `failed` + observabilité, pas de silence.
- **Observabilité** : `job_logs` + Sentry (erreurs, contextes par job) + PostHog (télémétrie d'usage) ; SLO par job (job_kind, latence cible, taux d'échec) ; **duty owner = Foundation jusqu'à ce qu'un module ait du trafic mesurable** (AD-16d). Dashboard d'alerte : `pending age > due_at + 5min` et `failed after max_attempts`.
- **Périmètre interdit** : aucun job ne mute une table d'un autre module (AD-2) ; le worker exécute des **commandes** du module owner (par ex. le job d'OCR écrit dans `documents`/`document_chunks` = owner Knowledge), jamais dans les tables de Productivity ou Learning.

### 5.4 R2 — buckets, nommage, URLs présignées (AD-16 owner Foundation)

- **Buckets** (structure AD-16a ; les noms concrets sont les données de vague 0) : UN bucket **par environnement** = `aurora-files-dev`, `aurora-files-staging`, `aurora-files-prod`. **Aucun autre bucket** (AD-16 : aucune équipe feature ne crée de bucket).
- **Policy de confidentialité** : bucket **privé** ; **aucun accès public direct** (stack du spine : « Cloudflare R2 (private bucket + presigned URLs) »).
- **Key naming convention** (stable, versionnée en `packages/data`), par domaine :
  - Documents (connaissance) : `documents/{user_id}/{document_id}/{sha256}`
  - Chunks d'embeddings : pas de stockage R2 (Postgres, § 4.3)
  - Artéfacts générés : `artifacts/{user_id}/{artifact_id}/{kind}.{ext}`
  - Fichiers uploadés par l'utilisateur (resources) : `resources/{user_id}/{resource_id}/{sha256}`
  - Assets d'export (SVG/PNG d'infographies) : `exports/{user_id}/{job_id}/{file}.{ext}` (cas « Design System → R2 staging » de la paire F-05, résolu : le bucket existe déjà, aucune équipe ne crée le sien)
- **Presigning (AD-16, owner Foundation)** : les URLs présignées ne sont **JAMAIS** émises par le client avec une clé — la Edge Function (rôle service) signe : `presignGet` (lecture : téléchargement/preview, TTL 15 min), `presignUpload` (upload : le client poste directement sur R2, TTL 5 min, taille annoncée ; **seul l'Artifact module** écrit dans le bucket — AD-2 « un module n'écrit pas dans les tables d'un autre » s'étend au bucket : seules les Edge Functions du monolité + le client via presigned upload (contrôlé par l'Artifact) y écrivt). Les clés R2 ne vivent **JAMAIS** sur l'appareil (AD-3) — l'appareil ne reçoit que des URLs présignées éphémères.
- **Intégrité** : `sha256` du fichier stocké dans `documents`/`artifacts` ; vérification à l'upload (job) ; expiration des URLs = `ArtifactGenerated` après confirmation R2 (F-06, § 3.3).

### 5.5 Event history (AD-6, § 4.8) — mécanique de delivery

- **Append-only** : les producers INSERT dans `events` (table du producer, AD-2) ; les consumers **déclarés** (AD-9/AD-13) observent via : (a) trigger Postgres → INSERT dans `job_queue` de type `event_dispatch` (job) pour les consommations asynchrones ; (b) polling incrémental par `since_event_id` (consommateurs qui tolèrent le léger delay).
- **Pas de re-persistance croisée** : un consumer **ne ré-écrit JAMAIS** un événement comme le sien (AD-2, last sentence) ; il peut consommer (lire + agir dans SES tables).
- **Rétention** : 2 ans (valeur de vague 0, cf. spine § Deferred « valeurs d'environnement »).

### 5.6 AI — split serveur (AD-4, AD-5, AD-16b, AD-12/F-09)

- **Placement figé** : Context Builder, Task Classifier, AI Router, AI Policy/Budget, Model Registry, Provider Adapters et **toute exécution IA** tournent **côté serveur** (jobs + gateway), jamais sur l'appareil (AD-3, F-09) ; l'appareil ne lit pas l'état UI (AD-7).
- **Clés et registres** : le **Model Registry** est une table Supabase + owner unique `packages/data`/Foundation (AD-16b) ; les **clés fournisseurs** (Agnes, Cloudflare, Groq, Cerebras…) vivent dans **Secrets du environnement Supabase** (ou Cloudflare Secrets Store pour les Workers AI Gateway), **JAMAIS** dans le code, **JAMAIS** sur l'appareil (AD-3).
- **Gateway** : la sortie IA passe par **Cloudflare AI Gateway** (contrôle, observabilité, caching, rate limiting, fallback) ; le **Worker de fallback** (Workers AI direct) ne porte **aucune logique métier** (AD-4 last-resort path ; ADR §4 v1.7) : normalisation req/resp + timeouts uniquement.
- **Fallback & quotas (AD-5)** : retry borné (panne transitoire) vs fallback (indisponibilité/incompatibilité/limite) ; **un `429` n'est JAMAIS contourné par rotation de clés/comptes** ; chaque réponse de fallback reste **traçable** (provider, model, attempt, reason, expected_quality — l'envelope `AIResponseEnvelope` § 3.1) ; le **Model Registry retire automatiquement** un provider qui devient indisponible/payant (AD-5, gated par l'owner unique AD-16b).
- **Free tiers = capacités, pas SLA** (AD-5, ADR §8) : les valeurs de registres par environnement (quotas, modèles) sont les **données de vague 0** (spine § Deferred), le **structure** (table registry + statut + quota + data_policy) est ici (AD-16a).
- **Data policy** : les providers déclarent leur `DataPolicy` dans le Model Registry (ADR §11 v1.7) ; la route de production peut **exclure** un free tier incompatible avec les besoins d'Aurora (ex. Mistral/OpenRouter free — ADR §11) ; les documents, cours, notes ne sont JAMAIS envoyés automatiquement vers un provider dont la politique de données est incompatible.
- **Budgets** : `AIBudgetManager` (ADR §9 contrats IA) : budget par provider/modèle/environnement/utilisateur ; arrêt avant dépassement (le job agentique reçoit un `budgetSnapshot` et s'arrête proprement, pas un cut-off en cours de génération).
- **Providers optionnels** (Groq, Cerebras, OpenRouter, Cohere, Mistral, Google) : branchés **derrière le même contrat `AIProvider`** (ADR §16 v1.7) ; aucun n'est une dépendance bloquante ; le Model Registry permet d'activer/désactiver **sans modifier le domaine** (AD-1).
- **Vérification des tâches critiques** : la `Verify` du kernel (KB/source + Scientific Engine) tourne en **job serveur persisté** (AD-8, F-09), JAMAIS sur l'appareil ; un second modèle « juge » est utilisé uniquement si la valeur de la vérification le justifie (ADR §14, v1.7).

## 6. États et gestion d'erreurs

- **Tous les heavy capabilities** (jobs, recherche, génération d'artéfact, calcul scientifique) exposent les états typés **`loading`, `empty`, `success`, `error`, `offline`** (spine § Consistency Conventions, AD-13 DoD) — l'État UI côté client reflète l'état du job (`pending`/`running` → `loading` ; `failed` → `error` avec `jobId` pour le retry) ; `offline` = mode local-first actif (AD-7 : **l'offline est un état de classe, pas une panne**).
- **Erreur par job** : `status: failed` + `job_logs` (Sentry) + `JobCompleted{status:failed, jobId, jobKind}` (le producer d'événements, AD-9, reste le système de jobs — pas chaque module) ; le **retry** est borné (exponentiel, § 5.3) ; le **fallback** de provider ne change JAMAIS le contrat de sortie (le domaine ne voit qu'un `AIResponseEnvelope`, § 3.1) ; une faute de **data policy** (provider exclut par AD-5/ADR §11) = `AIRequestGuard` rejette **avant** l'appel, avec une raison lisible (pas de fuite de contexte vers un provider incompatible).
- **Erreur d'authentification** : JWT Supabase expiré = refresh automatique ; échec d'Auth = redirection vers l'écran de login (l'appareil ne peut PAS appeler les Edge Functions sans identité — RLS § 2.2).
- **Dégradation propre** (AD-1, last paragraph) : OCR absent = le pipeline documentaire dégrade vers la saisie manuelle (pas de crash) ; TranscriptionProvider absent = la lecture audio fonctionne, le transcript est optionnel ; ResearchProvider = les résultats de recherche sont marqués `uncertain` (doc §13.2, « information encore incertaine »).
- **Conflit de conflit** (AD-7, server-wins + per-entity timestamp) : le conflit est résolu **silencieusement** par PowerSync (pas d'alerte utilisateur sauf collision sur des entités de type CRDT) ; le single-writer par entité (§ 2.3, AD-7) **prévient** les conflits, la résolution est le filet de sécurité.

## 7. Tests obligatoires (AD-13 DoD, par module Backend)

- **Test RLS de pénétration** (§ 2.2) : sur **chaque** table — utilisateur A ne lit/modifie pas les lignes d' utilisateur B ; service_role via policies, pas via `BYPASSRLS`. Bloquant, toute migration qui touche les policies.
- **Contrats d'événements (AD-9/F-04)** : (a) chaque event a **un** producer (test : un second producer même type = échec) ; (b) chaque declared consumer est **déclaré** dans le Contract Pack (AD-13) et **testé** (test : un non-déclaré consommateur = échec) ; (c) le `JobCompleted` sans `jobId`/`jobKind` est rejeté (F-08) ; (d) `ArtifactGenerated` émis **uniquement** après confirmation R2 (F-06) ; (e) Progress est **le seul** producer de `ProgressEvidenceCreated` (F-07).
- **Idempotence jobs (AD-8)** : un job ré-exécuté avec la même clé d'idempotence ne **double-pas** l'effet (insertion d'artefact, création de `discovery_item`, …). Test dédié par kind.
- **Retry/fallback (AD-5)** : (a) backoff exponentiel borné ; (b) un `429` déclenche le **cooldown** (pas rotation de clés) ; (c) le fallback est **traçable** dans l'envelope ; (d) la `AIUsageTracker` alimente `ai_usage` ; (e) le Model Registry peut **retirer** un provider (statut `retired`) sans casser le domaine (AD-1, test : le fallback path reste fonctionnel).
- **Single-writer (AD-7)** : test par entité locale — seule l'unité propriétaire mute ; le kernel ne mute JAMAIS une table (F-03 : le test est un échec si le `Action` du kernel écrit directement dans `tasks`).
- **PowerSync** (§ 3.4) : (a) les vues ne jointent JAMAIS les tables internes d'un autre module (test statique : un `JOIN` sur une table non-public = échec) ; (b) le server-wins + per-entity timestamp est déterministe (test : deux mises à jour concurrentes = le plus récent gagne) ; (c) les listes CRDT mergent sans perte.
- **Unité et domaine** : (a) `type-check` (zéro new violation de contrat AD-2 : les types inter-modules viennent de `packages/domain`, AD-15) ; (b) lint ; (c) tests unitaires par module (recommandation : ≥ 80% sur `packages/domain` et sur les event handlers) ; (d) build du monolithe (spine § Consistency Conventions : main buildable).
- **Observabilité (AD-8/AD-16d)** : (a) tout job terminé/échoué = une entrée dans `job_logs` + Sentry (le test vérifie le wiring) ; (b) les SLO par job_kind sont mesurables (test de la dashboard d'alerte) ; (c) Foundation est le duty owner (test d'opérationnel : l'alerte pointe vers l'équipe de Foundation).

## 8. Risques et dépendances

### 8.1 Dépendances (ordre de vague, AD-13/ADR §21.8)
- **Vague 0 (ce pack)** : `packages/domain` (SSoT AD-15, ratifié par la paire F-01), schéma SQL (AD-6/AD-15), policies RLS (§ 2.2), vues PowerSync (AD-7, owner `packages/data`), tables `job_queue`/`model_registry`, buckets R2 (noms concrets = données de vague 0), clés CI/CD (owner Foundation, AD-16c).
- **Vague 1 (Fondations)** : Auth Supabase, provision `packages/data`, implémentation R2 (`ObjectStorage`), dispatcher jobs + worker templates, gateway IA + adapter Agnes + adapter Workers AI (au moins 2 providers opérationnels, ADR §16 v1.7).
- **Vague 2 (Features)** : les modules (Productivity, Learning, Knowledge, Discovery, Progress) **consomment** les contrats de ce pack (jobs, événements, storage, AI) — ils **n'ont JAMAIS** à créer leurs propres buckets/clés/registres (AD-16).
- **Vague 3 (Agent)** : le kernel **côté serveur** (F-09) consomme `fn-agent-run` + AI Router ; les `Verify` critiques sont des jobs (AD-8, § 5.6).
- **BLOCANT** : le ratification pnpm (spine Open Question #1) + le mapping entité → package → équipe (AD-15, spine § Deferred) avant la découpe des packs Design System / Data / Agent (spine Open Question).

### 8.2 Risques (avec mitigations)
- **R1 (AD-8/AD-5) — free tiers flous / réversibles** : les quotas (snapshot 21 sept 2026) **changent sans préavis** ; le Model Registry **versionne** les états (vague 0 : structure de `ai_usage`/`ai_health` prête pour le drift, spine § Deferred « free-tier quotas ») ; mitigation : le test de « retrait de provider » (§ 7) est un **test récurrent** dans la CI, pas un test unique.
- **R2 (AD-2/AD-7) — RLS mal exprimé = fuite inter-utilisateurs** : une policy `USING (true)` par défaut = disaster ; mitigation : la revue Codex (ADR §21.6) **vérifie systématiquement** RLS (trou expressément listé) + le test RLS de pénétration **bloque** la PR (DoD § 7).
- **R3 (AD-9/F-04) — consumers non-déclarés / ré-persistance** : un module qui **consomme** un événement sans le **déclarer** dans son pack = violation AD-13 (trou expressément listé par le revue F-04) ; mitigation : le **test de déclarité** (§ 7) est **blocking**.
- **R4 (AD-8) — jobs qui échouent en silence** : un job bloqué en `pending`/`running` sans deadline = un travail **perdu** ; mitigation : le timeout **par kind** (§ 5.3) + SLO d'alerte (duty owner Foundation, AD-16d) + `JobCompleted` en échec (le UI peut le **re-essayer**, l'UI reste **honnête**).
- **R5 (AD-4/AD-5) — un seul pool gratuit (Workers AI 10 000 Neurons/jour)** : le **diminution silencieuse** des free tiers est le **risque principal de résilience** ; mitigation : (a) le fallback path est **testé** (§ 7, `AIUsageTracker` alimente les cooldowns) ; (b) le Model Registry **retire automatiquement** un provider **devenu payant** (AD-5, gated par l'owner unique AD-16b) ; (c) un **second provider opérationnel** (Groq/Cerebras branchés **dès qu'une clé est dispo**, ADR §16) est un critère de **ready-to-production** de la vague 1 (ne PAS une vague 3) ; (d) la `AIBudgetManager` arrête **avant** le dépassement.
- **R6 (AD-7) — conflits de PowerSync non prévus** : un **scope qui joint les tables d'un autre module** (trou F-03) ou un **single-writer violé** (le kernel mute directement) = des écrasements silencieux au re-sync ; mitigation : le **test statique** de vues (§ 7, `JOIN` sur non-public = échec) + le **test single-writer** (§ 7) + le `updated_at` serveur comme horodatage **canonique** (le client ne **date JAMAIS** ses propres mutations localement de manière à ce que le serveur **écrase** un `updated_at` plus ancien).
- **R7 (AD-16/AD-5) — registre de modèles **divergent** (un par équipe)** : le **trou F-05** du reviewer (buckets/clés par équipe) est **résolu** par l'AD-16 (owner **unique** = `packages/data` + Foundation) ; **le risque résiduel** : un team feature qui **ignore l'owner** et crée **son propre** registre/son propre bucket = violation **expressément** AD-16 (trou **expressément listé** dans la revue) ; mitigation : le **test de CI** (aucun nouveau bucket/registre dans les PRs feature = échec) + la **revoir** Codex (trou **expressément listé**, § 21.6 du doc ADR).

### 8.3 Ce qui reste ouvert (pour le team-lead)
- Les **noms concrets** des buckets (structure **fixée** ici, valeurs = vague 0) ; le **mapping final** entité → package → équipe (AD-15) ; le **ratification pnpm** (spine Open Question #1).

---
**Références** : spine (AD-1…AD-16, statut final 2026-09-21) ; ADR v1.7 (gelé, sections 7–26 + v1.6 + v1.5) ; revue adversariale (F-01…F-10, toutes **intégrées** dans le spine final). Ce pack **référence et approfondit** le spine (pas de **redondance** du contenu du spine) ; les **décisions contraignantes** restent dans le spine (read-only) ; **ce pack** est **prescriptif** (il **dit** comment **implémenter** les ADs du spine).
