/**
 * MathRenderer — AD-10 engine (KaTeX) behind the 02 §5.4 contract.
 *
 * AD-8 (02 §5.4): KaTeX failure → styled raw source, NEVER a crash.
 * `onError` fires with the reason; the rendered output degrades to the
 * raw LaTeX in a styled <pre> (JetBrains Mono, 05 §2.2).
 *
 * AD-11: `sourceRef` = corpus formula provenance (05 §3.6.8
 * "SourceRef xs muted") — the kernel always knows which source a
 * formula came from; the app displays it, never invents it.
 */
import { useMemo } from "react";
import katex from "katex";
import "katex/dist/katex.min.css";
import { cn } from "src/lib/utils";
import type { MathRendererProps, SourceRef } from "./contracts";

function ProvenanceChip({ sourceRef }: { sourceRef: SourceRef }) {
  return (
    <span
      data-source-ref={sourceRef.id}
      className="ml-2 font-mono text-xs text-muted-foreground"
      title={sourceRef.quotedText ?? sourceRef.id}
    >
      source {sourceRef.sourceId}
      {sourceRef.locator ? ` · ${sourceRef.locator}` : ""}
    </span>
  );
}

export function MathRenderer({
  latex,
  displayMode = false,
  sourceRef,
  onError,
}: MathRendererProps) {
  const rendered = useMemo(() => {
    try {
      return {
        ok: true as const,
        html: katex.renderToString(latex, {
          displayMode,
          throwOnError: false,
          output: "html",
        }),
      };
    } catch (err) {
      // AD-8 — styled raw source, never a crash
      onError?.({
        latex,
        reason: err instanceof Error ? err.message : String(err),
      });
      return { ok: false as const };
    }
  }, [latex, displayMode]);

  if (!rendered.ok) {
    // AD-8 degraded state: the raw source, styled (JetBrains Mono,
    // danger border so the state is readable at a glance).
    return (
      <figure
        data-aurora-renderer="math"
        data-state="error"
        className={cn("rounded-md border border-danger bg-danger-surface p-3")}
      >
        <pre className="overflow-x-auto font-mono text-sm text-foreground tabular-nums">
          {latex}
        </pre>
        {sourceRef ? <ProvenanceChip sourceRef={sourceRef} /> : null}
      </figure>
    );
  }

  return (
    <figure
      data-aurora-renderer="math"
      data-state={displayMode ? "display" : "inline"}
      className={cn(
        "rounded-md border border-border bg-card p-3",
        displayMode && "text-center",
      )}
    >
      <div
        // KaTeX output is sanitized by KaTeX itself (02 §5.4: engine
        // = view + interaction; the app passes trusted LaTeX).
        dangerouslySetInnerHTML={{ __html: rendered.html }}
      />
      {sourceRef ? <ProvenanceChip sourceRef={sourceRef} /> : null}
    </figure>
  );
}
