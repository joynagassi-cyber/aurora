/**
 * Home page (AD-14 fixed composition — "Qu'est-ce qui compte maintenant?").
 *
 * 7 AD-14 slots + GoalProject cards (goal-dashboard-ui S1). Local store
 * only on mount (02 §6.2, no network). Each slot renders a clean per-slot
 * empty state with a CTA (05 §4.1) — never a web-search skeleton. The
 * critical-progress slot reads goals; next-actions reads the active tasks
 * mirror (AD-7). Slots 3-6 carry navigational CTAs to their family.
 *
 * All 6 UX states + killed (AD-13, G-M2) via `UxStates`.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import type { ReactNode } from 'react';
import type {
  AppError,
  AsyncState,
  GoalProject,
  Task,
} from '@aurora/domain';
import { useGoals, useTasks } from '../../query/hooks';
import { GoalProjectCard } from './goal-card';
import { GoalCardSkeleton, SlotSkeleton, TaskRowSkeleton } from '../../ux/skeletons';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useKilledDetection } from '../../hooks/use-killed';
import { useOnlineStatus } from '../../hooks/use-online';
import { CaptureFab } from '../../ux/floating';

/**
 * The 7 AD-14 Home slots, in display order (goal-dashboard-ui S1):
 * greeting, critical-progress, due-reviews, coach-suggestion, today-agenda,
 * immediate-focus, next-actions.
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

/** One AD-14 slot: a titled card wrapping its content in the 6-state block. */
function Slot({
  slot,
  title,
  state,
  flags,
  emptyCta,
  emptyCtaHref,
  skeleton,
  children,
}: {
  slot: HomeSlot;
  title: string;
  state: AsyncState<unknown>;
  flags: UxStateFlags;
  emptyCta?: string;
  /** destination du CTA empty-state (navigable, sinon le CTA est inerte). */
  emptyCtaHref?: string;
  /** shape-feature du chargement (prévisualise la forme du slot). */
  skeleton?: ReactNode;
  children: ReactNode;
}) {
  const mergedFlags =
    emptyCta || emptyCtaHref
      ? { ...flags, ...(emptyCta ? { emptyCta } : {}), ...(emptyCtaHref ? { emptyCtaHref } : {}) }
      : flags;
  return (
    <section data-slot={slot} className="aurora-slot">
      <h3>{title}</h3>
      <UxStates state={state} flags={mergedFlags} label={title} skeleton={skeleton}>
        {children}
      </UxStates>
    </section>
  );
}

export function HomePage() {
  const { data: goals, isPending, isError, refetch } = useGoals();
  const tasks = useTasks();
  const online = useOnlineStatus();
  const killed = useKilledDetection(() => refetch());

  const flags: UxStateFlags = {
    offline: !online,
    killed,
    onRetry: () => refetch(),
  };

  // Première session (zéro donnée) : le slot greeting devient une
  // invitation explicite à créer le 1er objectif (CTA pré-bound agent) —
  // l'app ne "part" jamais en screen vide inexplicable.
  const firstRun = !isPending && goals.length === 0 && (tasks.data?.length ?? 0) === 0;

  // AD-14 slot 2: critical-progress = active GoalProject cards.
  const goalState = isError
    ? ({ status: 'error', error: { code: 'goal/load_failed', message: 'Objectifs indisponibles' } as AppError } as const)
    : isPending
      ? ({ status: 'loading' } as const)
      : goals.length === 0
        ? ({ status: 'empty' } as const)
        : ({ status: 'success', data: goals } as const);

  // AD-14 slot 7: next-actions = the most urgent active tasks (AD-7 local).
  const activeTasks: Task[] =
    tasks.data?.filter((t) => t.status !== 'done') ?? [];
  const taskState =
    tasks.isPending
      ? ({ status: 'loading' } as const)
      : tasks.isError
        ? ({ status: 'error', error: { code: 'task/load_failed', message: 'Tâches indisponibles' } as AppError } as const)
        : activeTasks.length === 0
          ? ({ status: 'empty' } as const)
          : ({ status: 'success', data: activeTasks } as const);

  const emptyState = { status: 'empty' as const };

  return (
    <>
      <IonHeader>
        <IonTitle>Aurora</IonTitle>
        {!online && (
          <span data-badge="offline" className="aurora-badge">
            Hors ligne
          </span>
        )}
      </IonHeader>
      <IonContent>
        {/* AD-14 slot 1: greeting — invitation explicite le 1er lancement
            (premier objectif via l'agent, intent pré-bound), sinon statut. */}
        <Slot slot="greeting" title="Salut" state={{ status: 'success', data: null }} flags={flags}>
          {firstRun ? (
            <div data-first-run>
              <p>
                Bienvenue dans Aurora. Créez votre premier objectif : l'agent le
                décompose en features claires, les suit et vous guide.
              </p>
              <a
                className="aurora-btn aurora-btn--primary aurora-tap"
                href="/agent?intent=Crée%20mon%20premier%20objectif"
                data-cta="first-goal"
              >
                Créer mon premier objectif
              </a>
            </div>
          ) : (
            <p>Voici ce qui compte maintenant.</p>
          )}
        </Slot>

        {/* AD-14 slot 2: critical-progress — GoalProject cards. */}
        <Slot
          slot="critical-progress"
          title="Progression critique"
          state={goalState}
          flags={flags}
          emptyCta="Créer un objectif"
          emptyCtaHref="/agent?intent=Crée%20mon%20premier%20objectif"
          skeleton={<GoalCardSkeleton />}
        >
          <div className="goal-cards">
            {goals?.map((g: GoalProject) => (
              <GoalProjectCard key={g.id} goal={g} />
            ))}
          </div>
        </Slot>

        {/* AD-14 slot 3: due-reviews (Learning). */}
        <Slot
          slot="due-reviews"
          title="Révisions dues"
          state={emptyState}
          flags={flags}
          emptyCta="Reprendre l'étude"
          emptyCtaHref="/learn"
          skeleton={<SlotSkeleton />}
        >
          <p>Aucune révision due.</p>
        </Slot>

        {/* AD-14 slot 4: coach-suggestion (Agent). */}
        <Slot
          slot="coach-suggestion"
          title="Suggestion de Coach"
          state={emptyState}
          flags={flags}
          emptyCta="Demande à Aurora"
          emptyCtaHref="/agent"
          skeleton={<SlotSkeleton />}
        >
          <p>Aucune suggestion pour l'instant.</p>
        </Slot>

        {/* AD-14 slot 5: today-agenda (Calendar). */}
        <Slot
          slot="today-agenda"
          title="Aujourd'hui"
          state={emptyState}
          flags={flags}
          emptyCta="Ouvrir le calendrier"
          emptyCtaHref="/calendar"
          skeleton={<SlotSkeleton />}
        >
          <p>Aucun agenda aujourd'hui.</p>
        </Slot>

        {/* AD-14 slot 6: immediate-focus (Focus). */}
        <Slot
          slot="immediate-focus"
          title="Focus immédiat"
          state={emptyState}
          flags={flags}
          emptyCta="Démarrer une session"
          emptyCtaHref="/focus"
          skeleton={<SlotSkeleton />}
        >
          <p>Prêt à vous concentrer ?</p>
        </Slot>

        {/* AD-14 slot 7: next-actions — the most urgent active tasks. */}
        <Slot
          slot="next-actions"
          title="Prochaines actions"
          state={taskState}
          flags={flags}
          emptyCta="Capturer une tâche"
          emptyCtaHref="/inbox"
          skeleton={<TaskRowSkeleton count={2} />}
        >
          <ul className="next-actions">
            {activeTasks.slice(0, 5).map((t) => (
              <li key={t.id}>
                <a className="next-action-row aurora-tap" href={`/tasks/${t.id}`}>
                  {t.title}
                </a>
              </li>
            ))}
          </ul>
        </Slot>

        {/* L8: floating capture surface (FAB → BottomSheet, z-30). */}
        <CaptureFab
          rows={[
            { key: 'capture', label: 'Capturer', to: '/inbox', icon: 'capture' },
            { key: 'goal', label: 'Nouvel objectif', to: '/goals', icon: 'goal' },
            { key: 'agent', label: 'Demander à Aurora', to: '/agent', icon: 'agent' },
          ]}
        />
      </IonContent>
    </>
  );
}
