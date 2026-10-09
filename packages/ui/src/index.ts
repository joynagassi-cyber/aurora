/**
 * @aurora/ui — Design System: tokens, shadcn/ui components, AD-10 renderer
 * implementations, themes JSON SSoT (AD-17, G-M5).
 *
 * Consumes @aurora/domain types (AD-15 SSoT); vendors only where AD-1
 * allows (AD-10 engines + UI libraries per docs/ui-libraries.md).
 *
 * shadcn/ui components live in src/components/ui/ (headless Radix +
 * Tailwind, fully skinnable via the Aurora CSS variables —
 * docs/ui-libraries.md §4).
 */

// --- Theme system (AD-17, 05 §5 v2) ---------------------------------------
export * from "./themes/types";
export { THEMES, PRESETS, THEME_CATALOG } from "./themes/index";
export { NEUTRAL_STYLES } from "./themes/neutral";
export {
  IMAGE_THEMES,
  IMAGE_THEME_FILES,
  getImageTheme,
  resolveImageThemeFile,
  type ImageThemeEntry,
  type ImageThemeOrientation,
  type ImageThemeSlug,
} from "./themes/image-themes";
export {
  resolveToken,
  resolveThemeCSSVars,
  toShadcnVars,
  accentInk,
  contrastRatio,
  hexLuminance,
  gradientCSS,
} from "./themes/resolve";
export {
  AuroraThemeProvider,
  useAuroraTheme,
  useReducedMotion,
  type AuroraThemeProviderProps,
  type AuroraThemeContextValue,
} from "./theme/provider";

// --- shadcn/ui components (docs/ui-libraries.md §1/§2) --------------------
export * from "./components/ui/accordion";
export * from "./components/ui/alert";
export * from "./components/ui/alert-dialog";
export * from "./components/ui/avatar";
export * from "./components/ui/badge";
export * from "./components/ui/breadcrumb";
export * from "./components/ui/button";
export * from "./components/ui/card";
export * from "./components/ui/checkbox";
export * from "./components/ui/command";
export * from "./components/ui/context-menu";
export * from "./components/ui/dialog";
export * from "./components/ui/drawer";
export * from "./components/ui/dropdown-menu";
export * from "./components/ui/form";
export * from "./components/ui/hover-card";
export * from "./components/ui/input";
export * from "./components/ui/kbd";
export * from "./components/ui/label";
export * from "./components/ui/menubar";
export * from "./components/ui/pagination";
export * from "./components/ui/popover";
export * from "./components/ui/progress";
export * from "./components/ui/radio-group";
export * from "./components/ui/scroll-area";
export * from "./components/ui/select";
export * from "./components/ui/separator";
export * from "./components/ui/sheet";
export * from "./components/ui/sidebar";
export * from "./components/ui/skeleton";
export * from "./components/ui/slider";
export * from "./components/ui/switch";
export * from "./components/ui/table";
export * from "./components/ui/tabs";
export * from "./components/ui/textarea";
export * from "./components/ui/toast";
export * from "./components/ui/toaster";
export * from "./components/ui/tooltip";

// --- Premium effects (Aceternity + Magic UI, docs/ui-libraries.md §2 s3) ---
export * from "./components/ui/premium";
// --- Motion SSoT (PAGE_TRANSITION/NodePulse/Reveal, 05 §2.6 + emotion §3) ---
export * from "./motion";
// --- Agent thinking state (docs/ui-libraries.md §9.3) --------------------
// Organic "organism" loader (3 morphing blobs, GPU transform+opacity)
// + optional static monochrome butterfly mark (prop). S9-compliant.
export { AgentThinkingLoader, type AgentThinkingLoaderProps } from "./components/ui/AgentThinkingLoader";

// --- AD-10 renderer contracts + 4 DS data components (05 §3.6) -----------
export * from "./renderers";
export type {
  SemanticTreeRendererProps,
  InfographicRendererProps,
  DataVisualizationRendererProps,
  MathRendererProps,
  AnimationController,
  AnimationSlotProps,
  DataTableColumn,
  DataTableProps,
  TimelineEvent,
  TimelineProps,
  GanttRowProps,
  StatTileProps,
  TreeRelation,
  RenderSemanticNode,
  RenderSemanticEdge,
  RenderSemanticBridge,
  InfographicSpec,
  CalendarBlockType,
  RenderCalendarEvent,
  CalendarViewName,
  CalendarViewProps,
  DayCellContentArg,
  AgGridColumnDef,
  AgGridTableProps,
} from "./renderers/contracts";
export type {
  ChartSpec,
  AuroraPreset,
  AuroraTheme,
} from "./themes/types";
export {
  createSemanticTreeRenderer,
  createInfographicRenderer,
  createDataVisualizationRenderer,
  createMathRenderer,
} from "./renderers/contracts";
export { DataTable } from "./components/ui/DataTable";
export { KeyValueList } from "./components/ui/KeyValueList";
export { Timeline } from "./components/ui/Timeline";
export { GanttRow } from "./components/ui/GanttRow";
export { StatTile } from "./components/ui/StatTile";

// --- Calendar (FullCalendar v6) + data grid (AG Grid Community) -----------
// docs/ui-libraries.md §1: Calendar = FullCalendar (NOT ion-calendar);
// data tables > 100 rows = AG Grid (virtualized, 60fps Pixel 4a).
export { CalendarView } from "./components/ui/CalendarView";
export { AgGridTable } from "./components/ui/AgGridTable";

// --- Utils & hooks ----------------------------------------------------------
export { cn } from "./lib/utils";
export { markdownToHtml, commentAnchors } from "./lib/canvas-utils";
export { useToast } from "./hooks/use-toast";
export { useIsMobile } from "./hooks/use-mobile";

export {};
