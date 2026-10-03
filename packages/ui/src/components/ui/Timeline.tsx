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
  /**
   * Task list mode (05 §4.4.2 — always-on task list under the calendar):
   * when true, each event renders as a task row (compact row with dot +
   * title + time) instead of the semantic-dot narrative history.
   */
  taskList = false,
  className,
}: TimelineProps & {
  errorMessage?: string;
  onRetry?: () => void;
  className?: string;
}) {
  if (taskList) {
    return (
      <div data-aurora-component="Timeline" className={cn("space-y-2", className)}>
        {events.length === 0 ? (
          <div className="rounded-md border border-info bg-info-surface p-3 text-sm">
            {emptyMessage ?? "Aucune tâche pour cette période."}
          </div>
        ) : (
          <ul className="space-y-1.5">
            {events.map((ev) => (
              <li
                key={ev.id}
                className="flex items-center gap-2 rounded-md border border-border bg-card px-3 py-2"
              >
                <span
                  aria-hidden
                  className={cn(
                    "h-3.5 w-3.5 shrink-0 rounded-full ring-2",
                    ev.kind === "success"
                      ? "bg-success ring-success/40"
                      : ev.kind === "warning"
                        ? "bg-warning ring-warning/40"
                        : "bg-primary ring-primary/40",
                  )}
                />
                <span
                  className={cn(
                    "flex-1 text-sm",
                    ev.kind === "success" && "text-muted-foreground line-through",
                  )}
                >
                  {ev.label}
                </span>
                <time className="font-mono text-xs text-muted-foreground tabular-nums">
                  {ev.at}
                </time>
              </li>
            ))}
          </ul>
        )}
      </div>
    );
  }

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
