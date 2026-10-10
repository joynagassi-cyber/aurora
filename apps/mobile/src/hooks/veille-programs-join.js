/**
 * veille-programs-join.js (discovery-vault plan 2026-10-10, Lot 4).
 *
 * Le join PUR de la carte de veille (AD-7, 03 S3.1, pattern de
 * `filtering.ts` / `discovery.ts` — logique sans React/DOM/réseau).
 * Ce module ne connaît PAS le type `.ts` du hook ; le hook
 * `use-veille-programs.ts` l'importe.
 *
 * Un programme de veille = une carte :
 *   titre    = automation.name
 *   sous-titre = automation.action (le sujet/prompt configuré à la
 *                création) — la description de tâche de la carte
 *   count    = newSources du dernier run (sources trouvées ce run)
 *   delta     = newSources(dernier run) − newSources(précédent),
 *                borné à 0 min (la carte ne montre pas un "moins que
 *                la veille" — le SSoT manifest est append-only)
 *   pertinence = verdict du dernier run (0..1, le verdict du
 *                FilterDecision de `runVeillePipeline`)
 *
 * Le menu 3 points de la carte émet les commandes typées G2/G3
 * (`update_automation` / `delete_automation`, packages/agent) —
 * le WRITER de `automations` est le module Integrations (AD-7),
 * jamais Discovery ni la carte elle-même.
 */

/**
 * `selectResearchPrograms` — le filtre du programme (la carte ne montre
 * que les veilles actives : une `Automation` `jobKind === 'research'`
 * ET `enabled`). Le module Integrations est le single-writer de la
 * table `automations` (AD-7) ; la carte est la surface de lecture.
 *
 * (Plain-JS module — les types `Automation` sont dérivés structurellement
 *  par le consommateur TypeScript du hook `use-veille-programs.ts`,
 *  pas importés ici pour garder le module chargeable sans le monorepo.)
 */
export function selectResearchPrograms(automations) {
  return automations.filter((a) => a.jobKind === 'research' && a.enabled);
}

/**
 * `buildVeilleProgram` — le join programme → SSoT vault + manifest.
 * Le vault se cherche par `domaine = automation.id` (V1 : le handler
 * de recherche écrit le vault du programme en keyant par l'id de
 * l'automation ; le domaine étant dérivé sinon de `query.domains[0]`).
 *
 * Bornes :
 *  - pas de vault / pas de run → `lastRun = null`, `relevance = null`,
 *    `totalSources = 0`, `delta = 0` (la carte montre « En attente du
 *    1er run » — un état vide honnête, jamais un faux verdict).
 *  - delta négatif (le run courant a moins de sources que le précédent
 *    — consolidation, pas de nouveauté) → borné à 0 (le "ce jour"
 *    de la carte ne dit jamais « moins que la veille »).
 */
export function buildVeilleProgram(automation, vaults) {
  const domain = automation.id;
  const vault =
    (vaults || []).find((v) => v.domaine === domain) ?? null;
  const runs = vault?.runs ?? [];
  const last = runs.at(-1) ?? null;
  const prev = runs.at(-2) ?? null;
  const delta = last
    ? Math.max(0, last.newSources - (prev?.newSources ?? 0))
    : 0;
  return {
    automation,
    lastRun: last,
    delta,
    relevance: last ? last.relevance : null,
    totalSources: last?.totalSources ?? 0,
    vault,
  };
}
