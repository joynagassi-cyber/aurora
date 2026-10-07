/**
 * Onboarding (usage personnel, 10-07) — le parcours de première entrée :
 * sign-up → /onboarding → app. Trois étapes courtes (bienvenue → style
 * visuel → premiers pas), state cosmétique persisté par device
 * (`ui-state.onboardingSeen`, AD-7 — jamais de données entités ici).
 *
 * Design : shell Ion + shadcn Card/Button/Badge (pattern Settings/NotFound),
 * tokens only, tap ≥ 44 px, 150–250 ms GPU-only.
 *
 * Règles d'accès :
 *  - pas de session → état « connecte-toi d'abord » (AD-13 empty-honnête) ;
 *  - `onboardingSeen = true` → redirection immédiate vers `/` (parcours déjà fait) ;
 *  - sinon → wizard ; « Commencer » pose le flag puis part sur l'accueil.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  ArrowRight,
  Check,
  Home,
  Loader2,
  LogIn,
  Moon,
  Sparkles,
  Sun,
  Target,
  Timer,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@aurora/ui';
import { currentSession } from '../../lib/auth';
import { useUiStateStore } from '../../state/ui-state';

type OnbStep = 1 | 2 | 3;

export function OnboardingPage() {
  const navigate = useNavigate();
  const [session, setSession] = useState<{ email?: string } | null | undefined>(undefined);
  const { theme, setTheme, onboardingSeen, setOnboardingSeen } = useUiStateStore();
  const [step, setStep] = useState<OnbStep>(1);
  const [busy, setBusy] = useState(false);

  // Session réelle (client partagé persistSession) — undefined = chargement.
  useEffect(() => {
    void currentSession().then((s) => setSession(s));
  }, []);

  // Parcours déjà terminé → on n'y reste pas (AD-13, jamais de blocage).
  useEffect(() => {
    if (session !== undefined && session !== null && onboardingSeen) {
      navigate('/', { replace: true });
    }
  }, [session, onboardingSeen, navigate]);

  async function finish() {
    setBusy(true);
    setOnboardingSeen(true);
    // Petit délai pour le persist (localStorage) avant le saut sur l'accueil.
    window.setTimeout(() => {
      navigate('/');
    }, 250);
  }

  const steps = ['Bienvenue', 'Ton style', 'Premiers pas'] as const;

  return (
    <>
      <IonHeader>
        <IonTitle>Onboarding</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-onboarding="true" className="onb-page">
          {session === undefined ? (
            <Card data-state="loading">
              <CardHeader>
                <CardTitle>Préparation…</CardTitle>
                <CardDescription>Chargement de ta session.</CardDescription>
              </CardHeader>
            </Card>
          ) : session === null ? (
            <Card data-state="empty">
              <CardHeader>
                <CardTitle>Bienvenue sur Aurora</CardTitle>
                <CardDescription>
                  Connecte-toi (ou crée ton compte) pour lancer ton onboarding.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button className="onb-full" onClick={() => navigate('/login')}>
                  <LogIn aria-hidden /> Se connecter / s'inscrire
                </Button>
              </CardContent>
            </Card>
          ) : (
            <Card>
              <CardHeader>
                <div className="onb-stepline">
                  <CardTitle>
                    {steps[step - 1]}
                  </CardTitle>
                  <Badge variant="secondary">
                    {step} / {steps.length}
                  </Badge>
                </div>
                <CardDescription>
                  {step === 1
                    ? `Content de te voir, ${session.email ?? 'à toi'}.`
                    : step === 2
                      ? "Aurora s'adapte à toi : le thème change instantanément (AD-17, tokens)."
                      : "Trois portes d'entrée — choisis où commencer."}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {step === 1 && (
                  <div className="onb-points" data-step="welcome">
                    <p>
                      <Sparkles aria-hidden /> Tes objectifs, tes apprentissages et ton
                      agent vivent <strong>localement d'abord</strong> : la synchro
                      PowerSync se passe en arrière-plan, hors-ligne compris (AD-7).
                    </p>
                    <p>
                      <Target aria-hidden /> L'accueil répond toujours à une question :
                      « Qu'est-ce qui compte maintenant ? » (AD-14) — jamais un mur de widgets.
                    </p>
                    <p>
                      <Timer aria-hidden /> Sessions Focus, coachings et agent t'accompagnent
                      sans jamais bloquer l'interface (jobs asynchrones, AD-8).
                    </p>
                  </div>
                )}

                {step === 2 && (
                  <div className="onb-style" data-step="style">
                    <div className="onb-style-row" role="radiogroup" aria-label="Style">
                      <Button
                        variant={theme !== 'dark' ? 'default' : 'outline'}
                        role="radio"
                        aria-checked={theme !== 'dark'}
                        onClick={() => setTheme('light')}
                      >
                        <Sun aria-hidden /> Clair
                      </Button>
                      <Button
                        variant={theme === 'dark' ? 'default' : 'outline'}
                        role="radio"
                        aria-checked={theme === 'dark'}
                        onClick={() => setTheme('dark')}
                      >
                        <Moon aria-hidden /> Sombre
                      </Button>
                    </div>
                    <p className="onb-note">
                      10 thèmes expressifs + 3 presets restent disponibles dans
                      Paramètres → « Thème » (catalogue SSoT du design system).
                    </p>
                  </div>
                )}

                {step === 3 && (
                  <div className="onb-ctas" data-step="next">
                    <Button variant="outline" className="onb-cta" onClick={() => navigate('/goals')}>
                      <Target aria-hidden /> Créer mon premier objectif
                    </Button>
                    <Button variant="outline" className="onb-cta" onClick={() => navigate('/')}>
                      <Home aria-hidden /> Voir ma journée
                    </Button>
                    <Button variant="outline" className="onb-cta" onClick={() => navigate('/focus')}>
                      <Timer aria-hidden /> Lancer une session Focus
                    </Button>
                  </div>
                )}

                <div className="onb-actions">
                  {step > 1 ? (
                    <Button variant="ghost" onClick={() => setStep((s) => (s - 1) as OnbStep)}>
                      Retour
                    </Button>
                  ) : null}
                  {step < 3 ? (
                    <Button onClick={() => setStep((s) => (s + 1) as OnbStep)}>
                      Suivant <ArrowRight aria-hidden />
                    </Button>
                  ) : (
                    <Button onClick={() => void finish()} disabled={busy}>
                      {busy ? <Loader2 aria-hidden className="is-spinning" /> : <Check aria-hidden />}
                      Commencer
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </IonContent>
    </>
  );
}
