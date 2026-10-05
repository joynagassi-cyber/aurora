// fn-notifications — 01 §5.1: trigger on `events_history` (Event History) → OneSignal
// (mobile Phase 1), respecting quiet-hours / coaching silence (ADR §13).
//
// Server-state-driven push channel (04 §3.2.5, AD-1, AD-3):
//   - The app holds ONLY the OneSignal *app* key (capacitor.config.ts — AD-3).
//   - The REST API key is server-side (Supabase secret store, AD-3 — never
//     shipped to the device, never committed, CI G2 grep).
//   - OneSignal REST API v2 (onesignal.com/api/notifications) is the native
//     path for a Deno edge function: direct HTTPS, no vendor SDK required.
//
// The MCP OneSignal server is a developer tool (console/dashboard) — it is
// OUT OF SCOPE for a Deno edge function; the REST v2 surface is the
// documented native path here.
//
// Quiet-hours check (notification_preferences.quiet_hours) + coaching
// silence (ADR §13) land in wave 1; the current shape already carries
// `quiet_hours` / `coaching_silence` in the request body (01 §5.1).

import { ok, err } from "../_shared/envelope.ts";

const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";
const ONESIGNAL_REST_ENDPOINT = "https://onesignal.com/api";

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}) as {
      eventType?: string;
      userId?: string;
      push?: OneSignalPushPayload;
    });

    // Stub wave-0: log the trigger + note OneSignal availability.
    // Quiet-hours check (notification_preferences.quiet_hours) lands in wave 1.
    console.log(
      `[fn-notifications] event=${body.eventType ?? "n/a"} user=${body.userId ?? "n/a"} ` +
        `onesignal=${ONESIGNAL_APP_ID ? "configured" : "MISSING"}`,
    );

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      // Degrade properly (AD-1): notifications are an optional capability;
      // the event is still processed, just not pushed. No crash.
      return ok({ delivered: false, reason: "onesignal_not_configured" });
    }

    if (!body.push) {
      // The event is valid but no push payload was provided — skip the send.
      return ok({ delivered: false, reason: "no_push_payload" });
    }

    const res = await fetch(`${ONESIGNAL_REST_ENDPOINT}/notifications`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        ...(body.push.includeExternalUserIds?.length
          ? { include_external_user_ids: body.push.includeExternalUserIds }
          : {}),
        ...(body.push.content ? { content: body.push.content } : {}),
        ...(body.push.head ? { head: body.push.head } : {}),
        ...(body.push.data ? { data: body.push.data } : {}),
      }),
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      console.error(
        `[fn-notifications] OneSignal send failed: ${res.status} ${text}`,
      );
      return err("notification/onesignal_send_failed", text, res.status);
    }

    const sent = await res.json().catch(
      () => ({}) as OneSignalNotificationResponse,
    );
    return ok({
      delivered: true,
      onesignal_notification_id: sent.id,
      event: body.eventType,
    });
  } catch (e) {
    console.error("[fn-notifications] error", e);
    return err("notification/processing_error", String(e), 500);
  }
});

// --- Types (01 §5.1) --------------------------------------------------------

/**
 * OneSignal REST v2 — notification request subset. The native REST surface
 * (onesignal.com/api/notifications) accepts an arbitrary `data` map that
 * lands in the client's `notification.data`; the app's OneSignal plugin
 * reads it for deep-link routing (04 §3.2.5).
 */
interface OneSignalPushPayload {
  /** Target users by Supabase external_id (alias created at onboarding, 01 §5.1). */
  includeExternalUserIds?: string[];
  /** Localized title/body (push `head`). */
  content?: Record<string, string>;
  /** Push head fields (title, icon, sound…). */
  head?: Record<string, unknown>;
  /** Arbitrary payload — deep-link `route`, `category`, `deadlineAt` (04 §3.2.5). */
  data?: Record<string, unknown>;
}

interface OneSignalNotificationResponse {
  /** OneSignal-assigned notification id. */
  id: string;
  [k: string]: unknown;
}
