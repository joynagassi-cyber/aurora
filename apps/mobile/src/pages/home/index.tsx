/**
 * Home page (AD-14 fixed composition — "Qu'est-ce qui compte maintenant?").
 *
 * 7 AD-14 slots + GoalProject cards (docs/architecture/goal-dashboard-ui.md
 * S1). Local store only on mount (02 §6.2, no network). Each slot renders
 * a clean per-slot empty state (05 §4.1), never a web-search skeleton.
 * Theme + persisted UI prefs only (page matrix PERSIST).
 *
 * Composition is data-driven: each slot re-resolves over enabled features
 * (feature-registry S6 deactivation effect — a hidden feature fades its
 * Home slot, never a hardcoded user check, S3 Horeb rule). Slots 2-7 all
 * carry the 5 UX states + killed (P3) via `Slot`.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import type { AsyncState, GoalProject } from '@aurora/domain';
import type { ReactNode } from 'react';
import { useGoals } from '../../query/hooks';
import { GoalProjectCard } from './goal-card';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useKilledDetection } from '../../hooks/use-killed';
import { useOnlineStatus } from '../../hooks/use-online';

/**
 * The 7 AD-14 Home slots, in display order (goal-dashboard-ui.md S1 +
 * agent-prompts Phase 2 S1: greeting, critical-progress, due-reviews,
 * coach, today-agenda, immediate-focus, next-actions).
 */
export const HOME_SLOTS = [
  'greeting',
  'critical-progress',
  'due-reviews',
  'coach-suggestion',
  'today-agenda',
  'immediate-focus',
  'next-actions',
] as const;

export type HomeSlot = (typeof HOME_SLOTS)[number];

/**
 * One AD-14 slot: a titled section that renders its content inside the
 * 5 UX states + killed wrapper (`UxStates`). Slot content is a function
 * of `AsyncState` so the slot owns its own state resolution.
 */
function Slot({
  slot,
  title,
  state,
  flags,
  children,
}: {
  slot: HomeSlot;
  title: string;
  state: AsyncState<unknown>;
  flags: UxStateFlags;
  children: ReactNode;
}) {
  return (
    <section data-slot={slot} className="aurora-slot">
      <h3>{title}</h3>
      <UxStates state={state} flags={flags} label={title}>
        {children}
      </UxStates>
    </section>
  );
}

export function HomePage() {
  const { data: goals, isPending, isError, refetch } = useGoals();
  const online = useOnlineStatus();
  const killed = useKilledDetection(() => refetch());

  const flags: UxStateFlags = { offline: !online, killed, onRetry: () => refetch() };

  // AD-14 slot 2: critical-progress = active GoalProject cards.
  const goalState: AsyncState<GoalProject[]> = isPending
    ? { status: 'loading' }
    : isError
      ? { status: 'error', error: { code: 'goal/load_failed', message: 'Objectifs indisponibles' } }
      : goals && goals.length === 0
        ? { status: 'empty' }
        : { status: 'success', data: goals ?? [] };

  // Placeholder slots 3-7: "today-context" from the local store only
  // (02 §6.2: no network on mount). Real producers wire in at wave 2.
  const emptyState: AsyncState<unknown> = { status: 'empty' };

  return (
    <>
      <IonHeader>
        <IonTitle>Aurora</IonTitle>
        {!online && <span data-badge="offline" className="aurora-badge">Offline</span>}
      </IonHeader>
      <IonContent>
        {/* AD-14 slot 1: greeting (static, no data dependency) */}
        <Slot slot="greeting" title="Salut" state={{ status: 'success', data: null }} flags={flags}>
          <p>Voici ce qui compte maintenant.</p>
        </Slot>

        {/* AD-14 slot 2: critical-progress — GoalProject cards */}
        <Slot slot="critical-progress" title="Progression critique" state={goalState} flags={flags}>
          <div className="goal-cards">
            {goals?.map((g) => <GoalProjectCard key={g.id} goal={g} />)}
          </div>
        </Slot>

        {/* AD-14 slots 3-7 — clean per-slot empty (05 §4.1) */}
        <Slot slot="due-reviews" title="Révisions dues" state={emptyState} flags={flags}>
          <p>Aucune révision due.</p>
        </Slot>
        <Slot slot="coach-suggestion" title="Suggestion de Coach" state={emptyState} flags={flags}>
          <p>Aucune suggestion pour l'instant.</p>
        </Slot>
        <Slot slot="today-agenda" title="Aujourd'hui" state={emptyState} flags={flags}>
          <p>Aucun agenda aujourd'hui.</p>
        </Slot>
        <Slot slot="immediate-focus" title="Focus immédiat" state={emptyState} flags={flags}>
          <p>Démarrer une session de focus ?</p>
        </Slot>
        <Slot slot="next-actions" title="Prochaines actions" state={emptyState} flags={flags}>
          <p>Aucune prochaine action.</p>
        </Slot>
      </IonContent>
    </>
  );
}
