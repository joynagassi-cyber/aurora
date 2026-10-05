// fn-skills — the Skills Marketplace seam (Task 1, 2026-10-04).
//
// Two tables (migration 0019):
//   skill_catalog : global, public-read curated catalog. The mobile app
//                   reads it via the publishable scope (no service key on
//                   the device, AD-3); the Aurora team curates it via
//                   service_role. This EF never writes skill_catalog.
//   user_skills   : per-user activated skills. RLS-isolated (AD-7
//                   single-writer = the skills module). The EF writes it via
//                   the service key (REST), so the device only ever sees its
//                   own rows through the user JWT.
//
// Auth model (AD-7): the user identity comes from the Supabase JWT
// (Authorization: Bearer header), NEVER from the request body.
//
// Endpoints (POST, { verb, ... } — same shape as fn-integrations):
//   { verb: 'list_catalog', domain? }   — public (no user JWT needed, AD-3)
//   { verb: 'list_user_skills' }        — user JWT required
//   { verb: 'activate_skill', skillKey }
//   { verb: 'deactivate_skill', skillKey }
//   { verb: 'create_user_skill', name, domain, trigger_?, objective?, ... }
//   { verb: 'delete_user_skill', skillKey }
//
// Response: { ok: true, data: { ... } } (envelope.ts ApiEnvelope).

import { ok, err, ulid } from "../_shared/envelope.ts";

type CatalogRow = {
  skill_key: string;
  domain: string;
  name: string;
  trigger_: string | null;
  objective: string | null;
  procedure: string[];
  constraints: string[];
  tools: string[];
  source: string;
  description: string | null;
  /** Markdown SKILL.md body (0021 marketplace seed). null for builtin. */
  body: string | null;
};

type UserSkillRow = {
  id: string;
  user_id: string;
  skill_key: string;
  domain: string;
  name: string;
  trigger_: string | null;
  objective: string | null;
  procedure: string[];
  constraints: string[];
  tools: string[];
  source: string;
  active: boolean;
  /** Markdown body copied from the catalog at activation (0021). */
  body: string | null;
  created_at: string;
  updated_at: string;
};

async function rest(
  method: string,
  path: string,
  qs: string,
  body: unknown,
  supabaseUrl: string,
  serviceKey: string,
): Promise<{ ok: boolean; status: number; json: unknown; error?: string }> {
  // Legacy service_role JWT ("eyJ...") = apikey + Authorization headers;
  // new "sb_secret_..." key = apikey header only (Supabase rejects it on
  // Authorization as "Invalid JWT").
  const isLegacyJwt = serviceKey.startsWith("eyJ");
  const headers: Record<string, string> = {
    apikey: serviceKey,
    "Content-Type": "application/json",
  };
  if (isLegacyJwt) {
    headers.Authorization = "Bearer " + serviceKey;
  }
  const res = await fetch(supabaseUrl + path + qs, {
    method: method,
    headers: headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  let json: unknown = {};
  try {
    json = await res.json();
  } catch {
    json = {};
  }
  const out: { ok: boolean; status: number; json: unknown; error?: string } = {
    ok: res.ok,
    status: res.status,
    json: json,
  };
  if (!res.ok) {
    out.error = JSON.stringify(json);
  }
  return out;
}

async function readBody(req: Request): Promise<Record<string, unknown>> {
  try {
    return (await req.json()) as Record<string, unknown>;
  } catch {
    return {};
  }
}

async function resolveUserId(bearer: string, supabaseUrl: string, serviceKey: string): Promise<string | null> {
  // /auth/v1/user always expects a real user JWT on Authorization; the
  // service key only goes on apikey here.
  const userRes = await fetch(supabaseUrl + "/auth/v1/user", {
    headers: {
      apikey: serviceKey,
      Authorization: "Bearer " + bearer,
    },
  });
  if (!userRes.ok) {
    return null;
  }
  const userObj = await userRes.json();
  return userObj.id ?? "unknown";
}

async function handleActivate(
  body: Record<string, unknown>,
  userId: string,
  supabaseUrl: string,
  serviceKey: string,
): Promise<Response> {
  const skillKey = String(body.skillKey ?? "");
  if (!skillKey) {
    return err("skills/missing_skill_key", "skillKey is required", 400);
  }
  // AD-7/AD-11: for a catalog key the payload comes from the CATALOG, not the
  // request body. Legacy UI keys are 'builtin:<key>' (stripped here); the 0021
  // marketplace seed keys ARE the catalog keys themselves ('marketplace:<key>')
  // — no prefix stripping needed, they match 1:1.
  const stripped = skillKey.replace(/^builtin:/, "");
  const catQs = "?skill_key=eq." + encodeURIComponent(stripped);
  const catRes = await rest("GET", "/rest/v1/skill_catalog", catQs, undefined, supabaseUrl, serviceKey);
  let payload: Record<string, unknown>;
  if (catRes.ok && Array.isArray(catRes.json) && catRes.json.length > 0) {
    const catRow = catRes.json[0] as Record<string, unknown>;
    payload = {
      user_id: userId,
      skill_key: skillKey,
      domain: String(catRow.domain ?? "documents"),
      name: String(catRow.name ?? skillKey),
      trigger_: (catRow.trigger_ as string | null) ?? null,
      objective: (catRow.objective as string | null) ?? null,
      procedure: Array.isArray(catRow.procedure) ? catRow.procedure : [],
      constraints: Array.isArray(catRow.constraints) ? catRow.constraints : [],
      tools: Array.isArray(catRow.tools) ? catRow.tools : [],
      source: String(catRow.source ?? "builtin"),
      active: true,
      body: (catRow.body as string | null) ?? null,
    };
  } else {
    payload = {
      user_id: userId,
      skill_key: skillKey,
      domain: String(body.domain ?? "documents"),
      name: String(body.name ?? skillKey),
      trigger_: body.trigger_ != null ? String(body.trigger_) : null,
      objective: body.objective != null ? String(body.objective) : null,
      procedure: Array.isArray(body.procedure) ? body.procedure : [],
      constraints: Array.isArray(body.constraints) ? body.constraints : [],
      tools: Array.isArray(body.tools) ? body.tools : [],
      source: String(body.source ?? "user-created"),
      active: true,
      // Personal (non-catalog) skills are prompt-only: no markdown body.
      body: null,
    };
  }
  const upsertQs = "?on_conflict=user_id,skill_key";
  const r = await rest("POST", "/rest/v1/user_skills", upsertQs, payload, supabaseUrl, serviceKey);
  if (!r.ok) {
    return err("skills/activate_failed", "activate failed: " + (r.error ?? String(r.status)), 502);
  }
  return ok({ activated: skillKey });
}

async function handleDeactivate(
  body: Record<string, unknown>,
  userId: string,
  supabaseUrl: string,
  serviceKey: string,
): Promise<Response> {
  const skillKey = String(body.skillKey ?? "");
  if (!skillKey) {
    return err("skills/missing_skill_key", "skillKey is required", 400);
  }
  const payload: Record<string, unknown> = { user_id: userId, skill_key: skillKey, active: false };
  const upsertQs = "?on_conflict=user_id,skill_key";
  const r = await rest("POST", "/rest/v1/user_skills", upsertQs, payload, supabaseUrl, serviceKey);
  if (!r.ok) {
    return err("skills/deactivate_failed", "deactivate failed: " + (r.error ?? String(r.status)), 502);
  }
  return ok({ deactivated: skillKey });
}

async function handleCreate(
  body: Record<string, unknown>,
  userId: string,
  supabaseUrl: string,
  serviceKey: string,
): Promise<Response> {
  const name = String(body.name ?? "").trim();
  if (!name) {
    return err("skills/missing_name", "name is required", 400);
  }
  const domain = String(body.domain ?? "documents");
  const key = "user:" + ulid().toLowerCase();
  const payload: Record<string, unknown> = {
    user_id: userId,
    skill_key: key,
    domain: domain,
    name: name,
    trigger_: body.trigger_ != null ? String(body.trigger_) : null,
    objective: body.objective != null ? String(body.objective) : null,
    procedure: Array.isArray(body.procedure) ? body.procedure : [],
    constraints: Array.isArray(body.constraints) ? body.constraints : [],
    tools: Array.isArray(body.tools) ? body.tools : [],
    source: "user-created",
    active: true,
  };
  const r = await rest("POST", "/rest/v1/user_skills", "", payload, supabaseUrl, serviceKey);
  if (!r.ok) {
    return err("skills/create_failed", "create failed: " + (r.error ?? String(r.status)), 502);
  }
  return ok({ created: key });
}

async function handleDelete(
  body: Record<string, unknown>,
  userId: string,
  supabaseUrl: string,
  serviceKey: string,
): Promise<Response> {
  const skillKey = String(body.skillKey ?? "");
  if (!skillKey) {
    return err("skills/missing_skill_key", "skillKey is required", 400);
  }
  if (!skillKey.startsWith("user:")) {
    const payload: Record<string, unknown> = { user_id: userId, skill_key: skillKey, active: false };
    const upsertQs = "?on_conflict=user_id,skill_key";
    const r = await rest("POST", "/rest/v1/user_skills", upsertQs, payload, supabaseUrl, serviceKey);
    if (!r.ok) {
      return err("skills/deactivate_failed", "deactivate failed: " + (r.error ?? String(r.status)), 502);
    }
    return ok({ deactivated: skillKey, note: "builtin skills are deactivated, not deleted" });
  }
  const qs =
    "?user_id=eq." + encodeURIComponent(userId) +
    "&skill_key=eq." + encodeURIComponent(skillKey);
  const r = await rest("DELETE", "/rest/v1/user_skills", qs, undefined, supabaseUrl, serviceKey);
  if (!r.ok) {
    return err("skills/delete_failed", "delete failed: " + (r.error ?? String(r.status)), 502);
  }
  return ok({ deleted: skillKey });
}

async function listCatalog(serviceKey: string, supabaseUrl: string, domainFilter: string | null): Promise<Response> {
  const qs = domainFilter != null ? "?domain=eq." + encodeURIComponent(domainFilter) : "";
  const r = await rest("GET", "/rest/v1/skill_catalog", qs, undefined, supabaseUrl, serviceKey);
  if (!r.ok) {
    return err("skills/catalog_failed", "skill_catalog read failed: " + (r.error ?? String(r.status)), 502);
  }
  return ok({ catalog: r.json as unknown as CatalogRow[] });
}

async function listUserSkills(userId: string, serviceKey: string, supabaseUrl: string): Promise<Response> {
  const qs = "?user_id=eq." + encodeURIComponent(userId) + "&order=created_at.desc";
  const r = await rest("GET", "/rest/v1/user_skills", qs, undefined, supabaseUrl, serviceKey);
  if (!r.ok) {
    return err("skills/user_skills_failed", "user_skills read failed: " + (r.error ?? String(r.status)), 502);
  }
  return ok({ skills: r.json as unknown as UserSkillRow[] });
}

Deno.serve(async (req: Request) => {
  try {
    const rawAuth = req.headers.get("Authorization") ?? "";
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
    // fn-agent-bootstrap reads SUPABASE_SECRET_KEY; this EF reads
    // SUPABASE_SERVICE_KEY. Fall back to SUPABASE_SECRET_KEY so a single
    // env var suffices in most setups.
    const SUPABASE_SERVICE_KEY =
      Deno.env.get("SUPABASE_SERVICE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY") ?? "";

    const body = await readBody(req);
    const verb = String(body.verb ?? "");

    // — Public, read-only verb (AD-3: the mobile app's catalog browsing, no
    //    user JWT required). Anything that touches user_skills still needs a
    //    real user token.
    if (verb === "list_catalog") {
      // Honest degraded state (AD-1: fail visibly, never fake it): when the
      // project's EF secret is not configured yet, the EF cannot read the
      // catalog with a service key — it says so plainly instead of 503-ing.
      if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
        return ok({
          catalog: [],
          degraded: true,
          note:
            "SUPABASE env not configured on the EF — set the project's SUPABASE_SECRET_KEY " +
            "secret (Dashboard > Edge Functions > Secrets, or `supabase secrets set " +
            "SUPABASE_SECRET_KEY=...`); no redeploy needed, it takes effect immediately.",
        });
      }
      const domainFilter = body.domain != null ? String(body.domain) : null;
      return listCatalog(SUPABASE_SERVICE_KEY, SUPABASE_URL, domainFilter);
    }

    // — Authed verbs (AD-7: identity from the Bearer user JWT) —
    const bearer = /Bearer\s+(.+)/.exec(rawAuth)?.[1] ?? "";
    if (!bearer) {
      return err("skills/unauthorized", "Bearer user token required", 401);
    }
    if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
      return err(
        "skills/env",
        "SUPABASE env not configured — set the project's SUPABASE_SECRET_KEY secret (Dashboard > Edge Functions > Secrets)",
        503,
      );
    }
    const userId = await resolveUserId(bearer, SUPABASE_URL, SUPABASE_SERVICE_KEY);
    if (!userId) {
      return err("skills/unauthorized", "invalid user token", 401);
    }

    switch (verb) {
      case "list_user_skills":
        return listUserSkills(userId, SUPABASE_SERVICE_KEY, SUPABASE_URL);
      case "activate_skill":
        return handleActivate(body, userId, SUPABASE_URL, SUPABASE_SERVICE_KEY);
      case "deactivate_skill":
        return handleDeactivate(body, userId, SUPABASE_URL, SUPABASE_SERVICE_KEY);
      case "create_user_skill":
        return handleCreate(body, userId, SUPABASE_URL, SUPABASE_SERVICE_KEY);
      case "delete_user_skill":
        return handleDelete(body, userId, SUPABASE_URL, SUPABASE_SERVICE_KEY);
      default:
        return err("skills/unknown_verb", 'unknown verb "' + verb + '"', 400);
    }
  } catch (e) {
    console.error("[fn-skills] error", e);
    const msg = e instanceof Error ? e.message : String(e);
    return err("skills/error", msg, 500);
  }
});
