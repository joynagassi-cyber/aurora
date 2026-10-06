/**
 * Goal Dashboard — adaptive layout renderer (goal-dashboard-ui.md S2-S4).
 *
 * The dashboard is NOT a list of features: it is a "mission control"
 * whose layout is computed from the goal's shape + timeline structure
 * (`computeGoalDashboardLayout`, packages/goal-engine). The agent writes
 * the DATA (features, sequence, progress); this component derives the
 * LAYOUT (node positions, connection lines, visual hierarchy) — the
 * Agent -> UI contract (goal-dashboard-ui.md S5).
 *
 * Aesthetics (goal-dashboard-ui.md S4, docs/ui-libraries.md):
 *  - ONE component system per screen (shadcn/ui + Framer Motion for the
 *    active-node pulse — AD-10 AnimationController [G-M1]).
 *  - Goal header = full-width band (no card); feature nodes = the ONLY
 *    card-like surface (8px radius); context strip = inline.
 *  - Progress = `info` semantic token; accent = the active theme (AD-17).
 *  - Connection lines = 1px, 40% opacity, rounded joins.
 *  - Active node PULSES (transform only, GPU); reduced-motion = static
 *    highlight (AD-10, useReducedMotion).
 *  - OQ-15: during a Focus session the secondary nodes attenuate to 40%.
 *
 * Brand (docs/ui-libraries.md S9): the in-app header uses the logo
 * WITHOUT background (`assets/aurora_icon_a_integre_dans_l'applciation.png`),
 * never the full app icon, never a re-invented logo.
 */
import { Compass } from 'lucide-react';
import * as React from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { cn } from '../../lib/utils';
import type { GoalProject } from '@aurora/domain';
import {
  computeGoalDashboardLayout,
  layoutTagFor,
  featureLabel,
  type FeatureNode,
  type GoalDashboardLayout,
} from '@aurora/goal-engine';

/**
 * The in-app logo (S9: header / empty states — WITHOUT background).
 * `assets/` at the repo root is the SSoT (docs/ui-libraries.md §9); the
 * bundler resolves the file name; the `data-asset` marker records which
 * asset a rule demands so the build can pin it (no re-invented logo).
 */
const IN_APP_LOGO =
  "aurora_icon_a_integre_dans_l'applciation"; // assets/ SSoT, imported at bundle time

// ---------------------------------------------------------------------------
// Header band — "the what and the how far" (goal-dashboard-ui.md S2 Top)
// ---------------------------------------------------------------------------

export function GoalHeader({
  layout,
  goal,
  /** When set, the header carries a "read the Ascent path" affordance —
   *  the /ascent route for this goal (Slide-Ascent, docs/ascent S11–S14).
   *  One tap = read the full training the agent has mounted. */
  ascentHref,
}: {
  layout: GoalDashboardLayout;
  goal: GoalProject;
  ascentHref?: string;
}) {
  return (
    <header className="goal-dashboard-header" data-goal-shape={layout.shape}>
      {/* S9: the in-app logo sits in the header band (no background). */}
      <img
        src={IN_APP_LOGO}
        alt=""
        className="goal-dashboard-logo"
        width={20}
        height={20}
        data-asset="aurora_icon_a_integre_dans_l'applciation"
      />
      <div className="goal-dashboard-header-text">
        <h2 className="goal-dashboard-title">{layout.header.objective}</h2>
        <p className="goal-dashboard-criteria">{layout.header.successCriteria}</p>
        <p className="goal-dashboard-horizon">
          {layout.header.horizon}
          {layout.header.targetDate ? ` — ${layout.header.targetDate}` : ''}
        </p>
      </div>
      {/* One tap → read the Ascent path for this goal (the agent CONDUCTS the
       *  climb, the /ascent page READS the mounted result — docs/ascent S12). */}
      {ascentHref && (
        <a
          className="goal-dashboard-ascent-link aurora-tap"
          href={ascentHref}
          data-ascent-entry="true"
        >
          <Compass size={14} aria-hidden />
          <span>Lire le chemin</span>
        </a>
      )}
      {/* Progress bar — `info` token (AD-17: theme = skin, semantic = state).
       * The goal card's "[18] / [43]" counters stay on the Home card, not
       * here (header band shows the overall %). */}
      <div
        role="progressbar"
        aria-valuenow={layout.header.overallPct}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={goal.objective}
        className="goal-dashboard-progress"
      >
        <motion.div
          className="goal-dashboard-progress-fill"
          initial={false}
          animate={{ width: `${layout.header.overallPct}%` }}
          transition={{ duration: 0.2, ease: 'easeOut' }}
        />
        <span className="goal-dashboard-progress-pct">{layout.header.overallPct}%</span>
      </div>
    </header>
  );
}

// ---------------------------------------------------------------------------
// Feature workflow — nodes + connection lines (S2 Middle, S3)
// ---------------------------------------------------------------------------

function NodeCard({
  node,
  isActive,
  attenuated,
  onNodeTap,
}: {
  node: FeatureNode;
  isActive: boolean;
  attenuated: boolean;
  onNodeTap: (featureId: string) => void;
}) {
  const reduced = useReducedMotion();
  const pulse = isActive && !reduced;
  return (
    <motion.div
      role="button"
      tabIndex={0}
      data-node-state={node.state}
      data-node-feature={node.featureId}
      aria-current={isActive ? 'step' : undefined}
      onClick={() => onNodeTap(node.featureId)}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') onNodeTap(node.featureId);
      }}
      className={cn(
        'goal-feature-node',
        node.state === 'done' && 'goal-feature-node--done',
        node.state === 'skipped' && 'goal-feature-node--skipped',
        node.state === 'blocked' && 'goal-feature-node--blocked',
        node.state === 'error' && 'goal-feature-node--error',
        isActive && 'goal-feature-node--active',
        attenuated && !isActive && 'goal-feature-node--attenuated',
      )}
      animate={pulse ? { scale: [1, 1.04, 1] } : { scale: 1 }}
      transition={
        pulse
          ? { duration: 1.6, repeat: Infinity, ease: 'easeInOut' }
          : { duration: 0.2, ease: 'easeOut' }
      }
      whileTap={reduced ? undefined : { scale: 0.98 }}
      style={{ transformOrigin: 'center' }}
    >
      <span className="goal-feature-node-label">{node.label}</span>
      {node.detail && <span className="goal-feature-node-detail">{node.detail}</span>}
      {node.state === 'active' && !reduced && (
        <span className="goal-feature-node-pulse" aria-hidden />
      )}
      {node.state === 'done' && <span className="goal-feature-node-check" aria-hidden>✓</span>}
    </motion.div>
  );
}

/**
 * The feature workflow: rows of nodes + 1px/40%-opacity connection lines
 * (goal-dashboard-ui.md S4 "Lines"). Lines are SVG, one per connection,
 * positioned by the row/col grid (position = meaning).
 */
export function FeatureWorkflow({
  layout,
  attenuated,
  onNodeTap,
}: {
  layout: GoalDashboardLayout;
  /** OQ-15: secondary nodes attenuated to 40% during an active Focus session. */
  attenuated: boolean;
  onNodeTap: (featureId: string) => void;
}) {
  return (
    <div className="goal-feature-workflow" data-shape={layout.shape}>
      {layout.rows.map((row) => (
        <div
          key={row.row}
          className="goal-feature-row"
          style={{ ['--row' as string]: row.row }}
        >
          {row.featureIds.map((fid) => {
            const node = layout.nodes.get(fid);
            if (!node) return null;
            return (
              <NodeCard
                key={fid}
                node={node}
                isActive={fid === layout.activeFeatureId}
                attenuated={attenuated}
                onNodeTap={onNodeTap}
              />
            );
          })}
        </div>
      ))}
      <AnimatePresence>
        <WorkflowLines layout={layout} />
      </AnimatePresence>
    </div>
  );
}

/** The 1px / 40% opacity connection lines (SVG overlay, GPU-safe). */
function WorkflowLines({ layout }: { layout: GoalDashboardLayout }) {
  // Grid metrics: 16px between rows, 8px within a row (goal-dashboard-ui.md
  // S4 spacing tokens — NOT uniform 20px). Node = fixed 96px wide.
  const NODE_W = 96;
  const GAP_X = 8;
  const GAP_Y = 16;
  const NODE_H = 56;
  const byRow = new Map<number, { fid: string; col: number }[]>();
  for (const [fid, n] of layout.nodes) {
    const arr = byRow.get(n.row) ?? [];
    arr.push({ fid, col: n.col });
    byRow.set(n.row, arr);
  }
  const pos = new Map<string, { x: number; y: number }>();
  for (const [row, items] of byRow) {
    items.sort((a, b) => a.col - b.col);
    items.forEach((it, i) => {
      pos.set(it.fid, {
        x: i * (NODE_W + GAP_X) + NODE_W / 2,
        y: row * (NODE_H + GAP_Y) + NODE_H / 2,
      });
    });
  }
  const lines: { from: { x: number; y: number }; to: { x: number; y: number }; key: string }[] = [];
  for (const [fid, n] of layout.nodes) {
    const from = pos.get(fid);
    if (!from) continue;
    for (const target of n.connections) {
      const to = pos.get(target);
      if (!to) continue;
      lines.push({
        from: { x: from.x, y: from.y + NODE_H / 2 },
        to: to.x > from.x ? { x: to.x, y: to.y - NODE_H / 2 } : { x: to.x, y: to.y - NODE_H / 2 },
        key: `${fid}->${target}`,
      });
    }
  }
  if (lines.length === 0) return null;
  const maxY = Math.max(...[...byRow.keys()]) * (NODE_H + GAP_Y) + NODE_H;
  const maxX = Math.max(
    ...[...byRow.values()].map((items) =>
      items.length * (NODE_W + GAP_X) - GAP_X,
    ),
  );
  return (
    <svg
      aria-hidden
      className="goal-feature-lines"
      width={maxX}
      height={maxY}
      viewBox={`0 0 ${maxX} ${maxY}`}
    >
      {lines.map((l) => (
        <line
          key={l.key}
          x1={l.from.x}
          y1={l.from.y}
          x2={l.to.x}
          y2={l.to.y}
          stroke="currentColor"
          strokeOpacity={0.4}
          strokeWidth={1}
          strokeLinecap="round"
        />
      ))}
    </svg>
  );
}

// ---------------------------------------------------------------------------
// Context strip — NL suggestion + quick stats (S2 Bottom, S4)
// ---------------------------------------------------------------------------

export function ContextStrip({
  layout,
  onSuggestionTap,
}: {
  layout: GoalDashboardLayout;
  /** Tap the suggestion = ask the agent (deep link /goals/:id + NL, S6). */
  onSuggestionTap?: () => void;
}) {
  return (
    <footer className="goal-context-strip">
      <div className="goal-context-strip-stats">
        {layout.contextStrip.stats.map((s) => (
          <span key={s} className="goal-context-strip-stat">
            {s}
          </span>
        ))}
      </div>
      {layout.contextStrip.suggestion && (
        <p
          className="goal-context-strip-suggestion"
          onClick={onSuggestionTap}
          data-interactive={onSuggestionTap ? 'true' : undefined}
        >
          {layout.contextStrip.suggestion}
        </p>
      )}
    </footer>
  );
}

// ---------------------------------------------------------------------------
// The dashboard itself — header + workflow + context strip
// ---------------------------------------------------------------------------

export function GoalDashboard({
  goal,
  /** the composition pattern's layout tag (when known, wins over derive). */
  shapeOverride,
  attenuated = false,
  onNodeTap,
  onSuggestionTap,
  /** /ascent entry for this goal (read the mounted training). */
  ascentHref,
}: {
  goal: GoalProject;
  shapeOverride?: ReturnType<typeof layoutTagFor>;
  attenuated?: boolean;
  onNodeTap?: (featureId: string) => void;
  onSuggestionTap?: () => void;
  ascentHref?: string;
}) {
  const shape = shapeOverride ?? layoutTagFor(goal);
  const layout = React.useMemo(
    () => computeGoalDashboardLayout(goal, shape),
    [goal, shape],
  );
  const handleNodeTap = (fid: string) => {
    if (fid === 'focus_session' && attenuated) return;
    onNodeTap?.(fid);
  };
  return (
    <div className="goal-dashboard" data-goal-shape={shape}>
      <GoalHeader layout={layout} goal={goal} ascentHref={ascentHref} />
      <FeatureWorkflow
        layout={layout}
        attenuated={attenuated}
        onNodeTap={handleNodeTap}
      />
      <ContextStrip layout={layout} onSuggestionTap={onSuggestionTap} />
    </div>
  );
}

export { featureLabel };
