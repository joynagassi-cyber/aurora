/**
 * Discovery feed (05 §4 / ADR §13.9, 02 S6.1).
 *
 * Feed of DiscoveryItems (gap-triggered, agent-curated). The " veille" —
 * the agent curates surfaces worth studying; "Ascent" CTA routes to the
 * agent (ascent mode) and, when a path exists, to /ascent (read the
 * mounted training). Sheet detail → "work on this" → /learn or /tasks
 * (context-preserving). "research running" empty state (job state, 01 §6
 * loading). Full 6 UX states + killed (AD-13, G-M2). No discovery mirror
 * wired yet → the surface ships the honest "recherche en cours" empty
 * state + CTA (never fake items).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Compass, Search } from 'lucide-react';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';
import { useUiStateStore } from '../../state/ui-state';

export function DiscoveryPage() {
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = {
    offline: !online,
    killed,
    emptyCta: "Lancer une recherche",
  };

  return (
    <>
      <IonHeader>
        <IonTitle>Découverte</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-discovery>
          {/* The feed: agent-curated DiscoveryItems (gap-triggered).
              No discovery mirror yet → the honest "recherche en cours"
              state (job state, 01 §6). `emptyCtaHref` points the UxStates
              CTA at the ascent CTA below (a real, in-page action) rather
              than a dead CTA — the button renders a link, not inert text. */}
          <UxStates
            state={{ status: 'empty' }}
            flags={{ ...flags, emptyCtaHref: '#ascent-cta' }}
            label="Découverte"
          >
            <div className="discovery-feed" data-research="running">
              <div className="discovery-item discovery-item--running">
                <Search size={20} aria-hidden />
                <span>Recherche en cours (job pending)</span>
              </div>
            </div>
          </UxStates>

          {/* Ascent entry (docs/ascent S12): the veille surfaces concepts;
              the "Ascent" CTA = conduct the climb (agent ascent mode) or,
              when a path exists, READ it on /ascent. One tap. */}
          <div id="ascent-cta" className="discovery-ascent-cta" data-ascent-entry="true">
            <Compass size={16} aria-hidden />
            <span>Étudier via Ascent</span>
            <a
              className="aurora-btn aurora-btn--ghost aurora-tap"
              href="/agent?intent=Mode%20Ascent%20:%20conçois%20ma%20formation%20et%20monte%20le%20chemin"
            >
              Lancer
            </a>
          </div>
        </div>
      </IonContent>
    </>
  );
}
