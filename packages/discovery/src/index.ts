/**
 * @aurora/discovery — Discovery module public surface (wave 2, ORION).
 *
 * Pure domain logic: multi-source discovery sheets (ADR S13.8), the
 * `ResearchProvider` port (AD-1, optional → degraded `uncertain`
 * results), data-driven Benin filtering (discovery-gap-pipeline S5),
 * gap detection (S1), and the `DiscoveryItemCreated` event builder
 * (AD-9). No vendor SDKs (AD-1), no DOM, no cross-module table writes
 * (AD-2/AD-7: single-writer on `discovery_items`).
 */

export * from './research-provider.ts';
export * from './filtering.ts';
export * from './discovery.ts';
export * from './gaps.ts';
export * from './events.ts';
export * from './jobs.ts';
export * from './veille-pipeline.ts';

// LOT 2 (discovery-vault plan 2026-10-10) : le sous-module vault
// (synthèse + storage PNG). Le port `VaultStore` + les types SSoT
// (VeilleVault, VaultRunManifest, VaultVerbe) vivent dans @aurora/domain
// (AD-15) ; ce module en possède la LOGIQUE (appendRun, buildVaultMd,
// decideVerbe) + l'adapter storage (AD-1 : le vendor Supabase Storage
// reste dans l'implémentation du port, pas ici).
export * from './vault.ts';
export * from './vault-storage.ts';
export * from './vault-store-rest.ts';

// LOT 3 (discovery-vault plan 2026-10-10) : l'adaptateur de lecture du
// vault (AD-7 : Discovery est le seul reader/writer de son vault ; le
// kernel n'accède que via la commande typée `discovery.vault_read`
// portée par l'outil `discoveryVaultRead`, packages/agent).
export * from './vault-read.ts';

// LOT 1 (AD-1, cross-package import surface): the REAL research provider
// (Exa/Tavily/You.com adapters, packages/integrations) is re-exported so
// a consumer can inject it into `buildDiscoveryResearchHandler` without
// its own adapter import. The spec is the package root (`@aurora/integrations`)
// — its root re-exports carry the `.ts` extension (LOT 1), resolved
// identically by the node:test runtime AND the TS project.
export { createResearchProvider } from '@aurora/integrations';
