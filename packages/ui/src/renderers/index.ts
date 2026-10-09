/**
 * @aurora/ui — AD-10 renderer contracts (DEF) + 4 DS data components.
 * Apps import from `@aurora/ui`, never the engines (AD-1 boundary, CI).
 */

export type {
  TreeRelation,
  RenderSemanticNode,
  RenderSemanticEdge,
  RenderSemanticBridge,
  SemanticTreeRendererProps,
  InfographicSpec,
  InfographicRendererProps,
  DataVisualizationRendererProps,
  MathRendererProps,
  MathRenderError,
  AnimationController,
  RevealKey,
  AnimationSlotProps,
  DataTableColumn,
  DataTableProps,
  TimelineEvent,
  TimelineProps,
  GanttRowProps,
  StatTileProps,
  CalendarBlockType,
  RenderCalendarEvent,
  CalendarViewName,
  CalendarViewProps,
  DayCellContentArg,
  AgGridColumnDef,
  AgGridTableProps,
  NodeState,
  SourceRef,
} from "./contracts";
export type { ChartSpec } from "src/themes/types";
export {
  createSemanticTreeRenderer,
  createInfographicRenderer,
  createDataVisualizationRenderer,
  createMathRenderer,
} from "./contracts";

// Engine implementations (React components — the AD-10 DEF side).
export { SemanticTreeRenderer } from "./SemanticTreeRenderer";
export { InfographicRenderer } from "./InfographicRenderer";
export {
  DataVisualizationRenderer,
  type DataVisualizationRendererProps as DataVizProps,
} from "./DataVisualizationRenderer";
export { MathRenderer } from "./MathRenderer";
export {
  AnimationSlot,
  createAnimationController,
} from "./AnimationController";

// 4 DS data components (05 S3.6 DEF selection).
export { DataTable } from "src/components/ui/DataTable";
export { KeyValueList } from "src/components/ui/KeyValueList";
export { Timeline } from "src/components/ui/Timeline";
export { GanttRow } from "src/components/ui/GanttRow";
export { StatTile } from "src/components/ui/StatTile";

// Calendar (FullCalendar) + data grid (AG Grid) — docs/ui-libraries.md §1.
export { CalendarView } from "../components/ui/CalendarView";
export { AgGridTable } from "../components/ui/AgGridTable";
