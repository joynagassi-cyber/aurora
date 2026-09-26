/**
 * AgentRunState streaming + command bus tests (wave 3 tasks 5 + 6).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  applyChunk,
  phaseFor,
  terminalChunk,
  heartbeatChunk,
  type AgentRunStateChunk,
} from '../src/run-state.ts';
import {
  CommandBus,
  buildActionEnvelope,
  confirmationCommand,
  navigationCommand,
  uiStateCommand,
  type AppCommand,
} from '../src/run-bus.ts';
import type { AgentRunState } from '../src/types.ts';

function mkState(patch?: Partial<AgentRunState>): AgentRunState {
  const t = '2026-09-01T00:00:00Z';
  return {
    agentRunId: 'run-1',
    stage: 'intent',
    status: 'running',
    startedAt: t,
    updatedAt: t,
    ...patch,
  };
}

function mkChunk(state: AgentRunState, seq = 1, kind: AgentRunStateChunk['kind'] = 'stage'): AgentRunStateChunk {
  return { seq, agentRunId: state.agentRunId, state, kind, at: state.updatedAt };
}

test('applyChunk: a stage chunk replaces the snapshot', () => {
  const next = mkState({ stage: 'plan', status: 'running', plan: { planId: 'p', steps: [], confirmationPoints: [], intentKind: 'x' } as never });
  const got = applyChunk(mkState(), mkChunk(next, 2));
  assert.equal(got.stage, 'plan');
});

test('applyChunk: text chunks accumulate streamed tokens', () => {
  const base = mkState({ text: 'Hello' });
  const c2 = mkChunk(mkState({ text: ' world', stage: 'result' }), 2, 'text');
  const got = applyChunk(base, c2);
  assert.equal(got.text, 'Hello world');
});

test('applyChunk: stale (out-of-order) chunks are dropped, done is not', () => {
  const fresh = mkState({ stage: 'done', status: 'succeeded', updatedAt: '2026-09-01T01:00:00Z' });
  const stale = mkChunk(mkState({ stage: 'plan', updatedAt: '2026-09-01T00:00:00Z' }), 1, 'stage');
  assert.equal(applyChunk(fresh, stale).stage, 'done');
  // done chunks always apply (terminal)
  const doneChunk = mkChunk(mkState({ stage: 'done', status: 'succeeded', updatedAt: '2026-09-01T00:30:00Z' }), 99, 'done');
  assert.equal(applyChunk(fresh, doneChunk).status, 'succeeded');
});

test('phaseFor maps run status to the 5 UX states (AD-13)', () => {
  assert.equal(phaseFor(mkState({ status: 'running' })), 'loading');
  assert.equal(phaseFor(mkState({ status: 'awaiting-confirmation' })), 'loading');
  assert.equal(phaseFor(mkState({ status: 'succeeded', text: 'done!' })), 'success');
  assert.equal(phaseFor(mkState({ status: 'succeeded' })), 'empty');
  assert.equal(phaseFor(mkState({ status: 'failed' })), 'error');
});

test('terminal + heartbeat chunks are well-formed', () => {
  const s = mkState({ stage: 'done', status: 'succeeded' });
  assert.deepEqual(terminalChunk(s, 1, s.updatedAt), {
    seq: 1,
    agentRunId: 'run-1',
    state: s,
    kind: 'done',
    at: s.updatedAt,
  });
  assert.equal(heartbeatChunk(s, 2, s.updatedAt).kind, 'heartbeat');
});

test('CommandBus publishes to subscribers; a bad one does not sink the bus', () => {
  const bus = new CommandBus();
  const seen: AppCommand[] = [];
  bus.subscribe(() => {
    throw new Error('boom');
  });
  bus.subscribe((c) => seen.push(c));
  bus.publish(uiStateCommand({ command: 'open_drawer', payload: { which: 'nav' } }));
  assert.equal(seen.length, 1);
  assert.equal((seen[0] as { kind: string }).kind, 'ui-state');
});

test('buildActionEnvelope: high risk => requiresConfirmation', () => {
  const env = buildActionEnvelope({
    capabilityId: 'focus.start',
    action: 'start a 120-min focus session',
    agentRunId: 'run-1',
    risk: 'high',
  });
  assert.equal(env.requiresConfirmation, true);
  assert.equal(env.status, 'proposed');
  assert.equal(buildActionEnvelope({ capabilityId: 'planning.daily', action: 'plan', agentRunId: 'r', risk: 'low' }).requiresConfirmation, false);
});

test('confirmation + navigation commands are well-formed', () => {
  const c = confirmationCommand('run-1', 'step-2', 'confirmed', () => '2026-09-01T00:00:00Z');
  assert.deepEqual(c, { kind: 'confirm', agentRunId: 'run-1', stepId: 'step-2', answer: 'confirmed', at: '2026-09-01T00:00:00Z' });
  const n = navigationCommand({ target: 'artifacts', params: { id: 'a1' }, mode: 'push' });
  assert.equal(n.kind, 'navigate');
  assert.equal((n as { intent: { target: string } }).intent.target, 'artifacts');
});

test('CommandBus history is bounded', () => {
  const bus = new CommandBus(3);
  for (let i = 0; i < 10; i++) bus.publish(uiStateCommand({ command: `c${i}` }));
  assert.equal(bus.history().length, 3);
});
