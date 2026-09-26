// Registers the Node ESM resolve hook so @aurora/ascent's extensionless
// source imports resolve under `--experimental-strip-types` (zero-dep,
// cross-platform). Same pattern as packages/data's hook.

import { register } from 'node:module';

register(
  new URL('./ascent-resolve-hook.mjs', import.meta.url),
);
