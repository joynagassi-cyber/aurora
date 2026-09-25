/**
 * @aurora/engineering-adapters — test suite (node built-in test runner).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  SymPyBackend,
  SymPyUnavailable,
  type SymPyProbe,
} from '../src/sympy.ts';

// ---- feature: SymPy adapter (AD-1 graceful degradation) ----

test('sympy: probe=false -> deterministic built-in fallback (beam/matrix solve)', async () => {
  const noSympy: SymPyProbe = () => false;
  const backend = new SymPyBackend(noSympy);
  const { x, backend: used } = await backend.solve(
    [
      [1, 1],
      [1, -1],
    ],
    [1, 3],
  );
  // x = [2, -1] (the built-in Gaussian elimination result, re-labelled 'sympy')
  assert.ok(Math.abs(x[0]! - 2) < 1e-9);
  assert.ok(Math.abs(x[1]! - -1) < 1e-9);
  assert.equal(used, 'sympy');
});

test('sympy: evaluate() returns a pass-through expression (V1 placeholder)', async () => {
  const noSympy: SymPyProbe = () => false;
  const backend = new SymPyBackend(noSympy);
  const out = backend.evaluate('M_max = P*L/4', { P: 20, L: 6 });
  // V1: the formula is carried through verbatim for the KaTeX renderer;
  // a SymPy worker attaches real symbolic evaluation in wave 3.
  assert.match(out, /M_max = P\*L\/4/);
});

test('sympy: SymPyUnavailable is a typed error (for diagnostic surfacing)', () => {
  const e = new SymPyUnavailable();
  assert.equal(e.name, 'SymPyUnavailable');
});
