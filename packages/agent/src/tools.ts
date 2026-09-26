/**
 * Vercel AI SDK — the 8 kernel tools (vercel-ai-sdk-integration.md, wave 3 task 2).
 *
 * AD-1 boundary: this file is the ONLY place in the monorepo that
 * imports the Vercel `ai` SDK (verified by the CI grep test, 01 S7).
 * The 8 tools are typed `tool()` definitions the kernel's Execution
 * Engine hands to `streamText` / `generateText` (maxSteps=5, the
 * 02 S4 streaming surface).
 *
 * Each tool is a THIN adapter: it calls the owning module's command /
 * port (AD-7 single-writer: the kernel never writes a module table —
 * it emits commands; the owning module applies the mutation). Heavy
 * tools (research, qcm_generate, mirror_analyze, scientific_verify)
 * return a job id — the work persists in `job_queue` (AD-8), the
 * dispatcher runs it, the result is observable via `job_queue` /
 * `JobCompleted` (AD-9, F-08).
 *
 * Zero provider keys here (AD-3): the SDK layer only ever sees the
 * `LanguageModel` instance the router built; keys live in the server
 * secret store.
 */
import { tool, type Tool } from 'ai';
import { z } from 'zod';

/**
 * The SDK's `Tool` union (FunctionTool | DynamicTool | …) is not
 * portable through this package's declaration emit (the SDK re-exports
 * it from nested @ai-sdk sub-packages, TS2742). Every `tool()` result
 * below is a FunctionTool-shaped object, so we name it via the SDK's
 * exported `Tool` alias with `any` type args — `any` keeps the input /
 * output positions covariant, so each concrete tool's inferred type is
 * assignable without re-exporting transitive SDK types.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any -- TS2742: the SDK Tool union is not portable through declaration emit (see the doc block above); `any` keeps each concrete tool assignable.
type KernelTool = Tool<any, any>;

/**
 * The 8 kernel tools (capability-catalog S2 / feature-agentability-matrix)
 * + the 7 goal capabilities (dynamic-goal-engine.md). Input schemas are
 * the minimal declared inputs (kernel S14: "typed input (validated before
 * execution)").
 */

/** 1. planDay — compose the day plan (planning.daily → Productivity command). */
export const planDay: KernelTool = tool({
  description: 'Compose the day plan: time-block today + order open tasks (planning.daily).',
  inputSchema: z.object({
    examPeriod: z.boolean().optional(),
    /** the user's declared energy today (low/medium/high) — drives session length */
    energyLevel: z.enum(['low', 'medium', 'high']).optional(),
    /** course ids to reserve blocks for */
    courseIds: z.array(z.string()).optional(),
  }),
  execute: async (input) => {
    // AD-7: emit the Productivity command; the module applies the write.
    // The command bus (kernel S15) routes this to planning.daily.
    return { ok: true, command: 'productivity.plan_day', payload: input };
  },
});

/** 2. schedule — schedule / reorder a time block (calendar.schedule → EventUpdateCommand). */
export const schedule: KernelTool = tool({
  description: 'Schedule or reorder a time block on the calendar (calendar.schedule).',
  inputSchema: z.object({
    /** the subject / task to schedule */
    subject: z.string(),
    /** ISO 8601 start */
    startAt: z.string(),
    /** duration in minutes */
    durationMin: z.number().int().positive(),
  }),
  execute: async (input) => ({ ok: true, command: 'productivity.event_update', payload: input }),
});

/** 3. startFocus — start a focus session (focus.start → FocusController, ADR S5 confirmation). */
export const startFocus: KernelTool = tool({
  description: 'Start a focus session (timer + optional blocklist). Important action — confirmation required (ADR S5).',
  inputSchema: z.object({
    /** planned duration in minutes */
    durationMin: z.number().int().positive().default(25),
    /** linked task ids */
    taskIds: z.array(z.string()).optional(),
    /** the notification policy id */
    notificationPolicy: z.string().optional(),
  }),
  execute: async (input) => ({ ok: true, command: 'focus.start', payload: input }),
});

/** 4. blockApps — block apps during focus (focus.block → DpcAdapter, v1.8 DPC). */
export const blockApps: KernelTool = tool({
  description: 'Suspend the blocklist packages for a focus session (focus.block). DPC-provisioned (OQ-17); degrades to restriction-only when DPC is absent.',
  inputSchema: z.object({
    /** package names to suspend */
    packages: z.array(z.string()),
    /** true = suspend, false = restore (S7 total restore) */
    suspend: z.boolean().default(true),
  }),
  execute: async (input) => ({ ok: true, command: 'focus.blocklist', payload: input }),
});

/** 5. research — run a typed multi-source research query (ResearchProvider port). */
export const research: KernelTool = tool({
  description: 'Run a typed multi-source research query (You.com / Tavily / Exa via the ResearchProvider port). Returns a job id — the work persists in job_queue (AD-8).',
  inputSchema: z.object({
    topic: z.string(),
    domains: z.array(z.string()).default([]),
    kinds: z.array(
      z.enum(['academic', 'scientific', 'technical', 'professional', 'technological', 'other']),
    ).default(['other']),
    region: z.string().optional(),
  }),
  execute: async (input) => {
    // Heavy step → persisted `research` job (AD-8). The dispatcher runs
    // the ResearchProvider; the result is observable via job_queue /
    // JobCompleted (F-08: jobId + jobKind mandatory).
    return { ok: true, jobKind: 'research', payload: input, idempotencyKey: `research:${input.topic}` };
  },
});

/** 6. qcm_generate — generate QCM items for a skill (Learning → artifact_gen job). */
export const qcmGenerate: KernelTool = tool({
  description: 'Generate QCM items for a skill / course (Learning). Heavy step → artifact_gen job (AD-8); the items render via the AD-10 engines when the artifact lands.',
  inputSchema: z.object({
    /** the skill / course the QCM targets */
    skillId: z.string(),
    /** difficulty ladder position (QcmService) */
    difficulty: z.enum(['easy', 'medium', 'hard', 'adaptive']).optional(),
    /** number of items */
    count: z.number().int().positive().default(5),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'artifact_gen', payload: input }),
});

/** 7. mirror_analyze — cognitive mirror analysis of a session (agent_run job). */
export const mirrorAnalyze: KernelTool = tool({
  description: 'Run the cognitive mirror on a learning session: claims vs the semantic tree (Learning + Knowledge). Heavy step → agent_run job (AD-8).',
  inputSchema: z.object({
    /** the transcript of the session */
    transcript: z.string(),
    /** the declared claims to check */
    claims: z.array(z.string()).default([]),
    /** the subject / course id */
    subjectId: z.string().optional(),
  }),
  execute: async (input) => ({
    ok: true,
    jobKind: 'agent_run',
    payload: { capability: 'mirror_cognitive', ...input },
  }),
});

/** 8. scientific_verify — deterministic scientific / engineering verification (ScientificEngine, job). */
export const scientificVerify: KernelTool = tool({
  description: 'Deterministic verification of a scientific / engineering result (ScientificEngine, AD-10). The LLM does NOT solve it — it structures + the solver computes + the verifier validates (engineering-intelligence-layer S1). Heavy step → scientific job (AD-8).',
  inputSchema: z.object({
    /** the domain (math | rdm | concrete | hydraulics | geotech | …) */
    domain: z.string(),
    /** the problem type */
    problemType: z.string(),
    /** typed inputs ({ value, unit } — NEVER a bare number) */
    inputs: z.array(z.object({ key: z.string(), value: z.number(), unit: z.string() })),
    /** requested outputs */
    requestedOutputs: z.array(z.string()).default([]),
  }),
  execute: async (input) => ({ ok: true, jobKind: 'scientific', payload: input }),
});

// ---------------------------------------------------------------------------
// Goal capabilities — the 7 agent goal commands (dynamic-goal-engine.md
// "Agent capabilities"). AD-7: the kernel NEVER writes a module table.
// The GoalProject row is Progress-owned (user_goals, F-07) — every tool
// below EMITS a typed `goal.*` command on the command bus; the Progress
// module applies the mutation and persists it. `goal.create` is
// CONFIRMATION_REQUIRED (the user sees the plan before it goes active);
// decomposition is the LLM step (the `goalDecomposition` payload), the
// assembly/validation is @aurora/goal-engine (the caller wires it, or the
// Progress module re-validates — the shape is the same frozen AD-15 type).
// ---------------------------------------------------------------------------

/** goal.create — NL objective -> GoalProject (CONFIRMATION_REQUIRED, dynamic-goal-engine.md). */
export const goalCreate: KernelTool = tool({
  description:
    'Create a GoalProject from a natural-language objective: decompose into sub-goals + feature placements, assemble the plan. CONFIRMATION_REQUIRED — the user sees the plan before it is active.',
  inputSchema: z.object({
    /** the NL goal, verbatim */
    objective: z.string(),
    /** the typed decomposition (the LLM step's output — GoalDecomposition, @aurora/goal-engine) */
    goalDecomposition: z.record(z.unknown()),
  }),
  execute: async (input) => {
    // AD-7: emit the command; the Progress module applies + persists
    // (user_goals) and confirms with the user before activation.
    return { ok: true, command: 'goal.create', payload: input };
  },
});

/** goal.status — read the GoalProject + GoalProgress (read-only). */
export const goalStatus: KernelTool = tool({
  description: 'Read a GoalProject with its progress snapshot (GoalProject + GoalProgress).',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.status', payload: input };
  },
});

/** goal.recompose — ADR S13: re-plan without destroying history. */
export const goalRecompose: KernelTool = tool({
  description:
    'Re-plan a GoalProject when progress stalls or context changes (ADR S13: recalcul du planning restant sans détruire l\'historique).',
  inputSchema: z.object({
    goalId: z.string(),
    /** the new decomposition (same shape as goal.create) */
    goalDecomposition: z.record(z.unknown()),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.recompose', payload: input };
  },
});

/** goal.pause — jobs stop, notifications mute (AD-7: data mutation by Progress). */
export const goalPause: KernelTool = tool({
  description: 'Pause a GoalProject: active features stop (jobs stop, notifications mute). Progress + history are preserved.',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.pause', payload: input };
  },
});

/** goal.complete — the Progress module checks the success criteria (F-07). */
export const goalComplete: KernelTool = tool({
  description:
    'Mark a GoalProject complete — only when the success criteria are met. The check + evidence are Progress-owned (F-07 sole producer of ProgressEvidenceCreated).',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.complete', payload: input };
  },
});

/** goal.abandon — data preserved, features deactivated (AD-15 additive). */
export const goalAbandon: KernelTool = tool({
  description:
    'Abandon a GoalProject: the row + all progress/history are preserved (AD-15), the goal\'s features are deactivated.',
  inputSchema: z.object({
    goalId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.abandon', payload: input };
  },
});

/** goal.feature.add — "et ajoute des QCM chaque semaine". */
export const goalFeatureAdd: KernelTool = tool({
  description:
    'Add a feature to an active GoalProject\'s composition ("ajoute des QCM chaque semaine").',
  inputSchema: z.object({
    goalId: z.string(),
    featureId: z.string(),
    /** optional: attach the feature to a specific sub-goal */
    subGoalId: z.string().optional(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.feature.add', payload: input };
  },
});

/** goal.feature.remove — "plus besoin de focus sur ce but". */
export const goalFeatureRemove: KernelTool = tool({
  description: 'Remove a feature from an active GoalProject\'s composition ("plus besoin de focus sur ce but").',
  inputSchema: z.object({
    goalId: z.string(),
    featureId: z.string(),
  }),
  execute: async (input) => {
    return { ok: true, command: 'goal.feature.remove', payload: input };
  },
});

/**
 * The full kernel tool set, keyed by the canonical tool ids the Planner's
 * `resolveTool` + `ExecutionEngine.invoke` address them by
 * (capability.tool === these keys).
 */
export const KERNEL_TOOLS = {
  planDay,
  schedule,
  startFocus,
  blockApps,
  research,
  qcm_generate: qcmGenerate,
  mirror_analyze: mirrorAnalyze,
  scientific_verify: scientificVerify,
  goal_create: goalCreate,
  goal_status: goalStatus,
  goal_recompose: goalRecompose,
  goal_pause: goalPause,
  goal_complete: goalComplete,
  goal_abandon: goalAbandon,
  goal_feature_add: goalFeatureAdd,
  goal_feature_remove: goalFeatureRemove,
};

export type KernelToolId = keyof typeof KERNEL_TOOLS;
export type ToolSet = typeof KERNEL_TOOLS;
