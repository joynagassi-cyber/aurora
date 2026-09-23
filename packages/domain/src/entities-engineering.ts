/**
 * Engineering / Scientific Engine entities (AD-15 SSoT,
 * docs/scientific-engine/engineering-intelligence-layer.md S2/S4/S5).
 *
 * A single `ProblemIR` covers ALL domains; domain-specific fields live in
 * typed sub-objects. The kernel NEVER branches on domain. `Quantity` is a
 * global guardrail: a bare number without a unit is a type error, not a
 * warning.
 */

/** Domain ids (the universal IR is NOT engineering-only). */
export type DomainId =
  | 'math'
  | 'rdm'
  | 'concrete'
  | 'hydraulics'
  | 'geotech'
  | 'surveying'
  | 'gis'
  | 'remote_sensing'
  | 'statistics'
  | 'data_science'
  | 'civil_engineering'
  | 'other';

export type DisciplineId = string;

export type ProblemStatus =
  | 'draft'
  | 'validated'
  | 'insufficient_data'
  | 'ambiguous'
  | 'unsupported'
  | 'ready_to_solve'
  | 'solved'
  | 'verification_failed';

/**
 * A physical dimension (dimensional-analysis guardrail): the engine
 * rejects `20 kN + 5 m` as a dimensional mismatch, not a soft warning.
 */
export interface PhysicalDimension {
  /** e.g. "L", "M", "T" exponents, or a compound label like "M/T^2" */
  base: Record<string, number>;
  label?: string;
}

/** A unit in the engine's unit system (ISO + domain codes, e.g. Eurocode). */
export interface Unit {
  /** canonical symbol ("m", "kN", "MPa", "rad") */
  symbol: string;
  /** SI base it maps to */
  siBase?: string;
  /** conversion factor to the canonical base */
  factor?: number;
  dimension: PhysicalDimension;
}

/**
 * Quantity — a value ALWAYS paired with a unit (global guardrail).
 * NEVER `length: 6`; ALWAYS `{ value: 6, unit: 'm' }`.
 */
export interface Quantity {
  value: number;
  unit: Unit;
  /** optional dimension check */
  dimension?: PhysicalDimension;
}

/** An assumption applied to the problem (ADR S15: traces of calculation
 *  include assumptions). */
export interface Assumption {
  id: string;
  /** what is assumed (e.g. "linear_elastic", "small_deformation") */
  statement: string;
  /** source of the assumption (course / norm / general / inferred) */
  authority: 'course' | 'norm' | 'general' | 'inferred';
  sourceRef?: string;
}

/** A required input, with its type/units. */
export interface InputRequirement {
  key: string;
  quantity?: { unit: string; dimension?: PhysicalDimension };
  /** non-quantity inputs */
  kind?: 'number' | 'string' | 'boolean' | 'enum' | 'reference';
  required: boolean;
  description?: string;
}

export interface ProblemInput {
  key: string;
  quantity?: Quantity;
  value?: unknown;
}

export interface ProblemUnknown {
  key: string;
  description?: string;
}

export interface ProblemConstraint {
  key: string;
  /** constraint expression (equality / inequality / range) */
  expression: string;
}

export interface RequestedOutput {
  key: string;
  description?: string;
}

/**
 * ProblemIR — the universal problem representation (engineering-intelligence
 * layer S2). SSoT AD-15: `packages/engineering-core/problem-ir.ts` mirrors
 * these types; the canonical shape lives here.
 */
export interface ProblemIR {
  id: string;
  domain: DomainId;
  discipline: DisciplineId;
  /** e.g. 'simply_supported_beam_point_load', 'regression_ols' */
  problemType: string;
  /** verbatim user text (for provenance) */
  statement: string;
  inputs: ProblemInput[];
  unknowns: ProblemUnknown[];
  constraints: ProblemConstraint[];
  assumptions: Assumption[];
  requestedOutputs: RequestedOutput[];
  /** course, norm, method constraint */
  context?: Record<string, unknown>;
  /** AD-11 provenance — SourceRef ids (knowledge SourceRef shape) */
  sources: string[];
  /** structured confidence (NOT a single "94%") */
  confidence: {
    extraction: number;
    inputsComplete: boolean;
    methodSelected: boolean;
  };
  status: ProblemStatus;
}

// ---- Six registries (S4) ----

export interface MethodDefinition {
  /** e.g. 'rdm.beam.statics', 'hydraulics.mannings' */
  id: string;
  domain: string;
  discipline: string;
  applicableProblemTypes: string[];
  description: string;
  requiredInputs: InputRequirement[];
  assumptions: Assumption[];
  /** description, NOT code */
  algorithm: { name: string; description: string };
  /** which solver executes this method */
  solverId: string;
  /** Verification Registry rule ids */
  validationRules: string[];
  /** which formulas / codes back this method */
  sourceRequirements: string[];
  /** 'eurocode2:6.2', 'bael:1993:5.5' */
  codeRef?: string;
}

export interface Limitation {
  id: string;
  description: string;
}

export interface SolverDefinition {
  /** e.g. 'solver.rdm.beam.symbolic', 'solver.math.linear-system' */
  id: string;
  name: string;
  version: string;
  supportedProblemTypes: string[];
  /** strict typed inputs/outputs (the doc uses Zod; kept abstract here) */
  inputSchema?: unknown;
  outputSchema?: unknown;
  executionMode: 'local' | 'worker' | 'server' | 'external-engine';
  deterministic: boolean;
  /** MANDATORY domain of validity — what the solver CAN handle */
  validityDomain: {
    dimensions: string[];
    supportTypes?: string[];
    loadTypes?: string[];
    assumptions: string[];
  };
  /** what it CANNOT do */
  limitations: Limitation[];
  /** SourceRef ids */
  references: string[];
  testSuite: string[];
}

export interface VerificationResult {
  ruleId: string;
  status: 'pass' | 'fail' | 'skipped';
  detail: string;
}

export interface VerificationRule {
  /** e.g. 'equilibrium.sum_forces', 'dimensional.consistency' */
  id: string;
  /** solver ids or problem types */
  appliesTo: string[];
  /** which fields of ProblemIR + SolverResult */
  inputs: string[];
  /** deterministic check — NOT a second LLM giving its opinion */
  kind: 'invariant' | 'analytical' | 'independent-computation' | 'domain-rule' | 'numerical-convergence';
}

export interface PatternSignature {
  /** NL phrase that matches this pattern */
  phrase: string;
  /** weight for pattern matching */
  weight?: number;
}

export interface ProblemPattern {
  /** e.g. 'RDM_BEAM_SIMPLY_SUPPORTED_POINT_LOAD' */
  id: string;
  domain: string;
  discipline: string;
  /** NL phrases that recognize this pattern (even with varied wording) */
  signatures: PatternSignature[];
  expectedInputs: InputRequirement[];
  /** Method Registry ids that apply */
  methods: string[];
  commonMistakes: string[];
  /** SourceRef ids */
  examples: string[];
}

export interface FormulaVariable {
  name: string;
  unit: string;
  description: string;
}

export interface FormulaDefinition {
  id: string;
  /** LaTeX */
  expression: string;
  variables: FormulaVariable[];
  units: { input: string[]; output: string };
  /** "valide pour ELS", "valide si x < L/4" */
  conditions: string[];
  /** which course / code / reference */
  sourceRef: string;
}

export interface CodeRegistryEntry {
  /** e.g. 'eurocode2', 'bael', 'recommandation_btp' */
  id: string;
  name: string;
  version: string;
  clauses: Array<{ id: string; scope: string; method: string; formulaRef: string }>;
}

// ---- Solver Result (S5) ----

export interface NormalizedInput {
  key: string;
  quantity: Quantity;
  /** original representation, if converted */
  original?: string;
}

export interface CalculationStep {
  id: string;
  /** the step (formula / operation) */
  label: string;
  /** LaTeX of the step */
  expression?: string;
  result?: unknown;
}

export interface SolverOutput {
  key: string;
  quantity?: Quantity;
  value?: unknown;
}

export interface SolverResult {
  solverId: string;
  solverVersion: string;
  status: 'verified' | 'unverified' | 'degraded' | 'failed';
  normalizedInputs: NormalizedInput[];
  assumptions: Assumption[];
  /** step-by-step (feeds explanation) */
  calculations: CalculationStep[];
  /** typed results */
  outputs: SolverOutput[];
  verification: VerificationResult[];
  /** AntV / KaTeX spec — the RENDERER draws, NOT the solver (AD-10) */
  visualization?: Array<{
    type: 'chart' | 'diagram' | 'formula' | 'table';
    spec: unknown;
  }>;
  /** AD-11 provenance */
  provenance: {
    method: string;
    /** SourceRef ids */
    formulas: string[];
    code?: string;
    course?: string;
  };
  confidence: {
    extraction: number;
    method: number;
    inputsComplete: boolean;
    solverStatus: string;
    verificationStatus: 'all_pass' | 'partial' | 'failed';
    sourceAuthority: 'course' | 'norm' | 'general' | 'inferred';
  };
}
