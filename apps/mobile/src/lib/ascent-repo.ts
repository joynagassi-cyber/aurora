/**
 * Ascent local-mirror repo (dyad/beta: A2 — ascent wiring).
 *
 * The PowerSync mirror stores `ascent_paths` in SNAKE_CASE, with the 80/20
 * JSONB columns held as TEXT (packages/data/powersync-schema.ts l.404-407:
 * user_id, goal, target_skill, target_date, steps/depth/baseline/status/
 * adaptations, created_at, updated_at). The read-only `AscentLearningIR`
 * (packages/domain, AD-15 SSoT) is CAMEL_CASE with those JSONB fields parsed.
 *
 * The screen (pages/ascent/index.tsx) is UNCHANGED: it passes a camelCase
 * `where` ({ userId, status }). This repo — confined to the provider layer
 * (AD-15) — translates it to snake_case for the raw-mirror match, then maps
 * each row back to a parsed `AscentLearningIR`. Read-only + local (AD-7):
 * offline a stale mirror is a frozen path, never an error.
 */
import type { LocalFilter, LocalQueryRepository, LocalStore } from '@aurora/data';
import type { AscentLearningIR } from '@aurora/domain';

type RawRow = Record<string, unknown>;

const str = (v: unknown): string | undefined => (typeof v === 'string' ? v : undefined);

/** JSONB-in-TEXT → parsed value (PowerSync stores JSONB columns as TEXT). */
function json<T>(value: unknown, fallback: T): T {
  if (value == null) return fallback;
  if (typeof value === 'string') {
    try {
      return JSON.parse(value) as T;
    } catch {
      return fallback;
    }
  }
  return value as T;
}

/** camelCase `where` keys → the snake_case mirror column names. */
function toSnakeWhere(where?: Record<string, unknown>): Record<string, unknown> | undefined {
  if (!where) return undefined;
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(where)) {
    out[key.replace(/([A-Z])/g, (m) => '_' + m.toLowerCase())] = value;
  }
  return out;
}

/** snake_case mirror row → camelCase, JSONB-parsed `AscentLearningIR`. */
function mapRow(row: RawRow): AscentLearningIR {
  return {
    id: str(row.id) ?? str(row.user_id) ?? '',
    userId: str(row.user_id) ?? '',
    goal: str(row.goal) ?? '',
    targetSkill: str(row.target_skill) || undefined,
    targetDate: str(row.target_date) || undefined,
    steps: json<AscentLearningIR['steps']>(row.steps, []),
    depth: json<AscentLearningIR['depth']>(row.depth, {}),
    baseline: json<AscentLearningIR['baseline']>(row.baseline, {
      userId: str(row.user_id) ?? '',
      skillStates: [],
      gaps: [],
      fragiles: [],
      mastered: [],
      computedAt: '',
    }),
    prerequisites: json<AscentLearningIR['prerequisites']>(row.prerequisites, []),
    // not a dedicated mirror column in the 80/20 table → [] (read-only view).
    passageCriteria: json<AscentLearningIR['passageCriteria']>(
      row.passage_criteria ?? row.passageCriteria,
      [],
    ),
    adaptations: json<AscentLearningIR['adaptations']>(row.adaptations, []),
    status: (str(row.status) as AscentLearningIR['status'] | undefined) ?? 'active',
    createdAt: str(row.created_at) ?? '',
    updatedAt: str(row.updated_at) ?? '',
  };
}

/**
 * A `LocalQueryRepository<AscentLearningIR>` over the `ascent_paths` mirror,
 * with the snake→camel + JSON.parse mapping confined here (AD-15). No
 * network (AD-7); the screen + the QueryClient read through it local-only.
 */
export function createAscentRepo(store: LocalStore): LocalQueryRepository<AscentLearningIR> {
  const matches = (row: RawRow, where?: Record<string, unknown>): boolean =>
    !where || Object.entries(where).every(([k, v]) => row[k] === v);

  return {
    async getById(id) {
      const row = store.row('ascent_paths', id) as RawRow | undefined;
      return row === undefined ? undefined : mapRow(row);
    },
    async list(filter: LocalFilter<AscentLearningIR>) {
      const where = toSnakeWhere(filter.where as Record<string, unknown> | undefined);
      return (store.allRows('ascent_paths') as RawRow[])
        .filter((row) => matches(row, where))
        .map(mapRow);
    },
    watch(filter: LocalFilter<AscentLearningIR>, onChange: (rows: AscentLearningIR[]) => void) {
      const where = toSnakeWhere(filter.where as Record<string, unknown> | undefined);
      const deliver = (rows: RawRow[]): void => {
        onChange(rows.filter((row) => matches(row, where)).map(mapRow));
      };
      deliver(store.allRows('ascent_paths') as RawRow[]);
      return store.watch(
        { entity: 'ascent_paths', where } as unknown as LocalFilter<AscentLearningIR>,
        (rows) => deliver(rows as RawRow[]),
      );
    },
  };
}
