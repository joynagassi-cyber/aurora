/**
 * dyad/beta: A1 (mobile build) — app mount (Vite entry, index.html → /src/main.tsx).
 *
 * Mount chain (verified against the current tree, 2026-09-29):
 *   createAuroraDataProvider(env)      — src/lib/boot-data.ts (PowerSync/SQLite local-mirror provider)
 *     → mobileDataProviderFrom(p)      — src/query/query-client.ts (adds the Ascent repo, A2)
 *       → <FocusThemeAdapter>          — src/ux/theme-adapter.tsx (AD-17 tokens, A7 blanc-par-défaut)
 *           → <MobileDataCtx>          — src/query/context.tsx
 *               → <AuroraApp>         — src/app.tsx (React Query + router)
 *
 * AD-3: no secret is hardcoded. The PUBLIC Supabase key + the PowerSync relay
 * URL come from the build env (`import.meta.env`, owner-provided `.env.local`).
 * connect() failure (offline / no auth session) degrades to the local-mirror
 * shell (AD-7 offline-first) — it never blocks render.
 */
import React from 'react';
import ReactDOM from 'react-dom/client';

// Ionic web CSS — the mobile shell chrome (AD-1: the native surface lives in
// @aurora/platform; the Ionic web CSS is the documented shell exception).
import '@ionic/react/css/core.css';
import '@ionic/react/css/normalize.css';
import '@ionic/react/css/structure.css';
import '@ionic/react/css/typography.css';

// Tailwind v3 (shadcn/ui layer, @aurora/ui): generates the utility classes the
// shadcn components use. Base first (Preflight), then the Aurora token
// baseline + per-family page styles. Every shadcn color token resolves to a
// runtime `var(--*)` written by <AuroraThemeProvider> (tailwind.config.js).
import './styles/tw.css';
import './styles/tokens.css';
import './styles/atoms.css';
import './styles/home.css';
import './styles/goals.css';
import './styles/focus.css';
import './styles/agent.css';
import './styles/canvas.css';
import './styles/ascent.css';
import './styles/data.css';
import './styles/floating.css';
import './styles/skills.css';
import './styles/integrations.css';
import './styles/login.css';

import { AuroraApp } from './app';
import { FocusThemeAdapter } from './ux/theme-adapter';
import { MobileDataCtx } from './query/context';
import { mobileDataProviderFrom } from './query/query-client';
import { createAuroraDataProvider, type AuroraDataEnv } from './lib/boot-data';
import { createAgentClient } from './lib/agent-client';
import { createCanvasClient } from './lib/canvas-client';
import { createIntegrationClient } from './lib/integrations-client';
import { createSkillClient } from './lib/skills-client';
import { useUiStateStore } from './state/ui-state';
import { createAuroraSupabaseClient } from '@aurora/data';

const env: AuroraDataEnv = {
  supabaseUrl: import.meta.env.VITE_SUPABASE_URL ?? '',
  supabasePublishableKey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? '',
  powersyncUrl: import.meta.env.VITE_POWERSYNC_URL ?? '',
};

// The local-mirror data provider (A2: `ascent` is wired through here).
const provider = createAuroraDataProvider(env);
// AD-3: the agent client runs on the SAME publishable-scope client — the
// device enqueues kernel runs (`fn-agent-run`) and reads the `agent_runs`
// mirror; zero provider keys cross this boundary (F-09). Absent env values
// (OQ-03) leave `agent` undefined → the /agent page shows the honest
// "agent indisponible" empty state (AD-7), never a fake run.
const agent =
  env.supabaseUrl && env.supabasePublishableKey
    ? createAgentClient(
        createAuroraSupabaseClient({
          env: {
            supabaseUrl: env.supabaseUrl,
            supabasePublishableKey: env.supabasePublishableKey,
          },
        }),
      )
    : undefined;
// AD-3: the integrations client runs on the SAME publishable-scope client —
// the device enqueues Composio calls (`fn-integrations`, v3.1 sessions) and
// reads connected accounts; zero provider / Composio keys cross this
// boundary (AD-3). Absent env values leave `integrations` undefined → the
// /integrations page shows the honest "indisponible" state, never a fake
// connection.
const integrations =
  env.supabaseUrl && env.supabasePublishableKey
    ? createIntegrationClient(
        createAuroraSupabaseClient({
          env: {
            supabaseUrl: env.supabaseUrl,
            supabasePublishableKey: env.supabasePublishableKey,
          },
        }),
      )
    : undefined;
// AD-3: the skills marketplace client runs on the SAME publishable-scope
// client — the device reads `fn-skills` (skill_catalog + user_skills). Zero
// provider keys cross this boundary. Absent env values leave `skills`
// undefined → the /skills page shows the honest "skills indisponibles"
// empty state (AD-7), never a fake catalog.
const skills =
  env.supabaseUrl && env.supabasePublishableKey
    ? createSkillClient(
        createAuroraSupabaseClient({
          env: {
            supabaseUrl: env.supabaseUrl,
            supabasePublishableKey: env.supabasePublishableKey,
          },
        }),
      )
    : undefined;
// AD-3: the canvas client runs on the SAME publishable-scope client —
// the /canvas page reads/writes canvas sessions + comments (0022, RLS user).
// Absent env values leave `canvas` undefined → honest "indisponible" state.
const canvas =
  env.supabaseUrl && env.supabasePublishableKey
    ? createCanvasClient(
        createAuroraSupabaseClient({
          env: {
            supabaseUrl: env.supabaseUrl,
            supabasePublishableKey: env.supabasePublishableKey,
          },
        }),
        env.supabasePublishableKey,
      )
    : undefined;
const dataProvider = mobileDataProviderFrom(provider, agent, integrations, skills, canvas);

function Root() {
  const focusActive = useUiStateStore((s) => s.focusActive);
  const theme = useUiStateStore((s) => s.theme);
  const auroraTheme = useUiStateStore((s) => s.auroraTheme);
  // A7 (AD-17): DARK only when the user explicitly chose it — 'auto' resolves
  // to light (blanc-par-défaut), never a silent theme switch on foreground.
  const style = theme === 'dark' ? 'dark' : 'light';
  // Layer-2 expressive theme / preset (05 §5). 'auto' = the default theme.
  const themeName = auroraTheme === 'auto' ? 'aurora' : auroraTheme;
  return (
    <FocusThemeAdapter focusActive={focusActive} style={style} theme={themeName}>
      <MobileDataCtx value={dataProvider}>
        <AuroraApp dataProvider={dataProvider} />
      </MobileDataCtx>
    </FocusThemeAdapter>
  );
}

async function boot(): Promise<void> {
  // 03 S8.1: the sync loop is the boot readiness gate. Offline / no session →
  // keep the local-mirror shell (AD-7); log for the diagnostics.
  try {
    await provider.connect();
  } catch (error) {
    console.warn('[Aurora] data provider connect() unavailable — offline / local-mirror mode', error);
  }
  const rootEl = document.getElementById('root');
  if (!rootEl) throw new Error('[Aurora] #root element not found');
  ReactDOM.createRoot(rootEl).render(
    <React.StrictMode>
      <Root />
    </React.StrictMode>,
  );
}

void boot();
