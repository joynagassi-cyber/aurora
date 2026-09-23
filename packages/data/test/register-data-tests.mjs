// Registers the Node ESM resolve hook so @aurora/data's extensionless
// source imports resolve under `--experimental-strip-types` (zero-dep,
// cross-platform). The hook file is plain .mjs — loadable via --import
// without type-stripping.

import { register } from 'node:module';

register(
  new URL('./data-resolve-hook.mjs', import.meta.url),
);
