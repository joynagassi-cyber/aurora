/**
 * Ionic app shell (04 S1, 02 S6.1) — root Ionic chrome for the app.
 *
 * The router's root element is <Shell />: pages mount through the React
 * Router <Outlet /> rendered inside the Ionic chrome (IonRouterOutlet
 * bridges router navigation into the Ionic nav stack). Details open OVER
 * the current tab (IonModal/IonSlides, never a tab switch — 02 §6.1).
 */
import { IonApp, IonContent, IonMenu, IonRouterOutlet } from '@ionic/react';
import { Outlet } from 'react-router-dom';

export function Shell() {
  return (
    <IonApp>
      <IonMenu menuId="start" type="reveal">
        <IonContent className="ion-padding">
          <h1>Aurora</h1>
        </IonContent>
      </IonMenu>
      <IonContent>
        <IonRouterOutlet />
        <Outlet />
      </IonContent>
    </IonApp>
  );
}
