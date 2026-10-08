/**
 * Goals family (05 §4.3, goal-dashboard-ui.md S2).
 *
 * /goals — list of all GoalProjects (active). /goals/:id — the Goal
 * Dashboard ("mission control", NOT a feature list). /goals/:id/features/:fid
 * — feature deep link with goal context in query (?goalId=X, 02 §6.2).
 *
 * Every async surface carries the full 6 UX states + killed (AD-13,
 * G-M2, ui-libraries S6). Read-only local mirror (AD-7, 03 §4.2).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import type { AppError, GoalProject } from '@aurora/domain';
import { useGoals, useGoal } from '../../query/hooks';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { GoalDashboardSkeleton, GoalRowSkeleton } from '../../ux/skeletons';
import { useKilledDetection } from '../../hooks/use-killed';
import { useOnlineStatus } from '../../hooks/use-online';
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
 * The Agent -> UI contract (goal-dashboard-ui.md S5): DATA in, LAYOUT out.
 * Kept as an export so the dashboard is testable without a route.
 */
export function renderGoalDashboard(
  goal: GoalProject,
  shapeOverride?: ReturnType<typeof layoutTagFor>,
) {
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
  const { data: goals, isPending, isError, refetch } = useGoals();
  const online = useOnlineStatus();
  const killed = useKilledDetection(() => refetch());
  const flags: UxStateFlags = { offline: !online, killed, onRetry: () => refetch() };

  const goalState = isError
    ? ({ status: 'error', error: { code: 'goal/load_failed', message: 'Objectifs indisponibles' } as AppError } as const)
    : isPending
      ? ({ status: 'loading' } as const)
      : goals.length === 0
        ? ({ status: 'empty' } as const)
        : ({ status: 'success', data: goals } as const);

  return (
    <>
      <IonHeader>
        <IonTitle>Objectifs</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-goals-screen>
          {/* Le but du module, en une ligne simple (pattern lots 1+2,
              zéro jargon technique visible par l'utilisateur). */}
          <p className="page-purpose">
            Où tu veux aller, et quoi faire pour y arriver.
          </p>

        <UxStates
          state={goalState}
          flags={{
            ...flags,
            emptyCta: "Créer un objectif",
            emptyCtaHref: "/agent?intent=Crée%20mon%20premier%20objectif",
          }}
          label="Objectifs"
          skeleton={<GoalRowSkeleton />}
        >
          <div data-goal-list className="goals-list-wrap">
            {goals?.map((g) => (
              <a
                key={g.id}
                className="goal-row aurora-tap"
                href={`/goals/${g.id}`}
                data-shape={layoutTagFor(g)}
              >
                <span className="goals-list-label">
                  {featureLabel(g.features[0]?.featureId ?? '')}
                </span>
                <span className="goal-row-title">{g.objective}</span>
              </a>
            ))}
          </div>
        </UxStates>
        </div>
      </IonContent>
    </>
  );
}

export function GoalDashboardPage() {
  const { id } = useParams<{ id: string }>();
  const { data: goal, isPending, isError, refetch } = useGoal(id);
  const navigate = useNavigate();
  const online = useOnlineStatus();
  const killed = useKilledDetection(() => refetch());

  const dashState = isPending
    ? ({ status: 'loading' } as const)
    : isError
      ? ({ status: 'error', error: { code: 'goal/load_failed', message: 'Objectif indisponible' } as AppError } as const)
      : !goal
        ? ({ status: 'empty' } as const)
        : ({ status: 'success', data: goal } as const);
  const flags: UxStateFlags = { offline: !online, killed, onRetry: () => refetch() };

  return (
    <>
      <IonHeader>
        <IonTitle>{goal?.objective ?? 'Objectif'}</IonTitle>
      </IonHeader>
      <IonContent>
        <UxStates
          state={dashState}
          flags={flags}
          label="Objectif"
          skeleton={<GoalDashboardSkeleton />}
        >
          {goal && (
            <GoalDashboard
              goal={goal}
              onNodeTap={(fid) =>
                navigate(`/goals/${goal.id}/features/${fid}?goalId=${goal.id}`)
              }
              onSuggestionTap={() => navigate(`/agent?goalId=${goal.id}`)}
              ascentHref={`/goals/${goal.id}/ascent`}
            />
          )}
        </UxStates>
      </IonContent>
    </>
  );
}

export function GoalFeatureDetailPage() {
  const { id, fid } = useParams<{ id: string; fid: string }>();
  const [searchParams] = useSearchParams();
  const goalId = searchParams.get('goalId') ?? id;
  const subGoalId = searchParams.get('subGoalId') ?? '';

  const featureName = featureLabel(fid);

  return (
    <IonContent>
      <IonHeader>
        <IonTitle>{featureName}</IonTitle>
      </IonHeader>
      <div
        data-goal-context={goalId}
        data-sub-goal={subGoalId}
        data-feature-detail
      >
        <span className="breadcrumb">Objectif &rsaquo; {featureName}</span>
        {/* Feature node detail (AD-7 local read). Rendered by the feature
            module when wired; 6 states covered by the parent dashboard. */}
        <div data-feature-body>
          <h2 className="feature-title">{featureName}</h2>
          <p className="feature-desc">Cette étape fait partie de ton objectif.</p>
        </div>
      </div>
    </IonContent>
  );
}
