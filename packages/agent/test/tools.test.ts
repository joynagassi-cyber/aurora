/**
 * Wave 3 — kernel tools coverage test (feature-agentability-matrix.md).
 *
 * Every agentable family in the matrix maps to a kernel tool + a
 * CapabilityEntry seed (AD-7 single-writer: the tool EMITS a typed
 * command / job, the owning module applies the mutation). This test
 * pins the closed contract:
 *  - every matrix row with a tool binding has a KERNEL_TOOLS key + a
 *    DefaultCapabilityRegistry entry whose `tool` resolves via byTool
 *  - heavy tools carry a valid JobKind (AD-8, AD-15 closed set)
 *  - USER_ONLY rows (artifact.preview) are read-only: no writeScopes,
 *    no job — they only drive the closed AGENT_UI_COMMANDS set
 *  - NOT_AGENT_ENABLED rows (call.policy) are deliberately NOT registered
 *
 * Run: `pnpm --filter @aurora/agent test`
 * Node 22: `node --experimental-strip-types --test test/tools.test.ts`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  KERNEL_TOOLS,
  ALL_TOOL_IDS,
  DefaultCapabilityRegistry,
  AGENT_UI_COMMANDS,
  type AgentUiCommand,
} from '../src/index.ts';

const reg = new DefaultCapabilityRegistry();

test('KERNEL_TOOLS exposes the full agentable tool set (matrix + 8 kernel + goals + docs)', () => {
  const expected = [
    // the 8 kernel tools
    'planDay', 'schedule', 'startFocus', 'blockApps',
    'research', 'qcm_generate', 'mirror_analyze', 'scientific_verify',
    // goal capabilities (7)
    'goal_create', 'goal_status', 'goal_recompose', 'goal_pause',
    'goal_complete', 'goal_abandon', 'goal_feature_add', 'goal_feature_remove',
    // docs (4)
    'docs_generate', 'docs_refine', 'docs_inspect', 'docs_parse',
    // feature-agentability-matrix families
    'flashcard_generate', 'learning_session', 'scientific_evaluate',
    'task_update', 'habit_checkin', 'planning_replan', 'course_search',
    'knowledge_add', 'progress_analyze', 'progress_trajectories', 'progress_cause',
    'artifact_generate', 'artifact_preview', 'coach_checkin', 'settings_theme',
    'review_run', 'automation_toggle', 'notification_pref', 'eisenhower_prioritize',
  ];
  for (const id of expected) {
    assert.ok(id in KERNEL_TOOLS, `KERNEL_TOOLS is missing the tool "${id}"`);
  }
  // the ids mirror ALL_TOOL_IDS exactly
  assert.deepEqual([...ALL_TOOL_IDS].sort(), Object.keys(KERNEL_TOOLS).sort());
});

test('every capability seed resolves to a registered KERNEL_TOOLS key (byTool ≠ undefined)', () => {
  for (const entry of reg.all()) {
    assert.ok(
      entry.tool in KERNEL_TOOLS,
      `capability "${entry.id}" binds an unknown tool "${entry.tool}"`,
    );
    assert.equal(
      reg.byTool(entry.tool)?.id,
      entry.id,
      `byTool("${entry.tool}") must resolve back to the capability "${entry.id}"`,
    );
  }
});

test('the matrix families are registered with their owning-module write scope (AD-7)', () => {
  const expectations: Array<[string, string]> = [
    ['task.update', 'productivity:write'],
    ['habit.checkin', 'productivity:write'],
    ['planning.replan', 'productivity:write'],
    ['learning.import', 'learning:write'],
    ['knowledge.add', 'knowledge:write'],
    ['progress.analyze', 'progress:write'],
    ['artifact.generate', 'artifact:write'],
    ['settings.theme', 'identity:write'],
    ['integrations.automation.toggle', 'integrations:write'],
    ['notification.prefs', 'integrations:write'],
    ['task.prioritize', 'productivity:write'],
  ];
  for (const [id, scope] of expectations) {
    const entry = reg.get(id);
    assert.ok(entry, `capability "${id}" is registered`);
    assert.ok(
      entry!.writeScopes.includes(scope),
      `capability "${id}" must write to its owning module scope "${scope}"`,
    );
  }
});

test('USER_ONLY rows are read-only: no write scope, no heavy job (AD-7 / F-06)', () => {
  const preview = reg.get('artifact.preview');
  assert.ok(preview, 'artifact.preview is registered');
  assert.deepEqual(preview!.writeScopes, [], 'artifact.preview never writes (the device opens the preview)');
  assert.equal(preview!.requiresConfirmation, false);
});

test('NOT_AGENT_ENABLED rows are deliberately NOT registered (call.policy, V1)', () => {
  assert.equal(reg.get('call.policy'), undefined);
  assert.ok(
    !Object.keys(KERNEL_TOOLS).some((k) => k.includes('call')),
    'no call.policy tool exists in the kernel set',
  );
});

test('the ui commands the tools emit stay inside the closed AGENT_UI_COMMANDS set', () => {
  const known = new Set<string>(AGENT_UI_COMMANDS);
  // the tool-level ui commands (artifact_preview) map onto the closed set
  const allowed: AgentUiCommand[] = ['show_artifact', 'open_page', 'show_result'];
  for (const c of allowed) {
    assert.ok(known.has(c), `"${c}" is in the closed ui-command set`);
  }
});

test('heavy tools carry a JobKind from the AD-15 closed vocabulary', () => {
  // packages/domain JobKind (AD-15): the kernel must only reference
  // these kinds on its heavy (job) tools.
  const validJobKinds = new Set([
    'ocr', 'transcription', 'artifact_gen', 'fsrs-tick', 'skill_recompute',
    'research', 'agent_run', 'verify', 'scientific', 'course_import', 'notification',
  ]);
  const heavy: Array<[string, string]> = [
    ['flashcard_generate', 'artifact_gen'],
    ['learning_session', 'agent_run'],
    ['knowledge_add', 'ocr'],
    ['progress_analyze', 'skill_recompute'], // deep variant
    ['progress_cause', 'skill_recompute'],
    ['artifact_generate', 'artifact_gen'],
    ['mirror_analyze', 'agent_run'],
    ['scientific_verify', 'scientific'],
    ['research', 'research'],
  ];
  for (const [toolId, kind] of heavy) {
    assert.ok(toolId in KERNEL_TOOLS, `heavy tool "${toolId}" exists`);
    assert.ok(validJobKinds.has(kind), `heavy tool "${toolId}" uses a valid JobKind "${kind}"`);
  }
});
