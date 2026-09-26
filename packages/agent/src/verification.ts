/**
 * Component 11 — Verification Engine (kernel.md S12).
 *
 * Verifies results for critical tasks: KB / source check and/or the
 * `ScientificEngine` deterministic validation, as a persisted server
 * job (AD-8, 01 S5.6). A second "judge" model only when the
 * verification value justifies the quota spend (ADR v1.7 S14).
 *
 * Verification failures mark `expectedQuality: 'degraded'` — never
 * silently accepted (kernel S8).
 */
import type { Plan } from './types.ts';
import type { AIResponseEnvelope } from '@aurora/domain';

export interface VerificationDeps {
  /** deterministic check (ScientificEngine) via a persisted job */
  verifyJob(stepId: string, input: Record<string, unknown>): Promise<{ ok: boolean; details?: unknown }>;
  /** KB / source check (provenance, AD-11) */
  checkSources(stepId: string): Promise<{ ok: boolean; refs?: string[] }>;
  /** the optional second "judge" model (ADR S14 — only when justified) */
  judge?(stepId: string, input: Record<string, unknown>): Promise<{ ok: boolean; reason: string }>;
}

export interface VerificationResult {
  stepId: string;
  ok: boolean;
  /** `full` | `degraded` — degraded on any verification failure (AD-5) */
  expectedQuality: 'full' | 'degraded';
  checks: Array<{ name: string; ok: boolean }>;
}

/**
 * Run verification over a plan's completed steps. Only steps that
 * required verification (engineering = always) are checked.
 */
export class VerificationEngine {
  private deps: VerificationDeps;

  constructor(deps: VerificationDeps) {
    this.deps = deps;
  }

  async verify(
    plan: Plan,
    envelope: AIResponseEnvelope<unknown>,
  ): Promise<{ results: VerificationResult[]; degraded: boolean }> {
    const need = plan.steps.filter((s) => s.risk !== 'read' || s.stepId.includes('verify') || s.stepId.includes('qcm') || s.stepId.includes('mirror'));
    const results: VerificationResult[] = [];
    let degraded = false;
    for (const step of need) {
      const checks: Array<{ name: string; ok: boolean }> = [];
      let ok = true;
      if (step.jobKind === 'scientific' || step.stepId.includes('verify')) {
        const v = await this.deps.verifyJob(step.stepId, step.input);
        checks.push({ name: 'deterministic', ok: v.ok });
        ok = ok && v.ok;
      }
      if (step.stepId.includes('research') || step.stepId.includes('mirror')) {
        const s = await this.deps.checkSources(step.stepId);
        checks.push({ name: 'sources', ok: s.ok });
        ok = ok && s.ok;
      }
      if (!ok && this.deps.judge) {
        const j = await this.deps.judge(step.stepId, step.input);
        checks.push({ name: 'judge', ok: j.ok });
        ok = ok && j.ok;
      }
      if (!ok) degraded = true;
      results.push({ stepId: step.stepId, ok, expectedQuality: ok ? 'full' : 'degraded', checks });
    }
    if (results.length === 0) {
      results.push({ stepId: plan.planId, ok: true, expectedQuality: envelope.expectedQuality, checks: [] });
      degraded = degraded || envelope.expectedQuality === 'degraded';
    }
    return { results, degraded };
  }
}
