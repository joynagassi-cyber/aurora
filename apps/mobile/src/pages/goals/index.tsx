/**
 * Goals family (05 §4.3, goal-dashboard-ui.md S2).
 *
 * /goals — list of all GoalProjects (active + completed).
 * /goals/:id — the Goal Dashboard ("mission control", NOT a feature list).
 * /goals/:id/features/:fid — feature detail deep link, with goal context
 * in query (?goalId=X&subGoalId=Y — context-preserving, 02 S6.1).
 *
 * The dashboard is an adaptive layout per goal shape (Preparation/Practice/
 * Curation/Delivery/Adaptation, goal-dashboard-ui.md S2). Feature nodes'
 * position = meaning; the active node pulses (AD-10 AnimationController).
 * Read-only local mirror (AD-7, 03 §4.2) — no network on tap.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { useGoals, useGoal } from '../../query/hooks';
import type { GoalProject } from '@aurora/domain';
import {
  GoalDashboard,
  GoalHeader,
  FeatureWorkflow,
  ContextStrip,
  featureLabel,
} from './dashboard';
import {
  computeGoalDashboardLayout,
  layoutTagFor,
} from '@aurora/goal-engine';

/**
 * The 5 adaptive goal-shape layouts, rendered from the goal's composition
 * data (goal-dashboard-ui.md S2: "the layout is NOT the same for every
 * goal. The agent's composition pattern drives the VISUAL."). The
 * dashboard component itself picks the renderer; this table is the S5
 * Agent->UI contract: DATA in, LAYOUT out — the user never sees a
 * feature list, they see the goal's shape.
 */
export function renderGoalDashboard(
  goal: GoalProject,
  shapeOverride?: ReturnType<typeof layoutTagFor>,
) {
  // The dashboard derives its LAYOUT from goal data (Agent->UI contract,
  // goal-dashboard-ui.md S5): shape tag from the composition pattern,
  // layout computed O(n) over the feature count (S8).
  const shape = shapeOverride ?? layoutTagFor(goal);
  const layout = computeGoalDashboardLayout(goal, shape);
  return (
    <>
      <GoalHeader layout={layout} goal={goal} />
      <FeatureWorkflow layout={layout} attenuated={false} onNodeTap={() => {}} />
      <ContextStrip layout={layout} />
    </>
  );
}

export function GoalsPage() {
  const { data: goals, isPending } = useGoals();

  return (
    <>
      <IonHeader>
        <IonTitle>Objectifs</IonTitle>
      </IonHeader>
      <IonContent>
        {isPending && <div data-state="loading" />}
        {goals && goals.length === 0 && <div data-state="empty">Aucun objectif + capture CTA</div>}
        <ul className="goals-list">
          {goals?.map((g: GoalProject) => {
            // context-preserving deep link target (goal-dashboard-ui.md S6):
            // /goals/:id/features/:fid carries ?goalId=X — the feature screen
            // shows the goal breadcrumb and back returns here (02 S6.2).
            const shape = layoutTagFor(g);
            return (
              <li key={g.id}>
                <a href={`/goals/${g.id}?shape=${shape}`} data-shape={shape}>
                  <span className="goals-list-label">{featureLabel(g.features[0]?.featureId ?? '')}</span>
                  {g.objective}
                </a>
              </li>
            );
          })}
        </ul>
      </IonContent>
    </>
  );
}

export function GoalDashboardPage() {
  const { id } = useParams<{ id: string }>();
  const { data: goal, isPending } = useGoal(id);
  const navigate = useNavigate();

  return (
    <>
      <IonHeader>
        <IonTitle>{goal?.objective ?? 'Objectif'}</IonTitle>
      </IonHeader>
      <IonContent>
        {isPending && <div data-state="loading" />}
        {goal && (
          <GoalDashboard
            goal={goal}
            onNodeTap={(fid) =>
              // context-preserving deep link (goal-dashboard-ui.md S6):
              // ?goalId=X&subGoalId=Y — the feature screen shows the
              // goal breadcrumb and back returns here (02 S6.2).
              navigate(`/goals/${goal.id}/features/${fid}?goalId=${goal.id}`)
            }
            onSuggestionTap={() =>
              // NL suggestion = agent chat with the goal in context (S6).
              navigate(`/agent?goalId=${goal.id}`)
            }
          />
        )}
      </IonContent>
    </>
  );
}

export function GoalFeatureDetailPage() {
  const { id, fid } = useParams<{ id: string; fid: string }>();
  const [searchParams] = useSearchParams();
  // context-preserving: goalId + subGoalId in the query string (02 S6.2)
  const goalId = searchParams.get('goalId') ?? id;

  return (
    <IonContent>
      <IonHeader>
        <IonTitle>{fid}</IonTitle>
      </IonHeader>
      <div data-goal-context={goalId} data-sub-goal={searchParams.get('subGoalId') ?? ''}>
        <span className="breadcrumb">Objectif &gt; {fid}</span>
      </div>
    </IonContent>
  );
}
