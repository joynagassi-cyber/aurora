// fn-integrations — Composio IntegrationProvider seam (composio.md S33-35,
// AD-1 vendor isolation, AD-3: server-side only, no device keys).
//
// The device NEVER holds Composio tokens or its own app OAuth credentials:
// every connected-account state + tool execution runs server-side here,
// scoped per-user (integrations_state SSoT, AD-7 single-writer).
//
// The `ComposioIntegrationProvider` adapter is runtime-agnostic (it accepts
// an explicit key/baseURL so this Deno EF reads from the server secret
// store — AD-3 — instead of `process.env`).
//
// Endpoints (POST, authenticated by the user JWT like every other EF):
//  { verb: 'discover_tools', app?, limit? }
//  { verb: 'list_accounts' }
//  { verb: 'execute_tool', toolId, input, idempotencyKey? }
//  { verb: 'connect', app }  → returns the Composio Connect Link (composio.md §4:
//      the user completes OAuth in the link; the token stays in Composio,
//      never in Aurora — we do NOT build our own provider OAuth flow).

import { ok, err } from "../_shared/envelope.ts";
import {
  createIntegrationProvider,
  type ComposioTool,
} from "../../../packages/integrations/src/composio.ts";

function provider() {
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
        "COMPOSIO_API_KEY is not set on this deployment (OQ-03). " +
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
        const toolId = String(body.toolId ?? "");
        if (!toolId) return err("integrations/missing_tool", "toolId is required", 400);
        // Discover the tool definition (we never trust a device-supplied
        // schema — AD-11 provenance: the catalog is the SSoT).
        const catalog = await p.discoverTools(userId, { limit: 500 });
        const tool = catalog.find((t) => t.toolId === toolId);
        if (!tool) {
          return err("integrations/unknown_tool", `tool "${toolId}" not in the catalog`, 404);
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
        // composio.md §4: the connect flow is the vendor's own Connect Link.
        // The user completes OAuth in their browser; the token stays in
        // Composio, never in Aurora (we do NOT build a provider OAuth
        // flow). Without a live Composio key we cannot issue the link —
        // report the degraded state rather than fabricate one.
        const app = String(body.app ?? "");
        if (!app) return err("integrations/missing_app", "app is required", 400);
        return ok({
          connectLink: null,
          app,
          note: "Connect flow pending a live COMPOSIO_API_KEY (OQ-03). " +
            "The user's OAuth + token stay in Composio (AD-3).",
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
