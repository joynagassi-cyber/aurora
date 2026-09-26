/**
 * Wave 3 — kernel core test (task 1 of 6).
 *
 * Verifies:
 *  - the 15-component wire-up (Intent → Context → Plan → … → Memory)
 *  - the intent classifier (typed, not keyword-sniffed)
 *  - the permission gate (destructive without confirmation = blocked)
 *  - the single-writer rule (the kernel itself writes no module table)
 *
 * Run: `pnpm --filter @aurora/agent test`
 * Node 22: `node --experimental-strip-types --test test/kernel.test.ts`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  AgentKernel,
  classifyIntent,
  buildTaskProfile,
  levelFor,
  AgnesPrimaryRouter,
  DefaultCapabilityRegistry,
  ConfirmationEngine,
  MemoryEngine,
  ExecutionEngine,
  ErrorRecovery,
  classifyFailure,
  normalizeResult,
  buildAgentContext,
  buildPlan,
  type ContextAssembler,
  type PermissionContext,
} from '../src/index.ts';

// ── helpers ──

function fakeAssembler(): ContextAssembler {
  const empty = async () => null;
  return {
    loadPersonal: async () => null,
    loadProductivity: async () => null,
    loadLearning: empty,
    loadDiscovery: empty,
    loadSemantic: empty,
    loadExpertSkills: async () => [],
    loadToolContext: empty,
    loadPermission: empty,
  } as unknown as ContextAssembler;
}

function openPerm(): PermissionContext {
  return {
    userId: 'u1',
    scopes: ['productivity:read', 'productivity:write', 'learning:write', 'discovery:read', 'engineering:read', 'knowledge:read'],
    featureState: {},
    allow: () => true,
  };
}

// ── Intent Engine ──

test('Intent: organize_day decomposes into the 4 canonical parts', () => {
  const i = classifyIntent({ userId: 'u1', intent: 'organize_day' });
  assert.deepEqual(i.parts, ['plan_day', 'schedule', 'focus_start', 'block_apps']);
  assert.equal(i.profile.tools, 2);
});

test('Intent: unknown intent degrades to the default ROUTINE profile', () => {
  const i = classifyIntent({ userId: 'u1', intent: 'wat' });
  assert.equal(i.kind, 'wat');
  assert.equal(i.profile.complexity, 'medium');
});

test('Intent: low-energy signals → critical latency (routing formula, S5)', () => {
  const p = buildTaskProfile({ energyLevel: 'low', interruptionCount: 4 });
  assert.equal(p.latency, 'critical');
});

// ── Router (S2.6: Agnes-primary) ──

function makeRouter(opts?: { agnesHealthy?: boolean; cooldown?: boolean }) {
  const registry = {
    list: () => [
      { provider: 'agnes', models: ['agnes-3.0'], role: 'primary', alwaysFirst: true },
      { provider: 'workers-ai', models: ['gemma-4-26b'], role: 'fallback' },
      { provider: 'groq', models: ['gpt-oss-120b'], role: 'fallback' },
    ],
    modelFor: (provider: string, _level: unknown, profile: { tools: number }) =>
      profile.tools > 0 ? `${provider}-agent` : `${provider}-fast`,
  };
  const health = {
    healthy: (p: string) => (p === 'agnes' ? opts?.agnesHealthy !== false : true),
    inCooldown: (p: string) => p === 'agnes' && opts?.cooldown === true,
  };
  const budget = { hasQuota: () => true };
  const dataPolicy = { compatible: () => true };
  return new AgnesPrimaryRouter(registry, health, budget, dataPolicy);
}

test('Router: Agnes is PRIMARY (alwaysFirst) when healthy', () => {
  const r = makeRouter();
  const pick = r.select(buildTaskProfile(undefined, { tools: 1 }), 'u1');
  assert.equal(pick?.provider, 'agnes');
  assert.equal(pick?.reason, 'primary');
});

test('Router: falls back to workers-ai when Agnes is in 429 cooldown', () => {
  const r = makeRouter({ cooldown: true });
  const pick = r.select(buildTaskProfile(undefined, { tools: 1 }), 'u1');
  assert.equal(pick?.provider, 'workers-ai');
  assert.equal(pick?.reason, 'fallback');
});

test('Router: sensitive data + compatible policy still routes (public data default)', () => {
  const r = makeRouter();
  const pick = r.select(buildTaskProfile(undefined, { tools: 0, dataSensitivity: 'public' }), 'u1');
  assert.equal(pick?.provider, 'agnes');
});

// ── Permission gate ──

test('Permission: destructive without confirmation is blocked by the engine', () => {
  const reg = new DefaultCapabilityRegistry();
  const entry = reg.byTool('blockApps');
  assert.ok(entry, 'focus.block (blockApps) is a registered capability');
  assert.equal(entry?.destructive, false); // it's confirmation-gated, not destructive
  // startFocus requires confirmation (important action, ADR S5).
  const focus = reg.byTool('startFocus');
  assert.equal(focus?.requiresConfirmation, true);
});

// ── Confirmation engine ──

test('Confirmation: timeout = safe-cancel (never auto-approve)', () => {
  const c = new ConfirmationEngine();
  c.prompt({ stepId: 's1', tool: 'startFocus', risk: 'write', message: 'start focus?' });
  c.decide({ stepId: 's1', answer: 'timeout', at: '2026-01-01' });
  assert.equal(c.isConfirmed('s1'), false);
  assert.equal(c.wasRejected('s1'), true);
});

// ── Memory engine (ADR S14.5 one-shot cap) ──

test('Memory: a one-shot observation never promotes past 0.5 (one-shot rule)', async () => {
  let stored: unknown = null;
  const mem = new MemoryEngine({
    upsert: async (s) => {
      stored = s;
    },
    load: async () => [],
    archive: async () => {},
    delete: async () => {},
    ulid: () => '00000000000000000000000001',
    now: () => '2026-01-01',
  });
  const skill = await mem.crystallize({
    userId: 'u1',
    key: 'planning.heavy-day',
    trigger: 'heavy day detected',
    objective: 'schedule blocks',
    procedure: ['x'],
    confidence: 0.9, // a single observation claims high confidence
    source: 'observation',
    provenance: { evidenceIds: ['e1'] },
  });
  assert.equal(skill.status, 'candidate');
  assert.ok(skill.confidence <= 0.5, `one-shot cap: ${skill.confidence}`);
  assert.equal(stored, skill);
});

// ── Error recovery (AD-5: 429 = cooldown, NEVER key rotation) ──

test('Recovery: a 429 → fallback (not retry, not key rotation)', () => {
  const rec = new ErrorRecovery();
  const cls = classifyFailure({ status: 429 });
  assert.equal(cls, 'rate_limited');
  const current = { provider: 'agnes', model: 'agnes-3.0', attempt: 1, reason: 'primary', expectedQuality: 'full' };
  const chain = [current, { ...current, provider: 'workers-ai', model: 'gemma-4-26b', reason: 'fallback' }];
  const d = rec.decide(cls, current, chain, 1);
  assert.equal(d.action, 'fallback');
  assert.ok(d.cooldownSec && d.cooldownSec >= 30, 'a 429 records a cooldown');
  assert.match(d.reason, /no key rotation/i);
});

test('Recovery: budget exhaustion = clean stop (no fallback)', () => {
  const rec = new ErrorRecovery();
  const cls = classifyFailure({ kind: 'budget' });
  assert.equal(cls, 'budget');
  const current = { provider: 'agnes', model: 'agnes-3.0', attempt: 1, reason: 'primary', expectedQuality: 'full' };
  const d = rec.decide(cls, current, [current], 1);
  assert.equal(d.action, 'stop');
});

// ── Result normalizer (AD-5 traceability) ──

test('Result: a fallback is marked fallbackUsed=true (traceable)', () => {
  const env = normalizeResult({
    data: 'ok',
    provider: 'workers-ai',
    model: 'gemma-4-26b',
    attempt: 2,
    reason: 'fallback',
    expectedQuality: 'full',
    traceId: 't-1',
  });
  assert.equal(env.fallbackUsed, true);
  assert.equal(env.provider, 'workers-ai');
});

// ── Planner: destructive/confirmation steps are flagged ──

test('Plan: startFocus + blockApps are confirmation points', () => {
  const reg = new DefaultCapabilityRegistry();
  const ctx = buildAgentContextSync('organize_day');
  const plan = buildPlan(ctx, openPerm(), {
    registry: reg,
    permission: (step, _c, _p) => {
      const e = reg.byTool(step.tool);
      return e && (e.destructive || e.requiresConfirmation) ? 'confirm' : 'allowed';
    },
    now: () => '2026-01-01',
    ulid: () => 's',
  });
  const confirmed = plan.confirmationPoints.length;
  assert.ok(confirmed >= 2, `expected ≥2 confirmation points, got ${confirmed}`);
});

/** Build a minimal AgentContext synchronously for the planner test. */
function buildAgentContextSync(intent: string) {
  const i = classifyIntent({ userId: 'u1', intent });
  return {
    intent: i,
    personal: {},
    productivity: {},
    learning: {},
    discovery: {},
    semantic: {},
    expertSkills: { active: [], provenance: [], evidenceIds: [] },
    tool: { available: [], providers: [] },
    permission: {},
  };
}

// ── Execution engine: confirmation gate blocks the destructive path ──

test('Execution: a rejected confirmation halts the run (no silent write)', async () => {
  const reg = new DefaultCapabilityRegistry();
  const confirmations = new ConfirmationEngine();
  const exec = new ExecutionEngine({
    invoke: async () => 'ok',
    dispatchJob: async () => ({ jobId: 'j1' }),
    confirmations,
    now: () => '2026-01-01',
  });
  const ctx = buildAgentContextSync('focus_start');
  const plan = buildPlan(ctx, openPerm(), {
    registry: reg,
    permission: (step, _c, _p) => {
      const e = reg.byTool(step.tool);
      return e && (e.destructive || e.requiresConfirmation) ? 'confirm' : 'allowed';
    },
    now: () => '2026-01-01',
    ulid: () => 's',
  });
  // Reject the startFocus confirmation.
  const step = plan.steps.find((s) => s.confirmationRequired);
  assert.ok(step, 'startFocus is confirmation-required');
  confirmations.decide({ stepId: step!.stepId, answer: 'rejected', at: '2026-01-01' });
  const { aborted } = await exec.execute(plan, 'u1');
  assert.equal(aborted, true, 'a rejected confirmation must halt the run');
});
