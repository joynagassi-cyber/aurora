/**
 * Artifact Hub — preview + export (AD-10 renderer contracts, ADR S16,
 * docs/artifacts/overview.md).
 *
 * Per-format preview + source-file access:
 *   - PDF: paginated read / zoom / search / navigation
 *   - DOCX: preview + content extraction
 *   - PPTX: slide previews
 *   - XLSX/CSV: tabular preview (+ optional G2 charting)
 *   - images: zoom viewer
 *   - markdown / text / code: rendered / editor
 *   - audio / video: built-in player where format + platform allow
 *   - LaTeX: formula / document render when convertible
 *   - unsupported: kept + downloadable, no native-preview claim
 *
 * Export: PDF / DOCX / PPTX / XLSX / PNG / TXT (ADR S17 sheet export
 * matrix). The RENDERER lives in @aurora/ui (AD-10); this module owns
 * the SPEC + metadata (previewable, kind, r2Key, provenance).
 */
import type { Artifact, ArtifactFile } from '@aurora/domain';

/** A preview spec — the renderer (AD-10) draws it, NOT the module. */
export interface PreviewSpec {
  /** which renderer applies (AD-10 contracts) */
  renderer:
    | 'pdf-paginated'
    | 'docx-content'
    | 'pptx-slides'
    | 'xlsx-tabular'
    | 'image-zoom'
    | 'text-markdown'
    | 'audio-player'
    | 'video-player'
    | 'latex-render'
    | 'fallback-download';
  /** format-specific options */
  options?: Record<string, unknown>;
  /** whether this kind supports a native preview (ADR S16 last bullet) */
  previewable: boolean;
}

/** The per-kind preview matrix (ADR S16 "never pretend" rule). */
export function previewSpecForKind(kind: Artifact['kind']): PreviewSpec {
  switch (kind) {
    case 'pdf':
      return { renderer: 'pdf-paginated', options: { zoom: 1, search: true }, previewable: true };
    case 'docx':
      return { renderer: 'docx-content', options: { extract: true }, previewable: true };
    case 'pptx':
      return { renderer: 'pptx-slides', options: {}, previewable: true };
    case 'xlsx':
    case 'csv':
      return { renderer: 'xlsx-tabular', options: { g2: true }, previewable: true };
    case 'image':
      return { renderer: 'image-zoom', options: {}, previewable: true };
    case 'markdown':
      return { renderer: 'text-markdown', options: { render: 'markdown' }, previewable: true };
    case 'text':
    case 'code':
      return { renderer: 'text-markdown', options: { render: 'plain' }, previewable: true };
    case 'audio':
      return { renderer: 'audio-player', options: { waveform: true }, previewable: true };
    case 'video':
      return { renderer: 'video-player', options: {}, previewable: true };
    case 'latex':
      return { renderer: 'latex-render', options: { formula: true }, previewable: true };
    case 'other':
      // Unsupported formats: kept + downloadable, no native-preview claim.
      return { renderer: 'fallback-download', options: {}, previewable: false };
  }
}

/** Export target formats (ADR S17: sheet -> MD/PDF/DOCX/PNG matrix). */
export type ExportFormat = 'pdf' | 'docx' | 'pptx' | 'xlsx' | 'png' | 'txt' | 'md';

export interface ExportRequest {
  /** the source artifact (or a SolverResult, via a `SourceSpec`) */
  sourceArtifactId?: string;
  /** the source (SolverResult, BOQ, infographic spec, ...) */
  source?: unknown;
  format: ExportFormat;
  /** title / context metadata */
  title?: string;
  /** which job kind to dispatch (AD-8) */
  jobKind: 'artifact_gen';
}

/** Mime types per export format (for the R2 upload contentType). */
export const EXPORT_MIME: Record<ExportFormat, string> = {
  pdf: 'application/pdf',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  pptx: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  png: 'image/png',
  txt: 'text/plain',
  md: 'text/markdown',
};

/** Pick the best export format for a given source. */
export function pickExportFormat(source: unknown): ExportFormat {
  if (typeof source === 'string') return 'txt';
  if (Array.isArray(source)) return 'xlsx';
  if (source && typeof source === 'object' && 'solverId' in source) {
    // SolverResult -> PDF (with diagrams + explanation, ADR S17).
    return 'pdf';
  }
  return 'pdf';
}

/**
 * A previewable artifact — the hub UI shows the renderer contract.
 * For `other`, the hub shows "download" (never a broken viewer).
 */
export function isPreviewable(artifact: Artifact): boolean {
  return artifact.previewable;
}

/** Build an ArtifactFile row behind a hub entry. */
export function makeArtifactFile(
  artifactId: string,
  r2Key: string,
  sizeBytes: number,
  mime?: string,
  viewer?: string,
): Omit<ArtifactFile, 'id' | 'userId' | 'createdAt' | 'updatedAt'> {
  return { artifactId, r2Key, sizeBytes, mime, viewer };
}
