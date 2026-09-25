/**
 * Progress family (ADR §18.6, 02 S6.1, 05 §4).
 *
 * /progress — dashboards today/week/month/trajectory (ADR §18.6) +
 * skill-map + gaps view. Period selector = ui-state. Read-only mirrors
 * (skill_states, progress_snapshots — 03 §4.2, AD-7 local-first).
 * /progress/:id — detail overlay over the /progress tab.
 *
 * AG Grid for heavy data (QCM results, 1000+ rows virtualized) OR
 * shadcn Table for < 20 rows (docs/ui-libraries.md S1 decision tree).
 * Charts = AntV G2 (AD-10 DataVisualizationRenderer, frozen engine in
 * packages/ui). Empty = "not enough data yet" (honest, no fake numbers).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { useUiStateStore } from '../../state/ui-state';

export function ProgressPage() {
  const period = useUiStateStore((s) => s.progressPeriod);

  return (
    <>
      <IonHeader>
        <IonTitle>Progrès</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-period={period} data-state="empty">Pas encore assez de données</div>
      </IonContent>
    </>
  );
}

export function ProgressDetailPage() {
  const { id } = useParams<{ id: string }>();
  return (
    <>
      <IonHeader>
        <IonTitle>{id}</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-detail-id={id} data-state="loading" />
      </IonContent>
    </>
  );
}
