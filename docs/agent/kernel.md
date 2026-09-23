# Agent Kernel — Technical Specification

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 3). Authority: spine AD-12 (one kernel, server-side),
F-09 (placement), AD-3 (no keys on device), AD-8 (heavy = jobs), ADR §5/§13/§14/§16,
`01-backend` §5.6, `02-frontend` §4.

## 1. Purpose

One central, **server-side** kernel that turns user intent + context into verified,
permitted action and durable memory. Planner, Coach, Tutor, Researcher and Executor are
kernel **capabilities** (ADR §26.8), not deployed agents (AD-12: N independently deployed
agents are forbidden — they would drift into incompatible context/permission models).

## 2. Responsibilities / non-responsibilities

Responsibilities: intent understanding, context assembly, planning, retrieval, tool
orchestration, verification, guarded action, result capture, memory (Expert Skills),
proactive Coach interactions (ADR §13: contextual check-ins, change detection, dynamic
replanning, discipline coaching, longitudinal memory, user-controlled cadence/silence
windows).

Non-responsibilities: never mutates a module table directly (AD-7/F-03 — it emits
commands/events; the owning module applies the mutation); never emits `ArtifactGenerated`
(it requests generation; the Artifact module emits after R2 upload, F-06); never reads/writes
`NodeState` (Knowledge only, AD-6); never runs on-device (F-09); never holds provider keys
(AD-3).

## 3. The loop (frozen, AD-12)

`Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory`

1. **Intent** — intent context + classified task profile (typed, not prompt keywords, ADR v1.7 §6).
2. **Context** — the 9 context forms (ADR §16): Intent, Personal, Productivity, Learning,
   Discovery, Semantic, Expert Skills, Tool, Permission. Built server-side (Context Builder,
   01 §5.6) over the module public contracts (AD-2) — projections are declared views of
   AD-15 types, never re-declarations (AD-15).
3. **Plan** — capability selection; confirmation requested for important/irreversible
   actions (ADR §5).
4. **Retrieve** — `KnowledgeBase` port: Postgres FTS + pgvector + R2 documents; provenance
   (AD-11) attached to every retrieved formulation.
5. **Tools** — typed tool calls through the AI pipeline (`AIProvider` → router → policy →
   gateway → provider adapter); optional capabilities degrade when absent (AD-1).
6. **Verify** — for critical tasks: KB/source check and/or `ScientificEngine` deterministic
   validation, **as a persisted server job** (AD-8, 01 §5.6); a second "judge" model only
   when the verification value justifies the quota spend (ADR v1.7 §14).
7. **Action** — emits domain commands / AD-9 events; the owning module applies the write
   (single-writer). Destructive operations: Permission Context gate + confirmation.
8. **Result** — normalized result + traceable `AIResponseEnvelope` (provider, model,
   attempt, reason, expected quality — AD-5).
9. **Memory** — `expert_skills` (server-only table, 03 §4.2): trigger/goal/procedure/
   constraints/examples/counter-examples/confidence/provenance/validation date/obsolescence
   conditions (ADR §14.2); error loop and success loop per ADR §14.3/§14.4; guardrails
   ADR §14.5 (no one-shot hypothesis promoted to durable truth; provenance kept; user can
   correct/disable/delete; contradiction detection; periodic review).

## 4. User surface

The device consumes **only `AgentRunState`** (02 §4, F-09) via `packages/agent`; it never
imports `AIProvider`/`AIModelRouter` client-side (AI_RULES). Kernel execution =
`fn-agent-run` + jobs (01 §5.1/§5.6). Coach proactivity = OneSignal check-ins honoring
silence windows (ADR §13, 04 §3.4 `setSubscribed`).

## 5. Permissions, confirmations, destructive ops

Permission Context (ADR §16): every tool is classified **read / write / destructive**.
Read = free; write = authorized scope; destructive/irreversible = explicit confirmation
(ADR §5 "Demander confirmation pour les actions importantes ou irréversibles"). The
Permission Context form is assembled per session from `user_context` (Identity) + user
settings. Kernel actions are replayable via the job system (AD-8 idempotency).

## 6. Provenance & observability

Every agent output carries provenance (documents/pages/passages/sources — AD-11; corpus
fidelity: authoritative formulations stay textually dominant, agent explanations labeled and
separated, ADR §17). Traces: `AIResponseEnvelope` on every model call (AD-5), job logs
(`job_logs`, 01 §5.3), Sentry/PostHog (AD-16d), `AgentRunState` for the UI.

## 7. Data

Server-only state: `expert_skills` (Agent module, 01 §4.7), run/job records (`job_queue`),
consumed events (`TaskCompleted` re-plan, `GoalUpdated`, `ProgressEvidenceCreated` context,
`SkillStateChanged` expert-skill targeting, `DiscoveryItemCreated` next recommendations —
AD-9 consumer declarations in the Agent Contract Pack, AD-13). No agent memory is synced to
the device (AD-3, 03 §4.2 `expert_skills` row).

## 8. Errors & fallbacks

Provider failures: AD-5 retry (transient) vs fallback (unavailability/incompatibility/limit);
429 → cooldown, **never** key rotation; traceability mandatory (01 §7 tests a–e). Budget
exhaustion: `AIBudgetManager` stops **before** overrun (job receives `budgetSnapshot`),
graceful partial result. Data-policy mismatch: `AIRequestGuard` refuses before the call
(01 §6). Verification failure: task marked degraded (`expectedQuality: 'degraded'`), user
informed, never silently accepted.

## 9. Tests (wave 3)

Loop property tests (intent→action on fixtures), permission-gate tests (destructive without
confirmation = blocked), single-writer test (kernel `Action` writes no table — 01 §7),
fallback traceability (01 §7), Expert-Skill guardrail tests (contradiction, obsolescence),
Coach non-intrusiveness (silence windows honored, ADR §13).

## 10. Durable execution

Multi-step kernel workflows survive crashes by design: state lives in Postgres
(`job_queue` + step records), executors are stateless (AD-8). If the Agent team later wants
a library-grade workflow engine (e.g. Postgres-backed durable execution), it is an
**internal detail behind `DispatcherApi` + the job store**: no new trigger sources (AD-8:
Cron + Postgres trigger only), no client contract change, additive ADR, owner
Foundation + Agent (recorded in `01-backend` §8.3, wave-3 option). Not in wave 0.

## 11. Future evolution

Phase 2 desktop reuses the same kernel (platform-agnostic, ADR §23). Event Sourcing,
multi-tenant agent fleets and Yjs-assisted memory are explicitly out of V1 (spine
§ Deferred).

## 12. Component architecture (master mission §6 — the 15 components)

All components run **server-side** (AD-12/F-09, 01 §5.6); the device only sees
`AgentRunState`. Fixed loop: Intent → Context → Plan → Retrieve → Tools → Verify →
Action → Result → Memory.

| Component | Responsibility | Normative constraint |
|---|---|---|
| **Intent Engine** | classify the user goal into a typed intent + task profile (never prompt keywords, ADR v1.7 §6); disambiguation + missing-info handling (§13) | typed `TaskProfile` (complexity, reasoning, tools, vision, context size, latency, cost, criticality, verification need, data sensitivity) |
| **Context Builder** | assemble the 9 context forms (Intent, Personal, Productivity, Learning, Discovery, Semantic, Expert Skills, Tool, Permission — ADR §16) from module **public contracts** | projections of AD-15 types, never re-declarations (AD-15); server-side only (01 §5.6) |
| **Planner** | build a capability plan (steps + tool sequence + confirmation points); dynamic replan on change (ADR §13 Coach) | plan = data, re-runnable; "recalcul du planning restant sans détruire l'historique" (ADR §13) |
| **Capability Registry** | discover module capabilities (§14) | the kernel **discovers**, never hardcodes a growing condition list (mission §8) |
| **Tool Registry** | tool definitions (input/output schemas, scopes) per capability | tools = typed functions with declared read/write scopes |
| **Tool Resolver** | pick the tool for a plan step given context + availability (provider present? feature enabled? offline class?) | graceful degradation when absent (AD-1 last paragraph) |
| **Permission Engine** | read/write/destructive classification per action (Permission Context form, ADR §16) | destructive/irreversible = confirmation mandatory (ADR §5) |
| **Confirmation Engine** | surfaces confirmations to the user (UI `AgentRunState`), blocks until answered; timeout = safe-cancel | confirmations are part of the plan, not an afterthought |
| **Model Router** | select model/provider via `AIModelRouter` + `AIModelPolicy` + `AIBudgetManager` (ADR v1.7 §9) → AI Gateway | no concrete model name in domain code (AD-1, ADR v1.7 §1); typed TaskProfile only |
| **Execution Engine** | run the plan step-by-step (tool calls, jobs for heavy steps) | heavy steps = persisted jobs (AD-8); jobs carry idempotency keys |
| **Verification Engine** | verify results: KB/source check + `ScientificEngine` for critical tasks (as a **server job**, 01 §5.6); optional second "judge" model only when justified (ADR v1.7 §14) | corpus fidelity (AD-11); verification failures mark `expectedQuality:'degraded'` |
| **Result Normalizer** | every model answer → `AIResponseEnvelope` (provider/model/attempt/reason/expectedQuality/fallbackUsed/traceId, 01 §3.1) | AD-5 traceability — no untraced fallback |
| **Memory** | `expert_skills` (server-only table, 03 §4.2): error loop / success loop / guardrails (ADR §14.2–14.5) | provenance + confidence + obsolescence conditions; user can correct/disable/delete |
| **Observability** | run traces (job_logs, Sentry, PostHog), `AIUsageTracker` feeds, per-kind SLOs (AD-16d) | duty owner = Foundation until a module owns traffic |
| **Error Recovery** | bounded retry (transient) vs fallback (unavailability/incompatibility/limit); budget stop-before-overrun (`budgetSnapshot`); graceful partial results | a 429 is never bypassed by key rotation (AD-5); recovery = resume from persisted step state |

## 13. Natural language → action (master mission §7)

Pipeline: `NL utterance → Intent Engine (typed profile + disambiguation) → Context
Builder → Planner (capability plan + confirmation points) → Tool Resolver →
Execution (commands to owning modules / jobs / gateway) → Verification → Result
Normalizer → Memory`. Disambiguation = follow-up when the intent is ambiguous
(never guess destructive parameters); missing information = explicit ask with
inferred defaults **flagged as inferred**; rollback = the plan records, per step,
its compensating action (e.g. "created task X" → cancel/delete X on abort) —
applied on user abort or verification failure.

**Mandatory example (mission §7):**

> "Organise ma journée, mets deux heures de géotechnique ce matin, démarre une
> session Focus et bloque TikTok et WhatsApp."

```
Intent: composite (plan_day + schedule + focus_start + block_apps)
  ↓ Context retrieval: today's calendar + tasks + available time (Productivity
    Context), exam period? (Personal Context), focus blocklist history
  ↓ Task analysis: geotechnique course identified (Learning Context → subject),
    2 h estimate checked against morning availability (time blocking)
  ↓ Planning: create time block 09:00-11:00 geotechnique (calendar.schedule),
    reorder morning tasks (planning.daily), focus session (2 h, blocklist
    [TikTok, WhatsApp])
  ↓ Focus configuration + start: focus.start(taskId?, 120 min, blocklist) —
    v1.8 DPC: precheckBlocklist (suspendability matrix, focus spec §4); consumer
    profile: restriction-only notice
  ↓ selected app restriction: setPackagesSuspended([tiktok, whatsapp], true)
    (DPC nominal) / reduceForFocus fallback
  ↓ final confirmation/result: AgentRunState shows the plan summary + the focus
    start confirmation (focus start = important action → confirm, ADR §5) →
    execution + "session démarrée, 2h, TikTok & WhatsApp bloqués (profil DPC)"
```

Every step maps to a registered capability (`planning.daily`, `calendar.schedule`,
`focus.start`, `focus.block` — feature-agentability-matrix.md); the agent never
improvises an unregistered action.

## 14. Capability Registry (master mission §8 — discovery, not hardcoding)

```ts
interface AgentCapability {
  id: string;                     // "task.create", "focus.start", "course.search" …
  name: string;
  description: string;
  inputSchema: unknown;           // typed input (validated before execution)
  outputSchema: unknown;          // typed output
  readScopes: string[];          // e.g. ["productivity:read", "learning:read"]
  writeScopes: string[];         // e.g. ["productivity:write"]
  permissions: string[];         // native/platform permissions the feature needs (focus: POST_NOTIFICATIONS / DPC)
  dependencies: string[];        // capability ids or provider/feature ids required
  requiresConfirmation: boolean; // important/irreversible actions (ADR §5)
  destructive: boolean;          // destructive class (Permission Engine)
  supportsNaturalLanguage: boolean;
  platform?: "shared" | "android" | "desktop";
  offlineClass?: "offline-capable" | "online-required" | "hybrid";  // planner must not
                                                                   // plan online-only steps into offline windows
}
```

Registration: each module declares its capabilities in its **Contract Pack**
(AD-13) — types in `packages/domain` (AD-15 SSoT), runtime registry owned by
`packages/agent` (server). The kernel's Capability/Tool Registries are built from
these declarations (+ availability checks: provider present per `AIHealthRegistry`,
feature enabled per the feature registry, platform capability per the deployment
profile — e.g. `focus.block` = android + DPC-provisioned, OQ-17). A disabled
feature removes its capabilities from the discoverable surface (feature-registry.md
§2 chain) — the agent **adapts**, it does not know users by name.

## 15. Agent ↔ Frontend surface (mission §61–§63 — the agent drives the UI through commands, never React)

The kernel **never touches React components** (mission §77). Its effects on the
UI are a typed contract (SSoT `packages/domain`, consumed by `apps/mobile`
shell + `packages/agent`):

```
Agent Action (server)
  ↓ AgentActionEnvelope { actionId, kind, payload, confirmationRequired?, deepLink? }
Application Command Bus (apps/mobile shell — the single bus, 02 §4)
  ↓ NavigationIntent { route, params, query, focusElement? }  →  Frontend Router (02 §6)
  ↓ UiStateCommand { select, filter, expandNode, showArtifact, startFocus… } → Zustand ui-state (02 §3)
  ↓ FeatureCommand (same use-cases as UI buttons — no duplicated logic, mission §17)
User-visible result (a screen opened / entity selected / artifact shown)
```

- **Allowed agent UI actions** (mission §61/§62): create (via use-cases),
  navigate/open (deep link via the bus), filter/select/expand-node (ui-state
  commands), show generated artifact (`/artifacts/:id`), start focus
  (`/focus` + `focus.start`), schedule (calendar view + time block), display
  result (`AgentRunState` inline + optional target screen), request
  confirmation (blocking UI surface, kernel §12 Confirmation Engine).
- **Not allowed**: raw DOM/React manipulation (`document.querySelector` is
  forbidden by the AD-10 boundary culture — the router/bus is the only door),
  bypassing navigation rules (02 §6: details open over the current tab; a
  disabled feature is never navigable), or authorization (Permission Engine
  decisions are final; the UI only renders them).
- **Command bus = single source of UI actions**: UI buttons, command palette,
  agent actions, deep links and automations all resolve to the **same
  application commands** (mission §17, feature-registry §4) — business logic is
  written once (02 §4 use-cases), never duplicated between agent and UI
  (mission §77).
- **Agent ↔ UI state** (mission §62): `UiStateCommand` cases = open page ·
  select entity · filter · expand node · show generated artifact · start focus —
  consumed by the shell store; each command is idempotent and safe to drop on
  app-kill (the deep link re-creates it, context-preserving navigation).
