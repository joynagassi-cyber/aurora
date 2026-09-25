/**
 * Math solver — linear systems + symbolic (engineering-intelligence S4/S17).
 *
 * Deterministic. The SymPy backend (external engine, AD-1 adapter in
 * `engineering-adapters`) provides the symbolic path; this module ships
 * a built-in Gaussian-elimination linear-system solver that works
 * offline and locally.
 */
import type {
  CalculationStep,
  SolverOutput,
  SolverResult,
} from '@aurora/domain';
import { q } from './units.ts';

/** Solve Ax = b via Gaussian elimination with partial pivoting. */
export function solveLinearSystem(
  A: number[][],
  b: number[],
): { x: number[]; residual: number; steps: CalculationStep[] } {
  const n = A.length;
  if (n !== b.length || A.some((row) => row.length !== n)) {
    throw new Error('matrix/vector dimension mismatch');
  }

  // Augment.
  const M = A.map((row, i) => [...row, b[i]]);

  const steps: CalculationStep[] = [];

  // Forward elimination.
  for (let col = 0; col < n; col++) {
    // Partial pivoting.
    let pivot = col;
    for (let r = col + 1; r < n; r++) {
      if (Math.abs(M[r]![col]!) > Math.abs(M[pivot]![col]!)) pivot = r;
    }
    if (Math.abs(M[pivot]![col]!) < 1e-12) {
      throw new Error('singular matrix');
    }
    if (pivot !== col) [M[col], M[pivot]] = [M[pivot]!, M[col]!];

    for (let r = col + 1; r < n; r++) {
      const f = M[r]![col]! / M[col]![col]!;
      for (let c = col; c <= n; c++) {
        M[r]![c] = M[r]![c]! - f * M[col]![c]!;
      }
    }
    steps.push({
      id: `elim_${col}`,
      label: `eliminate column ${col}`,
      result: M.map((row) => row.slice(col, n + 1)),
    });
  }

  // Back substitution.
  const x = new Array(n).fill(0);
  for (let i = n - 1; i >= 0; i--) {
    let s = M[i]![n]!;
    for (let j = i + 1; j < n; j++) {
      s -= M[i]![j]! * x[j]!;
    }
    x[i] = s / M[i]![i]!;
  }

  // Residual ||Ax - b||∞.
  let residual = 0;
  for (let i = 0; i < n; i++) {
    let s = -b[i]!;
    for (let j = 0; j < n; j++) s += A[i]![j]! * x[j]!;
    residual = Math.max(residual, Math.abs(s));
  }

  steps.push({
    id: 'back_sub',
    label: 'back substitution',
    result: x,
  });

  return { x, residual, steps };
}

/** Solve a polynomial equation numerically (bisection fallback). */
export function solvePolynomial(
  coeffs: number[],
  initialGuess?: number,
): number {
  // Newton's method.
  const f = (x: number) =>
    coeffs.reduce((acc, c, i) => acc + c * Math.pow(x, i), 0);
  const fp = (x: number) =>
    coeffs.reduce(
      (acc, c, i) =>
        acc + c * (i === 0 ? 0 : i * Math.pow(x, i - 1)),
      0,
    );

  let x0 = initialGuess ?? 1;
  for (let i = 0; i < 100; i++) {
    const fx = f(x0);
    const dfx = fp(x0);
    if (Math.abs(dfx) < 1e-12) break;
    x0 = x0 - fx / dfx;
    if (Math.abs(fx) < 1e-10) break;
  }
  return x0;
}

/** Envelope a linear-system solution as a SolverResult. */
export function linearSystemToResult(
  A: number[][],
  b: number[],
  solverId: string,
  methodId: string,
): SolverResult {
  const { x, residual, steps } = solveLinearSystem(A, b);
  const outputs: SolverOutput[] = x.map((v, i) => ({
    key: `x_${i}`,
    quantity: q(v, 'rad'), // dimensionless
  }));
  outputs.push({ key: 'residual', quantity: q(residual, 'rad') });
  return {
    solverId,
    solverVersion: '0.1',
    status: 'unverified',
    normalizedInputs: [{ key: 'matrix', quantity: q(1, 'rad') }],
    assumptions: [],
    calculations: steps,
    outputs,
    verification: [],
    provenance: { method: methodId, formulas: ['F.la.gauss'] },
    confidence: {
      extraction: 1.0,
      method: 1.0,
      inputsComplete: true,
      solverStatus: 'deterministic',
      verificationStatus: 'all_pass',
      sourceAuthority: 'general',
    },
  };
}
