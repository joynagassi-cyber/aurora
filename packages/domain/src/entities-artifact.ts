/**
 * Artifact entities (AD-15 SSoT, 01 S4.6, ADR S16).
 * Artifact Hub = unified representation of PDF/DOCX/PPTX/XLSX/images/
 * audio/video/etc. Binaries live in R2 buckets (private + presigned URLs,
 * AD-3/AD-16); `Artifact` rows carry metadata + r2_key only.
 * `ArtifactGenerated` fires AFTER the R2 upload (F-06).
 */
import type { OrSetValue } from './crdt';

export interface Artifact {
  id: string;
  userId: string;
  /** file kind (ADR S16 universal visualization) */
  kind:
    | 'pdf'
    | 'docx'
    | 'pptx'
    | 'xlsx'
    | 'csv'
    | 'image'
    | 'audio'
    | 'video'
    | 'markdown'
    | 'text'
    | 'code'
    | 'latex'
    | 'other';
  title: string;
  /** R2 object key (binaries never in SQLite; 01 S4.6) */
  r2Key: string;
  sizeBytes: number;
  mime?: string;
  /** whether Aurora generated it (vs imported) — drives ArtifactHub
   *  metadata: source, task, generation context (ADR S16) */
  generated: boolean;
  /** the task / context that produced it, if Aurora-generated */
  sourceTaskId?: string;
  /** provenance */
  sourceIds: OrSetValue[]; // CRDT list
  /** the job that generated it (ties to JobCompleted) */
  jobId?: string;
  /** preview support (ADR S16: stored + downloadable, no native-preview
   *  claim for unsupported formats) */
  previewable: boolean;
  createdAt: string;
  updatedAt: string;
}

/** A physical file record behind an Artifact (01 S4.6 `artifact_files`). */
export interface ArtifactFile {
  id: string;
  userId: string;
  artifactId: string;
  r2Key: string;
  sizeBytes: number;
  mime?: string;
  /** which viewer / renderer applies (ADR S10 renderer contracts, AD-10) */
  viewer?: string;
  createdAt: string;
  updatedAt: string;
}
