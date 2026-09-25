/**
 * Settings (02 S6.1 page matrix).
 *
 * Theme selector + preview (05 §2.1: auto-switch deferred to /settings
 * mount, NEVER at boot) · silence windows (coaching cadence, ADR §13) ·
 * notification prefs · account. Theme = persisted (ui-state persist
 * middleware, AD-17: theme = skin only). OneSignal appKey lives only in
 * capacitor.config.ts (04 §3.2.5, AD-3).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useUiStateStore } from '../../state/ui-state';

export function SettingsPage() {
  const theme = useUiStateStore((s) => s.theme);
  const setTheme = useUiStateStore((s) => s.setTheme);

  return (
    <>
      <IonHeader>
        <IonTitle>Paramètres</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-settings="true">
          <label>
            Thème ({theme})
            <select value={theme} onChange={(e) => setTheme(e.target.value as 'auto' | 'light' | 'dark')}>
              <option value="auto">Auto</option>
              <option value="light">Clair</option>
              <option value="dark">Sombre</option>
            </select>
          </label>
        </div>
      </IonContent>
    </>
  );
}
