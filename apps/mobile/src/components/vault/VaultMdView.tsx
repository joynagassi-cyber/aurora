/**
 * VaultMdView — le rendu « style Notion » du VAULT.md de veille, monté
 * DANS la carte de veille (discovery-vault plan 2026-10-10, Lot 4.1).
 *
 * Un programme de veille a un SSoT `vaultMd` (le VAULT.md évolutif du
 * domaine, append-only). La carte (Lot 4) expose ce document en rendu
 * TipTap : markdown → HTML « style Notion » via `markdownToHtml`
 * (AD-16b : le HTML brut est neutralisé), TipTap en `editable: false`.
 *
 * AD-7 : la carte est une surface de LECTURE du SSoT — elle ne committe
 * jamais le vault (seul le run `research` écrit). Le rendu est donc
 * non-éditable : `VaultMdEditor` avec `editable=false`, ou un rendu
 * statique si le SSoT est vide (état AD-13 « premier run en attente »).
 */
import { VaultMdEditor } from './VaultMdEditor';
import { BookOpenText, FileText } from 'lucide-react';

export function VaultMdView({
  vaultMd,
  domaine,
  ariaLabel,
}: {
  /** the SSoT markdown (VAULT.md of the program, may be empty pre-first-run). */
  vaultMd: string;
  /** the domain key (the accessible label prefix + `data-vault`). */
  domaine: string;
  /** the aria-label for the ProseMirror region. */
  ariaLabel: string;
}) {
  // L'état vide (AD-13) : pas encore de SSoT (le premier run n'a pas
  // committe de vault) → un placeholder honnête, jamais un rendu factice.
  if (!vaultMd || vaultMd.trim() === '') {
    return (
      <div className="vault-md-empty" data-vault-empty={domaine}>
        <FileText size={14} aria-hidden />
        <span>Le document de synthèse sera écrit au premier run.</span>
      </div>
    );
  }
  // Le SSoT markdown → HTML « style Notion » (AD-16b) → TipTap lecture.
  return (
    <div className="vault-md-view-wrap" data-vault-view={domaine}>
      <div className="vault-md-view-label">
        <BookOpenText size={13} aria-hidden />
        <span>Document de synthèse</span>
      </div>
      <VaultMdEditor
        content={vaultMd}
        domaine={domaine}
        ariaLabel={`${ariaLabel} (document de synthèse)`}
      />
    </div>
  );
}
