/**
 * canvas-client.test.ts — contrat de surface de createCanvasClient
 * (0022, AD-3). Test contractuel node:test : `createCanvasClient`
 * doit exposer exactement `{ get, create, save, listComments,
 * addComment, deleteComment }`.
 *
 * Run: node --experimental-strip-types --no-warnings
 *        --test apps/mobile/test/canvas-client.test.ts
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCanvasClient, type CanvasClient } from '../src/lib/canvas-client.ts';

/** Supabase fake minimal : la couche postgrest (from()) — zéro réseau. */
function fakeSupabase() {
  return {
    from(_table: string) {
      return {
        select: (_cols: string) => ({ eq: (_k: string, _v: unknown) => ({ then: (_ok: (r: unknown) => unknown) => Promise.resolve(_ok({ data: [], error: null })) }) }),
      };
    },
  };
}

test('createCanvasClient expose la surface { get, create, save, listComments, addComment, deleteComment } (0022)', () => {
  const client = createCanvasClient(fakeSupabase() as never, 'test-key') as CanvasClient;
  const expected = ['get', 'create', 'save', 'listComments', 'addComment', 'deleteComment'];
  for (const name of expected) {
    assert.ok(typeof (client as unknown as Record<string, unknown>)[name] === 'function', `surface manquante: ${name}`);
  }
});

test('get renvoie null quand la row est absente (AD-7: état vide honnête)', async () => {
  const client = createCanvasClient(fakeSupabase() as never, 'test-key') as CanvasClient;
  assert.equal(await client.get('nonexistent'), null);
});
