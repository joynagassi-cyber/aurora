/**
 * Le type partagé de la famille /projects (PROMPT 10) — le SEUL type
 * de carte projet, partagé entre la vue Liste plate et la vue
 * Timeline groupée (le `TLItem`/`TLGroup` de `views/TimelineView.tsx`),
 * ZÉRO duplication avec le calendrier (ses `.tl-*` y vivent déjà, on
 * consomme le type, on ne recopie pas l'interface ici).
 */
export interface ProjectCard {
  id: string;
  title: string;
  percent: number;
  status: 'en_cours' | 'bloque' | 'termine';
  nextMilestone: string;
  tasksTotal: number;
  tasksDone: number;
  /** Le jalon raté (ref_056 : « Manquant 24/09 ») — la state FROZEN. */
  missedMilestone?: string;
}
