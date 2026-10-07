/**
 * Canvas entities (AD-15 SSoT, 0022). Un canvas = session d'édition
 * d'artefact ; le SSoT contenu = markdown par bloc (block.kind 'md').
 */
export interface CanvasBlock {
  id: string;
  /** v1 unique : 'md' (markdown éditable TipTap). */
  kind: 'md';
  /** contenu markdown du bloc. */
  content: string;
}

export interface CanvasSession {
  id: string;
  userId: string;
  title: string;
  blocks: CanvasBlock[];
  artifactId?: string;
  /** verrou volontaire (wave 3 G10) : true = canvas_write devient read-only
   *  tant que l'agent ou l'humain n'a pas émis canvas_lock(locked=false). */
  locked?: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CanvasComment {
  id: string;
  userId: string;
  sessionId: string;
  /** offset [start, end) dans le texte plat de la session (join '\n\n'). */
  anchorStart: number;
  anchorEnd: number;
  body: string;
  createdAt: string;
}
