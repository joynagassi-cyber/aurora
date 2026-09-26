// Registers the Node ESM resolve hook so the Ascent view tests resolve
// extensionless source imports under `--experimental-strip-types`
// (same pattern as packages/ascent's hook).

import { register } from 'node:module';

register(new URL('./ascent-resolve-hook.mjs', import.meta.url));
