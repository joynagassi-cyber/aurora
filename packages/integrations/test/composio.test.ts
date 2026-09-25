/**
 * @aurora/integrations — Composio adapter tests (composio.md §11).
 * node:test + --experimental-strip-types. No network, no vendor key
 * required (AD-1 degrade-first: unconfigured env → offline fallback).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  ComposioIntegrationProvider,
  createIntegrationProvider,
  filterAvailableTools,
  toIntegrationsState,
} from '../src/composio.ts';
import type { ComposioTool, ConnectedAccount } from '../src/composio.ts';

const noTools: ComposioTool[] = [];
const someTools: ComposioTool[] = [
  {
    toolId: 'tool_gmail_send',
    app: 'gmail',
    name: 'gmail.send',
    requiredAuth: 'oauth',
  },
  {
    toolId: 'tool_notion_read',
    app: 'notion',
    name: 'notion.read_page',
    requiredAuth: 'oauth',
  },
];
const accounts: ConnectedAccount[] = [
  {
    connectedAccountId: 'ca-1',
    app: 'gmail',
    state: 'connected',
    lastCheckedAt: '2026-01-01T00:00:00Z',
  },
  {
    connectedAccountId: 'ca-2',
    app: 'notion',
    state: 'reauth_required',
  },
];

/** composio.md §11.2: unconnected app → tool marked unavailable;
 *  the kernel degrades, it does not fail. */
test('composio: filterAvailableTools marks unconnected/reauth apps unavailable', () => {
  const out = filterAvailableTools(someTools, accounts);
  const gmail = out.find((t) => t.app === 'gmail');
  const notion = out.find((t) => t.app === 'notion');
  assert.equal(gmail?.available, true);
  assert.equal(notion?.available, false);
  assert.equal(notion?.reason, 'reauth_required');
});

/** No accounts at all → everything unavailable, reason "unconnected". */
test('composio: no connected accounts → all tools unavailable', () => {
  const out = filterAvailableTools(someTools, []);
  assert.equal(out.length, someTools.length);
  for (const t of out) {
    assert.equal(t.available, false);
    assert.equal(t.reason, 'unconnected');
  }
});

/** toIntegrationsState maps vendor state onto the module SSoT shape
 *  (AD-7: only this module writes the integrations table). */
test('composio: toIntegrationsState maps to SSoT IntegrationsState', () => {
  const s = toIntegrationsState('u-1', accounts[0]);
  assert.equal(s.userId, 'u-1');
  assert.equal(s.vendor, 'composio');
  assert.equal(s.connection, 'gmail');
  assert.equal(s.status, 'connected');
});

/** AD-1 degrade-first: unconfigured env → provider reports
 *  not-configured, every call degrades without throwing. */
test('composio: unconfigured provider degrades without throwing', async () => {
  // Save/restore env so the test is deterministic regardless of CI.
  const prev = process.env.COMPOSIO_API_KEY;
  process.env.COMPOSIO_API_KEY = '';
  process.env.COMPOSIO_BASE_URL = 'http://127.0.0.1:0';
  try {
    const p = new ComposioIntegrationProvider();
    assert.equal(p.isConfigured(), false);
    assert.deepEqual(await p.discoverTools('u-1'), noTools);
    assert.deepEqual(await p.listConnectedAccounts('u-1'), []);
    const r = await p.executeTool('u-1', someTools[0], {});
    assert.equal(r.ok, false);
    assert.equal(r.error, 'composio_not_configured');
    assert.equal(r.trace.provider, 'composio');
  } finally {
    if (prev === undefined) delete process.env.COMPOSIO_API_KEY;
    else process.env.COMPOSIO_API_KEY = prev;
    delete process.env.COMPOSIO_BASE_URL;
  }
});

/** Factory returns the vendor adapter (AD-1: business code gets a
 *  provider, never the vendor SDK). */
test('composio: factory returns a configured-reporting provider', () => {
  const p = createIntegrationProvider();
  assert.equal(p.id, 'composio');
  assert.equal(typeof p.isConfigured(), 'boolean');
});
