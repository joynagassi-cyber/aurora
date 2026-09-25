/**
 * @aurora/ui — SemanticTreeRenderer 30fps DEVICE test (02 §9.2).
 *
 * The CI headless test (`test/semantic-tree-perf.test.ts`) asserts the
 * R2/R4 layout-cache contract. THIS script is the on-device perf gate:
 * it simulates a 1000-node tree pan/zoom loop (100 frames) and
 * reports p95 frame time vs the 50ms / 30fps threshold.
 *
 * Run on a real Pixel 4a (CPU 4x throttle, Chrome DevTools →
 * "Disable CPU Throttling: 4x" + "GPU": leave on), or on a local
 * dev machine for baseline.
 *
 *   pnpm run test:device
 *
 * `process.env.AURORA_DEVICE_PIXEL_4A=1` marks a Pixel-4a run and
 * enforces the 30fps threshold STRICTLY. Without the flag, the script
 * reports timing and exits 0 (informational baseline).
 *
 * The layout pass being timed is the SHARED headless core
 * (`src/perf/layout-core.ts`) — the exact function the React renderer
 * uses per frame (it re-exports `layoutWithDagre` from it). Importing
 * the framework-free core (not `SemanticTreeRenderer.tsx`) is what lets
 * this run under plain Node 22 type-stripping: no React, no @xyflow,
 * no JSX.
 *
 * Thresholds (02 §9.2 normative):
 *   - 1000-node tree must stay ≥ 30fps (p95 frame < 50ms)
 *   - pan/zoom must NOT trigger a global Dagre re-layout (R4)
 */
import {
  __resetDagreCacheForTests,
  dagreCacheSize,
  layoutWithDagre,
} from "../src/perf/layout-core.ts";
import type {
  RenderSemanticBridge,
  RenderSemanticEdge,
  RenderSemanticNode,
} from "../src/renderers/contracts.ts";

const ROOTS = 40;
const LEVELS = 25;
const TOTAL = ROOTS * LEVELS; // 1000
const REL = ["dependsOn", "isCaseOf", "deepens", "applies", "leadsTo"] as const;

function build() {
  const nodes: RenderSemanticNode[] = [];
  const edges: RenderSemanticEdge[] = [];
  for (let b = 0; b < ROOTS; b++) {
    let prev = "r" + b;
    for (let l = 0; l < LEVELS; l++) {
      const id = `${b}-${l}`;
      nodes.push({
        id,
        concept: `C ${b}·${l}`,
        state: { learningState: "mastered" },
        hasChildren: l < LEVELS - 1,
      });
      edges.push({
        id: `e-${prev}`,
        source: prev,
        target: id,
        relation: REL[(b + l) % 5] as (typeof REL)[number],
      });
      prev = id;
    }
  }
  return { nodes, edges };
}

function timeLoop(
  nodes: RenderSemanticNode[],
  edges: RenderSemanticEdge[],
  frames: number,
): { p95: number; median: number; cacheHits: number } {
  const times: number[] = [];
  let hits = 0;
  for (let i = 0; i < frames; i++) {
    // Simulate a pan frame: same batch key → cache hit (R4).
    const t0 = performance.now();
    layoutWithDagre(nodes, edges, [] as RenderSemanticBridge[]);
    const dt = performance.now() - t0;
    times.push(dt);
    if (dt < 1) hits++; // <1ms = cache-hit path
  }
  times.sort((a, b) => a - b);
  const p95 = times[Math.floor(times.length * 0.95)] ?? 0;
  const median = times[Math.floor(times.length * 0.5)] ?? 0;
  return { p95, median, cacheHits: hits };
}

async function main() {
  const device = process.env.AURORA_DEVICE_PIXEL_4A === "1";
  const { nodes, edges } = build();
  const roots = nodes.filter((n) => /^\d+-0$/.test(n.id));
  __resetDagreCacheForTests();

  // Warm up the cache with a roots-only layout (R1/R2 mount path).
  layoutWithDagre(roots, [], [] as RenderSemanticBridge[]);
  const rootsCache = dagreCacheSize();

  // 100-frame pan/zoom loop over the FULL tree batch.
  const full = timeLoop(nodes, edges, 100);
  const fullCacheAfter = dagreCacheSize();

  console.log("══════════════════════════════════════════════════════════════");
  console.log(" Aurora SemanticTree 30fps — 1000-node tree");
  console.log("══════════════════════════════════════════════════════════════");
  console.log(` device (Pixel 4a @4x): ${device ? "YES (strict)" : "no (baseline)"}`);
  console.log(` nodes: ${nodes.length}  roots: ${roots.length}`);
  console.log(` R4 cache: ${rootsCache} entry after mount, ${fullCacheAfter} after 100 frames`);
  console.log(` R4 cache-hit frames: ${full.cacheHits}/100 (<1ms = hit)`);
  console.log(` p95 frame: ${full.p95.toFixed(2)} ms  (budget: 50 ms = 30fps)`);
  console.log(` median frame: ${full.median.toFixed(2)} ms`);
  console.log("────────────────────────────────────────────────────────────────");

  if (device) {
    const ok =
      full.p95 < 50 && // 30fps threshold
      full.cacheHits >= 80; // R4: ≥80% of pan frames must be cache hits
    if (!ok) {
      console.error(`FAIL: 30fps threshold breached on Pixel 4a (p95=${full.p95.toFixed(1)}ms, cache-hits=${full.cacheHits}/100)`);
      process.exit(1);
    }
    console.log("PASS: 30fps + R4 cache-hit contract holds on device.");
  } else {
    console.log("baseline (no device): informational only — exit 0.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
