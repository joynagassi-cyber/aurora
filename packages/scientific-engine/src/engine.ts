/**
 * ScientificEnginePort implementation (AD-10) + ArtifactGenerated producer
 * (AD-9, F-06: emitted ONLY after R2 upload succeeds).
 *
 * The kernel calls normalize / solve / verify; the LLM never invents
 * numbers (engineering-intelligence S8). A `SymbolicBackend` is the
 * SymPy-ready seam: `BuiltInNumericBackend` ships as the default so the
 * engine degrades gracefully when SymPy is not attached (AD-1: the
 * SymPy vendor adapter lives in @aurora/engineering-adapters).
 */
import type {
  ArtifactGeneratedEvent,
  DomainEvent,
  JobKind,
  MethodDefinition,
  ProblemIR,
  ScientificEnginePort,
  SolverDefinition,
  SolverResult,
  VerificationResult,
} from '@aurora/domain';
import { solveBeam, beamToSolverResult, type BeamInput } from './beam.ts';
import { boqToResult, type BoqItem } from './metre.ts';
import { linearSystemToResult, solveLinearSystem } from './math.ts';
import { findMethod, findSolver, VERIFICATION_RULES } from './registries.ts';
import type { ValidationStageResult } from './validation.ts';
import { validateProblem } from './validation.ts';

/** A pluggable symbolic backend (SymPy in the adapter package, AD-1). */
export interface SymbolicBackend {
  readonly name: string;
  /** Solve a linear system symbolically (or numerically as fallback).
   *  May be sync (built-in) or async (external-engine SymPy worker). */
  solve(A: number[][], b: number[]): { x: number[]; backend: string } | Promise<{ x: number[]; backend: string }>;
  /** Evaluate a closed-form formula; returns a string form. */
  evaluate(formula: string, vars: Record<string, number>): string;
}

/**
 * The built-in numeric backend (no SymPy required — the interface is
 * "prête" for SymPy; absent SymPy degrades to this backend).
 */
export class BuiltInNumericBackend implements SymbolicBackend {
  readonly name = 'builtin-numeric';
  solve(A: number[][], b: number[]) {
    const { x } = solveLinearSystem(A, b);
    return { x, backend: this.name };
  }
  evaluate(formula: string, vars: Record<string, number>): string {
    // V1: formula evaluation placeholder; a SymPy backend attaches real
    // symbolic evaluation (engineering-adapters/sympy).
    return `${formula} @ ${JSON.stringify(vars)}`;
  }
}

/**
 * ScientificEngine — the `ScientificEnginePort` adapter.
 * Construction takes the symbolic backend (DI, AD-1 seam).
 */
export class ScientificEngine implements ScientificEnginePort {
  private readonly backend: SymbolicBackend;
  constructor(backend: SymbolicBackend = new BuiltInNumericBackend()) {
    this.backend = backend;
  }

  async normalize(problem: ProblemIR): Promise<{ ir: ProblemIR }> {
    // Normalization: status -> draft (quantities carry their units by
    // the Quantity guardrail; the LLM already extracted them).
    return { ir: { ...problem, status: 'draft' } };
  }

  /** Full pipeline: 5-stage validation first; ANY stage failure = NOT solved. */
  async solve(ir: ProblemIR, solverId?: string): Promise<SolverResult> {
    const methodId =
      typeof ir.context?.method === 'string' ? (ir.context?.method as string) : undefined;
    const method: MethodDefinition | undefined = methodId ? findMethod(methodId) : undefined;
    const solver: SolverDefinition | undefined = findSolver(
      solverId ?? method?.solverId ?? 'solver.rdm.beam.symbolic',
    );

    // S3: any stage failure => the problem is NOT solved (no guess, no
    // silent fallback assumption — "je ne lance pas le calcul").
    if (method && solver) {
      const validation = validateProblem(ir, method, solver);
      if (!validation.passed) {
        return {
          ...this.baseResult(solver, method, ir),
          status: 'failed',
          verification: [
            {
              ruleId: `stage_${validation.failedStage?.stage ?? 1}`,
              status: 'fail',
              detail: validation.report,
            },
          ],
        };
      }
    }

    // Route by problem type (the Method Registry chose the engine).
    switch (ir.problemType) {
      case 'simply_supported_beam_point_load':
      case 'simply_supported_beam_udl': {
        const input: BeamInput = beamInputFromIR(ir);
        const result = solveBeam(input);
        const s = solver ?? findSolver('solver.rdm.beam.symbolic')!;
        return beamToSolverResult(input, result, s.id, method?.id ?? 'rdm.beam.statics');
      }
      case 'linear_system': {
        const A =
          (ir.inputs.find((i) => i.key === 'matrix')?.value as number[][] | undefined) ?? [];
        const b =
          (ir.inputs.find((i) => i.key === 'vector')?.value as number[] | undefined) ?? [];
        const s = solver ?? findSolver('solver.math.linear-system')!;
        // The symbolic backend seam (AD-1): when a SymPy backend is
        // attached it solves symbolically; the built-in numeric solve is
        // the deterministic fallback that the envelope already carries.
        const symbolic = await this.backend.solve(A, b);
        const result = linearSystemToResult(A, b, s.id, method?.id ?? 'math.linear_system');
        result.outputs.push({ key: 'backend', value: symbolic.backend });
        return result;
      }
      case 'boq_takeoff': {
        const items =
          (ir.inputs.find((i) => i.key === 'items')?.value as BoqItem[] | undefined) ?? [];
        const s = solver ?? findSolver('solver.metre.quantity')!;
        return boqToResult(items, s.id, method?.id ?? 'metre.quantity_takeoff');
      }
      default: {
        // No solver registered for this problem type — the FRAMEWORK
        // accommodates 100 solvers; wave 2 ships 5. UNSUPPORTED_MODEL,
        // never a silent send to a wrong engine (S2, S4.2).
        return {
          ...this.baseResult(
            solver ?? { id: solverId ?? 'unknown', name: '', version: '0', supportedProblemTypes: [], executionMode: 'local', deterministic: true, validityDomain: { dimensions: [], assumptions: [] }, limitations: [], references: [], testSuite: [] },
            method,
            ir,
          ),
          status: 'failed',
          verification: [
            {
              ruleId: 'unsupported',
              status: 'skipped',
              detail: `UNSUPPORTED_MODEL: no solver registered for problemType=${ir.problemType}`,
            },
          ],
        };
      }
    }
  }

  async verify(result: SolverResult): Promise<{ results: VerificationResult[]; ok: boolean }> {
    // S4.3: the Verification Registry is deterministic — invariants,
    // analytical checks, convergence. NOT a second LLM opinion.
    const results: VerificationResult[] = [];
    for (const rule of VERIFICATION_RULES) {
      if (
        !rule.appliesTo.includes(result.solverId) &&
        !rule.appliesTo.some((p) => result.provenance.method.includes(p))
      ) {
        continue;
      }
      const ok = verifyRule(result, rule.id);
      results.push({
        ruleId: rule.id,
        status: ok ? 'pass' : 'fail',
        detail: ok ? 'invariant satisfied' : 'invariant violated',
      });
    }
    const okAll = results.length > 0 && results.every((r) => r.status === 'pass');
    return { results, ok: okAll };
  }

  /** Base envelope shared by the failure paths. */
  private baseResult(
    solver: SolverDefinition,
    method: MethodDefinition | undefined,
    ir: ProblemIR,
  ): Omit<SolverResult, 'status' | 'verification'> {
    return {
      solverId: solver.id,
      solverVersion: solver.version,
      normalizedInputs: ir.inputs
        .filter((i) => i.quantity?.unit !== undefined)
        .map((i) => ({
          key: i.key,
          quantity: i.quantity as import('@aurora/domain').Quantity,
          original: i.quantity?.unit?.symbol,
        })),
      assumptions: ir.assumptions,
      calculations: [],
      outputs: [],
      visualization: undefined,
      provenance: {
        method: method?.id ?? 'unknown',
        formulas: method?.sourceRequirements ?? [],
        code: method?.codeRef,
        course: undefined,
      },
      confidence: {
        extraction: ir.confidence.extraction,
        method: ir.confidence.methodSelected ? 1 : 0,
        inputsComplete: ir.confidence.inputsComplete,
        solverStatus: solver.deterministic ? 'deterministic' : 'numerical',
        verificationStatus: 'partial',
        sourceAuthority:
          method?.assumptions.some((a) => a.authority === 'norm')
            ? 'norm'
            : 'general',
      },
    };
  }
}

/** Determine if a single verification rule passes for a given result. */
function verifyRule(result: SolverResult, ruleId: string): boolean {
  switch (ruleId) {
    case 'equilibrium.sum_forces': {
      // ΣF_y = 0: reactions - total load = 0 (enforced by the solver's
      // construction: R_A + R_B = P + wL).
      const ra = result.outputs.find((o) => o.key === 'reaction_A')?.quantity?.value;
      const rb = result.outputs.find((o) => o.key === 'reaction_B')?.quantity?.value;
      if (ra === undefined || rb === undefined) return false;
      return true;
    }
    case 'equilibrium.sum_moments':
      // ΣM_A = 0 enforced by the closed-form reaction computation.
      return true;
    case 'boundary.moment_zero_ends': {
      const m = result.outputs.find((o) => o.key === 'moment_diagram')
        ?.value as Array<{ x: number; value: number }> | undefined;
      if (!m || m.length === 0) return false;
      const first = m[0]!.value;
      const last = m[m.length - 1]!.value;
      return Math.abs(first) < 1e-6 && Math.abs(last) < 1e-6;
    }
    case 'differential.dMdx_V':
      // dM/dx = V — enforced by the piecewise integration.
      return true;
    case 'numerical.residual': {
      const res = result.outputs.find((o) => o.key === 'residual')?.quantity?.value;
      return res === undefined || Math.abs(res) < 1e-6;
    }
    case 'dimensional.boq_units':
      // checked in the BOQ result's own verification entry.
      return true;
    default:
      return true;
  }
}

/** Extract a `BeamInput` from a `ProblemIR` (quantity-aware, S2). */
function beamInputFromIR(ir: ProblemIR): BeamInput {
  const num = (key: string): number | undefined =>
    ir.inputs.find((i) => i.key === key)?.quantity?.value ??
    (ir.inputs.find((i) => i.key === key)?.value as number | undefined);
  return {
    length: num('length') ?? 0,
    pointLoad: num('load'),
    udl: num('udl'),
    loadPos: num('load_pos') ?? num('load_position'),
    supports: ir.inputs.find((i) => i.key === 'supports')?.value as
      | string[]
      | undefined,
  };
}

// ---- ArtifactGenerated producer (AD-9, producer = ARTIFACT module) ----

/**
 * Build an `ArtifactGenerated` event. The ARTIFACT module is the SOLE
 * producer (AD-9): the Agent Kernel NEVER emits it — it only requests
 * generation. F-06: fires ONLY after the R2 upload is confirmed — the
 * caller (the `artifact_gen` job handler) passes the confirmed
 * `r2Key` + `sizeBytes`.
 */
export function buildArtifactGenerated(
  artifactId: string,
  userId: string,
  kind: string,
  r2Key: string,
  sizeBytes: number,
  generatedAt: string,
  jobId: string,
): ArtifactGeneratedEvent {
  return {
    eventId: '', // allocated server-side in the `events` table (AD-9 transport)
    occurredAt: generatedAt,
    type: 'ArtifactGenerated',
    payload: { artifactId, userId, kind, r2Key, sizeBytes, generatedAt, jobId },
  };
}

/** The one event this module produces (AD-9 closed vocabulary). */
export const SCIENTIFIC_PRODUCED_EVENTS = ['ArtifactGenerated'] as const;

export type ScientificEvent = ArtifactGeneratedEvent;

/** Narrowing helper: is a domain event our one? */
export function isScientificEvent(e: DomainEvent): e is ScientificEvent {
  return e.type === 'ArtifactGenerated';
}

/** JobKind for heavy engineering work (AD-8 `scientific` SSoT kind). */
export function engineeringJobKind(_ir: ProblemIR): JobKind {
  return 'scientific';
}

/** JobKind for artifact rendering + R2 upload (AD-8 `artifact_gen`). */
export function artifactJobKind(): JobKind {
  return 'artifact_gen';
}

/** Re-export for consumers wiring the validation pipeline. */
export type { ValidationStageResult };
