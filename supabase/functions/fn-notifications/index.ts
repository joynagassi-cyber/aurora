// fn-notifications — 01 §5.1: trigger on `events_history` (Event History) → OneSignal
// (mobile Phase 1), respecting quiet-hours / coaching silence (ADR §13).
//
// Server-state-driven push channel (04 §3.2.5, AD-1, AD-3):
//   - The app holds ONLY the OneSignal *app* key (capacitor.config.ts — AD-3).
//   - The REST API key is server-side (Supabase secret store, AD-3 — never
//     shipped to the device, never committed, CI G2 grep).
//   - OneSignal REST API v2 (spec: docs.onesignal.com — POST /api/v2/{app_id}/notifications)
//     is the native path for a Deno edge function: direct HTTPS, no vendor SDK.
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
// OneSignal REST v2 spec (docs.onesignal.com): POST /api/v2/{app_id}/notifications.
// The app_id is part of the URL path, NOT a body field.
const ONESIGNAL_REST_BASE = "https://onesignal.com/api/v2";

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}) as {
      eventType?: string;
      userId?: string;
      push?: OneSignalPushPayload;
    });

    // Log the trigger + note OneSignal availability.
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

    // OneSignal REST v2 request body — spec: docs.onesignal.com
    //   - `include_external_user_ids`: target users by their external_id
    //     (the Supabase user id, created at onboarding 01 §5.1).
    //   - `headings`: { en: string } — localized title.
    //   - `content`:  { en: string } — localized body.
    //   - `data`:     arbitrary map → lands in client `notification.data`
    //     for deep-link routing (04 §3.2.5: `route`, `category`, …).
    const notification: Record<string, unknown> = {};
    if (body.push.includeExternalUserIds?.length) {
      notification.include_external_user_ids = body.push.includeExternalUserIds;
    }
    if (body.push.headings) notification.headings = body.push.headings;
    if (body.push.content) notification.content = body.push.content;
    if (body.push.data) notification.data = body.push.data;

    const res = await fetch(
      `${ONESIGNAL_REST_BASE}/${ONESIGNAL_APP_ID}/notifications`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
        },
        body: JSON.stringify(notification),
      },
    );

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
 * OneSignal REST v2 — notification request subset.
 * Spec: docs.onesignal.com/api/ — the `data` map lands in the client's
 * `notification.data`; the app's OneSignal plugin reads it for deep-link
 * routing (04 §3.2.5).
 */
interface OneSignalPushPayload {
  /** Target users by Supabase external_id (alias created at onboarding, 01 §5.1). */
  includeExternalUserIds?: string[];
  /** Localized push title — OneSignal REST v2 field: `headings` ({ en: "…" }). */
  headings?: Record<string, string>;
  /** Localized push body — OneSignal REST v2 field: `content` ({ en: "…" }). */
  content?: Record<string, string>;
  /** Arbitrary payload — deep-link `route`, `category`, `deadlineAt` (04 §3.2.5). */
  data?: Record<string, unknown>;
}

interface OneSignalNotificationResponse {
  /** OneSignal-assigned notification id. */
  id: string;
  [k: string]: unknown;
}
