/**
 * Agent conversation (02 S6.1, F-09: the device sees ONLY AgentRunState).
 *
 * /agent — conversation surface. AgentRun streaming + run history
 * (local, AD-7). Confirmation surface for high-risk / irreversible
 * actions (ADR S5, AgentActionEnvelope S11: `requiresConfirmation`).
 * Suggestions in natural language (NOT "system message" —
 * goal-dashboard-ui.md S4). Deep link "coach check-in" → /agent
 * (page matrix DEEP/AGT).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';

export function AgentPage() {
  return (
    <>
      <IonHeader>
        <IonTitle>Aurora</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-state="empty">Commence par une intention</div>
      </IonContent>
    </>
  );
}
