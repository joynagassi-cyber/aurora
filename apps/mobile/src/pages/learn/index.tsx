/**
 * Learning family (02 S6.1, 05 §4.6–4.9).
 *
 * /learn — due-reviews list + course chain entry (context-preserving:
 * course → chapter → sheet/QCM/flashcards/mirror). Study position is
 * persisted (ui-state); FSRS state is read-only local (AD-7).
 * /learn/:id — detail overlay over the /learn tab (IonModal/IonSlides).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';

export function LearnPage() {
  return (
    <>
      <IonHeader>
        <IonTitle>Apprendre</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-state="empty">Aucune révision due (05 §4.8)</div>
      </IonContent>
    </>
  );
}

export function LearnDetailPage() {
  const { id } = useParams<{ id: string }>();
  return (
    <>
      <IonHeader>
        <IonTitle>{id}</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-course-id={id} data-state="loading" />
      </IonContent>
    </>
  );
}
