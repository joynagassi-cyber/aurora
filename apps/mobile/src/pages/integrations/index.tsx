/**
 * Integrations page (docs/integrations/composio.md, mission S33-35).
 *
 * Composio = tool/integration layer behind the `IntegrationProvider` port
 * (AD-1 vendor isolation). This page lets the user connect external apps
 * (Google Workspace by default) and see which connected accounts are live.
 *
 * AD-3: no external credentials on the device — connected-account state
 * is read from `integrations_state` (RLS user-isolated, server-side);
 * the OAuth flow happens in a WebView / deep link, tokens stay in
 * Composio's server.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Check, ExternalLink, Plus, Music } from 'lucide-react';
import { useState } from 'react';

// ——— Connector catalog (Composio toolkits; Google Workspace = default preset). ———
interface Connector {
  id: string;
  name: string;
  vendor: string;
  defaultOn: boolean; // Google Workspace preset = true
  status: 'connected' | 'disconnected' | 'token_expired' | 'reauth_required';
}

// In production this reads `integrations_state` (server, RLS); here the
// preset seed mirrors the documented default (Google Workspace full).
const CONNECTORS: Connector[] = [
  { id: 'google-docs', name: 'Google Docs', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'gmail', name: 'Gmail', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'google-calendar', name: 'Google Calendar', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'google-drive', name: 'Google Drive', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'google-sheets', name: 'Google Sheets', vendor: 'Google Workspace', defaultOn: true, status: 'disconnected' },
  { id: 'spotify', name: 'Spotify', vendor: 'Spotify', defaultOn: false, status: 'disconnected' },
  { id: 'notion', name: 'Notion', vendor: 'Notion', defaultOn: false, status: 'disconnected' },
  { id: 'slack', name: 'Slack', vendor: 'Slack', defaultOn: false, status: 'disconnected' },
  { id: 'github', name: 'GitHub', vendor: 'GitHub', defaultOn: false, status: 'disconnected' },
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
  // Optimistic local state — in production each toggle triggers the
  // Composio OAuth deep-link; the resulting connectedAccountID lands in
  // `integrations_state` (server). The UI reflects that state.
  const [connected, setConnected] = useState<Set<string>>(new Set());

  function toggle(id: string) {
    setConnected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  const google = CONNECTORS.filter((c) => c.vendor === 'Google Workspace');
  // Spotify gets its own dedicated section (focus-mode visualisation);
  // the "Autres" bucket excludes it so it is not rendered twice.
  const others = CONNECTORS.filter(
    (c) => c.vendor !== 'Google Workspace' && c.vendor !== 'Spotify',
  );

  function renderCard(c: Connector) {
    const on = connected.has(c.id);
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
                onClick={() => {
                  // Connect the full Google Workspace preset at once
                  setConnected((prev) => {
                    const next = new Set(prev);
                    google.forEach((g) => next.add(g.id));
                    return next;
                  });
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
            </p>
            <div className="spotify-block">
              {CONNECTORS.find((c) => c.id === 'spotify') ? (
                <div className={`integration-card ${connected.has('spotify') ? 'is-connected' : ''}`}>
                  <div className="integration-card-main">
                    <div className="integration-card-status">
                      {connected.has('spotify') ? (
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
                    className={`integration-toggle ${connected.has('spotify') ? 'is-on' : ''}`}
                    onClick={() => toggle('spotify')}
                    aria-label={connected.has('spotify') ? 'Déconnecter Spotify' : 'Connecter Spotify'}
                  >
                    {connected.has('spotify') ? 'Déconnecter' : 'Connecter'}
                  </button>
                </div>
              ) : null}
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
