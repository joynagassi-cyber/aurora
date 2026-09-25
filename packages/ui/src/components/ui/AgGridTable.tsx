/**
 * AgGridTable — docs/ui-libraries.md §1/§5: AG Grid Community for
 * heavy data tables (> 100 rows, virtualized, 60fps Pixel 4a target).
 * NOT shadcn Table (that is < 20 rows, §1 "Data Grid (light)").
 * Mobile: rowBuffer 10 (docs §5). AD-13 5 states: loading (skeleton
 * rows) / error (callout + retry, last-synced rows stay) / empty.
 *
 * VENDOR BOUNDARY (AD-1): ag-grid-community + ag-grid-react live ONLY
 * inside this file in packages/ui — the CI boundary grep enforces it.
 */
import * as React from "react";
import { useMemo, useRef } from "react";
import { AgGridReact } from "ag-grid-react";
import { ModuleRegistry, AllCommunityModule } from "ag-grid-community";
import type { ColDef } from "ag-grid-community";
import "ag-grid-community/styles/ag-grid.css";
import "ag-grid-community/styles/ag-theme-alpine.css";
import { cn } from "src/lib/utils";
import type {
  AgGridColumnDef,
  AgGridTableProps,
} from "src/renderers/contracts";

// AD-10 engine registration — Community modules only (no Enterprise).
ModuleRegistry.registerModules([AllCommunityModule]);

const AG_THEME = "ag-theme-alpine";

function toColDef<T extends { id: string | number }>(
  col: AgGridColumnDef<T>,
): ColDef<T> {
  const base: ColDef<T> = {
    field: col.field as ColDef<T>["field"],
    headerName: col.headerName,
    sortable: col.sortable,
    width: col.width,
    cellStyle: col.mono ? { fontVariantNumeric: "tabular-nums" } : undefined,
  };
  // Built-in progress renderer (the only non-trivial built-in).
  if (col.cellRenderer === "progress") {
    base.cellRenderer = (params: { value: unknown }) => {
      const pct = Number(params.value ?? 0);
      return (
        <div className="flex items-center gap-2">
          <div className="h-1.5 w-16 rounded-full bg-muted">
            <div
              className="h-full rounded-full bg-primary"
              style={{
                width: `${Math.min(100, Math.max(0, pct))}%`,
              }}
            />
          </div>
          <span className="font-mono text-xs tabular-nums text-muted-foreground">
            {Math.round(pct)}%
          </span>
        </div>
      );
    };
  }
  return base;
}

export function AgGridTable<T extends { id: string | number }>(
  props: AgGridTableProps<T> & { className?: string },
) {
  const {
    rows,
    columns,
    mobile = false,
    selectable = false,
    onRowClick,
    loading,
    errorMessage,
    onRetry,
    emptyMessage,
    className,
  } = props;
  // AG Grid v33 uses the row model: virtualization is ON by default
  // (rowBuffer below). The app-facing `virtualized` prop is a no-op kept
  // for API stability — the prop is read but not wired (see contract).

  const gridRef = useRef<AgGridReact<T>>(null);
  const defaultColDef = useMemo<Partial<ColDef<T>>>(
    () => ({
      sortable: true,
      filter: true,
      minWidth: 80,
    }),
    [],
  );

  const colDefs = useMemo(() => columns.map((c) => toColDef(c)), [columns]);

  return (
    <div
      data-aurora-component="AgGridTable"
      data-state={
        loading
          ? "loading"
          : errorMessage
            ? "error"
            : rows.length === 0
              ? "empty"
              : "idle"
      }
      className={cn("space-y-2", className)}
    >
      {loading ? (
        <div role="status" aria-label="Chargement" className="space-y-1">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className="h-9 w-full animate-pulse-skeleton rounded bg-muted"
            />
          ))}
        </div>
      ) : null}

      {errorMessage ? (
        <div
          role="alert"
          className="flex items-center justify-between rounded-md border border-danger bg-danger-surface p-3 text-sm text-danger"
        >
          <span>{errorMessage}</span>
          {onRetry ? (
            <button
              type="button"
              onClick={onRetry}
              className="rounded border border-danger/40 px-2 py-1 text-xs hover:bg-danger/20"
            >
              Réessayer
            </button>
          ) : null}
        </div>
      ) : null}

      {!loading && rows.length === 0 && !errorMessage ? (
        <div className="rounded-md border border-info bg-info-surface p-3 text-sm text-foreground">
          {emptyMessage ?? "Aucun résultat"}
        </div>
      ) : null}

      {/* Grid stays mounted on error (last-synced data, AD-8). */}
      <div
        className={cn(
          AG_THEME,
          "w-full overflow-hidden rounded-md border border-border bg-card",
          mobile ? "h-[260px]" : "h-[320px]",
        )}
        style={
          mobile
            ? ({
                "--ag-row-height": "48px",
                "--ag-font-size": "13px",
              } as unknown as React.CSSProperties)
            : undefined
        }
      >
        <AgGridReact
          ref={gridRef}
          theme={AG_THEME as never}
          rowData={rows}
          columnDefs={colDefs}
          defaultColDef={defaultColDef}
          animateRows={!mobile}
          rowBuffer={mobile ? 10 : 50}
          suppressClickEdit
          rowSelection={selectable ? "single" : undefined}
          onRowClicked={
            onRowClick
              ? (e: { data?: T }) => {
                  if (e.data !== undefined) onRowClick(e.data);
                }
              : undefined
          }
        />
      </div>
    </div>
  );
}

export type { AgGridColumnDef, AgGridTableProps };
