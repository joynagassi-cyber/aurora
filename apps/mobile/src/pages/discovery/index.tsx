/**
 * Discovery feed (05 §4 / ADR §13.9, 02 S6.1).
 *
 * Feed of DiscoveryItems (gap-triggered, agent-curated). Sheet detail →
 * "work on this" → /learn or /tasks (context-preserving). "research
 * running" empty state (job state, 01 §6 loading). Full 6 UX states +
 * killed (AD-13, G-M2). No discovery mirror wired yet → the surface ships
 * the honest "recherche en cours" empty state + CTA (never fake items).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Search } from 'lucide-react';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';
import { useUiStateStore } from '../../state/ui-state';

export function DiscoveryPage() {
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = { offline: !online, killed, emptyCta: "Lancer une recherche" };

  return (
    <>
      <IonHeader>
        <IonTitle>Découverte</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-discovery>
          {/* The feed: agent-curated DiscoveryItems (gap-triggered).
              No discovery mirror yet → the "recherche en cours" state
              (job state, 01 §6) + a research CTA. */}
          <UxStates state={{ status: 'empty' }} flags={flags} label="Découverte">
            <div className="discovery-feed" data-research="running">
              <div className="discovery-item discovery-item--running">
                <Search size={20} aria-hidden />
                <span>Recherche en cours (job pending)</span>
              </div>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
