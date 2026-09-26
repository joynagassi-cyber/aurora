/**
 * @aurora/workflows — composite workflow contracts (wave 4, HARPYS).
 *
 * Authority: docs/workflows/composite-workflows.md (W1–W23), AD-2/AD-7/AD-9,
 * AD-12 (single server kernel — the device sees only AgentRunState), AD-8
 * (heavy work = persisted idempotent jobs), 05 S4 (mobile UI slices).
 *
 * Each workflow is DETERMINISTIC DATA, not prose: it pins the 12 lanes
 * (Trigger -> Actors -> Modules -> Capabilities -> Data -> Events -> Jobs ->
 * UI -> Agent -> Permissions -> Failure -> Recovery) so a workflow can be
 * validated mechanically against the closed AD-9 vocabulary, the AD-15 job
 * vocabulary, and the single-writer rule (AD-7).
 */
import type { DomainEventName, JobKind } from '@aurora/domain';

/** The owning module of a lane — every module that exists in the monorepo. */
export type WorkflowModule =
  | 'Learning'
  | 'Knowledge'
  | 'Discovery'
  | 'Progress'
  | 'Productivity'
  | 'Artifact'
  | 'Integrations'
  | 'Agent';

/** UI transitions — `apps/mobile` slice keys (05 S4) + server side ('S'). */
export interface UiTransition {
  /** from-screen slice key (05 S4 / 02 S6.1 route map) */
  from: string;
  /** to-screen slice key */
  to: string;
  /** server-side (job/gateway), not a screen transition */
  server?: boolean;
}

/**
 * One composite workflow — the 12-lane spec (docs/workflows
 * composite-workflows.md). Validation (validate.ts) checks the invariants:
 * only the 9 events (AD-9), only AD-15 JobKinds (AD-8), single-writer
 * commands (AD-7), no direct cross-module table access (AD-2).
 */
export interface Workflow {
  /** 'W1'..'W23' */
  id: string;
  name: string;
  /** lane 1 — what fires the workflow (event name, user action, or schedule) */
  trigger: string;
  /** lane 2 — who acts (user, Agent roles, modules) */
  actors: string[];
  /** lane 3 — modules involved, in flow order */
  modules: WorkflowModule[];
  /** lane 4 — capability ids (feature-agentability-matrix vocabulary) */
  capabilities: string[];
  /** lane 5 — tables / R2 objects touched (owner module = single writer, AD-7) */
  data: string[];
  /** lane 6 — AD-9 events this workflow EMITS (producer = the owning module) */
  eventsEmitted: DomainEventName[];
  /** lane 6b — AD-9 events this workflow OBSERVES (via the events table) */
  eventsConsumed: DomainEventName[];
  /** lane 7 — AD-8 heavy jobs (server, persisted, idempotent) */
  jobs: JobKind[];
  /** lane 8 — UI transitions (5 UX states per screen, AD-13) */
  ui: UiTransition[];
  /** lane 9 — Agent role + action (server kernel, AD-12; device = AgentRunState only) */
  agent: { role: string; action: string };
  /** lane 10 — permissions / platform gates (camera, mic, notifications, DPC) */
  permissions: string[];
  /** lane 11 — failure modes */
  failures: string[];
  /** lane 12 — recovery (idempotent retry, local mirror, job re-dispatch) */
  recovery: string;
}

/** Validation verdict for one workflow. */
export interface WorkflowValidation {
  id: string;
  ok: boolean;
  /** violated invariants (empty when ok) */
  violations: string[];
}

/** Error classes E1–E10 (docs/agent/error-recovery.md, S64). */
export type ErrorClassId =
  | 'E1' // provider error (AI call fails)
  | 'E2' // permission error (insufficient scope / platform permission)
  | 'E3' // network error (offline / connectivity loss)
  | 'E4' // auth expired (Supabase / OneSignal / Composio)
  | 'E5' // feature disabled (registry state change mid-session)
  | 'E6' // tool unavailable (Composio / OCR / STT absent)
  | 'E7' // invalid input (data / AI output vs schema)
  | 'E8' // conflicting data (CRDT collision / optimistic update rejected)
  | 'E9' // partial execution (multi-step plan, some steps done)
  | 'E10'; // destructive action confirmed then fails

/** What happened in an error class — the four recovery questions
 *  (error-recovery.md convention: executed / not executed / retryable /
 *  needs confirmation). */
export interface ErrorClass {
  id: ErrorClassId;
  title: string;
  whatHappened: string;
  executed: string;
  notExecuted: string;
  retryable: string;
  needsConfirmation: boolean;
  recovery: string;
}

/** Self-improvement loop stage (expert-skills-extensions.md §3). */
export type SelfImprovementStage =
  | 'progress-gap' // 1. PROGRESS detects a gap
  | 'self-improve-triage' // 2. causal analysis (S18.4: correlation != causation)
  | 'discovery' // 3. optional research (ResearchProvider)
  | 'skill-revised' // 4. Expert Skill revised / hypothesis generated
  | 'next-session-applied' // 5. Agent applies the updated skill
  | 'progress-recorded'; // 6. outcome recorded -> loop continues
