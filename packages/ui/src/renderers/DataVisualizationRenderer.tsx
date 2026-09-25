/**
 * DataVisualizationRenderer — AD-10 engine (@antv/g2) behind the
 * 02 §5.3 contract. ChartSpec = SSoT G-M5 (packages/ui, 05 §3.6.9).
 *
 * 05 §2.6 rule 1: SCIENTIFIC DATA NEVER ANIMATES — the G2 animation
 * config is disabled when reduced-motion is ON (05 §2.6 rule 2) AND
 * when `animateValues === false` is set explicitly on the spec.
 *
 * The @antv/g2 engine is loaded lazily (dynamic import) so it stays
 * out of the initial bundle (AD-10: engine = view + interaction).
 */
import { useCallback, useEffect, useRef, useState } from "react";
import { cn } from "src/lib/utils";
import type { ChartSpec } from "./contracts";
import { useReducedMotion } from "src/theme/provider";

/**
 * G2 5.x Chart options, typed loosely (the engine API surface is frozen
 * by AD-10; only the option keys below are relied upon).
 * 05 §2.6 rule 1: `animateValues === false` or reduced-motion → no anim.
 */
function specToG2Options(
  spec: ChartSpec,
  width: number,
  height: number,
  reducedMotion: boolean,
): Record<string, unknown> {
  const values = (spec.series[0]?.values ?? []).map((v) => v.value);
  const maxV = Math.max(1, ...values);
  // 05 §2.6 rule 1: scientific data never animates — animation only
  // when animateValues is undefined (default ON) AND reduced-motion OFF.
  const animationOn = spec.animateValues === undefined && !reducedMotion;

  const base: Record<string, unknown> = {
    width,
    height,
    animation: animationOn ? undefined : false,
    legend: false,
  };

  switch (spec.type) {
    case "line":
    case "area":
      return {
        ...base,
        type: spec.type === "area" ? "area" : "line",
        data: spec.series[0]?.values ?? [],
        encode: { x: "label", y: "value" },
        axis: {
          x: { title: false },
          y: { title: false, min: 0, max: maxV },
        },
        style: {
          lineWidth: 2,
          ...(spec.type === "area" ? { fillOpacity: 0.15 } : {}),
        },
      };
    case "bar":
      return {
        ...base,
        type: "interval",
        data: spec.series[0]?.values ?? [],
        encode: { x: "label", y: "value" },
        axis: { x: { title: false }, y: { title: false, min: 0, max: maxV } },
        style: { radius: 4 },
      };
    case "pie":
      return {
        ...base,
        type: "interval",
        coordinate: { type: "polar", outerRadius: 0.8 },
        data: spec.series[0]?.values ?? [],
        encode: { y: "value", color: "label" },
      };
    case "radar":
      return {
        ...base,
        type: "line",
        coordinate: { type: "polar" },
        data: spec.series[0]?.values ?? [],
        encode: { x: "label", y: "value" },
      };
    case "heatmap":
      // 05 §2.6 rule 1: heatmap = scientific data → no animation.
      return {
        ...base,
        animation: false,
        type: "rect",
        data: spec.series[0]?.values ?? [],
        encode: { x: "label", color: "value" },
      };
    default:
      return base;
  }
}

export interface DataVisualizationRendererProps {
  spec: ChartSpec;
  width?: number;
  height?: number;
  seriesLabel?: string;
}

export function DataVisualizationRenderer({
  spec,
  width = 320,
  height = 200,
  seriesLabel,
}: DataVisualizationRendererProps) {
  const hostRef = useRef<HTMLDivElement>(null);
  const [error, setError] = useState(false);
  const [retryToken, setRetryToken] = useState(0);
  const reducedMotion = useReducedMotion();
  const g2Ref = useRef<{ destroy: () => void } | null>(null);

  useEffect(() => {
    if (!hostRef.current) return;
    let disposed = false;
    (async () => {
      try {
        const { Chart } = await import("@antv/g2");
        if (disposed || !hostRef.current) return;
        g2Ref.current?.destroy();
        const options = specToG2Options(spec, width, height, reducedMotion);
        const chart = new Chart({
          container: hostRef.current,
          ...options,
        } as never);
        chart.render();
        g2Ref.current = { destroy: () => chart.destroy() };
      } catch {
        if (disposed) return;
        setError(true);
      }
    })();
    return () => {
      disposed = true;
      g2Ref.current?.destroy();
      g2Ref.current = null;
    };
  }, [spec, width, height, reducedMotion, retryToken]);

  const retry = useCallback(() => {
    setError(false);
    setRetryToken((t) => t + 1);
  }, []);

  return (
    <figure
      data-aurora-renderer="data-viz"
      data-chart-id={spec.id}
      className={cn("space-y-1")}
    >
      {seriesLabel ? (
        <figcaption className="font-mono text-xs text-muted-foreground">
          {seriesLabel}
        </figcaption>
      ) : null}
      <div ref={hostRef} style={{ width, height }} className="w-full" />
      {error ? (
        <div className="space-y-1">
          <p
            role="alert"
            className="rounded-md border border-danger bg-danger-surface p-2 text-xs text-danger"
          >
            Graphique indisponible — valeurs source (AD-8).
          </p>
          <p className="font-mono text-xs text-muted-foreground tabular-nums">
            {spec.series[0]?.values
              .map((v) => `${v.label}:${v.value}${v.unit ?? ""}`)
              .join("  ")}
          </p>
          <button
            type="button"
            onClick={retry}
            className="rounded-md border border-border bg-secondary px-2 py-1 text-xs hover:bg-secondary/80"
          >
            Réessayer
          </button>
        </div>
      ) : null}
    </figure>
  );
}

export type { ChartSpec };
