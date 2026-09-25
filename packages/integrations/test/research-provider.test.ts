/**
 * @aurora/integrations — test suite (wave 2, ORION).
 * node:test + --experimental-strip-types.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  createResearchProvider,
  ExaResearchProvider,
  TavilyResearchProvider,
  YouComResearchProvider,
} from '../src/research-provider.ts';

/** AD-1: no keys configured → providers report not-configured, factory
 *  degrades to the offline provider (01 §6: no product break). */
test('research provider: unconfigured env → offline fallback', () => {
  const exa = new ExaResearchProvider();
  const tavily = new TavilyResearchProvider();
  const you = new YouComResearchProvider();
  assert.equal(exa.isConfigured(), (process.env.EXA_API_KEY ?? '') !== '');
  assert.equal(tavily.isConfigured(), (process.env.TAVILY_API_KEY ?? '') !== '');
  assert.equal(you.isConfigured(), (process.env.YOU_API_KEY ?? '') !== '');

  const p = createResearchProvider();
  if (!exa.isConfigured() && !tavily.isConfigured() && !you.isConfigured()) {
    assert.equal(p.id, 'offline');
    assert.equal(p.isConfigured(), false);
  }
});

/** An unconfigured provider search returns empty (no network, no throw). */
test('research provider: unconfigured search → empty results', async () => {
  const exa = new ExaResearchProvider();
  if (exa.isConfigured()) return; // skip when a real key is set in CI
  const out = await exa.search({
    userId: 'u-1',
    topic: 'FEM validation',
    domains: ['structures'],
    kinds: ['technical'],
  });
  assert.deepEqual(out, []);
});
