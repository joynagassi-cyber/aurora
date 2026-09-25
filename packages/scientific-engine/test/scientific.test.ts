/**
 * @aurora/scientific-engine — test suite (node built-in test runner,
 * per-feature, wave 2 delivery rule #4).
 *
 * Pure-domain tests: no vendor deps, no DOM.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  convert,
  q,
} from '../src/units.ts';
import { solveBeam } from '../src/beam.ts';
import { solveLinearSystem } from '../src/math.ts';
import { aggregateBoq, itemQuantity } from '../src/metre.ts';
import {
  METHODS,
  SOLVERS,
  VERIFICATION_RULES,
  CODES,
  FORMULAS,
  PATTERNS,
  findMethod,
  findSolver,
} from '../src/registries.ts';
import {
  BuiltInNumericBackend,
} from '../src/index.ts';
import {
  SymPyBackend,
} from '@aurora/engineering-adapters';
import {
  placeholderImage,
  validateInfographicSpec,
  budgetAllows,
  DEFAULT_IMAGE_BUDGET,
} from '../src/infographic.ts';
import { r2KeyForGenerated, R2_PRESIGN_TTL_GET_SEC } from '../src/r2.ts';

// ---- feature 1: units / dimensional analysis ----

test('units: 500mm -> 0.5m (normalization, same quantity)', () => {
  assert.equal(convert(500, 'mm', 'm'), 0.5);
});

test('units: 25MPa -> 25e6 Pa (conversion for the solver)', () => {
  assert.equal(convert(25, 'MPa', 'Pa'), 25e6);
});

test('units: 20kN + 5m = dimensional mismatch (REJECTION, not warning)', () => {
  assert.throws(() => convert(20, 'kN', 'm'), /dimensional_mismatch/);
});

test('units: q() rejects unknown units', () => {
  assert.throws(() => q(1, 'bogus'));
});

// ---- feature 2: RDM beam solver (golden test, hand-calculation) ----

test('beam: 6m span, P=20kN at midspan -> Ra=Rb=10kN, Mmax=30kN.m', () => {
  const r = solveBeam({ length: 6000, pointLoad: 20000, loadPos: 3000 });
  // N (internally SI)
  assert.ok(Math.abs(r.reactions.Ra - 10000) < 1e-6);
  assert.ok(Math.abs(r.reactions.Rb - 10000) < 1e-6);
  // Mmax = P·a·(L-a)/L = 20000 · 3000 · 3000 / 6000 = 30e6 N·mm (= 30 kN·m)
  assert.ok(Math.abs(r.maxMoment - 3e7) < 1e3, `Mmax=${r.maxMoment}`);
  assert.ok(Math.abs(r.maxMomentAt - 3000) < 1e-3);
  // Equilibrium: Ra + Rb = P
  assert.ok(Math.abs(r.reactions.Ra + r.reactions.Rb - 20000) < 1e-6);
  // Boundary: M(0) = M(L) = 0
  assert.ok(Math.abs(r.moment[0]!.value) < 1e-6);
  assert.ok(Math.abs(r.moment[r.moment.length - 1]!.value) < 1e-6);
});

test('beam: UDL over full span -> Mmax = wL^2/8', () => {
  const L = 4000; // 4000mm = 4m
  const w = 5; // N/mm (internally SI: 5000 N/m)
  const r = solveBeam({ length: L, udl: w });
  // Mmax = w·L²/8 (internally SI) = 5·4000²/8 = 1e7 N·mm (= 10 kN·m)
  const expectedMmax = (w * L * L) / 8;
  assert.ok(Math.abs(r.maxMoment - expectedMmax) < 1, `Mmax=${r.maxMoment} expected=${expectedMmax}`);
});

// ---- feature 3: linear system solver ----

test('math: 2x2 system [[1,1],[1,-1]] b=[1,3] -> x=[2,-1]', () => {
  const { x, residual } = solveLinearSystem(
    [
      [1, 1],
      [1, -1],
    ],
    [1, 3],
  );
  assert.ok(Math.abs(x[0]! - 2) < 1e-9);
  assert.ok(Math.abs(x[1]! - (-1)) < 1e-9);
  assert.ok(residual < 1e-9);
});

test('math: singular matrix throws', () => {
  assert.throws(() =>
    solveLinearSystem(
      [
        [1, 2],
        [2, 4],
      ],
      [3, 6],
    ),
  );
});

// ---- feature 4: metre / BOQ takeoff ----

test('metre: L x W x H volume item', () => {
  const qn = itemQuantity({
    designation: 'Concrete footing',
    category: 'substructure',
    unit: 'm^3',
    length: 3,
    width: 2,
    height: 0.4,
  });
  assert.ok(Math.abs(qn - 2.4) < 1e-9, `expected ~2.4, got ${qn}`);
});

test('metre: completeness check flags missing categories', () => {
  const totals = aggregateBoq([
    { designation: 'A', category: 'structure', unit: 'm^3', quantity: 10 },
  ]);
  assert.ok(totals.missingCategories.includes('substructure'));
  assert.ok(totals.missingCategories.includes('enveloppe'));
});

// ---- feature 5: registries (seed counts per the doc S27) ----

test('registries: 5 seed methods / solvers / verification rules / codes / formulas / patterns', () => {
  assert.equal(METHODS.length, 5);
  assert.equal(SOLVERS.length, 5);
  assert.equal(VERIFICATION_RULES.length, 5);
  assert.ok(CODES.length >= 2, 'Eurocode 2 + BAEL seed');
  assert.ok(FORMULAS.length >= 5);
  assert.ok(PATTERNS.length >= 4);
  assert.equal(findMethod('rdm.beam.statics')?.solverId, 'solver.rdm.beam.symbolic');
  assert.equal(findSolver('solver.rdm.beam.symbolic')?.deterministic, true);
});

// ---- feature 6: SymPy adapter (AD-1: graceful degradation) ----

test('sympy: SymPyBackend falls back to built-in numeric when probe is false', async () => {
  const backend = new SymPyBackend(async () => false);
  const { x, backend: used } = await backend.solve(
    [
      [1, 1],
      [1, -1],
    ],
    [1, 3],
  );
  assert.ok(Math.abs(x[0]! - 2) < 1e-9);
  assert.equal(used, 'sympy');
});

// ---- feature 7: infographic (placeholder + budget gate) ----

test('infographic: spec validation + placeholder degradation + budget', () => {
  const spec = {
    type: 'grid' as const,
    columns: 2,
    gap: 15,
    sections: [
      { id: 's1', label: 'Le Concept', imageSlot: 'generated' as const, imageRef: '{{tool_2_result_1}}', text: '...' },
      { id: 's2', label: 'Exemple', imageSlot: 'searched' as const, imageRef: '{{tool_1_result_1}}', caption: 'NASA/JPL' },
    ],
  };
  assert.equal(validateInfographicSpec(spec).ok, true);

  const empty = validateInfographicSpec({ type: 'grid', sections: [] });
  assert.equal(empty.ok, false);

  // Placeholder (AD-1: provider absent -> styled placeholder, never broken).
  assert.equal(placeholderImage('photo').imageUrl, 'placeholder_url');

  // Budget (AD-5: 2 per infographic, 20 per day).
  assert.equal(budgetAllows(DEFAULT_IMAGE_BUDGET), true);
  const drained = {
    ...DEFAULT_IMAGE_BUDGET,
    usedThisBuild: 2,
  };
  assert.equal(budgetAllows(drained), false);
});

// ---- feature 8: R2 key convention + presign TTL ----

test('r2: key naming + presign TTL (01 S5.4)', () => {
  const key = r2KeyForGenerated('user-1', 'artifact-abc', 'report.pdf');
  assert.equal(key, 'artifacts/generated/user-1/artifact-abc/report.pdf');
  assert.equal(R2_PRESIGN_TTL_GET_SEC, 900); // 15 min
});
