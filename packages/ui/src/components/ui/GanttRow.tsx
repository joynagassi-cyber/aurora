/**
 * GanttRow — 05 §3.6.4: one task = one line (mobile-first Gantt).
 *
 * Shared date axis (JetBrains Mono xs labels, 05 §3.4 Pager);
 * bar status colors: in-progress = primary / done = success /
 * to-do = border-strong / blocked = warning.
 * 5 canonical states: idle / loading / empty / error / offline.
 */
import { cn } from "src/lib/utils";
import type { GanttRowProps } from "src/renderers/contracts";

const BAR: Record<GanttRowProps["status"], string> = {
  "in-progress": "bg-primary",
  done: "bg-success",
  todo: "bg-border-strong",
  blocked: "bg-warning",
};

export function GanttRow({
  title,
  status,
  start,
  end,
  completionPct,
  axisLabels,
  loading,
  errorMessage,
  onRetry,
  className,
}: GanttRowProps & {
  errorMessage?: string;
  onRetry?: () => void;
  className?: string;
}) {
  const left = Math.min(100, Math.max(0, start * 100));
  const width = Math.max(2, (end - start) * 100);

  if (loading) {
    return (
      <div
        data-aurora-component="GanttRow"
        data-state="loading"
        className={cn("space-y-1", className)}
        role="status"
        aria-label="Chargement"
      >
        <div className="h-3 w-32 rounded bg-muted animate-pulse-skeleton" />
        <div className="h-4 rounded bg-muted animate-pulse-skeleton" />
      </div>
    );
  }

  if (errorMessage) {
    return (
      <div
        data-aurora-component="GanttRow"
        data-state="error"
        className={cn("space-y-2", className)}
      >
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
      </div>
    );
  }

  return (
    <div data-aurora-component="GanttRow" data-state="idle" className={cn("space-y-1", className)}>
      <div className="flex items-center justify-between gap-2">
        <p className="truncate text-sm">{title}</p>
        {completionPct !== undefined ? (
          <span className="font-mono text-xs text-muted-foreground tabular-nums">
            {completionPct}%
          </span>
        ) : null}
      </div>
      {/* The bar: one task = one line, position on the shared date axis */}
      <div
        role="progressbar"
        aria-valuenow={Math.round(left)}
        aria-valuemax={100}
        aria-valuetext={title}
        className="relative h-4 overflow-hidden rounded bg-muted"
      >
        <div
          className={cn("absolute inset-y-0 rounded", BAR[status])}
          style={{ left: `${left}%`, width: `${width}%` }}
        >
          {status === "in-progress" && completionPct !== undefined ? (
            <div
              className="h-full bg-foreground/20"
              style={{ width: `${completionPct}%` }}
            />
          ) : null}
        </div>
      </div>
      {axisLabels?.length ? (
        <div className="flex justify-between font-mono text-xs text-muted-foreground tabular-nums">
          {axisLabels.map((lbl) => (
            <span key={lbl}>{lbl}</span>
          ))}
        </div>
      ) : null}
    </div>
  );
}
