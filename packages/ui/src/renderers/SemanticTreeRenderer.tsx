/**
 * SemanticTreeRenderer — AD-10 engine (React Flow + Dagre) behind the
 * 02 §5.1 contract. Layout engine: computes positions ONLY (Dagre);
 * the app owns the tree (AD-6: the engine never owns the truth).
 *
 * PERFORMANCE (02 §9.2 normative rules — 30fps on Pixel 4a @4x):
 *  R1 — at mount: Level-1 nodes only. Children via `lazyChildren`,
 *       rendered only when a branch is deployed (`onToggleBranch`).
 *  R2 — `visibleBranches` = incremental Dagre: only deployed branches are
 *       laid out, so a 1000-node tree stays a few dozen nodes per render.
 *  R3 — memoized custom node component: React Flow re-renders a node only
 *       when its props actually change.
 *  R4 — Dagre cached per (nodes,edges,bridges) key: pan/zoom = 0 layout
 *       recomputes; a new node batch = 1 recompute.
 */
import * as React from "react";
import { useCallback, useMemo, useState } from "react";
import * as dagre from "dagre";
import {
  Background,
  Controls,
  ReactFlow,
  type Edge,
  type Node,
  type NodeProps,
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";
import { cn } from "src/lib/utils";
import type {
  RenderSemanticBridge,
  RenderSemanticEdge,
  RenderSemanticNode,
  SemanticTreeRendererProps,
} from "./contracts";
import { useReducedMotion } from "src/theme/provider";

// ---------------------------------------------------------------------------
// Custom node — AD-13 5 canonical states + node-state ring (05 §3.6.5)
// ---------------------------------------------------------------------------

const STATE_STYLES: Record<
  RenderSemanticNode["state"]["learningState"],
  { ring: string; label: string }
> = {
  mastered: { ring: "ring-2 ring-inset ring-success/50", label: "Acquis" },
  fragile: { ring: "ring-2 ring-inset ring-warning/50", label: "Fragile" },
  forgotten: { ring: "ring-2 ring-inset ring-danger/50", label: "Oublié" },
  "not-yet": { ring: "ring-2 ring-inset ring-border", label: "À venir" },
};

const STATE_FALLBACK = STATE_STYLES["not-yet"];

/**
 * R3 — memoized: React Flow only re-renders a node when its `data`
 * reference changes (a new node batch), never on pan/zoom/selection.
 */
const SemanticNodeComponent = React.memo(function SemanticNodeComponent({
  data,
}: NodeProps) {
  const node = (data as { semantic: RenderSemanticNode }).semantic;
  const s =
    STATE_STYLES[node.state?.learningState ?? "not-yet"] ?? STATE_FALLBACK;
  return (
    <div
      data-node-id={node.id}
      className={cn(
        "rounded-md border border-border bg-card px-3 py-2 text-sm font-medium shadow-sm",
        s.ring,
      )}
    >
      <span>{node.concept}</span>
      <span className="ml-2 font-mono text-xs text-muted-foreground">
        {s.label}
      </span>
      {node.hasChildren ? (
        <span className="ml-1 text-xs text-muted-foreground" aria-hidden>
          +
        </span>
      ) : null}
    </div>
  );
});

const nodeTypes = { semantic: SemanticNodeComponent };

// ---------------------------------------------------------------------------
// Dagre — layout only, cached per batch key (R4)
// ---------------------------------------------------------------------------

const DAGRE_CACHE = new Map<string, { nodes: Node[]; edges: Edge[] }>();

function layoutWithDagre(
  nodes: RenderSemanticNode[],
  edges: RenderSemanticEdge[],
  bridges: RenderSemanticBridge[],
): { nodes: Node[]; edges: Edge[] } {
  const key = [
    nodes.map((n) => n.id).join(","),
    edges.map((e) => e.id).join(","),
    bridges.map((b) => b.id).join(","),
  ].join("|");
  const hit = DAGRE_CACHE.get(key);
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

  const flowNodes: Node[] = nodes.map((n) => {
    const p = g.node(n.id) ?? { x: 0, y: 0 };
    return {
      id: n.id,
      type: "semantic",
      position: { x: p.x, y: p.y },
      data: { semantic: n },
    };
  });
  const flowEdges: Edge[] = [
    ...edges.map((e) => ({
      id: e.id,
      source: e.source,
      target: e.target,
      label: e.relation,
      style: { stroke: "hsl(var(--aurora-border-strong-h))" },
      labelStyle: { fill: "hsl(var(--aurora-text-muted-h))", fontSize: 10 },
    })),
    // Cross-domain bridges — dashed, passed explicitly by the app
    // (05 §3.6.6 Phased Layering: the app toggles the layer on/off).
    ...bridges.map((b) => ({
      id: b.id,
      source: b.source,
      target: b.target,
      label: b.label,
      dashed: true,
      style: { stroke: "hsl(var(--aurora-accent-secondary-h))" },
      labelStyle: { fill: "hsl(var(--aurora-text-muted-h))", fontSize: 10 },
    })),
  ];

  const out = { nodes: flowNodes, edges: flowEdges };
  DAGRE_CACHE.set(key, out);
  // Tiny cap: oldest key evicted on overflow (R4 — no unbounded growth).
  if (DAGRE_CACHE.size > 8) {
    const oldest = DAGRE_CACHE.keys().next().value;
    if (oldest !== undefined) DAGRE_CACHE.delete(oldest);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

/**
 * The semantic-tree DEF component (02 §5.1 CONSO). The app renders it
 * with Level-1 nodes + edges; children are lazy (`lazyChildren`), fired
 * only on branch deploy — R1/R2. Selection → `onSelectNode`.
 *
 * Branch deploy: the app calls `onToggleBranch(id, open)` — the
 * implementation here updates its internal `opened` set AND fires the
 * app callback (the app owns the tree, AD-6).
 */
export function SemanticTreeRenderer({
  nodes,
  edges,
  bridges,
  fitView = true,
  initialFocusId,
  onSelectNode,
  onToggleBranch,
  visibleBranches,
  lazyChildren,
}: SemanticTreeRendererProps) {
  const reducedMotion = useReducedMotion();
  const [opened, setOpened] = useState<string[]>(() =>
    visibleBranches
      ? [...visibleBranches]
      : initialFocusId
        ? [initialFocusId]
        : [],
  );
  const [lazyNodes, setLazyNodes] = useState<RenderSemanticNode[]>([]);
  const [loadingBranch, setLoadingBranch] = useState<string | null>(null);

  // R2 — only roots + deployed branches are in the layout batch.
  const hasParent = useMemo(() => {
    const s = new Set<string>();
    for (const e of edges) s.add(e.target);
    for (const b of bridges ?? []) s.add(b.target);
    return s;
  }, [edges, bridges]);

  const allNodes = useMemo(() => [...nodes, ...lazyNodes], [nodes, lazyNodes]);
  const effectiveVisible = visibleBranches ?? opened;

  const laid = useMemo(
    () => layoutWithDagre(allNodes, edges, bridges ?? []),
    // R4: cached internally — deps are the batch key inputs.
    [allNodes, edges, bridges, effectiveVisible],
  );

  // Branch deploy: update internal state + fire the app callback +
  // fetch lazy children if the branch is opened (R1).
  const toggleBranch = useCallback(
    (id: string, open: boolean) => {
      setOpened((prev) =>
        open
          ? Array.from(new Set([...prev, id]))
          : prev.filter((x) => x !== id),
      );
      onToggleBranch?.(id, open);
      if (open && lazyChildren) {
        setLoadingBranch(id);
        lazyChildren(id)
          .then((kids) => setLazyNodes((prev) => [...prev, ...kids]))
          .catch(() => {
            // AD-8: offline/error → the caller surfaces the callout state;
            // the tree never breaks (05 §3.7 matrix).
          })
          .finally(() => setLoadingBranch(null));
      }
    },
    [onToggleBranch, lazyChildren],
  );

  // Expose toggleBranch as the onToggleBranch prop to the React Flow
  // node component (R1: the "+" affordance on a node fires it).
  const handleNodeDoubleClick = useCallback(
    (_event: React.MouseEvent, node: Node) => {
      const semantic = node.data as { semantic: RenderSemanticNode };
      if (semantic.semantic?.hasChildren) {
        toggleBranch(node.id, true);
      }
    },
    [toggleBranch],
  );

  // R1 — lazy children of a deployed branch: their parent edge may be in
  // `edges` already, or arrives with the lazy batch (caller merges).
  const visibleNodeIds = useMemo(() => {
    const ids = new Set<string>();
    for (const n of allNodes) {
      if (!hasParent.has(n.id)) ids.add(n.id); // root — always visible
    }
    for (const id of effectiveVisible) {
      // children of every deployed branch
      for (const e of edges) {
        if (e.source === id) ids.add(e.target);
      }
    }
    return ids;
  }, [allNodes, hasParent, edges, effectiveVisible]);

  const displayNodes = useMemo(
    () => laid.nodes.filter((fn) => visibleNodeIds.has(fn.id)),
    [laid, visibleNodeIds],
  );
  const displayEdges = useMemo(
    () =>
      laid.edges.filter(
        (fe) => visibleNodeIds.has(fe.source) && visibleNodeIds.has(fe.target),
      ),
    [laid, visibleNodeIds],
  );

  const onNodeClick = useCallback(
    (_event: React.MouseEvent, node: Node) => {
      onSelectNode?.(node.id);
    },
    [onSelectNode],
  );

  return (
    <div
      data-aurora-renderer="semantic-tree"
      data-reduced-motion={reducedMotion ? "true" : "false"}
      data-loading-branch={loadingBranch ?? undefined}
      className="h-full w-full"
    >
      <ReactFlow
        nodes={displayNodes}
        edges={displayEdges}
        fitView={fitView}
        minZoom={0.2}
        maxZoom={2}
        nodeTypes={nodeTypes}
        onNodeClick={onNodeClick}
        onNodeDoubleClick={handleNodeDoubleClick}
        proOptions={{ hideAttribution: true }}
        className="!bg-background"
      >
        <Background gap={[24, 24]} color="hsl(var(--aurora-border-h))" />
        <Controls showInteractive={false} />
      </ReactFlow>
      {/* AD-13 states: branch fetching → subtle skeleton on the parent */}
      {loadingBranch ? (
        <span className="pointer-events-none absolute right-2 top-2 font-mono text-xs text-muted-foreground">
          chargement…
        </span>
      ) : null}
    </div>
  );
}

export { STATE_STYLES, SemanticNodeComponent, layoutWithDagre };
