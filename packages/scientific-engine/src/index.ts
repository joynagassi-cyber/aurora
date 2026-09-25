/**
 * @aurora/scientific-engine — wave 2, VECTOR.
 *
 * Implements `ScientificEnginePort` (AD-10) over the AD-15 SSoT types
 * (`@aurora/domain`). Boundary: pure TS, no vendor SDKs. Vendor engines
 * (SymPy, SciPy, EPANET) live in `@aurora/engineering-adapters` (AD-1)
 * and are plugged in as swappable backends.
 *
 * Features:
 *   - units: unit system + dimensional analysis (Quantity guardrail)
 *   - validation: 5-stage problem validator
 *   - registries: 5 seed methods / 5 solvers / 5 verification rules /
 *     Code Registry (Eurocode 2 + BAEL) / Formula + Pattern registries
 *   - beam: RDM simply-supported beam (reactions, V(x), M(x), M_max)
 *   - math: linear-system + symbolic fallbacks
 *   - metre: BOQ quantity takeoff + completeness check
 *   - engine: ScientificEnginePort adapter (normalize / solve / verify)
 *     + ArtifactGenerated producer (F-06) + SymbolicBackend contract
 *     (SymPy-ready, builtin-numeric fallback)
 *   - artifact-hub: per-kind preview matrix + export format selection
 *   - infographic: InfographicSpec (AD-10) + image tool ports + budget
 *   - r2: presign conventions + R2StoragePort contract
 *   - jobs: AD-8 idempotent job handlers (wired by ORION)
 */
export * from './units.ts';
export * from './validation.ts';
export * from './registries.ts';
export * from './beam.ts';
export * from './math.ts';
export * from './metre.ts';
export * from './engine.ts';
export * from './artifact-hub.ts';
export * from './infographic.ts';
export * from './r2.ts';
export * from './jobs.ts';

