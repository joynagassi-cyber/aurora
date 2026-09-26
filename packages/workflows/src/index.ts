/**
 * @aurora/workflows — 23 composite workflows W1..W23 (deterministic,
 * validated against the closed AD-9 event vocabulary + AD-15 JobKind
 * + AD-7 single-writer rule), the 20 E2E agent scenarios (OQ-08,
 * Playwright-on-device), the 10 error-recovery classes (S64), and the
 * Expert Skill self-improvement loop (ADR S14 + extensions).
 *
 * Authority chain: AD-2 / AD-7 / AD-8 / AD-9 / AD-12 / AD-13 / AD-15 +
 * 01 S5 (jobs) + docs/workflows + docs/agent.
 */
import { w1 } from './w1.ts';
import { w2 } from './w2.ts';
import { w3 } from './w3.ts';
import { w4 } from './w4.ts';
import { w5 } from './w5.ts';
import { w6 } from './w6.ts';
import { w7 } from './w7.ts';
import { w8 } from './w8.ts';
import { w9 } from './w9.ts';
import { w10 } from './w10.ts';
import { w11 } from './w11.ts';
import { w12 } from './w12.ts';
import { w13 } from './w13.ts';
import { w14 } from './w14.ts';
import { w15 } from './w15.ts';
import { w16 } from './w16.ts';
import { w17 } from './w17.ts';
import { w18 } from './w18.ts';
import { w19 } from './w19.ts';
import { w20 } from './w20.ts';
import { w21 } from './w21.ts';
import { w22 } from './w22.ts';
import { w23 } from './w23.ts';
import type { Workflow } from './types.ts';

/** The 23 composite workflows (W1..W23), docs/workflows/composite-workflows.md. */
export const WORKFLOWS: readonly Workflow[] = [
  w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12,
  w13, w14, w15, w16, w17, w18, w19, w20, w21, w22, w23,
];

/** One workflow by id (W1..W23). */
export function workflowById(id: string): Workflow | undefined {
  return WORKFLOWS.find((w) => w.id === id);
}

/** All AD-9 events emitted across the 23 workflows (producer check, AD-9). */
export function allEmittedEvents(): readonly string[] {
  const seen = new Set<string>();
  for (const w of WORKFLOWS) {
    for (const e of w.eventsEmitted) seen.add(e);
  }
  return [...seen];
}

// ---- AD-9 event wiring (event flow across workflows + scenarios) ----
export {
  EVENT_CONSUMERS, emittedBy, observedBy, flowVerdicts,
  selfImprovementEventChain, allEventsFlow,
} from './event-flow.ts';
export type { EventFlowVerdict } from './event-flow.ts';

// ---- Types ----
export type {
  Workflow, WorkflowModule, UiTransition, WorkflowValidation,
  ErrorClass, ErrorClassId, SelfImprovementStage,
} from './types.ts';

// ---- E2E agent scenarios (20, OQ-08 Playwright-on-device) ----
export { E2E_SCENARIOS, scenarioById } from './e2e-scenarios/scenarios.ts';
export type { E2EScenario, ConfirmationClass, OfflineClass } from './e2e-scenarios/types.ts';

// ---- 10 error-recovery classes (S64) ----
export {
  E1, E2, E3, E4, E5, E6, E7, E8, E9, E10,
  ERROR_CLASSES, ERROR_CLASS_IDS, errorClassById,
} from './error-recovery.ts';

// ---- Plan-level recovery (partial execution + rollback, S64) ----
export {
  classifyPlanError, replanPartial, errorClassErrorById,
} from './recovery-plan.ts';
export type { PlanStep, PlanFailure, RecoveryDecision } from './recovery-plan.ts';

// ---- Expert Skill self-improvement loop (ADR S14 + extensions) ----
export {
  confidenceAt, decayVerdict, DECAY_LAMBDA, REEVALUATION_THRESHOLD,
  AUTO_ARCHIVE_THRESHOLD,
  contrastiveConfidence, generateHypothesis, resolveHypothesis,
  firewallVerdict, userOverride, FIREWALL_MIN_CYCLES, ESTABLISHED_THRESHOLD,
  loopStage, SELF_IMPROVEMENT_STAGES, revalidate,
} from './self-improvement.ts';
export type {
  SkillType, ConfidenceDecayInput, DecayVerdict,
  ContrastivePairInput, HypothesisInput, TriageHypothesis,
  AnomalyCycle, FirewallInput, FirewallVerdict,
  LoopContext,
} from './self-improvement.ts';

// ---- Workflow validation (AD-2 / AD-7 / AD-9 / AD-15 invariants) ----
export {
  validateWorkflow, validateAll, allValid,
  emissionCountByEvent, EVENT_PRODUCER, TABLE_OWNER,
} from './validate.ts';
