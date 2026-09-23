/**
 * @aurora/ui — AD-10 renderer contracts (DEF side, 05-design-system §3.6).
 *
 * The 5 frozen engines (@xyflow/react, @dagrejs/dagre, @antv/infographic,
 * @antv/g2, katex, motion) live BEHIND these contracts. Apps consume the
 * contracts, never the engines (AD-1/AD-10 boundary — CI lint enforces).
 *
 * 05 §3.6.1–.12: each DS component is a wrapper of one renderer contract.
 * The 4 "DS data components" of this commit (05 S3.6 DEF selection):
 *   - DataTable   (§3.6.1 — semantic HTML table, NOT a G2 chart)
 *   - Timeline    (§3.6.3 — event narrative, semantic dots)
 *   - GanttRow    (§3.6.4 — one task = one line, mobile-first)
 *   - StatTile    (§3.3 — KPI tile, consumed by the focusBilan ChartSpec)
 * (Sparkline/SemanticTreeNode/InfographicSlot/MathBlock are thin
 * one-to-one wrappers of their engines — added in the 30fps commit.)
 */

import type * as React from "react";
import type { NodeState, SourceRef } from "@aurora/domain";
import type {
  AuroraPreset,
  AuroraTheme,
} from "src/themes/types";

// Re-export the domain SSoT types (AD-15) so `@aurora/ui` consumers can
// reference NodeState / SourceRef without a direct @aurora/domain import.
export type { NodeState, SourceRef };

// ---------------------------------------------------------------------------
// 1. SemanticTreeRenderer — engine: @xyflow/react + @dagrejs/dagre (AD-10)
// ---------------------------------------------------------------------------

/** Tree relation (doc §14). */
export type TreeRelation =
  | "dependsOn"
  | "isCaseOf"
  | "deepens"
  | "applies"
  | "leadsTo";

/** Projection of a semantic node (02 §5.1) — NOT the domain type. */
export interface RenderSemanticNode {
  id: string;
  concept: string;
  /** Domain NodeState (AD-15 SSoT: @aurora/domain). */
  state: NodeState;
  hasChildren?: boolean;
  sourceRef?: SourceRef;
}

export interface RenderSemanticEdge {
  id: string;
  source: string;
  target: string;
  relation: TreeRelation;
}

export interface RenderSemanticBridge {
  id: string;
  source: string;
  target: string;
  label: string;
}

export interface SemanticTreeRendererProps {
  /** Level-1 nodes only at mount (02 §9.2 rule 1 — perf normative). */
  nodes: RenderSemanticNode[];
  edges: RenderSemanticEdge[];
  /** Cross-domain links, hidden by default (Phased Layering, 05 §3.6.6). */
  bridges?: RenderSemanticBridge[];
  fitView?: boolean;
  initialFocusId?: string;
  onSelectNode?: (id: string) => void;
  onToggleBranch?: (id: string, open: boolean) => void;
  // PERFORMANCE (AD-10 / doc §25.2):
  /** Only deployed branches are rendered — incremental Dagre, 30fps target. */
  visibleBranches?: string[];
  lazyChildren?: (parentId: string) => Promise<RenderSemanticNode[]>;
}

/**
 * The AD-10 `SemanticTreeRenderer` contract (02 §5.1 CONSO side).
 * Implementation: `SemanticTreeRenderer` below — React Flow + Dagre, lazy
 * level-1, memoized nodes, 30fps (02 §9.2). The engine never owns the
 * truth (AD-6): nodes/edges are projections passed in by the app.
 */
export interface SemanticTreeRenderer {
  render(props: SemanticTreeRendererProps): string;
  /** Dispose the React Flow instance + Dagre cache. */
  dispose(): void;
}

export function createSemanticTreeRenderer(): SemanticTreeRenderer {
  // AD-10 DEF: engine wiring (React Flow + Dagre) lives in
  // SemanticTreeRendererImpl (lazy, 30fps) — the contract here is the
  // stable CONSO surface the app calls. Engine details stay out of the
  // app (AD-1 boundary).
  throw new Error(
    "createSemanticTreeRenderer: engine implementation is provided by " +
      "SemanticTreeRendererImpl (packages/ui). Call it via React, not raw.",
  );
}

// ---------------------------------------------------------------------------
// 2. InfographicRenderer — engine: @antv/infographic (AD-10)
// ---------------------------------------------------------------------------

/**
 * An infographic spec (02 §5.2, produced & validated by the kernel —
 * the app receives an ALREADY VALIDATED spec, never validates it).
 * The shape follows the 02 §5.2 CONSO signature; the engine (AntV)
 * does the paging, the content stays textually dominant (AD-11).
 */
export interface InfographicSpec {
  id: string;
  /** Page-by-page blocks (AntV pags, it never rewrites — AD-11 §25.5). */
  blocks: {
    type: "title" | "text" | "figure" | "formula" | "callout";
    text?: string;
    /** Figure source: a real photo or a generated image (R2, 04 §5). */
    image?: { url: string; caption?: string; alt?: string };
    latex?: string;
    /** AD-11 provenance: corpus formula/source (SourceRef). */
    sourceRef?: SourceRef;
  }[];
  /** Explicit separation (doc §17): the agent's explanation, labeled. */
  auroraExplanation?: string;
}

export interface InfographicRendererProps {
  spec: InfographicSpec;
  theme?: AuroraTheme | AuroraPreset;
  /** `image/png` export (SVG is the default render — 05 §3.6.7). */
  onExport?: (mime: "image/png", blob: Blob) => Promise<void> | void;
  /** AD-11: `strict` (default) = source text dominant, no paraphrase. */
  fidelityMode?: "strict" | "explanatory";
}

export interface InfographicRenderer {
  /** Renders to SVG (scalable, exportable — 05 §3.6.7: never raster by
   *  default; PNG is the export, not the render). */
  render(props: InfographicRendererProps): string;
  dispose(): void;
}

export function createInfographicRenderer(): InfographicRenderer {
  throw new Error(
    "createInfographicRenderer: engine implementation is provided by " +
      "InfographicRendererImpl (packages/ui). Call it via React, not raw.",
  );
}

// ---------------------------------------------------------------------------
// 3. DataVisualizationRenderer — engine: @antv/g2 (AD-10, G-M5 ChartSpec)
// ---------------------------------------------------------------------------

/**
 * ChartSpec — the public G-M5 shape (05 §3.6.9 focusBilan instance +
 * progression / time series / distributions / scientific results).
 * SSoT lives in `packages/ui` (G-M5 verdict). Re-exported from
 * `src/themes/types` so apps import it from `@aurora/ui` only.
 */
export type { ChartSpec } from "src/themes/types";

export interface DataVisualizationRendererProps {
  spec: import("src/themes/types").ChartSpec;
  width?: number;
  height?: number;
  seriesLabel?: string;
}

export interface DataVisualizationRenderer {
  render(props: DataVisualizationRendererProps): string;
  dispose(): void;
}

export function createDataVisualizationRenderer(): DataVisualizationRenderer {
  throw new Error(
    "createDataVisualizationRenderer: engine implementation is provided by " +
      "DataVisualizationRendererImpl (packages/ui). Call it via React, not raw.",
  );
}

// ---------------------------------------------------------------------------
// 4. MathRenderer — engine: KaTeX (AD-10)
// ---------------------------------------------------------------------------

/** KaTeX failure → styled raw source, never a crash (02 §5.4, AD-8). */
export interface MathRenderError {
  latex: string;
  reason: string;
}

export interface MathRendererProps {
  latex: string;
  displayMode?: boolean;
  /** AD-11: corpus formula provenance (05 §3.6.8 "SourceRef xs muted"). */
  sourceRef?: SourceRef;
  onError?: (err: MathRenderError) => void;
}

export interface MathRenderer {
  /** Returns KaTeX HTML or the styled raw-source fallback (onError fired). */
  render(props: MathRendererProps): string;
}

export function createMathRenderer(): MathRenderer {
  throw new Error(
    "createMathRenderer: engine implementation is provided by " +
      "MathRendererImpl (packages/ui). Call it via React, not raw.",
  );
}

// ---------------------------------------------------------------------------
// 5. AnimationController — engine: motion (AD-10, G-M1 AnimationSlot)
// ---------------------------------------------------------------------------

export type RevealKey = "formula" | "arrow" | "step" | "result" | "branch";

/**
 * The AD-10 `AnimationController` contract (02 §5.5 CONSO side). The DS
 * provides the instance; the app calls it. `prefers-reduced-motion` =
 * mandatory (a11y states, AD-13 DoD — 05 §2.6 rule 2).
 */
export interface AnimationController {
  /** Progressive reveal (doc §25.8): formula, arrow, step, result, branch. */
  reveal(
    nodeRef: { current: HTMLElement | SVGElement | null },
    key: RevealKey,
  ): void;
  setReducedMotion(on: boolean): void;
  prefersReducedMotion(): boolean;
}

/**
 * G-M1: the React wrapper that owns the motion engine for one subtree.
 * `revealKey` (not React's reserved `key`) selects the reveal key.
 */
export interface AnimationSlotProps {
  /** The reveal target (a KaTeX block, a step, a branch…). */
  children: React.ReactNode;
  /** Which key this slot reveals (05 §3.6.5 / 02 §5.5). */
  revealKey?: RevealKey;
  /** When reduced-motion is ON (05 §2.6 rule 2): instant, no trace. */
  reducedMotion?: boolean;
}

export function createAnimationController(): AnimationController {
  // AD-10 DEF: the motion engine is owned by AnimationSlot (React) —
  // the raw controller contract is the stable CONSO surface.
  throw new Error(
    "createAnimationController: engine implementation is provided by " +
      "AnimationSlot (packages/ui, React). Call it via React, not raw.",
  );
}

// ---------------------------------------------------------------------------
// 4 DS data components (05 S3.6 DEF selection, see header)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// 4 DS data components (05 S3.6 DEF selection, see header)
// ---------------------------------------------------------------------------

/** §3.6.1 — semantic HTML data table (JetBrains Mono values, sticky header). */
export interface DataTableColumn<T> {
  key: string;
  label: string;
  /** Values in `JetBrains Mono` `tabular-nums` when `mono` (05 §2.2). */
  mono?: boolean;
  render?: (row: T) => React.ReactNode;
}

export interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  rows: T[];
  /** AD-13 states: loading (skeleton rows) / empty (callout info, header
   *  stays) / error (callout danger + retry, last synced dataset stays). */
  loading?: boolean;
  emptyMessage?: string;
  errorMessage?: string;
  onRetry?: () => void;
  /** Horizontal scroll on mobile — data is never compressed (05 §3.6.1). */
  horizontalScroll?: boolean;
}

/** §3.6.3 — event history (narrative; 3 semantic dot colors, 05 §3.6.3). */
export interface TimelineEvent {
  id: string;
  label: string;
  at: string;
  /** success (completion) / warning (report) / primary (decision). */
  kind: "success" | "warning" | "primary";
}

export interface TimelineProps {
  events: TimelineEvent[];
  loading?: boolean;
  emptyMessage?: string;
}

/** §3.6.4 — one task = one line (mobile-first Gantt, shared date axis). */
export interface GanttRowProps {
  title: string;
  /** In-progress = primary / done = success / to-do = border-strong. */
  status: "in-progress" | "done" | "todo" | "blocked";
  /** 0..1 position on the shared date axis. */
  start: number;
  end: number;
  completionPct?: number;
  /** Shared axis labels (JetBrains Mono xs, 05 §3.4 Pager). */
  axisLabels?: string[];
  loading?: boolean;
}

/** §3.3 — KPI tile (StatTile): `loading` = skeleton value, `empty` = "—". */
export interface StatTileProps {
  label: string;
  value: string | number;
  unit?: string;
  /** The ChartSpec this tile belongs to (05 §3.6.9 focusBilan). */
  chartId?: string;
  loading?: boolean;
}
