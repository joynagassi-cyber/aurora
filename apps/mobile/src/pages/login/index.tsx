/**
 * Login (P1-4 unblock, 10-07) — the single Supabase Auth entry point.
 *
 * The shell boots WITHOUT a session by design (AD-7 local-first, 03 S8.1):
 * the PowerSync connector's `fetchCredentials` degrades to the local-mirror
 * shell and logs "No Supabase session — sign in before PowerSync connect".
 * This page is the missing entry: sign in → the persisted session is picked
 * up by the engine's client on the next boot → the sync loop connects.
 *
 * AD-13: loading (submitting) / error (credential failure) states, plus the
 * honest empty state when OQ-03 env values are absent (authAvailable = false).
 * AD-17 / pack 05: tokens only, no hardcoded colors, tap targets ≥ 44 px.
 *
 * DEV-ONLY (P1-4, 10-07) : bloc de diagnostic `fn-dev-auth` (réparation du
 * hash via l'admin API GoTrue + test de sign-in verbatim) — GATED DEV,
 * SUPPRIMER AVANT v1.0 avec l'EF `supabase/functions/fn-dev-auth`.
 */
import { IonButton, IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Lock, Loader2, LogOut } from 'lucide-react';
import { useEffect, useState } from 'react';
import { authAvailable, currentSession, signIn, signOut } from '../../lib/auth';
import { useNavigate } from 'react-router-dom';

const DEV_EF_URL = 'https://opagfyspdbhxthlxvlrk.supabase.co/functions/v1/fn-dev-auth';
const DEV_ACCOUNTS: Record<string, string> = {
  'dev.aurora@joynagassi.dev': 'Aurora-Dev1!',
  'dev.aurora2@joynagassi.dev': 'Aurora-Dev2!',
};

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [signedInAs, setSignedInAs] = useState<string | null>(null);
  const [diag, setDiag] = useState<string | null>(null);
  const navigate = useNavigate();

  // Restore the persisted session state so the page reflects reality.
  useEffect(() => {
    void currentSession().then((s) => setSignedInAs(s?.user?.email ?? null));
  }, []);

  // DEV-ONLY (P1-4, 10-07 — SUPPRIMER AVANT v1.0, avec l'EF fn-dev-auth) :
  // répare le hash par l'admin API GoTrue (canonique) + test de sign-in
  // verbatim. L'EF est public (verify_jwt=false) ; le scope sensible reste
  // service_role CÔTÉ EF (AD-3 — zéro secret sur device).
  async function runDevAuthDiagnostic() {
    setDiag('Diagnostic en cours (fn-dev-auth)…');
    try {
      const call = async (payload: Record<string, unknown>): Promise<unknown> => {
        const r = await fetch(DEV_EF_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            apikey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? '',
          },
          body: JSON.stringify(payload),
        });
        return (await r.json().catch(() => ({ ok: false, error: `HTTP ${r.status} (EF non déployée ?)` }))) as unknown;
      };
      // Recréation canonique via l'admin API GoTrue (audience par défaut du
      // projet + hash canonique + identité email) — les INSERT SQL bruts ne
      // garantissent pas l'audience du projet, d'où les 400 persistants.
      const recreated = await Promise.all(
        Object.entries(DEV_ACCOUNTS).map(async ([e, pw]) => {
          const out = await call({ action: 'recreate', email: e, password: pw });
          return { email: e, out };
        }),
      );
      const test = await call({
        action: 'test-signin',
        email: 'dev.aurora@joynagassi.dev',
        password: DEV_ACCOUNTS['dev.aurora@joynagassi.dev'],
      });
      setDiag(JSON.stringify({ recreated, test }, null, 2));
    } catch (e) {
      setDiag(`Diagnostic impossible : ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (busy) return;
    setBusy(true);
    setError(null);
    try {
      await signIn(email.trim(), password);
      // Fresh boot: the engine's Supabase client (persistSession) restores the
      // session and the PowerSync sync loop connects (03 S8.1).
      window.location.assign('/');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connexion impossible.');
      setBusy(false);
    }
  }

  async function logout() {
    setBusy(true);
    await signOut();
    window.location.assign('/');
  }

  return (
    <>
      <IonHeader>
        <IonTitle>Connexion</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-login="true" className="login">
          {signedInAs ? (
            <div data-state="success" className="login-state">
              <p>Connecté en tant que <strong>{signedInAs}</strong>.</p>
              <IonButton
                className="aurora-tap"
                fill="outline"
                role="button"
                aria-label="Se déconnecter"
                disabled={busy}
                onClick={() => void logout()}
              >
                <LogOut size={16} aria-hidden /> Déconnexion
              </IonButton>
            </div>
          ) : authAvailable ? (
            <>
              <form
                className="login-form"
                onSubmit={submit}
                data-state={busy ? 'loading' : error ? 'error' : 'idle'}
              >
                <label className="login-field">
                  <span>Email</span>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="dev.aurora@joynagassi.dev"
                    autoComplete="email"
                    required
                  />
                </label>
                <label className="login-field">
                  <span>Mot de passe</span>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    autoComplete="current-password"
                    required
                  />
                </label>

                {error ? (
                  <p className="login-error" role="alert">{error}</p>
                ) : null}

                <IonButton
                  type="submit"
                  className="aurora-tap"
                  disabled={busy || email.trim().length === 0 || password.length === 0}
                >
                  {busy ? <Loader2 size={16} aria-hidden className="is-spinning" /> : <Lock size={16} aria-hidden />}
                  {busy ? 'Connexion…' : 'Se connecter'}
                </IonButton>
              </form>

              {/* Dev accounts (created in Supabase Auth for the P1-4/P1-5
                  round-trip + RLS penetration, 10-07) — prefill only, never
                  auto-submit. */}
              <div className="login-dev-accounts" role="group" aria-label="Comptes de développement">
                <button
                  type="button"
                  className="aurora-btn aurora-btn--ghost aurora-tap"
                  onClick={() => { setEmail('dev.aurora@joynagassi.dev'); setPassword('Aurora-Dev1!'); }}
                >
                  dev.aurora@…
                </button>
                <button
                  type="button"
                  className="aurora-btn aurora-btn--ghost aurora-tap"
                  onClick={() => { setEmail('dev.aurora2@joynagassi.dev'); setPassword('Aurora-Dev2!'); }}
                >
                  dev.aurora2@…
                </button>
              </div>

              {import.meta.env.DEV && (
                <div className="login-diag" data-diag="true">
                  <button
                    type="button"
                    className="aurora-btn aurora-btn--ghost aurora-tap"
                    onClick={() => void runDevAuthDiagnostic()}
                  >
                    DEV — diagnostic comptes (EF fn-dev-auth)
                  </button>
                  {diag ? <pre>{diag}</pre> : null}
                </div>
              )}
            </>
          ) : (
            <div data-state="empty" className="login-state">
              <p>Aucun accès Supabase configuré (OQ-03 — valeurs d'env manquantes).</p>
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
