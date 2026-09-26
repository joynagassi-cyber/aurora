/**
 * Agent Kernel — 15 components (kernel.md S12, wave 3, ORACLE).
 *
 * All components run server-side (AD-12/F-09); the device sees ONLY
 * `AgentRunState` (AD-3: no keys / provider internals on the device).
 *
 * Fixed loop (frozen, AD-12):
 *   Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory
 *
 * Component map (15):
 *   1.  Intent Engine          → intent.ts
 *   2.  Context Builder        → context.ts
 *   3.  Planner                → planner.ts
 *   4.  Capability Registry    → capability.ts
 *   5.  Tool Registry          → capability.ts
 *   6.  Tool Resolver          → capability.ts
 *   7.  Permission Engine      → permission.ts
 *   8.  Confirmation Engine    → confirmation.ts
 *   9.  Model Router           → router.ts
 *   10. Execution Engine       → execution.ts
 *   11. Verification Engine   → verification.ts
 *   12. Result Normalizer     → result.ts
 *   13. Memory                → memory.ts
 *   14. Observability         → observability.ts
 *   15. Error Recovery        → recovery.ts
 *
 * The orchestrating loop lives in `kernel.ts` (wire-up); each component
 * is a pure, independently testable module — the kernel owns the
 * orchestration, components own their own state machines.
 */

// 1. Intent Engine
export {
  classifyIntent,
  buildTaskProfile,
  levelFor,
  type IntentRequest,
} from './intent.ts';

// 2. Context Builder
export {
  buildAgentContext,
  type ContextAssembler,
} from './context.ts';

// 3. Planner
export {
  buildPlan,
  replanRemaining,
  type PlannerDeps,
} from './planner.ts';

// 4-6. Capability + Tool Registry + Tool Resolver
export {
  DefaultCapabilityRegistry,
  resolveTool,
  type CapabilityEntry,
  type ToolResolver,
} from './capability.ts';
// 7. Permission Engine
export {
  classifyAction,
  isAllowed,
  type PermissionContext,
} from './permission.ts';

// 8. Confirmation Engine
export {
  ConfirmationEngine,
  type ConfirmationDecision,
  type ConfirmationPrompt,
} from './confirmation.ts';

// 9. Model Router (Agnes-primary, S2.6)
export {
  AgnesPrimaryRouter,
  AGNES_REGISTRY,
  type ProviderModel,
  type HealthChecker,
  type BudgetChecker,
  type DataPolicy,
  type RouterRegistry,
} from './router.ts';

// 10. Execution Engine
export {
  ExecutionEngine,
  type ExecutionDeps,
  type StepOutcome,
} from './execution.ts';

// 11. Verification Engine
export {
  VerificationEngine,
  type VerificationDeps,
} from './verification.ts';

// 12. Result Normalizer
export {
  normalizeResult,
  type NormalizedResult,
} from './result.ts';

// 13. Memory (Expert Skills)
export {
  MemoryEngine,
  type MemoryDeps,
  type SkillDraft,
} from './memory.ts';

// 14. Observability
export {
  RunTracer,
  type TraceSpan,
} from './observability.ts';

// 15. Error Recovery
export {
  ErrorRecovery,
  classifyFailure,
  type RecoveryDecision,
} from './recovery.ts';

// Shared kernel types
export {
  type TaskProfile,
  type TaskLevel,
  type Intent,
  type PlanStep,
  type Plan,
  type AgentContext,
  type AgentRunState,
} from './types.ts';

// The orchestrating loop
export {
  AgentKernel,
  type KernelDeps,
  type KernelRequest,
  type KernelEvent,
} from './kernel.ts';

// Vercel AI SDK layer (task 2 — AD-1: the ONLY `ai`-importing package)
export {
  KERNEL_TOOLS,
  type KernelToolId,
  type ToolSet,
  planDay,
  schedule,
  startFocus,
  blockApps,
  research,
  qcmGenerate,
  mirrorAnalyze,
  scientificVerify,
} from './tools.ts';

export {
  streamKernelRun,
  ALL_TOOL_IDS,
  KERNEL_MAX_STEPS,
  messagesFor,
  type ModelAdapter,
  type StreamKernelRunOptions,
} from './sdk.ts';

export {
  ProviderModelAdapter,
  envKeyProvider,
  type KeyProvider,
} from './adapters.ts';

export {
  ModelGateway,
  defaultRegistry,
  kernelMaxSteps,
  type ModelGatewayDeps,
} from './gateway.ts';
