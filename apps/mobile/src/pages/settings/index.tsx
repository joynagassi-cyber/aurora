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
 * G-M7 « Modules » (roadmap 10-07): the 8 target modules get a plain
 * switch row — optimistic toggle (the write is AD-8 async, the UI never
 * blocks) persisted in `user_context.features`. Deep link
 * `?section=modules` scrolls here (the S6 « module désactivé » CTA).
 *
 * Shadcn layer: each section is a `<Card>`; the coaching prefs are real
 * `@aurora/ui` `<Select>` / `<Switch>` controls. The theme-swatch grid
 * stays a custom token element (the DS swatch is not a shadcn control).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  Award,
  Brain,
  Calendar,
  Compass,
  Inbox,
  LogIn,
  Moon,
  PenTool,
  Plug,
  Sun,
  Timer,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  IMAGE_THEMES,
  PRESETS,
  THEMES,
  resolveImageThemeFile,
  type AuroraTheme,
  type ExpressiveThemeName,
  type PresetName,
  Button,
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
  Switch,
} from '@aurora/ui';
import { useUiStateStore } from '../../state/ui-state';
import { useUserFeatures } from '../../query/user-features';

/** The accent swatch for a theme / preset (its OWN tokens, 05 §5.7). */
function swatchGradient(t: AuroraTheme | Record<string, unknown>): string {
  const colors =
    t && 'colors' in t ? ((t as AuroraTheme).colors ?? {}) : {};
  // A preset may carry only a partial color set — fall back to the
  // default aurora accents (THEMES.aurora) so the swatch is never empty.
  const base = (THEMES as Record<string, AuroraTheme>).aurora?.colors ?? {};
  const c = { ...base, ...(colors as Partial<AuroraTheme['colors']>) };
  return `linear-gradient(120deg, ${c.primary}, ${c.secondary}, ${c.accent})`;
}

/** The 8 G-M7 module rows (same ids as GATED_FEATURES / FEATURE_MODULES). */
const MODULE_ROWS = [
  { id: 'calendar', label: 'Calendrier', hint: 'Agenda et événements', Icon: Calendar },
  { id: 'focus', label: 'Focus', hint: 'Sessions de concentration', Icon: Timer },
  { id: 'knowledge', label: 'Connaissances', hint: 'Arbre de connaissances', Icon: Brain },
  { id: 'discovery', label: 'Découvertes', hint: 'Idées et ressources', Icon: Compass },
  { id: 'skills', label: 'Compétences', hint: 'Compétences actives', Icon: Award },
  { id: 'integrations', label: 'Intégrations', hint: 'Apps et services connectés', Icon: Plug },
  { id: 'inbox', label: 'Inbox', hint: 'Capturer et trier', Icon: Inbox },
  { id: 'canvas', label: 'Canvas', hint: 'Carnet et blocs', Icon: PenTool },
] as const;

export function SettingsPage() {
  const {
    auroraTheme,
    setAuroraTheme,
    auroraImageTheme,
    setAuroraImageTheme,
    theme,
    setTheme,
  } = useUiStateStore();
  const { isEnabled, setFeature } = useUserFeatures();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  // Optimistic local coaching prefs (OQ-47: the write is a local mirror,
  // the sync is an AD-8 job — never blocks the screen).
  const [cadence, setCadence] = useState<'daily' | 'weekly' | 'off'>('daily');
  const [silence, setSilence] = useState<'never' | 'nights' | 'focus'>('focus');

  // S6 deep link (?section=modules — le CTA « Activer dans les Paramètres »):
  // scroll to the modules card once mounted.
  useEffect(() => {
    if (searchParams.get('section') === 'modules') {
      document.getElementById('modules-section')?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [searchParams]);

  const presets = Object.keys(PRESETS) as PresetName[];

  return (
    <>
      <IonHeader>
        <IonTitle>Paramètres</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-settings="true" className="settings-page">
          {/* Compte — la porte unique d'Auth (P1-4, 10-07) : Connexion ET
              Inscription sur /login (refonte design 10-07, shadcn). Le
              shell boote local-mirror-only (AD-7) ; la session y restaurée
              connecte le relay PowerSync (03 S8.1). */}
          <Card>
            <CardHeader>
              <CardTitle>Compte</CardTitle>
              <CardDescription>
                Connexion / inscription — ton compte et ta synchronisation.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button onClick={() => navigate('/login')}>
                <LogIn aria-hidden /> Se connecter / s'inscrire
              </Button>
            </CardContent>
          </Card>

          {/* G-M7 — the 8 module switches (user_context.features, AD-8
              optimistic): cut a module OFF without breaking the core. */}
          <Card id="modules-section">
            <CardHeader>
              <CardTitle>Modules</CardTitle>
              <CardDescription>
                Les modules sont activés par défaut — coupe ici ce que tu ne
                veux pas voir.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="module-rows" aria-label="Modules">
                {MODULE_ROWS.map(({ id, label, hint, Icon }) => (
                  <li key={id} className="module-row">
                    <Icon size={20} aria-hidden />
                    <span className="module-row-text">
                      <span className="module-row-label">{label}</span>
                      <span className="module-row-hint">{hint}</span>
                    </span>
                    <Switch
                      checked={isEnabled(id)}
                      onCheckedChange={(on) => setFeature(id, on)}
                      aria-label={`Module ${label}`}
                    />
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>

          {/* Layer 2 — expressive theme / preset (10 + 3). */}
          <Card>
            <CardHeader>
              <CardTitle>Thème</CardTitle>
              <CardDescription>
                10 thèmes expressifs + 3 presets.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="theme-grid" role="radiogroup" aria-label="Thème">
                {(Object.keys(THEMES) as ExpressiveThemeName[]).map((name) => (
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

          {/* Layer 2b — image themes (05 §5.4-annexe, 10-07): the chosen
              image becomes the app background + its « chromatic anchor »
              drives the accents (AD-17: canvas + semantics never move).
              26 themes (52 files P+L) served from /public/themes/. */}
          <Card>
            <CardHeader>
              <CardTitle>Thème image</CardTitle>
              <CardDescription>
                L'image devient le fond de l'application ; sa couleur
                phare pilote les accents. « Aucun » = canvas neutre.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div
                className="image-theme-grid"
                role="radiogroup"
                aria-label="Thème image"
              >
                <button
                  type="button"
                  role="radio"
                  aria-checked={auroraImageTheme === 'none'}
                  className="image-theme-tile image-theme-tile--none"
                  data-pressed={auroraImageTheme === 'none'}
                  onClick={() => setAuroraImageTheme('none')}
                >
                  <span className="image-theme-thumb image-theme-thumb--none">
                    <span className="image-theme-thumb-cross" aria-hidden />
                  </span>
                  <span className="theme-swatch-name">Aucun</span>
                </button>
                {IMAGE_THEMES.map((t) => {
                  const file = resolveImageThemeFile(t.slug, 'portrait') ?? '';
                  const active = auroraImageTheme === t.slug;
                  return (
                    <button
                      key={t.slug}
                      type="button"
                      role="radio"
                      aria-checked={active}
                      className="image-theme-tile"
                      data-pressed={active}
                      onClick={() => setAuroraImageTheme(t.slug)}
                    >
                      <span className="image-theme-thumb">
                        <img
                          src={`/themes/${file}`}
                          alt=""
                          loading="lazy"
                          decoding="async"
                        />
                        {/* The « chromatic anchor » dot (05 §5.4-annexe). */}
                        <span
                          className="image-theme-anchor"
                          style={{ background: t.anchorColor }}
                          aria-hidden
                        />
                      </span>
                      <span className="theme-swatch-name">{t.label}</span>
                    </button>
                  );
                })}
              </div>
            </CardContent>
          </Card>

          {/* Layer 1 — neutral style (Light default / Dark explicit). */}
          <Card>
            <CardHeader>
              <CardTitle>Style</CardTitle>
              <CardDescription>
                Clair (défaut) / Sombre — jamais de changement silencieux.
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
                Appliquées immédiatement, puis synchronisées en arrière-plan.
              </CardDescription>
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
