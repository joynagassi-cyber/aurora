/**
 * R2 storage layer (docs/artifacts/overview.md §5/§8/§11, AD-3).
 *
 * Private buckets + short-TTL presigned URLs:
 *   - `presignGet` 15 min (01 §5.4)
 *   - `presignUpload` 5 min (01 §5.4)
 *
 * No client-held R2 keys (AD-3): the device only ever sees a presigned
 * URL. The `StoragePort` SSoT (packages/domain) is the contract; this
 * module owns the *spec* + key-naming convention for the artifact
 * upload pipeline (the R2 adapter itself lives in @aurora/integrations).
 */

/** R2 key naming convention (docs/artifacts/overview.md §4: import /
 *  generation flow). All artifact objects are user-scoped. */
export function r2KeyForImport(
  userId: string,
  kind: string,
  filename: string,
): string {
  return `artifacts/imports/${userId}/${kind}/${filename}`;
}

export function r2KeyForGenerated(
  userId: string,
  artifactId: string,
  filename: string,
): string {
  return `artifacts/generated/${userId}/${artifactId}/${filename}`;
}

/** Presign TTLs (01 §5.4): 15 min GET, 5 min PUT. */
export const R2_PRESIGN_TTL_GET_SEC = 15 * 60;
export const R2_PRESIGN_TTL_UPLOAD_SEC = 5 * 60;

export interface R2UploadPlan {
  r2Key: string;
  contentType: string;
  /** the presigned PUT URL the client uploads to directly */
  uploadUrl: string;
  ttlSec: number;
}

/** A minimal R2 presign contract (implemented by the R2 adapter in
 *  @aurora/integrations — AD-1). */
export interface R2StoragePort {
  presignGet(r2Key: string, ttlSec?: number): Promise<string>;
  presignUpload(r2Key: string, contentType: string, ttlSec?: number): Promise<R2UploadPlan>;
  /** confirm an upload actually landed (F-06: event fires ONLY post-upload) */
  head(r2Key: string): Promise<{ sizeBytes: number; contentType?: string }>;
}
