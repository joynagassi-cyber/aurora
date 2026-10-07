/**
 * Fallback / "feature disabled" surface (OQ-48: ONE global 404, reused by
 * 5+ screens — AD-15, 1 pattern = 1 owner). A deep link into a disabled
 * feature renders this dedicated state, NEVER a crash or blank 404
 * (feature-registry S6).
 *
 * OQ-7: the logo is COLORED at the center (`05 §9.1`). The S9 in-app asset
 * (logo WITHOUT background) is pinned via `data-asset` so the build can
 * resolve it; until then a token emblem stands in — never a re-invented logo.
 *
 * Shadcn layer: the whole surface is a `<Card>` with two `<Button>` CTAs
 * (asChild → router Link). The emblem + centered layout stay token-driven
 * (`.a404-*` in atoms.css); only the controls are real @aurora/ui shadcn.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useLocation, Link } from 'react-router-dom';
import {
  Button,
  Card,
  CardContent,
  CardDescription,
  CardTitle,
} from '@aurora/ui';
import { IN_APP_LOGO, IN_APP_LOGO_ASSET } from '../../brand/logo';

export function NotFoundPage() {
  const { pathname } = useLocation();

  return (
    <>
      <IonHeader>
        <IonTitle>Indisponible</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-state="feature-disabled" data-path={pathname} className="a404-root">
          <Card className="a404-card">
            <CardContent className="a404-card-body">
              {/* S9 (§9.1 l.387): the 404 is a LIVING empty state → COLORED
                  without-background in-app logo, CENTERED. The real asset
                  (repo-root `assets/` SSoT via brand/logo.ts), never the
                  external full-logo and never a re-invented mark. */}
              <img
                src={IN_APP_LOGO}
                alt=""
                className="a404-logo"
                width={64}
                height={64}
                data-asset={IN_APP_LOGO_ASSET}
                loading="eager"
                decoding="async"
              />
              <CardTitle>« {pathname} » n'est pas disponible</CardTitle>
              <CardDescription>
                Cette fonction est désactivée sur cet appareil.
              </CardDescription>
              <div className="a404-actions">
                <Button asChild>
                  <Link to="/home">Retour à l'accueil</Link>
                </Button>
                {/* OQ-48: secondary CTA (FR S6 libellé — the parent-screen link). */}
                <Button asChild variant="secondary">
                  <Link to="/">Consulter l'écran parent</Link>
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </IonContent>
    </>
  );
}
