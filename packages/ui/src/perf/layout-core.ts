/**
 * @aurora/ui — headless Dagre perf core (02 §9.2).
 *
 * This is the framework-free core of the SemanticTree 30fps test.
 * Consumed by:
 *   - `scripts/semantic-tree-30fps.mts` (on-device / CI Node script)
 *   - `test/semantic-tree-perf.test.ts` (vitest, 02 §9.2 R2/R4)
 *
 * Why a separate module (not SemanticTreeRenderer.tsx)? The renderer
 * file pulls in @xyflow/react + React — for a headless Dagre timing
 * loop we only need the pure layout pass. Keeping the perf core
 * framework-free makes it runnable under plain Node 22 type-stripping
 * (zero deps) AND under vitest (jsdom).
 *
 * The R4 cache (module-level Map) lives here too — the renderer's
 * `layoutWithDagre` re-exports this exact function, so the cache is
 * shared between the React path and the headless path.
 */
// dagre is a CJS module. Under raw Node (type-stripping) its ESM
// namespace only exposes the named `graphlib` at the top level — `layout`
// lives on the default export. Read both defensively so this module runs
// identically under Node type-stripping AND under vitest/esbuild (which
// flattens the namespace so `dagre.layout` is directly reachable).
import dagreModule from "dagre";
import * as dagreNs from "dagre";

const dagre = ((dagreModule as unknown as Record<string, unknown>) ?? dagreNs) as {
  graphlib: { Graph: new () => DagreGraph };
  layout: (g: DagreGraph) => void;
};

interface DagreGraph {
  setGraph(o: Record<string, unknown>): void;
  setDefaultEdgeLabel(fn: () => Record<string, unknown>): void;
  setNode(id: string, attrs: Record<string, unknown>): void;
  setEdge(a: string, b: string, attrs?: Record<string, unknown>): void;
  layout(): void;
  node(id: string): { x: number; y: number } | undefined;
}

/** Node/edge/bridge shapes for the layout pass (subset of the contracts). */
export interface LayoutNode {
  id: string;
  concept: string;
}
export interface LayoutEdge {
  id: string;
  source: string;
  target: string;
  relation: string;
}
export interface LayoutBridge {
  id: string;
  source: string;
  target: string;
  label: string;
}

export interface LaidOutNode {
  id: string;
  x: number;
  y: number;
}

export interface LayoutResult {
  nodes: LaidOutNode[];
  edges: LayoutEdge[];
}

/**
 * R4 — Dagre cache: layout recomputed ONLY when the batch key changes
 * (nodes+edges+bridges id sequences). Pan/zoom frames on a stable
 * batch = cache hit = 0 layout work. Capped at 8 entries (oldest
 * evicted) so a long session never grows unbounded.
 */
let cache = new Map<string, LayoutResult>();

/** Test/teardown hook: reset the module cache between runs. */
export function resetLayoutCache(): void {
  cache = new Map();
}

/** Current cache size (R4 cap assertions). */
export function layoutCacheSize(): number {
  return cache.size;
}

/**
 * Compute Dagre layout for a batch of nodes/edges/bridges.
 * `positions` = LaidOutNode[] keyed by node id (id → {x,y}).
 *
 * Returns the laid-out batch. The cache is keyed on the id sequences —
 * identical batch = 0 recomputes (R4). A new batch = 1 recompute.
 */
export function layoutBatch(
  nodes: LayoutNode[],
  edges: LayoutEdge[],
  bridges: LayoutBridge[],
): LayoutResult {
  const key = [
    nodes.map((n) => n.id).join(","),
    edges.map((e) => e.id).join(","),
    bridges.map((b) => b.id).join(","),
  ].join("|");
  const hit = cache.get(key);
  if (hit) return hit;

  const g = new dagre.graphlib.Graph();
  g.setGraph({
    rankdir: "LR",
    nodesep: 24,
    ranksep: 48,
    marginx: 8,
    marginy: 8,
  });
  g.setDefaultEdgeLabel(() => ({}));
  for (const n of nodes) g.setNode(n.id, { label: n.concept });
  for (const e of edges) g.setEdge(e.source, e.target, { label: e.relation });
  for (const b of bridges) g.setEdge(b.source, b.target, { label: b.label });
  dagre.layout(g);

  const positions: LaidOutNode[] = nodes.map((n) => {
    const p = g.node(n.id) ?? { x: 0, y: 0 };
    return { id: n.id, x: p.x, y: p.y };
  });

  const out: LayoutResult = { nodes: positions, edges };
  cache.set(key, out);
  if (cache.size > 8) {
    const oldest = cache.keys().next().value;
    if (oldest !== undefined) cache.delete(oldest);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Compatibility re-exports — the pre-existing renderer/test API surface.
// `layoutWithDagre`/`__resetDagreCacheForTests`/`dagreCacheSize` stay
// importable from `src/renderers/SemanticTreeRenderer` (which re-exports
// them from this module), and the perf tests keep working unchanged.
// ---------------------------------------------------------------------------
export {
  layoutBatch as layoutWithDagre,
  resetLayoutCache as __resetDagreCacheForTests,
  layoutCacheSize as dagreCacheSize,
};
