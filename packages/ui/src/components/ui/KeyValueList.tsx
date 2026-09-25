/**
 * KeyValueList — 05 §3.6.2: definition-list style key/value rows
 * (e.g. exam metadata, source details). Values in JetBrains Mono
 * when numeric (05 §2.2).
 * 5 canonical states: idle / loading / empty / error / offline.
 */
import { cn } from "src/lib/utils";

export interface KeyValueItem {
  key: string;
  value: string | number;
  /** Numeric / unit values → JetBrains Mono tabular-nums. */
  mono?: boolean;
}

export function KeyValueList({
  items,
  loading,
  emptyMessage,
  errorMessage,
  onRetry,
  className,
}: {
  items: KeyValueItem[];
  loading?: boolean;
  emptyMessage?: string;
  errorMessage?: string;
  onRetry?: () => void;
  className?: string;
}) {
  if (loading) {
    return (
      <div
        data-aurora-component="KeyValueList"
        role="status"
        aria-label="Chargement"
        className={cn("space-y-1", className)}
      >
        {Array.from({ length: Math.max(3, items.length) }).map((_, i) => (
          <div key={i} className="flex justify-between gap-4">
            <div className="h-3 w-24 rounded bg-muted animate-pulse-skeleton" />
            <div className="h-3 flex-1 rounded bg-muted animate-pulse-skeleton" />
          </div>
        ))}
      </div>
    );
  }

  if (errorMessage) {
    return (
      <div
        data-aurora-component="KeyValueList"
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

  if (items.length === 0) {
    return (
      <div
        data-aurora-component="KeyValueList"
        data-state="empty"
        className={cn("rounded-md border border-info bg-info-surface p-3 text-sm", className)}
      >
        {emptyMessage ?? "Aucune donnée."}
      </div>
    );
  }

  return (
    <dl
      data-aurora-component="KeyValueList"
      data-state="idle"
      className={cn("divide-y divide-border/60", className)}
    >
      {items.map((it) => (
        <div key={it.key} className="flex items-baseline justify-between gap-4 py-1.5">
          <dt className="text-sm text-muted-foreground">{it.key}</dt>
          <dd
            className={cn(
              "text-right text-sm",
              (it.mono || typeof it.value === "number") &&
                "font-mono tabular-nums",
            )}
          >
            {it.value}
          </dd>
        </div>
      ))}
    </dl>
  );
}
