/**
 * Discovery module — the kernel read adapter for the vault (Lot 3,
 * discovery-vault plan 2026-10-10).
 *
 * AD-7 : Discovery est le seul reader/writer de SON vault. Le kernel
 * (chat-agent, packages/agent) N'Y ACCÈDE QUE via la commande typée
 * `discovery.vault_read` (packages/agent/src/tools.ts G13) ; cette
 * fonction est l'adaptateur que le module Discovery applique pour
 * répondre à cette commande — le lecteur lit via le port `VaultStore`
 * (le REST impl `createVaultStoreRest` est injecté par l'EF, 0025
 * `discovery_vault` sous RLS service_role).
 *
 * READ-ONLY : pas de write, pas de mutation. Le chat-agent PROPOSE
 * (un `JobProposal` loggé au manifest, appliqué au prochain run —
 * le run lit les propositions et décide, AD-7) ; seul le run committe.
 * En V1 la proposition est loggée uniquement (le choix LLM des verbes
 * = backlog) — le lecteur ici ne fait que RETOURNER l'état du vault.
 */
import type {
  VeilleVault,
  VaultRunManifest,
  VaultStore,
} from '@aurora/domain';

/** The payload the kernel command `discovery.vault_read` carries. */
export interface DiscoveryVaultReadPayload {
  /** le domaine de veille (ex. 'structures') */
  vaultDomaine: string;
  /** optionnel : lire UN run précis (rapport append-only) */
  runId?: string;
  /** l'identité du user courant (portée par le kernel, AD-7) */
  userId?: string;
}

/** What the kernel gets back from a `discovery.vault_read` command. */
export interface DiscoveryVaultReadResult {
  ok: boolean;
  /** the evolving VAULT.md (the SSoT the chat agent caches against) */
  vaultMd?: string;
  /** the append-only run manifest (for delta / "what changed" reads) */
  runs?: VaultRunManifest[];
  /** the specific run's rapport (when `runId` is set) */
  run?: VaultRunManifest;
  error?: string;
}

/**
 * `readDiscoveryVault` — the READ-ONLY adapter the Discovery module
 * applies for the kernel's `discovery.vault_read` command (AD-7 :
 * Discovery owns the read path of its own vault; the kernel never
 * touches `discovery_vault` directly, only via this typed command +
 * the injected `VaultStore` port).
 *
 * Degradation (AD-1): absent `userId` → `ok: false, error` (the kernel
 * must inject it, never trust a forged body, 0025 service_role RLS
 * bounds rows by user). No vault row → `ok: true` + empty manifest
 * (a fresh domain has no history yet — honest empty state, not an
 * error).
 */
export async function readDiscoveryVault(
  store: VaultStore,
  payload: DiscoveryVaultReadPayload,
): Promise<DiscoveryVaultReadResult> {
  const userId = payload.userId;
  if (userId === undefined || userId === '') {
    return { ok: false, error: 'discovery-vault-read/user_id_required' };
  }

  // The specific-run read (when runId is set) takes priority.
  if (payload.runId !== undefined && payload.runId !== '') {
    const run = await store.readRun(userId, payload.vaultDomaine, payload.runId);
    return run !== null
      ? { ok: true, run }
      : { ok: false, error: `discovery-vault-read/run_not_found:${payload.runId}` };
  }

  const vault: VeilleVault | null = await store.read(userId, payload.vaultDomaine);
  if (vault === null) {
    // Fresh domain : no history yet — honest empty, NOT an error.
    return { ok: true, vaultMd: '', runs: [] };
  }
  return { ok: true, vaultMd: vault.vaultMd, runs: vault.runs };
}
