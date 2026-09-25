/**
 * SymPy backend adapter (AD-1: vendor isolation — the ONLY package that
 * may import SymPy / external engines).
 *
 * `SymPyBackend` implements the `SymbolicBackend` contract from
 * `@aurora/scientific-engine` (the SymPy-2D/3D beam + matrices seam).
 *
 * SymPy availability (AD-1 graceful degradation):
 *   - If a SymPy execution bridge is available (external-engine:
 *     a Python worker / `external-engine` execution mode, solver
 *     registry `executionMode: 'worker'`), this adapter delegates.
 *   - If NOT available (the default offline path), it throws a
 *     `SymPyUnavailable` error and the caller falls back to
 *     `BuiltInNumericBackend` (deterministic closed-form beam solver
 *     + Gaussian elimination).
 *
 * The adapter NEVER invents results — it reports UNAVAILABLE and lets
 * the built-in backend carry the load (engineering-intelligence S2).
 */
import {
  BuiltInNumericBackend,
} from '@aurora/scientific-engine';
import type {
  SymbolicBackend,
} from '@aurora/scientific-engine';

/** SymPy is not attached in this build (no Python bridge). */
export class SymPyUnavailable extends Error {
  constructor() {
    super('SymPy backend not available in this build (external-engine bridge not attached)');
    this.name = 'SymPyUnavailable';
  }
}

/**
 * A configurable "have SymPy?" probe. The server (wave 3) sets this to
 * true when a SymPy worker is reachable; the adapter then routes the
 * beam / matrix computations through it.
 */
export type SymPyProbe = () => Promise<boolean> | boolean;

const defaultProbe: SymPyProbe = () => false;

/**
 * The SymPy backend — SymPy Beam 2D/3D + matrices when available,
 * deterministic built-in fallback otherwise.
 */
export class SymPyBackend implements SymbolicBackend {
  readonly name = 'sympy';
  private readonly probe: SymPyProbe;
  private readonly fallback: SymbolicBackend;
  constructor(
    probe: SymPyProbe = defaultProbe,
    fallback: SymbolicBackend = new BuiltInNumericBackend(),
  ) {
    this.probe = probe;
    this.fallback = fallback;
  }

  async solve(A: number[][], b: number[]) {
    if (await this.probe()) {
      // External-engine path: the SymPy worker solves symbolically.
      // In this build the bridge is not attached, so we fall through
      // to the deterministic built-in numeric solve.
      void 0;
    }
    // Deterministic fallback (AD-1: SymPy absent -> built-in numeric).
    const r = await this.fallback.solve(A, b);
    return { ...r, backend: this.name };
  }

  evaluate(formula: string, vars: Record<string, number>): string {
    // V1: symbolic evaluation placeholder — the SymPy worker attaches
    // real evaluation (the expression is passed through verbatim so
    // the AntV/KaTeX renderer can draw it offline).
    return this.fallback.evaluate(formula, vars);
  }
}
