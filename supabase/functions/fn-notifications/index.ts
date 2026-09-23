// fn-notifications — 01 §5.1: trigger on `events` (Event History) → OneSignal
// (mobile Phase 1), respecting quiet-hours / coaching silence (ADR §13).

import { ok, err } from "../_shared/envelope.ts";

const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}) as { eventType?: string; userId?: string });

    // Stub wave-0: log the trigger + note OneSignal availability.
    // Quiet-hours check (notification_preferences.quiet_hours) lands in wave 1.
    console.log(
      `[fn-notifications] event=${body.eventType ?? "n/a"} user=${body.userId ?? "n/a"} ` +
      `onesignal=${ONESIGNAL_APP_ID ? "configured" : "MISSING"}`,
    );

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      // Degrade properly (AD-1): notifications are an optional capability; the
      // event is still processed, just not pushed. No crash.
      return ok({ delivered: false, reason: "onesignal_not_configured" });
    }

    return ok({ delivered: false, reason: "wave0_stub" });
  } catch (e) {
    console.error("[fn-notifications] error", e);
    return err("notification/processing_error", String(e), 500);
  }
});
