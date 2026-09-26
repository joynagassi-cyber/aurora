/**
 * Component 3 — Planner (kernel.md S12).
 *
 * Builds a capability plan (steps + tool sequence + confirmation points).
 * Dynamic replan on change (ADR S13 Coach): the plan is DATA, re-runnable,
 * "recalcul du planning restant sans détruire l'historique" — executed
 * steps keep their results; only pending steps are recomputed.
 *
 * The Planner never improvises unregistered actions (kernel S13):
 * every step maps to a capability declared in the Capability Registry
 * (feature-agentability-matrix.md).
 */
import type { AgentContext, Plan, PlanStep } from './types.ts';
import type { PermissionContext } from './permission.ts';

export interface PlannerDeps {
  /** the tool registry (component 4-6) — resolves tool → capability entry */
  registry: { byTool(tool: string): import('./capability.ts').CapabilityEntry | undefined };
  /** permission gate (component 7) */
  permission: (step: PlanStep, ctx: AgentContext, perm: PermissionContext) => 'allowed' | 'confirm' | 'blocked';
  /** clock (injectable for tests) */
  now(): string;
  /** stable id generator */
  ulid(): string;
}

/**
 * The intent → step templates. This is the typed planning surface
 * (kernel S13 mandatory example): `organize_day` composes the 4
 * canonical intents. The kernel never invents a step for an
 * unregistered capability (mission S13: "l'agent n'improvise jamais
 * une action non enregistrée").
 */
function stepTemplatesFor(intent: string, ctx: AgentContext): Array<{ tool: string; input: Record<string, unknown>; jobKind?: string }> {
  const refs = ctx.intent.parts ?? [intent];
  const out: Array<{ tool: string; input: Record<string, unknown>; jobKind?: string }> = [];
  for (const part of refs) {
    switch (part) {
      case 'plan_day':
        out.push({
          tool: 'planDay',
          input: { context: ctx.productivity, examPeriod: Boolean(ctx.productivity.examPeriod) },
        });
        break;
      case 'schedule':
        out.push({ tool: 'schedule', input: { context: ctx.productivity } });
        break;
      case 'focus_start':
        out.push({ tool: 'startFocus', input: { context: ctx.productivity } });
        break;
      case 'block_apps':
        out.push({ tool: 'blockApps', input: { context: ctx.productivity } });
        break;
      case 'research':
        out.push({ tool: 'research', input: { topic: part }, jobKind: 'research' });
        break;
      case 'qcm_generate':
        out.push({ tool: 'qcm_generate', input: { context: ctx.learning }, jobKind: 'artifact_gen' });
        break;
      case 'mirror_analyze':
        out.push({ tool: 'mirror_analyze', input: { context: ctx.semantic }, jobKind: 'agent_run' });
        break;
      case 'scientific_verify':
        out.push({ tool: 'scientific_verify', input: { context: ctx.learning }, jobKind: 'scientific' });
        break;
      default:
        break;
    }
  }
  // Composite intents: the full plan
  if (intent === 'organize_day') {
    out.push({ tool: 'planDay', input: { context: ctx.productivity }, jobKind: undefined });
    out.push({ tool: 'schedule', input: { context: ctx.productivity } });
    out.push({ tool: 'startFocus', input: { context: ctx.productivity } });
    out.push({ tool: 'blockApps', input: { context: ctx.productivity } });
  }
  return out;
}

/**
 * Build the plan for a context. Steps are pre-validated through the
 * permission engine BEFORE execution (destructive ⇒ confirmation
 * point, ADR S5).
 */
export function buildPlan(
  ctx: AgentContext,
  perm: PermissionContext,
  deps: PlannerDeps,
): Plan {
  const templates = stepTemplatesFor(ctx.intent.kind, ctx);
  const steps: PlanStep[] = templates.map((t, i) => {
    const tool = deps.registry.byTool(t.tool);
    const risk = tool?.destructive ? 'destructive' : tool?.writeScopes.length ? 'write' : 'read';
    const step: PlanStep = {
      stepId: `${deps.ulid()}-${i}`,
      tool: t.tool,
      input: t.input,
      risk,
      confirmationRequired: risk === 'destructive' || risk === 'write',
      status: 'pending',
      ...(t.jobKind ? { jobKind: t.jobKind } : {}),
      ...(tool ? { compensation: tool.compensation } : {}),
    };
    const verdict = deps.permission(step, ctx, perm);
    if (verdict === 'blocked') {
      step.status = 'skipped';
    }
    return step;
  });

  const confirmationPoints = steps.filter((s) => s.confirmationRequired && s.status === 'pending').map((s) => s.stepId);

  return {
    planId: deps.ulid(),
    intentKind: ctx.intent.kind,
    steps,
    confirmationPoints,
  };
}

/**
 * Re-plan the REMAINING steps without destroying executed history
 * (ADR S13: "recalcul du planning restant sans détruire l'historique").
 * Done steps keep their `result`; pending steps are recomputed against
 * the new context.
 */
export function replanRemaining(
  current: Plan,
  ctx: AgentContext,
  perm: PermissionContext,
  deps: PlannerDeps,
): Plan {
  const fresh = buildPlan(ctx, perm, deps);
  return {
    ...fresh,
    planId: current.planId, // same plan identity — this is a re-plan, not a new plan
    steps: fresh.steps.map((s, i) => {
      const prev = current.steps[i];
      if (prev && (prev.status === 'done' || prev.status === 'failed')) {
        return { ...s, status: prev.status, result: prev.result, stepId: prev.stepId };
      }
      return s;
    }),
  };
}
