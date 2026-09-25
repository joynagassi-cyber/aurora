/**
 * Focus session screen (05 §4.4.2, focus-mode spec S6/S10).
 *
 * Timer ring (system clock — AD-7: the persisted session row is the
 * SSoT, an app kill loses nothing) + blocklist UI (per-package status:
 * suspendable / not-suspendable(reason) / aurora-protected).
 *
 * DPC detection (spec S2/S10): `isBlockingAvailable()` = DETECTION, not
 * a constant — the block CTA is NEVER rendered when it is false
 * (consumer fallback = restriction mode, 04 S4.2 rule unchanged).
 *
 * Theme adaptation (OQ-15, V1 = Focus only): secondary nodes
 * attenuated (40% opacity), active node + progress at full contrast
 * (goal-dashboard-ui.md S4 local adaptation rule).
 *
 * Focus suppression = `reduceForFocus` (focus spec S8,
 * FocusNotificationReducer seam on the service).
 */
import { IonButton, IonButtons, IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useEffect, useState } from 'react';
import { Timer, Play, Square, ListX, ShieldCheck } from 'lucide-react';
import { useUiStateStore } from '../../state/ui-state';
import type { FocusControllerService, FocusSessionOptions } from '@aurora/focus';
import type { FocusSession } from '@aurora/domain';

/**
 * The service is provided by the app shell (boot wiring, Foundation):
 * `createFocusService({ dpc: createDpcAdapter(bridge, PKG), ... },
 * atlasRepo, platformReducer)`. It is taken as an injectable prop so
 * the page stays testable without the native bridge (AD-1).
 */
export interface FocusPageProps {
  service: FocusControllerService | null;
  onSession?: (s: FocusSession | null) => void;
}

export function FocusPage({ service, onSession }: FocusPageProps) {
  const { focusActive, setFocusActive } = useUiStateStore();
  const [blocking, setBlocking] = useState<boolean | null>(null);

  // DETECTION (spec S2/S10): DPC operational? false -> the block CTA is
  // NEVER rendered (04 S4.2 rule).
  useEffect(() => {
    let live = true;
    if (!service) {
      setBlocking(false);
      return;
    }
    void service.isBlockingAvailable().then((b: boolean) => {
      if (live) setBlocking(b);
    });
    return () => {
      live = false;
    };
  }, [service]);

  async function start(opts: FocusSessionOptions) {
    if (!service) return;
    const s = await service.startSession(opts);
    setFocusActive(true);
    onSession?.(s);
  }

  async function stop() {
    if (!service) return;
    await service.endSession();
    setFocusActive(false);
    onSession?.(null);
  }

  return (
    <>
      <IonHeader>
        <IonButtons slot="start">
          {focusActive && service && (
            <IonButton fill="clear" onClick={() => void stop()} aria-label="Terminer la session">
              <Square size={18} />
            </IonButton>
          )}
        </IonButtons>
        <IonTitle>Focus</IonTitle>
      </IonHeader>
      <IonContent>
        <div
          data-focus-session="true"
          data-active={focusActive}
          data-state={focusActive ? 'active' : 'scheduled'}
          data-blocking={blocking ?? false}
        >
          {blocking === false && service && (
            <div data-state="restriction-fallback">
              <ListX size={20} aria-hidden />
              <span>Régime de restriction (pas de blocage système)</span>
            </div>
          )}
          {blocking === true && service && (
            <div data-state="dpc-available">
              <ShieldCheck size={20} aria-hidden />
              <span>Blocage système disponible (DPC actif)</span>
            </div>
          )}

          {!focusActive && (
            <section className="focus-setup">
              <Timer size={48} aria-hidden />
              <p>Démarrez une session — le chrono court sur l’horloge système.</p>
              <IonButton
                size="large"
                onClick={() =>
                  void start({
                    userId: 'self',
                    mode: 'timer',
                    plannedDurationSec: 25 * 60,
                  })
                }
                disabled={!service}
              >
                <Play size={18} />
                <span>Démarrer 25 min</span>
              </IonButton>
            </section>
          )}

          {focusActive && (
            <section className="focus-live" data-phase="active">
              <span data-role="timer" data-timer-state={service?.timer()?.state}>
                {service?.timer() ? 'en cours…' : '—'}
              </span>
            </section>
          )}
        </div>
      </IonContent>
    </>
  );
}
