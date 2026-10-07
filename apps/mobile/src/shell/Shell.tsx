/**
 * Ionic app shell (04 S1, 02 §6.1) — the root mobile chrome of the app.
 *
 * Structure (one chrome, no double-nesting):
 *   <IonApp>
 *     <Outlet />          → each page OWNS its own IonHeader + IonContent
 *                            (screen = page, 02 §6.1) — the shell never
 *                            wraps pages in an extra IonContent/menu.
 *     <IonFooter>        → the single global bottom tab bar (02 §6.1:
 *                            max 5 tabs, 44-60 px; details open OVER the
 *                            current tab so the bar persists).
 *     <AgentBus />        → the single application Command Bus (02 §4,
 *                            kernel S15) — at the router root so
 *                            useNavigate works; headless (returns null).
 *
 * Legacy removals (10-07) : l'IonMenu « reveal » (chrome desktop,
 * source de l'erreur [ion-menu] "must have a content element") et
 * l'IonRouterOutlet vide (pont nav Ionic inutile avec React Router)
 * ne montent PLUS ici — le shell mobile = onglets bas + écrans.
 */
import { IonApp, IonFooter } from '@ionic/react';
import { Outlet } from 'react-router-dom';
import { AgentBus } from './AgentBus';
import { ShellTabBar } from './ShellTabBar';

export function Shell() {
  return (
    <IonApp>
      <Outlet />
      {/* 02 §6.1 : la barre d'onglets est permanente (5 tabs) ; un
          IonFooter place le chrome sous chaque IonContent de page
          (layout Ionic natif, safe-area basse gérée en CSS). */}
      <IonFooter>
        <ShellTabBar />
      </IonFooter>
      <AgentBus />
    </IonApp>
  );
}
