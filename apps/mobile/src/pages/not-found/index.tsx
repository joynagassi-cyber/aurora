/**
 * Fallback / "feature disabled" state (feature-registry S6: a deep link
 * into a disabled feature renders a dedicated state, NEVER a crash or a
 * 404 — re-enable CTA + redirect to the parent tab).
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
          <p>« {pathname} » n'est pas disponible (fonction désactivée).</p>
          <Link to="/home">Retour à l'accueil</Link>
        </div>
      </IonContent>
    </>
  );
}
