/**
 * Projects family view (05 §4.3, 02 S6.1). Gantt/Kanban/Timeline/List
 * views + project detail (milestones, docs, notes). View modes persisted
 * per project (ui-state, cosmetic). Empty = "no projects" + goal CTA.
 *
 * Kanban drag & drop = dnd-kit (docs/ui-libraries.md S1, NOT ion-list).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';

export function ProjectsPage() {
  return (
    <>
      <IonHeader>
        <IonTitle>Projets</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-state="empty">
          Aucun projet
          <a href="/goals">Créer un objectif</a>
        </div>
      </IonContent>
    </>
  );
}
