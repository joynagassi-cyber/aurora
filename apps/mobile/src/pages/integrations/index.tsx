/**
 * Integrations page (docs/integrations/composio.md, mission S33-35).
 *
 * Composio = tool/integration layer behind the `IntegrationProvider` port
 * (AD-1 vendor isolation). This page lets the user connect external apps
 * (Google Workspace by default) and see which connected accounts are live.
 *
 * AD-3: no external credentials on the device — connected-account state is
 * read from `integrations_state` (RLS user-isolated, server-side); the
 * OAuth flow happens in a WebView / deep link, tokens stay in Composio's
 * server.
 *
 * The page is wired to the REAL server seam: `useMobileData().integrations`
 * (a `fn-integrations` EF, Composio v3.1 sessions). When the client is absent
 * (no Supabase env, AD-7) the page degrades to the honest
 * "intégrations indisponibles" empty state — it never fakes a connection.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Check, ExternalLink, Plus, Music, Loader2, CircleOff } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useMobileData } from '../../query/context';
import type { IntegrationAccount } from '../../lib/integrations-client';

// ——— Connector catalog (Composio v3.1 toolkits) ————————————————————————
// The 9 CONNECTORS below are a static device-side subset of the v3.1 toolkit
// catalog (composio-analysis.md §2). discoverTools() (lib/integrations-client.ts:47)
// is the SSoT runtime seam — it is NOT wired yet (wave-N); the server EF
// (fn-integrations) validates every toolSlug against the live session catalog
// before execution, so a stale slug in this array cannot corrupt data.
interface Connector {
  id: string; // toolkit_slug (v3.1)
  name: string;
  vendor: string;
  defaultOn: boolean; // Google Workspace preset = true
  status: 'connected' | 'disconnected' | 'token_expired' | 'reauth_required';
}

const CONNECTORS: Connector[] = [
  { id: 'GOOGLEDOCS', name: 'Google Docs', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'GMAIL', name: 'Gmail', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'GOOGLECALENDAR', name: 'Google Calendar', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'GOOGLEDRIVE', name: 'Google Drive', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'GOOGLESHEETS', name: 'Google Sheets', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'SPOTIFY', name: 'Spotify', vendor: 'Spotify', defaultOn: false, status: 'disconnected' },
  { id: 'NOTION', name: 'Notion', vendor: 'Notion', defaultOn: false, status: 'disconnected' },
  { id: 'SLACK', name: 'Slack', vendor: 'Slack', defaultOn: false, status: 'disconnected' },
  { id: 'GITHUB', name: 'GitHub', vendor: 'GitHub', defaultOn: false, status: 'disconnected' },
];

function statusIcon(s: Connector['status']) {
  switch (s) {
    case 'connected':
      return <Check size={14} className="is-ok" aria-hidden />;
    case 'reauth_required':
      return <ExternalLink size={14} className="is-warn" aria-hidden />;
    default:
      return <Plus size={14} className="is-muted" aria-hidden />;
  }
}

export function IntegrationsPage() {
  const { integrations } = useMobileData();

  // Live connection state, read from the server (AD-3: never from the body).
  const [accounts, setAccounts] = useState<IntegrationAccount[]>([]);
  const [loading, setLoading] = useState(false);
  const [connectError, setConnectError] = useState<string | null>(null);
  // In-flight guard: disables the toggles + preset while a connect call runs
  // (5 parallel window.open would otherwise race the accounts refresh).
  const [inFlight, setInFlight] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!integrations) return;
    let live = true;
    setLoading(true);
    integrations
      .listAccounts()
      .then((a) => {
        if (live) setAccounts(a);
      })
      .catch(() => {
        /* degraded: keep the catalog's default 'disconnected' state */
      })
      .finally(() => {
        if (live) setLoading(false);
      });
    return () => {
      live = false;
    };
  }, [integrations]);

  const isConnected = (id: string) =>
    accounts.some((a) => a.app.toUpperCase() === id && a.state === 'connected');

  /**
   * Connect (or disconnect) one app. Returns a Promise so preset-level
   * batching (Promise.allSettled) cannot lose individual rejections — a
   * failed item surfaces a per-item `setConnectError`, not a silent drop.
   */
  function connectOne(id: string): Promise<void> {
    if (!integrations) return Promise.resolve();
    setConnectError(null);
    setInFlight((prev) => new Set(prev).add(id));
    const connector = CONNECTORS.find((c) => c.id === id);
    const label = connector ? connector.name : id;
    return integrations
      .connect(id)
      .then((res) => {
        if (res.connectLink) {
          // AD-3 / composio.md §4: the user completes OAuth in the vendor's
          // Connect Link (opened in a WebView / browser). We do NOT build a
          // provider OAuth flow. On completion we re-read the accounts.
          window.open(res.connectLink, '_blank');
        }
        return integrations.listAccounts();
      })
      .then((a) => setAccounts(a))
      .catch((e: unknown) => {
        setConnectError(
          `${label} : ${e instanceof Error ? e.message : 'erreur de connexion'}`,
        );
      })
      .finally(() => {
        setInFlight((prev) => {
          const next = new Set(prev);
          next.delete(id);
          return next;
        });
      });
  }

  /** Single-app toggle (card button). */
  function toggle(id: string) {
    void connectOne(id);
  }

  const google = CONNECTORS.filter((c) => c.vendor === 'Google Workspace');
  const others = CONNECTORS.filter(
    (c) => c.vendor !== 'Google Workspace' && c.vendor !== 'Spotify',
  );

  // AD-7 degrade-first: no Supabase env → the client is undefined → honest
  // empty state, never a fake "connected".
  if (!integrations) {
    return (
      <>
        <IonHeader>
          <IonTitle>Intégrations</IonTitle>
        </IonHeader>
        <IonContent>
          <div className="integrations-page integrations-degraded">
            <CircleOff size={32} className="is-muted" aria-hidden />
            <p>Intégrations indisponibles — configure les valeurs Supabase de l'appareil.</p>
          </div>
        </IonContent>
      </>
    );
  }

  function renderCard(c: Connector) {
    const on = isConnected(c.id);
    return (
      <div key={c.id} className={`integration-card ${on ? 'is-connected' : ''}`}>
        <div className="integration-card-main">
          <div className="integration-card-status">{on ? <Check size={16} className="is-ok" /> : statusIcon(c.status)}</div>
          <div className="integration-card-text">
            <h4>{c.name}</h4>
            <span>{c.vendor}{c.defaultOn ? ' · par défaut' : ''}</span>
          </div>
        </div>
        <button
          type="button"
          className={`integration-toggle ${on ? 'is-on' : ''}`}
          onClick={() => toggle(c.id)}
          disabled={inFlight.has(c.id)}
          aria-label={on ? `Déconnecter ${c.name}` : `Connecter ${c.name}`}
        >
          {on ? 'Déconnecter' : 'Connecter'}
        </button>
      </div>
    );
  }

  return (
    <>
      <IonHeader>
        <IonTitle>Intégrations</IonTitle>
      </IonHeader>
      <IonContent>
        <div className="integrations-page">
          {loading ? (
            <div className="integrations-loading">
              <Loader2 size={16} className="is-spin" aria-hidden />
              <span>Chargement des comptes connectés…</span>
            </div>
          ) : null}
          {connectError ? (
            <div className="integrations-error" role="alert">
              <CircleOff size={14} aria-hidden />
              <span>{connectError}</span>
            </div>
          ) : null}

          <div className="integrations-hint">
            <p>
              Connecte des apps externes que l'agent peut utiliser (Gmail, Drive, Calendar…).
              Les identifiants restent côté serveur (Composio, AD-3) — rien ne part sur l'appareil.
            </p>
          </div>

          <section className="integration-group">
            <h3>Google Workspace <span className="integration-group-badge">par défaut</span></h3>
            <div className="integration-group-preset">
              <button
                type="button"
                className="integration-preset-btn"
                disabled={inFlight.size > 0}
                onClick={() => {
                  // Connect the full Google Workspace preset at once.
                  // allSettled: one item's rejection must not drop the
                  // others — each failure lands in setConnectError per item.
                  void Promise.allSettled(google.map((g) => connectOne(g.id)));
                }}
              >
                <Check size={14} />
                <span>Tout connecter (Docs + Gmail + Calendar + Drive + Sheets)</span>
              </button>
            </div>
            {google.map(renderCard)}
          </section>

          <section className="integration-group">
            <h3>Spotify <span className="integration-group-badge">focus mode</span></h3>
            <p className="integration-group-note">
              Quand tu connectes Spotify, le mode Focus peut <strong>visualiser
              ta session</strong> (timer ring synchronisé), te proposer ta
              <strong> playlist / album préféré</strong> en lecture au lieu du
              son générique, ou t'inviter à <strong>choisir ton propre
              morceau</strong> pour la session.
              <br />
              <span className="integration-group-note-muted">
                Spotify n'a pas d'OAuth géré par Composio : une app maison est
                requise (voir docs.composio.dev/toolkits/spotify.md).
              </span>
            </p>
            <div className="spotify-block">
              <div className={`integration-card ${isConnected('SPOTIFY') ? 'is-connected' : ''}`}>
                <div className="integration-card-main">
                  <div className="integration-card-status">
                    {isConnected('SPOTIFY') ? (
                      <Check size={16} className="is-ok" />
                    ) : (
                      <Music size={14} className="is-muted" />
                    )}
                  </div>
                  <div className="integration-card-text">
                    <h4>Spotify</h4>
                    <span>Visualisation · playlist préféré · son perso</span>
                  </div>
                </div>
                <button
                  type="button"
                  className={`integration-toggle ${isConnected('SPOTIFY') ? 'is-on' : ''}`}
                  onClick={() => toggle('SPOTIFY')}
                  disabled={inFlight.has('SPOTIFY')}
                  aria-label={isConnected('SPOTIFY') ? 'Déconnecter Spotify' : 'Connecter Spotify'}
                >
                  {isConnected('SPOTIFY') ? 'Déconnecter' : 'Connecter'}
                </button>
              </div>
            </div>
          </section>

          <section className="integration-group">
            <h3>Autres connecteurs</h3>
            {others.map(renderCard)}
          </section>
        </div>
      </IonContent>
    </>
  );
}
