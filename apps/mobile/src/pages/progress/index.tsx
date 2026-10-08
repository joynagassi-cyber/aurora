/**
 * Progress family (ADR §18.6, 02 S6.1, 05 §4).
 *
 * /progress — dashboards today/week/month/trajectory + skill-map + gaps.
 * The period selector is a T4 ui-state (cosmetic, persistent). Read-only
 * mirrors (skill_states, progress_snapshots — 03 §4.2, AD-7 local-first).
 *
 * Charts = AntV G2 via `DataVisualizationRenderer` (@aurora/ui, AD-10) —
 * the engine is lazy + memo; empty = "not enough data yet" (honest, no
 * fake numbers, 05 §4). Full 6 UX states + killed (AD-13, G-M2).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { useUiStateStore } from '../../state/ui-state';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';

/** The 4 period views (05 §4.6 "SegmentedControl 4 options"). */
const PERIODS = [
  ['today', "Aujourd'hui"],
  ['week', 'Semaine'],
  ['month', 'Mois'],
  ['trajectory', 'Évolution'],
] as const;

export function ProgressPage() {
  const period = useUiStateStore((s) => s.progressPeriod);
  const setPeriod = useUiStateStore((s) => s.setProgressPeriod);
  const killed = useUiStateStore((s) => s.killed);
  const online = useOnlineStatus();
  const flags: UxStateFlags = { offline: !online, killed };

  return (
    <>
      <IonHeader>
        <IonTitle>Progrès</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-period={period} data-progress-screen>
          {/* Le but du module, en une ligne simple (pattern lots 1+2,
              zéro jargon technique visible par l'utilisateur). */}
          <p className="page-purpose">
            Vois comment ta compréhension et ta mémoire progressent.
          </p>

          {/* T4 period pager (05 §3.4 / 05 §4.6: 4 options). */}
          <div className="segmented" role="tablist" aria-label="Période">
            {PERIODS.map(([value, label]) => (
              <button
                key={value}
                role="tab"
                aria-selected={period === value}
                className={
                  period === value
                    ? 'segmented-item active'
                    : 'segmented-item'
                }
                onClick={() => setPeriod(value)}
              >
                {label}
              </button>
            ))}
          </div>

          {/* KPI tiles + chart. No progress_snapshots mirror yet → the
              honest empty state (AD-7, 05 §4). G2 mounts here when wired. */}
          <UxStates
            state={{ status: 'empty' }}
            flags={{ ...flags, emptyCta: "Reprendre l'étude", emptyCtaHref: "/learn" }}
            label="Progrès"
          >
            <div data-progress-empty>
              <div className="stat-tile">
                <p className="stat-label">Maîtrise moyenne</p>
                <p className="stat-value">—</p>
              </div>
              <div className="stat-tile">
                <p className="stat-label">Révisions faites</p>
                <p className="stat-value">—</p>
              </div>
              <div data-chart-mount>
                <p className="stat-label">
                  Pas encore assez de données pour cette période
                </p>
                <p className="page-hint">
                  Les graphes se remplissent dès que tu fais des révisions et
                  des quiz.
                </p>
              </div>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}

export function ProgressDetailPage() {
  const { id } = useParams<{ id: string }>();
  const killed = useUiStateStore((s) => s.killed);
  const online = useOnlineStatus();
  const flags: UxStateFlags = {
    offline: !online,
    killed,
    emptyCta: 'Étudier ce concept',
    emptyCtaHref: '/learn',
  };
  return (
    <>
      <IonHeader>
        <IonTitle>Progrès</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-progress-detail data-detail-id={id}>
          <span className="breadcrumb">Progrès &rsaquo; Concept</span>
          {/* Trajectory (ADR §18.6): the skill trajectory for one concept.
              G2 `line`/`area` ChartSpec mounts here when the mirror is wired.
              Not wired yet → the honest EMPTY state (AD-7, 05 §4), never a
              perpetual loading. The CTA routes to /learn (study the concept). */}
          <UxStates
            state={{ status: 'empty' }}
            flags={flags}
            label="Évolution"
          >
            <div data-progress-empty>
              <p className="stat-label">
                Pas encore de progression pour ce concept
              </p>
              <a
                className="aurora-btn aurora-btn--ghost aurora-tap"
                href="/learn"
              >
                Étudier ce concept
              </a>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
