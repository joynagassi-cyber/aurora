/**
 * Six registries — seed definitions (engineering-intelligence S4/S14).
 *
 * These are the DETERMINISTIC KNOWLEDGE backbone: Method Registry
 * (what + how), Solver Registry (which engine + domain of validity),
 * Verification Registry (invariants + analytical checks), Code Registry
 * (normative sources), Formula Registry (LaTeX + units), Pattern
 * Registry (NL recognition). The agent orchestrates these — it does
 * NOT invent any of them.
 */
import type {
  CodeRegistryEntry,
  FormulaDefinition,
  MethodDefinition,
  ProblemPattern,
  SolverDefinition,
  VerificationRule,
} from '@aurora/domain';

// ---- Method Registry (5 seeds) ----

export const METHODS: readonly MethodDefinition[] = [
  {
    id: 'rdm.beam.statics',
    domain: 'rdm',
    discipline: 'statics',
    applicableProblemTypes: ['simply_supported_beam_point_load', 'simply_supported_beam_udl'],
    description: 'Equilibrium of a simply supported beam (ΣF=0, ΣM=0).',
    requiredInputs: [
      { key: 'length', required: true, description: 'Span L' },
      { key: 'load', required: true, description: 'Point load P at midspan' },
      { key: 'supports', required: true, description: 'End support positions' },
    ],
    assumptions: [
      { id: 'linear_elastic', statement: 'linear_elastic', authority: 'general' },
      { id: 'small_deformation', statement: 'small_deformation', authority: 'general' },
    ],
    algorithm: {
      name: 'statics',
      description: 'ΣM_A=0 -> R_B, ΣF_y=0 -> R_A',
    },
    solverId: 'solver.rdm.beam.symbolic',
    validationRules: ['equilibrium.sum_forces', 'equilibrium.sum_moments', 'boundary.moment_zero_ends'],
    sourceRequirements: ['F.statics.beam', 'F.moment_max'],
    codeRef: undefined,
  },
  {
    id: 'rdm.beam.shear_moment',
    domain: 'rdm',
    discipline: 'shear_moment',
    applicableProblemTypes: ['simply_supported_beam_point_load', 'simply_supported_beam_udl'],
    description: 'Shear and bending moment diagrams for a simply supported beam.',
    requiredInputs: [
      { key: 'length', required: true },
      { key: 'load', required: true },
    ],
    assumptions: [
      { id: 'linear_elastic', statement: 'linear_elastic', authority: 'general' },
    ],
    algorithm: {
      name: 'shear_moment',
      description: 'Integrate V(x) -> M(x) from left support, piecewise.',
    },
    solverId: 'solver.rdm.beam.shear_moment',
    validationRules: ['equilibrium.sum_forces', 'differential.dMdx_V'],
    sourceRequirements: ['F.statics.beam', 'F.Mmax_udl'],
    codeRef: undefined,
  },
  {
    id: 'math.linear_system',
    domain: 'math',
    discipline: 'linear_algebra',
    applicableProblemTypes: ['linear_system'],
    description: 'Solve Ax = b via Gaussian elimination.',
    requiredInputs: [
      { key: 'matrix', required: true, description: 'Coefficient matrix A' },
      { key: 'vector', required: true, description: 'RHS vector b' },
    ],
    assumptions: [],
    algorithm: {
      name: 'gaussian_elimination',
      description: 'Partial pivoting, back-substitution.',
    },
    solverId: 'solver.math.linear-system',
    validationRules: ['numerical.residual'],
    sourceRequirements: ['F.la.gauss'],
    codeRef: undefined,
  },
  {
    id: 'metre.quantity_takeoff',
    domain: 'other',
    discipline: 'metre',
    applicableProblemTypes: ['boq_takeoff'],
    description: 'Quantity takeoff from a Bill of Quantities spec (L×W×H, aggregation).',
    requiredInputs: [
      { key: 'items', required: true, description: 'BOQ items' },
    ],
    assumptions: [
      { id: 'completeness', statement: 'BOQ covers all required structural categories', authority: 'inferred' },
    ],
    algorithm: {
      name: 'quantity_takeoff',
      description: 'Item quantity = L×W×H×coeff (or explicit count), sum per category.',
    },
    solverId: 'solver.metre.quantity',
    validationRules: ['dimensional.boq_units'],
    sourceRequirements: ['F.boq.takeoff'],
    codeRef: undefined,
  },
  {
    id: 'math.symbolic',
    domain: 'math',
    discipline: 'symbolic',
    applicableProblemTypes: ['symbolic_equation'],
    description: 'Solve an algebraic equation / system symbolically.',
    requiredInputs: [
      { key: 'equation', required: true, description: 'Equation(s)' },
    ],
    assumptions: [],
    algorithm: {
      name: 'symbolic_solve',
      description: 'SymPy engine (when available), else numeric root find.',
    },
    solverId: 'solver.math.symbolic',
    validationRules: ['numerical.residual'],
    sourceRequirements: ['F.sym.solve'],
    codeRef: undefined,
  },
];

// ---- Solver Registry (5 seeds) ----

export const SOLVERS: readonly SolverDefinition[] = [
  {
    id: 'solver.rdm.beam.symbolic',
    name: 'Beam (statics, symbolic)',
    version: '0.1',
    supportedProblemTypes: ['simply_supported_beam_point_load', 'simply_supported_beam_udl'],
    executionMode: 'local',
    deterministic: true,
    validityDomain: {
      dimensions: ['2D'],
      supportTypes: ['pin', 'roller'],
      loadTypes: ['point', 'udl', 'moment'],
      assumptions: ['linear_elastic', 'small_deformation'],
    },
    limitations: [
      { id: 'no_nonlinear', description: 'Does NOT handle non-linear / plastic / large deflection' },
      { id: 'no_indeterminate', description: 'Statically determinate only' },
    ],
    references: ['RDM_ch3'],
    testSuite: ['golden_tests.beam_statics'],
  },
  {
    id: 'solver.rdm.beam.shear_moment',
    name: 'Beam (shear + moment)',
    version: '0.1',
    supportedProblemTypes: ['simply_supported_beam_point_load', 'simply_supported_beam_udl'],
    executionMode: 'local',
    deterministic: true,
    validityDomain: {
      dimensions: ['2D'],
      assumptions: ['linear_elastic', 'small_deformation'],
    },
    limitations: [
      { id: 'no_nonlinear', description: 'Linear elastic only' },
    ],
    references: ['RDM_ch3'],
    testSuite: ['golden_tests.beam_diagrams'],
  },
  {
    id: 'solver.math.linear-system',
    name: 'Linear system solver',
    version: '0.1',
    supportedProblemTypes: ['linear_system'],
    executionMode: 'local',
    deterministic: true,
    validityDomain: { dimensions: ['N'], assumptions: ['square_matrix', 'non_singular'] },
    limitations: [
      { id: 'no_sparse', description: 'Dense systems only (V1)' },
    ],
    references: ['LinearAlgebra_ch1'],
    testSuite: ['golden_tests.linear_system'],
  },
  {
    id: 'solver.metre.quantity',
    name: 'Quantity takeoff engine',
    version: '0.1',
    supportedProblemTypes: ['boq_takeoff'],
    executionMode: 'local',
    deterministic: true,
    validityDomain: { dimensions: ['3D'], assumptions: ['orthogonal_dimensions'] },
    limitations: [
      { id: 'no_curved', description: 'Straight orthogonal volumes only (V1)' },
    ],
    references: ['BTP_metre_ch1'],
    testSuite: ['golden_tests.boq'],
  },
  {
    id: 'solver.math.symbolic',
    name: 'Symbolic solver (SymPy backend)',
    version: '0.1',
    supportedProblemTypes: ['symbolic_equation'],
    executionMode: 'worker',
    deterministic: true,
    validityDomain: { dimensions: ['N'], assumptions: ['closed_form'] },
    limitations: [
      { id: 'no_pde', description: 'ODE/PDE only when SymPy backend attached' },
    ],
    references: ['SymPy.beam_2d'],
    testSuite: ['golden_tests.symbolic'],
  },
];

// ---- Verification Registry (5 seeds) ----

export const VERIFICATION_RULES: readonly VerificationRule[] = [
  {
    id: 'equilibrium.sum_forces',
    appliesTo: ['rdm', 'simply_supported_beam_point_load', 'simply_supported_beam_udl'],
    inputs: ['reactions', 'load'],
    kind: 'invariant',
  },
  {
    id: 'equilibrium.sum_moments',
    appliesTo: ['rdm', 'simply_supported_beam_point_load'],
    inputs: ['reactions', 'load', 'positions'],
    kind: 'invariant',
  },
  {
    id: 'boundary.moment_zero_ends',
    appliesTo: ['simply_supported_beam_point_load', 'simply_supported_beam_udl'],
    inputs: ['moment_at_ends'],
    kind: 'invariant',
  },
  {
    id: 'differential.dMdx_V',
    appliesTo: ['rdm'],
    inputs: ['shear', 'moment'],
    kind: 'analytical',
  },
  {
    id: 'numerical.residual',
    appliesTo: ['linear_system', 'symbolic_equation'],
    inputs: ['residual'],
    kind: 'numerical-convergence',
  },
];

// ---- Code Registry (S14: Eurocode 2 + BAEL seed) ----

export const CODES: readonly CodeRegistryEntry[] = [
  {
    id: 'eurocode2',
    name: 'Eurocode 2',
    version: 'EN 1992-1-1:2004+NA',
    clauses: [
      { id: '6.2', scope: 'flexion (ULS bending)', method: 'dimensionnement par couple interne', formulaRef: 'F.ec2.bending' },
      { id: '6.4', scope: 'cisillure (shear)', method: 'verrouillage diagonal', formulaRef: 'F.ec2.shear' },
    ],
  },
  {
    id: 'bael',
    name: 'BAEL (Béton Armé aux États Limites)',
    version: '1993 (FR)',
    clauses: [
      { id: '5.5', scope: 'flexion simple (ELS)', method: 'dimensionnement à la compression relative', formulaRef: 'F.bael.bending' },
      { id: '6.3', scope: 'cisillure (ELS)', method: 'acier anti-voile', formulaRef: 'F.bael.shear' },
    ],
  },
];

// ---- Formula Registry (5 seeds) ----

export const FORMULAS: readonly FormulaDefinition[] = [
  {
    id: 'F.statics.beam',
    expression: 'R_A + R_B = P \\quad \\text{and} \\quad R_B \\cdot L = P \\cdot x',
    variables: [
      { name: 'P', unit: 'N', description: 'point load' },
      { name: 'L', unit: 'm', description: 'span' },
      { name: 'x', unit: 'm', description: 'load position' },
    ],
    units: { input: ['N', 'm', 'm'], output: 'N' },
    conditions: ['simply supported ends'],
    sourceRef: 'RDM_ch3',
  },
  {
    id: 'F.Mmax',
    expression: 'M_{\\max} = \\frac{P \\cdot L}{4} \\quad \\text{(midspan, P at midspan)}',
    variables: [
      { name: 'P', unit: 'N', description: 'point load' },
      { name: 'L', unit: 'm', description: 'span' },
    ],
    units: { input: ['N', 'm'], output: 'N·m' },
    conditions: ['P at midspan'],
    sourceRef: 'RDM_ch3',
  },
  {
    id: 'F.Mmax_udl',
    expression: 'M_{\\max} = \\frac{w L^2}{8}',
    variables: [
      { name: 'w', unit: 'N/m', description: 'UDL' },
      { name: 'L', unit: 'm', description: 'span' },
    ],
    units: { input: ['N/m', 'm'], output: 'N·m' },
    conditions: ['UDL over full span'],
    sourceRef: 'RDM_ch3',
  },
  {
    id: 'F.la.gauss',
    expression: 'x = A^{-1} b',
    variables: [
      { name: 'A', unit: '1', description: 'coefficient matrix' },
      { name: 'b', unit: '1', description: 'RHS vector' },
    ],
    units: { input: ['1', '1'], output: '1' },
    conditions: ['square non-singular'],
    sourceRef: 'LinearAlgebra_ch1',
  },
  {
    id: 'F.boq.takeoff',
    expression: 'Q = L \\times W \\times H \\times c',
    variables: [
      { name: 'L', unit: 'm', description: 'length' },
      { name: 'W', unit: 'm', description: 'width' },
      { name: 'H', unit: 'm', description: 'height' },
      { name: 'c', unit: '1', description: 'coefficient' },
    ],
    units: { input: ['m', 'm', 'm', '1'], output: 'm³' },
    conditions: ['orthogonal volumes'],
    sourceRef: 'BTP_metre_ch1',
  },
];

// ---- Pattern Registry (4 seeds) ----

export const PATTERNS: readonly ProblemPattern[] = [
  {
    id: 'RDM_BEAM_SIMPLY_SUPPORTED_POINT_LOAD',
    domain: 'rdm',
    discipline: 'statics',
    signatures: [
      { phrase: 'poutre simplement appuyee', weight: 1.0 },
      { phrase: 'charge concentree au milieu', weight: 0.8 },
    ],
    expectedInputs: [
      { key: 'length', required: true },
      { key: 'load', required: true },
      { key: 'supports', required: true },
    ],
    methods: ['rdm.beam.statics', 'rdm.beam.shear_moment'],
    commonMistakes: ['confusing load position with midspan', 'forgetting support types'],
    examples: ['RDM_ch3_ex1'],
  },
  {
    id: 'RDM_BEAM_UDL',
    domain: 'rdm',
    discipline: 'shear_moment',
    signatures: [{ phrase: 'charge repartie uniformement', weight: 0.9 }],
    expectedInputs: [
      { key: 'length', required: true },
      { key: 'udl', required: true },
    ],
    methods: ['rdm.beam.shear_moment'],
    commonMistakes: ['using point-load formula for UDL'],
    examples: ['RDM_ch3_ex2'],
  },
  {
    id: 'LINEAR_SYSTEM',
    domain: 'math',
    discipline: 'linear_algebra',
    signatures: [{ phrase: 'systeme d\'equations lineaires', weight: 0.9 }],
    expectedInputs: [
      { key: 'matrix', required: true },
      { key: 'vector', required: true },
    ],
    methods: ['math.linear_system'],
    commonMistakes: ['singular matrix'],
    examples: ['LA_ch1_ex1'],
  },
  {
    id: 'BOQ_TAKEOFF',
    domain: 'other',
    discipline: 'metre',
    signatures: [{ phrase: 'decompte des quantites', weight: 0.8 }],
    expectedInputs: [{ key: 'items', required: true }],
    methods: ['metre.quantity_takeoff'],
    commonMistakes: ['missing category lines'],
    examples: ['BTP_metre_ch1_ex1'],
  },
];

// ---- Lookup helpers ----

export function findMethod(id: string): MethodDefinition | undefined {
  return METHODS.find((m) => m.id === id);
}

export function findSolver(id: string): SolverDefinition | undefined {
  return SOLVERS.find((s) => s.id === id);
}

export function findVerificationRule(id: string): VerificationRule | undefined {
  return VERIFICATION_RULES.find((v) => v.id === id);
}

export function findCode(id: string): CodeRegistryEntry | undefined {
  return CODES.find((c) => c.id === id);
}

export function findFormula(id: string): FormulaDefinition | undefined {
  return FORMULAS.find((f) => f.id === id);
}

export function findPattern(id: string): ProblemPattern | undefined {
  return PATTERNS.find((p) => p.id === id);
}
