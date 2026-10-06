// =============================================================================
// canvas-client.ts — device-side canvas client (0022, AD-3).
//
// Publishable Supabase client only — zero secrets on the device.
// Les tables canvas_* passent RLS user (0022) : chaque op est bornée
// par auth.uid(), le scope user n'est PAS en paramètre (RLS fait le job).
//
// AD-1: le vendor SDK n'est nommé que via `AuroraSupabaseClient`
// (@aurora/data) — ce fichier ne touche aucun type vendor.
// =============================================================================

import type { AuroraSupabaseClient } from '@aurora/data';
import type { CanvasSession, CanvasBlock, CanvasComment } from '@aurora/domain';

export interface CanvasClient {
  /** GET une session (null = absente — état vide honnête, AD-7). */
  get(id: string): Promise<CanvasSession | null>;
  /** INSERT une nouvelle session (title + blocks initiaux). */
  create(title: string, blocks: CanvasBlock[]): Promise<CanvasSession>;
  /** UPDATE blocs d'une session (debounce côté UI, pas ici). */
  save(id: string, blocks: CanvasBlock[]): Promise<void>;
  /** Commentaires d'une session (tri par création). */
  listComments(sessionId: string): Promise<CanvasComment[]>;
  /** Ajoute un commentaire ancré (offset [start, end) dans le texte plat). */
  addComment(
    sessionId: string,
    anchor: { start: number; end: number },
    body: string,
  ): Promise<CanvasComment>;
  /** Supprime un commentaire (RLS user : borné par auth.uid()). */
  deleteComment(commentId: string): Promise<void>;
}

const mapSession = (row: Record<string, unknown>): CanvasSession => ({
  id: String(row.id),
  userId: String(row.user_id ?? ''),
  title: String(row.title ?? ''),
  blocks: (row.blocks as CanvasBlock[]) ?? [],
  artifactId: row.artifact_id ? String(row.artifact_id) : undefined,
  createdAt: String(row.created_at ?? ''),
  updatedAt: String(row.updated_at ?? ''),
});

const mapComment = (row: Record<string, unknown>): CanvasComment => ({
  id: String(row.id),
  userId: String(row.user_id ?? ''),
  sessionId: String(row.session_id ?? ''),
  anchorStart: Number(row.anchor_start ?? 0),
  anchorEnd: Number(row.anchor_end ?? 0),
  body: String(row.body ?? ''),
  createdAt: String(row.created_at ?? ''),
});

/**
 * Le client canvas device-side. Constructé avec le Supabase client signé
 * de l'app (AD-3) — `supabaseKey` est accepté mais NON transmis : le
 * client injecté est déjà scoped, le paramètre préserve la signature
 * testable (pattern agent-client.ts).
 */
export function createCanvasClient(
  supabase: AuroraSupabaseClient,
  _supabaseKey: string,
): CanvasClient {
  return {
    async get(id) {
      const { data, error } = await supabase
        .from('canvas_sessions')
        .select('*')
        .eq('id', id);
      if (error) throw new Error(`canvas get: ${error.message ?? 'unknown'}`);
      const row = (data as unknown as Record<string, unknown>[] | null)?.[0];
      return row ? mapSession(row) : null;
    },

    async create(title, blocks) {
      const { data, error } = await supabase
        .from('canvas_sessions')
        .insert({ title, blocks })
        .select('*')
        .single();
      if (error) throw new Error(`canvas create: ${error.message ?? 'unknown'}`);
      return mapSession(data as unknown as Record<string, unknown>);
    },

    async save(id, blocks) {
      const { error } = await supabase
        .from('canvas_sessions')
        .update({ blocks })
        .eq('id', id);
      if (error) throw new Error(`canvas save: ${error.message ?? 'unknown'}`);
    },

    async listComments(sessionId) {
      const { data, error } = await supabase
        .from('canvas_comments')
        .select('*')
        .eq('session_id', sessionId)
        .order('created_at');
      if (error) throw new Error(`canvas comments: ${error.message ?? 'unknown'}`);
      return ((data as unknown as Record<string, unknown>[] | null) ?? []).map(mapComment);
    },

    async addComment(sessionId, anchor, body) {
      const { data, error } = await supabase
        .from('canvas_comments')
        .insert({
          session_id: sessionId,
          anchor_start: anchor.start,
          anchor_end: anchor.end,
          body,
        })
        .select('*')
        .single();
      if (error) throw new Error(`canvas comment add: ${error.message ?? 'unknown'}`);
      return mapComment(data as unknown as Record<string, unknown>);
    },

    async deleteComment(commentId) {
      const { error } = await supabase
        .from('canvas_comments')
        .delete()
        .eq('id', commentId);
      if (error) throw new Error(`canvas comment delete: ${error.message ?? 'unknown'}`);
    },
  };
}
