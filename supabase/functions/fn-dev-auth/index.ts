// fn-dev-auth — DEV-ONLY (P1-4/P1-5, 10-07) — SUPPRIMER AVANT v1.0.
//
// Repaire et diagnostique les 2 comptes dev Auth sans deviner le format de
// hash GoTrue : la réécriture passe par l'ADMIN API (`service_role`, serveur
// uniquement — AD-3), qui applique le hashage canonique de GoTrue lui-même.
//
// Actions (POST JSON) :
//   { "action": "list-users" }                     → les users dev.* (id/email/confirmé/hash présent)
//   { "action": "set-password", user_id, password } → PATCH admin /auth/v1/admin/users/{id}
//   { "action": "test-signin", email, password }    → POST /auth/v1/token?grant_type=password (anon)
//                                                      → statut + corps GoTrue VERBATIM (sans access_token — AD-3)
//
// Invocation client : URL complète hardcodée, header `apikey` = publishable
// key (EF déployées avec verify_jwt=false — le scope sensible reste côté
// service_role dans l'EF, jamais sur device).

import { serve } from "https://deno.land/std@0.190.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({} as Record<string, unknown>));
    const action = String(body["action"] ?? "");

    switch (action) {
      case "list-users": {
        const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?per_page=50`, {
          headers: { Authorization: `Bearer ${SERVICE_ROLE}`, apikey: SERVICE_ROLE },
        });
        const json = (await res.json().catch(() => null)) as
          | { users?: Array<Record<string, unknown>> }
          | null;
        const users = ((json?.users ?? []) as Array<Record<string, unknown>>)
          .filter((u) => String(u["email"] ?? "").startsWith("dev.aurora"))
          .map((u) => ({
            id: String(u["id"]),
            email: String(u["email"] ?? ""),
            confirmed: Boolean(u["email_confirmed_at"]),
            hasPassword: String(u["encrypted_password"] ?? "").length > 0,
          }));
        console.log("[fn-dev-auth] list-users", { count: users.length, status: res.status });
        return Response.json({ ok: res.ok, status: res.status, users }, { headers: corsHeaders });
      }

      case "set-password": {
        const user_id = String(body["user_id"] ?? "");
        const password = String(body["password"] ?? "");
        if (!user_id || !password) {
          return Response.json(
            { ok: false, error: "user_id + password required" },
            { status: 400, headers: corsHeaders },
          );
        }
        const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${user_id}`, {
          method: "PATCH",
          headers: {
            Authorization: `Bearer ${SERVICE_ROLE}`,
            apikey: SERVICE_ROLE,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ password }),
        });
        const json = await res.json().catch(() => null);
        // Ne jamais renvoyer le hash brut au client (AD-3, hygiène dev).
        const out = json && typeof json === "object" && "user" in json
          ? { user_email: String((json as { user?: { email?: string } }).user?.email ?? "") }
          : json;
        console.log("[fn-dev-auth] set-password", { user_id, status: res.status });
        return Response.json({ ok: res.ok, status: res.status, result: out }, { headers: corsHeaders });
      }

      case "test-signin": {
        const email = String(body["email"] ?? "");
        const password = String(body["password"] ?? "");
        if (!email || !password) {
          return Response.json(
            { ok: false, error: "email + password required" },
            { status: 400, headers: corsHeaders },
          );
        }
        const res = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
          method: "POST",
          headers: { "Content-Type": "application/json", apikey: ANON_KEY },
          body: JSON.stringify({ email, password }),
        });
        const json = (await res.json().catch(() => null)) as
          | { error?: string; error_description?: string; user?: { email?: string } }
          | null;
        // Pas d'access_token renvoyé (AD-3) — statut + messages GoTrue verbatim.
        const out = {
          error: json?.error ?? null,
          error_description: json?.error_description ?? null,
          signed_in_user: json?.user?.email ?? null,
        };
        console.log("[fn-dev-auth] test-signin", { email, status: res.status, error: json?.error });
        return Response.json({ ok: res.ok, status: res.status, result: out }, { headers: corsHeaders });
      }

      default:
        return Response.json(
          { ok: false, error: `unknown action: ${action}` },
          { status: 400, headers: corsHeaders },
        );
    }
  } catch (e) {
    console.error("[fn-dev-auth] unhandled error", e);
    return Response.json(
      { ok: false, error: e instanceof Error ? e.message : String(e) },
      { status: 500, headers: corsHeaders },
    );
  }
});
