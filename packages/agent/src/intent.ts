/**
 * Component 1 — Intent Engine (kernel.md S12).
 *
 * Classifies the user goal into a typed intent + task profile.
 * ADR v1.7 S6: NEVER prompt keywords — the classification is driven by
 * the intent catalog (docs/agent/natural-language-intents.md) + measurable
 * context variables (expert-skills-extensions S5: energy_level,
 * interruption_count, overload_score, skill_freshness, gap_urgency —
 * data, not "mood detection").
 */
import type { Intent, TaskProfile } from './types.ts';

/** A raw request into the kernel (01 S5.1 fn-agent-run IN contract). */
export interface IntentRequest {
  userId: string;
  /** the user utterance (or typed intent id, e.g. "plan_day") */
  intent: string;
  /** structured refs (task ids, course ids, session ids) */
  contextRefs?: string[];
  /** an already-classified task profile (planner entry point skips re-class) */
  taskProfile?: TaskProfile;
  /** measurable context inputs (Personal/Productivity context forms) */
  signals?: {
    energyLevel?: 'low' | 'medium' | 'high';
    interruptionCount?: number;
    overloadScore?: number;
    skillFreshness?: 'fresh' | 'stale' | 'none';
    gapUrgency?: number;
    inExaminationPeriod?: boolean;
  };
  /** the user's explicit goal (optional) */
  goalId?: string;
}

/**
 * The composite intent decomposition (kernel.md S13 mandatory example):
 * "Organise ma journée, mets 2h de géotechnique, démarre Focus et
 *  bloque TikTok/WhatsApp" = plan_day + schedule + focus_start + block_apps.
 * These are the canonical intent ids; unknown intents degrade to the
 * default ROUTINE profile (graceful degradation, AD-1 last paragraph).
 */
const COMPOSITE_DECOMPOSITION: Record<string, string[]> = {
  organize_day: ['plan_day', 'schedule', 'focus_start', 'block_apps'],
};

/** Per-intent default tool count (drives taskProfile.tools). */
const INTENT_TOOL_COUNT: Record<string, number> = {
  plan_day: 2,
  schedule: 1,
  focus_start: 2,
  block_apps: 1,
  research: 2,
  qcm_generate: 1,
  mirror_analyze: 1,
  scientific_verify: 2,
  review: 1,
  default: 0,
};

function pickDefaultProfile(signals?: IntentRequest['signals']): TaskProfile {
  const complexity = signals?.inExaminationPeriod ? 'high' : 'medium';
  const latency =
    signals && (signals.energyLevel === 'low' || (signals.interruptionCount ?? 0) >= 3)
      ? 'critical'
      : 'normal';
  return {
    complexity,
    reasoning: 'basic',
    tools: 0,
    vision: false,
    contextSize: 4_096,
    latency,
    cost: signals?.overloadScore && signals.overloadScore > 0.8 ? 'constrained' : 'unconstrained',
    criticality: signals?.inExaminationPeriod ? 'critical' : 'routine',
    verification: false,
    dataSensitivity: 'public',
  };
}

/**
 * Classify an intent request into a typed Intent.
 * - Known intent id (catalog) → deterministic profile.
 * - Composite intent → decomposed parts + merged tool count.
 * - Unknown intent → default ROUTINE profile (never crash, AD-1
 *   last paragraph: optional capabilities degrade when absent).
 */
export function classifyIntent(req: IntentRequest): Intent {
  const known = INTENT_TOOL_COUNT[req.intent] !== undefined;
  const composite = COMPOSITE_DECOMPOSITION[req.intent];
  const parts = composite ?? (known ? [req.intent] : ['default']);
  const tools = Math.max(...parts.map((p) => INTENT_TOOL_COUNT[p] ?? 0));

  const profile = req.taskProfile ? { ...req.taskProfile, tools } : { ...pickDefaultProfile(req.signals), tools };

  // Engineering verification (expert-skills-extensions S5 routing table:
  // "verification: derived from problem_type (engineering = always)").
  if (req.intent === 'scientific_verify' || req.intent === 'qcm_generate') {
    profile.verification = true;
  }

  return {
    kind: req.intent,
    parts: composite ? parts : undefined,
    profile,
    ambiguity: 0, // a typed intent id is never ambiguous; NL disambiguation
                  // happens upstream (device layer) before reaching the kernel
  };
}

/** Expose the default-profile builder (tests + planner seeding). */
export function buildTaskProfile(signals?: IntentRequest['signals'], overrides?: Partial<TaskProfile>): TaskProfile {
  return { ...pickDefaultProfile(signals), ...overrides };
}

/** Resolve the routing level of a profile (ADR v1.7 S7). */
export function levelFor(profile: TaskProfile): import('./types.ts').TaskLevel {
  if (profile.verification && profile.criticality === 'critical') return 'CRITICAL';
  if (profile.vision) return 'VISION';
  if (profile.tools > 0 || profile.reasoning === 'deep') return 'AGENT';
  return 'ROUTINE';
}

/** Re-exported intent type for consumers. */
export type { Intent };
