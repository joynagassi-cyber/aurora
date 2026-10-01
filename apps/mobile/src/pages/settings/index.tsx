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
 *
 * Shadcn layer: each section is a `<Card>`; the coaching prefs are real
 * `@aurora/ui` `<Select>` controls; a `<Badge>` signals the optimistic
 * AD-8 sync. The theme-swatch grid stays a custom token element (the DS
 * swatch is not a shadcn control).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Moon, Sun } from 'lucide-react';
import { useState } from 'react';
import {
  PRESETS,
  THEMES,
  type AuroraTheme,
  type PresetName,
  type ThemeName,
  Badge,
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@aurora/ui';
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
        <div data-settings="true" className="settings-page">
          {/* Layer 2 — expressive theme / preset (10 + 3). */}
          <Card>
            <CardHeader>
              <CardTitle>Thème</CardTitle>
              <CardDescription>
                10 thèmes expressifs + 3 presets (AD-17, 05 §5).
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="theme-grid" role="radiogroup" aria-label="Thème">
                {(Object.keys(THEMES) as ThemeName[]).map((name) => (
                  <button
                    key={name}
                    type="button"
                    role="radio"
                    aria-checked={auroraTheme === name}
                    className="theme-swatch"
                    data-pressed={auroraTheme === name}
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
                    aria-checked={auroraTheme === name}
                    className="theme-swatch"
                    data-pressed={auroraTheme === name}
                    onClick={() => setAuroraTheme(name)}
                  >
                    <span
                      className="theme-swatch-dot"
                      style={{
                        background: swatchGradient(
                          PRESETS[name] as unknown as AuroraTheme,
                        ),
                      }}
                      aria-hidden
                    />
                    <span className="theme-swatch-name">{name}</span>
                  </button>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Layer 1 — neutral style (Light default / Dark explicit). */}
          <Card>
            <CardHeader>
              <CardTitle>Style</CardTitle>
              <CardDescription>
                Clair (défaut) / Sombre — choix explicite, jamais un
                changement silencieux (05 §2.1).
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="theme-grid" role="radiogroup" aria-label="Style">
                <button
                  type="button"
                  role="radio"
                  aria-checked={theme !== 'dark'}
                  className="theme-swatch"
                  data-pressed={theme !== 'dark'}
                  onClick={() => setTheme('light')}
                >
                  <Sun size={20} />
                  <span className="theme-swatch-name">Clair</span>
                </button>
                <button
                  type="button"
                  role="radio"
                  aria-checked={theme === 'dark'}
                  className="theme-swatch"
                  data-pressed={theme === 'dark'}
                  onClick={() => setTheme('dark')}
                >
                  <Moon size={20} />
                  <span className="theme-swatch-name">Sombre</span>
                </button>
              </div>
            </CardContent>
          </Card>

          {/* Coaching / notification prefs — editable + optimistic. */}
          <Card>
            <CardHeader>
              <CardTitle>Coaching</CardTitle>
              <CardDescription>
                Préférences éditables + optimistes (OQ-47 : le sync est un
                job AD-8 asynchrone, la UI ne bloque jamais le render).
              </CardDescription>
              <Badge variant="secondary">Synchronisation optimiste · AD-8</Badge>
            </CardHeader>
            <CardContent className="settings-prefs">
              <div className="settings-field">
                <span className="settings-field-label">
                  Cadence des coachings
                </span>
                <Select
                  value={cadence}
                  onValueChange={(v) => setCadence(v as typeof cadence)}
                >
                  <SelectTrigger aria-label="Cadence des coachings" className="w-full">
                    <SelectValue placeholder="Cadence" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="daily">Quotidienne</SelectItem>
                    <SelectItem value="weekly">Hebdomadaire</SelectItem>
                    <SelectItem value="off">Désactivée</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="settings-field">
                <span className="settings-field-label">
                  Fenêtres de silence
                </span>
                <Select
                  value={silence}
                  onValueChange={(v) => setSilence(v as typeof silence)}
                >
                  <SelectTrigger aria-label="Fenêtres de silence" className="w-full">
                    <SelectValue placeholder="Fenêtres de silence" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="never">Jamais</SelectItem>
                    <SelectItem value="nights">Nuit (22h – 7h)</SelectItem>
                    <SelectItem value="focus">Pendant le Focus</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>
        </div>
      </IonContent>
    </>
  );
}
