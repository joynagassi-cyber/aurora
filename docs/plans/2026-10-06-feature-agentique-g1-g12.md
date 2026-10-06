# Feature agentique — gaps G1–G12 (plan d'implémentation)

> **For Claude:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans`
> pour exécuter ce plan tâche par tâche. **Exécution choisie :
> Subagent-Driven (option 1)** — un sous-agent frais par tâche, review
> entre les tâches.

**Goal :** rendre **tout pilotable par le chat agentique** — nommer,
renommer, créer, supprimer, verrouiller, **programmer le scheduling de
veille technologique sous plusieurs formes** — tout en gardant le **plan B
manuel** (UI) intouchable. Chaque gap = un **thin emitter AD-7** (le
kernel n'écrit jamais une table module ; il émet une commande typée ou un
job, le module propriétaire applique).

**Architecture (3 couches, AD-7/AD-8) :**
1. **`packages/agent/src/tools.ts`** — nouveaux outils kernel : `execute`
   renvoie `{ ok, command }` (commande typée `<module>.<action>`) ou
   `{ ok, jobKind }` (job AD-8). Jamais de write direct.
2. **`packages/agent/src/capability.ts`** — chaque outil a une entrée
   `DefaultCapabilityRegistry` (scopes read/write, `requiresConfirmation`,
   `destructive`). Le registry **découvre** (kernel S14), ne code pas en dur.
3. **`packages/*` modules** — le module propriétaire applique la mutation
   (Productivity/Integrations/Discovery/Canvas). Pour l'existant déjà
   prèt (MODULE-READY), on n'ajoute qu'un thin emitter ; pour le vrai
   ajout (scheduling veille), on assemble le pipeline.

**Veille = `Automation`** (entité `entities-integrations.ts`, table
`automations` migration 0008) : `trigger: 'event'|'schedule'|'condition'` +
`cron?` + `jobKind` + `action`. Le **scheduling** vit dans la table
`automations` (per-user) + le **dispatcher** (sweep `aurora_event_dispatch`
`*/5`) qui matérialise les `automations` dues en `job_queue`. **PAS** de
nouvelles entrées `cron.job` par user (anti-pattern, `0014` est global/batch).

**Périmètre** : G1–G12 (tous). Priorité 1 = **G1–G3 + G9** (scheduling de
veille multi-formes : périodique/réactive/conditionnelle + sheet persistée +
push). Verbes transverses : rename (G4), delete destructive (G5), habit
create (G6), récurrence (G7), focus/réview récurrents (G8), canvas (G10),
inbox/ascent (G11), skill rename/delete (G12).

**Stack** : TypeScript strict, pnpm, `node:test` (`node
--experimental-strip-types --test`), Vercel AI SDK `tool()` (zod),
Supabase (Postgres + RLS + Edge Functions), Vitest pour `packages/ui`.

---

## Décisions à figeler (à valider AVANT de coder)

| # | Décision | Défaut retenu |
|---|---|---|
| D1 | Forme cible de la veille = **conditionnelle** (priorité), mais le mécanisme est **partagé** avec schedule/event | Couvrir `create_automation` pour les 3 triggers ; le plan cible `condition` d'abord, `schedule`+`event` en lot 2 |
| D2 | `delete` = **destructive** → confirmation ADR §5 obligatoire (cohérent `review_run`/`automation_toggle`) | `requiresConfirmation: true`, `destructive: true` dans le registry |
| D3 | Suppression AD-15 : `goal` n'a pas de `delete` (on **abandonne**/gèle) ; `task`/`canvas`/`skill`/`automation` = vrai delete destructive | `goal_delete` → `goal_abandon` (gel) ; pas de destruction de données (AD-15 additif) |
| D4 | Veille produit **sheet persistée (`discovery_items`) + push OneSignal** | Pipeline G9 : `research` job → `discovery` sheet (flag `uncertain` AD-16b) → `notification` job → `fn-notifications` |
| D5 | Les nouveaux outils suivent le pattern **thin emitter** existant (pas de write direct, pas de vendor) | — |

> Le sous-agent doit valider D1–D5 avec le lead avant d'ouvrir G1. Si un
> point est flou, c'est le lead (moi) qui tranche, pas le sous-agent.

---

## Structure des tâches (ordre = dépendance)

```
L0. Socle scheduling (Automation → reader du dispatcher)
  G1  create_automation (3 triggers)
  G2  update_automation (renommer/cron/action/enabled)
  G3  delete_automation (DESTRUCTIVE)
  G9  pipeline veille: research → discovery sheet → notification push
L1. Verbes génériques rename/delete (MODULE-READY, thin emitters)
  G4  rename (goal/task/event/habit/canvas/skill)
  G5  delete destructive (task/canvas) + goal→abandon
  G12 skill rename/delete
L2. Création + programmation
  G6  habit_create + routine_create (cadence)
  G7  recurring (tâche/agenda/habit via nextRecurrence / materialize)
  G8  focus_recurring + review_schedule (cadence via Automation)
L3. Surfaces manquantes
  G10 canvas create/lock (+ comment déjà seedé)
  G11 inbox capture/triage + ascent read
GATE. Gates statiques + RLS live + typecheck + commit
```

Chaque tâche **TDD** : 1) test qui échoue, 2) run → FAIL, 3)
implémentation minimale, 4) run → PASS, 5) commit. Commit **fréquent**
(une par tâche, parfois un par test si le sous-agent préfère).

**Pattern de test (référence `packages/agent/test/goal-capabilities.test.ts`)** :
le test (a) vérifie que l'outil est dans `KERNEL_TOOLS` + résolu via
`byTool` du registry ; (b) vérifie les flags `destructive` /
`requiresConfirmation` ; (c) appelle `X.execute(payload,…)` et asserte le
`{ ok, command }` / `{ ok, jobKind }` émis (AD-7 : jamais de write).

---

## G1 — `create_automation` (cœur de la veille)

**Files :**
- Modify: `packages/agent/src/tools.ts` (après le bloc `automationToggle`, ~L695)
- Modify: `packages/agent/src/capability.ts` (`seedDefaults`, famille integrations ~L465)
- Modify: `packages/agent/src/index.ts` (export du nouvel outil si exposé)
- Test: `packages/agent/test/automation.test.ts` (nouveau)

**Step 1 — test qui échoue.**

```ts
// packages/agent/test/automation.test.ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { KERNEL_TOOLS, DefaultCapabilityRegistry } from '../src/index.ts';
import { createAutomation } from '../src/tools.ts';

const reg = new DefaultCapabilityRegistry();

test('G1: create_automation est dans KERNEL_TOOLS et résolu via byTool', () => {
  assert.ok('create_automation' in KERNEL_TOOLS);
  assert.ok(reg.byTool('create_automation'), 'capability byTool');
  assert.equal(reg.get('integrations.automation.create')?.writeScopes[0], 'integrations:write');
});

test('G1: create_automation émet la commande integrations.automation_create (AD-7, 3 triggers)', async () => {
  for (const trigger of ['schedule', 'event', 'condition'] as const) {
    const r = await createAutomation.execute(
      { name: 'veille IA', trigger, jobKind: 'research', action: 'LLM agents', userId: 'u1' },
      {} as never, undefined as never,
    );
    assert.equal((r as { command: string }).command, 'integrations.automation_create');
    assert.equal((r as { payload: { trigger: string } }).payload.trigger, trigger);
  }
});

test('G1: jobKind restreint au vocabulaire fermé AD-15 (isJobKind)', async () => {
  const r = await createAutomation.execute({ name: 'x', trigger: 'schedule', jobKind: 'not-a-kind', userId: 'u1' }, {} as never, undefined as never);
  // dégrade à 'notification' si kind inconnu (AD-1 optional capability)
  assert.equal((r as { payload: { jobKind: string } }).payload.jobKind, 'notification');
});
```

**Step 2 — run, FAIL** (`createAutomation` inexistant) :
`node --experimental-strip-types --no-warnings --test packages/agent/test/automation.test.ts`
→ « Cannot find name createAutomation ».

**Step 3 — implémentation minimale** (`tools.ts`, après `automationToggle`) :

```ts
/** G1 — integrations.automation.create : crée une Automation (veille) avec
 *  trigger schedule (cron) / event (AD-9) / condition. Thin command
 *  (AD-7 : le kernel émet, Integrations applique la write `automations`).
 *  jobKind restreint au vocabulaire fermé AD-15 (isJobKind) ; kind
 *  inconnu → dégrade à 'notification' (AD-1 optional capability). */
export const createAutomation: KernelTool = tool({
  description:
    'Créer une automation / une veille (ADR S2, 01 §5.2). trigger: schedule (cron, ex. chaque jeudi) / event (réactive sur un événement AD-9) / condition (seuil observé). jobKind = le job enfilé (vocabulaire fermé AD-15 ; inconnu → notification). Thin command → integrations.automation_create (AD-7 : le module Integrations écrit `automations`).',
  inputSchema: z.object({
    name: z.string(),
    trigger: z.enum(['schedule', 'event', 'condition']),
    /** expression cron (schedule) ou nom d'événement AD-9 (event) ou clé de condition */
    schedule: z.string().optional(),
    triggerEvent: z.string().optional(),
    condition: z.string().optional(),
    /** JobKind fermé (AD-15) ; défaut 'research' pour la veille */
    jobKind: z.string().default('research'),
    /** le payload / topic de l'action (ex. le sujet de la veille) */
    action: z.string().optional(),
    userId: z.string().optional(),
  }),
  execute: async (input) => {
    const kind = isJobKind(input.jobKind) ? input.jobKind : 'notification';
    return {
      ok: true,
      command: 'integrations.automation_create',
      payload: {
        name: input.name,
        trigger: input.trigger,
        schedule: input.trigger === 'schedule' ? input.schedule : undefined,
        triggerEvent: input.trigger === 'event' ? input.triggerEvent : undefined,
        condition: input.trigger === 'condition' ? input.condition : undefined,
        jobKind: kind,
        action: input.action,
        userId: input.userId,
      },
    };
  },
});
```

> `isJobKind` est exporté par `packages/integrations/src/automations.ts`
> (re-exporté dans `packages/integrations`). Vérifier l'import ; si le
> package `agent` ne doit pas dépendre d'integrations (boundaries),
> dupliquer le `JOB_KINDS` Set fermé dans `tools.ts` (AD-15 SSoT) —
> **à trancher par le lead** : préférence = importer depuis
> `@aurora/integrations` si la boundary le permet (le gate G4 ne scanne
> que `packages/agent` pour le DOM, pas les imports inter-packages).

**Step 4 — entrée registry** (`capability.ts`, dans la famille integrations) :

```ts
{
  id: 'integrations.automation.create',
  tool: 'create_automation',
  description: 'Create an automation / veille (ADR S2). trigger schedule (cron) / event / condition; jobKind from the AD-15 closed set. Thin command → integrations.automation_create (AD-7)',
  writeScopes: ['integrations:write'],
  readScopes: ['integrations:read', 'discovery:read'],
  destructive: false,
  requiresConfirmation: false, // créer n'est pas destructif ; c'est la suite (delete) qui l'est
},
```

**Step 5 — run, PASS** + ajouter `'create_automation'` à la liste
`ALL_TOOL_IDS` si un set fermé existe (vérifier `sdk.ts` /
`skill-templates.ts` `BUILTIN_TOOL_IDS`).

**Step 6 — commit** : `git add packages/agent/src/tools.ts packages/agent/src/capability.ts packages/agent/test/automation.test.ts ; git commit -m "feat(agent): G1 create_automation (veille, 3 triggers, AD-15 closed kind)"`.

---

## G2 — `update_automation` (renommer / reprogrammer / verrouiller)

**Files :** `tools.ts`, `capability.ts`, `test/automation.test.ts`.

Le `update_automation` complète `automation_toggle` (ON/OFF seul) :
renommer (`name`), reprogrammer (`schedule`/`triggerEvent`/`condition`),
changer l'action, et **verrouiller** = `enabled:false` (gel).

**Test (ajout à `automation.test.ts`) :**

```ts
test('G2: update_automation patche name/cron/action/enabled (verrouiller = enabled:false)', async () => {
  const r = await updateAutomation.execute(
    { automationId: 'a1', patch: { name: 'Veille IA', enabled: false }, userId: 'u1' },
    {} as never, undefined as never,
  );
  assert.equal((r as { command: string }).command, 'integrations.automation_update');
  assert.deepEqual((r as { payload: { patch: Record<string, unknown> } }).payload.patch, { name: 'Veille IA', enabled: false });
});
```

**Implémentation** (`tools.ts`) :

```ts
/** G2 — integrations.automation.update : renommer / reprogrammer /
 *  verrouiller (enabled) une Automation. Thin command AD-7. */
export const updateAutomation: KernelTool = tool({
  description:
    'Renommer / reprogrammer / (dé)verrouiller une automation (complète automation_toggle ON/OFF). patch: name (renommer), schedule (cron), triggerEvent, condition, action, enabled (verrouiller = false). Thin command → integrations.automation_update (AD-7 : le module Integrations applique le patch sur `automations`).',
  inputSchema: z.object({
    automationId: z.string(),
    patch: z.object({
      name: z.string().optional(),
      schedule: z.string().optional(),
      triggerEvent: z.string().optional(),
      condition: z.string().optional(),
      action: z.string().optional(),
      enabled: z.boolean().optional(),
    }),
    userId: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'integrations.automation_update', payload: input }),
});
```

**Registry :** `integrations.automation.update`, write `integrations:write`,
`requiresConfirmation: false` (le verrouillage est réversible — non
destructif). **Commit** : `feat(agent): G2 update_automation (renommer/reprogrammer/verrouiller)`.

---

## G3 — `delete_automation` (DESTRUCTIVE, ADR §5)

**Files :** `tools.ts`, `capability.ts`, `test/automation.test.ts`.

**Test :**

```ts
test('G3: delete_automation est destructive + requiresConfirmation (ADR §5)', () => {
  assert.equal(reg.get('integrations.automation.delete')?.destructive, true);
  assert.equal(reg.get('integrations.automation.delete')?.requiresConfirmation, true);
});
test('G3: delete_automation émet integrations.automation_delete', async () => {
  const r = await deleteAutomation.execute({ automationId: 'a1', userId: 'u1' }, {} as never, undefined as never);
  assert.equal((r as { command: string }).command, 'integrations.automation_delete');
});
```

**Implémentation** : outil `deleteAutomation` (schema `automationId` +
`userId`), `execute` → `{ ok, command: 'integrations.automation_delete' }`.
Registry : `integrations.automation.delete`, **`destructive: true`,
`requiresConfirmation: true`** (suppression = irréversible, ADR §5 ;
cohérent avec la règle déjà seedée dans `0019_user_skills.sql` L452).
**Commit** : `feat(agent): G3 delete_automation (DESTRUCTIVE, ADR §5)`.

> **Note D3/AD-15** : pour une *automation*, la suppression est un vrai
> delete (la table `automations` n'est pas AD-15-additive comme les goals).
> Les **goals** en revanche n'ont QUE `goal_abandon` (gel) — pas de
> `goal_delete` (voir G5).

---

## G4 — verbes **renommer** (thin emitters sur le patch titre existant)

**Files :** `tools.ts`, `capability.ts`, `test/rename.test.ts`.

Le module patche déjà le titre (`updateGoal` = `goals-projects.ts` L67 ;
`tasks` via `productivity.task_update` patch ; `calendar` `rescheduleEvent`
existe mais pas de rename). On expose **un seul outil générique par
famille** qui patche le champ titre (AD-7 : le module applique).

| Outil | Commande émise | Module qui applique |
|---|---|---|
| `goal_rename` | `progress.goal_rename` (`{ goalId, title }`) | Progress (`updateGoal` existe → title) |
| `task_rename` | `productivity.task_update` (`{ taskIds:[id], action:'update', patch:{ subject } }`) | Productivity |
| `event_rename` | `productivity.event_update` (`{ eventIds, patch:{ title } }`) | Productivity |
| `habit_rename` | `productivity.habit_update` (`{ habitId, patch:{ name } }`) | Productivity |
| `canvas_rename` | `canvas.rename` (`{ canvasId, title }`) | Canvas |
| `skill_rename` | `agent.skill_rename` (`{ skillId, name }`) | Agent |

**Test** (une famille suffit pour pin le pattern, les autres = même forme) :

```ts
test('G4: goal_rename émet progress.goal_rename (AD-7, le module patche le titre)', async () => {
  const r = await goalRename.execute({ goalId: 'g1', title: 'But v2', userId: 'u1' }, {} as never, undefined as never);
  assert.equal((r as { command: string }).command, 'progress.goal_rename');
});
```

**Implémentation** : 6 outils thin (`goalRename`, `taskRename`,
`eventRename`, `habitRename`, `canvasRename`, `skillRename`) — chacun
`execute` → `{ ok, command }`. Registry : `<famille>.rename`,
`writeScopes: [module:write]`, `destructive:false`, `requiresConfirmation:false`
(rénommer = non destructif). **Commit** : `feat(agent): G4 rename verbs (goal/task/event/habit/canvas/skill, AD-7 thin)`.

> **Module-side (si pas encore)** : `goal_rename` → vérifier que
> `packages/progress` ou `packages/productivity/src/goals-projects.ts`
> a un use-case rename (sinon = ajouter `renameGoal` qui patche `title`,
> pattern `updateGoal` L67, `GoalUpdated` fields:['title'] — AD-9).

---

## G5 — verbes **supprimer** (DESTRUCTIVE, ADR §5) — `task_delete` / `canvas_delete`

**Files :** `tools.ts`, `capability.ts`, `test/delete.test.ts`.

Contrairement à G3 (automation, vrai delete), ici :
- `task_delete` = destructive (supprime la row tasks + cascades) →
  confirmation.
- `canvas_delete` = destructive → confirmation.
- **`goal` n'A PAS de delete** (D3/AD-15) : on guide vers `goal_abandon`
  (gel, données préservées). Le sous-agent ne crée PAS de `goal_delete`.

**Test :**

```ts
test('G5: task_delete + canvas_delete sont destructive + requiresConfirmation', () => {
  assert.equal(reg.get('task.delete')?.destructive, true);
  assert.equal(reg.get('task.delete')?.requiresConfirmation, true);
  assert.equal(reg.get('canvas.delete')?.destructive, true);
  // pas de goal.delete (AD-15 additif) → on abandonne
  assert.equal(reg.get('goal.delete'), undefined);
});
```

**Implémentation** : `taskDelete` (`productivity.task_delete`),
`canvasDelete` (`canvas.delete`). Registry : `task.delete`, `canvas.delete`,
**`destructive:true`, `requiresConfirmation:true`** (ADR §5). **Commit** :
`feat(agent): G5 delete destructive (task/canvas; goal→abandon AD-15)`.

---

## G6 — `habit_create` + `routine_create` (cadence = programmer)

**Files :** `tools.ts`, `capability.ts`, `test/habit.test.ts`.

Le module `createHabit`/`createRoutine` (`packages/productivity/src/habits.ts`
L30/L197) est **prêt** — on l'expose. Cadence = le « programmer » d'un
habit/routine (daily/weekly/custom).

**Test :**

```ts
test('G6: habit_create émet productivity.habit_create avec cadence (programmer)', async () => {
  const r = await habitCreate.execute({ title: 'Lecture', cadence: 'daily', userId: 'u1' }, {} as never, undefined as never);
  assert.equal((r as { command: string }).command, 'productivity.habit_create');
  assert.equal((r as { payload: { cadence: string } }).payload.cadence, 'daily');
});
test('G6: routine_create émet productivity.routine_create', async () => {
  const r = await routineCreate.execute({ title: 'Matin', kind: 'morning', steps: ['café'], userId: 'u1' }, {} as never, undefined as never);
  assert.equal((r as { command: string }).command, 'productivity.routine_create');
});
```

**Implémentation** : `habitCreate` (`cadence: 'daily'|'weekly'|'custom'`,
`weekdays?`, `recurrenceRule?`), `routineCreate` (`kind`, `steps`,
`habitIds`). Thin commands. Registry : `habit.create`, `routine.create`,
write `productivity:write`, non-destructif. **Commit** :
`feat(agent): G6 habit_create + routine_create (cadence, module prêt)`.

---

## G7 — `recurring_*` (tâche/agenda via `nextRecurrence` + materialization)

**Files :** `tools.ts`, `capability.ts`, `test/recurring.test.ts`.

Le module `nextRecurrence` + `materializeRecurringEvent`
(`tasks.ts` L221, `calendar.ts` L218) gèrent déjà la récurrence
(materialized rows, 01 S4.1). L'agent doit pouvoir **créer** une tâche /
bloc **récurrente** en exposant le flag.

**Approche** : étendre les outils de création existants plutôt que créer
de nouveaux (YAGNI) :
- `taskUpdate` (action=`create`) : ajouter `recurring: boolean` +
  `recurrenceRule` dans le `patch` (le module `createTask` L72 s'en
  charge → `parent_recurrence_key`).
- `schedule` : ajouter `recurring`/`recurrenceRule` (module `createEvent`
  L35 gère `recurrence: { active, rule, materialized }`).

**Test :**

```ts
test('G7: task_update create + recurring porte la récurrence (materialized rows, 01 S4.1)', async () => {
  const r = await taskUpdate.execute({ taskIds: [], action: 'create', title: 'Réviser', recurring: true, recurrenceRule: 'FREQ=WEEKLY', userId: 'u1' }, {} as never, undefined as never);
  assert.equal((r as { payload: { recurring?: boolean } }).payload?.recurring, true);
});
```

**Implémentation** : enrichir les schémas zod de `taskUpdate` (action
create) et `schedule` de `recurring?: boolean` + `recurrenceRule?: string`
(passer en payload ; le module applique). Pas de nouvel outil. Registry :
pas de nouvelle entrée (réutilise `task.update`/`calendar.schedule`), mais
ajouter un commentaire que la récurrence est supportée. **Commit** :
`feat(agent): G7 recurring task/event (nextRecurrence, materialized rows)`.

> **Module-side check** : `nextRecurrence` ne supporte que
> `FREQ=DAILY|WEEKLY|MONTHLY[;INTERVAL=n]` — un autre rule = null
> (pas de materialization). Le sous-agent documente cette limite dans la
> description de l'outil.

---

## G8 — `focus_recurring` + `review_schedule` (cadence via Automation)

**Files :** `tools.ts`, `capability.ts`, `test/recurring-focus.test.ts`.

« programmer un focus / un bilan récurrent » = une **Automation** de
trigger `schedule` (cron) dont le `jobKind`/`action` déclenche un focus ou
une review. Donc G8 **réutilise G1** (`create_automation`) — pas de nouvel
outil, mais **deux helpers sémantiques** optionnels si le lead veut des
phrases NL plus propres.

**Décision (YAGNI)** : G8 = documenter dans la description de
`create_automation` (G1) que `trigger:'schedule'` +
`action:'focus.start'` / `'review.run'` = focus/bilan récurrent. Le
sous-agent ajoute une **section de doc** dans `tools.ts` (pas de nouvel
outil). Si le lead veut des outils dédiés `focus_recurring`/
`review_schedule` = ils emettent la même commande G1 avec l'action fixée.

**Test** (si outils dédiés) : sinon = doc. **Commit** :
`docs(agent): G8 focus/review récurrents via Automation (trigger schedule)`.

---

## G9 — pipeline veille : `research` → `discovery sheet` → `notification` push

**Files :** `packages/discovery/src/jobs.ts` (+ `discovery.ts`),
`supabase/functions/fn-job-dispatcher/index.ts` (wiring),
`packages/agent/src/tools.ts` (pas d'outil — c'est le module qui assemble).

C'est l'**assemblage**, pas un thin emitter. Le `research` job existe
(déjà CONNECTED) ; il faut que son **résultat** alimente une
`discovery_items` row (via `buildDiscoveryItem` `discovery.ts` L82, flag
`uncertain` AD-16b) et déclenche un `notification` job (push OneSignal,
`fn-notifications`).

**Step 1 — test module** (`packages/discovery/test/veille-pipeline.test.ts`) :
`runVeillePipeline(researchResults, userId, …)` → construit une
`DiscoveryItem` (kind `TREND`, `uncertain=true` si source non fiable) +
retourne le payload du `notification` job à enfileter.

**Step 2 — implémentation module** : fonction pure dans
`packages/discovery/src/jobs.ts` qui, à la complétion du `research` job
(le handler dispatcher `research`), (a) qualifie via
`applyDiscoveryFilters` (déjà existant `filtering.ts`), (b)
`buildDiscoveryItem` (flag uncertain AD-16b), (c) émet un `notification`
job (via `cronInsertSql`/dedupKey pattern de `automations.ts`).

**Step 3 — wiring dispatcher** : le handler `research` du
`fn-job-dispatcher` appelle le pipeline (chevauchement : le package
`discovery` fournit le handler, le dispatcher ne fait que l'enregistrer).

**Registry** : pas d'outil kernel (c'est le module qui assemble) — mais
`create_automation` (G1) avec `jobKind:'research'` est l'entrée agentique.
**Commit** : `feat(discovery): G9 veille pipeline (research→sheet→push, AD-16b uncertain)`.

> **Invariant AD-16b** : le résultat de recherche (source tierce) est du
> **contenu non fiable** → le `DiscoveryItem` porte `uncertain:true`
> (ADR §13.7) **avant** toute insertion dans le KB. Le sous-agent ne
> supprime JAMAIS ce flag.

---

## G10 — `canvas_create` + `canvas_lock` (canvas déjà seedé read/write/comment)

**Files :** `tools.ts`, `capability.ts`, `test/canvas-tools.test.ts`.

Le capability registry **a déjà** seedé `canvas_read`/`canvas_write`/
`canvas_comment` (capability.ts L549–578, tools.ts L391–444). Il manque
`canvas_create` (nouvelle session) + `canvas_lock` (verrouiller).

**Test :**

```ts
test('G10: canvas_create + canvas_lock émettent canvas.create / canvas.lock (AD-7)', async () => {
  assert.equal(await canvasCreate.execute({ title: 'Ma session', userId: 'u1' }, {} as never, undefined as never) as { command: string }, 'canvas.create' ? 'canvas.create' : (undefined as never));
  // assertion réelle :
  const r = await canvasCreate.execute({ title: 'x', userId: 'u1' }, {} as never, undefined as never);
  assert.equal((r as { command: string }).command, 'canvas.create');
  const l = await canvasLock.execute({ canvasId: 'c1', locked: true, userId: 'u1' }, {} as never, undefined as never);
  assert.equal((l as { command: string }).command, 'canvas.lock');
});
```

**Implémentation** : `canvasCreate` (`{ title, blocks?, artifactId? }` →
`canvas.create`), `canvasLock` (`{ canvasId, locked }` → `canvas.lock`).
Registry : `canvas.create` (write `canvas:write`), `canvas.lock`
(write `canvas:write`, `destructive:false`, `requiresConfirmation:false` —
le verrou est réversible). **Module-side** : `canvas-client.ts`
(`apps/mobile/src/lib/canvas-client.ts`) a déjà `create` ; ajouter `lock`
(si la table `canvas_sessions` n'a pas de champ `locked` → migration
additive, **à trancher** : ajouter la colonne `locked boolean default
false` en migration 0023, ou stocker dans `blocks jsonb`). **Commit** :
`feat(agent): G10 canvas_create + canvas_lock (le 0022, verrou).`

---

## G11 — `inbox_capture` / `inbox_triage` + `ascent_read`

**Files :** `tools.ts`, `capability.ts`, `test/inbox-ascent.test.ts`.

Le module `captureTask`/`triageTask` (`productivity/src/inbox.ts` L29/L42)
est **prêt**. `ascent` = lecture read-do-prove (mode `/ascent`).

**Test :**

```ts
test('G11: inbox_capture émet productivity.inbox_capture (AD-7, le module capture)', async () => {
  const r = await inboxCapture.execute({ text: 'se souvenir de X', userId: 'u1' }, {} as never, undefined as never);
  assert.equal((r as { command: string }).command, 'productivity.inbox_capture');
});
test('G11: ascent_read est read-only (pas de write scope)', () => {
  const e = reg.get('ascent.read');
  assert.ok(e && e.writeScopes.length === 0 && e.requiresConfirmation === false);
});
```

**Implémentation** : `inboxCapture` (`productivity.inbox_capture`),
`inboxTriage` (`productivity.inbox_triage`), `ascentRead`
(`ascent.read`, READ-ONLY, `ascent` module + `kernel-integration.ts`).
Registry : `inbox.capture`/`inbox.triage` (write `productivity:write`),
`ascent.read` (read-only, `ascent:read`). **Commit** :
`feat(agent): G11 inbox capture/triage + ascent read (surfaces manquantes).`

---

## G12 — `skill_rename` / `skill_delete` (complète la famille skills)

**Files :** `tools.ts`, `capability.ts`, `test/skill-mutation.test.ts`.

Le registry a `skill_activate`/`skill_create` (marketplace 0021). Il manque
renommer + supprimer (destructive).

**Test :**

```ts
test('G12: skill_rename (non-destructif) + skill_delete (DESTRUCTIVE, ADR §5)', () => {
  assert.equal(reg.get('skill.rename')?.destructive, false);
  assert.equal(reg.get('skill.delete')?.destructive, true);
  assert.equal(reg.get('skill.delete')?.requiresConfirmation, true);
});
```

**Implémentation** : `skillRename` (`agent.skill_rename`),
`skillDelete` (`agent.skill_delete`). Registry : `skill.rename`
(write `agent:write`, non-destructif), `skill.delete` (**destructive:true,
requiresConfirmation:true**, ADR §5). **Commit** :
`feat(agent): G12 skill_rename + skill_delete (destructive ADR §5).`

---

## GATE — gates statiques + RLS live + typecheck + commit final

Run (dans l'ordre) :

```bash
# 1. typecheck (0 erreur)
pnpm -F @aurora/mobile typecheck && pnpm -F @aurora/agent test
# 2. vitest packages/ui si touché
pnpm -F @aurora/ui test
# 3. tests node mobile
node --experimental-strip-types --no-warnings --test apps/mobile/test/*.test.ts
# 4. lint
pnpm -F @aurora/mobile lint
# 5. gates statiques
sh scripts/check-rls.sh
sh scripts/check-boundaries.sh all
```

**RLS live (MCP Supabase)** — si G10 a créé la migration `0023`
(colonne `locked` sur `canvas_sessions`) : appliquer via
`mcp__supabase-aurora__execute_sql` bloc par bloc, `check-rls.sh` doit
repasser vert, et le test négatif (user A ne lit pas les `automations` /
`canvas_sessions` de user B) via `SET ROLE authenticated` +
`SET request.jwt.claims`. Test positif (user lit ses lignes) seulement si
des users existent dans l'instance dev.

**Progress** : mettre à jour `progress/claude.md` (section Context n°6 :
feature agentique gaps G1–G12 + open items). **Commit** final :
`docs(progress): feature agentique G1–G12 + gates verts.`

---

## Ce que le sous-agent **ne touche PAS** (contraintes project)

- **AD-3** : zéro clé/secret en clair dans un payload.
- **AD-7** : le kernel n'écrit JAMAIS une table module — thin emitters.
- **AD-15** : `jobKind` reste dans le vocabulaire fermé (11 kinds).
- **AD-1** : les providers de recherche (You.com/Tavily/Exa) restent dans
  l'adapter `ResearchProvider` ; le kernel ne touche pas le vendor.
- **AD-16b** : résultat de veille (source tierce) = flag `uncertain`,
  jamais supprimé.
- **AD-15 additif** : pas de `goal_delete` (on `goal_abandon`/gèle).
- **Supabase MCP** : toute opération schéma passe par le MCP (pas de CLI
  direct) ; jamais de `DROP TABLE` non-Aurora ; schéma **additif** ;
  `FORCE ROW LEVEL SECURITY` ; jamais de `BYPASSRLS`.
- **WIP working tree** : ne PAS committer les fichiers WIP préexistants
  (`packages/agent/src/{context,tools,types}.ts` si en WIP,
  `supabase/functions/{_shared/fn-agent-bootstrap,fn-skills}` —
  **à re-vérifier le `git status` au démarrage** ; ici `tools.ts` est
  touché par le plan, donc il doit être dans le diff propre du commit
  agentique, séparé de la WIP knowledge/discovery/inbox si elle existe).

## Livrable final

- `docs/plans/2026-10-06-feature-agentique-g1-g12.md` (ce fichier)
- 12 jeux d'outils kernel + registry entries + tests (1 commit par G)
- G9 pipeline discovery + dispatcher wiring
- (optionnel) migration 0023 pour `canvas_sessions.locked`
- `progress/claude.md` à jour
- **Matrice finale** : après exécution, repasser
  `docs/agent/feature-mapping-agent-gaps.md` §0 → tous les verbes
  **CONNECTED** (l'agent peut nommer/renommer/créer/supprimer/verrouiller/
  programmer ; l'utilisateur garde le plan B manuel).
