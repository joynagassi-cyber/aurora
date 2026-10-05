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

// Builtin skill templates (Task 2, 2026-10-04) — the 15 seeded catalog
// entries, mirrored in TS for tests / type-checking (the SQL seed is the
// runtime SSoT, the TS file is NOT embedded in the prompt).
export {
  AGENT_SKILL_TEMPLATES,
  BUILTIN_TOOL_IDS,
} from './skill-templates.ts';

export {
  streamKernelRun,
  ALL_TOOL_IDS,
  KERNEL_MAX_STEPS,
  messagesFor,
  type ModelAdapter,
  type StreamKernelRunOptions,
} from './sdk.ts';

// Agent job handler (AD-8: provided to ORION's fn-job-dispatcher global
// switch via the chevauchement rule — the dispatcher imports + registers,
// the agent module owns the handler body).
export {
  buildAgentRunHandler,
  type AgentHandlerDeps,
  type AgentJobHandler,
} from './jobs.ts';

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

// Expert Skills — the 4 self-improvement extensions (ADR S14, task 4)
export {
  contrastiveConfidence,
  divergentConclusion,
  confidenceAt,
  decayVerdict,
  generateHypothesis,
  resolveHypothesis,
  firewallVerdict,
  userOverride,
  skillLifecycle,
  DECAY_LAMBDA,
  REEVALUATION_THRESHOLD,
  AUTO_ARCHIVE_THRESHOLD,
  FIREWALL_MIN_CYCLES,
  ESTABLISHED_THRESHOLD,
  REVALIDATE_CONFIDENCE,
  type ContrastivePair,
  type SkillType,
  type DecayInput,
  type DecayVerdict,
  type SkillHypothesis,
  type HypothesisInput,
  type HypothesisEvidence,
  type AnomalyCycle,
  type FirewallInput,
  type FirewallVerdict,
  type SkillLifecycleInput,
} from './expert-skills.ts';

// AgentRunState + command bus (kernel S15, task 5 — the device surface)
export {
  buildAgentUiEffect,
  uiCommand,
  confirmationSurfaceFor,
  AGENT_UI_COMMANDS,
  type AgentUiEffect,
  type AgentUiCommand,
  type CommandBus,
  type ConfirmationSurface,
  type AgentActionEnvelope,
  type NavigationIntent,
  type UiStateCommand,
} from './command-bus.ts';

// AgentRunState streaming surface (task 5, 02 S4 / AD-12-F-09 — the
// device-facing snapshot type the kernel / fn-agent-run produce, the UI
// projects).
export {
  type RunPhase,
  type AgentRunStateChunk,
  applyChunk,
  phaseFor,
  terminalChunk,
  heartbeatChunk,
} from './run-state.ts';

// Command bus (task 6, kernel S15) — the typed-command surface the agent
// drives the UI through (re-exports the SSoT types from packages/domain,
// AD-15: consume, never re-declare).
export {
  CommandBus as RunBus,
  type AppCommand,
  type CommandListener,
  buildActionEnvelope,
  confirmationCommand,
  navigationCommand,
  uiStateCommand,
} from './run-bus.ts';

// Model invocation layer (task 7, AD-1 boundary — the second `ai`-
// importing file besides tools.ts, confined to packages/agent).
export {
  invokeModel,
  agnesProviderChain,
  AGENT_SYSTEM_PROMPT,
  type HealthMutator,
  type InvokeModelDeps,
  type ModelCall,
  type ModelResult,
} from './model.ts';

// Provider adapters + runtime pipeline (task 7, AD-3: keys from env only).
export {
  isConfigured,
  buildModel,
  AgnesRouterRegistry,
  ProviderHealth,
  BudgetGate,
  DataPolicyGate,
  makeAgnesRouter,
  type ProviderSettings,
} from './providers.ts';
