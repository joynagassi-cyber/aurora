import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

/**
 * dyad/beta: A1 (mobile build). Web entry for the Capacitor shell.
 *
 * R1 mitigation (AI_RULES §5 / plan A1): the `@aurora/*` workspace packages
 * resolve to TS SOURCE (each package.json `exports` → `src/index.ts`). Vite
 * follows the pnpm symlinks, so the app bundles the monorepo source directly
 * (esbuild transpiles the `.ts`/`.tsx`) — no tsc pre-build required.
 *
 * `resolve.alias` makes the SUBPATH imports (`@aurora/data/repositories`,
 * `@aurora/ui/renderers`, `@aurora/domain/ascent`, …) resolve to source: the
 * packages' `exports` only declares `.` (`@aurora/domain/ascent` would not
 * resolve via `exports`), so the alias routes every `@aurora/*` to its
 * `src/` and Vite picks the sibling file/directory (`.ts` / `index.ts`).
 */
const here = path.dirname(fileURLToPath(import.meta.url));
const pkgSrc = (name: string) => path.resolve(here, `../../packages/${name}/src`);

export default defineConfig({
  root: here,
  plugins: [react()],
  resolve: {
    alias: {
      '@aurora/mobile': path.resolve(here, 'src'),
      '@aurora/domain': pkgSrc('domain'),
      '@aurora/data': pkgSrc('data'),
      '@aurora/ui': pkgSrc('ui'),
      '@aurora/platform': pkgSrc('platform'),
      '@aurora/agent': pkgSrc('agent'),
      '@aurora/productivity': pkgSrc('productivity'),
      '@aurora/learning': pkgSrc('learning'),
      '@aurora/goal-engine': pkgSrc('goal-engine'),
      '@aurora/progress': pkgSrc('progress'),
      '@aurora/discovery': pkgSrc('discovery'),
      '@aurora/focus': pkgSrc('focus'),
      '@aurora/ascent': pkgSrc('ascent'),
      '@aurora/integrations': pkgSrc('integrations'),
      '@aurora/scientific-engine': pkgSrc('scientific-engine'),
      '@aurora/workflows': pkgSrc('workflows'),
    },
    extensions: ['.ts', '.tsx', '.js', '.jsx', '.json'],
  },
  server: {
    // the dev server must read the workspace packages (symlinked TS source).
    fs: { allow: [path.resolve(here, '../..')] },
  },
  build: {
    // `webDir` in capacitor.config.ts = 'dist' — Capacitor ships this dir.
    outDir: 'dist',
    sourcemap: true,
    target: 'es2020',
  },
});
