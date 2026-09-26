/**
 * The 5 composition patterns (dynamic-goal-engine.md "5 shapes").
 *
 * These are NOT user-facing categories and NOT constraints: they are
 * HINTS the Agent Planner (kernel S12) recognizes in a goal and uses as
 * templates for the feature composition. The agent can use ONE pattern,
 * COMBINE patterns, or INVENT a composition that fits none — the patterns
 * seed a template, the LLM decomposition finalizes it.
 *
 * Each pattern carries:
 *  - a `signature` (what the agent recognizes in the goal) — a typed
 *    hint, never a keyword-only branch (event-reconciliation-and-router.md
 *    S2.5: decisions are typed, not naïve keyword matching);
 *  - a `template` of feature placements (the typical composition);
 *  - a `layout` tag consumed by the Goal Dashboard UI (goal-dashboard-ui.md
 *    S2: the pattern drives the VISUAL layout).
 */
import type { FeaturePlacement, TimelineBlock } from '@aurora/domain';

/** The 5 composition patterns (the agent's recognized shapes). */
export type CompositionPattern =
  | 'preparation'
  | 'practice'
  | 'curation'
  | 'delivery'
  | 'adaptation';

export const COMPOSITION_PATTERNS: readonly CompositionPattern[] = [
  'preparation',
  'practice',
  'curation',
  'delivery',
  'adaptation',
];

/**
 * A typed goal signature (what the agent RECOGNIZES in an NL goal). This is
 * the input the pattern selector reads — it is produced by the Intent
 * Engine's decomposition, not scraped from keywords alone.
 */
export interface GoalSignature {
  /** a deadline exists (exam, presentation, report, delivery date) */
  hasDeadline: boolean;
  /** a bounded domain / subject exists ("machine learning", "concrete") */
  hasDomain: boolean;
  /** the goal is ongoing + repetitive (habit, routine, practice) */
  isRepetitive: boolean;
  /** the goal is about collecting / organizing knowledge (veille, base) */
  isCollecting: boolean;
  /** the goal is a project with deliverable milestones */
  hasMilestones: boolean;
  /** the goal is about improving / changing a behavior */
  isBehaviorChange: boolean;
}

/** A pattern template: placements + the timeline rows they imply. */
export interface PatternTemplate {
  pattern: CompositionPattern;
  /** the typical feature composition (roles from dynamic-goal-engine.md) */
  placements: FeaturePlacement[];
  /** the typical sequencing of the composition */
  timeline: TimelineBlock[];
  /** the dashboard layout tag (goal-dashboard-ui.md S2 adaptive layouts) */
  layout: CompositionPattern;
  /** which goal-shape icon the dashboard/card uses */
  icon: 'target' | 'loop' | 'tree' | 'milestone' | 'spiral';
}

/** One placement helper — keeps the templates readable. */
function fp(
  featureId: string,
  role: string,
  frequency: string,
  position: string,
): FeaturePlacement {
  return { featureId, role, frequency, position, config: {} };
}

/** The pattern templates — HINTS, not constraints (dynamic-goal-engine.md). */
const TEMPLATES: Record<CompositionPattern, PatternTemplate> = {
  preparation: {
    pattern: 'preparation',
    // deadline + domain: gap_detect -> research -> import -> sheet -> qcm ->
    // flashcards -> focus -> mirror -> progress
    placements: [
      fp('gap_detect', 'assessment', 'on-event', 'before: research_run'),
      fp('research_run', 'preparation', 'per-block', 'before: course_import'),
      fp('course_import', 'preparation', 'on-event', 'after: research_run'),
      fp('sheet_generate', 'preparation', 'weekly', 'after: course_import'),
      fp('qcm_generate', 'practice', 'per-block', 'after: sheet_generate'),
      fp('flashcard_generate', 'practice', 'per-block', 'after: qcm_generate'),
      fp('focus_session', 'execution', 'daily', 'before: mirror_analyze'),
      fp('mirror_analyze', 'verification', 'on-event', 'after: focus_session'),
      fp('progress_analyze', 'verification', 'weekly', 'after: mirror_analyze'),
    ],
    timeline: [
      { featureId: 'gap_detect', startAt: 'T0' },
      { featureId: 'research_run', startAt: 'T1' },
      { featureId: 'course_import', startAt: 'T2' },
      { featureId: 'qcm_generate', startAt: 'T3' },
      { featureId: 'focus_session', startAt: 'T4' },
      { featureId: 'mirror_analyze', startAt: 'T5' },
    ],
    layout: 'preparation',
    icon: 'target',
  },
  practice: {
    pattern: 'practice',
    // ongoing + repetitive: habit_checkin -> focus_session ->
    // qcm/flashcards -> progress_analyze -> (weekly) review_run
    placements: [
      fp('habit_checkin', 'tracking', 'daily', 'before: focus_session'),
      fp('focus_session', 'execution', 'daily', 'after: habit_checkin'),
      fp('qcm_generate', 'practice', 'per-block', 'after: focus_session'),
      fp('flashcard_generate', 'practice', 'per-block', 'parallel: qcm_generate'),
      fp('progress_analyze', 'verification', 'weekly', 'after: qcm_generate'),
      fp('review_run', 'verification', 'weekly', 'after: progress_analyze'),
    ],
    timeline: [
      { featureId: 'habit_checkin', startAt: 'T0' },
      { featureId: 'focus_session', startAt: 'T1' },
      { featureId: 'qcm_generate', startAt: 'T2' },
      { featureId: 'progress_analyze', startAt: 'T3' },
    ],
    layout: 'practice',
    icon: 'loop',
  },
  curation: {
    pattern: 'curation',
    // collecting/organizing knowledge: knowledge_add -> tree_expand ->
    // research (optional) -> artifact_export
    placements: [
      fp('knowledge_add', 'collection', 'on-event', 'after: research_run'),
      fp('tree_expand', 'organization', 'on-event', 'after: knowledge_add'),
      fp('research_run', 'collection', 'monthly', 'before: knowledge_add'),
      fp('artifact_export', 'delivery', 'quarterly', 'after: tree_expand'),
    ],
    timeline: [
      { featureId: 'research_run', startAt: 'T0' },
      { featureId: 'knowledge_add', startAt: 'T1' },
      { featureId: 'tree_expand', startAt: 'T2' },
      { featureId: 'artifact_export', startAt: 'T3' },
    ],
    layout: 'curation',
    icon: 'tree',
  },
  delivery: {
    pattern: 'delivery',
    // project with milestones: project_create -> task_create ->
    // calendar_block -> focus -> artifact_export -> review
    placements: [
      fp('task_create', 'planning', 'on-event', 'before: calendar_block'),
      fp('calendar_block', 'scheduling', 'per-block', 'after: task_create'),
      fp('focus_session', 'execution', 'daily', 'after: calendar_block'),
      fp('artifact_export', 'delivery', 'per-milestone', 'after: focus_session'),
      fp('review_run', 'verification', 'per-milestone', 'after: artifact_export'),
    ],
    timeline: [
      { featureId: 'task_create', startAt: 'T0' },
      { featureId: 'calendar_block', startAt: 'T1' },
      { featureId: 'focus_session', startAt: 'T2' },
      { featureId: 'artifact_export', startAt: 'T3' },
    ],
    layout: 'delivery',
    icon: 'milestone',
  },
  adaptation: {
    pattern: 'adaptation',
    // improving/changing a behavior: progress_analyze -> gap_detect ->
    // (re)plan -> focus -> habit -> coach (bounded)
    placements: [
      fp('progress_analyze', 'assessment', 'weekly', 'before: gap_detect'),
      fp('gap_detect', 'assessment', 'on-event', 'after: progress_analyze'),
      fp('focus_session', 'intervention', 'daily', 'after: gap_detect'),
      fp('habit_checkin', 'intervention', 'daily', 'parallel: focus_session'),
      fp('chat_coach', 'intervention', 'on-event', 'after: habit_checkin'),
      fp('progress_analyze', 'verification', 'weekly', 'after: chat_coach'),
    ],
    timeline: [
      { featureId: 'progress_analyze', startAt: 'T0' },
      { featureId: 'gap_detect', startAt: 'T1' },
      { featureId: 'focus_session', startAt: 'T2' },
      { featureId: 'chat_coach', startAt: 'T3' },
    ],
    layout: 'adaptation',
    icon: 'spiral',
  },
};

/** The full template catalog (all 5 shapes). */
export const PATTERN_TEMPLATES: readonly PatternTemplate[] = [
  TEMPLATES.preparation,
  TEMPLATES.practice,
  TEMPLATES.curation,
  TEMPLATES.delivery,
  TEMPLATES.adaptation,
];

/** Read-only access to one template. */
export function patternTemplate(pattern: CompositionPattern): PatternTemplate {
  const t = TEMPLATES[pattern];
  if (!t) throw new Error(`goal-engine/unknown_pattern: ${pattern}`);
  return t;
}

/**
 * Score one pattern against a goal signature (typed, NOT keyword matching).
 * Returns the patterns ranked by fit — the top-N are handed to the Planner
 * as HINTS; the LLM decomposition may use one, combine them, or invent
 * something new (the ranking is advisory, not a hard constraint).
 */
export function matchPatterns(sig: GoalSignature): CompositionPattern[] {
  const scores: Record<CompositionPattern, number> = {
    preparation:
      (sig.hasDeadline ? 2 : 0) + (sig.hasDomain ? 1 : 0) + (sig.hasMilestones ? 1 : 0),
    practice:
      (sig.isRepetitive ? 2 : 0) +
      (sig.hasDomain ? 1 : 0) +
      (sig.hasDeadline ? -1 : 0),
    curation:
      (sig.isCollecting ? 3 : 0) + (sig.hasDomain ? 1 : 0) + (sig.isRepetitive ? 1 : 0),
    delivery:
      (sig.hasMilestones ? 3 : 0) +
      (sig.hasDeadline ? 2 : 0) +
      (sig.hasDomain ? 1 : 0),
    adaptation:
      (sig.isBehaviorChange ? 3 : 0) +
      (sig.isRepetitive ? 1 : 0) +
      (sig.hasDomain ? 1 : 0),
  };
  return COMPOSITION_PATTERNS.filter((p) => scores[p] > 0).sort(
    (a, b) => scores[b] - scores[a],
  );
}

/** The single best-fitting pattern (or `null` when the signature is empty —
 *  the LLM must then invent a composition). */
export function primaryPattern(sig: GoalSignature): CompositionPattern | null {
  const ranked = matchPatterns(sig);
  return ranked[0] ?? null;
}
