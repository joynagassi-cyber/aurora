/**
 * canvas-tools.test.ts — contrat de surface des outils canvas (0022, AD-7).
 *
 * Vérifie que `KERNEL_TOOLS` contient `canvas_read` / `canvas_write` /
 * `canvas_comment` et que la surface de leur inputSchema (noms de
 * champs) est correcte. Import direct depuis `packages/agent/src/tools.ts`
 * (pattern existant dans packages/agent/test ; le test vit dans
 * apps/mobile/test/ car c'est là que vit le test canvas-client sibling).
 *
 * Run: node --experimental-strip-types --no-warnings
 *        --test apps/mobile/test/canvas-tools.test.ts
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { KERNEL_TOOLS } from '../../../packages/agent/src/tools.ts';

/**
 * La surface d'inputSchema d'un outil Vercel AI SDK `tool()`:
 * `inputSchema` est un zod object — on en extrait les noms de champs
 * via `.shape` (zod 3) sans exécuter de validation.
 */
function inputFields(tool: unknown): string[] {
  const t = tool as { inputSchema?: { shape?: Record<string, unknown> } };
  const shape = t.inputSchema?.shape;
  if (!shape) return [];
  return Object.keys(shape);
}

test('KERNEL_TOOLS contient les 3 outils canvas (0022)', () => {
  for (const id of ['canvas_read', 'canvas_write', 'canvas_comment'] as const) {
    assert.ok(id in KERNEL_TOOLS, `KERNEL_TOOLS manquant: ${id}`);
  }
});

test('canvas_read: inputSchema = { canvasId, includeComments, userId? } (read-only, pas de job)', () => {
  assert.deepEqual(inputFields(KERNEL_TOOLS.canvas_read).sort(), [
    'canvasId',
    'includeComments',
    'userId',
  ]);
});

test('canvas_write: inputSchema = { canvasId, blockId?, markdown, userId? } (AD-7, overwrite = risk du planStep)', () => {
  assert.deepEqual(inputFields(KERNEL_TOOLS.canvas_write).sort(), [
    'blockId',
    'canvasId',
    'markdown',
    'userId',
  ]);
});

test('canvas_comment: inputSchema = { canvasId, replyToCommentId?, body, userId? } (0022 anchors)', () => {
  assert.deepEqual(inputFields(KERNEL_TOOLS.canvas_comment).sort(), [
    'body',
    'canvasId',
    'replyToCommentId',
    'userId',
  ]);
});
