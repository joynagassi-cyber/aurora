// fn-canvas — le module Canvas est le single-writer des tables canvas_* (0022, AD-7).
//
// Deux accès, même SSoT markdown par bloc :
//   - L'humain écrit via le client device (publishable-key, RLS user, canvas-client.ts).
//   - L'agent écrit via le kernel : le kernel ÉMET les commandes canvas.read /
//     canvas.write / canvas.comment (AD-7 thin commands, pas de write direct), et
//     c'est CET endpoint qui les applique (module Canvas = le seul à muter la table).
//
// Auth model (AD-7) : l'identité vient du JWT Supabase (Authorization Bearer),
// JAMAIS du body. L'EF écrit via la service key (REST) ; le scope user est porté
// par le JWT (user_id = auth.uid()), pas par un paramètre.
//
// Endpoints (POST { verb, ... } — même shape que fn-skills / fn-integrations) :
//   { verb: 'read',    canvasId, includeComments? }
//        -> { ok, data: { session, comments } }   (canvas.read)
//   { verb: 'write',   canvasId, blockId?, markdown }
//        -> { ok, data: { canvasId, blockCount } } (canvas.write)
//        - blockId présent : remplace le bloc ciblé ; absent : ajoute un bloc.
//   { verb: 'comment', canvasId, replyToCommentId?, body, anchorStart?, anchorEnd? }
//        -> { ok, data: { commentId } }            (canvas.comment)
//        - replyToCommentId présent : ancage hérité du commentaire parent
//          (réponse) ; sinon l'ancage est fourni par le caller (anchorStart/End)
//          ou par défaut tout le texte plat de la session.

import { ok, err, ulid } from "../_shared/envelope.ts";

type Block = { id: string; kind: string; content: string };

async function rest(
  method: string,
  path: string,
  qs: string,
  body: unknown,
  supabaseUrl: string,
  serviceKey: string,
): Promise<{ ok: boolean; status: number; json: unknown; error?: string }> {
  const isLegacyJwt = serviceKey.startsWith("eyJ");
  const headers: Record<string, string> = {
    apikey: serviceKey,
    "Content-Type": "application/json",
  };
  if (isLegacyJwt) {
    headers.Authorization = "Bearer " + serviceKey;
  }
  const res = await fetch(supabaseUrl + path + qs, {
    method,
    headers,
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
    json,
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
  // /auth/v1/user attend un vrai user JWT sur Authorization ; la service key
  // ne passe que sur apikey ici (fn-skills, même pattern).
  const userRes = await fetch(supabaseUrl + "/auth/v1/user", {
    headers: {
      apikey: serviceKey,
      Authorization: "Bearer " + bearer,
    },
  });
  if (!userRes.ok) {
    return null;
  }
  const userObj = (await userRes.json()) as { id?: string };
  return userObj.id ?? null;
}

/** canvas.read — lire la session (blocs + commentaires). READ-ONLY. */
async function handleRead(
  body: Record<string, unknown>,
  userId: string,
  supabaseUrl: string,
  serviceKey: string,
): Promise<Response> {
  const canvasId = String(body.canvasId ?? "");
  if (!canvasId) {
    return err("canvas/missing_canvas_id", "canvasId is required", 400);
  }
  const includeComments = body.includeComments !== false; // défaut = true
  const qs =
    "?id=eq." + encodeURIComponent(canvasId) + "&user_id=eq." + encodeURIComponent(userId);
  const sRes = await rest("GET", "/rest/v1/canvas_sessions", qs, undefined, supabaseUrl, serviceKey);
  if (!sRes.ok) {
    return err("canvas/read_failed", "canvas read failed: " + (sRes.error ?? String(sRes.status)), 502);
  }
  const rows = (sRes.json as unknown) as Array<Record<string, unknown>>;
  const session = Array.isArray(rows) ? rows[0] ?? null : null;
  let comments: unknown[] = [];
  if (includeComments && session) {
    const cQs =
      "?session_id=eq." + encodeURIComponent(canvasId) +
      "&user_id=eq." + encodeURIComponent(userId) +
      "&order=created_at.asc";
    const cRes = await rest("GET", "/rest/v1/canvas_comments", cQs, undefined, supabaseUrl, serviceKey);
    if (cRes.ok) {
      const cRows = (cRes.json as unknown) as Array<Record<string, unknown>>;
      comments = Array.isArray(cRows) ? cRows : [];
    }
  }
  // Absence de row = état vide honnête (AD-7), pas une erreur : session null.
  return ok({ session, comments });
}

/**
 * canvas.write — écrit / remplace un bloc markdown. blockId absent = ajout.
 * L'agent propose, le module applique (AD-7). La mutation porte les blocs
 * complets (jsonb) — on patche la liste, pas une cell, pour rester borné.
 */
async function handleWrite(
  body: Record<string, unknown>,
  userId: string,
  supabaseUrl: string,
  serviceKey: string,
): Promise<Response> {
  const canvasId = String(body.canvasId ?? "");
  const markdown = body.markdown != null ? String(body.markdown) : "";
  const blockId = body.blockId != null ? String(body.blockId) : "";
  if (!canvasId || !markdown) {
    return err("canvas/missing_write_payload", "canvasId + markdown are required", 400);
  }
  // 1. lire l'état courant (borné user par RLS service-role ? non : on filtre user_id).
  const readQs =
    "?id=eq." + encodeURIComponent(canvasId) + "&user_id=eq." + encodeURIComponent(userId);
  const sRes = await rest("GET", "/rest/v1/canvas_sessions", readQs, undefined, supabaseUrl, serviceKey);
  if (!sRes.ok) {
    return err("canvas/read_failed", "canvas read failed: " + (sRes.error ?? String(sRes.status)), 502);
  }
  const sRows = (sRes.json as unknown) as Array<Record<string, unknown>>;
  const session = Array.isArray(sRows) ? sRows[0] : undefined;
  if (!session) {
    return err("canvas/not_found", "canvas session not found (or not yours)", 404);
  }
  const blocks: Block[] = Array.isArray(session.blocks) ? (session.blocks as Block[]) : [];
  let nextBlocks: Block[];
  if (blockId) {
    const idx = blocks.findIndex((b) => b.id === blockId);
    nextBlocks = [...blocks];
    if (idx >= 0) {
      nextBlocks[idx] = { id: blockId, kind: nextBlocks[idx].kind ?? "md", content: markdown };
    } else {
      nextBlocks.push({ id: blockId, kind: "md", content: markdown });
    }
  } else {
    nextBlocks = [...blocks, { id: "b-" + ulid().toLowerCase(), kind: "md", content: markdown }];
  }
  const updQs =
    "?id=eq." + encodeURIComponent(canvasId) + "&user_id=eq." + encodeURIComponent(userId);
  const uRes = await rest("PATCH", "/rest/v1/canvas_sessions", updQs, { blocks: nextBlocks }, supabaseUrl, serviceKey);
  if (!uRes.ok) {
    return err("canvas/write_failed", "canvas write failed: " + (uRes.error ?? String(uRes.status)), 502);
  }
  return ok({ canvasId, blockCount: nextBlocks.length, replaced: blockId !== "" });
}

/**
 * canvas.comment — crée / répond à un commentaire ancré.
 * replyToCommentId présent = réponse (ancage hérité du parent) ; sinon
 * l'ancage est porté par le caller (anchorStart/anchorEnd) ou par défaut
 * tout le texte plat de la session.
 */
async function handleComment(
  body: Record<string, unknown>,
  userId: string,
  supabaseUrl: string,
  serviceKey: string,
): Promise<Response> {
  const canvasId = String(body.canvasId ?? "");
  const replyToCommentId = body.replyToCommentId != null ? String(body.replyToCommentId) : "";
  const bodyText = body.body != null ? String(body.body) : "";
  if (!canvasId || !bodyText) {
    return err("canvas/missing_comment_payload", "canvasId + body are required", 400);
  }
  let start: number;
  let end: number;
  if (replyToCommentId) {
    // Réponse : on hérite de l'ancage du commentaire parent.
    const pQs =
      "?id=eq." + encodeURIComponent(replyToCommentId) +
      "&user_id=eq." + encodeURIComponent(userId);
    const pRes = await rest("GET", "/rest/v1/canvas_comments", pQs, undefined, supabaseUrl, serviceKey);
    if (!pRes.ok) {
      return err("canvas/parent_not_found", "reply parent not found: " + (pRes.error ?? ""), 404);
    }
    const pRows = (pRes.json as unknown) as Array<Record<string, unknown>>;
    const parent = Array.isArray(pRows) ? pRows[0] : undefined;
    if (!parent) {
      return err("canvas/parent_not_found", "reply parent comment not found", 404);
    }
    start = Number(parent.anchor_start ?? 0);
    end = Number(parent.anchor_end ?? 0);
  } else {
    start = body.anchorStart != null ? Number(body.anchorStart) : 0;
    end = body.anchorEnd != null ? Number(body.anchorEnd) : 0;
    if (end < start) {
      // Ancage incohérent : on borne à la session (offsets sûrs).
      return err("canvas/bad_anchor", "anchorEnd must be >= anchorStart", 400);
    }
  }
  const insQs = "";
  const iRes = await rest(
    "POST",
    "/rest/v1/canvas_comments",
    insQs,
    {
      user_id: userId,
      session_id: canvasId,
      anchor_start: start,
      anchor_end: end,
      body: bodyText,
    },
    supabaseUrl,
    serviceKey,
  );
  if (!iRes.ok) {
    return err("canvas/comment_failed", "comment insert failed: " + (iRes.error ?? String(iRes.status)), 502);
  }
  const iRows = (iRes.json as unknown) as Array<Record<string, unknown>>;
  const commentId = Array.isArray(iRows) ? String(iRows[0]?.id ?? "") : "";
  return ok({ canvasId, commentId, replyTo: replyToCommentId !== "" ? replyToCommentId : null });
}

Deno.serve(async (req: Request) => {
  try {
    const rawAuth = req.headers.get("Authorization") ?? "";
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
    // Le secret service_role est stocké sous SERVICE_ROLE_KEY (Supabase refuse
    // tout nom commençant par SUPABASE_). Les EF lisent SERVICE_ROLE_KEY.
    const SUPABASE_SERVICE_KEY =
      Deno.env.get("SERVICE_ROLE_KEY") ?? "";

    const body = await readBody(req);
    const verb = String(body.verb ?? "");

    // Tous les verbes canvas sont authed (AD-7 : identité du JWT, jamais du body).
    const bearer = /Bearer\s+(.+)/.exec(rawAuth)?.[1] ?? "";
    if (!bearer) {
      return err("canvas/unauthorized", "Bearer user token required", 401);
    }
    if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
      return err(
        "canvas/env",
        "SUPABASE env not configured — set the project's SERVICE_ROLE_KEY secret",
        503,
      );
    }
    const userId = await resolveUserId(bearer, SUPABASE_URL, SUPABASE_SERVICE_KEY);
    if (!userId) {
      return err("canvas/unauthorized", "invalid user token", 401);
    }

    switch (verb) {
      case "read":
        return handleRead(body, userId, SUPABASE_URL, SUPABASE_SERVICE_KEY);
      case "write":
        return handleWrite(body, userId, SUPABASE_URL, SUPABASE_SERVICE_KEY);
      case "comment":
        return handleComment(body, userId, SUPABASE_URL, SUPABASE_SERVICE_KEY);
      default:
        return err("canvas/unknown_verb", 'unknown verb "' + verb + '"', 400);
    }
  } catch (e) {
    console.error("[fn-canvas] error", e);
    const msg = e instanceof Error ? e.message : String(e);
    return err("canvas/error", msg, 500);
  }
});
