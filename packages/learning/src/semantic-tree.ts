/**
 * Learning module — semantic tree: invariants + lazy Dagre layout
 * helpers (wave 2, SAPPHO).
 *
 * 01 S4.3 / docs/knowledge/overview.md: the Semantic Tree truth lives in
 * Postgres + pgvector (server). This file is PURE contract + layout
 * math for the lazy Dagre renderer (packages/ui / React Flow, AD-10):
 * the layout is presentation-only and the tree invariants must hold
 * whether or not the layout is computed. No vendor imports (AD-1);
 * the layout function mirrors the Dagre API shape so the ui-layer
 * adapter can delegate 1:1.
 */
import type {
  SemanticEdge,
  SemanticNode,
} from '@aurora/domain';

export interface TreeLayoutNode {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface TreeLayout {
  nodes: TreeLayoutNode[];
  edges: Array<{ from: string; to: string }>;
}

/** Frozen node dimensions for the tree renderer (02 S5.1 perf rule). */
export const TREE_NODE_W = 220;
export const TREE_NODE_H = 64;

/**
 * Tree invariants (docs/knowledge/overview.md ADR §14, "readable
 * hierarchy, never a chaotic graph" + 03 S4.2 mirror rule: no
 * embedding column locally). Pure checks — run on the server before a
 * version snapshot, and on the device mirror on load (fast path).
 */
export function checkTreeInvariants(
  nodes: SemanticNode[],
  edges: SemanticEdge[],
): { ok: boolean; violations: string[] } {
  const violations: string[] = [];
  const byId = new Map(nodes.map((n) => [n.id, n]));

  // 1. exactly one root (AD-14 "readable hierarchy": a single entry point;
  //    roots are nodes flagged isRoot OR parentless — children carry a
  //    parentId, so they never double-count as roots)
  const roots = nodes.filter((n) => n.isRoot === true || (n.parentId === undefined && !nodes.some((m) => m.parentId === n.id)));
  if (roots.length !== 1) {
    violations.push(`root-count=${roots.length} (expected 1)`);
  }

  // 2. every node reachable from the root
  if (roots.length === 1) {
    const reachable = new Set<string>([roots[0]!.id]);
    const children = new Map<string, string[]>();
    for (const e of edges) {
      const list = children.get(e.fromNodeId);
      if (list === undefined) children.set(e.fromNodeId, [e.toNodeId]);
      else list.push(e.toNodeId);
    }
    // follow parent links too (hierarchy is parent-child + depends_on)
    for (const n of nodes) {
      if (n.parentId !== undefined) {
        const list = children.get(n.parentId);
        if (list === undefined) children.set(n.parentId, [n.id]);
        else list.push(n.id);
      }
    }
    let queue = [...reachable];
    while (queue.length > 0) {
      const id = queue.pop()!;
      for (const c of children.get(id) ?? []) {
        if (!reachable.has(c)) {
          reachable.add(c);
          queue.push(c);
        }
      }
    }
    for (const n of nodes) {
      if (!reachable.has(n.id)) violations.push(`unreachable node ${n.id}`);
    }
  }

  // 3. no cycles: follow only forward (parent → child) arcs. Parent links
  //    are traversed parent→child; combining the child→parent direction with
  //    a same-pair edge would fabricate a 2-cycle, so we normalise.
  const graph = new Map<string, string[]>();
  for (const e of edges) {
    const list = graph.get(e.fromNodeId);
    if (list === undefined) graph.set(e.fromNodeId, [e.toNodeId]);
    else list.push(e.toNodeId);
  }
  for (const n of nodes) {
    if (n.parentId !== undefined) {
      const list = graph.get(n.parentId);
      if (list === undefined) graph.set(n.parentId, [n.id]);
      else list.push(n.id);
    }
  }
  const WHITE = 0;
  const GRAY = 1;
  const BLACK = 2;
  const color = new Map<string, number>();
  let cycle = false;
  const dfs = (id: string): void => {
    if (cycle) return;
    color.set(id, GRAY);
    for (const next of graph.get(id) ?? []) {
      const c = color.get(next);
      if (c === GRAY) {
        cycle = true;
        return;
      }
      if (c !== BLACK) dfs(next);
    }
    color.set(id, BLACK);
  };
  for (const n of nodes) {
    if ((color.get(n.id) ?? WHITE) === WHITE) dfs(n.id);
    if (cycle) break;
  }
  if (cycle) violations.push('cycle detected');

  // 4. edges reference existing nodes
  for (const e of edges) {
    if (!byId.has(e.fromNodeId)) violations.push(`edge source missing ${e.fromNodeId}`);
    if (!byId.has(e.toNodeId)) violations.push(`edge target missing ${e.toNodeId}`);
  }

  return { ok: violations.length === 0, violations };
}

/**
 * Level-by-level lazy expansion (02 S9.2: root + level-1 first,
 * deeper branches lazy). Returns the node ids visible after expanding
 * `depth` levels of the parent tree from the root.
 */
export function lazyExpand(
  nodes: SemanticNode[],
  edges: SemanticEdge[],
  depth: number,
): string[] {
  if (depth < 0) return [];
  const root = findRoot(nodes);
  if (root === undefined) return [];
  const byId = new Map(nodes.map((n) => [n.id, n]));
  const children = new Map<string, string[]>();
  for (const n of nodes) {
    if (n.parentId !== undefined) {
      const list = children.get(n.parentId);
      if (list === undefined) children.set(n.parentId, [n.id]);
      else list.push(n.id);
    }
  }
  for (const e of edges) {
    if (e.relation === 'depends-on') {
      const list = children.get(e.fromNodeId);
      if (list === undefined) children.set(e.fromNodeId, [e.toNodeId]);
      else list.push(e.toNodeId);
    }
  }
  const visible = new Set<string>();
  let frontier = [root.id];
  visible.add(root.id);
  for (let level = 0; level < depth; level++) {
    const next: string[] = [];
    for (const id of frontier) {
      for (const c of children.get(id) ?? []) {
        if (!visible.has(c) && byId.has(c)) {
          visible.add(c);
          next.push(c);
        }
      }
    }
    frontier = next;
  }
  return [...visible];
}

/**
 * Deterministic layered (Dagre-style) layout: each node's depth =
 * longest path from the root (ties broken by label order — so the
 * layout is a pure function of the tree, reproducible across the
 * 1000-node perf test, 02 S9.2). Nodes are placed left-to-right
 * within a depth row; edges inherit from node positions.
 */
export function treeLayout(
  nodes: SemanticNode[],
  edges: SemanticEdge[],
  opts?: { nodeWidth?: number; nodeHeight?: number; rankGap?: number; nodeGap?: number },
): TreeLayout {
  const w = opts?.nodeWidth ?? TREE_NODE_W;
  const h = opts?.nodeHeight ?? TREE_NODE_H;
  const rankGap = opts?.rankGap ?? 80;
  const nodeGap = opts?.nodeGap ?? 24;
  const root = findRoot(nodes);
  const byId = new Map(nodes.map((n) => [n.id, n]));
  const parents = new Map<string, string>();
  for (const n of nodes) if (n.parentId !== undefined) parents.set(n.id, n.parentId);
  if (root === undefined) {
    return {
      nodes: nodes.map((n, i) => ({ id: n.id, x: i * (w + nodeGap), y: 0, width: w, height: h })),
      edges: edges.map((e) => ({ from: e.fromNodeId, to: e.toNodeId })),
    };
  }
  // depth = longest path from root via parent links (deterministic, no cycles
  // by invariant #3; cap iterations to be safe on malformed input).
  const depth = new Map<string, number>([[root.id, 0]]);
  const ids = [...byId.keys()].sort((a, b) =>
    (byId.get(a)?.label ?? '').localeCompare(byId.get(b)?.label ?? ''),
  );
  for (let pass = 0; pass < Math.max(1, nodes.length) + 1; pass++) {
    let changed = false;
    for (const id of ids) {
      const p = parents.get(id);
      if (p === undefined) continue;
      const pd = depth.get(p);
      if (pd === undefined) continue;
      const d = pd + 1;
      const cur = depth.get(id) ?? -1;
      if (d > cur) {
        depth.set(id, d);
        changed = true;
      }
    }
    if (!changed) break;
  }
  const rows = new Map<number, string[]>();
  for (const id of ids) {
    const d = depth.get(id) ?? 0;
    const list = rows.get(d);
    if (list === undefined) rows.set(d, [id]);
    else list.push(id);
  }
  const placed = new Map<string, TreeLayoutNode>();
  let maxX = -Infinity;
  let minX = Infinity;
  for (const [d, list] of [...rows.entries()].sort((a, b) => a[0] - b[0])) {
    let x = 0;
    for (const id of list) {
      placed.set(id, { id, x, y: d * (h + rankGap), width: w, height: h });
      x += w + nodeGap;
    }
    maxX = Math.max(maxX, x);
    minX = Math.min(minX, 0);
  }
  // re-center rows on their centroid parent where a parent exists
  for (const [id, d] of [...placed.entries()]) {
    const p = parents.get(id);
    void d;
    if (p !== undefined) {
      const pn = placed.get(p);
      if (pn !== undefined) {
        const node = placed.get(id)!;
        const targetX = pn.x + (node.x - pn.x) * 0.5 + (node.x > pn.x ? nodeGap : -nodeGap);
        node.x = Math.min(Math.max(targetX, minX), maxX);
      }
    }
  }
  void root;
  return {
    nodes: nodes.map((n) => placed.get(n.id)!),
    edges: edges.map((e) => ({ from: e.fromNodeId, to: e.toNodeId })),
  };
}

/** The single root: flagged `isRoot`, else the unique parentless node that
 *  is referenced as someone's parent (a leaf is NOT a root, AD-14). */
function findRoot(nodes: SemanticNode[]): SemanticNode | undefined {
  const flagged = nodes.find((n) => n.isRoot === true);
  if (flagged !== undefined) return flagged;
  const parentless = nodes.filter((n) => n.parentId === undefined);
  if (parentless.length === 1 && nodes.some((m) => m.parentId === parentless[0]!.id)) {
    return parentless[0];
  }
  return parentless.length === 1 ? parentless[0] : undefined;
}
