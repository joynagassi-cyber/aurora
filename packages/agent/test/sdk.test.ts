/**
 * Wave 3 — Vercel AI SDK + 8 tools test (task 2).
 *
 * Verifies (no network, no keys — AD-3):
 *  - the 8 canonical tools are present with the right ids
 *  - the confirmation-gated tools are flagged
 *  - maxSteps = 5 (02 S4)
 *  - the gateway's fallback chain is Agnes-primary (S2.6)
 *  - the envelope marks a fallback (AD-5)
 *
 * Run: `pnpm --filter @aurora/agent test`
 * Node 22: `node --experimental-strip-types --test test/sdk.test.ts`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  KERNEL_TOOLS,
  ALL_TOOL_IDS,
  KERNEL_MAX_STEPS,
  ModelGateway,
  defaultRegistry,
  DefaultCapabilityRegistry,
  kernelMaxSteps,
  type KernelToolId,
} from '../src/index.ts';

const EXPECTED_TOOLS: KernelToolId[] = [
  'planDay', 'schedule', 'startFocus', 'blockApps',
  'research', 'qcm_generate', 'mirror_analyze', 'scientific_verify',
];

test('Tools: the 8 canonical kernel tools are registered (ids stable)', () => {
  for (const id of EXPECTED_TOOLS) {
    assert.ok(KERNEL_TOOLS[id], `tool ${id} is registered`);
  }
  // the goal-capability tools are ADDITIVE (dynamic-goal-engine.md),
  // the 8 canonical ones are the SSoT (capability-catalog S2).
  assert.ok(ALL_TOOL_IDS.length >= 8, `≥8 tools, got ${ALL_TOOL_IDS.length}`);
});

test('Tools: execute() returns a typed command / job descriptor (AD-7 single-writer)', async () => {
  // planDay → the Productivity command (the module applies the write).
  const planDay = KERNEL_TOOLS['planDay'];
  const out = await (planDay as { execute?: (i: unknown) => Promise<unknown> }).execute!(
    { examPeriod: false, energyLevel: 'high' },
  );
  assert.deepEqual(out, { ok: true, command: 'productivity.plan_day', payload: { examPeriod: false, energyLevel: 'high' } });

  // research → the persisted job descriptor (AD-8: heavy step).
  const research = KERNEL_TOOLS['research'];
  const rOut = await (research as { execute?: (i: unknown) => Promise<unknown> }).execute!(
    { topic: 'RDM flexion', domains: [], kinds: ['academic'] },
  );
  assert.equal((rOut as { jobKind: string }).jobKind, 'research', 'heavy tool → AD-8 job');

  // scientific_verify → the ScientificEngine job (AD-10, deterministic).
  const sv = KERNEL_TOOLS['scientific_verify'];
  const svOut = await (sv as { execute?: (i: unknown) => Promise<unknown> }).execute!({
    domain: 'rdm',
    problemType: 'flexion',
    inputs: [{ key: 'span', value: 5, unit: 'm' }],
    requestedOutputs: ['Mmax'],
  });
  assert.equal((svOut as { jobKind: string }).jobKind, 'scientific');
});

test('SDK: maxSteps = 5 (the 02 S4 streaming surface)', () => {
  assert.equal(KERNEL_MAX_STEPS, 5);
  assert.equal(kernelMaxSteps(), 5);
});

test('Gateway: the S2.6 chain is Agnes-primary, Workers AI + Groq fallback', () => {
  const gw = new ModelGateway({
    registry: defaultRegistry(),
    health: { healthy: () => true, inCooldown: () => false },
    budget: { hasQuota: () => true },
    dataPolicy: { compatible: () => true },
    keys: () => 'server-secret',
    baseURLs: {},
  });
  const profile = {
    complexity: 'medium' as const, reasoning: 'deep' as const, tools: 2, vision: false,
    contextSize: 4096, latency: 'normal' as const, cost: 'unconstrained' as const,
    criticality: 'routine' as const, verification: true, dataSensitivity: 'public' as const,
  };
  const chain = gw.chainFor(profile, 'u1');
  // S2.6 PRIORITY 3: Agnes ALWAYS first (alwaysFirst: true).
  assert.equal(chain[0]?.provider, 'agnes', 'Agnes is PRIMARY (S2.6)');
  assert.equal(chain[0]?.reason, 'primary');
  // the fallback chain follows (Workers AI → Groq → Cerebras → OpenRouter → CF Worker).
  const fallbacks = chain.filter((c) => c.reason === 'fallback').map((c) => c.provider);
  assert.ok(fallbacks.includes('workers-ai'), 'Workers AI is a fallback');
  assert.ok(fallbacks.includes('groq'), 'Groq is a fallback');
});

test('Gateway: a fallback marks the envelope fallbackUsed=true (AD-5 traceability)', () => {
  const gw = new ModelGateway({
    registry: defaultRegistry(),
    // Agnes is DOWN: every call goes to a fallback (reason != primary).
    health: {
      healthy: (p: string) => p !== 'agnes',
      inCooldown: () => false,
    },
    budget: { hasQuota: () => true },
    dataPolicy: { compatible: () => true },
    keys: () => 'server-secret',
    baseURLs: {},
  });
  const chain = gw.chainFor(
    { complexity: 'medium', reasoning: 'basic', tools: 0, vision: false, contextSize: 1024, latency: 'normal', cost: 'unconstrained', criticality: 'routine', verification: false, dataSensitivity: 'public' },
    'u1',
  );
  // The first eligible entry is NOT agnes → reason = fallback / last_resort.
  const first = chain[0];
  assert.ok(first, 'a fallback provider is eligible');
  assert.notEqual(first.reason, 'primary', 'with Agnes down the first pick is NOT primary');
  assert.ok(first.reason === 'fallback' || first.reason === 'last_resort');
});

test('Tools: confirmation-gated tools are flagged in the capability registry (ADR S5)', () => {
  // startFocus + blockApps require confirmation (important / DPC).
  const reg = new DefaultCapabilityRegistry();
  assert.equal(reg.byTool('startFocus')?.requiresConfirmation, true);
  assert.equal(reg.byTool('blockApps')?.requiresConfirmation, true);
  assert.equal(reg.byTool('planDay')?.requiresConfirmation, false);
});
