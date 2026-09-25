/**
 * Home page (AD-14 fixed composition — "Qu'est-ce qui compte maintenant?").
 *
 * 7 AD-14 slots + GoalProject cards (docs/architecture/goal-dashboard-ui.md S1).
 * Local store only on mount (02 §6.2, no network). Each slot renders a clean
 * per-slot empty state (05 §4.1), never a web-search skeleton. Theme +
 * persisted UI prefs only (page matrix PERSIST).
 *
 * Composition is data-driven: each slot re-resolves over enabled features
 * (feature-registry S6 deactivation effect — a hidden feature fades its
 * Home slot, never a hardcoded user check, S3 Horeb rule).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useGoals } from '../../query/hooks';
import { GoalProjectCard } from './goal-card';

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

export function HomePage() {
  const { data: goals, isPending, isError } = useGoals();

  return (
    <>
      <IonHeader>
        <IonTitle>Aurora</IonTitle>
      </IonHeader>
      <IonContent>
        {/* AD-14 slot 1: greeting (no data) */}
        <section data-slot="greeting" className="aurora-slot">
          <p>Salut.</p>
        </section>
        {/* AD-14 slot 2: critical progress — GoalProject cards */}
        <section data-slot="critical-progress" className="aurora-slot">
          {isPending && <div data-state="loading" className="aurora-slot-loading" />}
          {isError && <div data-state="error" className="aurora-slot-error">Données indisponibles</div>}
          {goals && goals.length === 0 && (
            <div data-state="empty" className="aurora-slot-empty">
              Aucun objectif actif
            </div>
          )}
          <div className="goal-cards">
            {goals?.map((g) => <GoalProjectCard key={g.id} goal={g} />)}
          </div>
        </section>
        {/* AD-14 slots 3-7 (due-reviews / coach / agenda / focus / next-actions)
            composed in P3 over enabled features. */}
        {(['due-reviews', 'coach-suggestion', 'today-agenda', 'immediate-focus', 'next-actions'] as const).map(
          (slot) => (
            <section key={slot} data-slot={slot} className="aurora-slot">
              <div data-state="empty" className="aurora-slot-empty" />
            </section>
          ),
        )}
      </IonContent>
    </>
  );
}
