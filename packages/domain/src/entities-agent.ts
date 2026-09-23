/**
 * Agent entities (AD-15 SSoT, 01 S4.7).
 *
 * `expert_skills` is SERVER-ONLY (no local mirror — 03 S4.2 invariant 5;
 * agent memory is never synced to device, AD-3).
 */

/**
 * ExpertSkill — a small, reusable procedural competence the agent distilled
 * from verified recurrent learnings (ADR S14.2: trigger, objective,
 * procedure, constraints, success examples, known failures, confidence,
 * source, validation history, obsolescence conditions).
 */
export interface ExpertSkill {
  id: string;
  /** which user the skill belongs to (server-only, RLS per user) */
  userId: string;
  /** a stable skill id the kernel can reference (e.g. "planning.heavy-day") */
  key: string;
  /** when the skill should be used (ADR S14.2) */
  trigger: string;
  /** the result it aims to produce (ADR S14.2) */
  objective: string;
  /** recommended steps (ADR S14.2) */
  procedure: string[];
  /** what to avoid (ADR S14.2) */
  constraints?: string[];
  /** success examples (ADR S14.2) */
  successExamples?: string[];
  /** known failures / counter-examples (ADR S14.2) */
  failures?: string[];
  /** 0..1 (ADR S14.2: confidence level, always kept) */
  confidence: number;
  /** provenance (ADR S14.2: observation / user correction / document /
   *  test / other evidence) */
  source: 'observation' | 'user-correction' | 'document' | 'test' | 'other';
  /** lifecycle (01 S4.7: candidate / validated / deprecated) */
  status: 'candidate' | 'validated' | 'deprecated';
  /** when validated */
  validatedAt?: string;
  /** conditions under which to revise or retire (ADR S14.2) */
  obsolescenceConditions?: string[];
  createdAt: string;
  updatedAt: string;
}

/**
 * AgentRun — the UI-visible state of a kernel run (02 S4: the device
 * sees ONLY AgentRunState, F-09; kernel execution is server-side).
 */
export interface AgentRun {
  id: string;
  userId: string;
  /** ULID action id (idempotent, contract-catalog S11) */
  actionId: string;
  /** the capability invoked */
  capabilityId?: string;
  /** kernel loop stage (AD-12: Intent→Context→Plan→Retrieve→Tools→
   *  Verify→Action→Result→Memory) */
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
  /** the server job driving the run (AD-8/F-09) */
  jobId?: string;
  /** streaming state consumed by the mobile shell (02 S4) */
  status: 'running' | 'awaiting-confirmation' | 'succeeded' | 'failed' | 'cancelled';
  /** the confirmation prompt when the action is important/irreversible
   *  (ADR S5: confirmation for important or irreversible actions) */
  confirmationMessage?: string;
  startedAt: string;
  updatedAt: string;
}
