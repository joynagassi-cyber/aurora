/**
 * Inbox (02 S6.1 page matrix, 05 §4).
 *
 * Quick-capture surface: capture CTA on every screen routes here.
 * Triage → /tasks/:id, /learn/:id, /settings. Draft persistence is local
 * (Tiptap — AD-7, no network on save). Empty state = "inbox cleared".
 * Permissions: camera/mic only when capturing media (optional, first use).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';

export function InboxPage() {
  return (
    <>
      <IonHeader>
        <IonTitle>Inbox</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-inbox="true" data-state="empty">Inbox vide</div>
      </IonContent>
    </>
  );
}
