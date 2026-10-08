/**
 * Slide-Ascent — view types over AscentLearningIR (apps/mobile, wave 3).
 *
 * docs/ascent/overview.md S12: the 12 slide types are a PALETTE, not a
 * mandatory sequence. The AscentLearningIR (mirrored from `ascent_paths`,
 * read-only, AD-7) is the source of truth; slides are a VIEW over it.
 *
 * This file is presentation-layer types ONLY — it imports the domain SSoT
 * (@aurora/domain) but re-declares NOTHING (AD-15). No vendor SDK (AD-1),
 * no DOM (these are data shapes rendered by the page components).
 */
import type { AscentStep, DepthLevel } from '@aurora/domain';
import { level1, type Level1View } from '@aurora/domain';
export { level1, type Level1View };



/**
 * The 12 Slide-Ascent slide types (overview S12). A palette: the path does
 * NOT have to use all 12. A 5-concept path might use Concept, Formula,
 * Example, Question, Recap; a deep-dive might use all 12.
 */
export type SlideType =
  | 'concept'
  | 'definition'
  | 'formula'
  | 'diagram'
  | 'example'
  | 'analogy'
  | 'timeline'
  | 'comparison'
  | 'question'
  | 'exercise'
  | 'reflection'
  | 'recap';

/**
 * An Analogy slide is ALWAYS labelled "analogy, not fact" (overview S12
 * rule: "Think of it like…" is a bridge, not a corpus statement, AD-11).
 */
export interface AnalogySlideMeta {
  /** the label that makes it clear this is a pedagogical bridge, not fact */
  labelledAsAnalogy: true;
}

/**
 * Progressive disclosure levels (overview S11): show information WHEN it
 * becomes useful, not before. Level 1 is the ALWAYS-visible default.
 */
export type DisclosureLevel = 1 | 2 | 3 | 4;

/** What each disclosure level shows (S11, frozen). */
export const DISCLOSURE_LEVELS = {
  1: 'Niveau 1 (toujours visible) : « qu\'apprendrai-je ensuite » = l\'étape actuelle + la suivante',
  2: 'Niveau 2 (en tapant) : le détail de l\'étape — le concept, la formule, un exemple, l\'activité à faire MAINTENANT',
  3: 'Niveau 3 (à la demande) : l\'aperçu du parcours, les prérequis, le « pourquoi » de la profondeur, les sources',
  4: 'Niveau 4 (panneau contextuel) : concepts liés, ponts entre domaines, historique de progression, « pourquoi cet ordre ? »',
} as const satisfies Record<DisclosureLevel, string>;

/**
 * Active-reading actions (overview S14). Start with 5; do NOT add 15
 * contextual actions (S22 "5 cover 90% of needs").
 *
 *  - Explain    → Agent generates a simplified explanation (labelled Aurora
 *                 explanation, NOT corpus, AD-11). Always available.
 *  - Note       → personal note stored in Productivity `notes`. Always.
 *  - Flashcard  → Learning creates a flashcard from the selected content.
 *                 If Learning is enabled.
 *  - Visualize  → Artifact generates an AntV/KaTeX visualization. If the
 *                 concept has a formula/diagram.
 *  - "Je bloque"→ Agent diagnoses (Mirror-style) + suggests remediation.
 *                 Always.
 */
export type ActiveReadingAction = 'explain' | 'note' | 'flashcard' | 'visualize' | 'stuck';

/** Availability of an active-reading action in the current context. */
export interface ActiveReadingAvailability {
  explain: true;
  note: true;
  /** only when the Learning feature is enabled (feature-registry, G-M7) */
  flashcard: boolean;
  /** only when the concept carries a formula/diagram */
  visualize: boolean;
  stuck: true;
}

/**
 * Depth badge (S13) — three levels modify CONTENT, not architecture.
 */
export interface DepthBadge {
  level: DepthLevel;
  /** the reason this depth was chosen (S11 Level 3) */
  rationale: string;
}

/**
 * Source-hierarchy badge (S16, AD-11): A > B > C > D. Level D NEVER
 * overrides A/B/C. The badge shows the governing level of the step.
 */
export interface SourceHierarchyBadge {
  /** the most authoritative source level among the step's refs */
  level: 'A' | 'B' | 'C' | 'D';
  /** when a lower-level source conflicts with a higher one, this flag is
   *  set (the conflict is NEVER silent — S16). */
  conflict?: string;
}

/**
 * A single Slide-Ascent view, derived from an AscentStep (the data is the
 * source of truth, S12 "the slides are rendering"). One step may map to
 * several slides (the step's READ → DO → PROVE phases expand the palette);
 * the renderer picks the slide type per phase + depth.
 */
export interface Slide {
  /** stable id — `${stepId}:${index}` so a step can re-render across sessions */
  id: string;
  stepId: string;
  type: SlideType;
  /** the step this view renders (read-only) */
  step: AscentStep;
  /** progressive-disclosure level this slide belongs to */
  disclosure: DisclosureLevel;
  /** depth badge (S13) */
  depth?: DepthBadge;
  /** source-hierarchy badge (S16) */
  source?: SourceHierarchyBadge;
  /** analogy-only metadata (S12 "labelled as analogy, NOT fact") */
  analogy?: AnalogySlideMeta;
}

/**
 * Expand one step into its Slide-Ascent views (the palette, S12). The
 * mapping follows the step's phase + depth; a step does NOT force all 12
 * types — only the ones its phase/depth justify.
 */
export function slidesForStep(
  step: AscentStep,
  depthBadge: DepthBadge,
  sourceBadge?: SourceHierarchyBadge,
): Slide[] {
  const slides: Slide[] = [];
  const base = { stepId: step.id, step, depth: depthBadge, source: sourceBadge };
  let i = 0;

  switch (step.phase) {
    case 'read':
      slides.push({ ...base, id: `${step.id}:${i++}`, type: 'concept', disclosure: 2 });
      if (step.depth !== 'quick') {
        slides.push({ ...base, id: `${step.id}:${i++}`, type: 'example', disclosure: 2 });
      }
      break;
    case 'do':
      slides.push({ ...base, id: `${step.id}:${i++}`, type: 'exercise', disclosure: 2 });
      break;
    case 'prove':
      slides.push({ ...base, id: `${step.id}:${i++}`, type: 'question', disclosure: 2 });
      slides.push({ ...base, id: `${step.id}:${i++}`, type: 'reflection', disclosure: 4 });
      break;
    case 'remediation':
      slides.push({ ...base, id: `${step.id}:${i++}`, type: 'example', disclosure: 2 });
      break;
    case 'recap':
      slides.push({ ...base, id: `${step.id}:${i++}`, type: 'recap', disclosure: 3 });
      break;
  }
  return slides;
}
