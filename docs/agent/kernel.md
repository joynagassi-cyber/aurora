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
