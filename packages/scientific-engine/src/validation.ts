/**
 * Five-stage problem validation (engineering-intelligence S3).
 *
 * Stage 1  Extraction  — did the agent parse the numbers right?
 * Stage 2  Physical    — are units dimensionally compatible, values plausible?
 * Stage 3  Structural  — domain invariants (beam supports, pipe sources…)
 * Stage 4  Method      — is the chosen method applicable to this problem type?
 * Stage 5  Solver      — does the solver accept this problem with these inputs?
 *
 * ANY stage failure => the problem is NOT solved.
 * The validator returns the first failed stage; the reporting message
 * is a "I won't run the calc until this is confirmed" string — no silent
 * fallback assumptions (S20 "je ne lance pas le calcul" rule).
 */
import type {
  MethodDefinition,
  ProblemIR,
  ProblemStatus,
  SolverDefinition,
} from '@aurora/domain';
import { UNIT_SYSTEM } from './units.ts';

export interface ValidationStageResult {
  stage: 1 | 2 | 3 | 4 | 5;
  name: string;
  pass: boolean;
  detail: string;
}

export interface ProblemValidation {
  ir: ProblemIR;
  passed: boolean;
  failedStage?: ValidationStageResult;
  stages: ValidationStageResult[];
  /** The status the IR should carry when a stage fails (S20). */
  suggestedStatus?: ProblemStatus;
  /** A reportable message for the agent ("I won't solve this yet"). */
  report: string;
}

/**
 * Run all 5 stages over a ProblemIR for a chosen method + solver.
 *
 * The IR is MUTATED: on failure its `status` and `confidence` reflect
 * the outcome (S20: INSUFFICIENT_DATA, unsupported, …).
 */
export function validateProblem(
  ir: ProblemIR,
  method: MethodDefinition,
  solver: SolverDefinition,
): ProblemValidation {
  const stages: ValidationStageResult[] = [];

  // ---- Stage 1 — Extraction (confidence + required inputs present) ----
  const missing = method.requiredInputs.filter(
    (req) =>
      req.required &&
      !ir.inputs.some((inp) => inp.key === req.key),
  );
  const extractionOk =
    ir.confidence.extraction >= 0.7 && ir.confidence.inputsComplete && missing.length === 0;
  stages.push({
    stage: 1,
    name: 'extraction',
    pass: extractionOk,
    detail: extractionOk
      ? `confidence ${ir.confidence.extraction.toFixed(2)}, ${ir.inputs.length} inputs`
      : missing.length > 0
        ? `missing required inputs: ${missing.map((m) => m.key).join(', ')}`
        : `insufficient extraction confidence (${ir.confidence.extraction.toFixed(2)})`,
  });

  // ---- Stage 2 — Physical (dimensional + plausibility checks) ----
  const physicalIssues: string[] = [];
  for (const inp of ir.inputs) {
    const qn = inp.quantity;
    if (qn?.unit) {
      // Known-unit check (unknown symbol = extraction smell).
      if (UNIT_SYSTEM[qn.unit.symbol] === undefined && qn.unit.siBase === undefined) {
        physicalIssues.push(`${inp.key}: unknown unit '${qn.unit.symbol}'`);
      }
      // Plausibility: a positive physical quantity must be > 0.
      const dim = qn.unit.dimension;
      const isLengthLike = dim !== undefined && (dim.base.L ?? 0) >= 1 && Object.keys(dim.base).length === 1;
      if (isLengthLike && qn.value <= 0) {
        physicalIssues.push(`${inp.key}: non-positive length (${qn.value} ${qn.unit.symbol})`);
      }
      // Load position within [0, L] (beam domain).
      if (inp.key === 'load_pos' || inp.key === 'load_position') {
        const L = ir.inputs.find((i) => i.key === 'length')?.quantity?.value;
        if (L !== undefined && (qn.value < 0 || qn.value > L)) {
          physicalIssues.push(`${inp.key}=${qn.value} outside [0, L=${L}]`);
        }
      }
    }
  }
  const physicalPass = physicalIssues.length === 0;
  stages.push({
    stage: 2,
    name: 'physical',
    pass: physicalPass,
    detail: physicalPass ? 'units compatible, values plausible' : physicalIssues.join('; '),
  });

  // ---- Stage 3 — Structural (domain invariants) ----
  const structuralPass = checkDomainInvariants(ir);
  stages.push({
    stage: 3,
    name: 'structural',
    pass: structuralPass,
    detail: structuralPass
      ? 'domain invariants satisfied'
      : 'structural/domain invariant failed (supports / topology)',
  });

  // ---- Stage 4 — Method (applicability to the problem type) ----
  const methodPass = method.applicableProblemTypes.includes(ir.problemType);
  stages.push({
    stage: 4,
    name: 'method',
    pass: methodPass,
    detail: methodPass
      ? `method ${method.id} applies to ${ir.problemType}`
      : `method ${method.id} does not apply to ${ir.problemType}`,
  });

  // ---- Stage 5 — Solver (domain of validity + input acceptance) ----
  const solverPass = solver.supportedProblemTypes.includes(ir.problemType);
  stages.push({
    stage: 5,
    name: 'solver',
    pass: solverPass,
    detail: solverPass
      ? `solver ${solver.id} accepts ${ir.problemType}`
      : `solver ${solver.id} does not accept ${ir.problemType}`,
  });

  const passed = stages.every((s) => s.pass);
  const failedStage = stages.find((s) => !s.pass);

  // S20: mutate the IR on failure (no silent fallback, no guess).
  let suggestedStatus: ProblemStatus | undefined;
  if (!passed) {
    if (failedStage?.stage === 1) {
      suggestedStatus = 'insufficient_data';
      ir.status = 'insufficient_data';
      ir.confidence.inputsComplete = false;
    } else if (failedStage?.stage === 2) {
      suggestedStatus = 'ambiguous';
      ir.status = 'ambiguous';
    } else if (failedStage?.stage === 3) {
      suggestedStatus = 'insufficient_data';
      ir.status = 'insufficient_data';
    } else {
      suggestedStatus = 'unsupported';
      ir.status = 'unsupported';
    }
    ir.confidence.methodSelected = false;
  } else {
    suggestedStatus = 'ready_to_solve';
    ir.status = 'ready_to_solve';
    ir.confidence.methodSelected = true;
  }

  const report = passed
    ? `All 5 validation stages passed (${method.id} -> ${solver.id})`
    : `Validation failed at Stage ${failedStage?.stage} (${failedStage?.name}): ${failedStage?.detail}. Je ne lance pas le calcul tant que ce point n'est pas confirmé.`;

  return { ir, passed, failedStage, stages, suggestedStatus, report };
}

/**
 * Domain-specific invariants (Stage 3).
 * RDM beam: at least 2 supports declared (pin/roller).
 */
function checkDomainInvariants(ir: ProblemIR): boolean {
  if (ir.domain !== 'rdm' && ir.domain !== 'civil_engineering') return true;
  const supports = ir.inputs.find((i) => i.key === 'supports')?.value as
    | Array<{ type: string; pos: number }>
    | string[]
    | undefined;
  if (!supports || supports.length < 2) return false;
  return true;
}
