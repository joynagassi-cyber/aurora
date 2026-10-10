/**
 * Automations local-mirror repo (dyad/beta: discovery-vault plan
 * 2026-10-10, Lot 4 — the Discovery card reads the veille program).
 *
 * The card's title + subtitle come from a veille program, which IS an
 * `Automation` with `jobKind: 'research'` (migration 0008, AD-15 SSoT).
 * The `automations` mirror table is populated by the PowerSync
 * `integrations` stream (schema.json: `mirrorTables.integrations =
 * [automations]`, stream `SELECT * FROM automations WHERE user_id =
 * auth.user_id()`).
 *
 * This repo is confined to the provider layer (AD-15, pattern of
 * `ascent-repo.ts`): a `LocalQueryRepository<Automation>` over the
 * `automations` mirror. The card reads the research automations
 * (`where: { jobKind: 'research' }`) local-only; offline a stale mirror
 * is a frozen program list, never an error (AD-7).
 *
 * NOTE: the WRITE side (`automations`) is owned by the Integrations
 * module (AD-7 single-writer) — the card's 3-point menu emits the typed
 * G2/G3 commands (`update_automation` / `delete_automation`,
 * packages/agent), it NEVER writes `automations` directly.
 */
import type { LocalFilter, LocalQueryRepository, LocalStore } from '@aurora/data';
import type { Automation } from '@aurora/domain';

type RawRow = Record<string, unknown>;

const str = (v: unknown): string | undefined => (typeof v === 'string' ? v : undefined);

/** snake_case mirror row → camelCase `Automation`. */
function mapRow(row: RawRow): Automation {
  return {
    id: str(row.id) ?? '',
    userId: str(row.user_id) ?? '',
    name: str(row.name) ?? '',
    trigger: (str(row.trigger) as Automation['trigger']) ?? 'schedule',
    triggerEvent: str(row.trigger_event),
    cron: str(row.cron),
    jobKind: str(row.job_kind),
    action: str(row.action),
    enabled: (row.enabled as boolean) ?? false,
    createdAt: str(row.created_at) ?? '',
    updatedAt: str(row.updated_at) ?? '',
  };
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

/**
 * A `LocalQueryRepository<Automation>` over the `automations` mirror.
 * Read-only here (the write side is the Integrations module, AD-7).
 */
export function createAutomationsRepo(
  store: LocalStore,
): LocalQueryRepository<Automation> {
  const matches = (row: RawRow, where?: Record<string, unknown>): boolean =>
    !where || Object.entries(where).every(([k, v]) => row[k] === v);

  return {
    async getById(id) {
      const row = store.row('automations', id) as RawRow | undefined;
      return row === undefined ? undefined : mapRow(row);
    },
    async list(filter: LocalFilter<Automation>) {
      const where = toSnakeWhere(filter.where as Record<string, unknown> | undefined);
      return (store.allRows('automations') as RawRow[])
        .filter((row) => matches(row, where))
        .map(mapRow);
    },
    watch(filter: LocalFilter<Automation>, onChange: (rows: Automation[]) => void) {
      const where = toSnakeWhere(filter.where as Record<string, unknown> | undefined);
      const deliver = (rows: RawRow[]): void => {
        onChange(rows.filter((row) => matches(row, where)).map(mapRow));
      };
      deliver(store.allRows('automations') as RawRow[]);
      return store.watch(
        { entity: 'automations', where } as unknown as LocalFilter<Automation>,
        (rows) => deliver(rows as RawRow[]),
      );
    },
  };
}
