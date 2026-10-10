/**
 * G13 (discovery-vault plan 2026-10-10, Lot 3).
 *
 * discovery_vault_read : l'outil kernel READ-ONLY qui porte la
 * commande typée `discovery.vault_read` (packages/agent). AD-7 :
 * Discovery est le seul reader/writer de son vault (table
 * `discovery_vault`, 0025) ; le kernel n'Y ACCÈDE QUE via cette
 * commande + l'adaptateur de lecture `readDiscoveryVault`
 * (packages/discovery/src/vault-read.ts). L'outil est READ-ONLY :
 * pas de write scope, pas de job, sans confirmation (ADR §5) — le
 * chat-agent RÉUTILISE les recherches archivées (caching), il ne
 * relance jamais le même search.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { KERNEL_TOOLS, DefaultCapabilityRegistry } from '../src/index.ts';
import { discoveryVaultRead } from '../src/tools.ts';

const reg = new DefaultCapabilityRegistry();

test('G13: discovery_vault_read est dans KERNEL_TOOLS', () => {
  assert.ok('discovery_vault_read' in KERNEL_TOOLS, 'discovery_vault_read en KERNEL_TOOLS');
});

test('G13: le registry discovery.vault.read est READ-ONLY (0 write scope, non-destructif, sans confirmation)', () => {
  const read = reg.get('discovery.vault.read');
  assert.ok(read, 'registry discovery.vault.read');
  assert.equal(read?.writeScopes.length, 0, 'discovery.vault.read a 0 write scope (READ-ONLY)');
  assert.equal(read?.destructive, false, 'non-destructif');
  assert.equal(read?.requiresConfirmation, false, 'sans confirmation');
  assert.equal(read?.readScopes[0], 'discovery:read', 'read scope discovery:read');
});

test('G13: discoveryVaultRead émet discovery.vault_read (READ-ONLY, commande typée)', async () => {
  const r = (await discoveryVaultRead.execute(
    { vaultDomaine: 'structures', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { vaultDomaine: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'discovery.vault_read');
  assert.equal(r.payload.vaultDomaine, 'structures');
});

test('G13: byTool résout discovery_vault_read vers discovery.vault.read', () => {
  assert.equal(
    reg.byTool('discovery_vault_read')?.id,
    'discovery.vault.read',
    'byTool("discovery_vault_read") doit résoudre vers "discovery.vault.read"',
  );
});
