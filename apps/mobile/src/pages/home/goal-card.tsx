/**
 * GoalProject card (goal-dashboard-ui.md S1) — Home / Goals list.
 *
 * Visual summary of an active goal: icon + title + progress bar + next
 * action + agent suggestion (natural language, NOT a system message).
 * Card height fixed (02 S9: no layout shift). Tap = navigate to the Goal
 * Dashboard (02 S6.1: detail over current tab).
 *
 * Uses Aurora design tokens (AD-17: theme = skin only). Progress = `info`
 * semantic token; accent = theme.
 */
import { IonItem, IonLabel } from '@ionic/react';
import { useNavigate } from 'react-router-dom';
import type { GoalProject } from '@aurora/domain';

/** Per-goal-shape icon (goal-dashboard-ui.md S1: target/loop/tree/milestone/spiral). */
const SHAPE_ICON: Record<string, string> = {
  preparation: 'target',
  practice: 'loop',
  curation: 'tree',
  delivery: 'milestone',
  adaptation: 'spiral',
};

export function GoalProjectCard({ goal }: { goal: GoalProject }) {
  const navigate = useNavigate();
  const nextSubGoal = goal.subGoals.find((s) => s.status === 'active');
  const nextLabel = nextSubGoal ? nextSubGoal.label : null;

  return (
    <IonItem
      button
      href={`/goals/${goal.id}`}
      onClick={(e) => {
        e.preventDefault();
        navigate(`/goals/${goal.id}`);
      }}
      className="goal-project-card"
      aria-label={`Objectif : ${goal.objective}`}
    >
      <IonLabel>
        <span data-shape-icon={SHAPE_ICON[goal.horizon] ?? 'target'} />
        <strong>{goal.objective}</strong>
        {/* progress bar — `info` token, AD-17 */}
        <div
          role="progressbar"
          aria-valuenow={goal.progress.overallPct}
          aria-valuemin={0}
          aria-valuemax={100}
          className="goal-progress"
        >
          <div className="goal-progress-fill" style={{ width: `${goal.progress.overallPct}%` }} />
        </div>
        {nextLabel && <em>Prochain : {nextLabel}</em>}
      </IonLabel>
    </IonItem>
  );
}
