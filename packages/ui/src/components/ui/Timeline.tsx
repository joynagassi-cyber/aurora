/**
 * Timeline — 05 §3.6.3: event history (narrative). 3 semantic dot
 * colors: success (completion) / warning (report) / primary (decision).
 * 5 canonical states: idle / loading / empty / error / offline.
 */
import { cn } from "src/lib/utils";
import type { TimelineEvent, TimelineProps } from "src/renderers/contracts";

const DOT: Record<TimelineEvent["kind"], string> = {
  success: "bg-success",
  warning: "bg-warning",
  primary: "bg-primary",
};

export function Timeline({
  events,
  loading,
  emptyMessage,
  errorMessage,
  onRetry,
  className,
}: TimelineProps & {
  errorMessage?: string;
  onRetry?: () => void;
  className?: string;
}) {
  return (
    <div data-aurora-component="Timeline" className={cn("space-y-2", className)}>
      {loading ? (
        <div role="status" aria-label="Chargement" className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="flex items-center gap-3">
              <div className="h-3 w-3 rounded-full bg-muted animate-pulse-skeleton" />
              <div className="h-3 flex-1 rounded bg-muted animate-pulse-skeleton" />
            </div>
          ))}
        </div>
      ) : errorMessage ? (
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
        </div>
      ) : events.length === 0 ? (
        <div className="rounded-md border border-info bg-info-surface p-3 text-sm">
          {emptyMessage ?? "Aucun événement."}
        </div>
      ) : (
        <ol className="relative space-y-4 border-l border-border pl-5">
          {events.map((ev) => (
            <li key={ev.id} className="relative">
              <span
                aria-hidden
                className={cn(
                  "absolute -left-[26px] top-1 h-3 w-3 rounded-full ring-4 ring-background",
                  DOT[ev.kind],
                )}
              />
              <p className="text-sm">{ev.label}</p>
              <time className="font-mono text-xs text-muted-foreground tabular-nums">
                {ev.at}
              </time>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
