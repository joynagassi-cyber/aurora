/**
 * Measure the apps/mobile web bundle for the 300 Ko JS-gz budget
 * (02 §9.1). The declaration-emit pipeline (tsconfig.build.json) was
 * removed on 2026-10-05 (Q6 2026-10-05, @aurora/mobile is an
 * executable app, not a library, zero external consumers) — this
 * module now measures the Vite web bundle (dist/assets/*.js) when
 * present, and falls back to a conservative 0.35 raw-byte factor
 * when it is not:
 *
 *   - raw:  total bytes of `dist` output
 *   - gz:   gzip of the collected text output (the emit's .d.ts is
 *           mostly declarations; the real JS gz comes from the bundler,
 *           this gate bounds the *declared* surface as a proxy).
 *
 * The real bundle gzip (React + dependencies) is measured in the
 * OQ-08 device E2E (wave 7) where the webview reports the transfer
 * size; this module is the CI-friendly static gate.
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import path from 'node:path';

/** Resolve apps/mobile/dist relative to this source file. */
function distDir(): string {
  // src/perf/measure.ts -> apps/mobile/dist (2 levels up from src/perf)
  return path.resolve(process.cwd(), 'dist');
}

/** Walk a dir summing file sizes (skip node_modules / .git). */
function walk(dir: string): number {
  let total = 0;
  for (const name of readdirSync(dir)) {
    if (name === 'node_modules' || name === '.git') continue;
    const p = path.join(dir, name);
    const st = statSync(p);
    total += st.isDirectory() ? walk(p) : st.size;
  }
  return total;
}

/** Total bytes of the apps/mobile declaration emit. 0 if dist missing. */
export function mobileEmitRawBytes(): number {
  const d = distDir();
  try {
    return walk(d);
  } catch {
    return 0;
  }
}

/**
 * Conservative gz estimate: gzip the actual collected text output when
 * it exists; otherwise apply a 0.35 factor to raw bytes (text-heavy
 * .d.ts emit) as the stand-in. This keeps the gate meaningful even
 * when the real bundler gzip is not available.
 */
export function mobileEmitGzBytes(rawBytes: number): number {
  // A5: when the Vite web bundle exists (dist/assets/*.js), its real gzip is
  // the true JS-gz transfer size (300 Ko SLO, PERF_BUDGETS.jsGzBytes) —
  // prefer it over the tsc `.d.ts` proxy below.
  const viteGz = viteBundleGzBytes();
  if (viteGz > 0) return viteGz;
  if (rawBytes === 0) return 0;
  const d = distDir();
  try {
    const content = collectText(d);
    if (content.length > 0) return gzipSync(Buffer.from(content, 'utf8')).length;
  } catch {
    /* fall through to factor */
  }
  return Math.ceil(rawBytes * 0.35);
}

/**
 * A5: the REAL web-bundle gzip — sum the gzipped bytes of `dist/assets/*.js`
 * (the Vite output = the transfer size the 300 Ko SLO bounds). Returns 0
 * when the Vite assets are absent, so the caller falls back to the proxy.
 */
export function viteBundleGzBytes(): number {
  const assetsDir = path.join(distDir(), 'assets');
  let total = 0;
  let found = false;
  try {
    for (const name of readdirSync(assetsDir)) {
      if (!name.endsWith('.js') && !name.endsWith('.mjs')) continue;
      found = true;
      total += gzipSync(readFileSync(path.join(assetsDir, name))).length;
    }
  } catch {
    return 0; // no Vite assets yet — the caller falls back to the proxy.
  }
  return found ? total : 0;
}

function collectText(dir: string): string {
  let out = '';
  try {
    for (const name of readdirSync(dir)) {
      const p = path.join(dir, name);
      const st = statSync(p);
      if (st.isDirectory()) out += collectText(p);
      else if (p.endsWith('.d.ts') || p.endsWith('.ts') || p.endsWith('.json')) {
        out += readFileSync(p, 'utf8');
      }
    }
  } catch {
    /* dir missing */
  }
  return out;
}
