/**
 * Discovery module — vault PNG storage (Lot 2, discovery-vault plan
 * 2026-10-10).
 *
 * V1 (tranché 2026-10-10) : les PNG des runs vont dans Supabase
 * Storage (pas R2 — R2 = V2, OQ-03). Convention de key :
 *   {env}/{user_id}/discovery/{domaine}/runs/{yyyy-MM-dd}/fig-XX.png
 *
 * The module owns the key convention (AD-7 : Discovery écrit son
 * vault, incluant ses assets) ; le `StoragePort` (packages/domain)
 * exécuté côté EF via service_role (AD-3 : les clés restent server-only).
 *
 * This is a THIN adapter: it computes the key + delegates the actual
 * upload to the injected `StoragePort` implementation (the EF provides
 * the Supabase Storage client; tests provide a fake). The module never
 * imports a vendor SDK (AD-1).
 */
import type { StoragePort } from '@aurora/domain';

/** Compute the Supabase Storage key for a vault asset (pure). */
export function vaultAssetKey(
  env: string,
  userId: string,
  domaine: string,
  date: string,
  figIndex: number,
): string {
  // fig-XX.png : 2-digit zero-padded index (fig-01, fig-02, …)
  const fig = String(figIndex).padStart(2, '0');
  return `${env}/${userId}/discovery/${domaine}/runs/${date}/fig-${fig}.png`;
}

/**
 * `VaultStorage` — the vault's PNG upload adapter. Thin: computes the
 * key, delegates to the `StoragePort` (AD-1: no vendor import here).
 */
export class VaultStorage {
  private readonly storage: StoragePort;
  private readonly env: string;

  constructor(storage: StoragePort, env: string) {
    this.storage = storage;
    this.env = env;
  }

  /**
   * Upload a run's PNG assets to Supabase Storage. Returns the keys
   * (for the manifest's `assets[]` field).
   *
   * `assets` = (figIndex, bytes) pairs, 0-indexed → fig-01.png is
   * figIndex 0.
   */
  async uploadRunAssets(
    userId: string,
    domaine: string,
    date: string,
    assets: Array<{ bytes: Uint8Array }>,
  ): Promise<string[]> {
    const keys: string[] = [];
    for (let i = 0; i < assets.length; i += 1) {
      const asset = assets[i];
      if (asset === undefined) continue; // defensive: TS array access
      const key = vaultAssetKey(this.env, userId, domaine, date, i);
      // AD-1: delegate to the StoragePort (the EF provides the Supabase
      // Storage client); the module never imports a vendor SDK.
      await this.storage.upload(userId, key, asset.bytes, 'image/png');
      keys.push(key);
    }
    return keys;
  }
}
