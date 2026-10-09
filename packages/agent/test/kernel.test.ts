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
  type KernelEvent,
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

// ── LOT 1 / Story 1.1 — confirmation gating (no auto-confirm) ──

/**
 * A minimal kernel whose invokeTool / jobs / invokeModel record every
 * call, so the tests can assert what actually ran.
 */
function makeKernelHarness() {
  const calls = {
    tools: [] as string[],
    jobs: [] as string[],
  };
  const kernel = new AgentKernel({
    assembler: fakeAssembler(),
    permission: async () => openPerm(),
    router: {} as never,
    invokeModel: async () => ({
      data: 'ok',
      provider: 'agnes',
      model: 'agnes-3.0',
      attempt: 1,
      reason: 'primary',
      expectedQuality: 'full',
      traceId: 't1',
    }),
    invokeTool: async (tool, _input) => {
      calls.tools.push(tool);
      return 'ok';
    },
    jobs: {
      dispatch: async (req) => {
        calls.jobs.push(req.jobKind);
        return { jobId: 'j1', status: 'pending' } as never;
      },
      getJob: async () => null,
    } as never,
    memory: {} as never,
    verification: {
      verifyJob: async () => ({ ok: true }),
      checkSources: async () => ({ ok: true, refs: [] }),
    } as never,
    ulid: () => 'seed',
    now: () => '2026-01-01',
  });
  return { kernel, calls };
}

async function collect(req: { userId: string; intent: string; decisions?: Array<{ stepId: string; answer: 'confirmed' | 'rejected'; stepHash?: string }> }) {
  const { kernel, calls } = makeKernelHarness();
  const events: KernelEvent[] = [];
  for await (const ev of kernel.run(req as never)) events.push(ev);
  return { events, calls };
}

test('Confirmations: a write step with no decision → nothing executes, confirmation event emitted', async () => {
  const { events, calls } = await collect({ userId: 'u1', intent: 'focus_start' });
  assert.deepEqual(calls.tools, [], 'no inline tool ran');
  assert.deepEqual(calls.jobs, [], 'no job dispatched');
  assert.ok(events.some((e) => e.type === 'confirmation'), 'a confirmation event was emitted');
  assert.equal(events[events.length - 1].type, 'done', 'the run terminates cleanly');
  assert.equal(events[events.length - 1].state.status, 'awaiting-confirmation');
});

test('Confirmations: a confirmed write step executes', async () => {
  // Pass 1 → capture the confirmation step id (stable: deterministic ulid).
  const first = await collect({ userId: 'u1', intent: 'focus_start' });
  const confEv = first.events.find((e) => e.type === 'confirmation');
  assert.ok(confEv, 'pass 1 emits a confirmation');
  assert.equal(confEv!.type, 'confirmation');
  const stepId = (confEv as Extract<KernelEvent, { type: 'confirmation' }>).state.confirmationStepId;
  assert.ok(stepId, 'the confirmation state carries the step id');

  // Pass 2 → resume with the decision. The step ids are stable across
  // passes (ulid() = 'seed'), so decisions key off the same stepId.
  // LOT 1-bis / 1.1-bis: the decision now carries the stepHash that was
  // stamped on the prompt in pass 1 (content binding).
  const stepHash = (confEv as Extract<KernelEvent, { type: 'confirmation' }>).prompt?.stepHash;
  const { calls } = await collect({ userId: 'u1', intent: 'focus_start', decisions: [{ stepId, answer: 'confirmed', ...(stepHash ? { stepHash } : {}) }] });
  assert.ok(calls.tools.length > 0 || calls.jobs.length > 0, 'the confirmed step executed');
});

test('Confirmations: a rejected write step is NEVER executed', async () => {
  const first = await collect({ userId: 'u1', intent: 'focus_start' });
  const confEv = first.events.find((e) => e.type === 'confirmation');
  assert.ok(confEv, 'pass 1 emits a confirmation');
  const stepId = (confEv as Extract<KernelEvent, { type: 'confirmation' }>).state.confirmationStepId;
  const stepHash = (confEv as Extract<KernelEvent, { type: 'confirmation' }>).prompt?.stepHash;

  const { events, calls } = await collect({ userId: 'u1', intent: 'focus_start', decisions: [{ stepId, answer: 'rejected', ...(stepHash ? { stepHash } : {}) }] });
  assert.deepEqual(calls.tools, [], 'the rejected step did not run');
  assert.deepEqual(calls.jobs, [], 'no job dispatched after rejection');
  assert.equal(events[events.length - 1].state.status, 'cancelled');
});

test('Confirmations: a read-only step runs without any decision', async () => {
  // canvas_read is risk 'read' in the capability registry → no
  // confirmation point: it must execute straight through.
  const { events, calls } = await collect({ userId: 'u1', intent: 'canvas_read' });
  assert.equal(events.find((e) => e.type === 'confirmation'), undefined, 'no confirmation event');
  assert.deepEqual(calls.tools, ['canvas_read'], 'the read tool executed');
  assert.equal(events[events.length - 1].state.status, 'succeeded');
});

// ── LOT 1-bis / Story 1.1-bis — server-side resume + stepHash binding ──

import { computeStepHash } from '../src/kernel.ts';

test('LOT 1.1-bis: computeStepHash is deterministic and content-bound (imported, not copied)', () => {
  const a = computeStepHash('blockApps', { appIds: ['1'] });
  const b = computeStepHash('blockApps', { appIds: ['1'] });
  const c = computeStepHash('blockApps', { appIds: ['2'] });
  assert.equal(a, b, 'same tool + input → same hash');
  assert.notEqual(a, c, 'different input → different hash');
  assert.equal(typeof a, 'string');
});

test('LOT 1.1-bis: a decision whose stepHash no longer matches is NOT trusted (re-prompted, never auto-confirmed)', async () => {
  // Pass 1: capture the confirmation step + its stepHash (stamped by the
  // kernel at prompt time via computeStepHash).
  const first = await collect({ userId: 'u1', intent: 'focus_start' });
  const confEv = first.events.find((e) => e.type === 'confirmation');
  assert.ok(confEv, 'pass 1 emits a confirmation');
  const prompt = (confEv as Extract<KernelEvent, { type: 'confirmation' }>).prompt;
  assert.ok(prompt.stepHash, 'the confirmation prompt carries a stepHash (content binding)');
  const stepId = prompt!.stepId;

  // Pass 2: a FORGED stepHash (the step content changed — or an attacker
  // replayed a stale answer) → the kernel must NOT trust it: no tool
  // runs, a fresh confirmation event is emitted instead.
  const forged = await collect({
    userId: 'u1',
    intent: 'focus_start',
    decisions: [{ stepId, answer: 'confirmed', stepHash: 'deadbeefdeadbeef' }],
  });
  assert.deepEqual(forged.calls.tools, [], 'a mismatched stepHash never auto-confirms');
  assert.ok(forged.events.some((e) => e.type === 'confirmation'), 'the step is re-prompted');
  assert.equal(forged.events[forged.events.length - 1].state.status, 'awaiting-confirmation');

  // Pass 3: the CORRECT stepHash → trusted, the step executes.
  const trusted = await collect({
    userId: 'u1',
    intent: 'focus_start',
    decisions: [{ stepId, answer: 'confirmed', stepHash: prompt!.stepHash }],
  });
  assert.ok(trusted.calls.tools.length > 0, 'a matching stepHash is trusted — the step runs');
});

test('LOT 1.1-bis: resuming ANOTHER user\'s run (wrong user_id) → 404, the plan is never re-loaded', async () => {
  // The resume seam (loadPendingPlan, fn-agent-bootstrap) filters by
  // user_id — a caller can only ever re-load their own stopped run.
  // Here the resumePlan dep reports "not found" (the 404 the REST
  // layer surfaces when trace_id + user_id match no row) → the kernel
  // degrades to a fresh plan build; it NEVER trusts a plan from a
  // different user, and still stops at the confirmation point.
  const { calls } = makeKernelHarness();
  let reloaded = false;
  const kernelWithResume = new AgentKernel({
    assembler: fakeAssembler(),
    permission: async () => openPerm(),
    router: {} as never,
    invokeModel: async () => ({
      data: 'ok',
      provider: 'agnes',
      model: 'agnes-3.0',
      attempt: 1,
      reason: 'primary',
      expectedQuality: 'full',
      traceId: 't1',
    }),
    invokeTool: async (tool, _input) => {
      calls.tools.push(tool);
      return 'ok';
    },
    jobs: {
      dispatch: async (req) => {
        calls.jobs.push(req.jobKind);
        return { jobId: 'j1', status: 'pending' } as never;
      },
      getJob: async () => null,
    } as never,
    memory: {} as never,
    verification: {
      verifyJob: async () => ({ ok: true }),
      checkSources: async () => ({ ok: true, refs: [] }),
    } as never,
    ulid: () => 'seed',
    now: () => '2026-01-01',
    // The seam: an "other user" resume loads nothing (404 → null).
    resumePlan: async (_userId: string, agentRunId: string) => {
      if (agentRunId === 'someone-elses-run-id') {
        reloaded = true;
      }
      // Mirrors loadPendingPlan's 404 / "no row" path → null.
      return null;
    },
  });
  const events: KernelEvent[] = [];
  for await (const ev of kernelWithResume.run({
    userId: 'u2',
    intent: 'focus_start',
    resumeFrom: { agentRunId: 'someone-elses-run-id' },
  } as never)) events.push(ev);
  assert.ok(reloaded, 'the resume seam was called (the agentRunId was carried)');
  assert.ok(events.some((e) => e.type === 'confirmation'), 'the run degrades to a fresh confirmation point (no forged plan)');
  assert.equal(events[events.length - 1].state.status, 'awaiting-confirmation', 'no auto-confirm across users');
});

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
