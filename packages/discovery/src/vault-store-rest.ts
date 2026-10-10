/**
 * Discovery module — `VaultStore` REST implementation (Lot 2,
 * discovery-vault plan 2026-10-10).
 *
 * Writes the vault to `discovery_vault` via Supabase REST (service_role,
 * AD-3: the keys stay in the EF env, never on device / never in this
 * module's static state). The module's PURE vault logic (vault.ts) is
 * injected here; this file is the data-layer adapter that the dispatcher
 * (fn-job-dispatcher) instantiates at DEPLOYMENT time (AD-8: the EF has
 * the env, the module table doesn't).
 *
 * AD-7 single-writer: `write` is the ONLY mutation path — it upserts the
 * vault row BY (user_id, domaine) (the UNIQUE constraint from 0025).
 * `read` / `readRun` are SELECT-only (the client mirror + the chat agent,
 * Lot 3, use them).
 *
 * No vendor SDK (AD-1): plain `fetch` to the PostgREST endpoint, same
 * pattern as `buildDiscoveryHandlers.resolveUserContext` (fn-job-dispatcher).
 */
import type {
  VeilleVault,
  VaultRunManifest,
  VaultStore,
} from '@aurora/domain';

export interface VaultStoreRestDeps {
  /** the Supabase REST base URL (EF env) */
  supabaseUrl: string;
  /** the service_role key (EF env; `restHeaders` shape from the dispatcher) */
  serviceRoleKey: string;
}

/** Build the REST headers (same contract as fn-job-dispatcher `restHeaders`). */
function restHeaders(key: string): Record<string, string> {
  const h: Record<string, string> = { 'Content-Type': 'application/json' };
  if (!key) return h;
  h.apikey = key;
  if (key.startsWith('eyJ')) h.Authorization = `Bearer ${key}`;
  return h;
}

/**
 * `createVaultStoreRest` — the `VaultStore` port implementation over
 * PostgREST (discovery_vault, 0025).
 *
 * - `read` : SELECT BY (user_id, domaine) → null if absent (AD-1: the
 *   vault is optional, absent row = no prior run, the handler bootstraps).
 * - `write`: upsert BY (user_id, domaine) — the UNIQUE constraint makes
 *   this idempotent (AD-8: re-dispatch of the same run = same row, no dup).
 * - `readRun`: read the vault, find the run in `runs_manifest` by id.
 */
export function createVaultStoreRest(deps: VaultStoreRestDeps): VaultStore {
  const { supabaseUrl, serviceRoleKey } = deps;
  const base = `${supabaseUrl}/rest/v1/discovery_vault`;
  const headers = restHeaders(serviceRoleKey);

  return {
    async read(userId, domaine) {
      const qs = `user_id=eq.${encodeURIComponent(userId)}&domaine=eq.${encodeURIComponent(domaine)}&limit=1`;
      const res = await fetch(`${base}?${qs}`, { headers }).catch(() => null);
      if (!res || !res.ok) return null;
      const rows = (await res.json()) as Array<Record<string, unknown>>;
      const row = rows[0];
      if (row === undefined) return null;
      return mapRow(row) ?? null;
    },

    async write(userId, domaine, next) {
      // Upsert BY (user_id, domaine) — on_conflict targets the UNIQUE
      // constraint from 0025. The vault row is the SSoT (AD-7).
      const res = await fetch(`${base}?user_id=eq.${encodeURIComponent(userId)}&domaine=eq.${encodeURIComponent(domaine)}&on_conflict=user_id,domaine`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          user_id: userId,
          domaine,
          vault_md: next.vaultMd,
          vault_hash: next.vaultHash,
          runs_manifest: next.runs,
          storage_prefix: next.storagePrefix ?? null,
          // created_at is preserved on update (the upsert only touches the
          // SSoT fields; the 0025 trigger maintains updated_at).
        }),
      }).catch(() => null);
      if (!res || !res.ok) {
        throw new Error(`discovery_vault write failed: ${res?.status ?? 'network'}`);
      }
      // Read back the persisted row (the server assigns/keeps id + created_at).
      const r2 = await fetch(`${base}?user_id=eq.${encodeURIComponent(userId)}&domaine=eq.${encodeURIComponent(domaine)}&limit=1`, {
        headers,
      }).catch(() => null);
      if (r2 === null || !r2.ok) {
        throw new Error('discovery_vault read-back failed after write');
      }
      const rows = (await r2.json()) as Array<Record<string, unknown>>;
      const row = rows[0];
      return mapRow(row) ?? next;
    },

    async readRun(userId, domaine, runId) {
      const vault = await this.read(userId, domaine);
      if (vault === null) return null;
      const run = vault.runs.find((r) => r.id === runId);
      return run ?? null;
    },
  };
}

/** Map a PostgREST row (snake_case) to the `VeilleVault` SSoT shape. */
function mapRow(row: Record<string, unknown> | null | undefined): VeilleVault | null {
  if (row === undefined || row === null) return null;
  const runs = (row.runs_manifest as VaultRunManifest[] | undefined) ?? [];
  return {
    id: String(row.id ?? ''),
    userId: String(row.user_id ?? ''),
    domaine: String(row.domaine ?? ''),
    vaultMd: String(row.vault_md ?? ''),
    vaultHash: String(row.vault_hash ?? ''),
    runs,
    storagePrefix: row.storage_prefix !== null && row.storage_prefix !== undefined
      ? String(row.storage_prefix)
      : undefined,
    createdAt: String(row.created_at ?? ''),
    updatedAt: String(row.updated_at ?? ''),
  };
}
