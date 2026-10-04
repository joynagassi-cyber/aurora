// fn-integrations — Composio IntegrationProvider seam (v3.1, sessions).
//
// Session-based contract (docs.composio.dev/docs/toolkits.md §3):
//   - REST base: https://backend.composio.dev/api/v3.1
//   - Per-user session: POST /sessions { user_id } → session_id
//   - Session tools:    GET  /sessions/{id}/tools → meta-tools
//   - Execute:          POST /sessions/{id}/tools/execute { tool_slug, input }
//
// Auth model (AD-3, composio.md §3/§4):
//   - Device identity comes from the Supabase user JWT (Authorization header),
//     NEVER from the request body (single-writer, AD-7).
//   - The Composio project key is read from the server secret store
//     (`Deno.env.get("COMPOSIO_API_KEY")`) — it is never on the device.
//   - Per-user sessions are cached in-process by the adapter (one session
//     per user, reused across calls — the docs say sessions persist for
//     the application user; a fresh session per call would burn quota).
//
// Endpoints (POST, authenticated by the user JWT like every other EF):
//   { verb: 'discover_tools', app?, limit? }
//   { verb: 'list_accounts' }
//   { verb: 'execute_tool', toolSlug, input, idempotencyKey? }
//   { verb: 'connect', app }  → returns the Composio Connect Link. The
//      user completes OAuth in the link; the token stays in Composio,
//      never in Aurora (we do NOT build our own provider OAuth flow).
//
// Failure mode (composio.md §7): `connect` returns a degraded note when
// the key is not configured; it does not fabricate a link. All other
// verbs return 503 when unconfigured so the UI can show "configure your
// Composio key" instead of a silent empty catalog.

import { ok, err } from "../_shared/envelope.ts";
import {
  createIntegrationProvider,
  type ComposioTool,
  type IntegrationProvider,
} from "../../../packages/integrations/src/composio.ts";

function provider(): IntegrationProvider {
  return createIntegrationProvider(Deno.env.get("COMPOSIO_API_KEY") ?? "");
}

Deno.serve(async (req: Request) => {
  try {
    // user id from the auth header (never trust the body for identity).
    const authHeader = req.headers.get("Authorization") ?? "";
    const match = /Bearer\s+(.+)/.exec(authHeader);
    if (!match?.[1]) return err("integrations/unauthorized", "Bearer token required", 401);
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
    const SUPABASE_SECRET_KEY = Deno.env.get("SUPABASE_SECRET_KEY") ?? "";
    if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) {
      return err("integrations/env", "SUPABASE env not configured", 503);
    }
    const userRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SUPABASE_SECRET_KEY, Authorization: `Bearer ${match[1]}` },
    });
    if (!userRes.ok) return err("integrations/unauthorized", "invalid user token", 401);
    const user = (await userRes.json()) as { id?: string };
    const userId = user.id ?? "unknown";

    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    const verb = String(body.verb ?? "");
    const p = provider();

    if (!p.isConfigured()) {
      return err(
        "integrations/not_configured",
        "COMPOSIO_API_KEY is not set on this deployment. " +
          "Run `supabase secrets set COMPOSIO_API_KEY=…` to enable.",
        503,
      );
    }

    switch (verb) {
      case "discover_tools": {
        const tools: ComposioTool[] = await p.discoverTools(userId, {
          app: body.app ? String(body.app) : undefined,
          limit: body.limit ? Number(body.limit) : 50,
        });
        return ok({ tools });
      }
      case "list_accounts": {
        const accounts = await p.listConnectedAccounts(userId);
        return ok({ accounts });
      }
      case "execute_tool": {
        // v3.1: the tool slug comes from the catalog (we never trust a
        // device-supplied schema — AD-11 provenance: the catalog is the
        // SSoT). The `toolSlug` field is the v3.1 name for `toolId`.
        const toolSlug = String(body.toolSlug ?? body.toolId ?? "");
        if (!toolSlug) return err("integrations/missing_tool", "toolSlug is required", 400);
        const catalog = await p.discoverTools(userId, { limit: 500 });
        const tool = catalog.find((t) => t.toolId === toolSlug);
        if (!tool) {
          return err(
            "integrations/unknown_tool",
            `tool "${toolSlug}" not in the user's session catalog`,
            404,
          );
        }
        const result = await p.executeTool(
          userId,
          tool,
          (body.input as Record<string, unknown>) ?? {},
          { idempotencyKey: body.idempotencyKey ? String(body.idempotencyKey) : undefined },
        );
        return ok({ ...result });
      }
      case "connect": {
        // composio.md §4: the connect flow is the vendor's own Connect
        // Link — the user completes OAuth in their browser; the token
        // stays in Composio, never in Aurora (we do NOT build a
        // provider OAuth flow).
        //
        // In v3.1 the connect link is obtained by calling
        // `COMPOSIO_MANAGE_CONNECTIONS` (a meta-tool) inside the
        // user's session. The adapter's `executeTool` path covers this
        // — but the Connect Link itself is a Composio-provided
        // deep-link that requires a toolkit slug + an auth_config.
        // Until the app-level `auth_config` is provisioned (out of
        // scope for this EF — it's a dashboard setup step), we return
        // a degraded note with the toolkit slug so the UI can show
        // the user what to do.
        const app = String(body.app ?? "");
        if (!app) return err("integrations/missing_app", "app is required", 400);
        return ok({
          connectLink: null,
          app,
          note: "Connect flow is provisioned via a Composio AuthConfig. " +
            "The user's OAuth + token stay in Composio (AD-3). " +
            "Toolkits with managed OAuth (GMAIL, GOOGLECALENDAR, NOTION, …) " +
            "need only the project key; Spotify requires a custom OAuth app " +
            "(no managed OAuth — see docs.composio.dev/toolkits/spotify.md).",
        });
      }
      default:
        return err("integrations/unknown_verb", `unknown verb "${verb}"`, 400);
    }
  } catch (e) {
    console.error("[fn-integrations] error", e);
    return err("integrations/error", e instanceof Error ? e.message : String(e), 500);
  }
});
