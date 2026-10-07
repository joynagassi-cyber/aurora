/**
 * feature-gate.tsx — the feature-registry S6 state: a deep link into a
 * DISABLED module renders the « module désactivé » screen (simple French,
 * CTA to Settings), NEVER a 404 / crash (02 S6.1). The 5 primary tabs are
 * never gated (frozen chrome) — only the 8 G-M7 module routes (GATED_FEATURES).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import type { ReactNode } from 'react';
import { useUserFeatures } from '../query/user-features';
import { FEATURE_MODULES } from '../feature-registry';

export function FeatureGate({ feature, children }: { feature: string; children: ReactNode }) {
  const { isEnabled } = useUserFeatures();
  if (isEnabled(feature)) return children;

  const module = FEATURE_MODULES.find((m) => m.id === feature);
  const name = module?.name ?? feature;

  return (
    <div data-feature-gated={feature}>
      <IonHeader>
        <IonTitle>{name}</IonTitle>
      </IonHeader>
      <IonContent>
        <div className="feature-gated" role="region" aria-label={`Module ${name} désactivé`}>
          <p>Le module « {name} » est actuellement désactivé.</p>
          <a
            href="/settings?section=modules"
            className="aurora-btn aurora-btn--primary aurora-tap"
            data-cta="enable-module"
          >
            Activer dans les Paramètres
          </a>
        </div>
      </IonContent>
    </div>
  );
}
