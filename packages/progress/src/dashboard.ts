/**
 * Progress module — dashboards + ChartSpec (ADR S18.6, docs/ui-libraries.md
 * "Charts (progress, analytics) → AntV G2").
 *
 * The dashboard layers (today / week / month / trajectory) read the device
 * mirrors `skill_states` + `progress_snapshots` ONLY (03 S4.2 mirror rule:
 * `progress_evidences` / `progress_events` / `progress_trends` are
 * server-only). This module produces a declarative `ChartSpec` that the
 * `DataVisualizationRenderer` (packages/ui, G2) renders. No vendor here
 * (AD-1): the renderer is the adapter; the spec is pure data.
 */
import type {
  ProgressSnapshot,
  SkillState,
} from '@aurora/domain';

/** A G2-compatible chart spec (AntV G2 `ChartSpec`). Kept minimal + typed
 *  so the renderer can pass it straight to G2 (docs/ui-libraries.md AD-10). */
export interface ChartSpec {
  type:
    | 'line'
    | 'interval'
    | 'point'
    | 'area'
    | 'column'
    | 'gauge'
    | 'table';
  data: Array<Record<string, unknown>>;
  encode?: Record<string, unknown>;
  /** human title (dashboard board label) */
  title?: string;
  /** G2 axis scales (0..1 for levels) */
  scale?: Record<string, unknown>;
}

/** A dashboard board (ADR S18.6: today / week / month / trajectory). */
export type DashboardBoard = 'today' | 'week' | 'month' | 'trajectory';

export const DASHBOARD_BOARDS: readonly DashboardBoard[] = [
  'today',
  'week',
  'month',
  'trajectory',
];

/** Encode a SkillState's level as an ordinal 0..7 (ADR S18.2 scale). */
export function levelToOrdinal(level: SkillState['level']): number {
  const S: readonly SkillState['level'][] = [
    'discovered',
    'comprehended',
    'recalled',
    'guided-application',
    'autonomous-application',
    'novel-problem',
    'mastered',
    'expert',
  ];
  const i = S.indexOf(level);
  return i < 0 ? 0 : i;
}

/** A skill-map trajectory chart (G2 line) over snapshots (S18.2 time-scale
 *  views: trajectories over percentages, not raw counters). */
export function skillTrajectoryChart(
  subject: string,
  snapshots: readonly Pick<ProgressSnapshot, 'takenAt' | 'level'>[],
): ChartSpec {
  const sorted = [...snapshots].sort(
    (a, b) => Date.parse(a.takenAt) - Date.parse(b.takenAt),
  );
  const data = sorted.map((s) => ({
    time: s.takenAt,
    subject,
    level: s.level,
    ordinal: levelToOrdinal(s.level as SkillState['level']),
  }));
  return {
    type: 'line',
    title: `${subject} — trajectoire`,
    data,
    encode: { x: 'time', y: 'ordinal', color: 'subject' },
    scale: { y: { domain: [0, 7] } },
  };
}

/** The "today" board (S18.1: major progress / main blockage / next action)
 *  as a table chart. Reads mirrors only. */
export function todayBoard(
  skillStates: readonly SkillState[],
  now: string,
): ChartSpec {
  const rows = skillStates
    .map((s) => ({
      skill: s.skillId,
      level: s.level,
      ordinal: levelToOrdinal(s.level),
      confidence: s.confidence ?? 0,
      freshness: s.freshness ?? 0,
      updatedAt: s.updatedAt,
    }))
    .sort((a, b) => b.ordinal - a.ordinal);
  return {
    type: 'table',
    title: `Aujourd'hui — ${now}`,
    data: rows,
  };
}

/** The week / month trend board (G2 area) — trajectory over percentages. */
export function trendBoard(
  board: 'week' | 'month',
  subject: string,
  points: Array<{ at: string; level: string; confidence?: number }>,
): ChartSpec {
  const data = points.map((p) => ({
    at: p.at,
    subject,
    ordinal: levelToOrdinal(p.level as SkillState['level']),
    confidence: p.confidence ?? 0,
  }));
  return {
    type: 'area',
    title: `${board} — ${subject}`,
    data,
    encode: { x: 'at', y: 'ordinal' },
    scale: { y: { domain: [0, 7] } },
  };
}

/**
 * The dashboard orchestrator (S18.6). Reads the device mirrors
 * (`skill_states` + `progress_snapshots` only — 03 S4.2), picks the
 * board, returns a ChartSpec. Offline-safe: stale mirrors surface as
 * `stale` state, not errors (02 S7).
 */
export function dashboard(
  board: DashboardBoard,
  input: {
    userId: string;
    subject?: string;
    skillStates: readonly SkillState[];
    snapshots: readonly ProgressSnapshot[];
    now: string;
  },
): ChartSpec {
  switch (board) {
    case 'today':
      return todayBoard(input.skillStates, input.now);
    case 'week':
      return trendBoard(
        'week',
        input.subject ?? input.userId,
        input.snapshots.map((s) => ({
          at: s.takenAt,
          level: s.level,
          confidence: s.confidence,
        })),
      );
    case 'month':
      return trendBoard(
        'month',
        input.subject ?? input.userId,
        input.snapshots.map((s) => ({
          at: s.takenAt,
          level: s.level,
          confidence: s.confidence,
        })),
      );
    case 'trajectory':
      return skillTrajectoryChart(
        input.subject ?? input.userId,
        input.snapshots,
      );
  }
}
