/**
 * LOT 3 (discovery-vault plan 2026-10-10) — the READ-ONLY read adapter
 * `readDiscoveryVault` (packages/discovery/src/vault-read.ts, AD-7 :
 * Discovery owns the read path of its own vault; the kernel reaches it
 * only via the typed command `discovery.vault_read`).
 *
 * node:test + --experimental-strip-types. A fake `VaultStore` stands in
 * for the injected port so the adapter is tested in isolation.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { readDiscoveryVault } from '../src/vault-read.ts';
import type { VeilleVault, VaultRunManifest, VaultStore } from '@aurora/domain';

/** A minimal `VeilleVault` fixture. */
function makeVault(): VeilleVault {
  const run: VaultRunManifest = {
    id: 'run-0',
    date: '2026-10-10',
    domaine: 'structures',
    newSources: 2,
    totalSources: 2,
    relevance: 1.0,
    sectionsTouched: ['Ce que je sais'],
    mutations: [],
    at: '2026-10-10T08:00:00.000Z',
  };
  return {
    id: 'vault-1',
    userId: 'user1',
    domaine: 'structures',
    vaultMd: '# VAULT — structures',
    vaultHash: 'h0',
    runs: [run],
    createdAt: run.at,
    updatedAt: run.at,
  };
}

/** A fake VaultStore wired against in-memory state. */
function fakeStore(data: Map<string, VeilleVault>): VaultStore {
  const key = (u: string, d: string) => `${u}/${d}`;
  return {
    write: async (_u, _d, next) => next,
    read: async (u, d) => data.get(key(u, d)) ?? null,
    readRun: async (u, d, runId) => {
      const v = data.get(key(u, d));
      return v?.runs.find((r) => r.id === runId) ?? null;
    },
  };
}

test('LOT 3 readDiscoveryVault: no userId → ok:false, user_id_required (AD-7, EF ne fait pas confiance au body)', async () => {
  const store = fakeStore(new Map());
  const r = await readDiscoveryVault(store, { vaultDomaine: 'structures' });
  assert.equal(r.ok, false);
  assert.equal(r.error, 'discovery-vault-read/user_id_required');
});

test('LOT 3 readDiscoveryVault: no vault row → ok:true + honest empty state (fresh domain)', async () => {
  const store = fakeStore(new Map());
  const r = await readDiscoveryVault(store, { vaultDomaine: 'structures', userId: 'user1' });
  assert.equal(r.ok, true);
  assert.equal(r.vaultMd, '');
  assert.deepEqual(r.runs, []);
});

test('LOT 3 readDiscoveryVault: existing vault → returns vaultMd + runs', async () => {
  const data = new Map([['user1/structures', makeVault()]]);
  const r = await readDiscoveryVault(fakeStore(data), {
    vaultDomaine: 'structures',
    userId: 'user1',
  });
  assert.equal(r.ok, true);
  assert.equal(r.vaultMd, '# VAULT — structures');
  assert.equal(r.runs?.length, 1);
});

test('LOT 3 readDiscoveryVault: runId set + found → returns that run', async () => {
  const data = new Map([['user1/structures', makeVault()]]);
  const r = await readDiscoveryVault(fakeStore(data), {
    vaultDomaine: 'structures',
    userId: 'user1',
    runId: 'run-0',
  });
  assert.equal(r.ok, true);
  assert.equal(r.run?.id, 'run-0');
});

test('LOT 3 readDiscoveryVault: runId set + missing → ok:false, run_not_found', async () => {
  const data = new Map([['user1/structures', makeVault()]]);
  const r = await readDiscoveryVault(fakeStore(data), {
    vaultDomaine: 'structures',
    userId: 'user1',
    runId: 'run-404',
  });
  assert.equal(r.ok, false);
  assert.equal(r.error, 'discovery-vault-read/run_not_found:run-404');
});
