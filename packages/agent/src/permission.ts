/**
 * Component 7 — Permission Engine (kernel.md S12, ADR S16).
 *
 * Every tool is classified read / write / destructive (Permission
 * Context form). Read = free; write = authorized scope;
 * destructive / irreversible = explicit confirmation (ADR S5).
 *
 * The Permission Context form is assembled per session from
 * `user_context` (Identity) + user settings. Kernel actions are
 * replayable via the job system (AD-8 idempotency).
 */
import type { PlanStep } from './types.ts';

/** The Permission Context form (ADR S16 form 9). */
export interface PermissionContext {
  userId: string;
  /** granted scopes ("productivity:read", "learning:write", …) */
  scopes: string[];
  /** FeatureRegistry state — a disabled feature's capabilities are gone
   *  from the discoverable surface (feature-registry §2 chain) */
  featureState: Record<string, boolean>;
  /** DPC availability for the focus.block path (android + DPC, OQ-17) */
  devicePolicyAvailable?: boolean;
  /** destructive gates (ADR S5 confirmation-required actions) */
  destructiveGates?: string[];
  /** read / write / destructive access verdict */
  allow(action: 'read' | 'write' | 'destructive', scope: string): boolean;
}

/**
 * Classify a plan step's risk from its capability. The Planner calls
 * this BEFORE the step is executed so the confirmation points are
 * known up-front (confirmations are part of the plan, not an
 * afterthought — kernel S12 Confirmation Engine).
 */
export function classifyAction(
  step: Pick<PlanStep, 'tool' | 'risk' | 'confirmationRequired'>,
): 'read' | 'write' | 'destructive' {
  return step.risk;
}

/**
 * Check whether a step is allowed / needs confirmation / is blocked,
 * given the permission context. The verdicts:
 *  - `allowed` — execute without confirmation
 *  - `confirm` — surface the confirmation engine before executing
 *  - `blocked` — the scope is not granted; the step is skipped
 */
export function isAllowed(
  step: Pick<PlanStep, 'tool' | 'risk' | 'confirmationRequired' | 'input'>,
  entry: { readScopes: string[]; writeScopes: string[]; destructive: boolean },
  perm: PermissionContext,
): 'allowed' | 'confirm' | 'blocked' {
  // Scope check: every write scope must be granted.
  const scopes = entry.writeScopes.length ? entry.writeScopes : entry.readScopes;
  for (const s of scopes) {
    const action = entry.destructive ? 'destructive' : entry.writeScopes.includes(s) ? 'write' : 'read';
    if (!perm.allow(action, s)) return 'blocked';
  }
  // Destructive / confirmation-required → confirmation engine.
  if (entry.destructive || step.confirmationRequired) return 'confirm';
  return 'allowed';
}
