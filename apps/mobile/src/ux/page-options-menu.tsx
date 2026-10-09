/**
 * PageOptionsMenu (C5 2026-10-08) — le menu « ⋮ » en haut à droite,
 * ancré par page (chaque page détermine son propre contenu), SSoT 05
 * §3.5 l.843-854 : icône `more` (lucide `MoreVertical`, 20px header) +
 * overlay ancré à l'icône, max 6 items, 150ms ease-out, tap backdrop /
 * `back` ferment.
 *
 * Le dernier item est TOUJOURS « Paramètres » → `/settings?section=…`
 * (le réglage global, retrouvable depuis chaque page qui l'ancre) —
 * c'est ce qui rend l'app « à la fois simple et puissante » : le menu
 * par page donne l'action contextuelle rapide, le dernier item déborde
 * vers le réglage global lié à cette page.
 *
 * Composant générique (pas lié à une page) : le contenu est passé par
 * le prop `items`. La persistance de l'option sélectionnée (ex. tri)
 * est à la charge du caller (ui-state T4, AD-7 cosmétique) — ce
 * composant n'est que le chrome + l'overlay.
 */
import { MoreVertical, SlidersHorizontal, type LucideIcon } from 'lucide-react';
import { useState } from 'react';

export interface PageOptionItem {
  id: string;
  label: string;
  /**
   * Icone 16px (05 §2.5 : jamais en dessous de 16px ; ref_045 : chaque
   * item de menu porte une icône **couleur** — la `currentColor` de
   * l'icône est pilotée par le token, jamais une valeur brute, AD-17).
   */
  icon?: LucideIcon;
  /**
   * La variante de **couleur** de l'icône (ref_045 : chaque item a sa
   * teinte propre) : `accent` (la teinte du thème), `success`,
   * `warning`, `danger`, `info` — les 5 états FROZEN (05 §5.1).
   * Sans variante = `currentColor` (text-primary).
   */
  iconTone?: 'accent' | 'success' | 'warning' | 'danger' | 'info';
  onClick?: () => void;
  /** Une item « lien » (navigation route) plutôt qu'une action locale. */
  href?: string;
  /** Marquée « active » (l'option courante, ex. le tri actif). */
  active?: boolean;
}

/** Le dernier item standard : « Paramètres » → /settings?section=… */
export function settingsItem(section: string, label = 'Paramètres'): PageOptionItem {
  const Icon = SlidersHorizontal;
  return {
    id: `settings-${section}`,
    label,
    icon: Icon,
    iconTone: 'accent',
    href: `/settings?section=${section}`,
  };
}

export function PageOptionsMenu({
  items,
  ariaLabel,
}: {
  items: PageOptionItem[];
  ariaLabel: string;
}) {
  const [open, setOpen] = useState(false);
  // max 6 items (05 §3.5 l.851) — troncature défensive.
  const visible = items.slice(0, 6);

  return (
    <div className="page-options-menu">
      <button
        type="button"
        className="page-options-menu-trigger aurora-tap"
        aria-label={ariaLabel}
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((o) => !o)}
      >
        <MoreVertical size={20} aria-hidden />
      </button>

      {open && (
        <div className="page-options-menu-backdrop" aria-hidden onClick={() => setOpen(false)} />
      )}
      {open && (
        <div className="page-options-menu-list" role="menu" aria-label={ariaLabel}>
          {visible.map((item) => {
            const Icon = item.icon;
            const toneClass = item.iconTone ? `page-options-menu-item--icon-${item.iconTone}` : '';
            const content = (
              <>
                {Icon && (
                  <span className={`page-options-menu-item-icon ${toneClass}`} aria-hidden>
                    <Icon size={16} />
                  </span>
                )}
                {item.label}
                {item.active && <span className="page-options-menu-check" aria-hidden />}
              </>
            );
            const baseClass = `page-options-menu-item aurora-tap${item.active ? ' is-active' : ''}`;
            return item.href ? (
              <a
                key={item.id}
                role="menuitem"
                className={baseClass}
                href={item.href}
                onClick={item.onClick}
              >
                {content}
              </a>
            ) : (
              <button
                key={item.id}
                type="button"
                role="menuitem"
                className={baseClass}
                onClick={() => {
                  item.onClick?.();
                  setOpen(false);
                }}
              >
                {content}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
