# Event History Reconciliation + AI Router TaskProfile (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED`. Authority: AD-8 (jobs),
AD-9 (9 events, no broker), 01 S3.3 (event transport), 03 S5
(sync, throttling), 04 S5.7 (minSyncIntervalMs), ADR v1.7 S6/S7
(task profile, routing levels), ai/providers-and-routing.md S9-12.

## Part 1: Event History Reconciliation (battery-aware)

### 1.1 How events flow (server -> device)

```
Server (Supabase Postgres):
  Module emits event -> INSERT into `events` table (Event History, AD-9)
    -> Postgres trigger on INSERT `events`
      -> dispatches a job (fn-event-dispatcher, AD-8)
      -> OR: consumer reads incrementally (since_event_id, 01 S3.3)

Device (PowerSync, 03 S5):
  PowerSync relay (server) watches `events` table
    -> pushes new rows to device via WebSocket (or HTTP poll)
    -> device SQLite: upsert into local `events` mirror
    -> React Query bridge (03 S5.8) notifies UI
```

**There is NO message broker (AD-9: V1 = no Kafka, no RabbitMQ).**
The event transport is:
1. Postgres `events` table (the Event History, source of truth)
2. Postgres trigger -> job (for server-side consumers)
3. PowerSync incremental sync (for device-side consumers)
4. `since_event_id` polling (for consumers that need a specific range)

### 1.2 Battery-aware reconciliation (03 S5.7, 04 S3.6)

The device does NOT process events in real-time. It uses a
**throttled reconciliation loop**:

```
Foreground (app active):
  sync interval = minSyncIntervalMs (03 S5.7, owner packages/data)
  default: 5000ms (5s)
  -> PowerSync pushes new events -> local upsert -> UI refresh
  -> CPU: active, network: active, battery: normal usage

Background (app in background, Android):
  sync interval = minSyncIntervalMs * 4 (throttled, 04 S3.6)
  default: 20000ms (20s)
  -> PowerSync uses Android WorkManager (NOT a continuous service)
  -> CPU: batched, network: Wi-Fi preferred, battery: low impact
  -> If OQ-04 resolves to "foreground service needed":
     FOREGROUND_SERVICE permission requested (04 S3.2.1,
     NOT at boot, on first background sync need)

Offline:
  No sync. Events accumulate on the server.
  On reconnect: PowerSync catches up (since_event_id = last seen)
  -> burst of events applied in order (event_id sequence)
  -> UI shows "X new events" badge, NOT a full reload
```

**Key rule: the device NEVER polls the server for events.**
PowerSync pushes. The device is passive. Battery cost =
PowerSync's sync interval, not a custom polling loop.

### 1.3 Event ordering (deterministic, no races)

```
events table (server):
  event_id (ULID, time-ordered)
  user_id
  type (one of 9, AD-9)
  payload (JSONB)
  created_at (server timestamp)
  source_module (which module emitted it)

Device SQLite mirror:
  Same schema. PowerSync syncs in event_id order.
  Reconciliation: process events in event_id order (ULID = time-ordered)
  -> No reordering, no races
  -> If 2 events have the same timestamp (impossible with ULID,
     but defensive): source_module breaks the tie
     (deterministic, 03 S5.1: server-wins + updated_at)
```

### 1.4 Event consumption (who reads what, when)

| Consumer | When | How | Battery impact |
|---|---|---|---|
| UI (React Query) | Foreground, on event arrival | PowerSync `watch` -> RQ invalidate (03 S5.8) | Low (event-driven, not polling) |
| Agent Kernel (server) | On event (Postgres trigger -> job) | `fn-event-dispatcher` -> `fn-agent-run` | N/A (server) |
| Progress (server) | On ProgressEvidenceCreated, SkillStateChanged | Incremental read (since_event_id) | N/A (server) |
| Focus timer (device) | Local, NOT event-driven | System clock (04 S3.6.9: app kill loses nothing, AD-7) | Zero (no network) |
| Notification (device) | Local deadline (04 S3.4) | Capacitor LocalNotification | Zero (no network) |
| Coach check-in (device) | Server-driven (OneSignal push, ADR S13) | OneSignal -> Android notification | Low (push, not poll) |

**The rule: if it can be local, it is local. If it needs
server data, it uses PowerSync push (not poll). If it needs
server action, it's a job (AD-8, not a client-side loop).**

### 1.5 The "background sync without draining battery" test

| Scenario | Expected behavior | Test |
|---|---|---|
| App in background 30 min | PowerSync WorkManager batches; no continuous service; battery < 2% drain | 04 S7 E2E (device, 30 min background) |
| Network drops 2h, reconnects | PowerSync catches up in one burst; events applied in order; no duplicates (idempotency, AD-8) | 03 S7 re-sync test |
| 100 events accumulated offline | UI shows "100 new events" badge; tap = process all; no full reload | 02 S11 E2E |
| FOREGROUND_SERVICE requested | Only if OQ-04 = "continuous background sync needed"; NOT at app boot; user sees the permission prompt once | 04 S3.2.1 test |

## Part 2: AI Router TaskProfile Specification

### 2.1 The TaskProfile (typed, NOT prompt keywords, ADR v1.7 S6)

```ts
// packages/domain (SSoT, AD-15)
interface TaskProfile {
  // WHAT the task is
  complexity: 'low' | 'medium' | 'high' | 'critical';
  reasoning: boolean;          // needs multi-step logical chain?
  tools: string[];            // which tools are needed? (names)
  vision: boolean;            // needs image understanding?
  dataSensitivity: 'public' | 'internal' | 'sensitive'; // data policy

  // HOW to route it
  contextSize: number;        // estimated tokens in context
  latency: 'low' | 'medium' | 'high'; // how fast does the user need it?
  cost: 'minimal' | 'moderate' | 'flexible'; // budget constraint
  criticality: 'routine' | 'important' | 'critical';
  verification: boolean;      // needs deterministic check?
  deterministicTool?: string; // ScientificEngine, FEM, etc.

  // WHERE it comes from
  source: 'user_direct' | 'agent_autonomous' | 'coach_proactive' | 'job_cron';
  goalProjectId?: string;     // which GoalProject (dynamic-goal-engine.md)
}
```

**The TaskProfile is built by the Intent Engine (kernel S12), NOT
by the LLM.** The Intent Engine reads:
- The user's utterance (NL)
- The GoalProject context (if active)
- The Progress state (skill freshness, gap urgency)
- The UserContext (energy, overload, silence windows)
- The event that triggered this (if agent_autonomous)

And produces a TYPED TaskProfile. The router reads the TaskProfile.
The router NEVER sees the raw prompt.

### 2.2 The 5 Routing Levels (ADR v1.7 S7)

| Level | Trigger (TaskProfile) | Model selection | Examples |
|---|---|---|---|
| **ROUTINE** | complexity=low, reasoning=false, tools=[], latency=low | Cheapest/fastest: Agnes 2.5 Flash / GLM-4.7 Flash / Groq GPT-OSS 20B | "Organise ma journée" (planning is deterministic), "Ajoute une tâche", theme switch |
| **AGENT** | complexity=medium-high, reasoning=true, tools>=1, criticality=important | Reasoning + tool calling: Agnes 3.0 / Nemotron 3 Super / GPT-OSS 120B | "Décompose mon objectif", "Trouve les lacunes en RDM", multi-step plan |
| **VISION** | vision=true | Multimodal: Gemma 4 / provider with vision | "Photographie cette page du cours, extrais la formule" |
| **CRITICAL** | criticality=critical, verification=true, deterministicTool set | Strongest model + ScientificEngine verification: Agnes 3.0 + verify job | "Dimensionne la poutre selon Eurocode 2" (FEM solver + equilibrium check) |
| **FALLBACK** | any level, primary provider unavailable (429/5xx/timeout) | Next compatible provider in the chain | Any level when the primary is down |

**The transition ROUTINE -> CRITICAL is NOT a model upgrade.**
It is a TASK reclassification: the Intent Engine detects that the
task needs deterministic verification (ScientificEngine) and
escalates the TaskProfile to `criticality: 'critical'`.

### 2.3 The Routing Formula (ai/providers-and-routing.md S11)

```
selectModel(taskProfile) -> { provider, model, attempt }

1. Filter providers by:
   - capability match (vision? tools? context size?)
   - data policy (taskProfile.dataSensitivity vs provider.dataPolicy)
   - availability (AIHealthRegistry: not in cooldown)
   - budget (AIBudgetManager: quota not exhausted)

2. Score remaining providers by:
   - taskProfile.complexity vs provider's model capability
   - taskProfile.latency vs provider's p95 latency
   - taskProfile.cost vs provider's pricing
   - taskProfile.criticality (CRITICAL = prefer strongest model)
   - AIHealthRegistry.errorRate (prefer healthy provider)

3. Select top-scored provider + model.
   Record in AIResponseEnvelope:
   { provider, model, attempt: 1, reason: 'primary',
     expectedQuality: 'full', fallbackUsed: false }

4. If attempt 1 fails (429/5xx/timeout):
   -> retry same provider (bounded: 3x, exponential backoff)
   -> if still failing: next provider in fallback chain
   -> AIResponseEnvelope: { attempt: 2, reason: 'fallback',
       fallbackUsed: true }

5. If ALL providers fail:
   -> CRITICAL task: mark 'degraded', inform user, do NOT
      silently accept a lower-quality result
   -> ROUTINE task: use the last available result (best effort)
```

### 2.4 What Triggers the Level (concrete examples)

| User input | Intent Engine output | Level | Model | Why |
|---|---|---|---|---|
| "Ajoute une tâche" | complexity=low, tools=[], reasoning=false | ROUTINE | Agnes 2.5 Flash | Deterministic, no reasoning needed |
| "Décompose mon objectif ML en sous-buts" | complexity=high, reasoning=true, tools=['goal.create','discovery.gaps'] | AGENT | Agnes 3.0 | Multi-step, needs tool calling |
| "Photographie cette page, extrais la formule" | vision=true, tools=['ocr'] | VISION | Gemma 4 | Needs image understanding |
| "Dimensionne la poutre selon Eurocode 2" | criticality=critical, verification=true, deterministicTool='solver.concrete.flexion' | CRITICAL | Agnes 3.0 + verify job | Needs FEM solver + equilibrium check |
| "Résume ce chapitre" (primary Agnes 429) | complexity=medium, fallback | FALLBACK | Workers AI GLM-4.7 | Agnes unavailable, use fallback |
| "Je suis fatiguée, suggère-moi une session courte" | complexity=low, latency=low, cost=minimal | ROUTINE | Agnes 2.5 Flash | Low energy = fast + cheap |

### 2.5 The Router is DETERMINISTIC (not LLM-based)

**The model selection is NOT done by an LLM.** The router is a
typed function:

```ts
// packages/agent/src/router.ts (server, NOT LLM)
function selectModel(
  profile: TaskProfile,
  registry: AIModelRegistry,
  health: AIHealthRegistry,
  budget: AIBudgetManager
): { provider: string; model: string; attempt: number } {
  const candidates = registry.list({
    capabilities: profile.vision ? ['vision'] : undefined,
    contextSize: profile.contextSize,
    dataPolicy: profile.dataSensitivity,
    status: 'active',
  });
  const available = candidates.filter(c =>
    health.isAvailable(c.provider, c.model) &&
    budget.hasQuota(c.provider, c.model)
  );
  const scored = available.map(c => score(c, profile));
  const best = scored.sort((a,b) => b.score - a.score)[0];
  return { provider: best.provider, model: best.model, attempt: 1 };
}
```

The LLM (the model itself) receives the TaskProfile as context.
But the CHOICE of which LLM to use is deterministic code. This is
ADR v1.7 S6: "Aucun branchement ne doit dépendre d'un mot-clé
naïf dans le prompt. La décision repose sur un profil de tâche
typé."

## Tests

- Event reconciliation: 100 events offline -> reconnect -> all
  applied in order, no duplicates, UI badge shows 100
- Battery: 30 min background = < 2% drain (WorkManager, not service)
- TaskProfile: 20 NL utterances -> correct level assigned
  (ROUTINE/AGENT/VISION/CRITICAL/FALLBACK)
- Router: primary 429 -> fallback selected, AIResponseEnvelope
  records fallbackUsed=true
- Budget: quota exhausted -> router refuses (not a fallback,
  a budget stop)
- CRITICAL: deterministicTool set -> verify job dispatched
  (AD-8, 01 S5.6)
- Data sensitivity: taskProfile.dataSensitivity='sensitive' ->
  router excludes providers with incompatible data policy

## 2.6 Routing Priority (CRITICAL CLARIFICATION, 2026-09-22)

**Agnes is ALWAYS the primary provider for ALL tasks. No exception.**

The routing priority is STRICT:

```
PRIORITY 1 (PRIMARY): Agnes (2.5 Flash / 3.0 / Image 2.5 Flash)
  -> ALL tasks default to Agnes first.
  -> ROUTINE = Agnes 2.5 Flash
  -> AGENT = Agnes 3.0
  -> VISION = Agnes multimodal (if available) or Agnes 3.0
  -> CRITICAL = Agnes 3.0 + ScientificEngine verification
  -> IMAGE = Agnes Image 2.5 Flash (primary) / 2.1 (secondary)

PRIORITY 2 (FALLBACK): ONLY when Agnes returns an error
  -> 429 (rate limit) -> respect retry-after -> if still 429:
  -> 5xx (server error) -> retry 3x (bounded) -> if still failing:
  -> timeout -> retry 1x -> if still failing:
  -> unavailability (provider down) ->
     THEN switch to fallback provider:
       - Cloudflare Workers AI (GLM-4.7 Flash / Gemma 4) [second pool]
       - Groq (GPT-OSS 120B / 20B) [high-speed fallback]
       - OpenRouter / Cohere / Mistral / Gemini [optional, last resort]
       - Cloudflare Worker (direct Workers AI, no Gateway) [last resort]

PRIORITY 3 (RETURN TO AGNES): ALWAYS
  -> The moment Agnes is available again (health check passes,
     cooldown expires, error cleared):
  -> ALL subsequent tasks go BACK to Agnes immediately.
  -> The fallback is a TEMPORARY bridge, NOT a permanent switch.
  -> AIHealthRegistry tracks Agnes availability. When Agnes recovers,
     the router's next call uses Agnes (Priority 1).
  -> No task "locks onto" a fallback provider. Every task re-evaluates:
     "Is Agnes available? YES -> Agnes. NO -> fallback."
```

**This is NOT a "round-robin" or "load-balancing" between providers.**
Agnes is the heart. The others are safety nets. The system prefers
a slightly less powerful but reliable Agnes response over a "better"
fallback response from a different provider (ADR v1.7 S14: "Aurora
doit preferer une reponse legèrement moins puissante mais fiable et
verifiable a une panne totale").

**Exception (data policy only):**
If `taskProfile.dataSensitivity = 'sensitive'` AND Agnes's data policy
is incompatible (e.g., Agnes uses data for training, which the user
has opted out of), the router skips Agnes for THAT SPECIFIC TASK and
uses a provider with compatible data policy. But this is a per-task
exception, not a permanent switch. The next task with
`dataSensitivity = 'public'` goes back to Agnes.

**Model Registry entry (AIHealthRegistry tracks):**

```json
{
  "provider": "agnes",
  "role": "PRIMARY",
  "priority": 1,
  "alwaysFirst": true,
  "returnAfterFallback": true,
  "cooldownOn429": 60,
  "retryOn5xx": 3,
  "fallbackTo": ["workers-ai", "groq", "openrouter"]
}

{
  "provider": "workers-ai",
  "role": "FALLBACK_SECOND_POOL",
  "priority": 2,
  "alwaysFirst": false,
  "onlyWhenPrimaryUnavailable": true
}

{
  "provider": "groq",
  "role": "FALLBACK_OPTIONAL",
  "priority": 3,
  "alwaysFirst": false,
  "onlyWhenPrimaryUnavailable": true
}
```

**The router code enforces this:**

```ts
function selectModel(profile: TaskProfile, registry, health, budget) {
  // 1. ALWAYS try Agnes first (unless data policy exception)
  const agnes = registry.get('agnes', pickAgnesModel(profile));
  if (agnes && health.isAvailable('agnes', agnes.model)
      && budget.hasQuota('agnes', agnes.model)
      && !dataPolicyConflict(profile, agnes)) {
    return { provider: 'agnes', model: agnes.model, attempt: 1,
             reason: 'primary' };
  }
  // 2. Agnes unavailable / 429 cooldown / data conflict -> fallback
  const fallbacks = registry.list({
    role: 'fallback',
    capabilities: profile.vision ? ['vision'] : undefined,
    contextSize: profile.contextSize,
    dataPolicy: profile.dataSensitivity,
    status: 'active',
  });
  const available = fallbacks.filter(f =>
    health.isAvailable(f.provider, f.model) &&
    budget.hasQuota(f.provider, f.model));
  const best = score(available, profile); // pick best available fallback
  if (best) {
    return { provider: best.provider, model: best.model,
             attempt: 1, reason: 'fallback', fallbackUsed: true };
  }
  // 3. No fallback available (CRITICAL task): mark degraded
  if (profile.criticality === 'critical') {
    throw new AIBudgetExhaustedError('All providers unavailable');
    // -> job receives 'degraded' status, user informed
  }
  // 4. No fallback available (ROUTINE task): queue for retry
  return { provider: null, model: null, attempt: 0,
           reason: 'queued', fallbackUsed: false };
  // -> job stays pending; AIHealthRegistry re-checks in 30s;
  //    when Agnes recovers, the job is re-dispatched with Agnes
}
```

**The "return to Agnes" is automatic.** Every task re-evaluates.
There is no "stuck on fallback" state. The moment Agnes's
AIHealthRegistry status flips back to `available` (cooldown
expired, error cleared), the next task uses Agnes. The user never
sees the fallback switch (it's transparent). The `AIResponseEnvelope`
records it for observability, not for user-facing display.
