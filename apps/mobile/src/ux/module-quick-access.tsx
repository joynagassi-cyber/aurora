/**
 * module-quick-access.tsx — the G-M7 module quick-access row (8 target
 * modules: calendrier, focus, connaissances, découvertes, compétences,
 * intégrations, inbox, canvas). Rendered in the Home header; each chip is
 * visible ONLY when its module is enabled (`useUserFeatures`), and tappable
 * (≥ 44 px, 05 DS). The 5 frozen primary tabs keep their own bar — this
 * row surfaces the gated modules without adding a 6th tab (02 §6.1: max 5).
 *
 * Icons = lucide 20 px (ui-libraries §4: real icons, never emoji/SVG).
 */
import { Award, Brain, Calendar, Compass, Inbox, PenTool, Plug, Timer } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useUserFeatures } from '../query/user-features';

const MODULE_CHIPS = [
  { id: 'calendar', label: 'Calendrier', href: '/calendar', Icon: Calendar },
  { id: 'focus', label: 'Focus', href: '/focus', Icon: Timer },
  { id: 'knowledge', label: 'Connaissances', href: '/knowledge', Icon: Brain },
  { id: 'discovery', label: 'Découvertes', href: '/discovery', Icon: Compass },
  { id: 'skills', label: 'Compétences', href: '/skills', Icon: Award },
  { id: 'integrations', label: 'Intégrations', href: '/integrations', Icon: Plug },
  { id: 'inbox', label: 'Inbox', href: '/inbox', Icon: Inbox },
  // /canvas/new = creation mode (router comment, 0022).
  { id: 'canvas', label: 'Canvas', href: '/canvas/new', Icon: PenTool },
] as const;

export function ModuleQuickAccess() {
  const { isEnabled } = useUserFeatures();
  const navigate = useNavigate();
  const visible = MODULE_CHIPS.filter((m) => isEnabled(m.id));
  if (visible.length === 0) return null;

  return (
    <nav className="module-quick-access" aria-label="Modules">
      {visible.map(({ id, label, href, Icon }) => (
        <a
          key={id}
          href={href}
          className="module-chip aurora-tap"
          onClick={(event) => {
            // Native <a> deep link works too; the navigate() keeps the SPA
            // transition (context-preserving navigation, 02 §6.3).
            event.preventDefault();
            navigate(href);
          }}
          aria-label={`Ouvrir ${label}`}
        >
          <Icon size={20} aria-hidden />
          <span>{label}</span>
        </a>
      ))}
    </nav>
  );
}
