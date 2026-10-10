/**
 * Discovery vault local-mirror repo (dyad/beta: discovery-vault plan
 * 2026-10-10, Lot 4).
 *
 * The PowerSync mirror stores `discovery_vault` in SNAKE_CASE, with the
 * JSONB `runs_manifest` column held as TEXT (`packages/data/powersync-
 * schema.ts` — every JSONB column is TEXT in the mirror). The read-only
 * `VeilleVault` (packages/domain, AD-15 SSoT) is CAMEL_CASE with the
 * manifest JSONB parsed.
 *
 * This repo is confined to the provider layer (AD-15, pattern of
 * `ascent-repo.ts`): it translates a camelCase `where` to the snake_case
 * mirror match, then maps each row back to a parsed `VeilleVault`. Read-
 * only + local (AD-7): offline a stale mirror is a frozen vault, never an
 * error. The Discovery card (pages/discovery) reads the SSoT vault + the
 * append-only manifest through it; no network on the render path.
 *
 * `domaine` is not a mirror column filter here — the mirror already
 * holds only the signed-in user's rows (RLS isolation, 01 S2.2) — but the
 * card lists vaults (one per veille domain) so `list` returns ALL of
 * them, camel-mapped.
 */
import type { LocalFilter, LocalQueryRepository, LocalStore } from '@aurora/data';
import type { VeilleVault, VaultRunManifest } from '@aurora/domain';

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

/** snake_case mirror row → camelCase, JSONB-parsed `VeilleVault`. */
function mapRow(row: RawRow): VeilleVault {
  const runs = json<VaultRunManifest[]>(row.runs_manifest ?? row.runs, []);
  return {
    id: str(row.id) ?? '',
    userId: str(row.user_id) ?? '',
    domaine: str(row.domaine) ?? '',
    vaultMd: str(row.vault_md) ?? '',
    vaultHash: str(row.vault_hash) ?? '',
    runs,
    storagePrefix: str(row.storage_prefix),
    createdAt: str(row.created_at) ?? '',
    updatedAt: str(row.updated_at) ?? '',
  };
}

/**
 * A `LocalQueryRepository<VeilleVault>` over the `discovery_vault` mirror,
 * with the snake→camel + JSON.parse mapping confined here (AD-15). No
 * network (AD-7); the card + the QueryClient read through it local-only.
 */
export function createDiscoveryVaultRepo(
  store: LocalStore,
): LocalQueryRepository<VeilleVault> {
  const matches = (row: RawRow, where?: Record<string, unknown>): boolean =>
    !where || Object.entries(where).every(([k, v]) => row[k] === v);

  return {
    async getById(id) {
      const row = store.row('discovery_vault', id) as RawRow | undefined;
      return row === undefined ? undefined : mapRow(row);
    },
    async list(filter: LocalFilter<VeilleVault>) {
      const where = toSnakeWhere(filter.where as Record<string, unknown> | undefined);
      return (store.allRows('discovery_vault') as RawRow[])
        .filter((row) => matches(row, where))
        .map(mapRow);
    },
    watch(
      filter: LocalFilter<VeilleVault>,
      onChange: (rows: VeilleVault[]) => void,
    ) {
      const where = toSnakeWhere(filter.where as Record<string, unknown> | undefined);
      const deliver = (rows: RawRow[]): void => {
        onChange(rows.filter((row) => matches(row, where)).map(mapRow));
      };
      deliver(store.allRows('discovery_vault') as RawRow[]);
      return store.watch(
        { entity: 'discovery_vault', where } as unknown as LocalFilter<VeilleVault>,
        (rows) => deliver(rows as RawRow[]),
      );
    },
  };
}
