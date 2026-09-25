/**
 * Ionic app shell (04 S1, 02 S6.1) — root Ionic chrome for the app.
 *
 * Routes + tabs are composed by the router (wave 1 P2); this component only
 * owns the Ionic chrome so the shell stays renderable before feature slices
 * exist. Details open OVER the current tab (IonModal/IonSlides, never a tab
 * switch — 02 §6.1).
 */
import { IonApp, IonContent, IonMenu, IonRouterOutlet, IonTabs } from '@ionic/react';
import type { ReactNode } from 'react';

export function Shell({ children }: { children: ReactNode }) {
  return (
    <IonApp>
      <IonMenu menuId="start" type="reveal">
        <IonContent className="ion-padding">
          <h1>Aurora</h1>
        </IonContent>
      </IonMenu>
      <IonContent>
        <IonTabs>
          <IonRouterOutlet />
          <ShellBody>{children}</ShellBody>
        </IonTabs>
      </IonContent>
    </IonApp>
  );
}

function ShellBody({ children }: { children: ReactNode }) {
  return <>{children}</>;
}
