/**
 * VeilleProgramCard — la carte d'un programme de veille (discovery-vault
 * plan 2026-10-10, Lot 4).
 *
 * Une carte = UN programme de veille (une `Automation` `jobKind:'research'`),
 * pas un résultat ponctuel :
 *   titre    = automation.name
 *   sous-titre = automation.action (le sujet/prompt configuré à la création)
 *   count    = sources du dernier run (manifest append-only, `discovery_vault`)
 *   delta     = "ce jour" — le delta du dernier run vs le précédent
 *   pertinence = verdict du dernier run (`relevance`, 0..1)
 *   menu 3 points = Modifier (G2) / Supprimer (G3, DESTRUCTIF → confirmation)
 *
 * AD-7 : le menu N'ÉCRIT JAMAIS `automations` directement — il émet les
 * commandes typées du kernel (`update_automation` G2 / `delete_automation`
 * G3), appliquées par le module Integrations (le single-writer, ADR §5 :
 * la suppression est DESTRUCTIVE → confirmation, le vault est ARCHIVÉ
 * pas supprimé — cohérent avec le gel G2). Les actions s'ouvrent sur
 * l'agent (le SSoT du programme), pré-bound à l'identité du programme.
 *
 * Lot 4.1 : le SSoT `vaultMd` (VAULT.md) est rendu « style Notion »
 * DANS la carte (le document évolutif que l'élève consulte page par
 * page) via `VaultMdView` (TipTap lecture + `markdownToHtml` AD-16b).
 */
import {
  Ellipsis,
  Pencil,
  Trash2,
  Files,
  TrendingUp,
  TrendingDown,
  Minus,
} from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@aurora/ui';
import type { VeilleProgram } from '../../hooks/use-veille-programs';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { VaultMdView } from '../../components/vault/VaultMdView';

/** Format the 0..1 relevance verdict into the card chip (plain French). */
function relevanceLabel(relevance: number | null): { text: string; tone: string } {
  if (relevance === null) return { text: 'Premier run…', tone: 'muted' };
  const pct = Math.round(relevance * 100);
  if (relevance >= 0.7) return { text: `Pertinence élevée · ${pct}%`, tone: 'high' };
  if (relevance >= 0.4) return { text: `Pertinence moyenne · ${pct}%`, tone: 'mid' };
  return { text: `Pertinence faible · ${pct}%`, tone: 'low' };
}

/** The "ce jour" delta chip (the last run vs the previous one). */
function deltaChip(delta: number) {
  if (delta > 0)
    return (
      <span className="veille-card-delta veille-card-delta--up" data-delta={delta}>
        <TrendingUp size={12} aria-hidden /> +{delta}
      </span>
    );
  if (delta < 0)
    return (
      <span className="veille-card-delta veille-card-delta--down" data-delta={delta}>
        <TrendingDown size={12} aria-hidden />{delta}
      </span>
    );
  return (
    <span className="veille-card-delta veille-card-delta--flat">
      <Minus size={12} aria-hidden /> aucun
    </span>
  );
}

/** The 3-point menu (Modifier G2 / Supprimer G3). READ-ONLY surface. */
function ProgramMenu({ program }: { program: VeilleProgram }) {
  const navigate = useNavigate();
  const [confirming, setConfirming] = useState(false);
  const a = program.automation;
  const label = a.name || 'ce programme';

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button
          type="button"
          className="veille-card-menu aurora-tap"
          aria-label={`Options du programme ${label}`}
        >
          <Ellipsis size={16} aria-hidden />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="veille-card-menu-pop">
        <DropdownMenuLabel>Programme de veille</DropdownMenuLabel>
        {/* G2 (AD-7) : modifier le programme → l'agent, pré-bound au nom du
            programme (le module Integrations écrit `automations`, pas ici). */}
        <DropdownMenuItem
          onSelect={() =>
            navigate(`/agent?intent=${encodeURIComponent(`Modifie mon programme de veille "${a.name}"`)}`)
          }
        >
          <Pencil size={14} aria-hidden />
          Modifier
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        {/* G3 (AD-7, ADR §5) : la suppression est DESTRUCTIVE → confirmation.
            Le vault est ARCHIVÉ (pas supprimé, gel G2) — l'agent applique
            `delete_automation` et le module Discovery archive le vault. */}
        {confirming ? (
          <DropdownMenuItem
            className="veille-card-menu-destructive"
            onSelect={() =>
              navigate(
                `/agent?intent=${encodeURIComponent(`Supprime mon programme de veille "${a.name}" (le vault d'archivage est conservé)`)}`,
              )
            }
          >
            <Trash2 size={14} aria-hidden />
            Confirmer la suppression ?
          </DropdownMenuItem>
        ) : (
          <DropdownMenuItem className="veille-card-menu-destructive" onSelect={() => setConfirming(true)}>
            <Trash2 size={14} aria-hidden />
            Supprimer
          </DropdownMenuItem>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export function VeilleProgramCard({ program }: { program: VeilleProgram }) {
  const a = program.automation;
  const last = program.lastRun;
  const relevance = relevanceLabel(program.relevance);
  const vaultMd = program.vault?.vaultMd ?? '';
  const domaine = program.vault?.domaine ?? a.id;

  return (
    <article
      className="veille-program-card"
      data-veille-program={a.id}
      aria-label={`Programme de veille ${a.name}`}
    >
      <header className="veille-card-head">
        <div className="veille-card-titles">
          <h3 className="veille-card-title">{a.name}</h3>
          {a.action ? <p className="veille-card-subtitle">{a.action}</p> : null}
        </div>
        <ProgramMenu program={program} />
      </header>

      <div className="veille-card-stats" data-vault-domaine={a.id}>
        <span className="veille-card-stat" data-count={last?.newSources ?? 0}>
          <Files size={13} aria-hidden />
          {last ? `${last.newSources} source${last.newSources > 1 ? 's' : ''}` : 'En attente du 1er run'}
        </span>
        <span className="veille-card-stat">{deltaChip(program.delta)}</span>
        <span className={`veille-card-stat veille-card-relevance--${relevance.tone}`}>
          {relevance.text}
        </span>
      </div>

      {/* Le SSoT du programme : le VAULT.md est rendu « style Notion »
          DANS la carte (Lot 4.1) — c'est le document unique évolutif
          que l'élève consulte, PAS un lien externe vers l'agent. */}
      <div className="vault-md-view" data-vault-view={domaine}>
        <VaultMdView
          vaultMd={vaultMd}
          domaine={domaine}
          ariaLabel={`Document de synthèse du programme ${a.name}`}
        />
      </div>
    </article>
  );
}
