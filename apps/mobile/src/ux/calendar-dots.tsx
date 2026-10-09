/**
 * CalendarDots — lot C2.2 (10-08, ref_020/021) : le **superposé de
 * pastilles** sur une date de la grille (le point « il y a des tâches /
 * événements associés à cette date »).
 *
 * Design (ref_020/021, lot C) :
 *   · 3 pastilles max par cellule (4px, `border-radius: 50%`, 2px de
 *     gap) — plus que ça = `+N` en mono xs à droite (le 4ᵉ point n'est
 *     PAS affiché, on montre le compteur).
 *   · Les couleurs = les **tokens d'accent du thème** (AD-17 :
 *     `--aurora-accent-primary` / `secondary` / `punctual`, jamais
 *     une valeur brute, jamais un glow — l'interface est lèche).
 *     Quand le thème change, les pastilles changent automatiquement
 *     (les variables `hsl()` du thème sont consommées via `color-mix()`
 *     avec un fallback `--aurora-border-strong`).
 *   · Les pastilles sont **statiques** (règle 1, 05 §2.6 : la donnée
 *     ne s'anime jamais — le `prefers-reduced-motion` ne s'applique
 *     pas, il n'y a rien à figer).
 *
 * AD-7 (miroir non câblé) : le composant est **honnête** — si la liste
 * de codes est vide, il ne rend AUCUNE pastille (jamais un point factice).
 * Le `+N` compteur n'apparaît que quand il y a plus de 3 éléments.
 */
import type { CSSProperties } from 'react';

/**
 * The accent code the pastille reads (AD-17 : les 3 accents du thème,
 * jamais l'état sémantique — les pastilles sont un **signal de
 * planification**, pas un état de tâche (05 §5.1 : success/warning/
 * danger/info stay FROZEN, the pastille is a schedule marker, not a
 * state — it follows the CURRENT accent, the theme owns it).
 */
export type AccentCode = 'primary' | 'secondary' | 'punctual' | 'neutral';

/**
 * The 4 accent → CSS variable map (AD-17 : the theme redefines these,
 * the code never hardcodes). `neutral` = `--aurora-border-strong`
 * (the 4th dot / overflow marker, not an accent — it's "there's more").
 */
const ACCENT_VAR: Record<AccentCode, string> = {
  primary: 'var(--aurora-accent-primary)',
  secondary: 'var(--aurora-accent-secondary)',
  punctual: 'var(--aurora-accent-punctual)',
  neutral: 'var(--aurora-border-strong)',
};

/**
 * `CalendarDots` — render up to `max` pastilles (default 3) + a `+N`
 * overflow counter when there are more. `codes` = the accent codes
 * (the caller derives them from the events/tasks on that date).
 *
 * The container is a 24×4px flex row (4px dots + 2px gap × 3 = 16px +
 * the `+N` label takes the remaining space, `JetBrains Mono` xs).
 */
export function CalendarDots({
  codes,
  max = 3,
  ariaLabel,
}: {
  codes: AccentCode[];
  max?: number;
  ariaLabel?: string;
}) {
  if (codes.length === 0) return null; // AD-7 : jamais une pastille factice
  const shown = codes.slice(0, max);
  const overflow = codes.length - shown.length;

  const dotStyle = (code: AccentCode): CSSProperties => ({
    background: `color-mix(in srgb, ${ACCENT_VAR[code]} 88%, transparent)`,
    // `color-mix()` with the theme variable — when the theme changes the
    // dot recolors automatically (AD-17 : no raw hex, the theme owns it).
    // Fallback (old browsers) = `--aurora-border-strong` (a neutral).
    backgroundColor: `color-mix(in srgb, ${ACCENT_VAR[code]} 88%, var(--aurora-border-strong))`,
  });

  return (
    <div
      className="cal-dots"
      role={ariaLabel ? 'list' : undefined}
      aria-label={ariaLabel}
    >
      {shown.map((c, i) => (
        <span
          key={i}
          role={ariaLabel ? 'listitem' : undefined}
          className={`cal-dot cal-dot--${c}`}
          style={dotStyle(c)}
          aria-hidden
        />
      ))}
      {overflow > 0 && (
        <span className="cal-dots-overflow mono" aria-hidden>
          +{overflow}
        </span>
      )}
    </div>
  );
}

/**
 * `calendarDotsStyle` — the container CSS (exported so the page can add
 * it to a shared `<style>` or `data.css` without re-importing the
 * component's internal classes). 24×4px flex row, 4px dots, 2px gap,
 * overflow label in `JetBrains Mono` xs (05 §2.2 l.227-229 : the
 * counter is mono, the data, never a free-form font).
 */
export const CALENDAR_DOTS_CSS = `
/* CalendarDots (C2.2 10-08, ref_020/021) — le superposé de pastilles.
   Lèche (pas de glow, AD-17 : les couleurs suivent le thème via
   color-mix(), les 4 pastilles sont statiques, règle 1 : jamais
   animées). 24px × 4px (3× 4px dots + 2px gap = 16px, le +N label
   prend le reste, mono xs). */
.cal-dots {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  min-height: 12px;
}
.cal-dot {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  flex: none;
}
.cal-dots-overflow {
  font-size: 10px;
  font-weight: 600;
  color: var(--aurora-text-muted);
  margin-left: 1px;
}
`;
