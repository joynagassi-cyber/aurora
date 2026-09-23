// 01 §3.1 ApiEnvelope — normalized responses for every Edge Function.
export type ApiEnvelope<T> =
  | { ok: true; data: T }
  | { ok: false; error: { code: string; message: string; details?: Record<string, unknown> } };

export function ok<T>(data: T, status = 200): Response {
  return new Response(JSON.stringify({ ok: true, data }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export function err(code: string, message: string, status = 400, details?: Record<string, unknown>): Response {
  return new Response(JSON.stringify({ ok: false, error: { code, message, details } }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ULID helper (01 §4.8/§5.3 ids are ULIDs). 26-char, Crockford, sortable.
export function ulid(): string {
  const C = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
  const time = Date.now().toString(36).toUpperCase().padStart(8, "0");
  let rand = "";
  for (let i = 0; i < 18; i++) rand += C[Math.floor(Math.random() * 32)];
  return (time + rand).slice(0, 26);
}
