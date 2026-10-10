/**
 * use-veille-programs.ts (discovery-vault plan 2026-10-10, Lot 4).
 *
 * Le join local de la CARTE de veille (AD-7, 03 S3.1) : un programme
 * = une `Automation` `jobKind:'research'` active (le titre + le
 * sous-titre de la carte), jointe à son vault (le miroir
 * `discovery_vault`, le SSoT évolutif) pour le count du dernier run,
 * le delta "ce jour", le verdict de pertinence et le document de
 * synthèse.
 *
 * Le join PUR (`buildVeilleProgram` + `selectResearchPrograms`) est
 * dans `veille-programs-join.js` (plain-JS, chargeable par le test
 * `node:test` sans le chemin TS du hook). Les types + les signatures
 * du join sont exposés par `veille-programs-join.d.ts` (le `.d.ts`
 * SIBLING du `.js` pur) — ce fichier n'est JAMAIS chargé par les
 * tests `node --experimental-strip-types` (il traîne
 * `@tanstack/react-query` + `query-client.ts` par son chemin
 * d'imports `.tsx`).
 */
import { useQuery } from '@tanstack/react-query';
import type { Automation, VeilleVault } from '@aurora/domain';
import { useMobileData } from '../query/context';
import { qk } from '../query/query-client';
import {
  buildVeilleProgram,
  selectResearchPrograms,
  type VeilleProgram,
} from './veille-programs-join';

export { buildVeilleProgram, selectResearchPrograms };
export type { VeilleProgram };

/**
 * `useVeillePrograms` — le join local de la carte. Deux lectures
 * PowerSync (le miroir `automations` + le miroir `discovery_vault`),
 * aucun réseau sur le chemin de rendu (AD-7). Dégradation honnête :
 * `[]` si le provider n'a pas encore le mirror → la carte affiche son
 * CTA vide (« Créer un programme de veille »), jamais un faux
 * programme (AD-13 état `empty`).
 */
export function useVeillePrograms(): {
  programs: VeilleProgram[];
  isPending: boolean;
  isError: boolean;
  refetch: () => void;
} {
  const data = useMobileData();

  const programsQuery = useQuery({
    queryKey: qk.discovery.programs(),
    queryFn: async (): Promise<Automation[]> => {
      if (!data.automations) return [];
      const rows = await data.automations.list({ entity: 'automations' });
      return selectResearchPrograms(rows);
    },
  });

  const vaultsQuery = useQuery({
    queryKey: qk.discovery.vaults(),
    queryFn: async (): Promise<VeilleVault[]> => {
      if (!data.discoveryVault) return [];
      return data.discoveryVault.list({ entity: 'discovery_vault' });
    },
  });

  const isPending = programsQuery.isPending || vaultsQuery.isPending;
  const isError = programsQuery.isError || vaultsQuery.isError;

  const programs: VeilleProgram[] = (programsQuery.data ?? []).map((a) =>
    buildVeilleProgram(a, vaultsQuery.data ?? []),
  );

  return {
    programs,
    isPending,
    isError,
    refetch: () => {
      void programsQuery.refetch();
      void vaultsQuery.refetch();
    },
  };
}
