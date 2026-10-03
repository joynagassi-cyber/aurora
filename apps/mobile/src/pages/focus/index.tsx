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
 * Two sub-modes:
 *  - Pomodoro: 25-30 min work + 5 min pause, repeating
 *  - Chrono: user sets an end time + picks a focus sound (concentration)
 */
import { IonButton, IonButtons, IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Timer, Play, Square, ListX, ShieldCheck, Music, AlarmClock } from 'lucide-react';
import { useEffect, useState } from 'react';
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

type FocusSubMode = 'pomodoro' | 'chrono';

// Focus sounds (concentration) — in production these come from the
// "sons de concentration" catalog (min 15, 5 par thème).
const FOCUS_SOUNDS = [
  'Pluie douce',
  'Forêt apaisante',
  'Bruit blanc',
  'Rivière',
  'Vagues',
];

export function FocusPage({ service, onSession }: FocusPageProps) {
  const { focusActive, setFocusActive } = useUiStateStore();
  const [blocking, setBlocking] = useState<boolean | null>(null);
  const [subMode, setSubMode] = useState<FocusSubMode>('pomodoro');
  const [pomodoroMin, setPomodoroMin] = useState(25);
  const [pauseMin, setPauseMin] = useState(5);
  const [chronosEnd, setChronosEnd] = useState('');
  const [focusSound, setFocusSound] = useState(FOCUS_SOUNDS[0]);

  useEffect(() => {
    let live = true;
    if (!service) {
      setBlocking(false);
      return;
    }
    void service.isBlockingAvailable().then((b: boolean) => {
      if (live) setBlocking(b);
    });
    return () => { live = false; };
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

  function startPomodoro() {
    void start({
      userId: 'self',
      mode: 'pomodoro',
      plannedDurationSec: pomodoroMin * 60,
      pomodoroPauseSec: pauseMin * 60,
      // The next Pomodoro block is auto-scheduled by the planner.
    });
  }

  function startChronos() {
    // Chronos mode: duration derived from the chosen end time.
    const now = new Date();
    const end = chronosEnd ? new Date(chronosEnd) : now;
    const durSec = Math.max(0, Math.round((end.getTime() - now.getTime()) / 1000));
    void start({
      userId: 'self',
      mode: 'timer',
      plannedDurationSec: durSec,
      focusSound, // the concentration sound plays during the session
    });
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
              {/* Sub-mode tabs */}
              <div className="focus-submode-tabs" role="tablist">
                <button
                  type="button"
                  role="tab"
                  aria-selected={subMode === 'pomodoro'}
                  className={`focus-submode-tab ${subMode === 'pomodoro' ? 'is-active' : ''}`}
                  onClick={() => setSubMode('pomodoro')}
                >
                  <Timer size={14} /> Pomodoro
                </button>
                <button
                  type="button"
                  role="tab"
                  aria-selected={subMode === 'chrono'}
                  className={`focus-submode-tab ${subMode === 'chrono' ? 'is-active' : ''}`}
                  onClick={() => setSubMode('chrono')}
                >
                  <AlarmClock size={14} /> Chrono
                </button>
              </div>

              {subMode === 'pomodoro' && (
                <div className="focus-pomodoro-config">
                  <div className="focus-config-row">
                    <label>
                      Travail (min)
                      <input
                        type="number"
                        min={15}
                        max={45}
                        step={5}
                        value={pomodoroMin}
                        onChange={(e) => setPomodoroMin(Number(e.target.value))}
                      />
                    </label>
                    <label>
                      Pause (min)
                      <input
                        type="number"
                        min={2}
                        max={15}
                        step={1}
                        value={pauseMin}
                        onChange={(e) => setPauseMin(Number(e.target.value))}
                      />
                    </label>
                  </div>
                  <p className="focus-config-hint">
                    {pomodoroMin} min de travail + {pauseMin} min de pause — le pomodoro suivant
                    est planifié automatiquement par l'agent (mode planifié).
                  </p>
                </div>
              )}

              {subMode === 'chrono' && (
                <div className="focus-chrono-config">
                  <label>
                    Sonner à (fin de session)
                    <input
                      type="time"
                      value={chronosEnd}
                      onChange={(e) => setChronosEnd(e.target.value)}
                    />
                  </label>
                  <div className="focus-sound-picker">
                    <Music size={14} aria-hidden />
                    <span>Son de concentration</span>
                    <select
                      value={focusSound}
                      onChange={(e) => setFocusSound(e.target.value)}
                      aria-label="Choisir le son de concentration"
                    >
                      {FOCUS_SOUNDS.map((s) => (
                        <option key={s} value={s}>{s}</option>
                      ))}
                    </select>
                  </div>
                </div>
              )}

              <IonButton
                size="large"
                onClick={() => (subMode === 'pomodoro' ? startPomodoro() : startChronos())}
                disabled={!service || (subMode === 'chrono' && !chronosEnd)}
              >
                <Play size={18} />
                <span>
                  {subMode === 'pomodoro'
                    ? `Démarrer ${pomodoroMin} min de Pomodoro`
                    : chronosEnd
                      ? `Démarrer jusqu'à ${chronosEnd}`
                      : 'Démarrer le chrono'}
                </span>
              </IonButton>
            </section>
          )}

          {focusActive && (
            <section className="focus-live" data-phase="active">
              <span data-role="timer" data-timer-state={service?.timer()?.state}>
                {service?.timer() ? 'en cours…' : '—'}
              </span>
              {subMode === 'chrono' && (
                <div className="focus-live-sound">
                  <Music size={14} aria-hidden />
                  <span>{focusSound}</span>
                </div>
              )}
            </section>
          )}
        </div>
      </IonContent>
    </>
  );
}
