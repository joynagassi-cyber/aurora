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

function safeJson(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

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
        const raw = await res.text();
        const json = (safeJson(raw)) as { users?: Array<Record<string, unknown>> } | null;
        const all = (json?.users ?? []) as Array<Record<string, unknown>>;
        // Preuve brute : nombre total + emails tels que renvoyés par GoTrue
        // (le filtre dev.* passe en second temps) — diagnostique un corps
        // d'API inattendu sans spéculer.
        const rawEmails = all.map((u) => u["email"] ?? null);
        const users = all
          .filter((u) => String(u["email"] ?? "").startsWith("dev.aurora"))
          .map((u) => ({
            id: String(u["id"]),
            email: String(u["email"] ?? ""),
            confirmed: Boolean(u["email_confirmed_at"]),
            hasPassword: String(u["encrypted_password"] ?? "").length > 0,
          }));
        console.log("[fn-dev-auth] list-users", { total: all.length, dev: users.length, status: res.status });
        return Response.json(
          {
            ok: res.ok,
            status: res.status,
            total_users: all.length,
            raw_emails: rawEmails,
            users,
            raw_body: raw.slice(0, 600),
          },
          { headers: corsHeaders },
        );
      }

      case "recreate": {
        // Canonicité GoTrue de bout en bout : création via l'ADMIN API →
        // audience par défaut du projet + hash canonique + identité email,
        // ce que les INSERT bruts SQL ne garantissent pas. « User already
        // registered » = le compte existe déjà (dans une audience fautive)
        // → le nettoyage passe par SQL côté base (ids connus), pas ici.
        const email = String(body["email"] ?? "");
        const password = String(body["password"] ?? "");
        if (!email || !password) {
          return Response.json(
            { ok: false, error: "email + password required" },
            { status: 400, headers: corsHeaders },
          );
        }
        const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${SERVICE_ROLE}`,
            apikey: SERVICE_ROLE,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ email, password, email_confirm: true }),
        });
        const raw = await res.text();
        const json = safeJson(raw) as { user?: { email?: string; aud?: string } } | null;
        console.log("[fn-dev-auth] recreate", { email, status: res.status });
        return Response.json(
          {
            ok: res.ok,
            status: res.status,
            user_email: json?.user?.email ?? null,
            user_aud: json?.user?.aud ?? null,
            raw_body: res.ok ? undefined : raw.slice(0, 300),
          },
          { headers: corsHeaders },
        );
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
        const raw = await res.text();
        const json = safeJson(raw) as
          | { error?: string; error_description?: string; user?: { email?: string } }
          | null;
        // Pas d'access_token renvoyé (AD-3) : sur 200 le corps contient le
        // token — `raw_body` n'est donc joint que sur ÉCHEC (tronqué 400).
        const out = {
          error: json?.error ?? null,
          error_description: json?.error_description ?? null,
          signed_in_user: json?.user?.email ?? null,
          ...(res.ok ? {} : { raw_body: raw.slice(0, 400) }),
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
