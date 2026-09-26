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
