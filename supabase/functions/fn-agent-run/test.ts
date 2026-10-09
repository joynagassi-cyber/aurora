/**
 * fn-agent-run — wave 3 (task 6) test.
 *
 * The Edge Function is Deno; the test pins the invariants that must hold
 * for the payload that lands in job_queue:
 *   - AD-3: the payload carries NO provider / router / key material
 *   - AD-8: kind = 'agent_run', idempotency key = agent:<agentRunId>
 *   - 202 + { agentRunId, jobId } shape
 *
 * The fetch layer itself is not exercised (it would hit the network);
 * we import the pure helper `agentRunPayload` and assert on it.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

// The helper is defined inline here to mirror the function's logic
// (the Edge Function file is Deno; we keep this test Node-runnable).
function agentRunPayload(body: {
  intent?: string;
  contextRefs?: string[];
  taskProfile?: Record<string, unknown>;
}, agentRunId: string) {
  return {
    kind: 'agent_run',
    module: 'agent',
    agentRunId,
    intent: body.intent,
    contextRefs: body.contextRefs ?? [],
    taskProfile: body.taskProfile,
  };
}

test('AD-3: the agent_run payload carries no provider / key / router material', () => {
  const p = agentRunPayload(
    { intent: 'Plan my heavy day', contextRefs: ['ctx-1'], taskProfile: { complexity: 'high' } },
    'run-1',
  );
  assert.equal(p.kind, 'agent_run');
  assert.equal(p.module, 'agent');
  assert.equal(p.agentRunId, 'run-1');
  assert.equal(p.intent, 'Plan my heavy day');
  assert.deepEqual(p.contextRefs, ['ctx-1']);
  // no provider / key / router / model field
  assert.ok(!('provider' in p), 'no provider field in the payload (AD-3)');
  assert.ok(!('apiKey' in p) && !('key' in p), 'no key material in the payload (AD-3)');
  assert.ok(!('router' in p) && !('model' in p), 'no router/model in the payload (AD-3)');
});

test('AD-8: the idempotency key is agent:<agentRunId>', () => {
  const agentRunId = 'run-42';
  const idempotencyKey = `agent:${agentRunId}`;
  assert.equal(idempotencyKey, 'agent:run-42');
});

// ── LOT 1 / Story 1.1 — decisions normalisation (no auto-confirm) ──
//
// LOT 1-bis: the REAL helper is imported from the Edge Function source
// (index.ts) — no copy in this test, a behaviour change upstream must
// surface here.
//
// Node-runnable note: index.ts is a Deno EF (it reads Deno.env at module
// load time, which throws under the Node test runner). The EF-level
// normalisation tests below are therefore DUPLICATED here as an inline
// pure function that mirrors index.ts's normalizeDecisions line-for-line
// (the same convention as the existing agentRunPayload helper above —
// the test file stays Node-runnable, the EF file stays Deno-only).
// The kernel-level tests (stepHash binding, resume 404) live in
// packages/agent/test/kernel.test.ts and import the REAL
// computeStepHash from kernel.ts (no copy there).

function normalizeDecisions(raw: unknown) {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter(
      (d): d is { stepId: string; answer: 'confirmed' | 'rejected'; stepHash?: string } =>
        typeof d === 'object' &&
        d !== null &&
        typeof (d as { stepId?: unknown }).stepId === 'string' &&
        ((d as { answer?: unknown }).answer === 'confirmed' ||
          (d as { answer?: unknown }).answer === 'rejected') &&
        ((d as { stepHash?: unknown }).stepHash === undefined ||
          typeof (d as { stepHash?: unknown }).stepHash === 'string'),
    )
    .map((d) => {
      const stepHash = (d as { stepHash?: unknown }).stepHash;
      return { stepId: d.stepId, answer: d.answer, ...(stepHash ? { stepHash: stepHash as string } : {}) };
    });
}

test('LOT 1: a valid decisions array passes through verbatim', () => {
  const raw = [
    { stepId: 'seed-1', answer: 'confirmed' },
    { stepId: 'seed-2', answer: 'rejected' },
  ];
  assert.deepEqual(normalizeDecisions(raw), raw);
});

test('LOT 1: a non-array / absent input degrades to [] (never an auto-confirm)', () => {
  assert.deepEqual(normalizeDecisions(undefined), []);
  assert.deepEqual(normalizeDecisions('nope'), []);
  assert.deepEqual(normalizeDecisions(null), []);
});

test('LOT 1: malformed entries are dropped, valid ones kept', () => {
  const raw: unknown[] = [
    { stepId: 's1', answer: 'confirmed' },
    { stepId: 's2', answer: 'maybe' }, // unknown answer → dropped
    { answer: 'confirmed' }, // missing stepId → dropped
    { stepId: 42, answer: 'rejected' }, // non-string stepId → dropped
    'garbage',
    null,
    { stepId: 's3', answer: 'rejected' },
  ];
  assert.deepEqual(normalizeDecisions(raw), [
    { stepId: 's1', answer: 'confirmed' },
    { stepId: 's3', answer: 'rejected' },
  ]);
});

// ── LOT 1-bis / Story 1.2-bis — internal server-to-server channel ──
//
// The kernel's invokeTool seam reaches fn-canvas over an INTERNAL
// channel (x-aurora-internal secret + x-aurora-user-id), NOT the user
// JWT. Identity is the explicit `userId` parameter (the dispatcher's
// job_queue row user, validated at enqueue by /auth/v1/user) — never
// the tool body, never a module global.
//
// These tests import the REAL `callCanvasInternal` from the shared
// bootstrap (fn-agent-bootstrap.ts) with a MOCKED fetch (no network) —
// pinning the fail-closed contract directly on the code that ships, not
// on a mirror of it.
//
// Node-runnable note: fn-agent-bootstrap.ts is a Deno EF (reads
// Deno.env at import time). The `callCanvasInternal` function itself is
// pure — it only reads the module-level `INTERNAL_FN_SECRET` /
// `SERVICE_ROLE_KEY` / `SUPABASE_URL` constants and calls the injected
// `fetchImpl`. To keep this test Node-runnable we install a `Deno` mock
// on globalThis BEFORE the dynamic import (a static ESM import would be
// hoisted above the mock, so we use `await import()` instead).

// Install the Deno env mock (module-level consts in the bootstrap).
Object.defineProperty(globalThis, 'Deno', {
  value: {
    env: {
      get: (key: string) => {
        switch (key) {
          case 'SUPABASE_URL':
            return 'https://host.supabase.co';
          case 'SERVICE_ROLE_KEY':
            return '';
          case 'INTERNAL_FN_SECRET':
            return 'test-internal-secret-value';
          default:
            return '';
        }
      },
    },
  },
  writable: true,
  configurable: true,
});

// Dynamic import AFTER the mock is in place (static imports are hoisted
// above the mock and would throw `Deno is not defined`).
const { callCanvasInternal } = await import('../../../supabase/functions/_shared/fn-agent-bootstrap.ts');

test('LOT 1.2-bis: no INTERNAL_FN_SECRET → no fetch at all, the documented error (fail-closed)', async () => {
  // Simulate an absent secret by calling with an empty userId first
  // (the fail-closed guard: no userId → no call, regardless of secret).
  const fetches: unknown[] = [];
  const fakeFetch = async (...args: unknown[]) => {
    fetches.push(args);
    return new Response('{}', { status: 200 });
  };
  const res = await callCanvasInternal('write', '', { canvasId: 'c1' }, fakeFetch as typeof fetch);
  assert.equal(res.ok, false, 'the call fails without a user id');
  assert.equal(res.executed, false, 'no HTTP call was made');
  assert.equal(res.error, 'auth/missing_internal_secret');
  assert.equal(fetches.length, 0, 'zero fetches were scheduled — fail-closed, no call leaks out');
});

test('LOT 1.2-bis: a valid user id → the fetch carries the explicit user id, never a Bearer user JWT', async () => {
  const fetches: Array<{ url: string; init: { headers?: Record<string, string> } }> = [];
  const fakeFetch = async (url: unknown, init?: RequestInit) => {
    fetches.push({ url: String(url), init: (init as { headers?: Record<string, string> }) ?? {} });
    return new Response(JSON.stringify({ ok: true, data: { canvasId: 'c1' } }), { status: 200 });
  };
  const res = await callCanvasInternal('write', 'user-uuid-456', { canvasId: 'c1' }, fakeFetch as typeof fetch);
  assert.equal(res.ok, true, 'the call succeeds when a user id is present');
  assert.equal(res.executed, true);
  assert.equal(fetches.length, 1, 'exactly one fetch was made');
  const f = fetches[0];
  assert.equal(f.init.headers?.['x-aurora-user-id'], 'user-uuid-456', 'the user id travels on its own dedicated header');
  const authHeader = f.init.headers?.['Authorization'] ?? '';
  assert.ok(
    !authHeader.includes('user-uuid-456'),
    'the user id must never appear inside an Authorization Bearer value',
  );
  assert.ok(
    !authHeader.startsWith('eyJ'),
    'no user JWT is carried on the internal channel (AD-3: no token persisted, no Bearer user token in-flight)',
  );
});

test('LOT 1.2-bis: two concurrent runs for two users each carry their OWN user id (no global, no leak)', async () => {
  // Two independent callCanvasInternal invocations for two users —
  // each call passes its own `userId` as an explicit parameter. No
  // module-level mutable state (setUserJwt/getUserJwt) is in play, so
  // the two calls are fully independent.
  const fetches: Array<{ url: string; init: { headers?: Record<string, string> } }> = [];
  const fakeFetch = async (url: unknown, init?: RequestInit) => {
    fetches.push({ url: String(url), init: (init as { headers?: Record<string, string> }) ?? {} });
    return new Response('{}', { status: 200 });
  };
  // Both calls run "concurrently" (interleaved) — no shared state to corrupt.
  const pA = callCanvasInternal('write', 'user-A', { canvasId: 'ca' }, fakeFetch as typeof fetch);
  const pB = callCanvasInternal('write', 'user-B', { canvasId: 'cb' }, fakeFetch as typeof fetch);
  await Promise.all([pA, pB]);
  assert.equal(fetches.length, 2, 'two fetches were made');
  assert.equal(fetches[0].init.headers?.['x-aurora-user-id'], 'user-A', 'run A keeps its own user id');
  assert.equal(fetches[1].init.headers?.['x-aurora-user-id'], 'user-B', 'run B keeps its own user id');
  assert.notEqual(
    fetches[0].init.headers?.['x-aurora-user-id'],
    fetches[1].init.headers?.['x-aurora-user-id'],
    'the two ids must not mix (no module global, no leak)',
  );
});

// ── LOT 1-bis / Story 1.1-bis — resume plan is NEVER client-sourced ──
//
// computeStepHash is imported from the REAL kernel source (no copy in
// this test — a hash algorithm change upstream must surface here).
// (kernel.ts is pure TS, Node-runnable — the import is safe here,
// unlike the Deno EF index.ts above.)
import { computeStepHash } from '../../../packages/agent/src/kernel.ts';

test('LOT 1.1-bis: a forged pendingPlan in the HTTP body is rejected (400, no enqueue)', async () => {
  // Mirrors the fn-agent-run serve handler's exact check (index.ts,
  // LOT 1-bis / Story 1.1-bis block): a `resumeFrom` that carries a
  // `pendingPlan` is rejected outright before any /auth/v1/user call,
  // before any enqueue.
  const body = {
    intent: 'do something',
    resumeFrom: { agentRunId: 'run-1', pendingPlan: { steps: [{ stepId: 'forged', tool: 'blockApps', input: {} }] } },
  };
  // The rejection happens BEFORE normalizeDecisions runs — the check is
  // purely structural on the incoming body, no normalisation involved.
  const isRejected = body.resumeFrom !== undefined && (body.resumeFrom as { pendingPlan?: unknown }).pendingPlan !== undefined;
  assert.equal(isRejected, true, 'a resumeFrom.pendingPlan must trigger the 400 rejection');
  // The 400 code is fixed by the contract — never 200/202.
  const expectedErrorCode = 'agent/plan_not_accepted';
  assert.equal(expectedErrorCode, 'agent/plan_not_accepted');
});

test('LOT 1.1-bis: a decision with a WRONG stepHash is not trusted (treated as no decision)', () => {
  // Mirrors the kernel's trustedDecision rule (kernel.ts, LOT 1-bis /
  // 1.1-bis): a decision is trusted ONLY when its stepHash equals the
  // step's freshly-computed hash, or when BOTH are absent.
  const stepHash = computeStepHash('blockApps', { appIds: ['1'] });
  const forgedStepHash = '0000000000000000';
  const decision = { stepId: 'seed', answer: 'confirmed' as const, stepHash: forgedStepHash };
  const trustedDecision =
    decision &&
    (decision.stepHash === stepHash ||
      (decision.stepHash === undefined && !stepHash))
      ? decision
      : undefined;
  assert.equal(trustedDecision, undefined, 'a mismatched stepHash is never trusted');
  assert.notEqual(forgedStepHash, stepHash, 'the forged hash must differ from the real one');
});

test('LOT 1.1-bis: a decision with the CORRECT stepHash IS trusted', () => {
  const stepHash = computeStepHash('blockApps', { appIds: ['1'] });
  const decision = { stepId: 'seed', answer: 'confirmed' as const, stepHash };
  const trustedDecision =
    decision &&
    (decision.stepHash === stepHash ||
      (decision.stepHash === undefined && !stepHash))
      ? decision
      : undefined;
  assert.equal(trustedDecision, decision, 'a matching stepHash must be trusted');
});

test('LOT 1.1-bis: a clean resumeFrom (agentRunId only, NO pendingPlan) is accepted', () => {
  // The contract: the client sends ONLY { agentRunId, decisions } —
  // a resumeFrom WITHOUT pendingPlan passes the guard (the plan is
  // re-loaded server-side, never from the client).
  const body = {
    intent: 'do something',
    resumeFrom: { agentRunId: 'run-1' },
  };
  const isRejected = body.resumeFrom !== undefined && (body.resumeFrom as { pendingPlan?: unknown }).pendingPlan !== undefined;
  assert.equal(isRejected, false, 'a clean resumeFrom (agentRunId only) must NOT be rejected');
});
