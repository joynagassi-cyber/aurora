/**
 * Fallback / "feature disabled" surface (OQ-48: ONE global 404, reused by
 * 5+ screens — AD-15, 1 pattern = 1 owner). A deep link into a disabled
 * feature renders this dedicated state, NEVER a crash or blank 404
 * (feature-registry S6).
 *
 * OQ-7: the logo is COLORED at the center (`05 §9.1`). The S9 in-app asset
 * (logo WITHOUT background) is pinned via `data-asset` so the build can
 * resolve it; until then a token emblem stands in — never a re-invented logo.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useLocation, Link } from 'react-router-dom';

export function NotFoundPage() {
  const { pathname } = useLocation();

  return (
    <>
      <IonHeader>
        <IonTitle>Indisponible</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-state="feature-disabled" data-path={pathname}>
          {/* S9: the in-app logo (colored, centered on the 404 — OQ-7). */}
          <span
            className="a404-logo"
            data-asset="aurora_icon_a_integre_dans_l'applciation"
            aria-hidden
          />
          <p>« {pathname} » n'est pas disponible (fonction désactivée).</p>
          <div className="a404-actions">
            <Link to="/home">Retour à l'accueil</Link>
            {/* OQ-48: secondary CTA (FR S6 libellé — the parent-screen link). */}
            <Link to="/" className="a404-secondary">
              Consulter l'écran parent
            </Link>
          </div>
        </div>
      </IonContent>
    </>
  );
}
