# Cartographie Agentique-First — Aurora

**Principe (mission)** : Aurora est une app **agentique-first**. Tout est
pilotable **facilement et simplement dans le chat agentique**. Les UI manuelles
(dashboards, formulaires, menus) existent uniquement comme **fallback**
(AD-7 : l'app dégrade, ne casse jamais). L'utilisateur peut **toujours planifier
manuellement** — mais ce n'est que le plan B ; le plan A est « dis-le à l'agent ».

**Cartographie** : pour chaque feature, on montre ce qui est
**(a)** déjà faisable au module (use-case `packages/*`),
**(b)** branché au kernel (`packages/agent/src/tools.ts`, `KERNEL_TOOLS`),
**(c)** l'écart à combler. Les verbes de mission : **nommer / renommer /
créer / supprimer / verrouiller / programmer**.

Légende branchement :

- **CONNECTED** : l'outil kernel existe, émet la commande (AD-7) / le job
  (AD-8) au module qui applique. L'agent le fait.
- **MODULE-READY** : le use-case module existe, **pas encore** exposé en outil
  kernel → à brancher (écart faible, un thin emitter).
- **MISSING** : ni module ni kernel → à construire.
- **DESTRUCTIVE** : suppression → confirmation obligatoire (ADR §5).

---

## 0. Les 6 verbes transverses (vue mission)

Le cœur de « l'agent peut tout faire » = qu'il puisse les 6 verbes sur
**n'importe quelle entité**. Matrice verbe × entité :

| Verbe | Task | Goal/Projet | Habit | Agenda/Evénement | Focus | Automation (veille) | Canvas | Skill |
|---|---|---|---|---|---|---|---|---|
| **créer** | ✅ kernel | ✅ kernel | ⚠️ module | ✅ kernel | ✅ kernel (profil) | ❌ | ❌ | ✅ kernel |
| **renommer** | ⚠️ module (patch titre) | ⚠️ module (`updateGoal`) | ⚠️ module | ⚠️ module | ⚠️ module | ❌ | ❌ | ⚠️ module |
| **supprimer** | ❌ | ⚠️ `goal_abandon` (gel, AD-15) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **verrouiller** | ⚠️ status `blocked` | ✅ `goal_pause` | ⚠️ status | ⚠️ (pas de DND par év.) | ✅ `blockApps` (DPC) | ✅ `automation_toggle` off | ❌ | ✅ `skill_activate` off |
| **programmer** (cron/récurrent) | ⚠️ `nextRecurrence` (mat. rows) | ❌ | ⚠️ cadence daily/weekly/custom | ⚠️ `recurrence` | ❌ | ✅ `Automation`+`cron` | ❌ | ❌ |
| **déclencher** (ad hoc) | ✅ kernel | ✅ `review_run` | ✅ `habit_checkin` | ✅ `schedule` | ✅ `startFocus` | ✅ `research` | ❌ | ✅ `skill_activate` |

**Lecture** :
- **Nommer / déclencher / verrouiller** = quasi couvert → on expose des thin
  emitters au kernel (MODULE-READY).
- **Supprimer** = le vrai trou (AD-15 est additif : on **gèle** / abandonne,
  on ne supprime jamais d'origine ; un `*.delete` doit naître DESTRUCTIVE).
- **Programmer** = le mécanisme commun = `Automation` (cron/event/condition) ;
  c'est le socle du scheduling de veille (§2) ET de la planification récurrente
  (tâches/agenda/habits).

**Le fallback manuel** (plan B) : chaque verbe a déjà son équivalent UI
(dashboard Goals, page Tasks, Agenda FullCalendar, Skills marketplace,
Settings). L'agentique-first = l'agent couvre les mêmes surfaces ; l'utilisateur
reste libre de planifier à la main sans rien casser (AD-7).

---

## 1. Features par module — couverture agentique

### 1.1 Productivity (`packages/productivity`)

| Feature | Use-cases module (existant) | Branchement kernel | Écart à combler |
|---|---|---|---|
| **Tasks** | `createTask`, `setTaskStatus`, `completeTask` (mat. récurrence), `rescheduleTask`, `toggleSubTask`, `nextRecurrence` | `task_update` (create/update/complete/archive) | **renommer** (patch titre non exposé), **delete**, **récurrence via agent** |
| **Calendar / time-block** | `createEvent`, `rescheduleEvent`, `detectConflicts`, `planTimeBlocks`, `materializeRecurringEvent` | `schedule`, `planDay`, `planning_replan`, `pomodoro_schedule` | **renommer** un bloc, **récurrence récurrente**, **DND par événement** |
| **Goals / Projects / Milestones** | `createGoal`, `updateGoal` (patch), `GoalUpdated` | `goal_create/status/recompose/pause/complete/abandon`, `goal_feature_add/remove` | **renommer** (`updateGoal` existe, à exposer), **delete vs abandon** |
| **Habits / Routines** | `createHabit` (cadence daily/weekly/custom), `recordHabitCompletion`, `habitStreak`, `habitHeatmap`, `createRoutine` | `habit_checkin` (réactif seul) | **créer** habit/routine par l'agent, **programmer** sa cadence |
| **Focus sessions** | sessions, pomodoro, blocklist (DPC) | `startFocus`, `blockApps`, `focus_profile`, `focusSound`, `focus_sound_catalog` | **verrouiller** = ok (blockApps) ; **programmer** un focus récurrent = non |
| **Reviews (bilans)** | `buildReview` (daily/weekly/monthly), `aggregateAnalytics` | `review_run` | **programmer** un bilan récurrent = non |
| **Inbox (capture)** | triage lens (`inbox.ts`) | ❌ | **à brancher** (capture → triage par l'agent) |

### 1.2 Discovery / Veille (`packages/discovery`)

| Feature | Use-cases module | Kernel | Écart |
|---|---|---|---|
| **Recherche** (You.com/Tavily/Exa) | `research-provider.ts` (port + offline fallback), job `research` | `research` | — (CONNECTED, ponctuel) |
| **Sheet de découverte** | `buildDiscoveryItem` (FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY), `applyDiscoveryFilters` | ❌ | **assembler le pipeline recherche → sheet** |
| **Veille périodique / réactive** | — | ❌ | **scheduling de veille** (§2) — cible mission |

### 1.3 Learning / Knowledge (`packages/learning`)

| Feature | Module | Kernel | Écart |
|---|---|---|---|
| Cours (recherche) | `retrieval.ts`, semantic tree | `course_search` | — |
| QCM / Flashcards | `qcm.ts`, `flashcard` | `qcm_generate`, `flashcard_generate` | — |
| Miroir / session | `mirror-cognitive.ts`, `fsrs.ts` | `learning_session`, `mirror_analyze` | — |
| Import cours | `course-import.ts` | `learning_import` | — |
| Ajout KB (OCR) | ingestion | `knowledge_add` | — |

→ Learning/Knowledge = **CONNECTED**. Seule la **récurrence d'étude**
(QCM hebdo) passe par §2 (automation).

### 1.4 Progress (`packages/progress`) — `progress_analyze`,
`progress_trajectories`, `progress_cause` — **CONNECTED** (lecture /
recompute).

### 1.5 Ascent (`packages/ascent`) — read-do-prove, baseline, depth —
**MISSING** au kernel (mode `/ascent` utilisateur-only). À brancher si la
mission l'exige.

### 1.6 Scientific / Engineering — `scientific_evaluate` (léger),
`scientific_verify` (job), `artifact_generate`, `artifact_preview` —
**CONNECTED**.

### 1.7 Integrations (`packages/integrations`)

| Feature | Module | Kernel | Écart |
|---|---|---|---|
| **Automations** (cron/event/composio) | `cronInsertSql`, `automationDedupKey`, `buildAutomationJobPayload`, handlers `notification`/`agent_run` | `automation_toggle` (ON/OFF seul) | **créer/renommer/supprimer/programmer** une automation (§2) |
| Notifications / DND | `notifications.ts` | `notification_pref` | **verrouiller** (DND) ok ; cadence coach = `coach_checkin` |
| Coach proactif | — | `coach_checkin` | — (cadence-limited par design) |

### 1.8 Identity / Settings — `settings_theme` (commande `identity.set_theme`)
— **CONNECTED**.

### 1.9 Agent itself (`packages/agent`) — `skill_activate`, `skill_create`,
`skill_search`, `skill_get` (marketplace 0021) — **CONNECTED**.

### 1.10 Canvas (0022, `packages/ui` + mobile) — **MISSING** au kernel.
Feature récente (blocs TipTap, commentaires, md⇄HTML). À brancher :
`canvas_create/rename/delete/lock` + commentaires agentiques.

---

## 2. Scheduling de veille technologique — « sous plusieurs formes »

Le socle **existe** (`Automation` + `cronInsertSql`) mais n'est **pas exposé
au kernel**. C'est LE point de convergence du scheduling (veille +
planification récurrente).

### 2.1 L'entité `Automation` (`entities-integrations.ts`)

```ts
interface Automation {
  id; userId; name;
  trigger: 'event' | 'schedule' | 'condition';  // ← les 3 formes
  triggerEvent?;      // 'event' : quel événement AD-9 déclenche
  cron?;              // 'schedule' : expression cron
  jobKind?;           // closed 11 kinds (AD-15)
  action?;            // le payload / topic de l'action
  enabled; createdAt; updatedAt;
}
```

### 2.2 Les **formes** de scheduling de veille

| Forme | `trigger` | Mécanisme | Écart kernel |
|---|---|---|---|
| **Ponctuelle** | — (job direct) | `research` job (kind `research`) | — déjà CONNECTED |
| **Périodique** | `schedule` + `cron` | Supabase Cron → `cronInsertSql` → `job_queue` (idempotent AD-8) → dispatcher | **G : `create_automation` (cron)** |
| **Réactive** | `event` + `triggerEvent` | événement AD-9 (ex. `JobCompleted`, `DiscoveryItemCreated`) → tick → `job_queue` | **G : `create_automation` (event)** |
| **Conditionnelle** | `condition` | une condition observée (seuil de progression, échéance…) | **G : `create_automation` (condition)** |
| **Séquentielle (pipeline)** | combiné | recherche → qualify → `discovery sheet` → diffusion | **G : assembler le pipeline** |
| **Avec diffusion** | + `notification` | résultat → `notification` job → OneSignal (`fn-notifications`) | **G : câbler result → push** |

### 2.3 Ce que l'agent doit pouvoir dire (NL)

| Phrase utilisateur | Outil (à créer) | Résultat |
|---|---|---|
| « une veille sur la tech X **chaque jeudi** » | `create_automation(schedule, cron, jobKind=research, action=X)` | veille périodique |
| « surveille l'événement Y et cherche quand il arrive » | `create_automation(event, triggerEvent=Y, jobKind=research)` | veille réactive |
| « **stoppe** cette veille » | `automation_toggle(enabled=false)` | gel (verrouiller) |
| « **renomme** ma veille en « Veille IA » » | `update_automation(name)` | renommer |
| « **supprime** cette veille » | `delete_automation` (DESTRUCTIVE, ADR §5) | supprimer |
| « quand la veille est finie, **préviens-moi** » | câblage `research` job → `notification` job | diffusion |

### 2.4 Invariants (gates) à respecter

**Mécanisme de scheduling (vérifié live, instance dev)** — ne PAS créer de
nouvelles entrées `cron.job` par user (anti-pattern ; `0014` est volontairement
global/batch). Les 4 `cron.job` existantes itèrent sur `user_context` et enfilent
`job_queue` par user (`ON CONFLICT idempotency_key DO NOTHING`, AD-8). Le
per-user scheduling vit dans la table `automations` (`trigger_ jsonb` = la
cron / règle par user) et est **déclenché par le dispatcher** (sweep
`aurora_event_dispatch` `*/5`) qui lit les `automations` dues → enfile le job
(`research` pour la veille). Le plan (G1–G3) doit donc porter :

- l'exposition kernel des verbes `Automation` (thin emitters, AD-7) ;
- le **reader** du dispatcher qui, au lieu de n'enfiler que les 4 jobs batch
  fixes, matérialise les `automations` dues (trigger_.schedule avec cron,
  trigger_.event, trigger_.condition) en jobs `job_queue` ;
- l'assemblage recherche → sheet → notification (G9).

Les invariants sous-jacents :

- **AD-8** : le scheduling n'insère que dans `job_queue` ; chaque tick reste
  idempotent (`automationDedupKey` : `kind|automationId|minute`).
- **AD-7** : l'outil kernel **émet la commande** ; seul **Integrations**
  écrit la table `automations` (single writer).
- **AD-15** : `jobKind` reste dans le vocabulaire fermé (11 kinds,
  vérif `isJobKind`).
- **AD-1** : les providers de recherche restent dans l'adapter
  `ResearchProvider` ; le kernel ne touche pas le vendor.
- **AD-3** : zéro clé en clair dans le payload (ids seulement).
- **AD-16b** : résultat de veille (source tierce) = contenu non fiable →
  flag `uncertain` (ADR §13.7) avant insertion KB.

---

## 3. Gaps — deltas à combler (cartographie, **pas** d'implémentation)

Ordre = valeur agentique-first. Chaque gap = un **thin emitter** à exposer au
kernel (pattern `tools.ts` : `execute` renvoie `{ ok, command }` ou
`{ ok, jobKind }`, jamais un write direct).

| # | Gap | Verbe | Surface | Note |
|---|---|---|---|---|
| **G1** | `automation_create` (schedule/event/condition) | programmer | `tools.ts` | **le scheduling de veille (§2)** — priorité 1 |
| **G2** | `automation_update` (renommer, cron, action, enabled) | renommer / verrouiller | `tools.ts` | complète `automation_toggle` (ON/OFF seul) |
| **G3** | `automation_delete` (DESTRUCTIVE) | supprimer | `tools.ts` + confirmation ADR §5 | |
| **G4** | `goal_rename` / `task_rename` / `event_rename` / `habit_rename` / `canvas_rename` | renommer | `tools.ts` | le module sait patcher le titre ; l'exposer suffit |
| **G5** | `task_delete` / `goal_delete` / `canvas_delete` (DESTRUCTIVE) | supprimer | `tools.ts` + ADR §5 | AD-15 : suppression vs abandon (gel) à distinguer |
| **G6** | `habit_create` + cadence / `routine_create` | créer / programmer | `tools.ts` | module `createHabit`/`createRoutine` prêt |
| **G7** | `recurring_*` (tâche/agenda/habit via `nextRecurrence` + `materializeRecurringEvent`) | programmer | `tools.ts` | récurrence = materialized rows (01 S4.1) |
| **G8** | `focus_recurring` (séance récurrente) / `review_schedule` (bilan récurrent) | programmer | `tools.ts` | cadence = `Automation` (`condition`/`schedule`) |
| **G9** | Pipeline veille : `research` job → `discovery sheet` → diffusion | assembler / diffuser | `discovery` + `tools.ts` | G5+G6 de l'ancienne liste |
| **G10** | `canvas_*` (create/rename/delete/lock) + commentaires agentiques | tous | `tools.ts` | feature 0022, zéro outil kernel |
| **G11** | `inbox_*` (capture + triage) / `ascent_*` | tous | `tools.ts` | MISSING aujourd'hui |
| **G12** | `skill_rename` / `skill_delete` | renommer / supprimer | `tools.ts` | complète la famille skills |

### 3.1 Regroupement par verbe

- **Nommer / renommer** → G4, G2, G12 (le module patche déjà ; on expose).
- **Créer** → G1 (automation), G6 (habit), G7 (récurrence), G9 (sheet), G10 (canvas).
- **Supprimer** → G3, G5, G12 (tous DESTRUCTIVE → ADR §5).
- **Verrouiller** → G2 (toggle off), G8 (gel focus/réview), G10 (lock canvas) ;
  existants : `goal_pause`, `blockApps`, `skill_activate` off.
- **Programmer** → G1 (cron), G7 (récurrence), G8 (cadences) ; socle =
  `Automation` + `cronInsertSql`.

### 3.2 Ce qui est déjà SOLIDE (ne pas casser)

- Les 44 outils kernel sont des **émetteurs thin** (AD-7). G1–G12
  reproduisent ce pattern.
- Le vocabulaire `JobKind` fermé est gardé par `isJobKind` (`automations.ts`).
- La récurrence module (`nextRecurrence`, materialized rows) est le socle
  déterministe de G7/G8.
- AD-9 (closed 9 events) : les nouveaux emitters **n'inventent** pas d'événement.

---

## 4. Fallback manuel (plan B) — toujours disponible, jamais bloquant

Chaque surface pilotable par l'agent a déjà son équivalent **manuel** :

| Piloté par l'agent (plan A) | Fallback manuel (plan B) |
|---|---|
| `planDay` / `pomodoro_schedule` / `schedule` | Page **Agenda** (FullCalendar, time-blocking) |
| `task_update` / `recurring_*` | Page **Tâches** (création, sous-tâches, récurrence) |
| `goal_*` | Page **Goals** (dashboard, décomposition) |
| `habit_create` / `habit_checkin` | Page **Habits** (heatmap AntV G2) |
| `startFocus` / `blockApps` | Page **Focus** (timer + blocklist + sons) |
| `create_automation` (veille) | Page **Découverte** / **Intégrations** (automations listées) |
| `settings_theme` | Page **Settings** (thème) |
| `skill_*` | Page **Skills** (marketplace) |

AD-7 : en offline, chaque fallback dégrade proprement (miroir local,
état vide honnête) ; l'app ne casse jamais. L'agentique-first n'enlève
**rien** au manuel — il **ajoute** le chat comme premier plan.

---

## 5. Validation avant implémentation (prochaine session)

1. **G1** (scheduling de veille) = priorité 1, confirmé par le user ?
2. G4/G5/G12 : verbes `renommer` / `supprimer` sur **toutes** les familles ou
   sous-ensemble ?
3. La veille produit-elle une `discovery sheet` persistée + push (G9) ou juste
   le résultat de recherche ?
4. **À vérifier** : existe-t-il une migration `automations` + une entrée cron
   Supabase ? (`automations.ts` mentionne une migration « 0013 coordinated » —
   confirmer via `list_migrations`.)
5. Le verbe `supprimer` reste **destructive** (confirmation ADR §5) — cohérent
   avec `review_run` / `automation_toggle` déjà CONFIRMATION_REQUIRED.
