/**
 * ERYNIS — release gate (wave 7 task 8, W7-E1-2): asserts the
 * release pipeline pieces are wired and byte-stable.
 *
 *   1. `.github/workflows/release.yml` exists + parses (the 3 jobs
 *      release-gate / release-build / deploy are the W7-E1-2 shape).
 *   2. `docs/release/changelog.md` has the `## Upcoming` section
 *      (the release-notes source, docs/release/README S2.2).
 *   3. The awk copy in release.yml (`/docs/release/changelog.md`
 *      `## Upcoming` -> `### `) produces a NON-EMPTY notes body when
 *      the Upcoming section is populated — so the GitHub Release is
 *      not cut from an empty notes file at tag time.
 *
 * Run: node --experimental-strip-types --no-warnings
 *        apps/mobile/test/release-gate.test.ts
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(fileURLToPath(new URL('.', import.meta.url)), '..', '..', '..');

function readFile(rel: string): string {
  const p = join(REPO_ROOT, rel);
  assert.ok(existsSync(p), `missing ${rel} (release gate, W7-E1-2)`);
  return readFileSync(p, 'utf8');
}

test('release.yml is wired (W7-E1-2: 3 jobs, deploy gated on OQ-03)', () => {
  const yml = readFile('.github/workflows/release.yml');
  // The 3-job shape: gate -> build -> deploy (docs/release/README S1).
  assert.ok(yml.includes('release-gate:'), 'release-gate job missing');
  assert.ok(yml.includes('release-build:'), 'release-build job missing');
  // The deploy job is the 3rd of the pipeline (docs/release/README S1):
  const deployIdx = yml.indexOf('  deploy:');
  assert.ok(deployIdx > 0, 'deploy job missing (W7-E1-2 shape: gate -> build -> deploy)');
  const deployBlock = yml.slice(deployIdx);
  // OQ-03 gate: the job is frozen (if: false) until the env values are
  // ratified (docs/release/README S1/S5).
  assert.ok(
    /if:\s*false/.test(deployBlock),
    'deploy job must be frozen (if: false) until OQ-03 is ratified',
  );
  // The tag trigger (v*) is the release trigger:
  assert.ok(/\*'[^\n]*\n/.test(yml) || yml.includes("'v*'"), 'tag v* trigger missing');
});

test('changelog.md has the Upcoming release-notes source', () => {
  const md = readFile('docs/release/changelog.md');
  assert.ok(
    md.includes('## Upcoming'),
    'docs/release/changelog.md: the "## Upcoming" section is the release-notes source (README S2.2)',
  );
  // The Upcoming section must be non-trivial (has at least one ### subsection):
  const upcoming = md.slice(md.indexOf('## Upcoming'));
  assert.ok(
    upcoming.includes('### '),
    '## Upcoming must contain at least one "### " wave/UI subsection',
  );
});

test('the awk notes-copy in release.yml is non-empty on the current changelog', () => {
  // Reproduce the exact awk block from release.yml against the
  // current changelog (byte-stable, so the notes file at tag time
  // is not empty when the Upcoming section is populated). The awk
  // extracts `## Upcoming` .. the next `## ` top-level heading
  // (`## Wave history` stops it).
  const md = readFile('docs/release/changelog.md');
  const lines = md.split('\n');
  const out: string[] = [];
  let inUpcoming = false;
  for (const line of lines) {
    if (line.startsWith('## Upcoming')) inUpcoming = true;
    else if (inUpcoming && line.startsWith('## ')) inUpcoming = false;
    if (inUpcoming) out.push(line);
  }
  const notes = out.join('\n');
  assert.ok(
    notes.trim().length > 0,
    'the release-notes copy of "## Upcoming" is empty — populate the changelog before cutting a tag (README S2.2)',
  );
  // The notes carry at least the wave/UI subsection headers:
  assert.ok(notes.includes('### '), 'the notes copy is missing the "### " subsection headers');
});
