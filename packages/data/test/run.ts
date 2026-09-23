// Test runner for @aurora/data (Node 22.20+ native type-stripping, zero-dep).
//
// Runs every invariant test in this directory sequentially; a single
// assertion failure in any test exits non-zero. Under the vitest runner
// (wave-1 tooling) the same test files are picked up by their `*.test.ts`
// suffix — this runner is the CI gate (ci-gate, 03 S7).
//
// Run: pnpm --filter @aurora/data test
//   (equivalently: node --experimental-strip-types --no-warnings
//    --import ./test/register-data-tests.mjs test/run.ts)

import { execFileSync } from 'node:child_process';
import { readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const files = readdirSync(here)
  .filter((f) => f.endsWith('.test.ts'))
  .sort();

// Each test module calls `process.exit` on failure — running them in the
// same process would abort the runner, so spawn one node per file. Both the
// --import hook and the entry are passed as relative paths resolved against
// cwd (packages/data), which is the form that works on Windows + POSIX.
let failed = 0;
for (const f of files) {
  process.stdout.write(`\n=== ${f} ===\n`);
  try {
    execFileSync(
      process.execPath,
      [
        '--experimental-strip-types',
        '--no-warnings',
        '--import',
        `./${join('test', 'register-data-tests.mjs')}`,
        `./${join('test', f)}`,
      ],
      { stdio: 'inherit', cwd: dirname(here) },
    );
  } catch {
    failed++;
  }
}

if (failed > 0) {
  console.error(`\n${failed} test file(s) failed`);
  process.exit(1);
}
console.log(`\nall ${files.length} test files passed`);
