# Aurora Engineering Intelligence Layer (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 2-3, Scientific team).
**Replaces** the generic `docs/scientific-engine/overview.md` as the
prescriptive architecture for the scientific/technical computation core.
Authority: ADR S15 (Scientific Engine), AD-1 (vendor isolation), AD-8
(heavy = jobs), 01 S5.6 (verify as server job), kernel.md S12
(Verification Engine).

## 1. Core Principle

**The LLM does NOT solve the problem. The LLM transforms human language
into a formal representation, selects the method, and orchestrates the
tools. The solver computes. The verifier validates. The result is
structured, traceable, and reproducible.**

```
USER (NL / image)
  -> Agent Kernel (Intent + Context)
    -> Problem Parser (NL -> ProblemIR)
      -> Problem Validator (5 stages)
        -> Domain Classification
          -> Method Registry (SELECT method)
            -> Solver Registry (SELECT engine)
              -> Deterministic Execution
                -> Verification Registry (VALIDATE)
                  -> EngineeringResult (STRUCTURED)
                    -> KaTeX / AntV / Explanation (RENDER)
                      -> Learning / Progress (LEARN)
```

The LLM's role: **interpret, structure, select, orchestrate, explain.**
The engine's role: **compute, verify, produce deterministic output.**

## 2. Problem IR (Universal, NOT engineering-only)

A single `ProblemIR` type covers ALL domains. Domain-specific fields
are in typed sub-objects. The kernel NEVER branches on domain.

```ts
// packages/engineering-core/problem-ir.ts (SSoT, AD-15)

type ProblemIR = {
  id: string;
  domain: DomainId;            // 'math' | 'rdm' | 'concrete' | 'hydraulics' | 'geotech' | 'surveying' | 'gis' | 'remote_sensing' | 'statistics' | 'data_science' | ...
  discipline: DisciplineId;    // finer grain within domain
  problemType: string;         // 'simply_supported_beam_point_load', 'regression_ols', 'pipe_headloss', ...
  statement: string;           // verbatim user text (for provenance)
  inputs: ProblemInput[];
  unknowns: ProblemUnknown[];
  constraints: ProblemConstraint[];
  assumptions: Assumption[];
  requestedOutputs: RequestedOutput[];
  context?: ProblemContext;    // course, norm, method constraint
  sources: SourceRef[];        // AD-11 provenance
  confidence: {               // NOT a single "94%" — structured
    extraction: number;       // LLM interpretation confidence
    inputsComplete: boolean;  // all required inputs present?
    methodSelected: boolean;  // method found + validated?
  };
  status: ProblemStatus;
};

type ProblemStatus =
  | 'draft' | 'validated' | 'insufficient_data' | 'ambiguous'
  | 'unsupported' | 'ready_to_solve' | 'solved' | 'verification_failed';

// Domain-specific payloads (typed, NOT free-form):
type ProblemInput = { key: string; quantity?: Quantity; value?: unknown; unit?: Unit; };
type Quantity = { value: number; unit: Unit; dimension?: PhysicalDimension };
// NEVER: length: 6  (bare number, no unit)
// ALWAYS: { value: 6, unit: 'm' }
```

**The Quantity object is a global guardrail.** The unit system catches:
- `20 kN + 5 m` = dimensional mismatch (rejection, not a "soft warning")
- `500 mm` vs `0.5 m` = same quantity, different representation (normalization)
- `25 MPa` = `25e6 Pa` (conversion for the solver)

## 3. Five-Stage Validation

```
ProblemIR
  -> Stage 1: Extraction Validation
       "L'agent a-t-il bien compris 6 m et pas 8 m?"
       (confidence check, cross-reference with source)
  -> Stage 2: Physical Validation
       "Les unites sont-elles compatibles? Les valeurs physiques possibles?"
       (dimensional analysis, range checks)
  -> Stage 3: Structural/Domain Validation
       "La poutre a-t-elle assez d'appuis? Le reseau a-t-il des sources et un exutoire?"
       (domain-specific invariants)
  -> Stage 4: Method Validation
       "La methode proposee est-elle applicable a ce probleme?"
       (Method Registry applicability rules)
  -> Stage 5: Solver Validation
       "Le solveur accepte-t-il ce type de probleme avec ces entrees?"
       (Solver input schema check)
```

**Any stage failure = the problem is NOT solved.** The agent reports:
"Le type d'appui n'est pas identifiable avec certitude. Je ne lance
pas le calcul tant que ce point n'est pas confirme." (NOT a guess,
NOT a fallback assumption silently applied).

## 4. The Six Registries

```
                    KNOWLEDGE
                        |
           +-------------+-------------+
           v                           v
    Method Registry          Formula Registry
           |                           |
           +-------------+-------------+
                         v
                   Solver Registry
                         |
                         v
                  Verification Registry
                         |
                         v
                  Problem Pattern Registry
```

### 4.1 Method Registry

```ts
interface MethodDefinition {
  id: string;               // 'rdm.beam.statics', 'hydraulics.mannings'
  domain: string;
  discipline: string;
  applicableProblemTypes: string[];
  description: string;
  requiredInputs: InputRequirement[];
  assumptions: AssumptionRule[];
  algorithm: AlgorithmDefinition;  // description, NOT code
  solverId: string;               // which solver executes this method
  validationRules: string[];      // Verification Registry rule ids
  sourceRequirements: SourceRef[]; // which formulas/codes back this method
  codeRef?: string;               // 'eurocode2:6.2', 'bael:1993:5.5'
}
```

Separates **WHAT** (the problem) from **HOW** (the method) from
**WHICH ENGINE** (the solver).

### 4.2 Solver Registry

```ts
interface SolverDefinition {
  id: string;               // 'solver.rdm.beam.symbolic', 'solver.math.linear-system'
  name: string;
  version: string;
  supportedProblemTypes: string[];
  inputSchema: ZodSchema;   // strict typed inputs
  outputSchema: ZodSchema;  // strict typed outputs
  executionMode: 'local' | 'worker' | 'server' | 'external-engine';
  deterministic: boolean;
  validityDomain: {         // what the solver CAN handle
    dimensions: string[];   // '2D', '3D'
    supportTypes: string[];
    loadTypes: string[];
    assumptions: string[]; // 'Euler-Bernoulli', 'small_deformation', 'linear_elastic'
  };
  limitations: Limitation[]; // what it CANNOT do
  references: SourceRef[];
  testSuite: string[];
}
```

**Domain of validity is MANDATORY.** If the agent receives "poutre
comportement non-lineaire complexe", it checks the solver's
`validityDomain.assumptions` (includes 'linear_elastic') and
responds `UNSUPPORTED_MODEL` — it does NOT silently send it to a
linear solver.

### 4.3 Verification Registry

```ts
interface VerificationRule {
  id: string;               // 'equilibrium.sum_forces', 'dimensional.consistency'
  appliesTo: string[];      // solver ids or problem types
  inputs: string[];         // which fields of ProblemIR + SolverResult
  execute(problem, result): VerificationResult;
}
```

**Verification is NOT a second LLM "giving its opinion."** It is:
- Invariants (sum of forces = 0, sum of moments = 0)
- Analytical checks (dM/dx = V)
- Independent computation (a second method for the same problem)
- Domain rules (mass balance, energy balance, geometric bounds)
- Numerical convergence (residual < epsilon)

The Verification Registry is deterministic. The optional second LLM
("judge model", ADR v1.7 S14) is for AUDITING the reasoning chain,
NOT for replacing the numerical verification.

### 4.4 Problem Pattern Registry

```ts
interface ProblemPattern {
  id: string;              // 'RDM_BEAM_SIMPLY_SUPPORTED_POINT_LOAD'
  domain: string;
  discipline: string;
  signatures: PatternSignature[];  // NL phrases that match this pattern
  expectedInputs: InputRequirement[];
  methods: string[];       // Method Registry ids that apply
  commonMistakes: string[];
  examples: SourceRef[];
}
```

The agent uses patterns to RECOGNIZE the problem type from NL:
"une poutre de 6 m appuye aux deux extremites avec une force au
milieu" -> `RDM_BEAM_SIMPLY_SUPPORTED_POINT_LOAD` even if the
exact wording varies.

### 4.5 Formula Registry

```ts
interface FormulaDefinition {
  id: string;
  expression: string;      // LaTeX
  variables: { name: string; unit: Unit; description: string }[];
  units: { input: Unit[]; output: Unit };
  conditions: string[];   // "valide pour ELS", "valide si x < L/4"
  source: SourceRef;      // which course / code / reference
}
```

### 4.6 Code Registry (normative sources)

```ts
interface CodeRegistryEntry {
  id: string;             // 'eurocode2', 'bael', 'recommandation_btp'
  name: string;
  version: string;
  clauses: { id: string; scope: string; method: string; formulaRef: string }[];
}
```

"Calcule selon mon cours" -> method from the course's formula refs.
"Dimensionne selon Eurocode 2" -> method from the code registry.

## 5. Solver Result (structured, NOT a string)

```ts
interface SolverResult {
  solverId: string;
  solverVersion: string;
  status: 'verified' | 'unverified' | 'degraded' | 'failed';

  normalizedInputs: NormalizedInput[];
  assumptions: Assumption[];
  calculations: CalculationStep[];  // step-by-step (for explanation)
  outputs: SolverOutput[];          // typed results

  verification: {
    ruleId: string;
    status: 'pass' | 'fail' | 'skipped';
    detail: string;
  }[];

  visualization?: {         // AntV / KaTeX spec (the renderer draws, NOT the solver)
    type: 'chart' | 'diagram' | 'formula' | 'table';
    spec: unknown;          // ChartSpec, BeamDiagram, LaTeX, ...
  }[];

  provenance: {             // AD-11
    method: string;
    formulas: SourceRef[];
    code?: string;
    course?: SourceRef;
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
```

The same `SolverResult` feeds: chat explanation, AntV diagram,
PDF export, Knowledge Base, Progress evidence, Artifact Hub.
**One computation, many representations.** No re-computation.

## 6. Example: RDM Beam (complete pipeline)

**User:** "Une poutre de 6 m simplement appuye recoit une charge
ponctuelle de 20 kN au milieu. Donne-moi les reactions, V(x), M(x)
et le moment maximal."

```
1. Problem Parser (LLM):
   -> ProblemIR {
        domain: 'civil_engineering',
        discipline: 'rdm',
        problemType: 'simply_supported_beam_point_load',
        inputs: [
          { key: 'length', quantity: { value: 6, unit: 'm' } },
          { key: 'load', quantity: { value: 20, unit: 'kN' },
            position: { value: 3, unit: 'm' } },
        ],
        supports: [{ type: 'pin', pos: 0 }, { type: 'roller', pos: 6 }],
        requestedOutputs: ['reactions', 'shear', 'moment', 'max_moment'],
        status: 'draft',
      }

2. Validation:
   - Extraction: "6 m" confirmed from text. CONFIDENCE 0.95.
   - Physical: units consistent (m, kN). LENGTH > 0. LOAD position
     within [0, L]. PASS.
   - Structural: 2 supports (pin + roller) = statically determinate.
     3 equilibrium equations = 3 unknowns. PASS.
   - Method: 'rdm.beam.statics' applies to this problem type. PASS.
   - Solver: 'solver.rdm.beam.symbolic' accepts 2D beam with
     point loads. PASS.

3. Method Selection:
   -> MethodRegistry: 'rdm.beam.statics'
      -> solverId: 'solver.rdm.beam.symbolic'
      -> validationRules: ['equilibrium.sum_forces',
                            'equilibrium.sum_moments',
                            'boundary.conditions']

4. Deterministic Execution (SymPy Beam adapter):
   -> RAy = 10 kN, RBy = 10 kN
   -> V(x): 10 kN (0<x<3), -10 kN (3<x<6)
   -> M(x): 10x (0<x<3), 10(6-x) (3<x<6)
   -> M_max = 30 kN.m at x = 3 m

5. Verification:
   - sum_forces: 10 + 10 - 20 = 0. PASS.
   - sum_moments: 10*6 - 20*3 = 0. PASS.
   - boundary: M(0) = 0, M(6) = 0. PASS.
   - V discontinuity at x=3 matches P. PASS.

6. SolverResult:
   status: 'verified'
   outputs: { reactions: [{A: 10kN, B: 10kN}], shear: [...],
             moment: [...], max_moment: 30 kN.m }
   verification: all PASS
   visualization: [BeamDiagram { x[], V[], M[] }, Formula(M_max)]
   provenance: { method: 'statics', formulas: [F1, F2],
                 course: SourceRef('RDM_ch3') }
   confidence: { extraction: 0.95, method: 1.0, inputsComplete: true,
                 solver: 'deterministic', verification: 'all_pass',
                 source: 'course' }

7. Agent explanation (LLM, NOT the solver):
   "La poutre est simplement appuiee. Les reactions sont symetriques
   (10 kN chacune) car la charge est au milieu. Le moment maximal est
   30 kN.m a mi-pannee. [diagramme AntV] [formule KaTeX]"
```

## 7. Package Structure

```
packages/
  engineering-core/           (SSoT types, AD-15)
    problem-ir/             ProblemIR, ProblemInput, Quantity, Unit, ...
    quantities/             Unit system, dimensional analysis, conversion
    assumptions/            Assumption, AssumptionRule
    validation/             5-stage validator
    methods/                MethodRegistry (type + seed)
    verification/           VerificationRegistry (type + rules)
    results/                SolverResult, SolverOutput
    patterns/               ProblemPatternRegistry

  engineering-solvers/        (deterministic engines, AD-8 jobs)
    math/                   linear algebra, ODE, symbolic
    rdm/                    beam (statics, shear, moment, deflection),
                            truss, frame
    concrete/               BA (BAEL, Eurocode 2)
    geotech/                bearing, settlement, slope stability
    hydraulics/             pipe (Mannings, Hazen-Williams), network
    surveying/              coordinate transforms, least squares
    metre/                  quantity takeoff (BTP)
    gis/                    CRS, distance, area, buffer, overlay
    data-science/           regression, classification, time series

  engineering-adapters/       (vendor engines behind ports, AD-1)
    sympy/                  SymPy Beam / SymPy matrices
    scipy/                  SciPy optimization / integration
    epanet/                 EPANET network hydraulics (external engine)
    swmm/                   SWMM stormwater (external engine)
    gdal/                   GDAL raster processing
    postgis/                PostGIS spatial queries

  engineering-registry/       (seed data, server-side)
    disciplines/            domain + discipline taxonomy
    problem-patterns/       NL signatures per problem type
    formulas/               LaTeX + units + conditions + source
    methods/                method definitions
    solvers/                solver definitions
    codes/                  Eurocode, BAEL, norms
```

**AD-1 boundary:** `engineering-solvers` and `engineering-adapters`
are the ONLY packages that import vendor libraries (SymPy, SciPy,
EPANET). `engineering-core` is pure TypeScript (no vendor).
`packages/domain` imports types from `engineering-core` (AD-15 SSoT).

## 8. What the Agent does vs. what the Engine does

| Task | Agent (LLM) | Engine (deterministic) |
|---|---|---|
| Understand the problem | YES (NL -> ProblemIR) | NO |
| Select the method | YES (Method Registry lookup) | NO |
| Select the solver | YES (Solver Registry lookup) | NO |
| Execute the computation | NO | YES (SymPy, SciPy, etc.) |
| Verify the result | NO (invariants, equilibrium) | YES (Verification Registry) |
| Explain the result | YES (natural language) | NO |
| Render the diagram | NO (spec) | YES (AntV, KaTeX) |
| Detect missing inputs | YES (ProblemIR confidence) | NO |
| Say "I cannot solve this" | YES (UNSUPPORTED_MODEL) | NO |

**The agent NEVER invents a numerical result.** Every number in the
output comes from the solver. The agent's contribution is
interpretation, structure, method selection, verification
orchestration, and explanation.

## 9. Missing Inputs (the "je ne lance pas le calcul" rule)

```
ProblemIR.inputs = [length, load, supports]
Method.requiredInputs = [length, load, supports, material, section]
Missing: material, section

-> ProblemIR.status = 'insufficient_data'
-> Agent response: "Pour dimensionner la poutre, il me manque:
   - le beton (C25/30?)
   - l'acier (B500?)
   - l'enrobage
   - la section (b x h)
   - la norme (Eurocode 2 / BAEL / cours)
   Je ne lance pas le calcul tant que ces parametres ne sont pas confirms."
```

The agent lists EXACTLY what is missing. It does NOT assume defaults
silently. It does NOT "guess" C30/37 because "c'est le plus courant."

## 10. One-Day Build scope (wave 2, NOT 100 solvers)

```
Problem IR                          [x] types + validation
Quantity / Unit System              [x] dimensional analysis
Problem Pattern Registry            [x] 10 seed patterns (RDM, math, metre)
Formula Registry                    [x] 20 seed formulas
Method Registry                     [x] 5 seed methods
Verification Registry               [x] 5 seed rules (equilibrium, dimensional)
Solver Registry                     [x] 5 seed solvers
  - solver.math.linear-system       [x]
  - solver.rdm.beam.statics         [x] (SymPy adapter)
  - solver.rdm.beam.shear_moment    [x]
  - solver.metre.quantity           [x] (basic takeoff)
  - solver.math.symbolic            [x] (SymPy)
Agent integration                   [x] ProblemParser + MethodSelector tools
```

Then domains plug in progressively (wave 3+). The FRAMEWORK
accommodates 100 solvers; the One-Day Build ships 5.

## 11. GenieCivilPDF pipeline (document -> knowledge -> registries)

```
GenieCivilPDF (website, future)
  -> Document ingestion (R2 + OCR, 04 S3.2)
  -> Formula extraction (LaTeX, units, conditions)
  -> Concept extraction (definitions, theorems)
  -> Method extraction (procedure, assumptions)
  -> Worked Example extraction (problem + solution + method used)
  -> Problem Pattern extraction (NL signature + type + inputs)
  -> Source provenance (page, section, author)
  -> Knowledge Base (Postgres + pgvector + R2)
  -> Method Registry (additive entry)
  -> Pattern Registry (additive entry)
  -> Formula Registry (additive entry)
```

Horeb's courses come **on top** of this base:
```
General technical corpus (GenieCivilPDF)
  + Horeb's courses (specific notation, conventions, methods)
  + Normative sources (Eurocode, BAEL)
  -> Context resolution (which method for which course?)
```

## 12. Tests (wave 2+)

- ProblemIR: 10 examples across domains (math, RDM, BA, hydraulics,
  geotech, surveying, GIS, data science, statistics, metre)
- Quantity: dimensional mismatch rejection (kN + m = error)
- 5-stage validation: each stage catches its specific failure
- Method Registry: correct method for correct problem type
- Solver Registry: domain of validity enforced (non-linear -> UNSUPPORTED)
- Verification: equilibrium checks pass/fail correctly
- SymPy adapter: beam statics (point, UDL, moment) match hand calculations
- Missing inputs: "calcule l'acier" without section -> `insufficient_data`
- End-to-end: NL -> ProblemIR -> solver -> verified result -> AntV diagram
- Offline: SolverResult cached in SQLite; diagram renders offline

## 13. Correction: Never "100% reliable"

**ADR rule: Aurora NEVER promises a deterministic result is correct
without verification. The goal is:**

> "Aurora ne doit jamais inventer un resultat: chaque resultat
> technique doit etre **traceable** a un modele explicite, calcule
> par un moteur deterministe lorsque possible, controle par des
> invariants/controles independants, et presente avec ses hypotheses
> et son statut de validation."

Not "100% fiable". A deterministic engine can still produce a wrong
answer if:
- The input was misinterpreted (extraction error)
- The wrong physical model was chosen (method error)
- Units are inconsistent (quantity error)
- Assumptions are false (e.g., linear elastic applied to a plastic problem)
- Boundary conditions are wrong
- The solver has a bug

The Verification Registry catches what it can. What it cannot catch
is reported as `verification_failed` or `unverified`, NEVER as
"correct". The result always carries its confidence breakdown
(§5.7 in SolverResult.confidence).

## 14. Code Registry (for Concrete / Normative Design)

For Reinforced Concrete (BA), a simple dictionary of functions
(`calculerSectionAcier(...)`) is WRONG. The system must know:

```
Code Registry
  -> Eurocode 2 (EN 1992-1-1, 2004 + NA)
  -> BAEL (1993, French)
  -> Other supported codes
    |
    -> Version
    -> Clause / Design method
    -> Domain of application
    -> Parameters (fck, fyk, epsilon limits, ...)
    -> Units
    -> Algorithm
    -> Checks
```

Because:
```
Eurocode 2 != BAEL != other regulations
```
And within a code, assumptions and calculation rules vary by clause.

```
Code Registry
  -> Design Method
  -> Deterministic Solver
  -> Checks
```

The user's course can say: "Dans ce cours, le professeur utilise
telle convention." Aurora distinguishes:

| Source type | Example | Authority |
|---|---|---|
| **Course convention** | "Ce cours utilise la methode par recoupement" | Pedagogical, specific to the course |
| **Normative method** | "Eurocode 2 clause 6.2: dimensionnement en flexion" | Legal, general |
| **Generic engineering explanation** | "Le beton travaille en compression, l'acier en traction" | General, explanatory |

The `CodeRegistry` entry links: `code -> version -> clause -> method -> formula -> solver`.

```ts
interface CodeRegistryEntry {
  id: string;            // 'eurocode2', 'bael'
  name: string;
  version: string;       // 'EN 1992-1-1:2004+NA:2005'
  clauses: {
    id: string;          // '6.2'
    scope: string;       // 'flexion'
    method: string;      // 'dimensionnement par recoupement'
    formulaRef: string;  // -> Formula Registry
    codeRef?: string;    // -> other code
  }[];
  parameters: { name: string; default?: number; unit?: Unit }[];
}
```

"Calcule selon mon cours" -> method from the course's formula refs.
"Dimensionne selon Eurocode 2" -> method from the code registry.
**Different chains, same framework.**

## 15. Métré: BOQ Completeness + Structure Hierarchy

The LLM extracts the lines; the application does the math.
But the LLM can FORGET a line. So:

```
LLM
  -> extraction des dimensions
  -> BillOfQuantitiesSpec
  -> Unit validation
  -> COMPLETENESS CHECK (structure hierarchy)
  -> Quantity Engine
  -> aggregation
  -> totals
```

**Structure hierarchy for completeness check:**

```
Building
  -> Substructure (fondations, semelles, pieux)
  -> Structure (piliers, poutres, dalles)
  -> Enveloppe (murs, toitures, etanchite)
  -> Fluides (plomberie, electricite, CVC)
  -> Finitions (carrelage, peinture, menuiserie)
```

If the BOQ has "structure" items but no "substructure" items for a
building that needs foundations, the completeness check flags it:
"Attention: pas de ligne de fondations detectee dans le plan.
Veux-tu que je te les ajoute?"

```ts
type QuantityItem = {
  designation: string;
  category: string;        // 'substructure' | 'structure' | 'enveloppe' | ...
  unit: Unit;
  dimensions: {
    length?: Quantity;
    width?: Quantity;
    height?: Quantity;
    thickness?: Quantity;
  };
  coefficient?: number;
  quantity?: number;       // explicit count (not always L x W x H)
};
```

## 16. Hydraulics: Use Proven Engines, Don't Simulate in LLM

**Never ask the LLM to simulate a hydraulic network.**

| Engine | Use | Source |
|---|---|---|
| **EPANET** | Pressurized networks, head loss, pumps, valves, pressure-dependent demands | US EPA (free, open source) |
| **SWMM** | Stormwater / drainage: pipes, channels, storage, pumps, weirs, orifices, dynamic routing | US EPA (free, open source) |
| **Manning / Hazen-Williams** | Single pipe head loss (formula engine, not a simulation) | Deterministic formula |

```
Hydraulics Agent
  -> problem classification (network vs pipe vs stormwater)
  -> EPANET / SWMM / formula engine
  -> verification (mass balance, energy gradient)
  -> result
```

## 17. Five Engine Families

"Scientific Engine" is NOT one monolith. It is 5 families:

| Family | Solves | Examples |
|---|---|---|
| **A. Formula Engine** | Closed-form calculations | F=ma, A=b*h, V=L*l*h, Darcy, Manning, trig |
| **B. Symbolic Engine** | Algebraic manipulation | Equations, systems, derivatives, integrals, transformations (SymPy) |
| **C. Numerical Engine** | Optimization, regression, interpolation | Non-linear systems, ODE, ML training (SciPy) |
| **D. Domain Simulation** | RDM, hydraulics, FEM, networks | Beam solvers, EPANET, SWMM, finite elements |
| **E. Geometry / Spatial** | Topography, GIS, remote sensing, projections | CRS transforms, distance, intersection, raster (GDAL, PostGIS, Shapely) |

Each family = a subdirectory in `engineering-solvers/`. The
Method Registry routes to the right family. The Agent does not
need to know which family a solver belongs to.

## 18. Four-Layer RAG (Not a Paragraph Index)

```
                    COURSE KNOWLEDGE
                          |
       +------------------+------------------+
       |                  |                  |
   Concepts           Formulas            Methods
       |                  |                  |
       +------------------+------------------+
                          |
                       Examples
```

| Layer | Content | Retrieval trigger |
|---|---|---|
| **Concept RAG** | Definitions, principles, prerequisites, explanations | "Qu'est-ce que..." / "Explique-moi..." |
| **Formula RAG** | Formula, variables, units, conditions, equivalent forms, source | "Calcule..." / "Quelle formule..." |
| **Method RAG** | When applicable / not applicable, inputs, steps, assumptions, solver mapping | "Comment resoudre..." / "Methode pour..." |
| **Example RAG** | Worked example, problem pattern, expected workflow, common mistakes | "Exemple de..." / "Exercice similaire" |

This 4-layer structure lets Aurora learn HOW course documents
present problems (not just what they say).

## 19. Source Hierarchy (5 Levels)

```
LEVEL 1: Course explicitly provided by the user (highest authority for "their" convention)
LEVEL 2: Official standard / normative source (Eurocode, BAEL)
LEVEL 3: Verified engineering reference (textbook, solved problem)
LEVEL 4: General explanatory knowledge (encyclopedia, LLM general)
LEVEL 5: LLM inference (lowest authority, always flagged)
```

**Rule: Level 5 NEVER replaces a rule available at Levels 1-4.**
If the course says "use method X" and the general knowledge says
"use method Y", the course wins (Level 1 > Level 4). The agent
reports the conflict: "Ton cours utilise la methode par recoupement
(Level 1) alors que Eurocode 2 6.2 recommande la methode par
couple interne (Level 2). Je suis le cours. Veux-tu voir les deux?"

## 20. The "I Cannot Calculate" Rule (INSUFFICIENT_DATA)

When data is missing, Aurora does NOT silently assume.

```
VALID
VALID_WITH_ASSUMPTIONS (explicitly stated, user confirmed)
INSUFFICIENT_DATA ("Il me manque: la section, le beton, la norme.
                    Je ne lance pas le calcul tant que ce n'est pas confirme.")
METHOD_AMBIGUOUS ("Deux methodes sont applicables (A et B).
                  Ta norme utilise A, ton cours utilise B. Laquelle?")
OUT_OF_DOMAIN ("Ce probleme depasse le perimetre actuel d'Aurora
               (ex: comportement non-lineaire avec endommagement).
               Je ne peux pas le resoudre de facon fiable.")
VERIFICATION_FAILED ("Le solveur a calcule, mais le controle
                     d'equilibre echoue. Resultat non fiable.")
UNSUPPORTED ("Aucun solveur ne couvre ce type de probleme actuellement.")
```

**The agent NEVER says "je suppose que..." without the user's
explicit confirmation.** This is the "no silent assumption" rule.

## 21. Multi-Agent = Capabilities Within One Kernel

AD-12: ONE kernel, server-side. For engineering, the kernel
exposes 9 capabilities (NOT 9 independent agents):

```
Engineering Capabilities (within the Agent Kernel)
  Problem Parser
  Domain Classifier
  Method Selector
  Knowledge Retriever
  Solver Executor
  Verification Agent
  Diagram Builder
  Technical Explainer
  Report Generator
```

Each capability = a function the kernel calls, possibly with a
different model (routing, ADR v1.7 S6). The "Verification Agent"
can use a different model than the "Problem Parser" if the
verification task profile is different. But it is still ONE kernel.

## 22. The LLM is a Coordinator, NOT the Calculator

```
LLM        = interprets, plans, selects, explains
Engine      = computes (deterministic)
Verifier   = checks (invariants, equilibrium, dimensional)
Knowledge  = provides rules (formulas, methods, norms)
Renderer   = visualizes (AntV, KaTeX)
```

This separation is what makes the system reliable. The LLM's
hallucination risk is contained: it can misinterpret the problem
(catchable by validation) or pick the wrong method (catchable by
the Method Registry applicability check), but it CANNOT produce a
wrong number — the number comes from the solver.

## 23. Universal EngineeringResult (feeds all consumers)

```ts
interface EngineeringResult {
  status: 'VALID' | 'VALID_WITH_ASSUMPTIONS' | 'INSUFFICIENT_DATA'
         | 'METHOD_AMBIGUOUS' | 'OUT_OF_DOMAIN' | 'VERIFICATION_FAILED'
         | 'UNSUPPORTED';

  problem: ProblemIR;            // the formalized problem
  inputs: NormalizedInput[];    // what was actually used
  assumptions: Assumption[];    // what was assumed (explicit)
  method: MethodReference;      // which method, which code/clause
  solver: SolverReference;     // which engine, which version
  calculations: CalculationStep[];  // step-by-step (for explanation)
  outputs: EngineeringOutput[];     // typed results
  verification: {
    rules: { id: string; status: 'pass' | 'fail' | 'skipped'; detail: string }[];
    crossCheck?: { solverB: string; agreement: boolean; diff: number };
  };
  visualizations?: VisualizationSpec[];  // AntV / KaTeX / Diagram spec
  sources?: SourceRef[];               // AD-11 provenance
  confidence: {
    extraction: number;     // LLM interpretation
    method: number;         // method selection confidence
    inputsComplete: boolean;
    solver: 'deterministic' | 'numerical' | 'approximate';
    verification: 'all_pass' | 'partial' | 'failed' | 'skipped';
    sourceAuthority: 1 | 2 | 3 | 4 | 5;  // source hierarchy level
  };
}
```

The same `EngineeringResult` feeds:
- **Chat**: agent explains in natural language
- **AntV**: renders diagrams from `visualizations`
- **KaTeX**: renders formulas from `calculations`
- **PDF/DOCX/PNG**: Artifact export (artifact_gen job)
- **Knowledge Base**: stores the result + provenance
- **Progress**: records understanding evidence (F-07)
- **Learning**: generates similar problems for practice

**One computation. Many representations. No re-computation.**

## 24. Progress Integration (the "she learned it" loop)

After solving, Aurora can QUIZ the user:

```
Problem solved -> Agent: "Voici la solution. Maintenant,
  peux-tu resoudre celle-ci [similar problem]?"
  -> User attempts
  -> Agent verifies (same solver, different inputs)
  -> ProgressEvidence: "Horeb sait maintenant resoudre ce type
     de probleme seule" (S18.3: understanding evidence)
```

This connects the Engineering Intelligence Layer to the Progress
module: `ProgressEvidenceCreated` (F-07, sole producer = Progress).

## 25. Test Strategy (5 types + generation)

| Test type | What it catches | Example |
|---|---|---|
| **Golden tests** | Known-answer problems | "Beam 6m, P=20kN at midspan -> Mmax=30kN.m" |
| **Dimensional tests** | Unit inconsistencies | "kN + m" = rejected |
| **Boundary tests** | Edge cases | "charge = 0" -> "reactions = 0"; "L = 0" -> error |
| **Equilibrium tests** | Physical invariants | "sum F = 0, sum M = 0" always |
| **Metamorphic tests** | Scaling invariance | "Double all loads -> reactions double, moments double" (no need to know the exact answer) |
| **Cross-solver tests** | Implementation bugs | "Solver A result vs Solver B result" |
| **Regression tests** | Fix doesn't break | "Patch to beam solver doesn't change truss results" |
| **Generated problems** | Scale + invariants | "1000 random valid beams -> equilibrium + continuity + symmetry + units + bounds" |

**Generated problems** are the most powerful: a problem generator
creates 1000 valid random beams; the solver computes; invariants
(equilibrium, continuity, symmetry) are checked WITHOUT needing a
hand-computed answer for each one.

## 26. Full Pipeline (the target architecture)

```
AURORA
  |
  NATURAL LANGUAGE ("Resous cette poutre, montre-moi V(x) et M(x),
                     explique-moi pourquoi, et donne-moi 3 exercices similaires")
  |
  AGENT KERNEL (Intent + Context)
  |
  Problem Parser -> ProblemIR
  |
  Validation (5 stages)
  |
  Method Registry (select method + code/clause)
  |
  Solver Registry (select engine)
  |
  Deterministic Engine (SymPy / EPANET / formula / ...)
  |
  Verification Registry (invariants + cross-check)
  |
  EngineeringResult (structured, verified, provenance)
  |
  +--- AntV (diagrams: V(x), M(x), deflection)
  +--- KaTeX (formulas: M = PL/4)
  +--- Agent explanation ("Les reactions sont symetriques car...")
  +--- 3 similar problems (Problem Generator + Solver)
  +--- Learning (QCM / flashcards on the method)
  +--- Progress (evidence: "solved RDM beam type X")
  +--- Artifact (export: PDF with diagrams + explanation)
  +--- Knowledge (store: method + result + provenance)
```

**This is the system. Not a chatbot with RAG. A technical
computation platform with an intelligent front-end.**

## 27. One-Day Build (wave 2) — Realistic Scope

| Component | Status | Notes |
|---|---|---|
| ProblemIR types | IMPLEMENT | packages/engineering-core/problem-ir |
| Quantity / Unit system | IMPLEMENT | Dimensional analysis, conversion |
| 5-stage validation | IMPLEMENT | 5 validators |
| Problem Pattern Registry | IMPLEMENT | 10 seed patterns (RDM, math, metre, hydraulics) |
| Formula Registry | IMPLEMENT | 20 seed formulas |
| Method Registry | IMPLEMENT | 5 seed methods |
| Solver Registry | IMPLEMENT | 5 seed solvers |
| Verification Registry | IMPLEMENT | 5 seed rules |
| Code Registry | IMPLEMENT | Eurocode 2 + BAEL (basic) |
| Math solver | IMPLEMENT | Linear systems, symbolic (SymPy) |
| RDM beam solver | IMPLEMENT | Statics + shear + moment (SymPy Beam) |
| Basic metre engine | IMPLEMENT | Quantity takeoff (L x W x H, aggregation) |
| Agent integration | IMPLEMENT | ProblemParser + MethodSelector tools |

**Then domains plug in progressively (wave 3+):**
Concrete, Geotech, Hydraulics (EPANET/SWMM), Surveying, GIS,
Remote Sensing, Data Science. Each = a new solver package +
registry entries. The Agent Kernel does NOT change.

## 28. GenieCivilPDF -> Patterns -> Registries (the learning loop)

```
GenieCivilPDF (website, future)
  -> Document ingestion (R2 + OCR)
  -> Formula extraction (LaTeX + units + conditions)
  -> Concept extraction (definitions, theorems, principles)
  -> Method extraction (procedure, assumptions, steps)
  -> Worked Example extraction (problem + solution + method used)
  -> Problem Pattern extraction (NL signature + type + inputs)
  -> Source provenance (page, section, author, level)
  -> Knowledge Base (Postgres + pgvector + R2, 4-layer RAG)
  -> Method Registry (additive entries)
  -> Pattern Registry (additive entries)
  -> Formula Registry (additive entries)
```

Horeb's courses come **on top**:
```
General technical corpus (GenieCivilPDF)  [Level 3]
  + Horeb's courses                        [Level 1]
  + Normative sources (Eurocode, BAEL)    [Level 2]
  -> Context resolution (which method for which course?)
```

**The course does NOT modify the LLM's weights.** It builds a
Personal Knowledge Layer on top of the model:

```
Base Engineering Knowledge (general, Level 3-4)
  + Horeb Course Knowledge (specific, Level 1)
  + User Preferences (Level 1)
  + Progress (what she knows, Level 1)
  -> Reasoning: question -> course retrieval -> general retrieval
     -> method selection -> solver
```

## 29. Final Decision (Frozen, 2026-09-22)

**The six registries are the foundations of Aurora's scientific
engine:**

1. **Problem IR** (universal, typed, quantity-based)
2. **Problem Pattern Registry** (NL recognition)
3. **Formula Registry** (LaTeX + units + conditions + source)
4. **Method Registry** (what + how + assumptions + code ref)
5. **Solver Registry** (which engine + domain of validity + limitations)
6. **Verification Registry** (invariants + checks + cross-validation)

Plus supporting:
7. **Code Registry** (norms: Eurocode, BAEL, versions, clauses)
8. **5 engine families** (Formula, Symbolic, Numerical, Domain Sim, Geometry)

**The cardinal separation:**
> The LLM interprets and orchestrates.
> The Method Registry determines HOW to treat the problem.
> The Solver determines HOW to compute it.
> The Verification Registry determines if the result PASSES.

This is what allows Aurora to progressively cover RDM, concrete,
geotechnics, hydraulics, sanitation, surveying, quantity surveying,
GIS, remote sensing, statistics, and data science — without
turning the Agent into a massive set of specialized prompts.
