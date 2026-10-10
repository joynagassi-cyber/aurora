/**
 * Discovery — page des programmes de veille (discovery-vault plan 2026-10-10,
 * Lot 4).
 *
 * La page LISTE les programmes de veille (une `Automation`
 * `jobKind:'research'`) en CARTE (`.veille-program-card`) : titre +
 * sous-titre du programme, sources du dernier run + delta "ce jour",
 * verdict de pertinence, menu 3 points (Modifier/Supprimer, AD-7 →
 * commandes G2/G3 du kernel). Le DATA est local-only (AD-7,
 * `use-veille-programs`) — le miroir PowerSync (`automations` +
 * `discovery_vault`) est lu hors-ligne ; le CTA vide = « Créer un
 * programme de veille » (G1, via l'agent, remplacement de l'ancien CTA
 * Ascent). 5 états UX + killed (AD-13, G-M2) via `UxStates`.
 *
 * Le vault reste le SSoT (Lot 2) : la carte est la surface de lecture
 * d'un programme ; le run `research` (module Discovery) est le seul
 * writer (AD-7 single-writer).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Compass } from 'lucide-react';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';
import { useKilledDetection } from '../../hooks/use-killed';
import { VeilleProgramSkeleton } from '../../ux/skeletons';
import { useVeillePrograms } from '../../hooks/use-veille-programs';
import { VeilleProgramCard } from './card';

export function DiscoveryPage() {
  const online = useOnlineStatus();
  const { programs, isPending, isError, refetch } = useVeillePrograms();
  const killed = useKilledDetection(() => refetch());

  // 5 états UX + killed (AD-13) : l'ordre de priorité est porté par
  // `resolveUxState` (killed > offline > query states).
  const hasPrograms = programs.length > 0;
  const state = isError
    ? ({ status: 'error', error: { code: 'discovery/load_failed', message: 'Programmes indisponibles' } } as const)
    : isPending
      ? ({ status: 'loading' } as const)
      : hasPrograms
        ? ({ status: 'success', data: programs } as const)
        : ({ status: 'empty' } as const);

  const flags: UxStateFlags = {
    offline: !online,
    killed,
    onRetry: () => refetch(),
    // CTA vide = « Créer un programme de veille » (G1, agent pré-bound ;
    // remplacement de l'ancien CTA Ascent — voir le plan Lot 4).
    emptyCta: 'Créer un programme de veille',
    emptyCtaHref: '/agent?intent=Crée%20mon%20programme%20de%20veille%3A%20titre%2C%20sujet%20et%20cadence',
    emptyMessage: 'Aucun programme de veille. Créez-en un pour que l’agent veille votre domaine.',
  };

  return (
    <>
      <IonHeader>
        <IonTitle>Veille</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-discovery>
          <UxStates
            state={state}
            flags={flags}
            label="Veille"
            skeleton={<VeilleProgramSkeleton />}
          >
            <div className="veille-programs" data-veille-list>
              {programs.map((program) => (
                <VeilleProgramCard key={program.automation.id} program={program} />
              ))}
            </div>
          </UxStates>

          {/* L'entrée du document SSoT de synthèse (le vault évolutif) :
              le chat-agent y réutilise les recherches archivées (Lot 3),
              la carte ci-dessus en rend le dernier run. */}
          {hasPrograms && (
            <div className="veille-synthesis" data-synthesis-entry>
              <Compass size={16} aria-hidden />
              <span>Document de synthèse</span>
              <a
                className="aurora-btn aurora-btn--ghost aurora-tap"
                href={`/agent?intent=${encodeURIComponent('Résume mes vaults de veille : ce que je sais et ce qui a changé')}`}
                data-synthesis-cta
              >
                Consulter
              </a>
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
