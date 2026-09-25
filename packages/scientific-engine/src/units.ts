/**
 * Unit system + dimensional analysis (engineering-intelligence S2).
 *
 * The `Quantity` guardrail: a bare number without a unit is a type error.
 * The unit system catches `20 kN + 5 m` as a hard dimensional mismatch —
 * rejection, not a soft warning.
 */
import type { PhysicalDimension, Quantity, Unit } from '@aurora/domain';

/** The engine's own units (ISO + prefixed codes). */
export const UNIT_SYSTEM: Record<string, Unit> = {
  // length
  m: { symbol: 'm', siBase: 'L', factor: 1, dimension: { base: { L: 1 } } },
  cm: { symbol: 'cm', siBase: 'L', factor: 0.01, dimension: { base: { L: 1 } } },
  mm: { symbol: 'mm', siBase: 'L', factor: 0.001, dimension: { base: { L: 1 } } },
  km: { symbol: 'km', siBase: 'L', factor: 1000, dimension: { base: { L: 1 } } },
  // area
  'm^2': { symbol: 'm²', siBase: 'L²', factor: 1, dimension: { base: { L: 2 } } },
  // volume
  'm^3': { symbol: 'm³', siBase: 'L³', factor: 1, dimension: { base: { L: 3 } } },
  // mass
  kg: { symbol: 'kg', siBase: 'M', factor: 1, dimension: { base: { M: 1 } } },
  // time
  s: { symbol: 's', siBase: 'T', factor: 1, dimension: { base: { T: 1 } } },
  // force
  N: { symbol: 'N', siBase: 'M/T²', factor: 1, dimension: { base: { M: 1, L: 1, T: -2 } } },
  kN: { symbol: 'kN', siBase: 'M/T²', factor: 1000, dimension: { base: { M: 1, L: 1, T: -2 } } },
  // stress / pressure
  Pa: { symbol: 'Pa', siBase: 'M/L·T²', factor: 1, dimension: { base: { M: 1, L: -1, T: -2 } } },
  kPa: { symbol: 'kPa', siBase: 'M/L·T²', factor: 1000, dimension: { base: { M: 1, L: -1, T: -2 } } },
  MPa: { symbol: 'MPa', siBase: 'M/L·T²', factor: 1e6, dimension: { base: { M: 1, L: -1, T: -2 } } },
  GPa: { symbol: 'GPa', siBase: 'M/L·T²', factor: 1e9, dimension: { base: { M: 1, L: -1, T: -2 } } },
  bar: { symbol: 'bar', siBase: 'M/L·T²', factor: 1e5, dimension: { base: { M: 1, L: -1, T: -2 } } },
  // moment
  'N·m': { symbol: 'N·m', siBase: 'M·L/T²', factor: 1, dimension: { base: { M: 1, L: 2, T: -2 } } },
  'kN·m': { symbol: 'kN·m', siBase: 'M·L/T²', factor: 1000, dimension: { base: { M: 1, L: 2, T: -2 } } },
  'MN·m': { symbol: 'MN·m', siBase: 'M·L/T²', factor: 1e6, dimension: { base: { M: 1, L: 2, T: -2 } } },
  // distributed load (force / length)
  'kN/m': { symbol: 'kN/m', siBase: 'M/T²', factor: 1000, dimension: { base: { M: 1, T: -2 } } },
  'N/m': { symbol: 'N/m', siBase: 'M/T²', factor: 1, dimension: { base: { M: 1, T: -2 } } },
  // moment of inertia
  'mm^4': { symbol: 'mm⁴', siBase: 'L⁴', factor: 1e-12, dimension: { base: { L: 4 } } },
  'm^4': { symbol: 'm⁴', siBase: 'L⁴', factor: 1, dimension: { base: { L: 4 } } },
  // dimensionless
  rad: { symbol: 'rad', siBase: '1', factor: 1, dimension: { base: {} } },
};

/**
 * Convert a value between two units of the SAME physical dimension.
 * Throws on a dimensional mismatch (20 kN -> m is rejected, not 0).
 */
export function convert(value: number, from: string, to: string): number {
  const uFrom = UNIT_SYSTEM[from];
  const uTo = UNIT_SYSTEM[to];
  if (!uFrom || !uTo) {
    throw new Error(`unknown_unit: ${!uFrom ? from : to}`);
  }
  if (!sameDimension(uFrom.dimension, uTo.dimension)) {
    throw new Error(`dimensional_mismatch: ${from} -> ${to} (different physical dimensions)`);
  }
  return (value * (uFrom.factor ?? 1)) / (uTo.factor ?? 1);
}

/** Build a `Quantity` value with a unit symbol. */
export function q(value: number, unit: string): Quantity {
  const u = UNIT_SYSTEM[unit];
  if (!u) throw new Error(`unknown_unit: ${unit}`);
  return { value, unit: u, dimension: u.dimension };
}

export function sameDimension(a: PhysicalDimension, b: PhysicalDimension): boolean {
  const keys = new Set([...Object.keys(a.base), ...Object.keys(b.base)]);
  for (const k of keys) {
    if ((a.base[k] ?? 0) !== (b.base[k] ?? 0)) return false;
  }
  return true;
}
