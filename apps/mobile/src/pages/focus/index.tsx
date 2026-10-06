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
import {
  FOCUS_SOUNDS,
  FOCUS_SOUND_THEMES,
  type FocusSound,
} from '../../lib/focus-sounds';
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

export function FocusPage({ service, onSession }: FocusPageProps) {
  const { focusActive, setFocusActive } = useUiStateStore();
  const [blocking, setBlocking] = useState<boolean | null>(null);
  const [subMode, setSubMode] = useState<FocusSubMode>('pomodoro');
  const [pomodoroMin, setPomodoroMin] = useState(25);
  const [pauseMin, setPauseMin] = useState(5);
  const [chronosEnd, setChronosEnd] = useState('');
  const [focusSound, setFocusSound] = useState<string>(FOCUS_SOUNDS[0]?.name ?? '');
  const [activeTheme, setActiveTheme] =
    useState<FocusSound['theme']>('nature');
  // Spotify source (Composio Spotify integration): when Spotify is connected,
  // the user can pick a playlist / album / their own track for the session.
  // The picker below maps UI choices to REAL Spotify tool slugs (Composio
  // `SPOTIFY_*`); the controller receives a `{ toolSlug, input }` reference
  // (never an invented slug).
  const [useSpotify, setUseSpotify] = useState(false);
  const [spotifySource, setSpotifySource] = useState('');

  /** The active theme's sounds (5 par thème, spec focus S6). */
  const themeSounds = FOCUS_SOUNDS.filter((s) => s.theme === activeTheme);

  function selectThemeSound(name: string) {
    setFocusSound(name);
    const picked = FOCUS_SOUNDS.find((s) => s.name === name);
    if (picked) setActiveTheme(picked.theme);
  }

  /** Resolve the Spotify source string (`spotifySource`) for the controller. */
  function resolveSpotifySource(): string | undefined {
    if (!useSpotify || !spotifySource) return undefined;
    return spotifySource;
  }

  useEffect(() => {
    let live = true;
    if (!service) {
      setBlocking(false);
      return;
    }
    // S2/S10 detection (AD-7): the DPC check is a LOCAL read of the device
    // owner state — it never touches the network. Offline = no blocking
    // available (consumer fallback = restriction mode, controller.ts L6);
    // the check is safe to run and its promise still settles.
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
      // Spotify source (Composio): playlist / album / track synced to the
      // session when the user has connected Spotify and picked one.
      spotifySource: resolveSpotifySource(),
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
      spotifySource: resolveSpotifySource(), // Spotify overrides the catalog sound
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
                  id="tab-pomodoro"
                  aria-selected={subMode === 'pomodoro'}
                  aria-controls={subMode === 'pomodoro' ? 'panel-pomodoro' : undefined}
                  tabIndex={subMode === 'pomodoro' ? 0 : -1}
                  className={`focus-submode-tab ${subMode === 'pomodoro' ? 'is-active' : ''}`}
                  onClick={() => setSubMode('pomodoro')}
                  onKeyDown={(e) => {
                    if (e.key === 'ArrowRight' || e.key === 'ArrowLeft' || e.key === 'Home' || e.key === 'End') {
                      e.preventDefault();
                      setSubMode('chrono');
                      document.getElementById('tab-chrono')?.focus();
                    }
                  }}
                >
                  <Timer size={14} /> Pomodoro
                </button>
                <button
                  type="button"
                  role="tab"
                  id="tab-chrono"
                  aria-selected={subMode === 'chrono'}
                  aria-controls={subMode === 'chrono' ? 'panel-chrono' : undefined}
                  tabIndex={subMode === 'chrono' ? 0 : -1}
                  className={`focus-submode-tab ${subMode === 'chrono' ? 'is-active' : ''}`}
                  onClick={() => setSubMode('chrono')}
                  onKeyDown={(e) => {
                    if (e.key === 'ArrowRight' || e.key === 'ArrowLeft' || e.key === 'Home' || e.key === 'End') {
                      e.preventDefault();
                      setSubMode('pomodoro');
                      document.getElementById('tab-pomodoro')?.focus();
                    }
                  }}
                >
                  <AlarmClock size={14} /> Chrono
                </button>
              </div>

              {subMode === 'pomodoro' && (
                <div
                  id="panel-pomodoro"
                  role="tabpanel"
                  aria-labelledby="tab-pomodoro"
                  tabIndex={0}
                  className="focus-pomodoro-config"
                >
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
                <div
                  id="panel-chrono"
                  role="tabpanel"
                  aria-labelledby="tab-chrono"
                  tabIndex={0}
                  className="focus-chrono-config"
                >
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
                    <div className="focus-sound-themes" role="tablist" aria-label="Thème du son">
                      {FOCUS_SOUND_THEMES.map((t, i) => (
                        <button
                          key={t.id}
                          type="button"
                          role="tab"
                          id={`tab-theme-${t.id}`}
                          aria-selected={activeTheme === t.id}
                          aria-controls="panel-sound-themes"
                          tabIndex={activeTheme === t.id ? 0 : -1}
                          className={`focus-sound-theme ${
                            activeTheme === t.id ? 'is-active' : ''
                          }`}
                          onClick={() => {
                            setActiveTheme(t.id);
                            const first = FOCUS_SOUNDS.find((s) => s.theme === t.id);
                            if (first) setFocusSound(first.name);
                          }}
                          onKeyDown={(e) => {
                            const n = FOCUS_SOUND_THEMES.length;
                            let next = -1;
                            if (e.key === 'ArrowRight') next = (i + 1) % n;
                            else if (e.key === 'ArrowLeft') next = (i - 1 + n) % n;
                            else if (e.key === 'Home') next = 0;
                            else if (e.key === 'End') next = n - 1;
                            if (next >= 0) {
                              e.preventDefault();
                              const target = FOCUS_SOUND_THEMES[next]!;
                              setActiveTheme(target.id);
                              const first = FOCUS_SOUNDS.find((s) => s.theme === target.id);
                              if (first) setFocusSound(first.name);
                              document.getElementById(`tab-theme-${target.id}`)?.focus();
                            }
                          }}
                        >
                          {t.label}
                        </button>
                      ))}
                    </div>
                    <select
                      id="panel-sound-themes"
                      role="tabpanel"
                      aria-labelledby={`tab-theme-${activeTheme}`}
                      tabIndex={0}
                      value={focusSound}
                      onChange={(e) => selectThemeSound(e.target.value)}
                      aria-label="Choisir le son de concentration"
                    >
                      {themeSounds.map((s) => (
                        <option key={s.id} value={s.name}>
                          {s.name}
                        </option>
                      ))}
                    </select>
                    <p className="focus-sound-provenance">
                      {FOCUS_SOUNDS.find((s) => s.name === focusSound)?.source}
                    </p>
                  </div>

                  {/* Spotify (Composio) — focus-mode visualisation +
                      playlist / album préféré + son perso. The options are
                      shown when Spotify is connected; the picked source
                      overrides the catalog sound for the session. */}
                  <div className="focus-spotify-picker">
                    <label className="focus-spotify-toggle">
                      <input
                        type="checkbox"
                        checked={useSpotify}
                        onChange={(e) => setUseSpotify(e.target.checked)}
                        aria-label="Utiliser Spotify pour cette session"
                      />
                      <span>Utiliser Spotify (playlist / album / mon morceau)</span>
                    </label>
                    {useSpotify && (
                      <>
                        <select
                          value={spotifySource}
                          onChange={(e) => setSpotifySource(e.target.value)}
                          aria-label="Choisir la source Spotify"
                        >
                          <option value="">— Choisir —</option>
                          <option value="SPOTIFY_START_RESUME_PLAYBACK">Playlist / album à lancer</option>
                          <option value="SPOTIFY_SEARCH_FOR_ITEM">Recherche d'un morceau</option>
                          <option value="SPOTIFY_GET_CURRENT_USER_S_PLAYLISTS">Une de mes playlists</option>
                        </select>
                        <p className="focus-spotify-hint">
                          Synchronisé avec le timer de la session — seule Aurora
                          peut notifier à la fin (règle Aurora-only).
                        </p>
                      </>
                    )}
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
                  <span>
                    {useSpotify && spotifySource
                      ? `Spotify · ${spotifySource}`
                      : focusSound}
                  </span>
                </div>
              )}
            </section>
          )}
        </div>
      </IonContent>
    </>
  );
}
