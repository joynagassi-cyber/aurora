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
import { IonApp, IonFooter, IonHeader } from '@ionic/react';
import { Outlet, useNavigate } from 'react-router-dom';
import { Settings } from 'lucide-react';
import { IN_APP_LOGO, IN_APP_LOGO_ASSET } from '../brand/logo';
import { AgentBus } from './AgentBus';
import { ShellTabBar } from './ShellTabBar';

export function Shell() {
  const navigate = useNavigate();
  return (
    <IonApp>
      {/* Global app header (ui-libraries §9.1 l.380, owner 2026-09-27) :
          « la marque COLOREE porte TOUJOURS le header » — chaque écran
          porte le logo in-app (coloré, sans fond, SSoT S9 l.352–358) + le
          wordmark. C'est l'en-tête « de l'app » (vs le header de page des
          écrans en IonTitle). Tap sur la barre → /settings (l'unique point
          d'entrée de l'écran « Réglages », 02 §6.1). */}
      <IonHeader data-app-header>
        <button
          type="button"
          className="app-brand-bar"
          onClick={() => navigate('/settings')}
          aria-label="Aurora — Réglages"
        >
          <img
            src={IN_APP_LOGO}
            alt=""
            className="app-brand-logo"
            width={20}
            height={20}
            data-asset={IN_APP_LOGO_ASSET}
            loading="lazy"
            decoding="async"
          />
          <span className="app-brand-wordmark">Aurora</span>
          <Settings size={16} aria-hidden className="app-brand-settings" />
        </button>
      </IonHeader>
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
