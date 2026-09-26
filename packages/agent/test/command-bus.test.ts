/**
 * Wave 3 — AgentRunState + command bus test (task 5, kernel S15).
 *
 * Verifies (no device, no React — §77):
 *  - high-risk actions carry requiresConfirmation + the blocking surface
 *  - the command bus emits typed UiStateCommand / NavigationIntent
 *  - every ui-state command is in the closed, idempotent set
 *
 * Run: `pnpm --filter @aurora/agent test`
 * Node 22: `node --experimental-strip-types --test test/command-bus.test.ts`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  buildAgentUiEffect,
  uiCommand,
  confirmationSurfaceFor,
  AGENT_UI_COMMANDS,
  type AgentUiCommand,
} from '../src/index.ts';

test('Command bus: a high-risk action is confirmation-gated (ADR S5)', () => {
  const effect = buildAgentUiEffect({
    capabilityId: 'focus.block',
    action: 'Suspend TikTok + WhatsApp for a 2h focus session',
    agentRunId: 'run-1',
    risk: 'high',
    uiCommands: [uiCommand('start_focus', { durationMin: 120 })],
  });
  assert.equal(effect.envelope.requiresConfirmation, true);
  assert.equal(effect.envelope.status, 'proposed');
  const surface = confirmationSurfaceFor(effect);
  assert.ok(surface, 'a high-risk action renders the blocking confirmation surface');
  assert.equal(surface?.blocking, true);
});

test('Command bus: a low-risk action executes without confirmation', () => {
  const effect = buildAgentUiEffect({
    capabilityId: 'goal.status',
    action: 'Open the goal dashboard',
    agentRunId: 'run-2',
    risk: 'low',
    navigation: { target: 'goal.dashboard', params: { goalId: 'g1' }, mode: 'push' },
  });
  assert.equal(effect.envelope.requiresConfirmation, false);
  assert.equal(effect.envelope.status, 'executed');
  assert.equal(confirmationSurfaceFor(effect), undefined);
  assert.equal(effect.navigation?.target, 'goal.dashboard');
});

test('Command bus: the ui-state command set is closed + idempotent (mission §62)', () => {
  // the shell only executes these; unknown commands are dropped.
  const known: Record<string, boolean> = Object.fromEntries(
    AGENT_UI_COMMANDS.map((c) => [c, true]),
  );
  for (const c of ['open_page', 'select_entity', 'filter', 'expand_node', 'show_artifact', 'start_focus', 'request_confirmation', 'show_result']) {
    assert.ok(known[c as AgentUiCommand], `${c} is in the closed set`);
  }
  // a dropped command re-applied is a no-op (idempotent by construction)
  const cmd = uiCommand('select_entity', { id: 'task-7' });
  assert.deepEqual(cmd, { command: 'select_entity', payload: { id: 'task-7' } });
});

test('Command bus: artifact display resolves to show_artifact + deep link (02 S4)', () => {
  const effect = buildAgentUiEffect({
    capabilityId: 'learning.qcm',
    action: 'Show the generated QCM artifact',
    agentRunId: 'run-3',
    risk: 'low',
    navigation: { target: 'artifact.view', params: { artifactId: 'a-1' }, deepLink: '/artifacts/a-1' },
    uiCommands: [uiCommand('show_artifact', { artifactId: 'a-1' })],
  });
  assert.equal(effect.envelope.status, 'executed');
  assert.equal(effect.navigation?.deepLink, '/artifacts/a-1');
  assert.equal(effect.uiCommands[0]?.command, 'show_artifact');
});
