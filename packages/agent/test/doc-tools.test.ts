/**
 * Document tools tests (docs/agent/document-tools.md) — the 4 docs.*
 * capabilities. Two strict directions (S4): TEXT→DOC (docs.generate,
 * docs.refine) and DOC→TEXT (docs.inspect, docs.parse). Never mixed:
 * a generator never parses, a parser never generates. All heavy steps
 * = persisted artifact_gen jobs (AD-8); the discriminator is
 * payload.docTool (job-kind vocabulary unchanged, domain SSoT).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { DefaultCapabilityRegistry, KERNEL_TOOLS, ALL_TOOL_IDS } from '../src/index.ts';
import { docsGenerate, docsInspect, docsParse, docsRefine } from '../src/tools.ts';

const registry = new DefaultCapabilityRegistry();

const DOC_IDS = ['docs.generate', 'docs.refine', 'docs.inspect', 'docs.parse'];

test('the 4 document capabilities are registered in the kernel registry', () => {
  for (const id of DOC_IDS) {
    const entry = registry.get(id);
    assert.ok(entry, `capability missing: ${id}`);
    // All 4 are additive, non-destructive: outputs are NEW artifact rows
    // (blobs immutable, artifacts §24 supersedes) — never user data.
    assert.equal(entry.destructive, false, `${id} must be non-destructive`);
    // Heavy steps = server jobs (AD-8) — never on-device (AD-3/F-09).
    assert.equal(entry.offlineClass, 'online-required', `${id} is online-only (AD-8)`);
  }
});

test('direction split: all 4 produce NEW artifact rows; source is never written (document-tools S4)', () => {
  // Every doc tool's output is a new artifact row (generated doc, revision,
  // or parsed representation) — applied by the Artifact module (AD-7).
  for (const id of DOC_IDS) {
    assert.deepEqual(
      registry.get(id)?.writeScopes,
      ['artifact:write'],
      `${id} writes artifact rows only`,
    );
  }
  // Read-only direction: inspect + parse additionally read the source
  // artifact but never write into it (blobs immutable, artifacts §18/§24).
  assert.ok(registry.get('docs.inspect')?.readScopes.includes('artifact:read'));
  assert.ok(registry.get('docs.parse')?.readScopes.includes('artifact:read'));
});

test('the 4 doc tools are exposed in the kernel tool set (additive, ids stable)', () => {
  for (const id of ['docs_generate', 'docs_refine', 'docs_inspect', 'docs_parse']) {
    assert.ok(KERNEL_TOOLS[id as keyof typeof KERNEL_TOOLS], `tool missing: ${id}`);
  }
  assert.ok(ALL_TOOL_IDS.length >= 19, `8 canonical + 7 goal + 4 doc = 19, got ${ALL_TOOL_IDS.length}`);
});

test('every doc tool returns a typed artifact_gen job descriptor (AD-8, F-08)', async () => {
  const type = (t: unknown) => t as { execute?: (i: unknown) => Promise<unknown> };
  const g = (await type(docsGenerate).execute!({ markdown: '# RPT', outputFormat: 'docx' })) as {
    ok: boolean; jobKind: string; payload: { docTool: string }; idempotencyKey: string;
  };
  assert.equal(g.jobKind, 'artifact_gen');
  assert.equal(g.payload.docTool, 'pandoc');
  assert.ok(g.idempotencyKey.startsWith('doc:pandoc:'));

  const r = (await type(docsRefine).execute!({ artifactId: 'a1', operations: [{ op: 'fill_table' }] })) as {
    ok: boolean; jobKind: string; payload: { docTool: string };
  };
  assert.equal(r.jobKind, 'artifact_gen');
  assert.equal(r.payload.docTool, 'python-docx');

  const i = (await type(docsInspect).execute!({ artifactId: 'a1' })) as {
    ok: boolean; jobKind: string; payload: { docTool: string };
  };
  assert.equal(i.jobKind, 'artifact_gen');
  assert.equal(i.payload.docTool, 'mammoth');

  const p = (await type(docsParse).execute!({ artifactId: 'a1', format: 'json' })) as {
    ok: boolean; jobKind: string; payload: { docTool: string };
  };
  assert.equal(p.jobKind, 'artifact_gen');
  assert.equal(p.payload.docTool, 'docling');
});
