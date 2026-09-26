// ESM resolve hook: makes the `@aurora/*` workspace packages resolve to
// their TypeScript source under `--experimental-strip-types`
// (zero-dep, cross-platform), and retries failed relative specifiers
// with a `.ts` suffix.
//
// pnpm leaves the dist symlinks for @aurora/* absent in this checkout,
// so we anchor resolution on this package's node_modules/@aurora/<name>
// entry and map it onto the workspace source tree.

import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const here = fileURLToPath(import.meta.url); // .../packages/ascent/test/

export async function resolve(specifier, context, nextResolve) {
  try {
    return await nextResolve(specifier, context);
  } catch (err) {
    if (
      (specifier.startsWith('./') || specifier.startsWith('../')) &&
      context.parentURL
    ) {
      const candidate = `${specifier}.ts`;
      const absUrl = new URL(candidate, context.parentURL);
      let absPath;
      try {
        absPath = fileURLToPath(absUrl);
      } catch {
        absPath = null;
      }
      if (absPath && existsSync(absPath)) {
        return nextResolve(candidate, context);
      }
    }
    // @aurora/* workspace packages: resolve to source entry, no build needed.
    if (
      specifier.startsWith('@aurora/') &&
      context.parentURL &&
      context.parentURL.includes('aurora-2')
    ) {
      const anchor = new URL(`../../node_modules/${specifier}/package.json`, context.parentURL);
      let anchorPath = null;
      try {
        anchorPath = fileURLToPath(anchor);
      } catch {
        anchorPath = null;
      }
      if (anchorPath && existsSync(anchorPath)) {
        return nextResolve(specifier, context);
      }
      // pnpm hoisted node_modules not found for this specifier — fall back to
      // the workspace layout: the sibling package's source is authoritative.
      // On Windows the path must be a file:// URL, not a bare drive-letter path.
      if (specifier === '@aurora/domain') {
        const p = fileURLToPath(new URL('../../domain/src/index.ts', import.meta.url));
        if (existsSync(p)) {
          // p = C:\Users\...\index.ts on Windows — build a file:// URL directly.
          const drive = p.match(/^([A-Za-z]:)(.*)$/);
          const url = drive
            ? `file:///${drive[1].toLowerCase()}${drive[2].replace(/\\/g, '/')}`
            : `file://${p}`;
          return nextResolve(url, context);
        }
      }
    }
    throw err;
  }
}
