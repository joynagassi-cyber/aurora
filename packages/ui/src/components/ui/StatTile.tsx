/**
 * StatTile — 05 §3.3: KPI tile (focusBilan instance of ChartSpec, 05
 * §3.6.9). `loading` = skeleton value; `empty` = "—".
 */
import { cn } from "src/lib/utils";
import type { StatTileProps } from "src/renderers/contracts";

export function StatTile({
  label,
  value,
  unit,
  chartId,
  loading,
  className,
}: StatTileProps & { className?: string }) {
  const empty = value === "" || (value === 0 && !unit);
  return (
    <div
      data-aurora-component="StatTile"
      data-chart-id={chartId}
      data-state={loading ? "loading" : empty ? "empty" : "idle"}
      className={cn(
        "rounded-md border border-border bg-card p-4 shadow-sm",
        className,
      )}
    >
      <p className="font-mono text-xs uppercase tracking-wide text-muted-foreground">
        {label}
      </p>
      {loading ? (
        <div className="mt-2 h-6 w-24 rounded bg-muted animate-pulse-skeleton" />
      ) : empty ? (
        <p className="mt-1 text-2xl font-bold text-muted-foreground">—</p>
      ) : (
        <p className="mt-1 text-2xl font-bold tabular-nums">
          {value}
          {unit ? (
            <span className="ml-1 font-mono text-sm font-normal text-muted-foreground">
              {unit}
            </span>
          ) : null}
        </p>
      )}
    </div>
  );
}
