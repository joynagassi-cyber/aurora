/**
 * Discovery feed (05 §4 / ADR §13.9, 02 S6.1).
 *
 * Feed of DiscoveryItems (gap-triggered, agent-curated). Sheet detail →
 * "work on this" → /learn or /tasks (context-preserving). "research
 * running" empty state (job state, 01 §6 loading). Feed scroll + read
 * state persisted (ui-state, cosmetic).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';

export function DiscoveryPage() {
  return (
    <>
      <IonHeader>
        <IonTitle>Découverte</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-state="empty">Recherche en cours (job pending)</div>
      </IonContent>
    </>
  );
}
