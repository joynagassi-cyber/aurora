/**
 * @aurora/agent — Agent Kernel shared types (wave 3, ORACLE).
 *
 * Authority: docs/agent/kernel.md S12-S15, docs/ai/vercel-ai-sdk-integration.md,
 * ADR v1.7 S6 (typed TaskProfile — never keyword sniffing), AD-15 (types
 * consumed from @aurora/domain where frozen).
 *
 * This file is the kernel-local vocabulary (server-side, AD-12).
 * Domain-frozen types (AgentRun, AgentActionEnvelope, NavigationIntent,
 * UiStateCommand, AgentCapability, JobKind, ...) come from @aurora/domain.
 */

/**
 * Typed TaskProfile (ADR v1.7 S6, providers-and-routing S10).
 * The Intent Engine produces it; the Model Router consumes it.
 * NEVER derived from prompt keywords (02 S4 mission S13 example is the
 * canonical classification, not a string match).
 */
export interface TaskProfile {
  /** 'low' | 'medium' | 'high' — derived from gap_urgency + skill_freshness */
  complexity: 'low' | 'medium' | 'high';
  /** 'none' | 'basic' | 'deep' — engineering = deep, routine = none */
  reasoning: 'none' | 'basic' | 'deep';
  /** number of tools expected for this task (more = AGENT profile) */
  tools: number;
  /** whether the task needs image/document input */
  vision: boolean;
  /** estimated context size in tokens (sum of 9 context forms) */
  contextSize: number;
  /** latency budget — low energy / high interruptions = 'critical' */
  latency: 'normal' | 'important' | 'critical';
  /** cost budget — constrained when remaining quota is low */
  cost: 'unconstrained' | 'moderate' | 'constrained';
  /** criticality — exam/deadline proximity drives verification need */
  criticality: 'routine' | 'important' | 'critical';
  /** whether deterministic/KB verification is required (engineering = always) */
  verification: boolean;
  /** 'public' | 'sensitive' — sensitive data prefers local / ZDR providers */
  dataSensitivity: 'public' | 'sensitive';
  /**
   * The device's explicit model picker choice (AD-3: the picker is
   * public config; the kernel enforces AD-5 fallback server-side).
   * When set, the model layer pins this provider/model as the first
   * eligible selection in the chain; AD-5 fallback to the next
   * provider still applies on 429 / error (the pinned provider is
   * recorded in the health gate, not bypassed).
   * `undefined` = the S2.6 router picks automatically.
   */
  preferredProvider?: string;
  preferredModel?: string;
  /**
   * Thinking effort level (Vercel AI SDK reasoning tier, ADR v1.7 S9):
   * low = fast, medium = balanced, high = deep reasoning, max = full
   * chain-of-thought + tool use. Default = medium.
   */
  thinkingLevel?: 'low' | 'medium' | 'high' | 'max';
  /**
   * Research mode (the kernel activates the Discovery port):
   *   off       = no research job, use only local context
   *   standard  = ResearchProvider (Exa/Tavily/You.com) for one round
   *   deep      = multi-round research + source verification (01 §6.1)
   */
  researchMode?: 'off' | 'standard' | 'deep';
  /**
   * The agent's interaction mode (kernel §4 user surface):
   *   chat    = free-form conversation, no autonomous tool loop
   *   agent   = autonomous: plan → tools → verify → act (full kernel)
   *   mirror  = teach-the-AI mode: user explains what they learned,
   *             the agent stores it as an expert skill (ADR S14)
   */
  agentMode?: 'chat' | 'agent' | 'mirror';
}

/** The routing level a TaskProfile resolves to (ADR v1.7 S7 levels). */
export type TaskLevel = 'ROUTINE' | 'AGENT' | 'VISION' | 'CRITICAL' | 'FALLBACK';

/** An intent classification (Intent Engine output — typed, not keywords). */
export interface Intent {
  /** canonical intent ids (docs/agent/natural-language-intents.md) */
  kind: string;
  /** composite intents carry their constituent intents */
  parts?: string[];
  /** the typed task profile derived from the intent + context */
  profile: TaskProfile;
  /** missing information the kernel must ask for (inferred defaults flagged) */
  missing?: Array<{ field: string; inferredDefault?: unknown }>;
  /** ambiguity score 0..1 — above threshold = follow-up question, never guess */
  ambiguity: number;
}

/** A planner step: data, re-runnable, with its compensating action. */
export interface PlanStep {
  /** stable step id (re-plan preserves executed history, ADR S13) */
  stepId: string;
  /** the capability / tool this step executes */
  tool: string;
  /** validated tool input */
  input: Record<string, unknown>;
  /** read/write/destructive classification (Permission Engine) */
  risk: 'read' | 'write' | 'destructive';
  /** confirmation points (ADR S5) — destructive/important => required */
  confirmationRequired: boolean;
  /** the compensating action applied on abort / verification failure */
  compensation?: Record<string, unknown>;
  /** heavy steps persist as a job (AD-8) instead of inline execution */
  jobKind?: string;
  /** outcome of the step once executed */
  status: 'pending' | 'running' | 'done' | 'failed' | 'skipped' | 'awaiting-confirmation';
  result?: unknown;
}

/** The planner output: ordered steps + confirmation points (plan = data). */
export interface Plan {
  planId: string;
  steps: PlanStep[];
  /** which steps need user confirmation before execution */
  confirmationPoints: string[];
  /** created from this intent (traceability) */
  intentKind: string;
}

/**
 * The 9 context forms (ADR S16) assembled server-side from module public
 * contracts (AD-2): projections of AD-15 types, never re-declarations.
 */
export interface AgentContext {
  /** form 1 — the classified intent + task profile */
  intent: Intent;
  /** form 2 — Personal Context (UserContext: energy, silence window) */
  personal: Record<string, unknown>;
  /** form 3 — Productivity Context (today's calendar + tasks + free time) */
  productivity: Record<string, unknown>;
  /** form 4 — Learning Context (course / subject, due items) */
  learning: Record<string, unknown>;
  /** form 5 — Discovery Context (competence profile, next recommendations) */
  discovery: Record<string, unknown>;
  /** form 6 — Semantic Context (tree nodes + states, provenance AD-11) */
  semantic: Record<string, unknown>;
  /** form 7 — Expert Skills Context (active skills + hypotheses) */
  expertSkills: Record<string, unknown>;
  /** form 8 — Tool Context (available tools + provider availability) */
  tool: Record<string, unknown>;
  /** form 9 — Permission Context (scopes, destructive gates, feature state) */
  permission: Record<string, unknown>;
  /** form 10 — Active user skills (user_skills rows, Task 1/2).
   *  Feeds prompt layer 1. Degrades to {} when the assembler lacks the
   *  loadUserSkills seam (AD-1: the loop continues without skills). */
  skills: Record<string, unknown>;
}

/**
 * The kernel run state the device sees (02 S4, AD-12/F-09).
 * Server-side ONLY — this is the single device-facing type. The device
 * never sees AIProvider / router / keys (AD-3).
 */
export interface AgentRunState {
  agentRunId: string;
  /** kernel loop stage (AD-12 frozen loop) */
  stage:
    | 'intent'
    | 'context'
    | 'plan'
    | 'retrieve'
    | 'tools'
    | 'verify'
    | 'action'
    | 'result'
    | 'memory'
    | 'done'
    | 'failed';
  status: 'running' | 'awaiting-confirmation' | 'succeeded' | 'failed' | 'cancelled';
  /** the plan so far (steps + their statuses) — streamed to the device */
  plan?: Plan;
  /** the pending confirmation when status = 'awaiting-confirmation' */
  confirmationMessage?: string;
  confirmationStepId?: string;
  /** streamed text chunks (model output, normalized) */
  text?: string;
  /** tool call log (ad-hoc, human-readable) */
  toolLog?: Array<{ tool: string; input: unknown; at: string }>;
  /** the last AIResponseEnvelope for the most recent model call (AD-5) */
  envelope?: import('@aurora/domain').AIResponseEnvelope<unknown>;
  /** degraded quality notice (never silently accepted, kernel S8) */
  degraded?: boolean;
  startedAt: string;
  updatedAt: string;
}

export type { PlanStep as AgentKernelPlanStep };
