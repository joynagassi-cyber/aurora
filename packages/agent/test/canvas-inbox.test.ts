/**
 * G10 + G11 (feature-agentique plan 2026-10-06).
 *
 * G10 — canvas_create + canvas_lock : les 2 tools canvas manquantes
 * (le 0022 a déjà seedé canvas_read / canvas_write / canvas_comment ;
 * il manque la création de session + le verrou réversible). Thin
 * emitters AD-7 : le module Canvas (endpoint fn-canvas ou le client
 * device canvas-client.ts) applique la mutation sur `canvas_sessions`
 * — le kernel n'y touche jamais directement. Le verrou est réversible
 * → non-destructif, sans confirmation.
 *
 * G11 — inbox_capture + inbox_triage + ascent_read : les surfaces
 * manquantes de la productivité (le module inbox.ts L29 captureTask /
 * L42 triageTask est PRÊT ; les 3 kinds de triage = project /
 * tomorrow / discard, la forme exacte du test file). ascent_read est
 * READ-ONLY (pas de write scope, ADR §5) : le module Ascent lit sa
 * propre table, le kernel ne fait que porter la commande typed.
 *
 * AD-7 : execute ne write JAMAIS une table — il émet seulement
 * { ok, command, payload } ; le module du domaine applique.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { KERNEL_TOOLS, DefaultCapabilityRegistry } from '../src/index.ts';
import {
  ascentRead,
  canvasCreate,
  canvasLock,
  inboxCapture,
  inboxTriage,
} from '../src/tools.ts';

const reg = new DefaultCapabilityRegistry();

// ---------------------------------------------------------------------------
// G10 — canvas_create + canvas_lock
// ---------------------------------------------------------------------------

test('G10: canvas_create + canvas_lock sont dans KERNEL_TOOLS', () => {
  assert.ok('canvas_create' in KERNEL_TOOLS, 'canvas_create en KERNEL_TOOLS');
  assert.ok('canvas_lock' in KERNEL_TOOLS, 'canvas_lock en KERNEL_TOOLS');
});

test('G10: les 2 registry canvas.create / canvas.lock existent, write canvas:write, non-destructifs', () => {
  for (const id of ['canvas.create', 'canvas.lock']) {
    const e = reg.get(id);
    assert.ok(e, `registry ${id}`);
    assert.equal(e?.writeScopes[0], 'canvas:write', `writeScope de ${id}`);
    assert.equal(e?.destructive, false, `${id} non-destructif`);
    assert.equal(e?.requiresConfirmation, false, `${id} sans confirmation`);
  }
});

test('G10: canvas_create émet canvas.create', async () => {
  const r = (await canvasCreate.execute(
    { title: 'Ma session', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { title: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'canvas.create');
  assert.equal(r.payload.title, 'Ma session');
});

test('G10: canvas_lock émet canvas.lock', async () => {
  const l = (await canvasLock.execute(
    { canvasId: 'c1', locked: true, userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { canvasId: string; locked: boolean } };
  assert.equal(l.ok, true);
  assert.equal(l.command, 'canvas.lock');
  assert.equal(l.payload.canvasId, 'c1');
  assert.equal(l.payload.locked, true);
});

// ---------------------------------------------------------------------------
// G11 — inbox_capture + inbox_triage + ascent_read
// ---------------------------------------------------------------------------

test('G11: inbox_capture + inbox_triage + ascent_read sont dans KERNEL_TOOLS', () => {
  for (const id of ['inbox_capture', 'inbox_triage', 'ascent_read'] as const) {
    assert.ok(id in KERNEL_TOOLS, `${id} en KERNEL_TOOLS`);
  }
});

test('G11: les 3 registry inbox.capture / inbox.triage / ascent.read existent, flags par entrée', () => {
  const cap = reg.get('inbox.capture');
  assert.ok(cap, 'registry inbox.capture');
  assert.equal(cap?.writeScopes[0], 'productivity:write');
  assert.equal(cap?.destructive, false);
  assert.equal(cap?.requiresConfirmation, false);

  const tri = reg.get('inbox.triage');
  assert.ok(tri, 'registry inbox.triage');
  assert.equal(tri?.writeScopes[0], 'productivity:write');
  assert.equal(tri?.destructive, false);
  assert.equal(tri?.requiresConfirmation, false);

  // ascent_read est READ-ONLY (ADR §5) : pas de write scope, sans confirmation.
  const read = reg.get('ascent.read');
  assert.ok(read, 'registry ascent.read');
  assert.equal(read?.writeScopes.length, 0, 'ascent.read a 0 write scope (READ-ONLY)');
  assert.equal(read?.destructive, false);
  assert.equal(read?.requiresConfirmation, false);
});

test('G11: inbox_capture émet productivity.inbox_capture', async () => {
  const r = (await inboxCapture.execute(
    { text: 'se souvenir de X', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { text: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'productivity.inbox_capture');
  assert.equal(r.payload.text, 'se souvenir de X');
});

test('G11: inbox_triage émet productivity.inbox_triage (3 kinds de résolution)', async () => {
  const cases = [
    { taskId: 't1', resolution: { kind: 'project', projectId: 'p1', dueAt: '2026-10-07T00:00:00Z' } },
    { taskId: 't2', resolution: { kind: 'tomorrow', dueAt: '2026-10-07T00:00:00Z' } },
    { taskId: 't3', resolution: { kind: 'discard' } },
  ];
  for (const input of cases) {
    const r = (await inboxTriage.execute(
      input as Parameters<typeof inboxTriage.execute>[0],
      {} as never,
      undefined as never,
    )) as { ok: boolean; command: string };
    assert.equal(r.ok, true, `kind=${(input.resolution as { kind: string }).kind}`);
    assert.equal(r.command, 'productivity.inbox_triage', `kind=${(input.resolution as { kind: string }).kind}`);
  }
});

test('G11: ascent_read émet ascent.read (READ-ONLY)', async () => {
  const r = (await ascentRead.execute(
    { ascentId: 'a1', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { ascentId: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'ascent.read');
  assert.equal(r.payload.ascentId, 'a1');
});

// ---------------------------------------------------------------------------
// Invariant byTool : chaque tool G10/G11 se résout dans le registry
// (le contract ToolResolver pin byTool() contre le nom exporté).
// ---------------------------------------------------------------------------

test('G10+G11: byTool résout chaque tool vers son entrée registry', () => {
  const specs: Array<[string, string]> = [
    ['canvas.create', 'canvas_create'],
    ['canvas.lock', 'canvas_lock'],
    ['inbox.capture', 'inbox_capture'],
    ['inbox.triage', 'inbox_triage'],
    ['ascent.read', 'ascent_read'],
  ];
  for (const [capId, toolId] of specs) {
    assert.equal(
      reg.byTool(toolId)?.id,
      capId,
      `byTool("${toolId}") doit résoudre vers "${capId}"`,
    );
  }
});
