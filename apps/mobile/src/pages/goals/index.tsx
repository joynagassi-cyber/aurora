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
import { useParams, useSearchParams } from 'react-router-dom';
import { useGoals, useGoal } from '../../query/hooks';

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
          {goals?.map((g) => (
            <li key={g.id}>
              <a href={`/goals/${g.id}`}>{g.objective}</a>
            </li>
          ))}
        </ul>
      </IonContent>
    </>
  );
}

export function GoalDashboardPage() {
  const { id } = useParams<{ id: string }>();
  const { data: goal, isPending } = useGoal(id);

  return (
    <>
      <IonHeader>
        <IonTitle>{goal?.objective ?? 'Objectif'}</IonTitle>
      </IonHeader>
      <IonContent>
        {isPending && <div data-state="loading" />}
        {goal && (
          <div data-goal-shape={goal.horizon} className="goal-dashboard">
            <div className="goal-header">
              <strong>{goal.objective}</strong>
              <span data-progress={goal.progress.overallPct}>{goal.progress.overallPct}%</span>
            </div>
            <div className="feature-workflow">
              {goal.features.map((f) => (
                <a key={f.featureId} href={`/goals/${goal.id}/features/${f.featureId}`} className="feature-node">
                  {f.featureId}
                </a>
              ))}
            </div>
            <div className="context-strip">
              <span>Cette semaine : {goal.subGoals.filter((s) => s.status === 'done').length}/
                {goal.subGoals.length} sous-objectifs</span>
            </div>
          </div>
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
