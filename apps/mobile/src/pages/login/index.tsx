/**
 * Compte (P1-4, 10-07) — la porte unique d'Auth de l'app :
 * Connexion ET Inscription (reprend la place de l'ancienne « login page »
 * brute — refonte design 10-07 : shadcn Card/Tabs/Label/Input/Button du
 * design system, shell IonHeader/IonContent comme Settings/NotFound ;
 * plus aucun IonButton ni bouton HTML nu — pack 05 §3 / AD-17).
 *
 * Le shell boote SANS session par design (AD-7 local-first, 03 S8.1) :
 * le connector relay dégrade vers le shell local-mirror et ne spame plus
 * (gate boot-data.ts). Sign-in / sign-up → session persistée (client
 * partagé main.tsx) → le sync relay se connecte sous ~5 s.
 *
 * AD-13 : loading (submit) / error (alert role) / empty (OQ-03 env absent)
 * / success (connecté ou inscription confirmée). Tokens only, tap ≥ 44 px.
 *
 * DEV-ONLY (P1-4, 10-07) : bloc de diagnostic `fn-dev-auth` (récreation
 * canonique des comptes dev via l'admin API + test de sign-in verbatim) —
 * GATED DEV, SUPPRIMER AVANT v1.0 avec l'EF `supabase/functions/fn-dev-auth`.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { KeyRound, Loader2, LogOut, MailCheck, UserPlus } from 'lucide-react';
import { useEffect, useState } from 'react';
import {
  Button,
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  Input,
  Label,
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from '@aurora/ui';
import {
  authAvailable,
  currentSession,
  signIn,
  signOut,
  signUp,
} from '../../lib/auth';

const DEV_EF_URL = 'https://opagfyspdbhxthlxvlrk.supabase.co/functions/v1/fn-dev-auth';
const DEV_ACCOUNTS: Record<string, string> = {
  'dev.aurora@joynagassi.dev': 'Aurora-Dev1!',
  'dev.aurora2@joynagassi.dev': 'Aurora-Dev2!',
};

export function LoginPage() {
  const [tab, setTab] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [signedInAs, setSignedInAs] = useState<string | null>(null);
  const [diag, setDiag] = useState<string | null>(null);

  // Restaure l'état réel : session persistée (client partagé persistSession).
  useEffect(() => {
    void currentSession().then((s) => setSignedInAs(s?.user?.email ?? null));
  }, []);

  const switchTab = (t: 'signin' | 'signup') => {
    setTab(t);
    setError(null);
    setSuccess(null);
  };

  async function submitSignIn(e: React.FormEvent) {
    e.preventDefault();
    if (busy) return;
    setBusy(true);
    setError(null);
    setSuccess(null);
    try {
      await signIn(email, password);
      // Boot neuf : le client partagé restaure la session, le relay
      // PowerSync se connecte (03 S8.1).
      window.location.assign('/');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connexion impossible.');
      setBusy(false);
    }
  }

  async function submitSignUp(e: React.FormEvent) {
    e.preventDefault();
    if (busy) return;
    setBusy(true);
    setError(null);
    setSuccess(null);
    try {
      const { needsEmailConfirmation } = await signUp(email, password);
      if (needsEmailConfirmation) {
        setSuccess(
          `Compte créé pour ${email.trim()} — un email de confirmation a été envoyé. Vérifie ta boîte mail, puis reviens te connecter.`,
        );
      } else {
        setSuccess(`Compte créé — tu es connecté en tant que ${email.trim()}.`);
        // La session est active dans le client partagé : le reload active
        // le relay (03 S8.1).
        window.setTimeout(() => window.location.assign('/'), 1500);
      }
      setBusy(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Inscription impossible.');
      setBusy(false);
    }
  }

  async function logout() {
    setBusy(true);
    await signOut();
    window.location.assign('/');
  }

  // DEV-ONLY (P1-4 — SUPPRIMER AVANT v1.0 avec l'EF fn-dev-auth) :
  // récrée les comptes dev via l'admin API GoTrue (canonique) + test de
  // sign-in verbatim. Scope sensible service_role CÔTÉ EF (AD-3).
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
        return (await r.json().catch(
          () => ({ ok: false, error: `HTTP ${r.status} (EF non déployée ?)` }),
        )) as unknown;
      };
      const recreated = await Promise.all(
        Object.entries(DEV_ACCOUNTS).map(async ([e, pw]) => ({
          email: e,
          out: await call({ action: 'recreate', email: e, password: pw }),
        })),
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

  return (
    <>
      <IonHeader>
        <IonTitle>Compte</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-auth-page="true" className="auth-page">
          {signedInAs ? (
            <Card data-state="success">
              <CardHeader>
                <CardTitle>Connecté</CardTitle>
                <CardDescription>Session active — sync relay PowerSync opérationnel.</CardDescription>
              </CardHeader>
              <CardContent>
                <p className="auth-conn-email" data-conn-email="true">{signedInAs}</p>
                <Button
                  variant="outline"
                  className="auth-full"
                  disabled={busy}
                  onClick={() => void logout()}
                >
                  {busy ? <Loader2 aria-hidden className="is-spinning" /> : <LogOut aria-hidden />}
                  Se déconnecter
                </Button>
              </CardContent>
            </Card>
          ) : authAvailable ? (
            <Card>
              <CardHeader>
                <CardTitle>Compte Aurora</CardTitle>
                <CardDescription>
                  Connexion ou inscription — synchronisation PowerSync + agent (03 S8.1).
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Tabs value={tab} onValueChange={(v) => switchTab(v as typeof tab)}>
                  <TabsList className="auth-tabs-list">
                    <TabsTrigger value="signin">Connexion</TabsTrigger>
                    <TabsTrigger value="signup">Inscription</TabsTrigger>
                  </TabsList>

                  <TabsContent value="signin">
                    <form onSubmit={submitSignIn} data-state={busy ? 'loading' : error ? 'error' : 'idle'}>
                      <div className="auth-fields">
                        <div className="auth-field">
                          <Label htmlFor="auth-signin-email">Email</Label>
                          <Input
                            id="auth-signin-email"
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="prenom@domaine.dev"
                            autoComplete="email"
                            required
                          />
                        </div>
                        <div className="auth-field">
                          <Label htmlFor="auth-signin-password">Mot de passe</Label>
                          <Input
                            id="auth-signin-password"
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            autoComplete="current-password"
                            required
                          />
                        </div>
                      </div>

                      {error ? (
                        <p className="auth-error" role="alert">{error}</p>
                      ) : null}

                      <Button
                        type="submit"
                        className="auth-full"
                        disabled={busy || email.trim().length === 0 || password.length === 0}
                      >
                        {busy ? <Loader2 aria-hidden className="is-spinning" /> : <KeyRound aria-hidden />}
                        {busy ? 'Connexion…' : 'Se connecter'}
                      </Button>

                      {/* Comptes dev P1-4/P1-5 — pré-remplissage uniquement
                          (jamais d'auto-submit), 10-07. */}
                      <div className="auth-dev-accounts" role="group" aria-label="Comptes de développement">
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => { setEmail('dev.aurora@joynagassi.dev'); setPassword('Aurora-Dev1!'); }}
                        >
                          dev.aurora@…
                        </Button>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => { setEmail('dev.aurora2@joynagassi.dev'); setPassword('Aurora-Dev2!'); }}
                        >
                          dev.aurora2@…
                        </Button>
                      </div>
                    </form>
                  </TabsContent>

                  <TabsContent value="signup">
                    {success ? (
                      <div data-state="success" className="auth-result">
                        <p className="auth-success-note">
                          <MailCheck aria-hidden /> {success}
                        </p>
                        <Button
                          variant="outline"
                          className="auth-full"
                          onClick={() => switchTab('signin')}
                        >
                          Passer à la connexion
                        </Button>
                      </div>
                    ) : (
                      <form onSubmit={submitSignUp} data-state={busy ? 'loading' : error ? 'error' : 'idle'}>
                        <div className="auth-fields">
                          <div className="auth-field">
                            <Label htmlFor="auth-signup-email">Email</Label>
                            <Input
                              id="auth-signup-email"
                              type="email"
                              value={email}
                              onChange={(e) => setEmail(e.target.value)}
                              placeholder="prenom@domaine.dev"
                              autoComplete="email"
                              required
                            />
                          </div>
                          <div className="auth-field">
                            <Label htmlFor="auth-signup-password">Mot de passe</Label>
                            <Input
                              id="auth-signup-password"
                              type="password"
                              value={password}
                              onChange={(e) => setPassword(e.target.value)}
                              autoComplete="new-password"
                              minLength={8}
                              required
                            />
                          </div>
                        </div>

                        {error ? (
                          <p className="auth-error" role="alert">{error}</p>
                        ) : null}

                        <Button
                          type="submit"
                          className="auth-full"
                          disabled={busy || email.trim().length === 0 || password.length < 8}
                        >
                          {busy ? <Loader2 aria-hidden className="is-spinning" /> : <UserPlus aria-hidden />}
                          {busy ? 'Inscription…' : 'Créer mon compte'}
                        </Button>
                        <p className="auth-note">
                          8 caractères minimum. Si le projet exige la confirmation par email,
                          tu recevras un lien avant ta première connexion.
                        </p>
                      </form>
                    )}
                  </TabsContent>
                </Tabs>
              </CardContent>
            </Card>
          ) : (
            <Card data-state="empty">
              <CardHeader>
                <CardTitle>Compte indisponible</CardTitle>
                <CardDescription>
                  Aucun accès Supabase configuré (OQ-03 — valeurs d'env manquantes).
                </CardDescription>
              </CardHeader>
            </Card>
          )}

          {import.meta.env.DEV && (
            <div className="auth-diag" data-diag="true">
              <Button
                variant="outline"
                size="sm"
                onClick={() => void runDevAuthDiagnostic()}
              >
                DEV — diagnostic comptes (EF fn-dev-auth)
              </Button>
              {diag ? <pre>{diag}</pre> : null}
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
