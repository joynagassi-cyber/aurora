/**
 * InfographicRenderer — AD-10 engine (@antv/infographic) behind the
 * 02 §5.2 contract. The kernel produces & validates the spec; this
 * component only lays out (AD-11: text dominant, the engine never
 * rewrites content).
 *
 * SVG-first (05 §3.6.7: scalable, exportable — PNG is the export, not
 * the render). Hybrid SVG + <image>: figures are real photos /
 * generated images (R2, 04 §5) embedded via <image> in the SVG.
 *
 * The @antv/infographic engine is loaded lazily (dynamic import) so it
 * stays out of the initial bundle (AD-10: engine = view + interaction,
 * not a bundle-level dependency).
 */
import { useCallback, useEffect, useRef, useState } from "react";
import { cn } from "src/lib/utils";
import type {
  InfographicRendererProps,
  InfographicSpec,
} from "./contracts";
import type {
  Data,
  ExportOptions,
  ItemDatum,
} from "@antv/infographic";

// `ListDatum` (BaseDatum shape) is internal to the package — only the
// `ItemDatum` union is exported from the index. Items are built as
// plain BaseDatum-shaped objects and cast through `unknown` into the
// `Data` shape below.

/**
 * 02 §5.2 blocks → @antv/infographic `Data` shape.
 * The engine never rewrites content (AD-11): blocks map 1:1 to items.
 */
function specToData(spec: InfographicSpec): Data {
  const titleBlock = spec.blocks.find((b) => b.type === "title");
  // `ListDatum` (BaseDatum shape) — `value` is optional here (required
  // only on the StatisticsDatum variant, which we don't use). Typed
  // through the `ItemDatum` union; the unknown cast below is safe.
  const items = spec.blocks.map((b, i) => ({
    label: b.type === "title" ? (b.text ?? "") : `§${i + 1}`,
    desc: b.text ?? b.latex ?? b.image?.caption ?? "",
    icon: b.image?.url,
    // AD-11 provenance: the kernel's source ref, never re-invented
    // by the engine (Record<string, object> — sourceRefId wrapped in an
    // object to satisfy the `object` index signature).
    attributes: {
      type: b.type,
      sourceRefId: b.sourceRef?.id ? { id: b.sourceRef.id } : undefined,
    },
  }));
  return {
    title: titleBlock?.text ?? "",
    desc: spec.auroraExplanation,
    // BaseDatum[] is assignable to ItemDatum[] (ListDatum = BaseDatum).
    items: items as unknown as ItemDatum[],
  };
}

/** The @antv/infographic runtime instance surface we rely on. */
type InfographicInstance = {
  destroy: () => void;
  render: () => void;
  update: (opts: object) => void;
  toDataURL: (opts?: ExportOptions) => Promise<string>;
};

export function InfographicRenderer({
  spec,
  theme,
  onExport,
  fidelityMode = "strict",
}: InfographicRendererProps) {
  const hostRef = useRef<HTMLDivElement>(null);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);
  const infographicRef = useRef<InfographicInstance | null>(null);

  useEffect(() => {
    if (!hostRef.current) return;
    let disposed = false;
    (async () => {
      try {
        const { Infographic } = await import("@antv/infographic");
        if (disposed || !hostRef.current) return;
        hostRef.current.innerHTML = "";
        const infographic = new Infographic({
          container: hostRef.current,
          template: "list",
          data: specToData(spec),
          width: hostRef.current.clientWidth || 400,
          height: Math.max(240, spec.blocks.length * 56),
          svg: { background: false },
        }) as InfographicInstance;
        infographic.render();
        infographicRef.current = infographic;
      } catch (err) {
        if (disposed) return;
        setError(err instanceof Error ? err.message : String(err));
      }
    })();
    return () => {
      disposed = true;
      infographicRef.current?.destroy();
      infographicRef.current = null;
    };
  }, [spec]);

  const exportPng = useCallback(async () => {
    if (!onExport || !infographicRef.current) return;
    setExporting(true);
    try {
      const dataUrl = await infographicRef.current.toDataURL({
        type: "png",
      });
      const res = await fetch(dataUrl);
      const blob = await res.blob();
      await onExport("image/png", blob);
    } catch {
      // AD-8: export failure → the caller surfaces a callout; never crash
    } finally {
      setExporting(false);
    }
  }, [onExport]);

  // AD-11 fidelity: `strict` (default) — the source text is verbatim,
  // the engine only lays it out. `explanatory` — the agent's separate
  // explanation is rendered as a distinct, labeled block (doc §17).
  const auroraNote =
    fidelityMode === "explanatory" && spec.auroraExplanation
      ? spec.auroraExplanation
      : null;

  return (
    <div
      data-aurora-renderer="infographic"
      data-fidelity-mode={fidelityMode}
      className={cn("space-y-2", theme && "text-card-foreground")}
    >
      <div ref={hostRef} className="min-h-[240px] w-full" />
      {error ? (
        <p
          role="alert"
          className="rounded-md border border-danger bg-danger-surface p-3 text-sm text-danger"
        >
          Infographie indisponible ({error}) — texte source conservé
          (AD-8).
        </p>
      ) : null}
      {auroraNote ? (
        <aside className="rounded-md border border-info bg-info-surface p-3 text-sm">
          <p className="font-mono text-xs text-info">Explication d'Aurora</p>
          <p className="mt-1 text-foreground">{auroraNote}</p>
        </aside>
      ) : null}
      {onExport ? (
        <button
          type="button"
          onClick={() => void exportPng()}
          disabled={exporting}
          className="mt-2 rounded-md border border-border bg-secondary px-3 py-1.5 text-xs font-medium hover:bg-secondary/80 disabled:opacity-50"
        >
          {exporting ? "Export…" : "Exporter PNG"}
        </button>
      ) : null}
    </div>
  );
}

export type { InfographicSpec };
