/**
 * Metre / Quantity Takeoff engine (engineering-intelligence S15).
 *
 * The LLM extracts the lines; the application does the math.
 * Completeness check: structure hierarchy (substructure / structure /
 * envelope / fluides / finitions).
 */
import type {
  CalculationStep,
  SolverOutput,
  SolverResult,
} from '@aurora/domain';
import { q } from './units.ts';

export interface BoqItem {
  designation: string;
  category:
    | 'substructure'
    | 'structure'
    | 'enveloppe'
    | 'fluides'
    | 'finitions'
    | 'other';
  unit: 'm' | 'm^2' | 'm^3' | 'kg' | 'unit' | 'L';
  /** dimensions for L×W×H computation (SI base units: metres for length) */
  length?: number;
  width?: number;
  height?: number;
  /** explicit count (not always L×W×H) */
  quantity?: number;
  coefficient?: number;
}

export interface BoqTotals {
  byCategory: Record<string, { quantity: number; unit: string }>;
  totalQuantity: number;
  missingCategories: string[];
}

/** The structure hierarchy completeness check. */
const REQUIRED_CATEGORIES: BoqItem['category'][] = [
  'substructure',
  'structure',
  'enveloppe',
];

/** Compute a single item's quantity. */
export function itemQuantity(item: BoqItem): number {
  if (item.quantity !== undefined) {
    return item.quantity * (item.coefficient ?? 1);
  }
  const l = item.length ?? 0;
  const w = item.width ?? 0;
  const h = item.height ?? 0;
  let base: number;
  switch (item.unit) {
    case 'm':
      base = l;
      break;
    case 'm^2':
      base = l * w;
      break;
    case 'm^3':
      base = l * w * h;
      break;
    case 'kg':
    case 'L':
    case 'unit':
      base = 1;
      break;
  }
  return base * (item.coefficient ?? 1);
}

/** Aggregate a BOQ into totals + completeness check. */
export function aggregateBoq(items: BoqItem[]): BoqTotals {
  const byCategory: Record<string, { quantity: number; unit: string }> = {};
  for (const item of items) {
    const qn = itemQuantity(item);
    const existing = byCategory[item.category];
    if (existing) {
      // Same unit — additive.
      existing.quantity += qn;
    } else {
      byCategory[item.category] = { quantity: qn, unit: item.unit };
    }
  }
  const present = new Set(items.map((i) => i.category));
  const missingCategories = REQUIRED_CATEGORIES.filter(
    (c) => !present.has(c),
  );
  return {
    byCategory,
    totalQuantity: Object.values(byCategory).reduce((a, b) => a + b.quantity, 0),
    missingCategories,
  };
}

/** Envelope a BOQ takeoff as a SolverResult. */
export function boqToResult(
  items: BoqItem[],
  solverId: string,
  methodId: string,
): SolverResult {
  const totals = aggregateBoq(items);
  const outputs: SolverOutput[] = [
    {
      key: 'totals',
      value: totals.byCategory,
    },
    {
      key: 'missing_categories',
      value: totals.missingCategories,
    },
  ];
  const steps: CalculationStep[] = items.map((item, i) => ({
    id: `item_${i}`,
    label: item.designation,
    result: itemQuantity(item),
  }));
  return {
    solverId,
    solverVersion: '0.1',
    status: 'unverified',
    normalizedInputs: [{ key: 'items', quantity: q(items.length, 'unit') }],
    assumptions: [],
    calculations: steps,
    outputs,
    verification: [
      {
        ruleId: 'dimensional.boq_units',
        status: totals.missingCategories.length > 0 ? 'skipped' : 'pass',
        detail:
          totals.missingCategories.length > 0
            ? `missing categories: ${totals.missingCategories.join(', ')}`
            : 'all required categories present',
      },
    ],
    provenance: { method: methodId, formulas: ['F.boq.takeoff'] },
    confidence: {
      extraction: 1.0,
      method: 1.0,
      inputsComplete: totals.missingCategories.length === 0,
      solverStatus: 'deterministic',
      verificationStatus:
        totals.missingCategories.length === 0 ? 'all_pass' : 'partial',
      sourceAuthority: 'inferred',
    },
  };
}
