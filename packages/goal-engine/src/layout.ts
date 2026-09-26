/**
 * @aurora/goal-engine — Dashboard layout engine (goal-dashboard-ui.md S2/S5).
 *
 * "The agent does NOT control pixel positions. The UI derives the layout
 * from the goal's shape + timeline structure." This module is that
 * derivation: it consumes a `GoalProject` (+ the composition pattern's
 * layout tag) and produces the spatial arrangement — rows, node states,
 * connection lines — that the dashboard renders. Pure function, O(n)
 * where n = feature count (goal-dashboard-ui.md S8: n typically 4-12,
 * never > 20 in V1).
 */
import type { GoalProject } from '@aurora/domain';
import type { GoalProjectLayoutTag } from './decomposition.ts';
import {
  nextSubGoal,
  goalSuggestion,
} from './progress.ts';

/** A node in the feature workflow (goal-dashboard-ui.md S3). */
export interface FeatureNode {
  /** the feature this node renders ("qcm_generate" -> "QCM" in UI) */
  featureId: string;
  /** short display label (the UI-local naming, not the module name) */
  label: string;
  /** the sub-goal(s) this feature serves */
  subGoalIds: string[];
  /** the feature's role within the goal */
  role: string;
  /** node state (goal-dashboard-ui.md S3 states) */
  state: 'pending' | 'active' | 'done' | 'skipped' | 'blocked' | 'error';
  /** within-feature progress hint ("12/20 faits") when available */
  detail?: string;
  /** the layout row this node sits on (top->bottom = dependency) */
  row: number;
  /** the layout column within its row (left->right = sequence) */
  col: number;
  /** the connection lines out of this node (to node featureIds) */
  connections: string[];
}

/** One horizontal row of the workflow (parallel = same row). */
export interface WorkflowRow {
  row: number;
  /** parallel nodes on this row */
  featureIds: string[];
}

/** The computed dashboard layout. */
export interface GoalDashboardLayout {
  /** the goal-shape the layout was computed for (drives the visual) */
  shape: GoalProjectLayoutTag;
  /** the goal header band (objective, criteria, horizon, overall %) */
  header: {
    objective: string;
    successCriteria: string;
    horizon: GoalProject['horizon'];
    overallPct: number;
    targetDate?: string;
  };
  /** the feature workflow (rows of nodes; position = meaning) */
  rows: WorkflowRow[];
  /** every node, keyed by featureId */
  nodes: Map<string, FeatureNode>;
  /** the currently active node (pulses — AD-10 AnimationController) */
  activeFeatureId?: string;
  /** bottom context strip (NL suggestion + quick stats) */
  contextStrip: {
    suggestion: string | null;
    stats: string[];
  };
}

/**
 * Short user-facing labels for the canonical features (goal-dashboard-ui.md
 * S9: the user NEVER sees "qcm_generate"; they see "QCM"). Unknown
 * features fall back to a humanized form of the id.
 */
const FEATURE_LABELS: Record<string, string> = {
  capture: 'Inbox',
  task_create: 'Tâche',
  task_complete: 'Tâche terminée',
  calendar_block: 'Bloc agenda',
  time_block: 'Time block',
  focus_session: 'Focus',
  block_apps: 'Block apps',
  habit_checkin: 'Habit check-in',
  review_run: 'Révision',
  course_search: 'Recherche cours',
  course_import: 'Import',
  sheet_generate: 'Fiches',
  qcm_generate: 'QCM',
  flashcard_generate: 'Flashcards',
  mirror_analyze: 'Mirror',
  progress_analyze: 'Progress',
  skill_track: 'Suivi de skill',
  gap_detect: 'Lacunes',
  research_run: 'Recherche',
  horizon_scan: 'Veille',
  knowledge_add: 'Connaissance',
  tree_expand: 'Arbre',
  artifact_export: 'Livrable',
  artifact_preview: 'Aperçu',
  scientific_compute: 'Calcul scientifique',
  notification_schedule: 'Notification',
  automation_toggle: 'Automatisation',
  chat_explain: 'Explication',
  chat_verify: 'Vérification',
  chat_coach: 'Coach',
};

/** Humanize an unknown feature id ("qcm_x" -> "Qcm X"). */
export function featureLabel(featureId: string): string {
  return (
    FEATURE_LABELS[featureId] ??
    featureId
      .split(/[_-]/)
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ')
  );
}

function nodeState(g: GoalProject, featureId: string): FeatureNode['state'] {
  const sub = g.subGoals.find((s) => s.features.includes(featureId));
  if (!sub) return 'pending';
  switch (sub.status) {
    case 'done':
      return 'done';
    case 'skipped':
      return 'skipped';
    case 'active':
      return 'active';
    default:
      return 'pending';
  }
}

/**
 * Compute the dashboard layout for a goal (goal-dashboard-ui.md S2).
 *
 * Layout algorithm (position = meaning):
 *  1. Group the goal's features by the sub-goal sequence -> rows. Same
 *     sequence number = parallel = same row, side by side.
 *  2. Rows are ordered by sequence (left->right flow, top->bottom
 *     dependency).
 *  3. Connections: same-row "parallel:" lines (from the placement
 *     position) + vertical flow (each node connects to the next row's
 *     nodes — the output feeds the input).
 *  4. The active node = the first feature of the first active sub-goal
 *     (pulses via AD-10; OQ-15 attenuation is a render concern).
 *
 * Shape-specific tweaks (goal-dashboard-ui.md S2 adaptive layouts):
 *  - `adaptation`: loop-back — the last row connects back to the first
 *     row (verification -> re-plan).
 *  - `practice` / `delivery` / `curation`: the generic algorithm already
 *     produces their diagram shapes (convergence, milestone band +
 *     active sub-goal row, tree -> export) from the sequence structure.
 */
export function computeGoalDashboardLayout(
  g: GoalProject,
  shape: GoalProjectLayoutTag,
): GoalDashboardLayout {
  // Row assignment: row of the sub-goal sequence that references this
  // feature (a feature in several sub-goals sits on the earliest row).
  const featureRow = new Map<string, number>();
  const featureSubGoals = new Map<string, string[]>();
  let lastRow = 0;
  for (const s of g.subGoals) {
    lastRow = Math.max(lastRow, s.sequence - 1);
    for (const fid of s.features) {
      featureRow.set(fid, Math.min(featureRow.get(fid) ?? s.sequence - 1, s.sequence - 1));
      const subs = featureSubGoals.get(fid) ?? [];
      subs.push(s.id);
      featureSubGoals.set(fid, subs);
    }
  }

  // Features with no sub-goal (added mid-goal, goal.feature.add) sit on
  // the last row.
  for (const p of g.features) {
    if (!featureRow.has(p.featureId)) featureRow.set(p.featureId, lastRow);
  }

  // Build rows: row index -> feature ids (order = g.features order).
  const rows: WorkflowRow[] = [];
  for (const p of g.features) {
    const r = featureRow.get(p.featureId) ?? lastRow;
    const row = rows.find((x) => x.row === r);
    if (row) {
      if (!row.featureIds.includes(p.featureId)) row.featureIds.push(p.featureId);
    } else {
      rows.push({ row: r, featureIds: [p.featureId] });
    }
  }
  rows.sort((a, b) => a.row - b.row);

  // Nodes.
  const nodes = new Map<string, FeatureNode>();
  for (const p of g.features) {
    const r = featureRow.get(p.featureId) ?? lastRow;
    const sameRow = rows.find((x) => x.row === r)?.featureIds ?? [];
    nodes.set(p.featureId, {
      featureId: p.featureId,
      label: featureLabel(p.featureId),
      subGoalIds: featureSubGoals.get(p.featureId) ?? [],
      role: p.role,
      state: nodeState(g, p.featureId),
      detail: p.config.progressDetail as string | undefined,
      row: r,
      col: Math.max(0, sameRow.indexOf(p.featureId)),
      connections: [],
    });
  }

  // Connections: same-row parallels first, then vertical flow.
  for (const row of rows) {
    for (const fid of row.featureIds) {
      const node = nodes.get(fid);
      if (!node) continue;
      const placement = g.features.find((x) => x.featureId === fid);
      const parallelTo =
        placement?.position.startsWith('parallel:') &&
        placement.position.split(':')[1]?.trim();
      if (parallelTo && parallelTo !== fid && row.featureIds.includes(parallelTo)) {
        node.connections.push(parallelTo);
      }
    }
    const nextRow = rows.find((x) => x.row === row.row + 1);
    if (nextRow) {
      for (const fid of row.featureIds) {
        const node = nodes.get(fid);
        if (node) {
          for (const target of nextRow.featureIds) {
            if (target !== fid && !node.connections.includes(target)) {
              node.connections.push(target);
            }
          }
        }
      }
    }
  }

  // Adaptation shape: loop-back (verification -> re-plan), the loop is
  // rendered by the UI, expressed as a connection from the last row back
  // to row 0 (goal-dashboard-ui.md S2 Adaptation).
  if (shape === 'adaptation' && rows.length > 1) {
    const firstRow = rows[0];
    const last = rows[rows.length - 1];
    if (firstRow && last) {
      for (const fid of last.featureIds) {
        const node = nodes.get(fid);
        if (node) {
          for (const target of firstRow.featureIds) {
            if (!node.connections.includes(target)) node.connections.push(target);
          }
        }
      }
    }
  }

  // Active node: first feature of the first active sub-goal.
  const activeSub = nextSubGoal(g);
  const activeFeatureId = activeSub?.features[0];

  // Context strip: stats + the NL suggestion (goal-dashboard-ui.md S4:
  // natural language, NOT a system message).
  const doneCount = g.subGoals.filter((s) => s.status === 'done').length;
  const stats = [
    `${doneCount}/${g.subGoals.length} sous-objectifs`,
    `${g.progress.overallPct}%`,
  ];
  const suggestion = goalSuggestion(g);

  return {
    shape,
    header: {
      objective: g.objective,
      successCriteria: g.successCriteria,
      horizon: g.horizon,
      overallPct: g.progress.overallPct,
      targetDate: g.targetDate,
    },
    rows,
    nodes,
    activeFeatureId,
    contextStrip: { suggestion, stats },
  };
}

/**
 * The layout tag for a goal: an explicit tag from the composition pattern
 * wins; otherwise the shape is derived from the goal's structure.
 * (The 5 shapes are internal composition patterns, NOT user-facing labels —
 * goal-dashboard-ui.md S9.)
 */
export function layoutTagFor(
  g: GoalProject,
  explicit?: GoalProjectLayoutTag,
): GoalProjectLayoutTag {
  if (explicit) return explicit;
  const has = (fid: string) => g.features.some((p) => p.featureId === fid);
  if (has('gap_detect') && g.targetDate !== undefined) return 'preparation';
  if (has('task_create') && has('artifact_export')) return 'delivery';
  if (has('knowledge_add') || has('tree_expand')) return 'curation';
  if (has('chat_coach') && has('progress_analyze')) return 'adaptation';
  if (has('focus_session') && has('qcm_generate')) return 'practice';
  return 'custom';
}

/** The 5 shape labels + custom (goal-dashboard-ui.md S2). */
export const GOAL_SHAPES: readonly GoalProjectLayoutTag[] = [
  'preparation',
  'practice',
  'curation',
  'delivery',
  'adaptation',
];
