// fn-import-course — 01 §5.1 contract:
//   IN  { courseId, fileRefs[] }
//   OUT 202 { ok, data: { jobId } }  → CourseImported after OCR/chunk/embed
// Heavy work is a PERSISTED JOB (AD-8), never done inside the EF.

import { ok, err, ulid } from "../_shared/envelope.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
// Le secret service_role est stocké sous SERVICE_ROLE_KEY (Supabase refuse
// tout nom commençant par SUPABASE_). Les EF lisent SERVICE_ROLE_KEY.
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") ?? "";

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}) as { courseId?: string; fileRefs?: string[] });
    const courseId = body.courseId;
    const fileRefs = body.fileRefs ?? [];

    if (!courseId) return err("course/import_missing_id", "courseId is required", 400);
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      // Secrets are read from env only (never inlined). Wave-0 stub state.
      console.warn("[fn-import-course] SERVICE_ROLE_KEY not configured — cannot enqueue job");
      return err("course/secrets_missing", "Server env not configured", 503);
    }

    // Wave-0 stub: generate the job id + would INSERT into job_queue (kind=ocr/import).
    const jobId = ulid();
    console.log(`[fn-import-course] enqueued import jobId=${jobId} course=${courseId} files=${fileRefs.length}`);

    // 202 Accepted with jobId (01 §5.1)
    return ok({ jobId }, 202);
  } catch (e) {
    console.error("[fn-import-course] error", e);
    return err("course/import_error", String(e), 500);
  }
});
