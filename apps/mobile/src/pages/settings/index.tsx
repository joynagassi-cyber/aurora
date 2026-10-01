/**
 * Settings (02 §6.1, 05 §2.1 / §5, OQ-47).
 *
 * Two AD-17 layers, both skin-only and live-previewed by the provider:
 *   - Layer 2: the expressive theme / preset selector (10 themes + 3
 *     presets, `packages/ui` SSoT catalog — the swatch dot uses that theme's
 *     OWN accent tokens, never a re-invented palette, 05 §5.7).
 *   - Layer 1: the neutral style (Light = default / Dark — the user's
 *     explicit choice, blanc-par-défaut, never a silent switch, 05 §2.1).
 *
 * Coaching / notification prefs are editable + OPTIMISTIC (OQ-47): the sync
 * is an AD-8 async job — the UI never blocks the render (AD-7).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Moon, Sun } from 'lucide-react';
import { useState } from 'react';
import { PRESETS, THEMES, type AuroraTheme, type PresetName, type ThemeName } from '@aurora/ui';
import { useUiStateStore } from '../../state/ui-state';

/** The accent swatch for a theme / preset (its OWN tokens, 05 §5.7). */
function swatchGradient(t: AuroraTheme | Record<string, unknown>): string {
  const colors =
    t && 'colors' in t ? ((t as AuroraTheme).colors ?? {}) : {};
  // A preset may carry only a partial color set — fall back to the
  // default aurora accents (THEMES.aurora) so the swatch is never empty.
  const base = (THEMES as Record<string, AuroraTheme>).aurora.colors;
  const c = { ...base, ...(colors as Partial<AuroraTheme['colors']>) };
  return `linear-gradient(120deg, ${c.primary}, ${c.secondary}, ${c.accent})`;
}

export function SettingsPage() {
  const { auroraTheme, setAuroraTheme, theme, setTheme } = useUiStateStore();
  // Optimistic local coaching prefs (OQ-47: the write is a local mirror,
  // the sync is an AD-8 job — never blocks the screen).
  const [cadence, setCadence] = useState<'daily' | 'weekly' | 'off'>('daily');
  const [silence, setSilence] = useState<'never' | 'nights' | 'focus'>('focus');

  const presets = Object.keys(PRESETS) as PresetName[];

  return (
    <>
      <IonHeader>
        <IonTitle>Paramètres</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-settings="true">
          {/* Layer 2 — expressive theme / preset (10 + 3). */}
          <section>
            <h2 className="settings-section-title">Thème</h2>
            <div className="theme-grid" role="radiogroup" aria-label="Thème">
              {(Object.keys(THEMES) as ThemeName[]).map((name) => (
                <button
                  key={name}
                  type="button"
                  role="radio"
                  className="theme-swatch"
                  aria-pressed={auroraTheme === name}
                  onClick={() => setAuroraTheme(name)}
                >
                  <span
                    className="theme-swatch-dot"
                    style={{ background: swatchGradient(THEMES[name]) }}
                    aria-hidden
                  />
                  <span className="theme-swatch-name">
                    {name.charAt(0).toUpperCase() + name.slice(1)}
                  </span>
                </button>
              ))}
              {presets.map((name) => (
                <button
                  key={name}
                  type="button"
                  role="radio"
                  className="theme-swatch"
                  aria-pressed={auroraTheme === name}
                  onClick={() => setAuroraTheme(name)}
                >
                  <span
                    className="theme-swatch-dot"
                    style={{
                      background: swatchGradient(PRESETS[name] as unknown as AuroraTheme),
                    }}
                    aria-hidden
                  />
                  <span className="theme-swatch-name">{name}</span>
                </button>
              ))}
            </div>
          </section>

          {/* Layer 1 — neutral style (Light default / Dark explicit). */}
          <section>
            <h2 className="settings-section-title">Style</h2>
            <div className="theme-grid" role="radiogroup" aria-label="Style">
              <button
                type="button"
                role="radio"
                className="theme-swatch"
                aria-pressed={theme !== 'dark'}
                onClick={() => setTheme('light')}
              >
                <Sun size={20} />
                <span className="theme-swatch-name">Clair</span>
              </button>
              <button
                type="button"
                role="radio"
                className="theme-swatch"
                aria-pressed={theme === 'dark'}
                onClick={() => setTheme('dark')}
              >
                <Moon size={20} />
                <span className="theme-swatch-name">Sombre</span>
              </button>
            </div>
          </section>

          {/* Coaching / notification prefs — editable + optimistic. */}
          <section>
            <h2 className="settings-section-title">Coaching</h2>
            <label>
              Cadence des coachings
              <select
                value={cadence}
                onChange={(e) => setCadence(e.target.value as typeof cadence)}
              >
                <option value="daily">Quotidienne</option>
                <option value="weekly">Hebdomadaire</option>
                <option value="off">Désactivée</option>
              </select>
            </label>
            <label>
              Fenêtres de silence
              <select
                value={silence}
                onChange={(e) => setSilence(e.target.value as typeof silence)}
              >
                <option value="never">Jamais</option>
                <option value="nights">Nuit (22h – 7h)</option>
                <option value="focus">Pendant le Focus</option>
              </select>
            </label>
          </section>
        </div>
      </IonContent>
    </>
  );
}
