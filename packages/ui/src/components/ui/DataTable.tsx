/**
 * DataTable — 05 §3.6.1: semantic HTML data table (NOT a G2 chart).
 *
 * Values in JetBrains Mono tabular-nums (05 §2.2); sticky header;
 * horizontal scroll on mobile — data is never compressed.
 * 5 canonical UX states (05 §3.7): idle / loading / empty / error /
 * offline.
 */
import * as React from "react";
import { cn } from "src/lib/utils";
import type { DataTableColumn, DataTableProps } from "src/renderers/contracts";

export function DataTable<T>({
  columns,
  rows,
  loading,
  emptyMessage,
  errorMessage,
  onRetry,
  horizontalScroll = true,
  className,
}: DataTableProps<T> & { className?: string }) {
  return (
    <div
      data-aurora-component="DataTable"
      className={cn("space-y-2", className)}
    >
      {loading ? (
        // AD-13: loading = skeleton rows (05 §2.6 rule 4: pulse 1.2s)
        <div className="space-y-1" role="status" aria-label="Chargement">
          <SkeletonRow cols={columns.length} />
          <SkeletonRow cols={columns.length} />
          <SkeletonRow cols={columns.length} />
        </div>
      ) : errorMessage ? (
        // AD-13: error = callout danger + retry; last synced data stays
        <div className="space-y-2">
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
          <TableShell columns={columns} scroll={horizontalScroll}>
            <BodyRows columns={columns} rows={rows} />
          </TableShell>
        </div>
      ) : rows.length === 0 ? (
        // AD-13: empty = callout info, header stays
        <div className="space-y-2">
          {emptyMessage ? (
            <div className="rounded-md border border-info bg-info-surface p-3 text-sm text-foreground">
              {emptyMessage}
            </div>
          ) : null}
          <TableShell columns={columns} scroll={horizontalScroll} />
        </div>
      ) : (
        <TableShell columns={columns} scroll={horizontalScroll}>
          <BodyRows columns={columns} rows={rows} />
        </TableShell>
      )}
    </div>
  );
}

function SkeletonRow({ cols }: { cols: number }) {
  return (
    <div className="flex gap-2">
      {Array.from({ length: cols }).map((_, i) => (
        <div
          key={i}
          className="h-4 flex-1 rounded bg-muted animate-pulse-skeleton"
        />
      ))}
    </div>
  );
}

function TableShell({
  columns,
  children,
  scroll,
}: {
  columns: { key: string; label: string }[];
  children?: React.ReactNode;
  scroll?: boolean;
}) {
  return (
    <div className={cn(scroll && "overflow-x-auto")}>
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="sticky top-0 bg-background">
            {columns.map((c) => (
              <th
                key={c.key}
                scope="col"
                className="border-b border-border px-3 py-2 text-left font-mono text-xs font-medium uppercase tracking-wide text-muted-foreground"
              >
                {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}

function BodyRows<T>({
  columns,
  rows,
}: {
  columns: DataTableColumn<T>[];
  rows: T[];
}) {
  return (
    <>
      {rows.map((row, ri) => (
        <tr key={ri} className="border-b border-border/60">
          {columns.map((col) => {
            const raw = (row as Record<string, unknown>)[col.key];
            return (
              <td
                key={col.key}
                className={cn(
                  "px-3 py-2",
                  col.mono && "font-mono tabular-nums text-sm",
                )}
              >
                {col.render ? col.render(row) : String(raw ?? "—")}
              </td>
            );
          })}
        </tr>
      ))}
    </>
  );
}
