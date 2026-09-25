/**
 * Learning module — course import pipeline (wave 2, SAPPHO).
 *
 * Flow (docs/learning/overview.md §2):
 *   camera/PDF capture (device, R2 upload) → `course_import` job →
 *   OCR (`ocr` job) → KB ingestion → `CourseImported` event (AD-9,
 *   producer = Learning; consumers: Knowledge, Discovery, Progress).
 *
 * AD-8: every step here enqueues a persisted idempotent job; nothing
 * blocks the UI. AD-7: this module writes its own tables only.
 */
import type {
  Course,
  JobDispatcherPort,
  JobQueue,
  StoragePort,
} from '@aurora/domain';

/** Where a course file comes from (drives `CourseImported.payload.source`). */
export type CourseImportSource = 'camera' | 'pdf' | 'web' | 'manual' | 'other';

/** The persisted upload the OCR job will read (binaries in R2, AD-3). */
export interface CourseImportUpload {
  courseId: string;
  userId: string;
  /** R2 object key of the captured document */
  r2Key: string;
  contentType: string;
  sizeBytes: number;
  source: CourseImportSource;
  /** course metadata the user supplied at capture time */
  course: Pick<Course, 'title' | 'subjectId' | 'period'> & {
    userId: string;
    tags: string[];
  };
  createdAt: string;
}

/**
 * One step of the import pipeline. Implemented by the server job
 * workers (fn-import-course, 01 S5.1); the module only orchestrates
 * through persisted jobs (AD-8).
 */
export interface CourseImportPipeline {
  /** Upload the capture to R2 (StoragePort, short-lived presigned) and
   *  record the upload row. Idempotent by course + file hash. */
  capture(
    upload: CourseImportUpload,
    body: Uint8Array,
  ): Promise<{ uploadId: string; r2Key: string; sizeBytes: number }>;

  /** Enqueue the `course_import` job (OCR + KB ingestion + event). */
  dispatchImport(
    uploadId: string,
    opts?: { idempotencyKey?: string; sourceLocalMutationId?: string },
  ): Promise<{ jobId: string; status: JobQueue['status'] }>;

  /** Enqueue a standalone `ocr` job for an already-imported document. */
  dispatchOcr(
    uploadId: string,
    opts?: { idempotencyKey?: string },
  ): Promise<{ jobId: string; status: JobQueue['status'] }>;
}

/**
 * Reference pipeline on top of `JobDispatcherPort` + `StoragePort`.
 * Used by the server workers and by unit tests with fake ports.
 */
export class DefaultCourseImportPipeline implements CourseImportPipeline {
  readonly jobs: JobDispatcherPort;
  readonly storage: StoragePort;
  constructor(
    jobs: JobDispatcherPort,
    storage: StoragePort,
  ) {
    this.jobs = jobs;
    this.storage = storage;
  }

  async capture(
    upload: CourseImportUpload,
    body: Uint8Array,
  ): Promise<{ uploadId: string; r2Key: string; sizeBytes: number }> {
    // F-06: binary in R2, metadata in Postgres (the upload row is
    // written by the repository layer, not by this pipeline).
    const r2Key = `courses/${upload.userId}/${upload.courseId}/${r2KeySafe(upload, body.length)}`;
    const stored = await this.storage.upload(upload.courseId, r2Key, body, upload.contentType);
    return { uploadId: `${upload.courseId}:${r2Key}`, r2Key: stored.r2Key, sizeBytes: stored.sizeBytes };
  }

  async dispatchImport(
    uploadId: string,
    opts?: { idempotencyKey?: string; sourceLocalMutationId?: string },
  ): Promise<{ jobId: string; status: JobQueue['status'] }> {
    const [courseId, r2Key] = splitUploadId(uploadId);
    return this.jobs.dispatch({
      jobKind: 'course_import',
      userId: courseId,
      payload: { uploadId, r2Key },
      idempotencyKey: opts?.idempotencyKey ?? `course_import:${uploadId}`,
      sourceLocalMutationId: opts?.sourceLocalMutationId,
    });
  }

  async dispatchOcr(
    uploadId: string,
    opts?: { idempotencyKey?: string },
  ): Promise<{ jobId: string; status: JobQueue['status'] }> {
    const [courseId, r2Key] = splitUploadId(uploadId);
    return this.jobs.dispatch({
      jobKind: 'ocr',
      userId: courseId,
      payload: { uploadId, r2Key },
      idempotencyKey: opts?.idempotencyKey ?? `ocr:${uploadId}`,
    });
  }
}

function splitUploadId(uploadId: string): [string, string] {
  const idx = uploadId.lastIndexOf(':');
  if (idx <= 0) throw new Error(`learning/bad_upload_id: ${uploadId}`);
  return [uploadId.slice(0, idx), uploadId.slice(idx + 1)];
}

function r2KeySafe(upload: CourseImportUpload, sizeBytes: number): string {
  // Deterministic, idempotent key: same capture = same key (AD-8).
  const name = upload.course.title.replace(/[^\p{L}\p{N}]+/gu, '-').replace(/^-|-$/g, '').toLowerCase() || 'document';
  return `${name}-${sizeBytes}.${extFor(upload.contentType)}`;
}

function extFor(contentType: string): string {
  return contentType.includes('pdf') ? 'pdf' : contentType.includes('png') ? 'png' : contentType.includes('jpeg') || contentType.includes('jpg') ? 'jpg' : 'bin';
}
