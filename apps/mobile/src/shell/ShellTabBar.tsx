/**
 * ShellTabBar — la barre d'onglets mobile (02 §6.1 : max 5 tabs,
 * 44-60 px). Montage UNIQUE dans <Shell /> (permanente sur toutes les
 * routes ; les détails s'ouvrent AU-DESSUS de l'onglet courant — la barre
 * reste, l'onglet actif ne change pas).
 *
 * Navigation : React Router (navigate) + state cosmétique `activeTab`
 * (ui-state, AD-7 — jamais de données entités). Icônes lucide 20 px,
 * labels 10–11 px, tokens only (--aurora-*), tap target ≥ 44 px,
 * safe-area basse (Capacitor/Android).
 */
import { Bot, BookOpen, Home, ListChecks, TrendingUp } from 'lucide-react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useUiStateStore, type TabId } from '../state/ui-state';

const TABS: Array<{ id: TabId; path: string; label: string; Icon: typeof Home }> = [
  { id: 'home', path: '/', label: 'Accueil', Icon: Home },
  { id: 'tasks', path: '/tasks', label: 'Tâches', Icon: ListChecks },
  { id: 'learn', path: '/learn', label: 'Apprendre', Icon: BookOpen },
  { id: 'progress', path: '/progress', label: 'Progrès', Icon: TrendingUp },
  { id: 'agent', path: '/agent', label: 'Agent', Icon: Bot },
];

export function ShellTabBar() {
  const navigate = useNavigate();
  const location = useLocation();
  const { setActiveTab } = useUiStateStore();

  const isActive = (tab: (typeof TABS)[number]) =>
    tab.id === 'home'
      ? location.pathname === '/'
      : location.pathname === tab.path || location.pathname.startsWith(`${tab.path}/`);

  return (
    <nav className="shell-tabbar" data-tabbar="true" aria-label="Navigation principale">
      {TABS.map(({ id, path, label, Icon }) => {
        const active = isActive({ id, path, label, Icon });
        return (
          <button
            key={id}
            type="button"
            className="shell-tab"
            data-tab={id}
            data-active={active || undefined}
            aria-current={active ? 'page' : undefined}
            onClick={() => {
              setActiveTab(id);
              navigate(path);
            }}
          >
            <Icon size={20} aria-hidden />
            <span className="shell-tab-label">{label}</span>
          </button>
        );
      })}
    </nav>
  );
}
